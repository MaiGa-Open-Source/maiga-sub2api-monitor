import { common } from '@kit.AbilityKit';
import { getAccountStats } from '../network/Sub2ApiClient';
import { Sub2ApiError } from '../network/Sub2ApiContract';
import { loadConfigSummary, loadLocalCredentials } from '../storage/LocalConfig';
import { loadSnapshot } from '../storage/QuotaSnapshotStore';
import { loadTrendAccountId, loadTrendSelectionRevision, loadTrendSnapshot,
  saveTrendSnapshot } from '../storage/TrendStore';
import { beginTrendRefresh, finishTrendRefresh } from '../storage/TrendRefreshStore';
import { RefreshReason, RefreshPolicyState } from './RefreshPolicy';
import { RefreshCoordinator } from './RefreshCoordinator';
import { TrendSnapshot } from './TrendStats';

const coordinator = new RefreshCoordinator<TrendSnapshot>();

export function emptyTrend(accountId: number = 0, accountName: string = ''): TrendSnapshot {
  return { accountId: accountId, accountName: accountName, history: [], savedAt: 0,
    status: 'empty', notice: accountId ? '暂无请求记录' : '请选择关注账号' };
}

export function currentTrend(context: common.Context): TrendSnapshot {
  const summary = loadConfigSummary(context);
  const accountId = loadTrendAccountId(context);
  if (!summary.hasKey) {
    const result = emptyTrend();
    result.notice = '请先配置连接';
    return result;
  }
  if (!accountId) return emptyTrend();
  const saved = loadTrendSnapshot(context, summary.serviceUrl, summary.revision, accountId);
  if (saved) return saved;
  const result = emptyTrend(accountId);
  result.status = 'waiting';
  result.notice = '等待首次同步';
  return result;
}

function failedTrend(previous: TrendSnapshot | undefined, accountId: number,
  error: Sub2ApiError): TrendSnapshot {
  const auth = error.kind === 'auth';
  const notice = auth ? '认证失效' : error.diagnosticCode === 2300028 ? '统计接口超时' :
    error.kind === 'unsupported' ? '统计接口不存在' :
    error.kind === 'format' ? '统计数据格式不兼容' : error.kind === 'redirect' ? '地址重定向' :
      error.kind === 'server' ? `统计服务错误（HTTP ${error.diagnosticCode || 0}）` :
        error.kind === 'local' ? '本地处理失败' : error.diagnosticCode ?
          `连接失败（系统码 ${error.diagnosticCode}）` : '连接失败';
  const result = previous || emptyTrend(accountId);
  result.accountId = accountId;
  result.status = auth ? 'auth' : 'offline';
  result.notice = previous ? `${notice} · 上次数据` : notice;
  return result;
}

export async function refreshTrend(context: common.Context,
  reason: RefreshReason = 'automatic'): Promise<TrendSnapshot> {
  const summary = loadConfigSummary(context);
  const accountId = loadTrendAccountId(context);
  if (!summary.hasKey || !accountId) return currentTrend(context);
  const selectionRevision = loadTrendSelectionRevision(context);
  const isCurrent = (): boolean => {
    const latest = loadConfigSummary(context);
    return latest.hasKey && latest.serviceUrl === summary.serviceUrl && latest.revision === summary.revision &&
      loadTrendAccountId(context) === accountId &&
      loadTrendSelectionRevision(context) === selectionRevision;
  };
  return coordinator.run(`${summary.revision}:${selectionRevision}:${accountId}`, async (): Promise<TrendSnapshot> => {
    const previous = loadTrendSnapshot(context, summary.serviceUrl, summary.revision, accountId);
    let reservation: RefreshPolicyState | undefined;
    try {
      reservation = await beginTrendRefresh(context, summary.revision, selectionRevision, reason);
      if (!isCurrent()) return currentTrend(context);
      if (!reservation) return previous || currentTrend(context);
      const credentials = await loadLocalCredentials(context);
      if (!isCurrent()) return currentTrend(context);
      if (!credentials) return currentTrend(context);
      const history = await getAccountStats(credentials, accountId);
      if (!isCurrent()) return currentTrend(context);
      const quota = loadSnapshot(context, summary.serviceUrl, summary.revision, false);
      const accountName = quota?.accounts.find((account) => account.id === accountId)?.name ||
        previous?.accountName || `账号 #${accountId}`;
      const snapshot: TrendSnapshot = { accountId: accountId, accountName: accountName,
        history: history, savedAt: Date.now(), status: 'ready', notice: '' };
      if (!await saveTrendSnapshot(context, summary.serviceUrl, summary.revision,
        selectionRevision, snapshot) || !isCurrent()) return currentTrend(context);
      try { await finishTrendRefresh(context, selectionRevision, reservation, ''); } catch (_error) {}
      return snapshot;
    } catch (error) {
      if (!isCurrent()) return currentTrend(context);
      const failure = error instanceof Sub2ApiError ? error : new Sub2ApiError('local');
      if (reservation) {
        try { await finishTrendRefresh(context, selectionRevision, reservation, failure.kind); } catch (_error) {}
      }
      const failed = failedTrend(previous, accountId, failure);
      try {
        await saveTrendSnapshot(context, summary.serviceUrl, summary.revision,
          selectionRevision, failed);
      } catch (_error) {}
      return isCurrent() ? failed : currentTrend(context);
    }
  });
}
