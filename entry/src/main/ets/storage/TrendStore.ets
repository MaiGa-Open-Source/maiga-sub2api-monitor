import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { TrendDay, TrendSnapshot } from '../model/TrendStats';
import { loadConfigSummary } from './LocalConfig';

const STORE_NAME = 'trend_monitor';
const ACCOUNT_KEY = 'account_id';
const REVISION_KEY = 'selection_revision';
const CACHE_KEY = 'snapshot';

interface SavedTrend {
  serviceUrl: string;
  configRevision: number;
  selectionRevision: number;
  snapshot: TrendSnapshot;
}

function store(context: common.Context): preferences.Preferences {
  return preferences.getPreferencesSync(context, { name: STORE_NAME });
}

export function loadTrendAccountId(context: common.Context): number {
  const id = store(context).getSync(ACCOUNT_KEY, 0) as number;
  return Number.isSafeInteger(id) && id > 0 ? id : 0;
}

export function loadTrendSelectionRevision(context: common.Context): number {
  return store(context).getSync(REVISION_KEY, 0) as number;
}

export async function saveTrendAccountId(context: common.Context, accountId: number): Promise<void> {
  const id = Number.isSafeInteger(accountId) && accountId > 0 ? accountId : 0;
  if (loadTrendAccountId(context) === id) return;
  const prefs = store(context);
  prefs.putSync(ACCOUNT_KEY, id);
  prefs.putSync(REVISION_KEY, loadTrendSelectionRevision(context) + 1);
  prefs.deleteSync(CACHE_KEY);
  await prefs.flush();
}

export function loadTrendSnapshot(context: common.Context, serviceUrl: string,
  configRevision: number, accountId: number): TrendSnapshot | undefined {
  try {
    const value = JSON.parse(store(context).getSync(CACHE_KEY, '') as string) as SavedTrend;
    if (!value || value.serviceUrl !== serviceUrl || value.configRevision !== configRevision ||
      value.selectionRevision !== loadTrendSelectionRevision(context) ||
      value.snapshot?.accountId !== accountId || !Array.isArray(value.snapshot.history) ||
      !Number.isSafeInteger(value.snapshot.savedAt)) return undefined;
    for (const day of value.snapshot.history) {
      if (typeof day.date !== 'string' || !Number.isSafeInteger(day.requests) ||
        !Number.isFinite(day.actualCost)) return undefined;
    }
    const status = value.snapshot.status;
    if (status !== 'ready' && status !== 'offline' && status !== 'auth') return undefined;
    return { accountId: value.snapshot.accountId, accountName: value.snapshot.accountName,
      history: value.snapshot.history, savedAt: value.snapshot.savedAt, status: status,
      notice: typeof value.snapshot.notice === 'string' ? value.snapshot.notice : '' };
  } catch (_error) {
    return undefined;
  }
}

export async function saveTrendSnapshot(context: common.Context, serviceUrl: string,
  configRevision: number, selectionRevision: number, snapshot: TrendSnapshot): Promise<boolean> {
  const summary = loadConfigSummary(context);
  if (!summary.hasKey || summary.serviceUrl !== serviceUrl || summary.revision !== configRevision ||
    loadTrendSelectionRevision(context) !== selectionRevision ||
    loadTrendAccountId(context) !== snapshot.accountId) return false;
  const displayOnly: TrendSnapshot = {
    accountId: snapshot.accountId,
    accountName: snapshot.accountName,
    history: snapshot.history.map((day: TrendDay): TrendDay => ({
      date: day.date, requests: day.requests, actualCost: day.actualCost
    })),
    savedAt: snapshot.savedAt,
    status: snapshot.status,
    notice: snapshot.notice
  };
  store(context).putSync(CACHE_KEY, JSON.stringify({
    serviceUrl: serviceUrl, configRevision: configRevision, selectionRevision: selectionRevision,
    snapshot: displayOnly
  } as SavedTrend));
  await store(context).flush();
  return true;
}

export async function clearTrendData(context: common.Context): Promise<void> {
  const prefs = store(context);
  prefs.deleteSync(ACCOUNT_KEY);
  prefs.deleteSync(CACHE_KEY);
  prefs.putSync(REVISION_KEY, loadTrendSelectionRevision(context) + 1);
  await prefs.flush();
}
