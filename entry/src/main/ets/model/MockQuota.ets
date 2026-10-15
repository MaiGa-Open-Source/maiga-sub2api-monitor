import { CardPreferences, cardPalette, defaultCardPreferences } from './CardPreferences';

export type AccountHealth = 'healthy' | 'low' | 'unavailable' | 'unknown';
export type SnapshotHealth = 'ready' | 'partial' | 'refreshing' | 'offline' | 'stale' | 'authRequired' | 'empty';

export interface AccountPreview {
  id?: number;
  name: string;
  platform: string;
  region: string;
  period: string;
  remaining: string;
  health: AccountHealth;
  stateLabel: string;
}

export interface QuotaSnapshot {
  health: SnapshotHealth;
  statusLabel: string;
  notice: string;
  checkedAt: string;
  lastSuccessAt: string;
  cached: boolean;
  savedAt?: number;
  accounts: AccountPreview[];
}

export interface MockScenario {
  id: string;
  label: string;
}

export const MOCK_SCENARIOS: MockScenario[] = [
  { id: 'normal', label: '全部正常' },
  { id: 'low', label: '额度偏低' },
  { id: 'partial', label: '部分异常' },
  { id: 'unknown', label: '额度未知' },
  { id: 'refreshing', label: '刷新中' },
  { id: 'offline', label: '连接失败' },
  { id: 'stale', label: '快照过期' },
  { id: 'auth', label: '认证失效' },
  { id: 'empty', label: '没有账号' }
];

export function mockUpdateTime(): string {
  const now = new Date();
  const hour = now.getHours().toString().padStart(2, '0');
  const minute = now.getMinutes().toString().padStart(2, '0');
  return `${hour}:${minute}`;
}

function demoAccounts(): AccountPreview[] {
  return [
    { name: '主账号', platform: 'Claude', region: '美区', period: '本期', remaining: '42%', health: 'healthy', stateLabel: '正常' },
    { name: '备用账号', platform: 'OpenAI', region: '欧区', period: '本期', remaining: '68%', health: 'healthy', stateLabel: '正常' },
    { name: '工作账号', platform: 'Claude', region: '日区', period: '本期', remaining: '76%', health: 'healthy', stateLabel: '正常' }
  ];
}

export function abnormalCount(accounts: AccountPreview[]): number {
  return accounts.filter((account: AccountPreview) => account.health === 'low' || account.health === 'unavailable').length;
}

export function createMockSnapshot(scenarioId: string): QuotaSnapshot {
  const accounts = demoAccounts();
  const now = mockUpdateTime();
  const snapshot: QuotaSnapshot = {
    health: 'ready', statusLabel: '全部正常', notice: '账号状态正常', checkedAt: now,
    lastSuccessAt: now, cached: false, accounts: accounts
  };

  switch (scenarioId) {
    case 'low':
      accounts[1].remaining = '9%';
      accounts[1].health = 'low';
      accounts[1].stateLabel = '额度偏低';
      snapshot.statusLabel = '1 个异常';
      snapshot.notice = '备用账号额度偏低';
      break;
    case 'partial':
      accounts[1].remaining = '--';
      accounts[1].health = 'unavailable';
      accounts[1].stateLabel = '暂不可用';
      accounts[2].health = 'low';
      accounts[2].remaining = '6%';
      accounts[2].stateLabel = '额度偏低';
      snapshot.statusLabel = '2 个异常';
      snapshot.notice = '部分账号需要处理';
      break;
    case 'unknown':
      accounts[0].remaining = '--';
      accounts[0].health = 'unknown';
      accounts[0].stateLabel = '额度未知';
      snapshot.statusLabel = '额度未知';
      snapshot.notice = '账号可用，尚无可确认的额度';
      break;
    case 'refreshing':
      snapshot.health = 'refreshing';
      snapshot.statusLabel = '刷新中';
      snapshot.notice = '正在检查，显示上次成功数据';
      snapshot.cached = true;
      snapshot.lastSuccessAt = '10:24';
      break;
    case 'offline':
      snapshot.health = 'offline';
      snapshot.statusLabel = '连接失败';
      snapshot.notice = '无法连接服务，显示上次成功数据';
      snapshot.cached = true;
      snapshot.lastSuccessAt = '10:24';
      break;
    case 'stale':
      snapshot.health = 'stale';
      snapshot.statusLabel = '数据已过期';
      snapshot.notice = '上次成功数据已过期，请刷新';
      snapshot.cached = true;
      snapshot.lastSuccessAt = '昨天 21:10';
      break;
    case 'auth':
      snapshot.health = 'authRequired';
      snapshot.statusLabel = '认证失效';
      snapshot.notice = '请检查服务地址与密钥';
      snapshot.cached = true;
      snapshot.lastSuccessAt = '10:24';
      break;
    case 'empty':
      snapshot.health = 'empty';
      snapshot.statusLabel = '尚无账号';
      snapshot.notice = '连接服务后选择两个关注账号';
      snapshot.lastSuccessAt = '';
      snapshot.accounts = [];
      break;
    default:
      break;
  }
  return snapshot;
}

export class MockFormData {
  dimension: string = 'dual';
  cardTitle: string = 'Sub2API';
  glass: string = 'false';
  surfaceColor: string = '';
  surfaceEndColor: string = '';
  edgeColor: string = '';
  shadowColor: string = '';
  inkColor: string = '';
  mutedColor: string = '';
  lineColor: string = '';
  healthyColor: string = '';
  warningColor: string = '';
  errorColor: string = '';
  statusLabel: string = '';
  statusTone: string = '';
  notice: string = '';
  abnormalLabel: string = '';
  timeLabel: string = '';
  singleTimeLabel: string = '未更新';
  hasAccounts: string = '';
  firstName: string = '';
  firstMeta: string = '';
  firstRemaining: string = '';
  firstState: string = '';
  firstTone: string = '';
  secondName: string = '';
  secondMeta: string = '';
  secondRemaining: string = '';
  secondState: string = '';
  secondTone: string = '';
  singleName: string = '';
  singleMeta: string = '';
  singleRemaining: string = '--';
  singleState: string = '';
  singleTone: string = 'unknown';
  singleRingValue: number = 0;
  singleRingKnown: string = 'false';

  constructor(snapshot: QuotaSnapshot, selectedIds?: number[], dimension: number = 3,
    preferences: CardPreferences = defaultCardPreferences(), darkMode: boolean = false) {
    this.dimension = dimension === 2 ? 'single' : 'dual';
    this.cardTitle = preferences.title;
    this.glass = preferences.theme === 'glass' ? 'true' : 'false';
    const glassDark = preferences.appearance === 'dark' ||
      (preferences.appearance === 'system' && darkMode);
    const palette = cardPalette(preferences.theme, preferences.transparency,
      preferences.theme === 'glass' ? glassDark : darkMode);
    this.surfaceColor = palette.surface;
    this.surfaceEndColor = palette.surfaceEnd;
    this.edgeColor = palette.edge;
    this.shadowColor = palette.shadow;
    this.inkColor = palette.ink;
    this.mutedColor = palette.muted;
    this.lineColor = palette.line;
    this.healthyColor = palette.healthy;
    this.warningColor = palette.warning;
    this.errorColor = palette.error;
    this.statusLabel = snapshot.statusLabel;
    const featured = selectedIds !== undefined ? selectedIds.map((id: number) =>
      snapshot.accounts.find((account: AccountPreview) => account.id === id)).filter((account: AccountPreview | undefined) =>
      account !== undefined) as AccountPreview[] : snapshot.accounts.slice(0, 2);
    this.statusTone = snapshot.health === 'offline' || snapshot.health === 'authRequired' ? 'error' :
      snapshot.health === 'ready' && abnormalCount(snapshot.accounts) === 0 &&
      featured.length > 0 && !featured.some((account: AccountPreview) => account.health === 'unknown') ?
      'healthy' : 'warning';
    if (snapshot.health === 'ready') {
      this.statusLabel = featured.length === 0 ? '请选择关注账号' :
        featured.some((account: AccountPreview) => account.health === 'unknown') ? '部分额度未知' :
          abnormalCount(snapshot.accounts) > 0 ? snapshot.statusLabel : '运行正常';
    }
    this.notice = snapshot.notice;
    this.abnormalLabel = `${snapshot.cached ? '上次 ' : ''}${abnormalCount(snapshot.accounts)} 个已知异常`;
    this.timeLabel = snapshot.lastSuccessAt ? `上次成功 ${snapshot.lastSuccessAt}` : '尚无成功数据';
    this.singleTimeLabel = snapshot.lastSuccessAt ? snapshot.lastSuccessAt.slice(-5) : '未更新';
    this.hasAccounts = featured.length > 0 ? 'true' : 'false';
    if (featured.length === 0 && snapshot.accounts.length > 0 && snapshot.health === 'ready') {
      this.notice = '请在详情页选择两个关注账号';
    }
    if (featured.length > 0) {
      const first = featured[0];
      this.firstName = first.name;
      this.firstMeta = [first.platform, first.region, first.period].filter((part: string) => part.length > 0).join(' · ');
      this.firstRemaining = first.remaining;
      this.firstState = `${snapshot.cached ? '上次 · ' : ''}${first.stateLabel}`;
      this.firstTone = first.health;
    }
    if (featured.length > 1) {
      const second = featured[1];
      this.secondName = second.name;
      this.secondMeta = [second.platform, second.region, second.period].filter((part: string) => part.length > 0).join(' · ');
      this.secondRemaining = second.remaining;
      this.secondState = `${snapshot.cached ? '上次 · ' : ''}${second.stateLabel}`;
      this.secondTone = second.health;
    }
    if (dimension === 2) {
      const single = featured[0];
      if (single) {
        this.singleName = single.name;
        this.singleMeta = [single.platform, single.region, single.period].filter((part: string) =>
          part.length > 0).join(' · ');
        this.singleRemaining = single.remaining;
        this.singleState = snapshot.health === 'offline' || snapshot.health === 'stale' ||
          snapshot.health === 'authRequired' ? snapshot.statusLabel :
          `${snapshot.cached ? '上次 · ' : ''}${single.stateLabel}`;
        this.singleTone = snapshot.health === 'offline' || snapshot.health === 'authRequired' ? 'error' : single.health;
        const match = /^(100|[1-9]?\d)%$/.exec(single.remaining);
        this.singleRingKnown = match ? 'true' : 'false';
        this.singleRingValue = match ? Number(match[1]) : 0;
      } else {
        this.singleName = '选择关注账号';
        this.singleMeta = '在应用内设置';
        this.singleState = snapshot.statusLabel;
      }
    }
  }
}

export function mockFormData(scenarioId: string = 'low'): MockFormData {
  return new MockFormData(createMockSnapshot(scenarioId));
}
