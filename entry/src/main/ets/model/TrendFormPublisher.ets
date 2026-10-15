import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { loadCardPreferences } from '../storage/CardPreferencesStore';
import { loadTrendForm, loadTrendForms, TrendFormView } from '../storage/TrendFormRegistry';
import { currentTrend } from './TrendRefresh';
import { TrendSnapshot } from './TrendStats';
import { TrendFormData } from './TrendFormData';

function isSystemDark(context: common.Context): boolean {
  try {
    return Number(context.resourceManager.getConfigurationSync().colorMode) ===
      ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  } catch (_error) {
    return false;
  }
}

export async function publishTrendForm(context: common.Context, form: TrendFormView,
  snapshot: TrendSnapshot = currentTrend(context), darkMode?: boolean): Promise<void> {
  const data = formBindingData.createFormBindingData(new TrendFormData(snapshot, form,
    loadCardPreferences(context), darkMode === undefined ? isSystemDark(context) : darkMode));
  await formProvider.updateForm(form.id, data);
}

export async function publishTrendForms(context: common.Context,
  snapshot: TrendSnapshot = currentTrend(context), darkMode?: boolean): Promise<number> {
  let failed = 0;
  for (const form of loadTrendForms(context)) {
    try { await publishTrendForm(context, form, snapshot, darkMode); } catch (_error) { failed++; }
  }
  return failed;
}

export async function publishTrendFormById(context: common.Context, formId: string,
  snapshot: TrendSnapshot = currentTrend(context)): Promise<void> {
  const form = loadTrendForm(context, formId);
  if (form) await publishTrendForm(context, form, snapshot);
}
