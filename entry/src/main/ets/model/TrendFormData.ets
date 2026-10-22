import { trendVisualPaths, TrendVisualPaths } from './CardVisuals';
import { CardPreferences, cardPalette, defaultCardPreferences } from './CardPreferences';
import { TrendChart, TrendSnapshot, trendChart } from './TrendStats';
import { TrendFormView } from '../storage/TrendFormRegistry';

export interface TrendWidgetData {
  dimension: string;
  theme: string;
  panelColor: string;
  textureColor: string;
  highlightColor: string;
  chartStyleLine: string;
  chartStyleArea: string;
  chartStyleMarks: string;
  chartStyleStems: string;
  chartStyleHighlight: string;
  surfaceColor: string;
  surfaceEndColor: string;
  edgeColor: string;
  shadowColor: string;
  inkColor: string;
  mutedColor: string;
  lineColor: string;
  requestColor: string;
  costColor: string;
  chipColor: string;
  accountName: string;
  statusLabel: string;
  days: number;
  metric: string;
  totalRequests: string;
  totalCost: string;
  axisTop: string;
  axisMid: string;
  chartBars: string;
  chartHighlight: string;
  chartLine: string;
  chartArea: string;
  dateLabels: string[];
  dayCount: number;
  barHeights: number[];
  selectedDayIndex: number;
  dayLabel: string;
  dayValue: string;
  chartCaption: string;
  hasChart: string;
  emptyLabel: string;
  lastUpdated: string;
}

export class TrendFormData implements TrendWidgetData {
  dimension: string = 'medium';
  theme: string = 'aurora';
  panelColor: string = '';
  textureColor: string = '';
  highlightColor: string = '';
  chartStyleLine: string = '';
  chartStyleArea: string = '';
  chartStyleMarks: string = '';
  chartStyleStems: string = '';
  chartStyleHighlight: string = '';
  surfaceColor: string = '#FFF9FBFA';
  surfaceEndColor: string = '#FFF9FBFA';
  edgeColor: string = '#00000000';
  shadowColor: string = '#00000000';
  inkColor: string = '#24332F';
  mutedColor: string = '#64746E';
  lineColor: string = '#DCE5E0';
  requestColor: string = '#187B59';
  costColor: string = '#C3654F';
  chipColor: string = '#EAF2EE';
  accountName: string = '选择关注账号';
  statusLabel: string = '等待首次同步';
  days: number = 7;
  metric: string = 'requests';
  totalRequests: string = '0';
  totalCost: string = '$0.00';
  axisTop: string = '0';
  axisMid: string = '0';
  chartBars: string = '';
  chartHighlight: string = '';
  chartLine: string = '';
  chartArea: string = '';
  dateLabels: string[] = [];
  dayCount: number = 0;
  barHeights: number[] = [];
  selectedDayIndex: number = -1;
  dayLabel: string = '--';
  dayValue: string = '--';
  chartCaption: string = '每日请求';
  hasChart: string = 'false';
  emptyLabel: string = '暂无请求记录';
  lastUpdated: string = '未更新';

  constructor(snapshot: TrendSnapshot, form: TrendFormView,
    settings: CardPreferences = defaultCardPreferences(), darkMode: boolean = false) {
    this.dimension = form.dimension === 4 ? 'large' : 'medium';
    this.days = form.days;
    this.metric = form.metric;
    this.theme = settings.theme;
    const palette = cardPalette(settings.theme, settings.transparency, darkMode, settings.paletteIndex);
    this.panelColor = palette.panel;
    this.textureColor = palette.texture;
    this.highlightColor = palette.highlight;
    this.surfaceColor = palette.surface;
    this.surfaceEndColor = palette.surfaceEnd;
    this.edgeColor = palette.edge;
    this.shadowColor = palette.shadow;
    this.inkColor = palette.ink;
    this.mutedColor = palette.muted;
    this.lineColor = palette.line;
    this.requestColor = palette.healthy;
    this.costColor = palette.secondary;
    this.chipColor = palette.chip;
    this.accountName = snapshot.accountName || (snapshot.accountId ? `账号 #${snapshot.accountId}` : '选择关注账号');
    this.lastUpdated = snapshot.savedAt ? `${new Date(snapshot.savedAt).getHours().toString().padStart(2, '0')}:` +
      `${new Date(snapshot.savedAt).getMinutes().toString().padStart(2, '0')}` : '未更新';
    const age = Date.now() - snapshot.savedAt;
    this.statusLabel = snapshot.status === 'ready' ?
      age >= 0 && age < 60 * 1000 ? '刚刚更新' : `更新于 ${this.lastUpdated}` :
      snapshot.status === 'waiting' ? '等待首次同步' :
        snapshot.status === 'offline' ? (snapshot.history.length > 0 ? '同步失败 · 上次数据' : '同步失败') :
          snapshot.notice;
    const chart: TrendChart = trendChart(snapshot.history, form.days, form.metric,
      form.selectedIndex, snapshot.savedAt);
    const visual: TrendVisualPaths = trendVisualPaths(chart, settings.theme, form.days);
    this.chartStyleLine = visual.line;
    this.chartStyleArea = visual.area;
    this.chartStyleMarks = visual.marks;
    this.chartStyleStems = visual.stems;
    this.chartStyleHighlight = visual.highlight;
    this.totalRequests = chart.requests;
    this.totalCost = chart.cost;
    this.axisTop = chart.axisTop;
    this.axisMid = chart.axisMid;
    this.chartBars = chart.bars;
    this.chartHighlight = chart.highlight;
    this.chartLine = chart.line;
    this.chartArea = chart.area;
    this.dateLabels = chart.labels;
    this.dayCount = chart.dayCount;
    this.barHeights = chart.barHeights;
    this.selectedDayIndex = chart.selectedDayIndex;
    this.dayLabel = chart.date;
    this.dayValue = chart.dayValue;
    this.chartCaption = form.metric === 'cost' ? '每日账号费用' : '每日请求';
    this.hasChart = !chart.empty && snapshot.history.length > 0 ? 'true' : 'false';
    this.emptyLabel = snapshot.accountId === 0 ? '请在应用内选择账号' :
      snapshot.status === 'auth' || snapshot.status === 'offline' && snapshot.history.length === 0 ?
        snapshot.notice : '这段时间暂无请求记录';
  }
}
