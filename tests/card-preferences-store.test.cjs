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
const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === '@kit.ArkData') {
    return { preferences: { getPreferencesSync: () => prefs } };
  }
  return originalLoad.call(this, request, parent, isMain);
};
const store = require('../entry/src/main/ets/storage/CardPreferencesStore.ets');
Module._load = originalLoad;

test('each structure and colorway survives a store round trip without changing refresh settings', async () => {
  const { CARD_STYLES } = require('../entry/src/main/ets/model/CardPreferences.ets');
  for (const style of CARD_STYLES) {
    for (const paletteIndex of [0, 1, 2]) {
      const input = { ...store.loadCardPreferences({}), theme: style.id, paletteIndex,
        title: '我的额度', appearance: 'light', transparency: 25,
        cardPeriodMinutes: 240, autoIntervalMinutes: 37, failureBackoffMinutes: 30 };
      await store.saveCardPreferences({}, input);
      assert.deepEqual(store.loadCardPreferences({}), input);
    }
  }
});

test('loading a legacy record keeps business preferences and leaves stored data intact', () => {
  const legacy = JSON.stringify({ title: '旧卡片', theme: 'glass', appearance: 'dark', transparency: 20,
    cardPeriodMinutes: 120, autoIntervalMinutes: 91, failureBackoffMinutes: 60 });
  values.set('preferences', legacy);
  const loaded = store.loadCardPreferences({});
  assert.equal(loaded.theme, 'aurora');
  assert.equal(loaded.paletteIndex, 0);
  assert.equal(loaded.autoIntervalMinutes, 91);
  assert.equal(loaded.cardPeriodMinutes, 120);
  assert.equal(loaded.failureBackoffMinutes, 60);
  assert.equal(values.get('preferences'), legacy);
});
