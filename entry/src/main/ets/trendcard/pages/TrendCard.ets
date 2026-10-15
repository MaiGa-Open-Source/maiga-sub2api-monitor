@Entry
@Component
struct TrendCard {
  @LocalStorageProp('dimension') dimension: string = 'medium';
  @LocalStorageProp('glass') glass: string = 'false';
  @LocalStorageProp('surfaceColor') surfaceColor: string = '#FFF9FBFA';
  @LocalStorageProp('surfaceEndColor') surfaceEndColor: string = '#FFF9FBFA';
  @LocalStorageProp('edgeColor') edgeColor: string = '#00000000';
  @LocalStorageProp('shadowColor') shadowColor: string = '#00000000';
  @LocalStorageProp('inkColor') inkColor: string = '#24332F';
  @LocalStorageProp('mutedColor') mutedColor: string = '#64746E';
  @LocalStorageProp('lineColor') lineColor: string = '#DCE5E0';
  @LocalStorageProp('requestColor') requestColor: string = '#187B59';
  @LocalStorageProp('costColor') costColor: string = '#C3654F';
  @LocalStorageProp('chipColor') chipColor: string = '#EAF2EE';
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

  private large(): boolean {
    return this.dimension === 'large';
  }

  private activeColor(): string {
    return this.metric === 'cost' ? this.costColor : this.requestColor;
  }

  private command(value: string): void {
    postCardAction(this, { action: 'message', params: { command: value } });
  }

  private openDetail(): void {
    postCardAction(this, { action: 'router', abilityName: 'EntryAbility' });
  }

  @Builder
  private periodButton(label: string, value: number) {
    Text(label)
      .fontSize(this.large() ? 11 : 10)
      .fontWeight(this.days === value ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.days === value ? this.inkColor : this.mutedColor)
      .textAlign(TextAlign.Center)
      .width(this.large() ? 60 : 51)
      .height(this.large() ? 28 : 21)
      .backgroundColor(this.days === value ? this.chipColor : Color.Transparent)
      .borderRadius(4)
      .onClick(() => this.command(`period-${value}`))
  }

  @Builder
  private metricButton(label: string, value: string) {
    Column({ space: this.large() ? 4 : 0 }) {
      Text(label).fontSize(this.large() ? 11 : 8).fontColor(this.mutedColor).maxLines(1)
      Text(value === 'cost' ? this.totalCost : this.totalRequests)
        .fontSize(this.large() ? 24 : 15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.metric === value ? this.inkColor : this.mutedColor)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(this.large() ? 69 : 26)
    .padding({ left: value === 'cost' ? (this.large() ? 16 : 8) : 0 })
    .border({ width: { bottom: this.metric === value ? 2 : 0,
      left: value === 'cost' ? 1 : 0 }, color: this.metric === value ?
        (value === 'cost' ? this.costColor : this.requestColor) : this.lineColor })
    .onClick(() => this.command(`metric-${value}`))
  }

  @Builder
  private chart() {
    Row({ space: 3 }) {
      if (this.large()) {
        Column() {
          Text(this.axisTop).fontSize(9).fontColor(this.mutedColor)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Blank()
          Text(this.axisMid).fontSize(9).fontColor(this.mutedColor)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Blank()
          Text(this.metric === 'cost' ? '$0' : '0').fontSize(9).fontColor(this.mutedColor)
        }
        .width(32).height('100%')
        .alignItems(HorizontalAlign.End)
      }
      Stack() {
        Column() {
          Row().width('100%').height(1).backgroundColor(this.lineColor)
          Blank()
          Row().width('100%').height(1).backgroundColor(this.lineColor)
          Blank()
          Row().width('100%').height(1).backgroundColor(this.lineColor)
        }.width('100%').height('100%')
        Shape() {
          if (this.days === 30) {
            Path({ width: '300px', height: '100px', commands: this.chartArea })
              .fill(this.activeColor()).stroke(Color.Transparent).opacity(0.13)
            Path({ width: '300px', height: '100px', commands: this.chartLine })
              .fill(Color.Transparent).stroke(this.activeColor()).strokeWidth(2.5)
            Path({ width: '300px', height: '100px', commands: this.chartHighlight })
              .fill(this.surfaceColor).stroke(this.activeColor()).strokeWidth(2.5)
          }
        }
        .viewPort({ x: 0, y: 0, width: '300px', height: '100px' })
        .width('100%').height('100%')
        if (this.days === 7) {
          Row({ space: 2 }) {
            ForEach(this.barHeights, (height: number, index: number) => {
              Column() {
                Blank()
                if (height > 0) {
                  Column()
                    .width(this.large() ? 16 : 12)
                    .height(`${Math.max(2, Math.round(height * 0.84))}%`)
                    .backgroundColor(this.activeColor())
                    .opacity(index === this.selectedDayIndex ? 1 : 0.72)
                    .borderRadius(2)
                }
              }
              .layoutWeight(1).height('100%')
            }, (_height: number, index: number) => `${index}`)
          }
          .width('100%').height('100%').padding({ top: 3, bottom: 2 })
        }
        Row() {
          ForEach(Array.from({ length: this.dayCount }, (_value: number, index: number) => index),
            (index: number) => {
              Blank().layoutWeight(1).height('100%')
                .onClick(() => this.command(`day-${index}`))
            }, (index: number) => `${index}`)
        }
        .width('100%').height('100%')
      }
      .layoutWeight(1).height('100%')
    }
    .width('100%').height(this.large() ? 100 : 33)
  }

  build() {
    Column({ space: 0 }) {
      Row({ space: 7 }) {
        Text('S2')
          .fontSize(this.large() ? 11 : 9).fontWeight(FontWeight.Bold)
          .fontColor(this.surfaceColor).textAlign(TextAlign.Center)
          .width(this.large() ? 30 : 25).height(this.large() ? 30 : 25)
          .backgroundColor(this.requestColor).borderRadius(5)
        Column({ space: 1 }) {
          Text('用量趋势')
            .fontSize(this.large() ? 14 : 12).fontWeight(FontWeight.Bold)
            .fontColor(this.inkColor).maxLines(1)
          Text(this.accountName).fontSize(this.large() ? 10 : 9).fontColor(this.mutedColor)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1).onClick(() => this.openDetail())
        Text('↻').fontSize(this.large() ? 21 : 19).fontColor(this.inkColor)
          .textAlign(TextAlign.Center).width(28).height(27)
          .onClick(() => this.command('refresh'))
      }
      .width('100%').height(this.large() ? 33 : 27)

      Row({ space: 2 }) {
        this.periodButton('近 7 天', 7)
        this.periodButton('近 30 天', 30)
        Blank()
        Text(this.statusLabel).fontSize(this.large() ? 10 : 8).fontColor(this.mutedColor)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.End).constraintSize({ maxWidth: this.large() ? 170 : 110 })
      }
      .width('100%').height(this.large() ? 36 : 22)

      Row() {
        this.metricButton('请求总数', 'requests')
        this.metricButton('账号费用', 'cost')
      }
      .width('100%').margin({ top: this.large() ? 6 : 0 })

      if (this.hasChart === 'true') {
        this.chart()
        if (this.large()) {
          Row({ space: 0 }) {
            Blank().width(35)
            ForEach(this.dateLabels, (label: string) => {
              Text(label).fontSize(9).fontColor(this.mutedColor)
                .textAlign(TextAlign.Center).maxLines(1).layoutWeight(1)
            }, (label: string) => label)
          }
          .width('100%').height(19)
        }
      } else {
        Column() {
          Text(this.emptyLabel).fontSize(this.large() ? 13 : 11).fontColor(this.mutedColor)
            .maxLines(2).textAlign(TextAlign.Center)
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      }

      Row({ space: 6 }) {
        Text(this.hasChart === 'true' ? `${this.dayLabel} · ${this.dayValue}` : this.emptyLabel)
          .fontSize(this.large() ? 11 : 9).fontWeight(FontWeight.Medium).fontColor(this.inkColor)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
        Text(this.chartCaption).fontSize(this.large() ? 10 : 8).fontColor(this.mutedColor)
          .maxLines(1)
      }
      .width('100%').height(this.large() ? 25 : 12)
      .border({ width: { top: 1 }, color: this.lineColor })
      .onClick(() => this.openDetail())
    }
    .width('100%').height('100%')
    .padding({ left: this.large() ? 16 : 10, right: this.large() ? 16 : 10,
      top: this.large() ? 13 : 4, bottom: this.large() ? 12 : 4 })
    .backgroundColor(this.surfaceColor)
    .linearGradient({ angle: 135, colors: [[this.surfaceColor, 0], [this.surfaceEndColor, 1]] })
    .border({ width: this.glass === 'true' ? 1 : 0, color: this.edgeColor })
    .shadow({ radius: this.glass === 'true' ? 16 : 0, color: this.shadowColor })
  }
}
