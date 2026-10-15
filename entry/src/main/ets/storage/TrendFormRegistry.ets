import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { TrendMetric } from '../model/TrendStats';

const STORE_NAME = 'trend_forms';
const KEY = 'forms';

export interface TrendFormView {
  id: string;
  dimension: number;
  days: number;
  metric: TrendMetric;
  selectedIndex: number;
}

function store(context: common.Context): preferences.Preferences {
  return preferences.getPreferencesSync(context, { name: STORE_NAME });
}

export function loadTrendForms(context: common.Context): TrendFormView[] {
  try {
    const values = JSON.parse(store(context).getSync(KEY, '[]') as string) as TrendFormView[];
    if (!Array.isArray(values)) return [];
    return values.filter((value: TrendFormView) => value && typeof value.id === 'string' && value.id.length > 0)
      .map((value: TrendFormView): TrendFormView => ({
        id: value.id,
        dimension: value.dimension === 4 ? 4 : 3,
        days: value.days === 30 ? 30 : 7,
        metric: value.metric === 'cost' ? 'cost' : 'requests',
        selectedIndex: Number.isInteger(value.selectedIndex) && value.selectedIndex >= 0 &&
          value.selectedIndex < 30 ? value.selectedIndex : -1
      }));
  } catch (_error) {
    return [];
  }
}

export function loadTrendForm(context: common.Context, formId: string): TrendFormView | undefined {
  return loadTrendForms(context).find((form: TrendFormView) => form.id === formId);
}

export function registerTrendForm(context: common.Context, formId: string, dimension: number): TrendFormView {
  const form: TrendFormView = { id: formId, dimension: dimension === 4 ? 4 : 3,
    days: 7, metric: 'requests', selectedIndex: -1 };
  saveTrendForm(context, form);
  return form;
}

export function saveTrendForm(context: common.Context, form: TrendFormView): void {
  const prefs = store(context);
  prefs.putSync(KEY, JSON.stringify([...loadTrendForms(context).filter((value: TrendFormView) =>
    value.id !== form.id), form]));
  prefs.flush().then(() => {}, () => {});
}

export function removeTrendForm(context: common.Context, formId: string): void {
  const prefs = store(context);
  prefs.putSync(KEY, JSON.stringify(loadTrendForms(context).filter((form: TrendFormView) => form.id !== formId)));
  prefs.flush().then(() => {}, () => {});
}
