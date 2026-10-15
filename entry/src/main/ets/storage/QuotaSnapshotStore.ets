import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { AccountPreview, QuotaSnapshot } from '../model/MockQuota';
import { loadConfigSummary } from './LocalConfig';

const STORE_NAME = 'quota_snapshot';
const URL_KEY = 'service_url';
const SNAPSHOT_KEY = 'snapshot';
const FEATURED_KEY = 'featured_ids';
const SINGLE_KEY = 'single_id';
const FEATURED_REVISION_KEY = 'featured_revision';
const CONFIG_REVISION_KEY = 'config_revision';

function store(context: common.Context): preferences.Preferences {
  return preferences.getPreferencesSync(context, { name: STORE_NAME });
}

export function loadFeaturedIds(context: common.Context): number[] {
  try {
    const raw = store(context).getSync(FEATURED_KEY, '[]');
    const ids = JSON.parse(raw as string) as number[];
    return Array.isArray(ids) ? ids.filter((id: number) => Number.isInteger(id) && id > 0).slice(0, 2) : [];
  } catch (_error) {
    return [];
  }
}

export function loadFeaturedRevision(context: common.Context): number {
  return store(context).getSync(FEATURED_REVISION_KEY, 0) as number;
}

export function loadSingleId(context: common.Context): number {
  const id = store(context).getSync(SINGLE_KEY, 0) as number;
  return Number.isInteger(id) && id > 0 ? id : 0;
}

export async function saveSingleId(context: common.Context, id: number): Promise<void> {
  const prefs = store(context);
  prefs.putSync(SINGLE_KEY, Number.isInteger(id) && id > 0 ? id : 0);
  prefs.putSync(FEATURED_REVISION_KEY, loadFeaturedRevision(context) + 1);
  await prefs.flush();
}

export async function saveFeaturedIds(context: common.Context, ids: number[]): Promise<void> {
  const selected = ids.filter((id: number) => Number.isInteger(id) && id > 0).slice(0, 2);
  const prefs = store(context);
  prefs.putSync(FEATURED_KEY, JSON.stringify(selected));
  prefs.putSync(FEATURED_REVISION_KEY, loadFeaturedRevision(context) + 1);
  await prefs.flush();
}

export function loadSnapshot(context: common.Context, serviceUrl: string,
  configRevision: number, markStale: boolean = true): QuotaSnapshot | undefined {
  try {
    const prefs = store(context);
    if (prefs.getSync(URL_KEY, '') !== serviceUrl || prefs.getSync(CONFIG_REVISION_KEY, -1) !== configRevision) {
      return undefined;
    }
    const raw = prefs.getSync(SNAPSHOT_KEY, '');
    const snapshot = JSON.parse(raw as string) as QuotaSnapshot;
    if (!snapshot || !Array.isArray(snapshot.accounts) || !snapshot.lastSuccessAt) {
      return undefined;
    }
    snapshot.cached = true;
    if (markStale) {
      snapshot.health = 'stale';
      snapshot.statusLabel = '数据待刷新';
      snapshot.notice = '显示上次成功数据';
    }
    return snapshot;
  } catch (_error) {
    return undefined;
  }
}

export async function saveSnapshot(context: common.Context, serviceUrl: string, configRevision: number,
  featuredRevision: number, snapshot: QuotaSnapshot): Promise<boolean> {
  const summary = loadConfigSummary(context);
  if (!summary.hasKey || summary.serviceUrl !== serviceUrl || summary.revision !== configRevision ||
    loadFeaturedRevision(context) !== featuredRevision) {
    return false;
  }
  const prefs = store(context);
  const displayOnly: QuotaSnapshot = {
    health: snapshot.health,
    statusLabel: snapshot.statusLabel,
    notice: snapshot.notice,
    checkedAt: snapshot.checkedAt,
    lastSuccessAt: snapshot.lastSuccessAt,
    cached: true,
    savedAt: snapshot.savedAt,
    accounts: snapshot.accounts.map((account: AccountPreview): AccountPreview => {
      return {
        id: account.id, name: account.name, platform: account.platform, region: account.region,
        period: account.period, remaining: account.remaining, health: account.health,
        stateLabel: account.stateLabel
      };
    })
  };
  prefs.putSync(URL_KEY, serviceUrl);
  prefs.putSync(CONFIG_REVISION_KEY, configRevision);
  prefs.putSync(SNAPSHOT_KEY, JSON.stringify(displayOnly));
  await prefs.flush();
  return true;
}

export async function clearSnapshot(context: common.Context): Promise<void> {
  const prefs = store(context);
  prefs.deleteSync(URL_KEY);
  prefs.deleteSync(CONFIG_REVISION_KEY);
  prefs.deleteSync(SNAPSHOT_KEY);
  prefs.deleteSync(FEATURED_KEY);
  prefs.deleteSync(SINGLE_KEY);
  prefs.putSync(FEATURED_REVISION_KEY, loadFeaturedRevision(context) + 1);
  await prefs.flush();
}
