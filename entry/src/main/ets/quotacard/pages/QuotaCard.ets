import { QuotaWidgetData } from '../../model/MockQuota';
import { QuotaWidget } from '../../components/QuotaWidget';

@Entry
@Component
struct QuotaCard {
  @LocalStorageProp('dimension') dimension: string = 'dual';
  @LocalStorageProp('cardTitle') cardTitle: string = 'Sub2API';
  @LocalStorageProp('theme') theme: string = 'aurora';
  @LocalStorageProp('chipColor') chipColor: string = '#D8DDF1';
  @LocalStorageProp('panelColor') panelColor: string = '#F7F7FC';
  @LocalStorageProp('textureColor') textureColor: string = '#4A4F91';
  @LocalStorageProp('highlightColor') highlightColor: string = '#FFFFFF';
  @LocalStorageProp('surfaceColor') surfaceColor: string = '#FFE8E9F7';
  @LocalStorageProp('surfaceEndColor') surfaceEndColor: string = '#FFF8DDD8';
  @LocalStorageProp('edgeColor') edgeColor: string = '#B9BFD5';
  @LocalStorageProp('shadowColor') shadowColor: string = '#18283541';
  @LocalStorageProp('inkColor') inkColor: string = '#29344F';
  @LocalStorageProp('mutedColor') mutedColor: string = '#555D78';
  @LocalStorageProp('lineColor') lineColor: string = '#B9BFD5';
  @LocalStorageProp('healthyColor') healthyColor: string = '#4A4F91';
  @LocalStorageProp('warningColor') warningColor: string = '#80500D';
  @LocalStorageProp('errorColor') errorColor: string = '#A1324A';
  @LocalStorageProp('statusLabel') statusLabel: string = '';
  @LocalStorageProp('statusTone') statusTone: string = '';
  @LocalStorageProp('notice') notice: string = '';
  @LocalStorageProp('abnormalLabel') abnormalLabel: string = '';
  @LocalStorageProp('timeLabel') timeLabel: string = '';
  @LocalStorageProp('singleTimeLabel') singleTimeLabel: string = '未更新';
  @LocalStorageProp('hasAccounts') hasAccounts: string = '';
  @LocalStorageProp('firstName') firstName: string = '';
  @LocalStorageProp('firstMeta') firstMeta: string = '';
  @LocalStorageProp('firstRemaining') firstRemaining: string = '';
  @LocalStorageProp('firstState') firstState: string = '';
  @LocalStorageProp('firstTone') firstTone: string = '';
  @LocalStorageProp('secondName') secondName: string = '';
  @LocalStorageProp('secondMeta') secondMeta: string = '';
  @LocalStorageProp('secondRemaining') secondRemaining: string = '';
  @LocalStorageProp('secondState') secondState: string = '';
  @LocalStorageProp('secondTone') secondTone: string = '';
  @LocalStorageProp('singleName') singleName: string = '';
  @LocalStorageProp('singleMeta') singleMeta: string = '';
  @LocalStorageProp('singleRemaining') singleRemaining: string = '--';
  @LocalStorageProp('singleState') singleState: string = '';
  @LocalStorageProp('singleTone') singleTone: string = 'unknown';
  @LocalStorageProp('singleRingValue') singleRingValue: number = 0;
  @LocalStorageProp('singleRingKnown') singleRingKnown: string = 'false';

  private viewData(): QuotaWidgetData {
    return {
      dimension: this.dimension, cardTitle: this.cardTitle, theme: this.theme,
      chipColor: this.chipColor, panelColor: this.panelColor, textureColor: this.textureColor,
      highlightColor: this.highlightColor, surfaceColor: this.surfaceColor, surfaceEndColor: this.surfaceEndColor,
      edgeColor: this.edgeColor, shadowColor: this.shadowColor, inkColor: this.inkColor,
      mutedColor: this.mutedColor, lineColor: this.lineColor, healthyColor: this.healthyColor,
      warningColor: this.warningColor, errorColor: this.errorColor, statusLabel: this.statusLabel,
      statusTone: this.statusTone, notice: this.notice, abnormalLabel: this.abnormalLabel,
      timeLabel: this.timeLabel, singleTimeLabel: this.singleTimeLabel, hasAccounts: this.hasAccounts,
      firstName: this.firstName, firstMeta: this.firstMeta, firstRemaining: this.firstRemaining,
      firstState: this.firstState, firstTone: this.firstTone, secondName: this.secondName,
      secondMeta: this.secondMeta, secondRemaining: this.secondRemaining, secondState: this.secondState,
      secondTone: this.secondTone, singleName: this.singleName, singleMeta: this.singleMeta,
      singleRemaining: this.singleRemaining, singleState: this.singleState, singleTone: this.singleTone,
      singleRingValue: this.singleRingValue, singleRingKnown: this.singleRingKnown,
    };
  }

  build() {
    Stack() {
      QuotaWidget({ data: this.viewData(),
      onRefresh: () => postCardAction(this, { action: 'message', params: { command: 'refresh' } }),
      onOpen: () => postCardAction(this, { action: 'router', abilityName: 'EntryAbility' }) })
    }.width('100%').height('100%')
  }
}
