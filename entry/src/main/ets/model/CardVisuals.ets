import { CardTheme } from './CardPreferences';
import { TrendChart } from './TrendStats';

interface ChartPoint {
  x: number;
  y: number;
}

export interface TrendVisualPaths {
  line: string;
  area: string;
  marks: string;
  stems: string;
  highlight: string;
}

function circlePath(point: ChartPoint, radius: number): string {
  return `M${point.x + radius},${point.y} A${radius},${radius} 0 1,0 ` +
    `${point.x - radius},${point.y} A${radius},${radius} 0 1,0 ${point.x + radius},${point.y} Z `;
}

// Restyle the already-calculated chart coordinates. Totals, dates, gaps and scale stay in TrendStats.
export function trendVisualPaths(chart: TrendChart, theme: CardTheme, days: number): TrendVisualPaths {
  const result: TrendVisualPaths = { line: '', area: '', marks: '', stems: '', highlight: '' };
  const points: ChartPoint[] = [];
  if (days === 30) {
    const matches = chart.line.match(/[ML][\d.]+,[\d.]+/g) || [];
    for (const match of matches) {
      const pair = match.slice(1).split(',');
      points.push({ x: Number(pair[0]), y: Number(pair[1]) });
    }
  } else {
    const matches = `${chart.bars} ${chart.highlight}`.match(/M[\d.]+,92 V[\d.]+ H[\d.]+/g) || [];
    for (const match of matches) {
      const values = match.match(/[\d.]+/g) || [];
      points.push({ x: (Number(values[0]) + Number(values[3])) / 2, y: Number(values[2]) });
    }
    points.sort((left: ChartPoint, right: ChartPoint) => left.x - right.x);
  }
  if (points.length === 0) return result;
  const active = points[Math.max(0, Math.min(points.length - 1, chart.selectedDayIndex))];
  if (theme === 'pixel') {
    result.line = `M${points[0].x},${points[0].y} ` + points.slice(1)
      .map((point: ChartPoint) => `H${point.x} V${point.y}`).join(' ');
    result.highlight = `M${active.x - 2},${active.y - 2} h4 v4 h-4 Z`;
  } else if (theme === 'label') {
    result.marks = points.map((point: ChartPoint) => circlePath(point, days === 30 ? 1.4 : 2.6)).join('');
    result.stems = points.map((point: ChartPoint) => `M${point.x},92 V${point.y}`).join(' ');
    result.highlight = circlePath(active, days === 30 ? 2.2 : 3.2);
  } else if (theme === 'aurora') {
    result.line = `M${points[0].x},${points[0].y} ` + points.slice(1)
      .map((point: ChartPoint) => `L${point.x},${point.y}`).join(' ');
    result.area = `${result.line} L${points[points.length - 1].x},92 L${points[0].x},92 Z`;
    result.highlight = circlePath(active, 3);
  }
  return result;
}

export function cardTexturePath(theme: string): string {
  let path = '';
  if (theme === 'chrome') {
    for (let y = 3; y < 300; y += 3) path += `M0,${y} H300 `;
  } else if (theme === 'pixel') {
    for (let y = 6; y < 300; y += 6) {
      for (let x = 6; x < 300; x += 6) path += `M${x},${y} h0.8 `;
    }
  }
  return path;
}
