const assert = require('node:assert/strict');
const fs = require('node:fs');
const test = require('node:test');
const ts = require('typescript');

require.extensions['.ets'] = (module, filename) => {
  const compiled = ts.transpileModule(fs.readFileSync(filename, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 }
  });
  module._compile(compiled.outputText, filename);
};

const { RefreshCoordinator, sameRefreshStamp } =
  require('../entry/src/main/ets/model/RefreshCoordinator.ets');

function deferred() {
  let resolve;
  const promise = new Promise((done) => { resolve = done; });
  return { promise, resolve };
}

test('simultaneous refreshes of one revision share one request', async () => {
  const gate = new RefreshCoordinator();
  const request = deferred();
  let calls = 0;
  const first = gate.run('config-1:featured-1', () => { calls++; return request.promise; });
  const second = gate.run('config-1:featured-1', () => { calls++; return Promise.resolve('wrong'); });
  assert.equal(first, second);
  assert.equal(calls, 1);
  request.resolve('ready');
  assert.equal(await second, 'ready');
  assert.equal(await gate.run('config-1:featured-1', () => Promise.resolve('new')), 'new');
});

test('new config or selection revision runs independently of an older request', async () => {
  const gate = new RefreshCoordinator();
  const old = deferred();
  const first = gate.run('config-1:featured-1', () => old.promise);
  const second = gate.run('config-1:featured-2', () => Promise.resolve('current'));
  assert.equal(await second, 'current');
  old.resolve('old');
  assert.equal(await first, 'old');
  assert.equal(await gate.run('config-1:featured-2', () => Promise.resolve('fresh')), 'fresh');
});

test('a completed request is stale after key or featured account changes', () => {
  const start = { serviceUrl: 'https://sub2.example', configRevision: 2, featuredRevision: 3 };
  assert.equal(sameRefreshStamp(start, { ...start }), true);
  assert.equal(sameRefreshStamp(start, { ...start, configRevision: 3 }), false);
  assert.equal(sameRefreshStamp(start, { ...start, featuredRevision: 4 }), false);
  assert.equal(sameRefreshStamp(start, { ...start, serviceUrl: 'https://other.example' }), false);
});
