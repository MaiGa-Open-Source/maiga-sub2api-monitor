import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { clearLocalConfig, loadConfigSummary, normalizeServiceUrl, saveLocalConfig } from '../storage/LocalConfig';
import { clearSnapshot } from '../storage/QuotaSnapshotStore';
import { publishCurrentForms } from '../model/FormPublisher';
import { unconfiguredSnapshot, waitingSnapshot } from '../model/QuotaRefresh';
import { clearTrendData } from '../storage/TrendStore';
import { publishTrendForms } from '../model/TrendFormPublisher';
import { currentTrend } from '../model/TrendRefresh';
import { clearCardPreferences } from '../storage/CardPreferencesStore';

@Entry
@Component
struct Settings {
  @State private serviceUrl: string = '';
  @State private savedUrl: string = '';
  @State private adminKey: string = '';
  @State private hasKey: boolean = false;
  @State private isSaving: boolean = false;
  @State private feedback: string = '';
  @State private hasError: boolean = false;

  onPageShow(): void {
    try {
      const summary = loadConfigSummary(getContext(this) as common.UIAbilityContext);
      this.serviceUrl = summary.serviceUrl;
      this.savedUrl = summary.serviceUrl;
      this.hasKey = summary.hasKey;
    } catch (_error) {
      this.showFeedback('无法读取本机配置', true);
    }
  }

  onPageHide(): void {
    this.adminKey = '';
  }

  private showFeedback(message: string, error: boolean): void {
    this.feedback = message;
    this.hasError = error;
  }

  private async save(): Promise<void> {
    if (this.isSaving) {
      return;
    }
    let normalized: string;
    try {
      normalized = normalizeServiceUrl(this.serviceUrl);
    } catch (_error) {
      this.showFeedback('请输入有效的 HTTPS 服务地址，不含账号、查询参数或片段', true);
      return;
    }
    if (!this.adminKey.trim() && (!this.hasKey || normalized !== this.savedUrl)) {
      this.showFeedback('首次配置或更换服务地址时，请输入 Admin Key', true);
      return;
    }
    if (this.adminKey.length > 4096 || /[\r\n]/.test(this.adminKey)) {
      this.showFeedback('Admin Key 格式无效', true);
      return;
    }

    this.isSaving = true;
    this.showFeedback('', false);
    const adminKey = this.adminKey;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const summary = await saveLocalConfig(context, normalized, adminKey);
      let failedForms = 0;
      if (adminKey.trim()) {
        await clearSnapshot(context);
        await clearTrendData(context);
        failedForms += await publishCurrentForms(context, waitingSnapshot());
        failedForms += await publishTrendForms(context, currentTrend(context));
      }
      this.serviceUrl = summary.serviceUrl;
      this.savedUrl = summary.serviceUrl;
      this.adminKey = '';
      this.hasKey = summary.hasKey;
      this.showFeedback(failedForms > 0 ?
        '配置已保存；部分桌面卡片未更新，请从桌面移除后重新添加' : '已保存到此设备', failedForms > 0);
    } catch (_error) {
      this.showFeedback('保存失败，请检查设备安全服务后重试', true);
    } finally {
      this.isSaving = false;
    }
  }

  private async clear(): Promise<void> {
    if (this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await clearLocalConfig(context);
      await clearSnapshot(context);
      await clearTrendData(context);
      await clearCardPreferences(context);
      const failedQuotaForms = await publishCurrentForms(context, unconfiguredSnapshot());
      const failedTrendForms = await publishTrendForms(context, currentTrend(context));
      const failedForms = failedQuotaForms + failedTrendForms;
      this.serviceUrl = '';
      this.savedUrl = '';
      this.adminKey = '';
      this.hasKey = false;
      this.showFeedback(failedForms > 0 ?
        '本机配置已删除；部分桌面卡片可能仍显示旧内容，请从桌面移除' :
        '本机配置已删除；请确认桌面卡片已清空', failedForms > 0);
    } catch (_error) {
      this.showFeedback('删除失败，请重试', true);
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        Button('返回')
          .fontSize(14)
          .fontColor($r('app.color.quota_ink'))
          .backgroundColor(Color.Transparent)
          .padding(0)
          .onClick(() => router.back())
          .margin({ bottom: 18 })

        Text('连接配置')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.quota_ink'))
          .width('100%')
        Text('Sub2API')
          .fontSize(12)
          .fontColor($r('app.color.quota_muted'))
          .margin({ top: 4, bottom: 28 })

        Text('服务地址')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.quota_ink'))
          .margin({ bottom: 10 })
        TextInput({ text: this.serviceUrl, placeholder: 'https://example.com' })
          .type(InputType.Normal)
          .maxLength(512)
          .onChange((value: string) => {
            this.serviceUrl = value;
            this.feedback = '';
          })
          .width('100%')
          .height(48)
          .margin({ bottom: 26 })

        Row() {
          Text('Admin Key')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.quota_ink'))
          Blank()
          if (this.hasKey) {
            Text('本机已保存')
              .fontSize(12)
              .fontColor($r('app.color.quota_healthy'))
          }
        }
        .width('100%')
        .margin({ bottom: 10 })
        TextInput({ text: this.adminKey, placeholder: this.hasKey ? '留空则保留当前密钥' : '输入 Admin Key' })
          .type(InputType.Password)
          .maxLength(4096)
          .onChange((value: string) => {
            this.adminKey = value;
            this.feedback = '';
          })
          .width('100%')
          .height(48)
        Text('已保存的密钥不会在此显示')
          .fontSize(12)
          .fontColor($r('app.color.quota_muted'))
          .margin({ top: 9, bottom: 24 })

        if (this.feedback) {
          Text(this.feedback)
            .fontSize(13)
            .fontColor(this.hasError ? $r('app.color.quota_error') : $r('app.color.quota_healthy'))
            .width('100%')
            .margin({ bottom: 14 })
        }

        Button(this.isSaving ? '保存中' : '保存配置')
          .enabled(!this.isSaving)
          .width('100%')
          .height(46)
          .backgroundColor($r('app.color.quota_healthy'))
          .onClick(() => {
            this.save();
          })

        if (this.hasKey) {
          Button('删除本机配置')
            .enabled(!this.isSaving)
            .fontColor($r('app.color.quota_error'))
            .backgroundColor(Color.Transparent)
            .margin({ top: 24 })
            .onClick(() => {
              AlertDialog.show({
                title: '删除本机配置',
                message: '将删除此设备保存的服务地址和 Admin Key。',
                primaryButton: { value: '取消', action: () => {} },
                secondaryButton: { value: '删除', action: () => { this.clear(); } }
              });
            })
        }

        Column({ space: 8 }) {
          Text('隐私与开源')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.quota_ink'))
          Text('设备直接连接你填写的服务。密钥和账号快照保存在本机，项目方没有中转服务器。')
            .fontSize(12)
            .fontColor($r('app.color.quota_muted'))
          Text('本项目按 MIT License 开源。')
            .fontSize(12)
            .fontColor($r('app.color.quota_muted'))
          Hyperlink('https://github.com/MaiGa-Open-Source/maiga-sub2api-monitor',
            '查看源码、隐私说明和许可证')
            .color($r('app.color.quota_healthy'))
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .margin({ top: 32 })
      }
      .padding({ left: 20, right: 20, top: 24, bottom: 36 })
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.quota_background'))
  }
}
