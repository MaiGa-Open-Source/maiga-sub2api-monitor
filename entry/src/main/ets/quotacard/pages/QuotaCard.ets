@Entry
@Component
struct QuotaCard {
  @LocalStorageProp('dimension') dimension: string = 'dual';
  @LocalStorageProp('cardTitle') cardTitle: string = 'Sub2API';
  @LocalStorageProp('glass') glass: string = 'false';
  @LocalStorageProp('surfaceColor') surfaceColor: string = '#FFF9FBFA';
  @LocalStorageProp('surfaceEndColor') surfaceEndColor: string = '#FFF9FBFA';
  @LocalStorageProp('edgeColor') edgeColor: string = '#00000000';
  @LocalStorageProp('shadowColor') shadowColor: string = '#00000000';
  @LocalStorageProp('inkColor') inkColor: string = '#24332F';
  @LocalStorageProp('mutedColor') mutedColor: string = '#64746E';
  @LocalStorageProp('lineColor') lineColor: string = '#DCE5E0';
  @LocalStorageProp('healthyColor') healthyColor: string = '#187B59';
  @LocalStorageProp('warningColor') warningColor: string = '#A66D1D';
  @LocalStorageProp('errorColor') errorColor: string = '#B44842';
  @LocalStorageProp('statusLabel') statusLabel: string = '尚未配置';
  @LocalStorageProp('statusTone') statusTone: string = 'warning';
  @LocalStorageProp('abnormalLabel') abnormalLabel: string = '0 个异常';
  @LocalStorageProp('timeLabel') timeLabel: string = '尚无成功数据';
  @LocalStorageProp('singleTimeLabel') singleTimeLabel: string = '未更新';
  @LocalStorageProp('notice') notice: string = '';
  @LocalStorageProp('hasAccounts') hasAccounts: string = 'false';
  @LocalStorageProp('firstName') firstName: string = '';
  @LocalStorageProp('firstMeta') firstMeta: string = '';
  @LocalStorageProp('firstRemaining') firstRemaining: string = '--';
  @LocalStorageProp('firstState') firstState: string = '';
  @LocalStorageProp('firstTone') firstTone: string = 'healthy';
  @LocalStorageProp('secondName') secondName: string = '';
  @LocalStorageProp('secondMeta') secondMeta: string = '';
  @LocalStorageProp('secondRemaining') secondRemaining: string = '--';
  @LocalStorageProp('secondState') secondState: string = '';
  @LocalStorageProp('secondTone') secondTone: string = 'low';
  @LocalStorageProp('singleName') singleName: string = '';
  @LocalStorageProp('singleMeta') singleMeta: string = '';
  @LocalStorageProp('singleRemaining') singleRemaining: string = '--';
  @LocalStorageProp('singleState') singleState: string = '';
  @LocalStorageProp('singleTone') singleTone: string = 'unknown';
  @LocalStorageProp('singleRingValue') singleRingValue: number = 0;
  @LocalStorageProp('singleRingKnown') singleRingKnown: string = 'false';

  private toneColor(tone: string): string {
    if (tone === 'error' || tone === 'unavailable') return this.errorColor;
    if (tone === 'warning' || tone === 'low' || tone === 'unknown') return this.warningColor;
    return this.healthyColor;
  }

  private openDetail(): void {
    postCardAction(this, { action: 'router', abilityName: 'EntryAbility' });
  }

  @Builder
  private header(showStatus: boolean) {
    Row({ space: 4 }) {
      Text(this.cardTitle)
        .fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.inkColor)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1).onClick(() => this.openDetail())
      if (showStatus) {
        Text(this.statusLabel)
          .fontSize(10).fontColor(this.toneColor(this.statusTone))
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      Text('↻')
        .fontSize(20).fontColor(this.inkColor).width(26).height(24)
        .textAlign(TextAlign.Center)
        .onClick(() => postCardAction(this, { action: 'message', params: { command: 'refresh' } }))
    }
    .width('100%').height(24)
  }

  @Builder
  private account(name: string, meta: string, remaining: string, state: string, tone: string,
    divider: boolean) {
    Row() {
      Column({ space: 1 }) {
        Text(name).fontSize(12).fontWeight(FontWeight.Medium).fontColor(this.inkColor)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(meta).fontSize(9).fontColor(this.mutedColor)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      Column({ space: 1 }) {
        Text(remaining).fontSize(17).fontWeight(FontWeight.Bold).fontColor(this.toneColor(tone))
        Text(state).fontSize(9).fontColor(this.mutedColor).maxLines(1)
      }
      .alignItems(HorizontalAlign.End).width(76)
    }
    .width('100%').layoutWeight(1)
    .border({ width: { bottom: divider ? 1 : 0 }, color: this.lineColor })
    .onClick(() => this.openDetail())
  }

  build() {
    Column() {
      this.header(this.dimension !== 'single')
      if (this.dimension === 'single') {
        Column({ space: 1 }) {
          Text(this.singleName || '选择关注账号')
            .fontSize(12).fontWeight(FontWeight.Medium).fontColor(this.inkColor)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.singleMeta || '在应用内设置')
            .fontSize(9).fontColor(this.mutedColor)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start).width('100%').height(24)
        .onClick(() => this.openDetail())

        Stack({ alignContent: Alignment.Center }) {
          if (this.singleRingKnown === 'true') {
            Progress({ value: this.singleRingValue, total: 100, type: ProgressType.Ring })
              .color(this.toneColor(this.singleTone)).backgroundColor(this.lineColor)
              .style({ strokeWidth: 6 }).width(56).height(56)
          } else {
            Column().width(56).height(56)
              .border({ width: 6, color: this.lineColor, style: BorderStyle.Dashed })
              .borderRadius(28)
          }
          Column({ space: 1 }) {
            Text(this.singleRemaining)
              .fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.toneColor(this.singleTone))
            Text(this.singleRingKnown === 'true' ? '剩余额度' : '额度未知')
              .fontSize(8).fontColor(this.mutedColor)
          }
          .alignItems(HorizontalAlign.Center)
        }
        .layoutWeight(1).width('100%').onClick(() => this.openDetail())

        Row() {
          Text(this.singleState || this.statusLabel)
            .fontSize(9).fontWeight(FontWeight.Medium)
            .fontColor(this.toneColor(this.singleTone)).maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
          Text(this.singleTimeLabel).fontSize(8).fontColor(this.mutedColor).maxLines(1)
        }
        .width('100%').height(17).border({ width: { top: 1 }, color: this.lineColor })
        .onClick(() => this.openDetail())
      } else {
        if (this.hasAccounts === 'true') {
          this.account(this.firstName, this.firstMeta, this.firstRemaining, this.firstState, this.firstTone, true)
          this.account(this.secondName || '第二个关注账号', this.secondMeta || '在应用内设置',
            this.secondName ? this.secondRemaining : '--', this.secondState, this.secondTone, false)
        } else {
          Column({ space: 4 }) {
            Text('尚无关注账号').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.inkColor)
            Text(this.notice).fontSize(11).fontColor(this.mutedColor).maxLines(2)
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start).onClick(() => this.openDetail())
        }
        Row() {
          Text(this.abnormalLabel).fontSize(9).fontColor(this.mutedColor)
          Blank()
          Text(this.timeLabel).fontSize(9).fontColor(this.mutedColor).maxLines(1)
        }
        .width('100%').height(17).onClick(() => this.openDetail())
      }
    }
    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    .width('100%').height('100%')
    .backgroundColor(this.surfaceColor)
    .linearGradient({ angle: 135, colors: [[this.surfaceColor, 0], [this.surfaceEndColor, 1]] })
    .border({ width: this.glass === 'true' ? 1 : 0, color: this.edgeColor })
    .shadow({ radius: this.glass === 'true' ? 16 : 0, color: this.shadowColor })
  }
}
