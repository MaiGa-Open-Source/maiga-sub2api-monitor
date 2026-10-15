import { AccountPreview, abnormalCount, QuotaSnapshot } from '../model/MockQuota';
import { refreshQuota, unconfiguredSnapshot, waitingSnapshot } from '../model/QuotaRefresh';
import { loadConfigSummary } from '../storage/LocalConfig';
import { loadFeaturedIds, loadFeaturedRevision, loadSnapshot, saveFeaturedIds } from '../storage/QuotaSnapshotStore';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { publishCurrentForms } from '../model/FormPublisher';
import { RefreshReason } from '../model/RefreshPolicy';
import { nextRefreshAt } from '../storage/RefreshPolicyStore';

@Entry
@Component
struct Index {
  @State private refreshing: boolean = false;
  @State private nextAllowedAt: number = 0;
  @State private clockNow: number = 0;
  private refreshAgain: boolean = false;
  private refreshTimer: number = -1;
  private pageVisible: boolean = false;
  @State private selectedIds: number[] = [];
  @State private snapshot: QuotaSnapshot = unconfiguredSnapshot();

  onPageShow(): void {
    this.pageVisible = true;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const summary = loadConfigSummary(context);
      this.selectedIds = loadFeaturedIds(context);
      this.snapshot = summary.hasKey ? loadSnapshot(context, summary.serviceUrl, summary.revision) || waitingSnapshot() :
        unconfiguredSnapshot();
      this.syncRefreshAvailability();
      if (summary.hasKey) {
        this.refresh('automatic');
      }
    } catch (_error) {
      this.snapshot = unconfiguredSnapshot();
    }
  }

  onPageHide(): void {
    this.pageVisible = false;
    if (this.refreshTimer >= 0) {
      clearTimeout(this.refreshTimer);
      this.refreshTimer = -1;
    }
  }

  private syncRefreshAvailability(): void {
    if (this.refreshTimer >= 0) {
      clearTimeout(this.refreshTimer);
      this.refreshTimer = -1;
    }
    const context = getContext(this) as common.UIAbilityContext;
    const summary = loadConfigSummary(context);
    this.clockNow = Date.now();
    this.nextAllowedAt = summary.hasKey ? nextRefreshAt(context, summary.revision) : 0;
    if (this.pageVisible && this.nextAllowedAt > this.clockNow) {
      this.refreshTimer = setTimeout(() => this.syncRefreshAvailability(),
        this.nextAllowedAt - this.clockNow + 1);
    }
  }

  private nextRefreshLabel(): string {
    const time = new Date(this.nextAllowedAt);
    return `${time.getHours().toString().padStart(2, '0')}:` +
      `${time.getMinutes().toString().padStart(2, '0')}:` +
      `${time.getSeconds().toString().padStart(2, '0')}`;
  }

  private async refresh(reason: RefreshReason = 'manual'): Promise<void> {
    if (this.refreshing) {
      return;
    }
    this.refreshing = true;
    if (this.snapshot.lastSuccessAt) {
      this.snapshot = {
        health: 'refreshing', statusLabel: '刷新中', notice: '正在检查，显示上次成功数据',
        checkedAt: this.snapshot.checkedAt, lastSuccessAt: this.snapshot.lastSuccessAt,
        cached: true, savedAt: this.snapshot.savedAt, accounts: this.snapshot.accounts
      };
    }
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const revision = loadConfigSummary(context).revision;
      const featuredRevision = loadFeaturedRevision(context);
      const result = await refreshQuota(context, reason);
      if (loadConfigSummary(context).revision === revision &&
        loadFeaturedRevision(context) === featuredRevision) {
        this.snapshot = result;
        await publishCurrentForms(context, result);
      }
    } finally {
      this.refreshing = false;
      this.syncRefreshAvailability();
      if (this.refreshAgain) {
        this.refreshAgain = false;
        this.refresh('selection');
      }
    }
  }

  private async toggleFeatured(id: number): Promise<void> {
    if (id <= 0) {
      return;
    }
    let ids = this.selectedIds.slice();
    if (ids.includes(id)) {
      ids = ids.filter((value: number) => value !== id);
    } else if (ids.length < 2) {
      ids.push(id);
    } else {
      return;
    }
    this.selectedIds = ids;
    await saveFeaturedIds(getContext(this) as common.UIAbilityContext, ids);
    if (this.refreshing) {
      this.refreshAgain = true;
    } else {
      this.refresh('selection');
    }
  }

  private statusColor(): ResourceColor {
    if (this.snapshot.health === 'offline' || this.snapshot.health === 'authRequired') {
      return $r('app.color.quota_error');
    }
    if (this.snapshot.health !== 'ready' || abnormalCount(this.snapshot.accounts) > 0 ||
      (this.snapshot.accounts.length > 0 && !this.snapshot.accounts.some((account: AccountPreview) =>
        this.selectedIds.includes(account.id || 0))) ||
      this.snapshot.accounts.some((account: AccountPreview) =>
        this.selectedIds.includes(account.id || 0) && account.health === 'unknown')) {
      return $r('app.color.quota_warning');
    }
    return $r('app.color.quota_healthy');
  }

  private accountColor(health: string): ResourceColor {
    if (health === 'unavailable') {
      return $r('app.color.quota_error');
    }
    if (health === 'low' || health === 'unknown') {
      return $r('app.color.quota_warning');
    }
    return $r('app.color.quota_healthy');
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        Row() {
          Text('套餐额度')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.quota_ink'))
          Blank()
          Button('配置')
            .fontSize(14)
            .fontColor($r('app.color.quota_ink'))
            .backgroundColor(Color.Transparent)
            .onClick(() => router.pushUrl({ url: 'pages/Settings' }))
          Button('卡片')
            .fontSize(14)
            .fontColor($r('app.color.quota_ink'))
            .backgroundColor(Color.Transparent)
            .onClick(() => router.pushUrl({ url: 'pages/CardSettings' }))
          Button(this.refreshing ? '刷新中' : '刷新')
            .fontSize(14)
            .fontColor($r('app.color.quota_healthy'))
            .backgroundColor(Color.Transparent)
            .enabled(!this.refreshing)
            .onClick(() => this.refresh())
        }
        .width('100%')
        Text('Sub2API · 实时数据')
          .fontSize(12)
          .fontColor($r('app.color.quota_muted'))
          .margin({ top: 4, bottom: 24 })
          .width('100%')

        Row() {
          Column({ space: 5 }) {
            Text(this.snapshot.statusLabel)
              .fontSize(19)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.statusColor())
            Text(this.snapshot.notice)
              .fontSize(13)
              .fontColor($r('app.color.quota_muted'))
              .maxLines(2)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 16, bottom: 16 })
        .border({ width: { top: 1, bottom: 1 }, color: $r('app.color.quota_line') })

        Row() {
          Text(`${this.snapshot.accounts.length} 个账号 · ${abnormalCount(this.snapshot.accounts)} 个已知异常`)
            .fontSize(12)
            .fontColor($r('app.color.quota_ink'))
          Blank()
          Text(this.snapshot.cached ? '上次成功快照' : '当前快照')
            .fontSize(12)
            .fontColor($r('app.color.quota_muted'))
        }
        .width('100%')
        .margin({ top: 16, bottom: 6 })

        if (this.snapshot.accounts.length === 0) {
          Column({ space: 8 }) {
            Text(this.snapshot.health === 'empty' && this.snapshot.statusLabel === '尚无账号' ?
              '暂无上游账号' : this.snapshot.statusLabel)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.quota_ink'))
            Text(this.snapshot.notice)
              .fontSize(13)
              .fontColor($r('app.color.quota_muted'))
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ top: 24, bottom: 32 })
        } else {
          Text(`双账号卡片关注 ${this.selectedIds.length}/2`)
            .fontSize(12)
            .fontColor($r('app.color.quota_muted'))
            .width('100%')
          ForEach(this.snapshot.accounts, (account: AccountPreview) => {
            Row() {
              Column({ space: 5 }) {
                Text(account.name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.quota_ink'))
                  .maxLines(1)
                Text([account.platform, account.region, account.period].filter((part: string) =>
                  part.length > 0).join(' · '))
                  .fontSize(12)
                  .fontColor($r('app.color.quota_muted'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Column({ space: 5 }) {
                Text(account.remaining)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.accountColor(account.health))
                Text(account.stateLabel)
                  .fontSize(12)
                  .fontColor(this.accountColor(account.health))
              }
              .alignItems(HorizontalAlign.End)
              .width(88)
              Checkbox({ name: `account-${account.id}`, group: 'featured' })
                .select(this.selectedIds.includes(account.id || 0))
                .enabled(this.selectedIds.length < 2 || this.selectedIds.includes(account.id || 0))
                .onChange(() => this.toggleFeatured(account.id || 0))
                .margin({ left: 8 })
            }
            .width('100%')
            .height(78)
            .border({ width: { bottom: 1 }, color: $r('app.color.quota_line') })
          }, (account: AccountPreview) => `${account.id || account.name}`)
        }

        Column({ space: 5 }) {
          Text(`上次成功 ${this.snapshot.lastSuccessAt || '尚无'}`)
            .fontSize(12)
            .fontColor($r('app.color.quota_muted'))
          Text(`本次检查 ${this.snapshot.checkedAt}`)
            .fontSize(12)
            .fontColor($r('app.color.quota_muted'))
          if (this.nextAllowedAt > this.clockNow) {
            Text(`下次自动请求 ${this.nextRefreshLabel()}`)
              .fontSize(12)
              .fontColor($r('app.color.quota_muted'))
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .margin({ top: 18, bottom: 32 })

      }
      .padding({ left: 20, right: 20, top: 28, bottom: 30 })
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.quota_background'))
  }
}
