import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Configuration, ConfigurationConstant, Want } from '@kit.AbilityKit';
import { MockFormData } from '../model/MockQuota';
import { refreshQuota, unconfiguredSnapshot, waitingSnapshot } from '../model/QuotaRefresh';
import { loadConfigSummary } from '../storage/LocalConfig';
import { loadFeaturedIds, loadFeaturedRevision, loadSingleId, loadSnapshot } from '../storage/QuotaSnapshotStore';
import { registerFormId, unregisterFormId } from '../storage/FormRegistry';
import { RefreshReason } from '../model/RefreshPolicy';
import { loadCardPreferences } from '../storage/CardPreferencesStore';
import { publishCurrentForms } from '../model/FormPublisher';

export default class QuotaFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    try {
      const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY];
      const requestedDimension = want.parameters?.[formInfo.FormParam.DIMENSION_KEY];
      const dimension = requestedDimension === '2*2' || Number(requestedDimension) === 2 ? 2 : 3;
      if (typeof formId === 'string') {
        registerFormId(this.context, formId, dimension);
      }
      const summary = loadConfigSummary(this.context);
      const snapshot = summary.hasKey ? loadSnapshot(this.context, summary.serviceUrl, summary.revision) : undefined;
      return formBindingData.createFormBindingData(new MockFormData(snapshot ||
        (summary.hasKey ? waitingSnapshot() : unconfiguredSnapshot()),
        dimension === 2 ? [loadSingleId(this.context)] : loadFeaturedIds(this.context),
        dimension, loadCardPreferences(this.context),
        this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK));
    } catch (_error) {
      return formBindingData.createFormBindingData(new MockFormData(unconfiguredSnapshot(), []));
    }
  }

  onUpdateForm(formId: string): void {
    this.updateLiveForm(formId, 'card');
  }

  onRemoveForm(formId: string): void {
    unregisterFormId(this.context, formId);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    const colorMode = newConfig.colorMode === undefined ? this.context.config.colorMode : newConfig.colorMode;
    this.updateFormAppearance(colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
  }

  private async updateFormAppearance(darkMode: boolean): Promise<void> {
    try {
      const summary = loadConfigSummary(this.context);
      const snapshot = summary.hasKey ? loadSnapshot(this.context, summary.serviceUrl, summary.revision) : undefined;
      await publishCurrentForms(this.context, snapshot ||
        (summary.hasKey ? waitingSnapshot() : unconfiguredSnapshot()), darkMode);
    } catch (_error) {
      // The next scheduled update will publish the current appearance.
    }
  }

  onFormEvent(formId: string, message: string): void {
    if (message.includes('refresh')) {
      this.updateLiveForm(formId, 'manual');
    }
  }

  onAcquireFormState(_want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }

  private async updateLiveForm(formId: string, reason: RefreshReason): Promise<void> {
    try {
      const revision = loadConfigSummary(this.context).revision;
      const featuredRevision = loadFeaturedRevision(this.context);
      const snapshot = await refreshQuota(this.context, reason);
      if (loadConfigSummary(this.context).revision !== revision ||
        loadFeaturedRevision(this.context) !== featuredRevision) {
        return;
      }
      await publishCurrentForms(this.context, snapshot);
    } catch (_error) {
      // The next card refresh can retry without exposing response or credential data in logs.
    }
  }
}
