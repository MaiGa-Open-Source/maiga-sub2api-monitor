import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AccountRecord, UsageRecord } from '../model/LiveQuota';
import { AccountStatsResponse, normalizeAccountStats, TrendDay } from '../model/TrendStats';
import { LocalCredentials } from '../storage/LocalConfig';
import { AccountPage, collectAccounts, httpErrorKind, parseEnvelope, Sub2ApiError,
  validateUsage } from './Sub2ApiContract';

async function get<T>(credentials: LocalCredentials, path: string,
  readTimeout: number = 12000): Promise<T> {
  const request = http.createHttp();
  try {
    const redirects = new http.HttpInterceptorChain();
    const stopRedirect: http.HttpInterceptor = {
      interceptorType: http.InterceptorType.REDIRECTION,
      interceptorHandle: async (_request, _response): Promise<http.ChainContinue> => false
    };
    if (!redirects.addChain([stopRedirect]) || !redirects.apply(request)) {
      throw new Sub2ApiError('network');
    }
    const response = await request.request(`${credentials.serviceUrl}${path}`, {
      method: http.RequestMethod.GET,
      header: { 'x-api-key': credentials.adminKey, 'Accept': 'application/json' },
      expectDataType: http.HttpDataType.STRING,
      usingCache: false,
      connectTimeout: 8000,
      readTimeout: readTimeout,
      maxLimit: 2 * 1024 * 1024
    });
    const errorKind = httpErrorKind(response.responseCode);
    if (errorKind) {
      throw new Sub2ApiError(errorKind, response.responseCode);
    }
    if (typeof response.result !== 'string') {
      throw new Sub2ApiError('format');
    }
    return parseEnvelope<T>(response.result);
  } catch (error) {
    if (error instanceof Sub2ApiError) {
      throw error;
    }
    const code = error && typeof error === 'object' ? (error as BusinessError).code : undefined;
    if (code === 2300998) {
      throw new Sub2ApiError('domain', code);
    }
    throw new Sub2ApiError('network', typeof code === 'number' && Number.isSafeInteger(code) ? code : undefined);
  } finally {
    request.destroy();
  }
}

export async function listAccounts(credentials: LocalCredentials): Promise<AccountRecord[]> {
  return collectAccounts((page: number): Promise<AccountPage> => get<AccountPage>(credentials,
    `/api/v1/admin/accounts?lite=1&page=${page}&page_size=100`));
}

export async function getAccountUsage(credentials: LocalCredentials, id: number,
  passive: boolean): Promise<UsageRecord> {
  const source = passive ? '?source=passive' : '';
  return validateUsage(await get<UsageRecord>(credentials, `/api/v1/admin/accounts/${id}/usage${source}`));
}

export async function getAccountStats(credentials: LocalCredentials, id: number): Promise<TrendDay[]> {
  const response = await get<AccountStatsResponse>(credentials,
    `/api/v1/admin/accounts/${id}/stats?days=30`, 30000);
  try {
    return normalizeAccountStats(response);
  } catch (_error) {
    throw new Sub2ApiError('format');
  }
}
