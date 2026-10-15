import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const STORE_NAME = 'quota_forms';
const IDS_KEY = 'form_ids';

export interface RegisteredForm {
  id: string;
  dimension: number;
}

function store(context: common.Context): preferences.Preferences {
  return preferences.getPreferencesSync(context, { name: STORE_NAME });
}

export function loadForms(context: common.Context): RegisteredForm[] {
  try {
    const values = JSON.parse(store(context).getSync(IDS_KEY, '[]') as string) as Array<RegisteredForm | string>;
    if (!Array.isArray(values)) return [];
    const forms: RegisteredForm[] = [];
    for (const value of values) {
      if (typeof value === 'string' && value.length > 0) {
        forms.push({ id: value, dimension: 3 });
      } else if (typeof value !== 'string' && value && typeof value.id === 'string' && value.id.length > 0) {
        forms.push({ id: value.id, dimension: value.dimension === 2 ? 2 : 3 });
      }
    }
    return forms;
  } catch (_error) {
    return [];
  }
}

export function formDimension(context: common.Context, formId: string): number {
  return loadForms(context).find((entry: RegisteredForm) => entry.id === formId)?.dimension || 3;
}

export function registerFormId(context: common.Context, formId: string, dimension: number): void {
  if (!formId) {
    return;
  }
  const prefs = store(context);
  prefs.putSync(IDS_KEY, JSON.stringify([...loadForms(context).filter((entry: RegisteredForm) =>
    entry.id !== formId), { id: formId, dimension: dimension === 2 ? 2 : 3 }]));
  prefs.flush().then(() => {}, () => {});
}

export function unregisterFormId(context: common.Context, formId: string): void {
  const prefs = store(context);
  prefs.putSync(IDS_KEY, JSON.stringify(loadForms(context).filter((entry: RegisteredForm) => entry.id !== formId)));
  prefs.flush().then(() => {}, () => {});
}
