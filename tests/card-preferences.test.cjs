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
  assert.equal(value.theme, 'pine');
  assert.equal(value.appearance, 'system');
  assert.equal(value.transparency, 50);
  assert.equal(value.cardPeriodMinutes, 60);
  assert.equal(value.autoIntervalMinutes, 1);
  assert.equal(value.failureBackoffMinutes, 15);
  assert.equal(card.cardPalette('graphite', 50).surface, '#80252D32');
});

test('single card ring distinguishes zero, unknown, and a known percentage', () => {
  const snapshot = createMockSnapshot('normal');
  snapshot.accounts[0].id = 1;
  const options = { ...card.defaultCardPreferences(), title: '我的套餐', theme: 'mist' };
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

test('glass appearance and brightness bind to both card sizes', () => {
  const options = card.normalizeCardPreferences({ ...card.defaultCardPreferences(), theme: 'glass', transparency: 50 });
  assert.equal(options.theme, 'glass');
  assert.equal(card.cardPalette('glass', 0).surface, '#E1F0F1');
  assert.equal(card.cardPalette('glass', 50).surface, '#F8FFFF');
  assert.equal(card.cardPalette('glass', 0, true).surface, '#354D57');
  assert.equal(card.cardPalette('glass', 50, true).surfaceEnd, '#344F59');

  const snapshot = createMockSnapshot('normal');
  snapshot.accounts[0].id = 1;
  for (const dimension of [2, 3]) {
    const light = new MockFormData(snapshot, [1], dimension, options, false);
    const dark = new MockFormData(snapshot, [1], dimension, options, true);
    assert.equal(light.glass, 'true');
    assert.equal(light.surfaceColor, '#F8FFFF');
    assert.equal(light.surfaceEndColor, '#DBF1F2');
    assert.equal(dark.surfaceColor, '#63858B');
    assert.equal(dark.surfaceEndColor, '#344F59');
    assert.notEqual(light.inkColor, dark.inkColor);
    assert.notEqual(light.edgeColor, dark.edgeColor);
    assert.equal(new MockFormData(snapshot, [1], dimension,
      { ...options, appearance: 'light' }, true).surfaceColor, light.surfaceColor);
    assert.equal(new MockFormData(snapshot, [1], dimension,
      { ...options, appearance: 'dark' }, false).surfaceColor, dark.surfaceColor);
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
