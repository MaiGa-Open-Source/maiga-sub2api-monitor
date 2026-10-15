import { AccountRecord, UsageRecord } from '../model/LiveQuota';

interface ApiEnvelope<T> {
  code: number;
  data: T;
}

export interface AccountPage {
  items: AccountRecord[];
  total: number;
  page: number;
  pages: number;
}

export class Sub2ApiError extends Error {
  kind: string;
  diagnosticCode?: number;

  constructor(kind: string, diagnosticCode?: number) {
    super(kind);
    this.kind = kind;
    this.diagnosticCode = diagnosticCode;
  }
}

export function httpErrorKind(status: number): string {
  if (status === 401 || status === 403) {
    return 'auth';
  }
  if (status === 404) {
    return 'unsupported';
  }
  if (status >= 300 && status < 400) {
    return 'redirect';
  }
  return status >= 200 && status < 300 ? '' : 'server';
}

export function parseEnvelope<T>(raw: string): T {
  let envelope: ApiEnvelope<T>;
  try {
    envelope = JSON.parse(raw) as ApiEnvelope<T>;
  } catch (_error) {
    throw new Sub2ApiError('format');
  }
  if (!envelope || envelope.code !== 0 || envelope.data === undefined || envelope.data === null) {
    throw new Sub2ApiError('format');
  }
  return envelope.data;
}

export function validateAccountPage(data: AccountPage, requestedPage: number): AccountPage {
  if (!data || !Array.isArray(data.items) || !Number.isInteger(data.total) || data.total < 0 ||
    data.page !== requestedPage || !Number.isInteger(data.pages) || data.pages < 1) {
    throw new Sub2ApiError('format');
  }
  for (const item of data.items) {
    if (!item || !Number.isSafeInteger(item.id) || item.id <= 0 || typeof item.name !== 'string' ||
      typeof item.platform !== 'string' || typeof item.type !== 'string' ||
      typeof item.status !== 'string' || typeof item.schedulable !== 'boolean') {
      throw new Sub2ApiError('format');
    }
  }
  return data;
}

export function validateUsage(data: UsageRecord): UsageRecord {
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    throw new Sub2ApiError('format');
  }
  return data;
}

export async function collectAccounts(fetchPage: (page: number) => Promise<AccountPage>): Promise<AccountRecord[]> {
  const accounts: AccountRecord[] = [];
  const seen = new Set<number>();
  let expectedTotal = -1;
  for (let page = 1; page <= 10; page++) {
    const data = validateAccountPage(await fetchPage(page), page);
    if (expectedTotal < 0) {
      expectedTotal = data.total;
    } else if (expectedTotal !== data.total) {
      throw new Sub2ApiError('format');
    }
    for (const item of data.items) {
      if (seen.has(item.id)) {
        throw new Sub2ApiError('format');
      }
      seen.add(item.id);
      accounts.push(item);
    }
    if (accounts.length === expectedTotal) {
      return accounts;
    }
    if (accounts.length > expectedTotal || data.items.length === 0 || page >= data.pages) {
      throw new Sub2ApiError('format');
    }
  }
  throw new Sub2ApiError('tooManyAccounts');
}
