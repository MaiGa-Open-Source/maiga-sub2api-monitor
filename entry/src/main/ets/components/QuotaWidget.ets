import { QuotaWidgetData } from '../model/MockQuota';
import { CardTheme, cardStyle } from '../model/CardPreferences';
import { WidgetSurface } from './WidgetSurface';

@Component
export struct QuotaWidget {
  @Prop data: QuotaWidgetData;
  onRefresh: () => void = () => {};
  onOpen: () => void = () => {};

  private toneColor(tone: string): string {
    if (tone === 'error' || tone === 'unavailable') return this.data.errorColor;
    if (tone === 'warning' || tone === 'low' || tone === 'unknown') return this.data.warningColor;
    return this.data.healthyColor;
  }

  private numericFont(): string {
    return cardStyle(this.data.theme as CardTheme).fontFamily;
  }

  private badge(): boolean {
    return this.data.theme === 'cushion' || this.data.theme === 'label';
  }

  @Builder
  private header() {
    Row({ space: 4 }) {
      Text(this.data.cardTitle)
        .fontSize(12).fontWeight(this.data.theme === 'aurora' || this.data.theme === 'label' ?
          FontWeight.Medium : FontWeight.Bold).fontColor(this.data.inkColor)
        .textAlign(this.data.theme === 'label' ? TextAlign.Center : TextAlign.Start)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1).onClick(() => this.onOpen())
      if (this.data.dimension !== 'single') {
        Text(this.data.statusLabel).fontSize(9).fontColor(this.toneColor(this.data.statusTone))
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 88 })
      }
      Text('↻').fontSize(20).fontColor(this.data.inkColor).width(24).height(23)
        .textAlign(TextAlign.Center).onClick(() => this.onRefresh())
    }
    .width('100%').height(24)
    .border({ width: { bottom: this.data.theme === 'pixel' || this.data.theme === 'chrome' ? 1 : 0 },
      color: this.data.lineColor })
  }

  @Builder
  private account(name: string, meta: string, remaining: string, state: string, tone: string,
    divider: boolean) {
    Row({ space: 6 }) {
      Column({ space: 2 }) {
        Text(name).fontSize(12).fontWeight(FontWeight.Medium).fontColor(this.data.inkColor)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(meta).fontSize(9).fontColor(this.data.mutedColor)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Column({ space: 1 }) {
        Text(remaining).fontSize(23).fontFamily(this.numericFont())
          .fontStyle(this.data.theme === 'label' ? FontStyle.Italic : FontStyle.Normal)
          .fontWeight(this.data.theme === 'aurora' || this.data.theme === 'label' ?
            FontWeight.Regular : FontWeight.Bold).fontColor(this.toneColor(tone))
          .maxLines(1)
        Text(state).fontSize(8).fontColor(this.data.mutedColor).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(this.data.theme === 'label' ? HorizontalAlign.Center : HorizontalAlign.End)
      .width(this.data.theme === 'label' ? 86 : 76)
      .border({ width: this.data.theme === 'label' ? 1 : 0, color: this.data.lineColor })
      .borderRadius(this.data.theme === 'label' ? 50 : 0)
      .padding({ left: this.data.theme === 'label' ? 5 : 0, right: this.data.theme === 'label' ? 5 : 0 })
    }
    .width('100%').layoutWeight(1)
    .padding({ left: this.data.theme === 'cushion' ? 8 : 0, right: this.data.theme === 'cushion' ? 8 : 0 })
    .margin({ top: this.data.theme === 'cushion' ? 2 : 0, bottom: this.data.theme === 'cushion' ? 2 : 0 })
    .backgroundColor(this.data.theme === 'cushion' ? this.data.panelColor : Color.Transparent)
    .borderRadius(this.data.theme === 'cushion' ? 14 : 0)
    .border({ width: { bottom: divider && !this.badge() && this.data.theme !== 'aurora' ? 1 : 0 },
      color: this.data.lineColor })
    .onClick(() => this.onOpen())
  }

  @Builder
  private singleNumber() {
    Column({ space: 1 }) {
      Text(this.data.singleRemaining)
        .fontSize(this.data.theme === 'pixel' ? 34 : this.badge() ? 29 : 22)
        .fontFamily(this.numericFont())
        .fontStyle(this.data.theme === 'label' ? FontStyle.Italic : FontStyle.Normal)
        .fontWeight(this.data.theme === 'aurora' || this.data.theme === 'label' ?
          FontWeight.Regular : FontWeight.Bold)
        .fontColor(this.toneColor(this.data.singleTone)).maxLines(1)
      Text(this.data.singleRingKnown === 'true' ? '剩余额度' : '额度未知')
        .fontSize(8).fontColor(this.data.mutedColor)
    }
    .alignItems(HorizontalAlign.Center)
    .width(this.badge() ? 104 : 95)
    .padding({ top: this.badge() ? 5 : 0, bottom: this.badge() ? 5 : 0 })
    .backgroundColor(this.data.theme === 'cushion' ? this.data.panelColor : Color.Transparent)
    .border({ width: this.data.theme === 'label' ? 1 : 0, color: this.data.lineColor })
    .borderRadius(this.badge() ? 52 : 0)
    .shadow({ radius: this.data.theme === 'cushion' ? 5 : 0, color: this.data.shadowColor })
  }

  @Builder
  private singleQuota() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.data.theme === 'aurora' || this.data.theme === 'chrome') {
        if (this.data.singleRingKnown === 'true') {
          Progress({ value: this.data.singleRingValue, total: 100, type: ProgressType.Ring })
            .color(this.toneColor(this.data.singleTone)).backgroundColor(this.data.lineColor)
            .style({ strokeWidth: this.data.theme === 'aurora' ? 2 : 4 }).width(62).height(62)
        } else {
          Column().width(62).height(62)
            .border({ width: 2, color: this.data.lineColor, style: BorderStyle.Dashed }).borderRadius(31)
        }
      }
      Column({ space: 3 }) {
        this.singleNumber()
        if (this.data.theme === 'pixel') {
          if (this.data.singleRingKnown === 'true') {
            Row({ space: 2 }) {
              ForEach(Array.from({ length: 20 }, (_value: number, index: number) => index), (index: number) => {
                Column().layoutWeight(1).height(5)
                  .backgroundColor(index < Math.round(this.data.singleRingValue / 5) ?
                    this.toneColor(this.data.singleTone) : this.data.lineColor)
              }, (index: number) => `${index}`)
            }.width('100%')
          } else {
            Row().width('100%').height(5)
              .border({ width: { top: 2 }, color: this.data.mutedColor, style: BorderStyle.Dashed })
          }
        }
      }.width('100%')
    }
    .layoutWeight(1).width('100%').onClick(() => this.onOpen())
  }

  build() {
    Stack() {
      WidgetSurface({ theme: this.data.theme, surface: this.data.surfaceColor,
        surfaceEnd: this.data.surfaceEndColor, edge: this.data.edgeColor, line: this.data.lineColor,
        texture: this.data.textureColor, highlight: this.data.highlightColor })
      Column({ space: 0 }) {
        this.header()
        if (this.data.dimension === 'single') {
          Column({ space: 2 }) {
            Text(this.data.singleName || '选择关注账号')
              .fontSize(11).fontWeight(FontWeight.Medium).fontColor(this.data.inkColor)
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.data.singleMeta || '在应用内设置').fontSize(8).fontColor(this.data.mutedColor)
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(this.data.theme === 'label' ? HorizontalAlign.Center : HorizontalAlign.Start)
          .width('100%').height(29).onClick(() => this.onOpen())
          this.singleQuota()
          Row({ space: 3 }) {
            Text(this.data.singleState || this.data.statusLabel).fontSize(8)
              .fontColor(this.toneColor(this.data.singleTone)).maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
            Text(this.data.singleTimeLabel).fontSize(8).fontColor(this.data.mutedColor).maxLines(1)
          }
          .width('100%').height(17)
          .border({ width: { top: this.data.theme === 'aurora' || this.data.theme === 'cushion' ? 0 : 1 },
            color: this.data.lineColor, style: this.data.theme === 'label' ? BorderStyle.Dotted : BorderStyle.Solid })
          .onClick(() => this.onOpen())
        } else {
          if (this.data.hasAccounts === 'true') {
            this.account(this.data.firstName, this.data.firstMeta, this.data.firstRemaining,
              this.data.firstState, this.data.firstTone, true)
            this.account(this.data.secondName || '第二个关注账号', this.data.secondMeta || '在应用内设置',
              this.data.secondName ? this.data.secondRemaining : '--', this.data.secondState, this.data.secondTone, false)
          } else {
            Column({ space: 4 }) {
              Text('尚无关注账号').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.data.inkColor)
              Text(this.data.notice).fontSize(11).fontColor(this.data.mutedColor).maxLines(2)
            }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Start).onClick(() => this.onOpen())
          }
          Row() {
            Text(this.data.abnormalLabel).fontSize(9).fontColor(this.data.mutedColor)
            Blank()
            Text(this.data.timeLabel).fontSize(9).fontColor(this.data.mutedColor).maxLines(1)
          }.width('100%').height(17).onClick(() => this.onOpen())
        }
      }
      .padding({ left: 12, right: 12, top: 7, bottom: 7 }).width('100%').height('100%')
    }
    .width('100%').height('100%').borderRadius(cardStyle(this.data.theme as CardTheme).radius)
    .shadow({ radius: this.data.theme === 'cushion' ? 8 : this.data.theme === 'chrome' ? 3 : 0,
      color: this.data.shadowColor }).clip(true)
  }
}
