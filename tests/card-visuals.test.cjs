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

const { CARD_STYLES, defaultCardPreferences, cardPalette } = require('../entry/src/main/ets/model/CardPreferences.ets');
const { MockFormData, createMockSnapshot } = require('../entry/src/main/ets/model/MockQuota.ets');
const { TrendFormData } = require('../entry/src/main/ets/model/TrendFormData.ets');
const { trendChart } = require('../entry/src/main/ets/model/TrendStats.ets');
const { trendVisualPaths } = require('../entry/src/main/ets/model/CardVisuals.ets');

const history = Array.from({ length: 30 }, (_, i) => ({
  date: `2026-10-${String(i + 1).padStart(2, '0')}`, requests: i * 13, actualCost: i * 0.17
}));
const snapshot = { accountId: 7, accountName: '真实口径示例', history, savedAt: new Date(2026, 9, 30, 8).getTime(),
  status: 'offline', notice: '同步失败 · 上次数据' };
const isVisual = key => /Color$/.test(key) || key === 'theme' || key.startsWith('chartStyle');
const businessFields = data => Object.fromEntries(Object.entries(data).filter(([key]) => !isVisual(key)));

test('fifteen colorways bind identically to all four sizes without altering quota or trend data', () => {
  assert.equal(CARD_STYLES.length, 5);
  const quota = createMockSnapshot('offline');
  quota.accounts.forEach((account, i) => { account.id = i + 1; });
  for (const style of CARD_STYLES) {
    assert.equal(style.palettes.length, 3);
    for (const paletteIndex of [0, 1, 2]) {
      const preferences = { ...defaultCardPreferences(), theme: style.id, paletteIndex };
      const palette = cardPalette(style.id, 0, false, paletteIndex);
      const forms = [new MockFormData(quota, [1], 2, preferences), new MockFormData(quota, [1, 3], 3, preferences),
        new TrendFormData(snapshot, { dimension: 3, days: 7, metric: 'requests', selectedIndex: 2 }, preferences),
        new TrendFormData(snapshot, { dimension: 4, days: 30, metric: 'cost', selectedIndex: 9 }, preferences)];
      for (const form of forms) {
        assert.equal(form.theme, style.id);
        assert.equal(form.surfaceColor, palette.surface);
        assert.equal(form.surfaceEndColor, palette.surfaceEnd);
        assert.equal(form.inkColor, palette.ink);
        assert.equal(form.panelColor, palette.panel);
      }
      for (const dimension of [2, 3]) {
        const ids = dimension === 2 ? [1] : [1, 3];
        assert.deepEqual(businessFields(new MockFormData(quota, ids, dimension, preferences)),
          businessFields(new MockFormData(quota, ids, dimension)));
      }
      for (const days of [7, 30]) for (const metric of ['requests', 'cost']) {
        const form = { dimension: 4, days, metric, selectedIndex: 2 };
        assert.deepEqual(businessFields(new TrendFormData(snapshot, form, preferences)),
          businessFields(new TrendFormData(snapshot, form)));
      }
      assert.equal(forms[2].requestColor, palette.healthy);
      assert.equal(forms[2].costColor, palette.secondary);
    }
  }
});

test('all structures distinguish known zero from unknown and preserve cached data', () => {
  for (const style of CARD_STYLES) for (const paletteIndex of [0, 1, 2]) {
    const settings = { ...defaultCardPreferences(), theme: style.id, paletteIndex };
    const quota = createMockSnapshot('offline');
    quota.accounts[0].id = 1;
    quota.accounts[0].remaining = '0%';
    const zero = new MockFormData(quota, [1], 2, settings);
    assert.equal(zero.singleRingKnown, 'true');
    assert.equal(zero.singleRingValue, 0);
    assert.equal(zero.singleRemaining, '0%');
    assert.equal(zero.singleState, '连接失败');
    quota.accounts[0].remaining = '--';
    const unknown = new MockFormData(quota, [1], 2, settings);
    assert.equal(unknown.singleRingKnown, 'false');
    assert.equal(unknown.singleRemaining, '--');
    assert.equal(unknown.singleTimeLabel, quota.lastSuccessAt.slice(-5));
  }
});

test('visual paths preserve the existing plotted coordinates and never mutate chart data', () => {
  for (const days of [7, 30]) for (const metric of ['requests', 'cost']) {
    const chart = trendChart(history, days, metric, 3, snapshot.savedAt);
    const before = structuredClone(chart);
    const aurora = trendVisualPaths(chart, 'aurora', days);
    const pixel = trendVisualPaths(chart, 'pixel', days);
    const label = trendVisualPaths(chart, 'label', days);
    const points = days === 30 ? [...chart.line.matchAll(/[ML]([\d.]+),([\d.]+)/g)].map(m => [+m[1], +m[2]]) :
      [...`${chart.bars} ${chart.highlight}`.matchAll(/M([\d.]+),92 V([\d.]+) H([\d.]+)/g)]
        .map(m => [(+m[1] + +m[3]) / 2, +m[2]]).sort((a, b) => a[0] - b[0]);
    assert.deepEqual([...aurora.line.matchAll(/[ML]([\d.]+),([\d.]+)/g)].map(m => [+m[1], +m[2]]), points);
    assert.equal((pixel.line.match(/ V/g) || []).length, points.length - 1);
    assert.equal((label.stems.match(/M/g) || []).length, points.length);
    assert.ok(pixel.highlight.includes(`${points[3][0] - 2},${points[3][1] - 2}`));
    assert.deepEqual(chart, before);
  }
  const empty = trendChart([], 7, 'requests');
  for (const style of CARD_STYLES) {
    assert.deepEqual(trendVisualPaths(empty, style.id, 7), { line: '', area: '', marks: '', stems: '', highlight: '' });
  }
});

function luminance(hex) {
  const rgb = hex.slice(-6).match(/../g).map(v => Number.parseInt(v, 16) / 255)
    .map(v => v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4);
  return rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722;
}

test('small text and state colors stay readable on the opaque palette and gradient endpoints', () => {
  for (const style of CARD_STYLES) for (const paletteIndex of [0, 1, 2]) {
    const palette = cardPalette(style.id, 0, false, paletteIndex);
    for (const background of [palette.surface, palette.surfaceEnd, palette.panel]) {
      for (const role of ['ink', 'muted', 'healthy', 'secondary', 'warning', 'error']) {
        const a = luminance(background), b = luminance(palette[role]);
        assert.ok((Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05) >= 4.5,
          `${style.id}/${paletteIndex}/${role}`);
      }
    }
  }
});
