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
const registry = require('../entry/src/main/ets/storage/FormRegistry.ets');
Module._load = originalLoad;

test('existing 2x4 registrations migrate and a 2x2 card keeps its own dimension', () => {
  values.set('form_ids', JSON.stringify(['old-dual']));
  assert.deepEqual(registry.loadForms({}), [{ id: 'old-dual', dimension: 3 }]);
  registry.registerFormId({}, 'new-single', 2);
  assert.deepEqual(registry.loadForms({}), [
    { id: 'old-dual', dimension: 3 }, { id: 'new-single', dimension: 2 }
  ]);
  assert.equal(registry.formDimension({}, 'new-single'), 2);
  registry.unregisterFormId({}, 'old-dual');
  assert.deepEqual(registry.loadForms({}), [{ id: 'new-single', dimension: 2 }]);
});
