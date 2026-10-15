import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { RefreshPolicyState, RefreshReason, canStartRefresh, completeRefresh, freshPolicy,
  reserveRefresh } from '../model/RefreshPolicy';
import { loadConfigSummary } from './LocalConfig';
import { loadCardPreferences } from './CardPreferencesStore';
import { loadTrendSelectionRevision } from './TrendStore';

const STORE_NAME = 'trend_refresh_policy';
const KEY = 'policy';

interface SavedPolicy {
  selectionRevision: number;
  policy: RefreshPolicyState;
}

function store(context: common.Context): preferences.Preferences {
  return preferences.getPreferencesSync(context, { name: STORE_NAME });
}

export function loadTrendPolicy(context: common.Context, configRevision: number,
  selectionRevision: number): RefreshPolicyState {
  try {
    const value = JSON.parse(store(context).getSync(KEY, '') as string) as SavedPolicy;
    const policy = value.policy;
    if (value.selectionRevision === selectionRevision && policy.configRevision === configRevision &&
      typeof policy.requestId === 'string' && typeof policy.inFlight === 'boolean' &&
      Number.isSafeInteger(policy.lastAttemptAt) && Number.isSafeInteger(policy.nextAllowedAt) &&
      Number.isInteger(policy.failureCount) && policy.failureCount >= 0 && policy.failureCount <= 16 &&
      typeof policy.lastFailureKind === 'string' && Number.isSafeInteger(policy.lastFailureAt)) return policy;
  } catch (_error) {
  }
  return freshPolicy(configRevision);
}

export async function beginTrendRefresh(context: common.Context, configRevision: number,
  selectionRevision: number, reason: RefreshReason): Promise<RefreshPolicyState | undefined> {
  const now = Date.now();
  const current = loadTrendPolicy(context, configRevision, selectionRevision);
  const settings = loadCardPreferences(context);
  if (!canStartRefresh(current, reason, now, settings)) return undefined;
  const reserved = reserveRefresh(current, now, `${now}-${Math.random()}`, settings);
  const prefs = store(context);
  prefs.putSync(KEY, JSON.stringify({ selectionRevision: selectionRevision, policy: reserved } as SavedPolicy));
  await prefs.flush();
  return reserved;
}

export async function finishTrendRefresh(context: common.Context, selectionRevision: number,
  reservation: RefreshPolicyState, failureKind: string): Promise<void> {
  if (loadConfigSummary(context).revision !== reservation.configRevision ||
    loadTrendSelectionRevision(context) !== selectionRevision) return;
  const current = loadTrendPolicy(context, reservation.configRevision, selectionRevision);
  if (current.requestId !== reservation.requestId) return;
  const prefs = store(context);
  prefs.putSync(KEY, JSON.stringify({ selectionRevision: selectionRevision,
    policy: completeRefresh(current, Date.now(), failureKind, loadCardPreferences(context)) } as SavedPolicy));
  await prefs.flush();
}
