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

const { normalizeAccountStats, trendChart } = require('../entry/src/main/ets/model/TrendStats.ets');
const { TrendFormData } = require('../entry/src/main/ets/model/TrendFormData.ets');

const history = Array.from({ length: 30 }, (_, index) => ({
  date: `2026-09-${String(index + 1).padStart(2, '0')}`,
  requests: index + 1,
  actual_cost: (index + 1) / 10,
  cost: 999,
  user_cost: 888,
  tokens: 12345
}));

test('D02 accepts only daily date, requests and account cost', () => {
  const days = normalizeAccountStats({ history });
  assert.deepEqual(days[0], { date: '2026-09-01', requests: 1, actualCost: 0.1 });
  assert.equal(days.length, 30);
  assert.equal(JSON.stringify(days).includes('user_cost'), false);
  assert.equal(JSON.stringify(days).includes('tokens'), false);
});

test('7-day columns and 30-day area use distinct period totals', () => {
  const days = normalizeAccountStats({ history });
  const seven = trendChart(days, 7, 'requests', -1, new Date(2026, 8, 30).getTime());
  assert.equal(seven.requests, '189');
  assert.equal(seven.cost, '$18.90');
  assert.equal(seven.labels.length, 7);
  assert.equal(seven.barHeights.length, 7);
  assert.equal(seven.barHeights[6], 100);
  assert.equal(seven.selectedDayIndex, 6);
  assert.equal(seven.line, '');
  assert.match(seven.bars, /M/);
  const thirty = trendChart(days, 30, 'cost', 0, new Date(2026, 8, 30).getTime());
  assert.equal(thirty.requests, '465');
  assert.equal(thirty.cost, '$46.50');
  assert.equal(thirty.date, '09.01');
  assert.equal(thirty.dayValue, '$0.10');
  assert.equal(thirty.labels.length, 5);
  assert.match(thirty.area, /Z$/);
  assert.equal(thirty.bars, '');
});

test('a sparse response fills calendar gaps instead of borrowing older activity', () => {
  const days = normalizeAccountStats({ history: [history[19], history[27]] });
  const seven = trendChart(days, 7, 'requests', -1, new Date(2026, 8, 30).getTime());
  assert.equal(seven.requests, '28');
  assert.equal(seven.cost, '$2.80');
  assert.equal(seven.dayCount, 7);
  assert.deepEqual(seven.labels, ['09.24', '09.25', '09.26', '09.27', '09.28', '09.29', '09.30']);
  assert.equal(seven.dayValue, '0 次');
});

test('missing, duplicate or invalid daily values are rejected', () => {
  assert.throws(() => normalizeAccountStats({ history: [{ ...history[0], actual_cost: undefined }] }));
  assert.throws(() => normalizeAccountStats({ history: [history[0], history[0]] }));
  assert.throws(() => normalizeAccountStats({ history: [{ ...history[0], requests: -1 }] }));
  assert.throws(() => normalizeAccountStats({ history: [{ ...history[0], date: '2026-02-30' }] }));
});

test('form binding keeps the requested size, metric and selected day', () => {
  const snapshot = { accountId: 3, accountName: '示例账号', history: normalizeAccountStats({ history }),
    savedAt: new Date(2026, 8, 30, 8, 0).getTime(), status: 'ready', notice: '' };
  const form = { id: 'test-form', dimension: 4, days: 30, metric: 'cost', selectedIndex: 0 };
  const data = new TrendFormData(snapshot, form);
  assert.equal(data.dimension, 'large');
  assert.equal(data.totalCost, '$46.50');
  assert.equal(data.dayLabel, '09.01');
  assert.equal(data.dayValue, '$0.10');
  assert.equal(data.chartCaption, '每日账号费用');
  assert.equal(data.hasChart, 'true');
  assert.equal(data.statusLabel, '更新于 08:00');
});

test('failed refresh keeps last chart and presents the failure', () => {
  const snapshot = { accountId: 3, accountName: '示例账号', history: normalizeAccountStats({ history }),
    savedAt: Date.UTC(2026, 8, 30), status: 'offline', notice: '连接失败 · 上次数据' };
  const data = new TrendFormData(snapshot,
    { id: 'test-form', dimension: 3, days: 7, metric: 'requests', selectedIndex: -1 });
  assert.equal(data.hasChart, 'true');
  assert.equal(data.statusLabel, '同步失败 · 上次数据');
  assert.equal(data.totalRequests, '189');
});
