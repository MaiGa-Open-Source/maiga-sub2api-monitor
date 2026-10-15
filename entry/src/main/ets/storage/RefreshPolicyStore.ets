import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { RefreshPolicyState, RefreshReason, canStartRefresh, completeRefresh, freshPolicy,
  remainingRefreshWait, reserveRefresh } from '../model/RefreshPolicy';
import { loadConfigSummary } from './LocalConfig';
import { loadCardPreferences } from './CardPreferencesStore';

const STORE_NAME = 'quota_refresh_policy';
const POLICY_KEY = 'policy';

function store(context: common.Context): preferences.Preferences {
  return preferences.getPreferencesSync(context, { name: STORE_NAME });
}

export function loadRefreshPolicy(context: common.Context, configRevision: number): RefreshPolicyState {
  try {
    const value = JSON.parse(store(context).getSync(POLICY_KEY, '') as string) as RefreshPolicyState;
    if (value && value.configRevision === configRevision && typeof value.requestId === 'string' &&
      typeof value.inFlight === 'boolean' &&
      Number.isSafeInteger(value.lastAttemptAt) && Number.isSafeInteger(value.nextAllowedAt) &&
      Number.isInteger(value.failureCount) && value.failureCount >= 0 && value.failureCount <= 16 &&
      typeof value.lastFailureKind === 'string' && Number.isSafeInteger(value.lastFailureAt)) {
      return value;
    }
  } catch (_error) {
  }
  return freshPolicy(configRevision);
}

export function nextRefreshAt(context: common.Context, configRevision: number): number {
  const now = Date.now();
  const policy = loadRefreshPolicy(context, configRevision);
  const settings = loadCardPreferences(context);
  if (policy.lastAttemptAt > 0 && now < policy.lastAttemptAt - 2 * 60000) {
    return 0;
  }
  const automaticAt = policy.lastAttemptAt > 0 ?
    policy.lastAttemptAt + settings.autoIntervalMinutes * 60000 : 0;
  return Math.max(policy.nextAllowedAt > now ? policy.nextAllowedAt : 0,
    automaticAt > now ? automaticAt : 0);
}

export async function beginRefresh(context: common.Context, configRevision: number,
  reason: RefreshReason): Promise<RefreshPolicyState | undefined> {
  const now = Date.now();
  const current = loadRefreshPolicy(context, configRevision);
  const settings = loadCardPreferences(context);
  if (!canStartRefresh(current, reason, now, settings)) {
    return undefined;
  }
  const reserved = reserveRefresh(current, now, `${now}-${Math.random()}`, settings);
  const prefs = store(context);
  prefs.putSync(POLICY_KEY, JSON.stringify(reserved));
  await prefs.flush();
  return reserved;
}

export async function finishRefresh(context: common.Context, reservation: RefreshPolicyState,
  failureKind: string): Promise<void> {
  if (loadConfigSummary(context).revision !== reservation.configRevision) {
    return;
  }
  const current = loadRefreshPolicy(context, reservation.configRevision);
  if (current.requestId !== reservation.requestId) {
    return;
  }
  const prefs = store(context);
  prefs.putSync(POLICY_KEY, JSON.stringify(completeRefresh(current, Date.now(), failureKind,
    loadCardPreferences(context))));
  await prefs.flush();
}
