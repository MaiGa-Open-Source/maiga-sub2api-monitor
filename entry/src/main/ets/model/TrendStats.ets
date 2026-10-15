export type TrendMetric = 'requests' | 'cost';
export type TrendStatus = 'ready' | 'waiting' | 'offline' | 'auth' | 'empty';

export interface TrendDay {
  date: string;
  requests: number;
  actualCost: number;
}

export interface AccountStatsHistoryRow {
  date: string;
  requests: number;
  actual_cost: number;
}

export interface AccountStatsResponse {
  history: AccountStatsHistoryRow[];
}

export interface TrendSnapshot {
  accountId: number;
  accountName: string;
  history: TrendDay[];
  savedAt: number;
  status: TrendStatus;
  notice: string;
}

export interface TrendChart {
  requests: string;
  cost: string;
  date: string;
  dayValue: string;
  axisTop: string;
  axisMid: string;
  labels: string[];
  dayCount: number;
  barHeights: number[];
  selectedDayIndex: number;
  bars: string;
  highlight: string;
  line: string;
  area: string;
  empty: boolean;
}

export function normalizeAccountStats(data: AccountStatsResponse): TrendDay[] {
  if (!data || !Array.isArray(data.history) || data.history.length > 31) {
    throw new Error('INVALID_TREND_HISTORY');
  }
  const days: TrendDay[] = [];
  const seen = new Set<string>();
  for (const row of data.history) {
    if (!row || typeof row.date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(row.date) ||
      new Date(`${row.date}T00:00:00Z`).toISOString().slice(0, 10) !== row.date ||
      !Number.isSafeInteger(row.requests) || row.requests < 0 ||
      !Number.isFinite(row.actual_cost) || row.actual_cost < 0 || seen.has(row.date)) {
      throw new Error('INVALID_TREND_HISTORY');
    }
    seen.add(row.date);
    days.push({ date: row.date, requests: row.requests, actualCost: row.actual_cost });
  }
  return days.sort((left: TrendDay, right: TrendDay) => left.date.localeCompare(right.date)).slice(-30);
}

export function formatTrendMoney(amount: number): string {
  return `$${amount.toFixed(2)}`;
}

function axisLabel(value: number, metric: TrendMetric): string {
  return metric === 'cost' ? `$${value.toFixed(value >= 10 ? 0 : 1)}` : `${Math.round(value)}`;
}

export function trendChart(history: TrendDay[], period: number, metric: TrendMetric,
  selectedIndex: number = -1, asOf: number = Date.now()): TrendChart {
  const count = period === 30 ? 30 : 7;
  const localDate = new Date(asOf);
  const current = `${localDate.getFullYear()}-${String(localDate.getMonth() + 1).padStart(2, '0')}-` +
    `${String(localDate.getDate()).padStart(2, '0')}`;
  const latest = history.length > 0 ? history[history.length - 1].date : current;
  const end = new Date(`${latest > current ? latest : current}T00:00:00Z`).getTime();
  const byDate = new Map<string, TrendDay>(history.map((day: TrendDay): [string, TrendDay] =>
    [day.date, day]));
  const days: TrendDay[] = [];
  if (history.length > 0) {
    for (let index = 0; index < count; index++) {
      const date = new Date(end - (count - index - 1) * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
      days.push(byDate.get(date) || { date: date, requests: 0, actualCost: 0 });
    }
  }
  const totalRequests = days.reduce((sum: number, day: TrendDay) => sum + day.requests, 0);
  const totalCost = days.reduce((sum: number, day: TrendDay) => sum + day.actualCost, 0);
  const active = selectedIndex >= 0 && selectedIndex < days.length ? selectedIndex : days.length - 1;
  const value = (day: TrendDay): number => metric === 'cost' ? day.actualCost : day.requests;
  let largest = 1;
  for (const day of days) largest = Math.max(largest, value(day));
  const maximum = largest * 1.12;
  const left = 12;
  const width = 278;
  const top = 8;
  const bottom = 92;
  const x = (index: number): number => left + (index + 0.5) * width / Math.max(1, days.length);
  const y = (amount: number): number => bottom - amount / maximum * (bottom - top);
  const point = (index: number): string => `${x(index).toFixed(1)},${y(value(days[index])).toFixed(1)}`;
  let bars = '';
  let highlight = '';
  let line = '';
  let area = '';
  if (period !== 30 && days.length > 0) {
    const barWidth = Math.min(28, width / days.length - 10);
    days.forEach((day: TrendDay, index: number) => {
      const leftBar = (x(index) - barWidth / 2).toFixed(1);
      const topBar = y(value(day)).toFixed(1);
      const path = `M${leftBar},${bottom} V${topBar} H${(x(index) + barWidth / 2).toFixed(1)} V${bottom} Z `;
      if (index === active) highlight = path;
      else bars += path;
    });
  } else if (days.length > 0) {
    line = `M${point(0)} ` + days.slice(1).map((_day: TrendDay, index: number) =>
      `L${point(index + 1)}`).join(' ');
    area = `${line} L${x(days.length - 1).toFixed(1)},${bottom} L${x(0).toFixed(1)},${bottom} Z`;
    const cx = x(active).toFixed(1);
    const cy = y(value(days[active])).toFixed(1);
    highlight = `M${(x(active) + 4).toFixed(1)},${cy} A4,4 0 1,0 ${(x(active) - 4).toFixed(1)},${cy} A4,4 0 1,0 ${(x(active) + 4).toFixed(1)},${cy} Z`;
  }
  const labelIndices = period === 30 ? [0, 7, 14, 21, Math.max(0, days.length - 1)] :
    days.map((_day: TrendDay, index: number) => index);
  const labels = labelIndices.filter((index: number, position: number) => index < days.length &&
    labelIndices.indexOf(index) === position).map((index: number) => days[index].date.slice(5).replace('-', '.'));
  const selected = days[active];
  return {
    requests: totalRequests.toLocaleString('en-US'), cost: formatTrendMoney(totalCost),
    date: selected ? selected.date.slice(5).replace('-', '.') : '--',
    dayValue: selected ? (metric === 'cost' ? formatTrendMoney(selected.actualCost) : `${selected.requests} 次`) : '--',
    axisTop: axisLabel(maximum, metric), axisMid: axisLabel(maximum / 2, metric), labels: labels,
    dayCount: days.length,
    barHeights: days.map((day: TrendDay): number => Math.round(value(day) / largest * 100)),
    selectedDayIndex: active,
    bars: bars, highlight: highlight, line: line, area: area,
    empty: totalRequests === 0 && totalCost === 0
  };
}
