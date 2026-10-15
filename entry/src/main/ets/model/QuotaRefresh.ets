import { common } from '@kit.AbilityKit';
import { LiveAccountPreview, mapAccount, liveSnapshot, UsageRecord } from './LiveQuota';
import { QuotaSnapshot } from './MockQuota';
import { getAccountUsage, listAccounts } from '../network/Sub2ApiClient';
import { Sub2ApiError } from '../network/Sub2ApiContract';
import { loadLocalCredentials, LocalCredentials } from '../storage/LocalConfig';
import { loadConfigSummary } from '../storage/LocalConfig';
import { loadFeaturedIds, loadFeaturedRevision, loadSingleId, loadSnapshot,
  saveSnapshot } from '../storage/QuotaSnapshotStore';
import { RefreshCoordinator, RefreshStamp, sameRefreshStamp } from './RefreshCoordinator';
import { RefreshPolicyState, RefreshReason } from './RefreshPolicy';
import { beginRefresh, finishRefresh, loadRefreshPolicy, nextRefreshAt } from '../storage/RefreshPolicyStore';

const coordinator = new RefreshCoordinator<QuotaSnapshot>();

export function unconfiguredSnapshot(): QuotaSnapshot {
  return {
    health: 'empty', statusLabel: '尚未配置', notice: '请填写自己的 Sub2API 地址和 Admin Key',
    checkedAt: '', lastSuccessAt: '', cached: false, accounts: []
  };
}

export function waitingSnapshot(): QuotaSnapshot {
  return {
    health: 'refreshing', statusLabel: '等待首次同步', notice: '请刷新卡片或在详情页读取账号',
    checkedAt: '', lastSuccessAt: '', cached: false, accounts: []
  };
}

export function failureSnapshot(previous: QuotaSnapshot | undefined, error: Sub2ApiError,
  checkedAt: number = Date.now()): QuotaSnapshot {
  const auth = error.kind === 'auth';
  const checked = new Date(checkedAt);
  const time = `${checked.getHours().toString().padStart(2, '0')}:${checked.getMinutes().toString().padStart(2, '0')}`;
  const stale = previous !== undefined && (!previous.savedAt || Date.now() - previous.savedAt > 60 * 60 * 1000);
  const networkCode = error.kind === 'network' && error.diagnosticCode !== undefined ?
    `；系统错误码 ${error.diagnosticCode}` : '';
  return {
    health: auth ? 'authRequired' : stale ? 'stale' : 'offline',
    statusLabel: auth ? '认证失效' : error.kind === 'domain' ? '域名未获准' :
      error.kind === 'redirect' ? '地址重定向' :
      error.kind === 'tooManyAccounts' ? '账号过多' :
      error.kind === 'unsupported' || error.kind === 'format' ? '接口不兼容' :
      stale ? '数据已过期' : error.kind === 'server' ? '服务错误' : '连接失败',
    notice: auth ? '请检查服务地址与密钥' : error.kind === 'domain' ?
      '系统阻止访问该域名，请检查应用类型与域名策略' : error.kind === 'redirect' ?
      '请填写最终 HTTPS 服务地址' : error.kind === 'tooManyAccounts' ?
      '账号超过当前支持的数量' : error.kind === 'unsupported' || error.kind === 'format' ?
      '请确认 Sub2API 版本与服务地址' : previous ?
      `无法读取服务，显示上次成功数据${networkCode}` : `无法读取服务，尚无成功数据${networkCode}`,
    checkedAt: time,
    lastSuccessAt: previous?.lastSuccessAt || '',
    cached: previous !== undefined,
    savedAt: previous?.savedAt,
    accounts: previous?.accounts || []
  };
}

function currentSnapshot(context: common.Context): QuotaSnapshot {
  const summary = loadConfigSummary(context);
  if (!summary.hasKey) {
    return unconfiguredSnapshot();
  }
  return loadSnapshot(context, summary.serviceUrl, summary.revision) || waitingSnapshot();
}

function cooldownSnapshot(context: common.Context, serviceUrl: string, configRevision: number): QuotaSnapshot {
  const policy = loadRefreshPolicy(context, configRevision);
  const previous = loadSnapshot(context, serviceUrl, configRevision, false);
  if (policy.inFlight) {
    if (previous) {
      previous.health = 'refreshing';
      previous.statusLabel = '刷新中';
      previous.notice = '正在读取，显示上次成功数据';
      return previous;
    }
    return waitingSnapshot();
  }
  if (policy.lastFailureKind === 'usage' && previous) {
    const minutes = Math.ceil(Math.max(0, nextRefreshAt(context, configRevision) - Date.now()) / 60000);
    previous.health = 'partial';
    previous.statusLabel = '额度读取失败';
    previous.notice = `部分关注账号额度暂不可读；下次自动请求约 ${minutes} 分钟后`;
    return previous;
  }
  if (policy.failureCount > 0 && policy.lastFailureKind) {
    const failed = failureSnapshot(previous, new Sub2ApiError(policy.lastFailureKind), policy.lastFailureAt);
    const minutes = Math.ceil(Math.max(0, nextRefreshAt(context, configRevision) - Date.now()) / 60000);
    failed.notice = `${failed.notice}；下次自动请求约 ${minutes} 分钟后`;
    return failed;
  }
  if (previous) {
    return previous;
  }
  return waitingSnapshot();
}

export async function refreshQuota(context: common.Context,
  reason: RefreshReason = 'automatic'): Promise<QuotaSnapshot> {
  const summary = loadConfigSummary(context);
  if (!summary.hasKey) {
    return unconfiguredSnapshot();
  }
  const featuredRevision = loadFeaturedRevision(context);
  const stamp: RefreshStamp = { serviceUrl: summary.serviceUrl, configRevision: summary.revision,
    featuredRevision: featuredRevision };
  const isCurrent = (): boolean => {
    const latest = loadConfigSummary(context);
    return latest.hasKey && sameRefreshStamp(stamp, { serviceUrl: latest.serviceUrl,
      configRevision: latest.revision, featuredRevision: loadFeaturedRevision(context) });
  };
  return coordinator.run(`${summary.revision}:${featuredRevision}`, async (): Promise<QuotaSnapshot> => {
    const previous = loadSnapshot(context, summary.serviceUrl, summary.revision);
    let reservation: RefreshPolicyState | undefined;
    try {
      reservation = await beginRefresh(context, summary.revision, reason);
      if (!isCurrent()) {
        return currentSnapshot(context);
      }
      if (!reservation) {
        return cooldownSnapshot(context, summary.serviceUrl, summary.revision);
      }
      const credentials: LocalCredentials | undefined = await loadLocalCredentials(context);
      if (!isCurrent()) {
        return currentSnapshot(context);
      }
      if (!credentials) {
        return unconfiguredSnapshot();
      }
      const records = await listAccounts(credentials);
      const selectedIds = Array.from(new Set([...loadFeaturedIds(context), loadSingleId(context)]))
        .filter((id: number) => id > 0);
      const previews: LiveAccountPreview[] = [];
      let usageFailed = false;
      let reusedQuota = false;
      for (const record of records) {
        let usage: UsageRecord | undefined;
        let accountUsageFailed = false;
        if (selectedIds.includes(record.id) && (record.type !== 'apikey' || record.platform === 'gemini') &&
          record.status === 'active' && record.schedulable) {
          try {
            usage = await getAccountUsage(credentials, record.id,
              record.platform === 'anthropic' && (record.type === 'oauth' || record.type === 'setup-token'));
          } catch (error) {
            if (error instanceof Sub2ApiError && error.kind === 'auth') {
              throw error;
            }
            usageFailed = true;
            accountUsageFailed = true;
          }
        }
        const preview = mapAccount(record, usage);
        if (accountUsageFailed && preview.health === 'unknown') {
          const older = previous?.accounts.find((account) => account.id === record.id);
          if (older && /^(100|[1-9]?\d)%$/.test(older.remaining)) {
            preview.remaining = older.remaining;
            preview.period = older.period;
            preview.region = older.region;
            preview.health = older.health;
            preview.stateLabel = `上次 · ${older.stateLabel.replace(/^上次 · /, '')}`;
            reusedQuota = true;
          }
        }
        previews.push(preview);
      }
      const snapshot = liveSnapshot(previews, selectedIds);
      if (reusedQuota && previous) {
        snapshot.lastSuccessAt = previous.lastSuccessAt;
        snapshot.savedAt = previous.savedAt;
      }
      if (usageFailed) {
        snapshot.health = 'partial';
        snapshot.statusLabel = '额度读取失败';
        snapshot.notice = '部分关注账号额度暂不可读';
      }
      if (!isCurrent()) {
        return currentSnapshot(context);
      }
      const saved = await saveSnapshot(context, summary.serviceUrl, summary.revision, featuredRevision, snapshot);
      if (!saved || !isCurrent()) {
        return currentSnapshot(context);
      }
      try {
        await finishRefresh(context, reservation, usageFailed ? 'usage' : '');
      } catch (_error) {
      }
      return snapshot;
    } catch (error) {
      if (!isCurrent()) {
        return currentSnapshot(context);
      }
      const failure = error instanceof Sub2ApiError ? error : new Sub2ApiError('network');
      if (reservation) {
        try {
          await finishRefresh(context, reservation, failure.kind);
        } catch (_error) {
        }
      }
      return failureSnapshot(previous, failure);
    }
  });
}
