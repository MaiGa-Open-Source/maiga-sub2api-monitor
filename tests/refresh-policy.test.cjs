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

const policy = require('../entry/src/main/ets/model/RefreshPolicy.ets');
const MINUTE = 60 * 1000;

test('manual refresh bypasses the automatic interval but merges an active request', () => {
  const initial = policy.freshPolicy(4);
  assert.equal(policy.canStartRefresh(initial, 'manual', 1000), true);
  const active = policy.reserveRefresh(initial, 1000, 'request-1');
  assert.equal(active.inFlight, true);
  assert.equal(policy.canStartRefresh(active, 'manual', 1000), false);
  const success = policy.completeRefresh(active, 5000, '');
  assert.equal(success.inFlight, false);
  assert.equal(policy.canStartRefresh(success, 'manual', 5001), true);
  assert.equal(policy.canStartRefresh(success, 'automatic', 1000 + 60 * MINUTE - 1), false);
  assert.equal(policy.canStartRefresh(success, 'automatic', 1000 + 60 * MINUTE), true);
});

test('selection change bypasses success interval but respects failure backoff', () => {
  const active = policy.reserveRefresh(policy.freshPolicy(2), 1000, 'request-1');
  const success = policy.completeRefresh(active, 2000, '');
  assert.equal(policy.canStartRefresh(success, 'selection', 2001), true);
  const failure = policy.completeRefresh(active, 2000, 'network');
  assert.equal(policy.canStartRefresh(failure, 'selection', 2001), false);
  assert.equal(policy.canStartRefresh(failure, 'selection', 2000 + MINUTE), true);
});

test('card period and request limit both gate automatic card reads', () => {
  const settings = { ...require('../entry/src/main/ets/model/CardPreferences.ets').defaultCardPreferences(),
    cardPeriodMinutes: 120, autoIntervalMinutes: 1 };
  const success = policy.completeRefresh(policy.reserveRefresh(policy.freshPolicy(1), 1000, 'one'), 2000, '');
  assert.equal(policy.canStartRefresh(success, 'card', 1000 + 119 * MINUTE, settings), false);
  assert.equal(policy.canStartRefresh(success, 'card', 1000 + 120 * MINUTE, settings), true);
  assert.equal(policy.canStartRefresh(success, 'automatic', 1000 + MINUTE, settings), true);
});

test('consecutive failures back off to configured cap and success clears failures', () => {
  let state = policy.freshPolicy(1);
  const settings = { ...require('../entry/src/main/ets/model/CardPreferences.ets').defaultCardPreferences(),
    autoIntervalMinutes: 1, failureBackoffMinutes: 30 };
  for (const [index, minutes] of [1, 2, 4, 8, 16, 30, 30].entries()) {
    const now = 1000 + index * 20 * MINUTE;
    state = policy.reserveRefresh(state, now, `request-${index}`, settings);
    state = policy.completeRefresh(state, now + 1000, 'server', settings);
    assert.equal(state.nextAllowedAt - now - 1000, minutes * MINUTE);
    assert.equal(policy.canStartRefresh(state, 'manual', now + 1001), true);
  }
  const recoveredAt = state.nextAllowedAt;
  state = policy.completeRefresh(state, recoveredAt, '', settings);
  assert.equal(state.failureCount, 0);
  assert.equal(state.lastFailureKind, '');
  assert.equal(state.nextAllowedAt, 0);
});

test('a large backwards clock change does not block refresh indefinitely', () => {
  const state = policy.completeRefresh(policy.freshPolicy(1), 100 * MINUTE, 'network');
  assert.equal(policy.canStartRefresh(state, 'manual', 0), true);
});
