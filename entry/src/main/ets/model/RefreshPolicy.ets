import { CardPreferences, defaultCardPreferences } from './CardPreferences';

export type RefreshReason = 'automatic' | 'card' | 'manual' | 'selection';

export interface RefreshPolicyState {
  configRevision: number;
  requestId: string;
  inFlight: boolean;
  lastAttemptAt: number;
  nextAllowedAt: number;
  failureCount: number;
  lastFailureKind: string;
  lastFailureAt: number;
}

export const MIN_REFRESH_INTERVAL_MS: number = 60 * 1000;
export const MAX_FAILURE_DELAY_MS: number = 60 * 60 * 1000;

export function freshPolicy(configRevision: number): RefreshPolicyState {
  return { configRevision: configRevision, requestId: '', inFlight: false, lastAttemptAt: 0, nextAllowedAt: 0,
    failureCount: 0, lastFailureKind: '', lastFailureAt: 0 };
}

export function remainingRefreshWait(state: RefreshPolicyState, now: number): number {
  const remaining = state.nextAllowedAt - now;
  return remaining > 0 && remaining <= 24 * 60 * 60 * 1000 ? remaining : 0;
}

export function canStartRefresh(state: RefreshPolicyState, reason: RefreshReason, now: number,
  settings: CardPreferences = defaultCardPreferences()): boolean {
  if (state.inFlight && now - state.lastAttemptAt < 2 * MIN_REFRESH_INTERVAL_MS) {
    return false;
  }
  if (reason === 'manual') {
    return true;
  }
  if (state.lastAttemptAt > 0 && now < state.lastAttemptAt - 2 * MIN_REFRESH_INTERVAL_MS) {
    return true;
  }
  if (reason === 'selection' && state.failureCount === 0) {
    return true;
  }
  if (reason === 'selection') {
    return remainingRefreshWait(state, now) === 0;
  }
  const interval = (reason === 'card' ? Math.max(settings.cardPeriodMinutes, settings.autoIntervalMinutes) :
    settings.autoIntervalMinutes) * MIN_REFRESH_INTERVAL_MS;
  const automaticAt = state.lastAttemptAt > 0 ? state.lastAttemptAt + interval : 0;
  return now >= Math.max(state.nextAllowedAt, automaticAt) &&
    (state.lastAttemptAt === 0 || now >= state.lastAttemptAt);
}

export function reserveRefresh(state: RefreshPolicyState, now: number, requestId: string,
  _settings: CardPreferences = defaultCardPreferences()): RefreshPolicyState {
  return { configRevision: state.configRevision, requestId: requestId, inFlight: true, lastAttemptAt: now,
    nextAllowedAt: 0, failureCount: state.failureCount,
    lastFailureKind: state.lastFailureKind, lastFailureAt: state.lastFailureAt };
}

export function completeRefresh(state: RefreshPolicyState, now: number, failureKind: string,
  settings: CardPreferences = defaultCardPreferences()): RefreshPolicyState {
  if (!failureKind) {
    return { configRevision: state.configRevision, requestId: state.requestId, inFlight: false,
      lastAttemptAt: state.lastAttemptAt, nextAllowedAt: 0,
      failureCount: 0,
      lastFailureKind: '', lastFailureAt: 0 };
  }
  const count = Math.min(state.failureCount + 1, 16);
  const delay = Math.min(MIN_REFRESH_INTERVAL_MS * Math.pow(2, count - 1),
    settings.failureBackoffMinutes * MIN_REFRESH_INTERVAL_MS);
  return { configRevision: state.configRevision, requestId: state.requestId, inFlight: false,
    lastAttemptAt: state.lastAttemptAt, nextAllowedAt: now + delay, failureCount: count,
    lastFailureKind: failureKind, lastFailureAt: now };
}
