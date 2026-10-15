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

const values = new Map();
const prefs = {
  getSync: (key, fallback) => values.has(key) ? values.get(key) : fallback,
  putSync: (key, value) => values.set(key, value),
  flush: async () => {}
};
let configRevision = 1;
const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === '@kit.ArkData') {
    return { preferences: { getPreferencesSync: () => prefs } };
  }
  if (request === './LocalConfig' && parent.filename.endsWith('RefreshPolicyStore.ets')) {
    return { loadConfigSummary: () => ({ revision: configRevision }) };
  }
  if (request === './CardPreferencesStore' && parent.filename.endsWith('RefreshPolicyStore.ets')) {
    return { loadCardPreferences: () => ({ autoIntervalMinutes: 60, cardPeriodMinutes: 60,
      failureBackoffMinutes: 15 }) };
  }
  return originalLoad.call(this, request, parent, isMain);
};
const store = require('../entry/src/main/ets/storage/RefreshPolicyStore.ets');
Module._load = originalLoad;

test('refresh policy persists failure backoff and resets with new connection revision', async () => {
  const context = {};
  const originalNow = Date.now;
  let now = 1000000;
  Date.now = () => now;
  try {
    const first = await store.beginRefresh(context, 1, 'manual');
    assert.ok(first);
    assert.equal(await store.beginRefresh(context, 1, 'automatic'), undefined);
    await store.finishRefresh(context, first, 'network');
    assert.equal(store.loadRefreshPolicy(context, 1).failureCount, 1);
    assert.equal(store.nextRefreshAt(context, 1), now + 60 * 60000);

    now += 60000;
    const second = await store.beginRefresh(context, 1, 'manual');
    assert.ok(second);
    await store.finishRefresh(context, second, 'server');
    assert.equal(store.nextRefreshAt(context, 1), now + 60 * 60000);

    configRevision = 2;
    assert.equal(store.nextRefreshAt(context, 2), 0);
    const third = await store.beginRefresh(context, 2, 'manual');
    assert.ok(third);
    await store.finishRefresh(context, second, 'network');
    assert.equal(store.loadRefreshPolicy(context, 2).requestId, third.requestId);
  } finally {
    Date.now = originalNow;
  }
});
