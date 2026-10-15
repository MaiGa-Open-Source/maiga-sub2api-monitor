import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Configuration, ConfigurationConstant, Want } from '@kit.AbilityKit';
import { loadCardPreferences } from '../storage/CardPreferencesStore';
import { loadTrendForm, registerTrendForm, removeTrendForm, saveTrendForm } from '../storage/TrendFormRegistry';
import { TrendFormData } from '../model/TrendFormData';
import { currentTrend, emptyTrend, refreshTrend } from '../model/TrendRefresh';
import { publishTrendFormById, publishTrendForms } from '../model/TrendFormPublisher';
import { RefreshReason } from '../model/RefreshPolicy';

export default class TrendFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    try {
      const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY];
      const requested = want.parameters?.[formInfo.FormParam.DIMENSION_KEY];
      const dimension = requested === '4*4' || Number(requested) === 4 ? 4 : 3;
      const form = registerTrendForm(this.context, String(formId || ''), dimension);
      return formBindingData.createFormBindingData(new TrendFormData(currentTrend(this.context), form,
        loadCardPreferences(this.context),
        this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK));
    } catch (_error) {
      return formBindingData.createFormBindingData(new TrendFormData(emptyTrend(),
        { id: '', dimension: 3, days: 7, metric: 'requests', selectedIndex: -1 }));
    }
  }

  onUpdateForm(formId: string): void {
    this.updateLiveForm(formId, 'card');
  }

  onRemoveForm(formId: string): void {
    removeTrendForm(this.context, formId);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    const mode = newConfig.colorMode === undefined ? this.context.config.colorMode : newConfig.colorMode;
    publishTrendForms(this.context, currentTrend(this.context),
      mode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
  }

  onFormEvent(formId: string, message: string): void {
    let command: string = '';
    try {
      const params = JSON.parse(message) as Record<string, string>;
      command = typeof params.command === 'string' ? params.command : '';
    } catch (_error) {
      return;
    }
    if (command === 'refresh') {
      this.updateLiveForm(formId, 'manual');
      return;
    }
    const form = loadTrendForm(this.context, formId);
    if (!form) return;
    if (command === 'period-7' || command === 'period-30') {
      form.days = command === 'period-30' ? 30 : 7;
      form.selectedIndex = -1;
    } else if (command === 'metric-requests' || command === 'metric-cost') {
      form.metric = command === 'metric-cost' ? 'cost' : 'requests';
    } else if (/^day-(?:[0-9]|[12][0-9])$/.test(command)) {
      const index = Number(command.slice(4));
      if (index >= form.days) return;
      form.selectedIndex = index;
    } else {
      return;
    }
    saveTrendForm(this.context, form);
    publishTrendFormById(this.context, formId).catch(() => {});
  }

  onAcquireFormState(_want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }

  private async updateLiveForm(formId: string, reason: RefreshReason): Promise<void> {
    try {
      const snapshot = await refreshTrend(this.context, reason);
      await publishTrendForms(this.context, snapshot);
    } catch (_error) {
      try { await publishTrendFormById(this.context, formId); } catch (_publishError) {}
    }
  }
}
