const assert = require('node:assert/strict');
const fs = require('node:fs');
const Module = require('node:module');
const test = require('node:test');
const ts = require('typescript');

require.extensions['.ets'] = (module, filename) => {
  const compiled = ts.transpileModule(fs.readFileSync(filename, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 }
  });
  module._compile(compiled.outputText, filename);
};

const policy = require('../entry/src/main/ets/model/RefreshPolicy.ets');
let state = policy.freshPolicy(1);
let saved;
let listCalls = 0;
let usageCalls = 0;
let lastOutcome = '';
let failList = false;
const summary = { serviceUrl: 'https://sub2.example', hasKey: true, revision: 1 };
const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (parent.filename.endsWith('QuotaRefresh.ets')) {
    if (request === '../storage/LocalConfig') {
      return { loadConfigSummary: () => summary,
        loadLocalCredentials: async () => ({ serviceUrl: summary.serviceUrl, adminKey: 'test-only' }) };
    }
    if (request === '../storage/QuotaSnapshotStore') {
      return { loadFeaturedIds: () => [1], loadSingleId: () => 0, loadFeaturedRevision: () => 0,
        loadSnapshot: () => saved,
        saveSnapshot: async (_context, _url, _revision, _featuredRevision, snapshot) => {
          saved = snapshot;
          return true;
        } };
    }
    if (request === '../storage/RefreshPolicyStore') {
      return { loadRefreshPolicy: () => state,
        nextRefreshAt: () => Math.max(state.nextAllowedAt,
          state.lastAttemptAt ? state.lastAttemptAt + 60 * 60000 : 0),
        beginRefresh: async (_context, _revision, reason) => {
          if (!policy.canStartRefresh(state, reason, Date.now())) return undefined;
          state = policy.reserveRefresh(state, Date.now(), 'request-1');
          return state;
        },
        finishRefresh: async (_context, _reservation, failureKind) => {
          lastOutcome = failureKind;
          state = policy.completeRefresh(state, Date.now(), failureKind);
        } };
    }
    if (request === '../network/Sub2ApiClient') {
      return { listAccounts: async () => {
        listCalls++;
        if (failList) throw new Error('test list failure');
        return [
          { id: 1, name: 'Selected', platform: 'openai', type: 'oauth', status: 'active', schedulable: true },
          { id: 2, name: 'Other', platform: 'openai', type: 'oauth', status: 'active', schedulable: true }
        ];
      }, getAccountUsage: async () => { usageCalls++; throw new Error('test network failure'); } };
    }
  }
  return originalLoad.call(this, request, parent, isMain);
};
const { refreshQuota, failureSnapshot } = require('../entry/src/main/ets/model/QuotaRefresh.ets');
const { Sub2ApiError } = require('../entry/src/main/ets/network/Sub2ApiContract.ets');
Module._load = originalLoad;

test('domain policy failure is distinct from a connection failure', () => {
  const result = failureSnapshot(undefined, new Sub2ApiError('domain', 2300998));
  assert.equal(result.statusLabel, '域名未获准');
  assert.match(result.notice, /域名策略/);
  assert.equal(result.cached, false);
});

test('one selected usage failure keeps the account list; manual retry is immediate', async () => {
  const first = await refreshQuota({}, 'manual');
  assert.equal(first.accounts.length, 2);
  assert.equal(first.health, 'partial');
  assert.equal(first.statusLabel, '额度读取失败');
  assert.equal(first.accounts[0].remaining, '--');
  assert.equal(lastOutcome, 'usage');
  assert.equal(state.failureCount, 1);

  const second = await refreshQuota({}, 'manual');
  assert.equal(second.accounts.length, 2);
  assert.equal(second.health, 'partial');
  assert.equal(listCalls, 2);
  assert.equal(usageCalls, 2);
});

test('a full read failure keeps manual retry available without inventing a snapshot', async () => {
  state = policy.freshPolicy(1);
  saved = undefined;
  listCalls = 0;
  failList = true;
  try {
    const first = await refreshQuota({}, 'manual');
    assert.equal(first.health, 'offline');
    assert.equal(first.cached, false);
    assert.equal(first.notice, '无法读取服务，尚无成功数据');
    assert.equal(state.failureCount, 1);
    const second = await refreshQuota({}, 'manual');
    assert.equal(second.health, 'offline');
    assert.equal(listCalls, 2);
  } finally {
    failList = false;
  }
});

test('a selected usage failure keeps its last known percentage', async () => {
  state = policy.freshPolicy(1);
  saved = {
    health: 'ready', statusLabel: '运行正常', notice: '', checkedAt: '10:00',
    lastSuccessAt: '09-27 10:00', cached: true, savedAt: Date.now(),
    accounts: [{ id: 1, name: 'Selected', platform: 'openai', region: '', period: '本周',
      remaining: '42%', health: 'healthy', stateLabel: '正常' }]
  };
  const result = await refreshQuota({}, 'manual');
  assert.equal(result.health, 'partial');
  assert.equal(result.accounts[0].remaining, '42%');
  assert.equal(result.accounts[0].stateLabel, '上次 · 正常');
  assert.equal(result.lastSuccessAt, '09-27 10:00');
  assert.equal(result.accounts[1].remaining, '--');
});

test('automatic checks respect the interval after a manual refresh', async () => {
  state = policy.freshPolicy(1);
  saved = undefined;
  const before = listCalls;
  await refreshQuota({}, 'manual');
  const delayed = await refreshQuota({}, 'automatic');
  assert.equal(listCalls, before + 1);
  assert.equal(delayed.health, 'partial');
  assert.match(delayed.notice, /下次自动请求/);
});
