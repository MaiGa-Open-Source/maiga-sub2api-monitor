import { TrendWidgetData } from '../model/TrendFormData';
import { CardTheme, cardStyle } from '../model/CardPreferences';
import { WidgetSurface } from './WidgetSurface';

@Component
export struct TrendWidget {
  @Prop data: TrendWidgetData;
  onCommand: (value: string) => void = (_value: string) => {};
  onOpen: () => void = () => {};

  private large(): boolean {
    return this.data.dimension === 'large';
  }

  private activeColor(): string {
    return this.data.metric === 'cost' ? this.data.costColor : this.data.requestColor;
  }

  private styledChart(): boolean {
    return this.data.theme === 'aurora' || this.data.theme === 'label' || this.data.theme === 'pixel';
  }

  @Builder
  private periodButton(label: string, value: number) {
    Text(label).fontSize(this.large() ? 11 : 9)
      .fontWeight(this.data.days === value ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(this.data.days === value ? this.data.inkColor : this.data.mutedColor)
      .textAlign(TextAlign.Center).width(this.large() ? 60 : 47).height(this.large() ? 25 : 19)
      .backgroundColor(this.data.days === value ? this.data.chipColor : Color.Transparent)
      .border({ width: this.data.theme === 'chrome' && this.data.days === value ? 1 : 0,
        color: this.data.lineColor })
      .borderRadius(this.data.theme === 'pixel' ? 0 : this.data.theme === 'chrome' ? 4 : 20)
      .onClick(() => this.onCommand(`period-${value}`))
  }

  @Builder
  private metricButton(label: string, value: string) {
    Column({ space: this.large() ? 4 : 1 }) {
      Text(label).fontSize(this.large() ? 10 : 8).fontColor(this.data.mutedColor).maxLines(1)
      Text(value === 'cost' ? this.data.totalCost : this.data.totalRequests)
        .fontSize(this.large() ? 30 : 17)
        .fontFamily(cardStyle(this.data.theme as CardTheme).fontFamily)
        .fontStyle(this.data.theme === 'label' ? FontStyle.Italic : FontStyle.Normal)
        .fontWeight(this.data.theme === 'aurora' || this.data.theme === 'label' ?
          FontWeight.Regular : FontWeight.Bold)
        .fontColor(this.data.metric === value ?
          (value === 'cost' ? this.data.costColor : this.data.requestColor) : this.data.inkColor)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Center).layoutWeight(1)
    .height(this.large() ? 65 : 33)
    .padding({ left: this.data.theme === 'cushion' ? 8 : value === 'cost' ? (this.large() ? 12 : 8) : 0,
      right: this.data.theme === 'cushion' ? 6 : 0 })
    .margin({ left: this.data.theme === 'cushion' && value === 'cost' ? 7 : 0 })
    .backgroundColor(this.data.theme === 'cushion' ? this.data.panelColor : Color.Transparent)
    .borderRadius(this.data.theme === 'cushion' ? 12 : 0)
    .border({ width: { bottom: this.data.metric === value ? 1 : 0,
      left: value === 'cost' && this.data.theme !== 'cushion' && this.data.theme !== 'aurora' ? 1 : 0,
      top: this.data.theme === 'cushion' && this.data.metric === value ? 1 : 0,
      right: this.data.theme === 'cushion' && this.data.metric === value ? 1 : 0 },
      color: this.data.theme === 'cushion' ? this.data.lineColor :
        this.data.metric === value ? (value === 'cost' ? this.data.costColor : this.data.requestColor) : this.data.lineColor,
      style: this.data.theme === 'label' ? BorderStyle.Dotted : BorderStyle.Solid })
    .shadow({ radius: this.data.theme === 'cushion' ? 3 : 0, color: this.data.shadowColor })
    .onClick(() => this.onCommand(`metric-${value}`))
  }

  @Builder
  private chart() {
    Row({ space: 3 }) {
      if (this.large()) {
        Column() {
          Text(this.data.axisTop).fontSize(8).fontColor(this.data.mutedColor)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Blank()
          Text(this.data.axisMid).fontSize(8).fontColor(this.data.mutedColor)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Blank()
          Text(this.data.metric === 'cost' ? '$0' : '0').fontSize(8).fontColor(this.data.mutedColor)
        }.width(30).height('100%').alignItems(HorizontalAlign.End)
      }
      Stack() {
        Column() {
          Row().width('100%').height(1).backgroundColor(this.data.lineColor)
          Blank()
          Row().width('100%').height(1).backgroundColor(this.data.lineColor)
          Blank()
          Row().width('100%').height(1).backgroundColor(this.data.lineColor)
        }.width('100%').height('100%').opacity(this.data.theme === 'cushion' ? 0.4 : 0.65)
        Shape() {
          if (this.styledChart()) {
            Path({ width: '300px', height: '100px', commands: this.data.chartStyleArea })
              .fill(this.activeColor()).stroke(Color.Transparent).opacity(0.1)
            Path({ width: '300px', height: '100px', commands: this.data.chartStyleLine })
              .fill(Color.Transparent).stroke(this.activeColor()).strokeWidth(this.data.theme === 'pixel' ? 1.5 : 2)
            Path({ width: '300px', height: '100px', commands: this.data.chartStyleStems })
              .fill(Color.Transparent).stroke(this.activeColor()).strokeWidth(0.8).opacity(0.45)
            Path({ width: '300px', height: '100px', commands: this.data.chartStyleMarks })
              .fill(this.activeColor()).stroke(Color.Transparent).opacity(0.6)
            Path({ width: '300px', height: '100px', commands: this.data.chartStyleHighlight })
              .fill(this.data.theme === 'aurora' ? this.data.panelColor : this.activeColor())
              .stroke(this.activeColor()).strokeWidth(this.data.theme === 'aurora' ? 1.5 : 0)
          } else if (this.data.days === 30) {
            Path({ width: '300px', height: '100px', commands: this.data.chartArea })
              .fill(this.activeColor()).stroke(Color.Transparent).opacity(0.13)
            Path({ width: '300px', height: '100px', commands: this.data.chartLine })
              .fill(Color.Transparent).stroke(this.activeColor()).strokeWidth(2.5)
            Path({ width: '300px', height: '100px', commands: this.data.chartHighlight })
              .fill(this.data.panelColor).stroke(this.activeColor()).strokeWidth(2.5)
          }
        }
        .viewPort({ x: 0, y: 0, width: '300px', height: '100px' }).width('100%').height('100%')
        if (!this.styledChart() && this.data.days === 7) {
          Row({ space: 2 }) {
            ForEach(this.data.barHeights, (height: number, index: number) => {
              Column() {
                Blank()
                if (height > 0) {
                  Column().width(this.large() ? 17 : 12)
                    .height(`${Math.max(2, Math.round(height * 0.84))}%`)
                    .backgroundColor(this.activeColor()).opacity(index === this.data.selectedDayIndex ? 1 : 0.65)
                    .borderRadius(this.data.theme === 'cushion' ? 9 : 1)
                }
              }.layoutWeight(1).height('100%')
            }, (_height: number, index: number) => `${index}`)
          }.width('100%').height('100%').padding({ top: 3, bottom: 2 })
        }
        Row() {
          ForEach(Array.from({ length: this.data.dayCount }, (_value: number, index: number) => index),
            (index: number) => {
              Blank().layoutWeight(1).height('100%').onClick(() => this.onCommand(`day-${index}`))
            }, (index: number) => `${index}`)
        }.width('100%').height('100%')
      }.layoutWeight(1).height('100%')
    }.width('100%').layoutWeight(1).margin({ top: this.large() ? 9 : 3, bottom: 2 })
  }

  build() {
    Stack() {
      WidgetSurface({ theme: this.data.theme, surface: this.data.surfaceColor,
        surfaceEnd: this.data.surfaceEndColor, edge: this.data.edgeColor, line: this.data.lineColor,
        texture: this.data.textureColor, highlight: this.data.highlightColor })
      Column({ space: 0 }) {
        Row({ space: 6 }) {
          Text('S2').fontSize(this.large() ? 10 : 8).fontWeight(FontWeight.Bold)
            .fontColor(this.data.theme === 'aurora' || this.data.theme === 'label' || this.data.theme === 'chrome' ?
              this.data.requestColor : this.data.panelColor).textAlign(TextAlign.Center)
            .width(this.large() ? 27 : 22).height(this.large() ? 27 : 22)
            .backgroundColor(this.data.theme === 'aurora' || this.data.theme === 'label' || this.data.theme === 'chrome' ?
              Color.Transparent : this.data.requestColor)
            .border({ width: this.data.theme === 'aurora' || this.data.theme === 'label' || this.data.theme === 'chrome' ? 1 : 0,
              color: this.data.lineColor })
            .borderRadius(this.data.theme === 'pixel' ? 0 : this.data.theme === 'chrome' ? 5 : 20)
          Column({ space: 1 }) {
            Text('用量趋势').fontSize(this.large() ? 13 : 11)
              .fontWeight(this.data.theme === 'label' || this.data.theme === 'aurora' ?
                FontWeight.Medium : FontWeight.Bold).fontColor(this.data.inkColor).maxLines(1)
            Text(this.data.accountName).fontSize(this.large() ? 9 : 8).fontColor(this.data.mutedColor)
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          }.alignItems(HorizontalAlign.Start).layoutWeight(1).onClick(() => this.onOpen())
          Text('↻').fontSize(20).fontColor(this.data.inkColor).textAlign(TextAlign.Center)
            .width(25).height(25).onClick(() => this.onCommand('refresh'))
        }
        .width('100%').height(this.large() ? 31 : 25)
        .border({ width: { bottom: this.data.theme === 'chrome' || this.data.theme === 'pixel' ? 1 : 0 },
          color: this.data.lineColor })
        Row({ space: 2 }) {
          this.periodButton('近 7 天', 7)
          this.periodButton('近 30 天', 30)
          Blank()
          Text(this.data.statusLabel).fontSize(this.large() ? 9 : 8).fontColor(this.data.mutedColor)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.End).constraintSize({ maxWidth: this.large() ? 140 : 100 })
        }.width('100%').height(this.large() ? 37 : 23)
        Row() {
          this.metricButton('请求总数', 'requests')
          this.metricButton('账号费用', 'cost')
        }.width('100%').margin({ top: this.large() ? 3 : 0 })
        if (this.data.hasChart === 'true') {
          this.chart()
          if (this.large()) {
            Row() {
              Blank().width(33)
              ForEach(this.data.dateLabels, (label: string) => {
                Text(label).fontSize(8).fontColor(this.data.mutedColor)
                  .textAlign(TextAlign.Center).maxLines(1).layoutWeight(1)
              }, (label: string) => label)
            }.width('100%').height(18)
          }
        } else {
          Column() {
            Text(this.data.emptyLabel).fontSize(this.large() ? 13 : 11).fontColor(this.data.mutedColor)
              .maxLines(2).textAlign(TextAlign.Center)
          }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        }
        Row({ space: 6 }) {
          Text(this.data.hasChart === 'true' ? `${this.data.dayLabel} · ${this.data.dayValue}` : this.data.emptyLabel)
            .fontSize(this.large() ? 10 : 8).fontWeight(FontWeight.Medium).fontColor(this.data.inkColor)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
          Text(this.data.chartCaption).fontSize(this.large() ? 9 : 8).fontColor(this.data.mutedColor).maxLines(1)
        }
        .width('100%').height(this.large() ? 25 : 16)
        .border({ width: { top: this.data.theme === 'aurora' || this.data.theme === 'cushion' ? 0 : 1 },
          color: this.data.lineColor, style: this.data.theme === 'label' ? BorderStyle.Dotted : BorderStyle.Solid })
        .onClick(() => this.onOpen())
      }
      .width('100%').height('100%')
      .padding({ left: this.large() ? 16 : 12, right: this.large() ? 16 : 12,
        top: this.large() ? 13 : 8, bottom: this.large() ? 11 : 7 })
    }
    .width('100%').height('100%').borderRadius(cardStyle(this.data.theme as CardTheme).radius)
    .shadow({ radius: this.data.theme === 'cushion' ? 8 : this.data.theme === 'chrome' ? 3 : 0,
      color: this.data.shadowColor }).clip(true)
  }
}
