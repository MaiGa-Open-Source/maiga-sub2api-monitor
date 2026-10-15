import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { MockFormData, QuotaSnapshot } from './MockQuota';
import { loadForms } from '../storage/FormRegistry';
import { loadFeaturedIds, loadSingleId } from '../storage/QuotaSnapshotStore';
import { loadCardPreferences } from '../storage/CardPreferencesStore';

function isSystemDark(context: common.Context): boolean {
  try {
    return Number(context.resourceManager.getConfigurationSync().colorMode) ===
      ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  } catch (_error) {
    return false;
  }
}

export async function publishCurrentForms(context: common.Context, snapshot: QuotaSnapshot,
  darkMode?: boolean): Promise<number> {
  const settings = loadCardPreferences(context);
  const useDark = darkMode === undefined ? isSystemDark(context) : darkMode;
  let failed = 0;
  for (const form of loadForms(context)) {
    try {
      const ids = form.dimension === 2 ? [loadSingleId(context)] : loadFeaturedIds(context);
      const data = formBindingData.createFormBindingData(new MockFormData(snapshot, ids,
        form.dimension, settings, useDark));
      await formProvider.updateForm(form.id, data);
    } catch (_error) {
      failed++;
    }
  }
  return failed;
}
