import { AccountHealth, AccountPreview, QuotaSnapshot } from './MockQuota';

export interface AccountRecord {
  id: number;
  name: string;
  platform: string;
  type: string;
  status: string;
  schedulable: boolean;
  quota_limit?: number;
  quota_used?: number;
  quota_daily_limit?: number;
  quota_daily_used?: number;
  quota_weekly_limit?: number;
  quota_weekly_used?: number;
}

export interface UsageProgress {
  utilization: number;
  resets_at?: string;
}

export interface AntigravityModelQuota {
  utilization: number;
  reset_time: string;
}

export interface GrokBilling {
  period_type?: string;
  usage_percent?: number;
  period_end?: string;
  used_percent?: number;
  monthly_limit_cents?: number;
  used_cents?: number;
  billing_period_end?: string;
}

export interface GrokLocalUsage {
  tokens: number;
}

export interface UsageRecord {
  five_hour?: UsageProgress;
  seven_day?: UsageProgress;
  gemini_shared_daily?: UsageProgress;
  gemini_pro_daily?: UsageProgress;
  gemini_flash_daily?: UsageProgress;
  gemini_shared_minute?: UsageProgress;
  gemini_pro_minute?: UsageProgress;
  gemini_flash_minute?: UsageProgress;
  antigravity_quota?: Record<string, AntigravityModelQuota>;
  grok_billing?: GrokBilling;
  grok_free_token_limit?: number;
  grok_local_usage_24h?: GrokLocalUsage;
  error_code?: string;
  needs_reauth?: boolean;
  is_banned?: boolean;
  needs_verify?: boolean;
}

export interface LiveAccountPreview extends AccountPreview {
  id: number;
}

interface QuotaReading {
  percent: number;
  period: string;
  region: string;
}

function validPercent(value: number | undefined): boolean {
  return value !== undefined && Number.isFinite(value) && value >= 0;
}

function quotaPercent(limit: number | undefined, used: number | undefined): number | undefined {
  if (!limit || !Number.isFinite(limit) || limit <= 0 || !validPercent(used)) {
    return undefined;
  }
  return Math.max(0, Math.round(100 * (1 - used! / limit)));
}

function windowPercent(progress: UsageProgress | undefined): number | undefined {
  if (!progress || !progress.resets_at || !validPercent(progress.utilization) ||
    Number.isNaN(Date.parse(progress.resets_at)) || Date.parse(progress.resets_at) <= Date.now()) {
    return undefined;
  }
  return Math.max(0, Math.round(100 - progress.utilization));
}

function reading(percent: number | undefined, period: string, region: string = ''): QuotaReading | undefined {
  return percent === undefined ? undefined : { percent: percent, period: period, region: region };
}

function apiKeyReading(account: AccountRecord): QuotaReading | undefined {
  return reading(quotaPercent(account.quota_daily_limit, account.quota_daily_used), '日限额') ||
    reading(quotaPercent(account.quota_weekly_limit, account.quota_weekly_used), '周限额') ||
    reading(quotaPercent(account.quota_limit, account.quota_used), '总限额');
}

function genericWindowReading(usage?: UsageRecord): QuotaReading | undefined {
  return reading(windowPercent(usage?.seven_day), '7 天窗口') ||
    reading(windowPercent(usage?.five_hour), '5 小时窗口');
}

function mostRestricted(readings: (QuotaReading | undefined)[]): QuotaReading | undefined {
  let selected: QuotaReading | undefined;
  for (const value of readings) {
    if (value && (!selected || value.percent < selected.percent)) {
      selected = value;
    }
  }
  return selected;
}

function geminiReading(usage?: UsageRecord): QuotaReading | undefined {
  if (!usage) {
    return undefined;
  }
  const sharedDaily = reading(windowPercent(usage.gemini_shared_daily), '日请求额度', '共享池');
  if (sharedDaily) {
    return sharedDaily;
  }
  const daily = mostRestricted([
    reading(windowPercent(usage.gemini_pro_daily), '日请求额度', 'Pro'),
    reading(windowPercent(usage.gemini_flash_daily), '日请求额度', 'Flash')
  ]);
  if (daily) {
    return daily;
  }
  const sharedMinute = reading(windowPercent(usage.gemini_shared_minute), '分钟请求额度', '共享池');
  return sharedMinute || mostRestricted([
    reading(windowPercent(usage.gemini_pro_minute), '分钟请求额度', 'Pro'),
    reading(windowPercent(usage.gemini_flash_minute), '分钟请求额度', 'Flash')
  ]);
}

function antigravityReading(usage?: UsageRecord): QuotaReading | undefined {
  if (!usage?.antigravity_quota) {
    return undefined;
  }
  let selected: QuotaReading | undefined;
  for (const model of Object.keys(usage.antigravity_quota)) {
    const value = usage.antigravity_quota[model];
    if (!value) {
      continue;
    }
    const progress: UsageProgress = { utilization: value.utilization, resets_at: value.reset_time };
    const candidate = reading(windowPercent(progress), '模型额度', model);
    if (candidate && (!selected || candidate.percent < selected.percent)) {
      selected = candidate;
    }
  }
  return selected;
}

function grokReading(usage?: UsageRecord): QuotaReading | undefined {
  if (!usage) {
    return undefined;
  }
  const billing = usage.grok_billing;
  let monthly: QuotaReading | undefined;
  let weekly: QuotaReading | undefined;
  if (billing) {
    let monthlyUsed = billing.used_percent;
    if (!validPercent(monthlyUsed) && billing.monthly_limit_cents && billing.monthly_limit_cents > 0 &&
      validPercent(billing.used_cents)) {
      monthlyUsed = billing.used_cents! * 100 / billing.monthly_limit_cents;
    }
    if (billing.period_type !== 'weekly' || billing.monthly_limit_cents !== undefined) {
      const monthlyProgress: UsageProgress = {
        utilization: monthlyUsed === undefined ? -1 : monthlyUsed,
        resets_at: billing.billing_period_end || billing.period_end
      };
      monthly = reading(windowPercent(monthlyProgress), '月度账期');
    }
    if (billing.period_type === 'weekly') {
      const weeklyProgress: UsageProgress = {
        utilization: billing.usage_percent === undefined ? -1 : billing.usage_percent,
        resets_at: billing.period_end
      };
      weekly = reading(windowPercent(weeklyProgress), '周账期');
    }
  }
  const paid = mostRestricted([monthly, weekly]);
  if (paid) {
    return paid;
  }
  const limit = usage.grok_free_token_limit;
  const used = usage.grok_local_usage_24h?.tokens;
  return reading(quotaPercent(limit, used), '24 小时本地 Token');
}

export function mapAccount(account: AccountRecord, usage?: UsageRecord): LiveAccountPreview {
  let quota: QuotaReading | undefined;
  if (account.platform === 'gemini') {
    quota = geminiReading(usage) || (account.type === 'apikey' ? apiKeyReading(account) : undefined);
  } else if (account.platform === 'antigravity') {
    quota = antigravityReading(usage);
  } else if (account.platform === 'grok') {
    quota = grokReading(usage);
  } else {
    quota = account.type === 'apikey' ? apiKeyReading(account) : genericWindowReading(usage);
  }
  const percent = quota?.percent;

  const unavailable = account.status !== 'active' || !account.schedulable ||
    usage?.needs_reauth === true || usage?.is_banned === true || usage?.needs_verify === true ||
    usage?.error_code === 'rate_limited' || usage?.error_code === 'unauthenticated' ||
    usage?.error_code === 'forbidden';
  const health: AccountHealth = unavailable ? 'unavailable' : percent === undefined ? 'unknown' :
    percent < 10 ? 'low' : 'healthy';
  return {
    id: account.id,
    name: account.name || `账号 ${account.id}`,
    platform: account.platform || '未知平台',
    region: quota?.region || '',
    period: quota?.period || '额度未提供',
    remaining: percent === undefined ? '--' : `${percent}%`,
    health: health,
    stateLabel: unavailable ? '暂不可用' : percent === undefined ? '额度未知' :
      percent < 10 ? '额度偏低' : '正常'
  };
}

export function liveSnapshot(accounts: LiveAccountPreview[], selectedIds: number[]): QuotaSnapshot {
  const now = new Date();
  const time = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
  const datedTime = `${(now.getMonth() + 1).toString().padStart(2, '0')}-${now.getDate().toString().padStart(2, '0')} ${time}`;
  const abnormal = accounts.filter((account: LiveAccountPreview) =>
    account.health === 'low' || account.health === 'unavailable').length;
  const featured = accounts.filter((account: LiveAccountPreview) => selectedIds.includes(account.id));
  const unknown = featured.filter((account: LiveAccountPreview) => account.health === 'unknown').length;
  return {
    health: accounts.length === 0 ? 'empty' : 'ready',
    statusLabel: accounts.length === 0 ? '尚无账号' : abnormal > 0 ? `${abnormal} 个已知异常` :
      featured.length === 0 ? '请选择关注账号' : unknown > 0 ? '部分额度未知' : '关注账号正常',
    notice: accounts.length === 0 ? '服务中没有上游账号' : abnormal > 0 ? '部分账号需要处理' :
      featured.length === 0 ? '请从列表中选择关注账号' :
      unknown > 0 ? '关注账号没有可确认的额度' : '关注账号额度已读取',
    checkedAt: time,
    lastSuccessAt: datedTime,
    cached: false,
    savedAt: now.getTime(),
    accounts: accounts
  };
}
