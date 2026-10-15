import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { AccountPreview, QuotaSnapshot } from '../model/MockQuota';
import { CardAppearance, CardPreferences, CardTheme, cardPalette,
  normalizeCardPreferences } from '../model/CardPreferences';
import { loadCardPreferences, saveCardPreferences } from '../storage/CardPreferencesStore';
import { loadFeaturedIds, loadSingleId, loadSnapshot, saveFeaturedIds,
  saveSingleId } from '../storage/QuotaSnapshotStore';
import { loadConfigSummary } from '../storage/LocalConfig';
import { publishCurrentForms } from '../model/FormPublisher';
import { refreshQuota, unconfiguredSnapshot, waitingSnapshot } from '../model/QuotaRefresh';
import { publishTrendForms } from '../model/TrendFormPublisher';
import { TrendFormData } from '../model/TrendFormData';
import { currentTrend, emptyTrend, refreshTrend } from '../model/TrendRefresh';
import { TrendMetric, TrendSnapshot } from '../model/TrendStats';
import { loadTrendAccountId, saveTrendAccountId } from '../storage/TrendStore';

@Entry
@Component
struct CardSettings {
  @State private tab: string = 'data';
  @State private previewMode: string = 'dual';
  @State private trendDimension: number = 4;
  @State private trendDays: number = 7;
  @State private trendMetric: TrendMetric = 'requests';
  @State private trendIndex: number = -1;
  @State private trendAccountId: number = 0;
  @State private query: string = '';
  @State private trend: TrendSnapshot = emptyTrend();
  @State private title: string = 'Sub2API';
  @State private theme: CardTheme = 'pine';
  @State private appearance: CardAppearance = 'system';
  @State private transparency: number = 0;
  @State private previewDark: boolean = false;
  @State private cardPeriodMinutes: number = 60;
  @State private autoIntervalText: string = '60';
  @State private failureBackoffMinutes: number = 15;
  @State private featuredIds: number[] = [];
  @State private singleId: number = 0;
  @State private snapshot: QuotaSnapshot = unconfiguredSnapshot();
  @State private saving: boolean = false;
  @State private readingAccounts: boolean = false;
  @State private refreshingTrend: boolean = false;
  @State private feedback: string = '';
  private originalFeatured: string = '';
  private originalSingle: number = 0;
  private originalTrend: number = 0;

  onPageShow(): void {
    const context = getContext(this) as common.UIAbilityContext;
    const settings = loadCardPreferences(context);
    this.title = settings.title;
    this.theme = settings.theme;
    this.appearance = settings.appearance;
    this.transparency = settings.transparency;
    this.previewDark = settings.appearance === 'dark' || (settings.appearance === 'system' &&
      context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    this.cardPeriodMinutes = settings.cardPeriodMinutes;
    this.autoIntervalText = `${settings.autoIntervalMinutes}`;
    this.failureBackoffMinutes = settings.failureBackoffMinutes;
    this.featuredIds = loadFeaturedIds(context);
    this.singleId = loadSingleId(context);
    this.trendAccountId = loadTrendAccountId(context);
    this.originalTrend = this.trendAccountId;
    this.trend = currentTrend(context);
    this.originalFeatured = JSON.stringify(this.featuredIds);
    this.originalSingle = this.singleId;
    const connection = loadConfigSummary(context);
    this.snapshot = connection.hasKey ?
      loadSnapshot(context, connection.serviceUrl, connection.revision, false) || waitingSnapshot() :
      unconfiguredSnapshot();
    if (connection.hasKey && this.snapshot.accounts.length === 0) this.refreshAccounts();
  }

  private previewPreferences(): CardPreferences {
    return normalizeCardPreferences({ title: this.title, theme: this.theme,
      appearance: this.appearance, transparency: this.transparency,
      cardPeriodMinutes: this.cardPeriodMinutes,
      autoIntervalMinutes: Number(this.autoIntervalText) || 60,
      failureBackoffMinutes: this.failureBackoffMinutes });
  }

  private trendName(): string {
    return this.snapshot.accounts.find((account: AccountPreview) => account.id === this.trendAccountId)?.name ||
      (this.trendAccountId ? `账号 #${this.trendAccountId}` : '选择关注账号');
  }

  private trendPreviewData(): TrendFormData {
    const snapshot = this.trendAccountId === this.trend.accountId ? this.trend :
      emptyTrend(this.trendAccountId, this.trendName());
    return new TrendFormData(snapshot, { id: 'preview', dimension: this.trendDimension,
      days: this.trendDays, metric: this.trendMetric, selectedIndex: this.trendIndex },
      this.previewPreferences(), this.previewDark);
  }

  private accountResults(): AccountPreview[] {
    const needle = this.query.trim().toLowerCase();
    return this.snapshot.accounts.filter((account: AccountPreview) => !needle ||
      account.name.toLowerCase().includes(needle) || account.platform.toLowerCase().includes(needle) ||
      account.region.toLowerCase().includes(needle))
      .slice(0, 60);
  }

  private async refreshAccounts(): Promise<void> {
    if (this.readingAccounts || this.saving) return;
    this.readingAccounts = true;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.snapshot = await refreshQuota(context, 'manual');
      await publishCurrentForms(context, this.snapshot);
      this.feedback = this.snapshot.accounts.length ? '' : this.snapshot.notice;
    } catch (_error) {
      this.feedback = '账号列表读取失败';
    } finally {
      this.readingAccounts = false;
    }
  }

  private async refreshTrendData(): Promise<void> {
    if (this.refreshingTrend || this.saving) return;
    if (!this.trendAccountId || this.trendAccountId !== this.originalTrend) {
      this.feedback = '请先保存趋势卡关注账号';
      return;
    }
    this.refreshingTrend = true;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.trend = await refreshTrend(context, 'manual');
      await publishTrendForms(context, this.trend);
      this.feedback = this.trend.status === 'ready' ? '趋势已更新' : this.trend.notice;
    } catch (_error) {
      this.feedback = '趋势刷新失败，请重试';
    } finally {
      this.refreshingTrend = false;
    }
  }

  private paletteColor(role: string): string {
    const palette = cardPalette(this.theme, this.transparency, this.previewDark);
    if (role === 'surface') return palette.surface;
    if (role === 'surfaceEnd') return palette.surfaceEnd;
    if (role === 'edge') return palette.edge;
    if (role === 'shadow') return palette.shadow;
    if (role === 'ink') return palette.ink;
    if (role === 'muted') return palette.muted;
    if (role === 'line') return palette.line;
    if (role === 'warning') return palette.warning;
    if (role === 'error') return palette.error;
    return palette.healthy;
  }

  private previewAccount(): AccountPreview | undefined {
    const id = this.previewMode === 'single' ? this.singleId : this.featuredIds[0];
    return this.snapshot.accounts.find((account: AccountPreview) => account.id === id);
  }

  private accountTone(account: AccountPreview | undefined): string {
    return !account || account.health === 'unknown' || account.health === 'low' ?
      this.paletteColor('warning') : account.health === 'unavailable' ?
        this.paletteColor('error') : this.paletteColor('healthy');
  }

  private ringValue(account: AccountPreview | undefined): number {
    const match = account ? /^(100|[1-9]?\d)%$/.exec(account.remaining) : undefined;
    return match ? Number(match[1]) : 0;
  }

  private ringKnown(account: AccountPreview | undefined): boolean {
    return account !== undefined && /^(100|[1-9]?\d)%$/.test(account.remaining);
  }

  private toggleFeatured(id: number): void {
    if (this.featuredIds.includes(id)) {
      this.featuredIds = this.featuredIds.filter((value: number) => value !== id);
    } else if (this.featuredIds.length < 2) {
      this.featuredIds = [...this.featuredIds, id];
    }
    this.feedback = '';
  }

  private setAppearance(value: CardAppearance): void {
    this.appearance = value;
    const context = getContext(this) as common.UIAbilityContext;
    this.previewDark = value === 'dark' || (value === 'system' &&
      context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    this.feedback = '';
  }

  private async save(): Promise<void> {
    if (this.saving || this.readingAccounts || this.refreshingTrend) return;
    const rawInterval = Number(this.autoIntervalText);
    if (!Number.isInteger(rawInterval) || rawInterval < 1 || rawInterval > 1440) {
      this.feedback = '自动请求间隔请输入 1 至 1440 分钟的整数';
      return;
    }
    this.saving = true;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await saveCardPreferences(context, normalizeCardPreferences({
        title: this.title, theme: this.theme, appearance: this.appearance,
        transparency: this.transparency,
        cardPeriodMinutes: this.cardPeriodMinutes, autoIntervalMinutes: rawInterval,
        failureBackoffMinutes: this.failureBackoffMinutes
      }));
      const selectionChanged = this.originalFeatured !== JSON.stringify(this.featuredIds) ||
        this.originalSingle !== this.singleId;
      const trendChanged = this.originalTrend !== this.trendAccountId;
      if (this.originalFeatured !== JSON.stringify(this.featuredIds)) {
        await saveFeaturedIds(context, this.featuredIds);
      }
      if (this.originalSingle !== this.singleId) {
        await saveSingleId(context, this.singleId);
      }
      if (trendChanged) await saveTrendAccountId(context, this.trendAccountId);
      this.originalFeatured = JSON.stringify(this.featuredIds);
      this.originalSingle = this.singleId;
      this.originalTrend = this.trendAccountId;
      const connection = loadConfigSummary(context);
      if (selectionChanged && connection.hasKey) {
        this.snapshot = await refreshQuota(context, 'selection');
      }
      this.trend = trendChanged && connection.hasKey && this.trendAccountId > 0 ?
        await refreshTrend(context, 'selection') : currentTrend(context);
      await publishCurrentForms(context, this.snapshot);
      await publishTrendForms(context, this.trend);
      this.feedback = trendChanged && this.trend.status !== 'ready' && this.trendAccountId > 0 ?
        `方案已保存 · ${this.trend.notice}` : '方案已保存';
    } catch (_error) {
      this.feedback = '保存失败，请重试';
    } finally {
      this.saving = false;
    }
  }

  @Builder
  private tabButton(label: string, value: string) {
    Button(label)
      .fontSize(14)
      .fontColor(this.tab === value ? Color.White : $r('app.color.quota_ink'))
      .backgroundColor(this.tab === value ? $r('app.color.quota_healthy') : Color.Transparent)
      .borderRadius(6)
      .layoutWeight(1)
      .onClick(() => { this.tab = value; })
  }

  @Builder
  private option(label: string, group: string, value: string) {
    Button(label)
      .fontSize(13)
      .fontColor(this.optionSelected(group, value) ? Color.White : $r('app.color.quota_ink'))
      .backgroundColor(this.optionSelected(group, value) ?
        $r('app.color.quota_healthy') : $r('app.color.quota_surface'))
      .borderRadius(6)
      .layoutWeight(1).height(38)
      .onClick(() => this.selectOption(group, value))
  }

  private optionSelected(group: string, value: string): boolean {
    if (group === 'mode') return this.previewMode === value;
    if (group === 'period') return this.cardPeriodMinutes === Number(value);
    if (group === 'backoff') return this.failureBackoffMinutes === Number(value);
    if (group === 'appearance') return this.appearance === value;
    return this.trendDimension === Number(value);
  }

  private selectOption(group: string, value: string): void {
    if (group === 'mode') this.previewMode = value;
    else if (group === 'period') this.cardPeriodMinutes = Number(value);
    else if (group === 'backoff') this.failureBackoffMinutes = Number(value);
    else if (group === 'appearance') this.setAppearance(value as CardAppearance);
    else this.trendDimension = Number(value);
  }

  @Builder
  private themeOption(name: CardTheme, label: string) {
    Button(label)
      .fontSize(13)
      .fontColor(cardPalette(name, 0, this.previewDark).ink)
      .backgroundColor(name === 'glass' ?
        (this.previewDark ? '#324A50' : '#D8E7E4') : cardPalette(name, 0).surface)
      .border({ width: this.theme === name ? 2 : 1,
        color: this.theme === name ? $r('app.color.quota_healthy') : $r('app.color.quota_line') })
      .borderRadius(6)
      .layoutWeight(1)
      .height(42)
      .onClick(() => { this.theme = name; })
  }

  @Builder
  private previewIcon(symbol: string, color: string) {
    Text(symbol)
      .fontSize(22).fontColor(Color.White).textAlign(TextAlign.Center)
      .width(42).height(42).backgroundColor(color).borderRadius(10)
  }

  @Builder
  private previewWallpaper() {
    Column() {
      Row() {
        this.previewIcon('✦', '#BD695F')
        Blank()
        this.previewIcon('◉', '#467D96')
        Blank()
        this.previewIcon('▦', '#557C69')
        Blank()
        this.previewIcon('♪', '#AD805A')
      }
      .width('100%')
      Blank()
      Row() {
        this.previewIcon('◈', '#659B91')
        Blank()
        this.previewIcon('✳', '#AB707A')
        Blank()
        this.previewIcon('⚙', '#6F7985')
        Blank()
        this.previewIcon('◎', '#9A727D')
      }
      .width('100%')
    }
    .width('100%').height('100%').padding(9)
  }

  @Builder
  private preview() {
    Column({ space: 7 }) {
      Row() {
        Text(this.title.trim() || 'Sub2API')
          .fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.paletteColor('ink'))
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
        Text(this.snapshot.statusLabel)
          .fontSize(10).fontColor(this.paletteColor('warning')).maxLines(1)
      }
      .width('100%')
      if (this.previewMode === 'single') {
        Text(this.previewAccount()?.name || '选择单账号')
          .fontSize(12).fontColor(this.paletteColor('ink')).width('100%').maxLines(1)
        Stack({ alignContent: Alignment.Center }) {
          if (this.ringKnown(this.previewAccount())) {
            Progress({ value: this.ringValue(this.previewAccount()), total: 100, type: ProgressType.Ring })
              .color(this.accountTone(this.previewAccount()))
              .backgroundColor(this.paletteColor('line'))
              .style({ strokeWidth: 8 }).width(82).height(82)
          } else {
            Column().width(82).height(82)
              .border({ width: 8, color: this.paletteColor('line'), style: BorderStyle.Dashed })
              .borderRadius(41)
          }
          Column({ space: 2 }) {
            Text(this.previewAccount()?.remaining || '--')
              .fontSize(23).fontWeight(FontWeight.Bold)
              .fontColor(this.accountTone(this.previewAccount()))
            Text(this.ringKnown(this.previewAccount()) ? '剩余额度' : '额度未知')
              .fontSize(9).fontColor(this.paletteColor('muted'))
          }
        }
        .width('100%').height(88)
        Text(this.previewAccount()?.stateLabel || '待选择')
          .fontSize(10).fontColor(this.accountTone(this.previewAccount()))
          .width('100%')
      } else {
        ForEach(this.featuredIds, (id: number) => {
          Row() {
            Text(this.snapshot.accounts.find((item: AccountPreview) => item.id === id)?.name || '账号待同步')
              .fontSize(12).fontColor(this.paletteColor('ink')).layoutWeight(1).maxLines(1)
            Text(this.snapshot.accounts.find((item: AccountPreview) => item.id === id)?.remaining || '--')
              .fontSize(17).fontWeight(FontWeight.Bold).fontColor(this.paletteColor('healthy'))
          }
          .width('100%').height(43)
          .border({ width: { bottom: 1 }, color: this.paletteColor('line') })
        }, (id: number) => `${id}`)
        if (this.featuredIds.length < 2) {
          Text('选择双账号卡片关注的账号')
            .fontSize(12).fontColor(this.paletteColor('muted'))
            .height(43).width('100%')
        }
        Text(this.snapshot.lastSuccessAt ? `上次成功 ${this.snapshot.lastSuccessAt}` : '尚无成功数据')
          .fontSize(10).fontColor(this.paletteColor('muted')).width('100%')
      }
    }
    .padding(13)
    .width(this.previewMode === 'single' ? 184 : '100%')
    .height(this.previewMode === 'single' ? 184 : 184)
    .backgroundColor(this.paletteColor('surface'))
    .linearGradient({ angle: 135, colors: [[this.paletteColor('surface'), 0],
      [this.paletteColor('surfaceEnd'), 1]] })
    .border({ width: this.theme === 'glass' ? 1 : 0, color: this.paletteColor('edge') })
    .shadow({ radius: this.theme === 'glass' ? 16 : 0, color: this.paletteColor('shadow') })
    .borderRadius(8)
  }

  @Builder
  private trendMetricButton(label: string, metric: TrendMetric) {
    Column({ space: this.trendDimension === 4 ? 2 : 0 }) {
      Text(label).fontSize(this.trendDimension === 4 ? 10 : 8)
        .fontColor(this.trendPreviewData().mutedColor)
      Text(metric === 'cost' ? this.trendPreviewData().totalCost :
        this.trendPreviewData().totalRequests)
        .fontSize(this.trendDimension === 4 ? 22 : 15).fontWeight(FontWeight.Bold)
        .fontColor(this.trendMetric === metric ? this.trendPreviewData().inkColor :
          this.trendPreviewData().mutedColor)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start).layoutWeight(1)
    .height(this.trendDimension === 4 ? 59 : 26)
    .padding({ left: metric === 'cost' ? 12 : 0 })
    .border({ width: { bottom: this.trendMetric === metric ? 2 : 0,
      left: metric === 'cost' ? 1 : 0 }, color: this.trendMetric === metric ?
        (metric === 'cost' ? this.trendPreviewData().costColor :
          this.trendPreviewData().requestColor) :
        this.trendPreviewData().lineColor })
    .onClick(() => { this.trendMetric = metric; })
  }

  @Builder
  private trendPreview() {
    Column({ space: 0 }) {
      Row({ space: 7 }) {
        Text('S2').fontSize(9).fontWeight(FontWeight.Bold)
          .fontColor(this.trendPreviewData().surfaceColor).textAlign(TextAlign.Center)
          .width(26).height(26).backgroundColor(this.trendPreviewData().requestColor).borderRadius(5)
        Column({ space: 1 }) {
          Text('用量趋势').fontSize(this.trendDimension === 4 ? 14 : 12).fontWeight(FontWeight.Bold)
            .fontColor(this.trendPreviewData().inkColor)
          Text(this.trendName()).fontSize(9).fontColor(this.trendPreviewData().mutedColor)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Text('↻').fontSize(20).fontColor(this.trendPreviewData().inkColor)
          .onClick(() => this.refreshTrendData())
      }.width('100%').height(this.trendDimension === 4 ? 32 : 27)
      Row({ space: 3 }) {
        ForEach([7, 30], (days: number) => {
          Text(days === 7 ? '近 7 天' : '近 30 天')
            .fontSize(10).fontColor(this.trendDays === days ? this.trendPreviewData().inkColor :
              this.trendPreviewData().mutedColor)
            .backgroundColor(this.trendDays === days ? this.trendPreviewData().chipColor : Color.Transparent)
            .borderRadius(4).padding({ left: 5, right: 5, top: 4, bottom: 4 })
            .onClick(() => { this.trendDays = days; this.trendIndex = -1; })
        }, (days: number) => `${days}`)
        Blank()
        Text(this.trendPreviewData().statusLabel).fontSize(9)
          .fontColor(this.trendPreviewData().mutedColor)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }.width('100%').height(this.trendDimension === 4 ? 31 : 22)
      Row() {
        this.trendMetricButton('请求总数', 'requests')
        this.trendMetricButton('账号费用', 'cost')
      }.width('100%')
      if (this.trendPreviewData().hasChart === 'true') {
        Row({ space: 3 }) {
           if (this.trendDimension === 4) {
             Column() {
            Text(this.trendPreviewData().axisTop).fontSize(8)
              .fontColor(this.trendPreviewData().mutedColor)
            Blank()
            Text(this.trendPreviewData().axisMid).fontSize(8)
              .fontColor(this.trendPreviewData().mutedColor)
            Blank()
            Text('0').fontSize(8).fontColor(this.trendPreviewData().mutedColor)
             }.width(28).height('100%').alignItems(HorizontalAlign.End)
           }
          Stack() {
            Column() {
              Row().width('100%').height(1).backgroundColor(this.trendPreviewData().lineColor)
              Blank()
              Row().width('100%').height(1).backgroundColor(this.trendPreviewData().lineColor)
              Blank()
              Row().width('100%').height(1).backgroundColor(this.trendPreviewData().lineColor)
            }.width('100%').height('100%')
            Shape() {
              if (this.trendDays === 30) {
                 Path({ width: '300px', height: '100px', commands: this.trendPreviewData().chartArea })
                  .fill(this.trendMetric === 'cost' ? this.trendPreviewData().costColor :
                    this.trendPreviewData().requestColor).stroke(Color.Transparent).opacity(0.13)
                 Path({ width: '300px', height: '100px', commands: this.trendPreviewData().chartLine })
                  .fill(Color.Transparent).stroke(this.trendMetric === 'cost' ?
                    this.trendPreviewData().costColor : this.trendPreviewData().requestColor).strokeWidth(2)
                Path({ width: '300px', height: '100px', commands: this.trendPreviewData().chartHighlight })
                  .fill(this.trendPreviewData().surfaceColor)
                  .stroke(this.trendMetric === 'cost' ? this.trendPreviewData().costColor :
                    this.trendPreviewData().requestColor).strokeWidth(2.5)
              }
            }.viewPort({ x: 0, y: 0, width: '300px', height: '100px' })
              .width('100%').height('100%')
            if (this.trendDays === 7) {
              Row({ space: 2 }) {
                ForEach(this.trendPreviewData().barHeights, (height: number, index: number) => {
                  Column() {
                    Blank()
                    if (height > 0) {
                      Column().width(this.trendDimension === 4 ? 16 : 12)
                        .height(`${Math.max(2, Math.round(height * 0.84))}%`)
                        .backgroundColor(this.trendMetric === 'cost' ?
                          this.trendPreviewData().costColor : this.trendPreviewData().requestColor)
                        .opacity(index === this.trendPreviewData().selectedDayIndex ? 1 : 0.72)
                        .borderRadius(2)
                    }
                  }.layoutWeight(1).height('100%')
                }, (_height: number, index: number) => `${index}`)
              }.width('100%').height('100%').padding({ top: 3, bottom: 2 })
            }
            Row() {
              ForEach(Array.from({ length: this.trendPreviewData().dayCount },
                (_value: number, index: number) => index), (index: number) => {
                Blank().layoutWeight(1).height('100%').onClick(() => { this.trendIndex = index; })
              }, (index: number) => `${index}`)
            }.width('100%').height('100%')
          }.layoutWeight(1).height('100%')
         }.width('100%').height(this.trendDimension === 4 ? 102 : 33)
         if (this.trendDimension === 4) {
           Row() {
             Blank().width(31)
             ForEach(this.trendPreviewData().dateLabels, (label: string) => {
               Text(label).fontSize(8).fontColor(this.trendPreviewData().mutedColor)
                 .textAlign(TextAlign.Center).layoutWeight(1).maxLines(1)
             }, (label: string) => label)
           }.width('100%').height(17)
         }
      } else {
        Text(this.trendPreviewData().emptyLabel).fontSize(12)
          .fontColor(this.trendPreviewData().mutedColor)
          .textAlign(TextAlign.Center).width('100%').layoutWeight(1)
      }
      Row() {
        Text(this.trendPreviewData().dayLabel + ' · ' + this.trendPreviewData().dayValue)
          .fontSize(10).fontColor(this.trendPreviewData().inkColor)
          .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.trendPreviewData().chartCaption).fontSize(9)
          .fontColor(this.trendPreviewData().mutedColor)
       }.width('100%').height(this.trendDimension === 4 ? 23 : 12)
        .border({ width: { top: 1 }, color: this.trendPreviewData().lineColor })
    }
    .width(this.trendDimension === 4 ? 290 : '100%')
     .height(this.trendDimension === 4 ? 290 : 132)
     .padding(this.trendDimension === 4 ? 13 : 4)
    .backgroundColor(this.trendPreviewData().surfaceColor)
    .linearGradient({ angle: 135, colors: [[this.trendPreviewData().surfaceColor, 0],
      [this.trendPreviewData().surfaceEndColor, 1]] })
    .border({ width: this.theme === 'glass' ? 1 : 0, color: this.trendPreviewData().edgeColor })
    .shadow({ radius: this.theme === 'glass' ? 16 : 0, color: this.trendPreviewData().shadowColor })
    .borderRadius(8)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Button('返回')
            .fontSize(14).fontColor($r('app.color.quota_ink'))
            .backgroundColor(Color.Transparent).padding(0)
            .onClick(() => router.back())
          Blank()
          Text('卡片设置')
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor($r('app.color.quota_ink'))
        }
        .width('100%')

        Row({ space: 4 }) {
          this.tabButton('数据与刷新', 'data')
          this.tabButton('外观', 'appearance')
        }
        .width('100%').height(42)

        Row({ space: 7 }) {
          this.option('双账号', 'mode', 'dual')
          this.option('单账号', 'mode', 'single')
          this.option('用量趋势', 'mode', 'trend')
        }.width('100%')

        if (this.tab === 'data') {
          Text(this.previewMode === 'dual' ? `双账号卡片关注 ${this.featuredIds.length}/2` :
            this.previewMode === 'single' ? '单账号额度卡关注账号' : '趋势卡关注账号')
            .fontSize(15).fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.quota_ink')).width('100%')
          TextInput({ text: this.query, placeholder: '搜索账号' })
            .onChange((value: string) => { this.query = value; })
            .width('100%').height(42)
          ForEach(this.accountResults(), (account: AccountPreview) => {
            Row({ space: 9 }) {
              if (this.previewMode === 'single') {
                Radio({ value: `${account.id}`, group: 'single-card' })
                  .checked(this.singleId === account.id)
                  .onChange(() => { this.singleId = account.id || 0; })
              } else if (this.previewMode === 'trend') {
                Radio({ value: `${account.id}`, group: 'trend-card' })
                  .checked(this.trendAccountId === account.id)
                  .onChange(() => { this.trendAccountId = account.id || 0; this.trendIndex = -1; })
              } else {
                Checkbox({ name: `featured-${account.id}`, group: 'dual-card' })
                  .select(this.featuredIds.includes(account.id || 0))
                  .enabled(this.featuredIds.length < 2 || this.featuredIds.includes(account.id || 0))
                  .onChange(() => this.toggleFeatured(account.id || 0))
              }
              Column({ space: 3 }) {
                Text(account.name).fontSize(14).fontColor($r('app.color.quota_ink')).maxLines(1)
                Text([account.platform, account.region, account.period].filter((part: string) =>
                  part.length > 0).join(' · '))
                  .fontSize(11).fontColor($r('app.color.quota_muted')).maxLines(1)
              }
              .alignItems(HorizontalAlign.Start).layoutWeight(1)
              .onClick(() => {
                if (this.previewMode === 'single') this.singleId = account.id || 0;
                else if (this.previewMode === 'trend') {
                  this.trendAccountId = account.id || 0;
                  this.trendIndex = -1;
                } else this.toggleFeatured(account.id || 0);
              })
              if (this.previewMode !== 'trend') {
                Text(account.remaining).fontSize(14).fontColor($r('app.color.quota_healthy'))
              }
            }
            .width('100%').height(55)
            .border({ width: { bottom: 1 }, color: $r('app.color.quota_line') })
          }, (account: AccountPreview) => `${account.id}`)
          if (this.snapshot.accounts.length === 0) {
            Text('连接并读取账号后可在此选择')
              .fontSize(13).fontColor($r('app.color.quota_muted')).width('100%')
          }
          Button(this.readingAccounts ? '读取中' : '重新读取账号').enabled(!this.readingAccounts)
            .fontSize(12).fontColor($r('app.color.quota_healthy'))
            .backgroundColor(Color.Transparent).padding(0)
            .onClick(() => this.refreshAccounts())
          if (this.previewMode === 'trend') {
            Row() {
              Text(this.trendAccountId !== this.originalTrend ? '保存后读取趋势' :
                this.trend.status === 'ready' ? '趋势已同步' : this.trend.notice)
                .fontSize(12).fontColor($r('app.color.quota_muted')).layoutWeight(1)
              Button(this.refreshingTrend ? '刷新中' : '刷新趋势')
                .enabled(!this.refreshingTrend).fontSize(12)
                .fontColor($r('app.color.quota_healthy'))
                .backgroundColor(Color.Transparent).padding(0)
                .onClick(() => this.refreshTrendData())
            }.width('100%')
          }
          Text('自动刷新').fontSize(15).fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.quota_ink')).width('100%')
            .margin({ top: 8 }).border({ width: { top: 1 }, color: $r('app.color.quota_line') })
          Text('卡片后台周期').fontSize(15).fontColor($r('app.color.quota_ink')).width('100%')
          Row({ space: 7 }) {
            ForEach([30, 60, 120, 240], (minutes: number) => {
              this.option(minutes < 60 ? '30 分' : `${minutes / 60} 小时`,
                'period', `${minutes}`)
            }, (minutes: number) => `${minutes}`)
          }
          .width('100%')
          Text('系统按约 30 分钟唤醒卡片，所选周期是最早允许自动检查的时间。')
            .fontSize(12).fontColor($r('app.color.quota_muted')).width('100%')
          Text('自动请求限频间隔 · 分钟')
            .fontSize(15).fontColor($r('app.color.quota_ink')).width('100%')
          TextInput({ text: this.autoIntervalText, placeholder: '60' })
            .type(InputType.Number).width('100%').height(46)
            .onChange((value: string) => { this.autoIntervalText = value; })
          Text('默认 60，最短 1，最长 1440。仅限制自动请求。')
            .fontSize(12).fontColor($r('app.color.quota_muted')).width('100%')
          Text('自动失败退避上限').fontSize(15).fontColor($r('app.color.quota_ink')).width('100%')
          Row({ space: 7 }) {
            ForEach([5, 15, 30, 60], (minutes: number) => {
              this.option(`${minutes} 分`, 'backoff', `${minutes}`)
            }, (minutes: number) => `${minutes}`)
          }
          .width('100%')
          Text('手动刷新无冷却时间；同时进行的请求会合并。')
            .fontSize(12).fontColor($r('app.color.quota_muted')).width('100%')
        } else {
          Text('额度卡主标题').fontSize(15).fontColor($r('app.color.quota_ink')).width('100%')
          TextInput({ text: this.title, placeholder: 'Sub2API' })
            .maxLength(24).width('100%').height(46)
            .onChange((value: string) => { this.title = value; })
          Text('颜色风格').fontSize(15).fontColor($r('app.color.quota_ink')).width('100%')
          Row({ space: 8 }) {
            this.themeOption('pine', '云松')
            this.themeOption('graphite', '石墨')
          }
          .width('100%')
          Row({ space: 8 }) {
            this.themeOption('mist', '海雾')
            this.themeOption('coral', '珊瑚')
          }
          .width('100%')
          Row() {
            this.themeOption('glass', '琉璃')
          }
          .width('100%')
          Text(this.theme === 'glass' ? `玻璃透亮度 ${this.transparency}%` :
            `卡片背景透明度 ${this.transparency}%`)
            .fontSize(15).fontColor($r('app.color.quota_ink')).width('100%')
          Slider({ value: this.transparency, min: 0, max: 50, step: 5 })
            .onChange((value: number) => { this.transparency = value; })
            .width('100%')
          Text('只调整卡片表面；文字和状态颜色保持不透明。')
            .fontSize(12).fontColor($r('app.color.quota_muted')).width('100%')
          if (this.theme === 'glass') {
            Text('琉璃深浅').fontSize(15).fontColor($r('app.color.quota_ink')).width('100%')
            Row({ space: 8 }) {
              this.option('跟随系统', 'appearance', 'system')
              this.option('浅色', 'appearance', 'light')
              this.option('深色', 'appearance', 'dark')
            }
            .width('100%')
          }
          if (this.previewMode === 'trend') {
            Row({ space: 8 }) {
              this.option('2×4 中卡', 'dimension', '3')
              this.option('4×4 大卡', 'dimension', '4')
            }.width('100%')
          }
          Text(this.previewMode === 'trend' ?
            (this.trendDimension === 4 ? '趋势卡 · 4×4 预览' : '趋势卡 · 2×4 预览') :
            this.previewMode === 'single' ? '额度卡 · 2×2 预览' : '额度卡 · 2×4 预览')
            .fontSize(15).fontColor($r('app.color.quota_ink')).width('100%')
          Stack({ alignContent: Alignment.Center }) {
            this.previewWallpaper()
            if (this.previewMode === 'trend') this.trendPreview()
            else this.preview()
          }
          .width('100%').height(this.previewMode === 'trend' && this.trendDimension === 4 ? 330 : 224)
          .padding(14)
          .backgroundColor(this.previewDark ? '#48636B' : '#AEC8C9')
        }

        if (this.feedback) {
          Text(this.feedback).fontSize(13).fontColor($r('app.color.quota_warning')).width('100%')
        }
        Button(this.saving ? '保存中' : '保存方案')
          .enabled(!this.saving && !this.readingAccounts && !this.refreshingTrend)
          .width('100%').height(46)
          .backgroundColor($r('app.color.quota_healthy'))
          .onClick(() => { this.save(); })
      }
      .padding({ left: 20, right: 20, top: 24, bottom: 36 })
      .alignItems(HorizontalAlign.Start).width('100%')
    }
    .width('100%').height('100%').backgroundColor($r('app.color.quota_background'))
  }
}
