import { TrendWidgetData } from '../../model/TrendFormData';
import { TrendWidget } from '../../components/TrendWidget';

@Entry
@Component
struct TrendCard {
  @LocalStorageProp('dimension') dimension: string = 'medium';
  @LocalStorageProp('theme') theme: string = 'aurora';
  @LocalStorageProp('panelColor') panelColor: string = '#F7F7FC';
  @LocalStorageProp('textureColor') textureColor: string = '#4A4F91';
  @LocalStorageProp('highlightColor') highlightColor: string = '#FFFFFF';
  @LocalStorageProp('chartStyleLine') chartStyleLine: string = '';
  @LocalStorageProp('chartStyleArea') chartStyleArea: string = '';
  @LocalStorageProp('chartStyleMarks') chartStyleMarks: string = '';
  @LocalStorageProp('chartStyleStems') chartStyleStems: string = '';
  @LocalStorageProp('chartStyleHighlight') chartStyleHighlight: string = '';
  @LocalStorageProp('surfaceColor') surfaceColor: string = '#FFE8E9F7';
  @LocalStorageProp('surfaceEndColor') surfaceEndColor: string = '#FFF8DDD8';
  @LocalStorageProp('edgeColor') edgeColor: string = '#B9BFD5';
  @LocalStorageProp('shadowColor') shadowColor: string = '#18283541';
  @LocalStorageProp('inkColor') inkColor: string = '#29344F';
  @LocalStorageProp('mutedColor') mutedColor: string = '#555D78';
  @LocalStorageProp('lineColor') lineColor: string = '#B9BFD5';
  @LocalStorageProp('requestColor') requestColor: string = '#4A4F91';
  @LocalStorageProp('costColor') costColor: string = '#934E66';
  @LocalStorageProp('chipColor') chipColor: string = '#D8DDF1';
  @LocalStorageProp('accountName') accountName: string = '选择关注账号';
  @LocalStorageProp('statusLabel') statusLabel: string = '等待首次同步';
  @LocalStorageProp('days') days: number = 7;
  @LocalStorageProp('metric') metric: string = 'requests';
  @LocalStorageProp('totalRequests') totalRequests: string = '0';
  @LocalStorageProp('totalCost') totalCost: string = '$0.00';
  @LocalStorageProp('axisTop') axisTop: string = '0';
  @LocalStorageProp('axisMid') axisMid: string = '0';
  @LocalStorageProp('chartBars') chartBars: string = '';
  @LocalStorageProp('chartHighlight') chartHighlight: string = '';
  @LocalStorageProp('chartLine') chartLine: string = '';
  @LocalStorageProp('chartArea') chartArea: string = '';
  @LocalStorageProp('dateLabels') dateLabels: string[] = [];
  @LocalStorageProp('dayCount') dayCount: number = 0;
  @LocalStorageProp('barHeights') barHeights: number[] = [];
  @LocalStorageProp('selectedDayIndex') selectedDayIndex: number = -1;
  @LocalStorageProp('dayLabel') dayLabel: string = '--';
  @LocalStorageProp('dayValue') dayValue: string = '--';
  @LocalStorageProp('chartCaption') chartCaption: string = '每日请求';
  @LocalStorageProp('hasChart') hasChart: string = 'false';
  @LocalStorageProp('emptyLabel') emptyLabel: string = '暂无请求记录';
  @LocalStorageProp('lastUpdated') lastUpdated: string = '未更新';

  private viewData(): TrendWidgetData {
    return {
      dimension: this.dimension, theme: this.theme, panelColor: this.panelColor,
      textureColor: this.textureColor, highlightColor: this.highlightColor, chartStyleLine: this.chartStyleLine,
      chartStyleArea: this.chartStyleArea, chartStyleMarks: this.chartStyleMarks, chartStyleStems: this.chartStyleStems,
      chartStyleHighlight: this.chartStyleHighlight, surfaceColor: this.surfaceColor, surfaceEndColor: this.surfaceEndColor,
      edgeColor: this.edgeColor, shadowColor: this.shadowColor, inkColor: this.inkColor,
      mutedColor: this.mutedColor, lineColor: this.lineColor, requestColor: this.requestColor,
      costColor: this.costColor, chipColor: this.chipColor, accountName: this.accountName,
      statusLabel: this.statusLabel, days: this.days, metric: this.metric,
      totalRequests: this.totalRequests, totalCost: this.totalCost, axisTop: this.axisTop,
      axisMid: this.axisMid, chartBars: this.chartBars, chartHighlight: this.chartHighlight,
      chartLine: this.chartLine, chartArea: this.chartArea, dateLabels: this.dateLabels,
      dayCount: this.dayCount, barHeights: this.barHeights, selectedDayIndex: this.selectedDayIndex,
      dayLabel: this.dayLabel, dayValue: this.dayValue, chartCaption: this.chartCaption,
      hasChart: this.hasChart, emptyLabel: this.emptyLabel, lastUpdated: this.lastUpdated,
    };
  }

  build() {
    Stack() {
      TrendWidget({ data: this.viewData(),
      onCommand: (value: string) => postCardAction(this, { action: 'message', params: { command: value } }),
      onOpen: () => postCardAction(this, { action: 'router', abilityName: 'EntryAbility' }) })
    }.width('100%').height('100%')
  }
}
