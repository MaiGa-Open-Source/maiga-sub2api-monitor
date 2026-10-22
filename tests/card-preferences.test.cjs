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

const card = require('../entry/src/main/ets/model/CardPreferences.ets');
const { MockFormData, createMockSnapshot } = require('../entry/src/main/ets/model/MockQuota.ets');

test('card preferences validate title, intervals, theme and opacity', () => {
  const value = card.normalizeCardPreferences({ title: 'A\nB', theme: 'invalid', appearance: 'invalid', transparency: 90,
    cardPeriodMinutes: 31, autoIntervalMinutes: 0, failureBackoffMinutes: 999 });
  assert.equal(value.title, 'AB');
  assert.equal(value.theme, 'aurora');
  assert.equal(value.paletteIndex, 0);
  assert.equal(value.appearance, 'system');
  assert.equal(value.transparency, 50);
  assert.equal(value.cardPeriodMinutes, 60);
  assert.equal(value.autoIntervalMinutes, 1);
  assert.equal(value.failureBackoffMinutes, 15);
  assert.equal(card.cardPalette('aurora', 50).surface, '#80E8E9F7');
});

test('single card ring distinguishes zero, unknown, and a known percentage', () => {
  const snapshot = createMockSnapshot('normal');
  snapshot.accounts[0].id = 1;
  const options = { ...card.defaultCardPreferences(), title: '我的套餐', theme: 'aurora' };
  const known = new MockFormData(snapshot, [1], 2, options);
  assert.equal(known.cardTitle, '我的套餐');
  assert.equal(known.dimension, 'single');
  assert.equal(known.singleRingKnown, 'true');
  assert.equal(known.singleRingValue, 42);
  assert.equal(known.singleTimeLabel, snapshot.lastSuccessAt.slice(-5));
  snapshot.accounts[0].remaining = '0%';
  const empty = new MockFormData(snapshot, [1], 2, options);
  assert.equal(empty.singleRingKnown, 'true');
  assert.equal(empty.singleRingValue, 0);
  snapshot.accounts[0].remaining = '--';
  const unknown = new MockFormData(snapshot, [1], 2, options);
  assert.equal(unknown.singleRingKnown, 'false');
  assert.equal(unknown.singleRingValue, 0);
});

test('removed theme preferences migrate only appearance fields', () => {
  for (const theme of ['pine', 'graphite', 'mist', 'coral', 'glass']) {
    const input = { title: '旧账号卡', theme, appearance: 'dark', transparency: 25,
      cardPeriodMinutes: 240, autoIntervalMinutes: 37, failureBackoffMinutes: 30 };
    assert.deepEqual(card.normalizeCardPreferences(input), { ...input, theme: 'aurora', paletteIndex: 0 });
  }
  for (const paletteIndex of [-1, 3, 1.5, undefined, NaN]) {
    assert.equal(card.normalizeCardPreferences({ ...card.defaultCardPreferences(), paletteIndex }).paletteIndex, 0);
  }
});

test('dual card uses its own two selected accounts', () => {
  const snapshot = createMockSnapshot('normal');
  snapshot.accounts.forEach((account, index) => { account.id = index + 1; });
  const data = new MockFormData(snapshot, [1, 3], 3);
  assert.equal(data.firstName, '主账号');
  assert.equal(data.secondName, '工作账号');
  assert.equal(data.dimension, 'dual');
});
