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

test('glass appearance and brightness survive a store round trip', async () => {
  const input = { ...store.loadCardPreferences({}), theme: 'glass', appearance: 'light', transparency: 50 };
  await store.saveCardPreferences({}, input);
  assert.equal(store.loadCardPreferences({}).appearance, 'light');
  assert.equal(store.loadCardPreferences({}).transparency, 50);
  assert.equal(store.loadCardPreferences({}).theme, 'glass');
});
