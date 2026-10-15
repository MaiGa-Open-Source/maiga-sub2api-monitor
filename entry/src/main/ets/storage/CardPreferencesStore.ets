import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { CardPreferences, defaultCardPreferences, normalizeCardPreferences } from '../model/CardPreferences';

const STORE_NAME = 'quota_card_preferences';
const KEY = 'preferences';

function store(context: common.Context): preferences.Preferences {
  return preferences.getPreferencesSync(context, { name: STORE_NAME });
}

export function loadCardPreferences(context: common.Context): CardPreferences {
  try {
    return normalizeCardPreferences(JSON.parse(store(context).getSync(KEY, '{}') as string) as CardPreferences);
  } catch (_error) {
    return defaultCardPreferences();
  }
}

export async function saveCardPreferences(context: common.Context, value: CardPreferences): Promise<CardPreferences> {
  const normalized = normalizeCardPreferences(value);
  const prefs = store(context);
  prefs.putSync(KEY, JSON.stringify(normalized));
  await prefs.flush();
  return normalized;
}

export async function clearCardPreferences(context: common.Context): Promise<void> {
  const prefs = store(context);
  prefs.deleteSync(KEY);
  await prefs.flush();
}
