const assert = require('node:assert/strict');
const fs = require('node:fs');
const test = require('node:test');
const ts = require('typescript');

require.extensions['.ets'] = (module, filename) => {
  const source = fs.readFileSync(filename, 'utf8');
  const compiled = ts.transpileModule(source, {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 }
  });
  module._compile(compiled.outputText, filename);
};

const contract = require('../entry/src/main/ets/network/Sub2ApiContract.ets');
const { mapAccount, liveSnapshot } = require('../entry/src/main/ets/model/LiveQuota.ets');
const { MockFormData } = require('../entry/src/main/ets/model/MockQuota.ets');
const fixtures = require('./fixtures/sub2api-v0.2.8.json');

function page(name) {
  return contract.parseEnvelope(JSON.stringify(fixtures[name]));
}

test('v0.2.8 account envelope and pagination', async () => {
  const pages = [page('page1'), page('page2')];
  const visited = [];
  const accounts = await contract.collectAccounts(async (number) => {
    visited.push(number);
    return pages[number - 1];
  });
  assert.deepEqual(visited, [1, 2]);
  assert.deepEqual(accounts.map((account) => account.id), [101, 102, 103]);
});

test('auth, missing endpoint, and malformed envelopes stay distinct', () => {
  assert.equal(contract.httpErrorKind(200), '');
  assert.equal(contract.httpErrorKind(401), 'auth');
  assert.equal(contract.httpErrorKind(403), 'auth');
  assert.equal(contract.httpErrorKind(302), 'redirect');
  assert.equal(contract.httpErrorKind(404), 'unsupported');
  assert.equal(contract.httpErrorKind(503), 'server');
  assert.throws(() => contract.parseEnvelope('<html>login</html>'), { kind: 'format' });
  assert.throws(() => contract.parseEnvelope('{"code":401,"message":"invalid"}'), { kind: 'format' });
});

test('incomplete or changing account pages never report a partial total', async () => {
  const first = page('page1');
  const duplicate = structuredClone(page('page2'));
  duplicate.items[0].id = 101;
  await assert.rejects(contract.collectAccounts(async (number) => number === 1 ? first : duplicate),
    { kind: 'format' });
  const changed = structuredClone(page('page2'));
  changed.total = 4;
  await assert.rejects(contract.collectAccounts(async (number) => number === 1 ? first : changed),
    { kind: 'format' });
  const malformed = structuredClone(first);
  delete malformed.items[0].schedulable;
  await assert.rejects(contract.collectAccounts(async () => malformed), { kind: 'format' });
  const unsafeId = structuredClone(first);
  unsafeId.items[0].id = Number.MAX_SAFE_INTEGER + 1;
  await assert.rejects(contract.collectAccounts(async () => unsafeId), { kind: 'format' });
});

test('pagination cap reports too many accounts without returning a partial list', async () => {
  await assert.rejects(contract.collectAccounts(async (number) => ({
    items: Array.from({ length: 100 }, (_, index) => ({
      id: (number - 1) * 100 + index + 1, name: 'Account', platform: 'openai',
      type: 'oauth', status: 'active', schedulable: true
    })),
    total: 1001, page: number, pages: 11
  })), { kind: 'tooManyAccounts' });
});

test('known quota, expired window, and unavailable status map without inventing zero', () => {
  const codex = page('page1').items[0];
  const usage = contract.validateUsage(contract.parseEnvelope(JSON.stringify(fixtures.usage)));
  assert.equal(mapAccount(codex, usage).remaining, '8%');
  assert.equal(mapAccount(codex, usage).period, '7 天窗口');
  assert.equal(mapAccount(codex, usage).health, 'low');
  assert.equal(mapAccount(page('page1').items[1]).remaining, '10%');
  assert.equal(mapAccount(codex).remaining, '--');
  assert.equal(mapAccount(codex).health, 'unknown');
  assert.equal(mapAccount(codex, { seven_day: { utilization: 100, resets_at: '2000-01-01T00:00:00Z' } }).remaining, '--');
  assert.equal(mapAccount(page('page2').items[0]).health, 'unavailable');
});

test('unselected unknown quotas do not warn when featured quotas are available', () => {
  const account = (id) => ({ id, name: `Account ${id}`, platform: 'openai', type: 'oauth',
    status: 'active', schedulable: true });
  const usage = { seven_day: { utilization: 20, resets_at: '2099-01-01T00:00:00Z' } };
  const accounts = [mapAccount(account(1), usage), mapAccount(account(2), usage), mapAccount(account(3))];
  const ready = liveSnapshot(accounts, [1, 2]);
  assert.equal(ready.statusLabel, '关注账号正常');
  assert.equal(new MockFormData(ready, [1, 2]).statusTone, 'healthy');

  const unknown = liveSnapshot(accounts, [1, 3]);
  assert.equal(unknown.statusLabel, '部分额度未知');
  assert.equal(new MockFormData(unknown, [1, 3]).statusTone, 'warning');

  const unselected = liveSnapshot(accounts, []);
  assert.equal(unselected.statusLabel, '请选择关注账号');
  assert.equal(new MockFormData(unselected, []).statusTone, 'warning');
});

test('Gemini keeps the source pool and never presents missing limits as zero', () => {
  const account = { id: 201, name: 'Gemini', platform: 'gemini', type: 'apikey',
    status: 'active', schedulable: true };
  const actual = mapAccount(account, page('geminiUsage'));
  assert.equal(actual.remaining, '13%');
  assert.equal(actual.region, '共享池');
  assert.equal(actual.period, '日请求额度');
  assert.equal(mapAccount(account).remaining, '--');
});

test('Antigravity identifies the most constrained model rather than combining models', () => {
  const account = { id: 202, name: 'Antigravity', platform: 'antigravity', type: 'oauth',
    status: 'active', schedulable: true };
  const actual = mapAccount(account, page('antigravityUsage'));
  assert.equal(actual.remaining, '9%');
  assert.equal(actual.region, 'claude-sonnet-4-5');
  assert.equal(actual.period, '模型额度');
  assert.equal(actual.health, 'low');
});

test('Grok picks the tighter valid billing window and labels local free quota', () => {
  const account = { id: 203, name: 'Grok', platform: 'grok', type: 'oauth',
    status: 'active', schedulable: true };
  const paid = mapAccount(account, page('grokUsage'));
  assert.equal(paid.remaining, '5%');
  assert.equal(paid.period, '周账期');
  const free = mapAccount(account, { grok_free_token_limit: 10000,
    grok_local_usage_24h: { tokens: 6000 } });
  assert.equal(free.remaining, '40%');
  assert.equal(free.period, '24 小时本地 Token');
  const monthly = mapAccount(account, { grok_billing: { period_type: 'monthly', used_percent: 60,
    period_end: '2099-01-01T00:00:00Z' } });
  assert.equal(monthly.remaining, '40%');
  assert.equal(monthly.period, '月度账期');
  assert.equal(mapAccount(account, { grok_billing: { usage_percent: 100, period_end: '2000-01-01T00:00:00Z',
    period_type: 'weekly' } }).remaining, '--');
});
