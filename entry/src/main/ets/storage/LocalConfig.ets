import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util, url } from '@kit.ArkTS';
import { huks } from '@kit.UniversalKeystoreKit';
import { BusinessError } from '@kit.BasicServicesKit';

const STORE_NAME = 'local_connection';
const URL_KEY = 'service_url';
const CIPHER_KEY = 'admin_key_cipher';
const NONCE_KEY = 'admin_key_nonce';
const REVISION_KEY = 'config_revision';
const HUKS_ALIAS = 'sub2api_admin_key_v1';
const TAG_LENGTH = 16;

export interface LocalConfigSummary {
  serviceUrl: string;
  hasKey: boolean;
  revision: number;
}

export interface LocalCredentials {
  serviceUrl: string;
  adminKey: string;
}

function configStore(context: common.Context): preferences.Preferences {
  return preferences.getPreferencesSync(context, { name: STORE_NAME });
}

function storedBytes(store: preferences.Preferences, key: string): Uint8Array {
  const value = store.getSync(key, new Uint8Array(0));
  return value instanceof Uint8Array ? value : new Uint8Array(0);
}

export function normalizeServiceUrl(input: string): string {
  const value = input.trim();
  if (value.length > 512 || !value.toLowerCase().startsWith('https://') || /[\r\n\t]/.test(value)) {
    throw new Error('INVALID_URL');
  }
  const parsed = url.URL.parseURL(value);
  if (parsed.protocol !== 'https:' || !parsed.hostname || parsed.username || parsed.password || parsed.search || parsed.hash) {
    throw new Error('INVALID_URL');
  }
  return parsed.href.replace(/\/+$/, '');
}

export function loadConfigSummary(context: common.Context): LocalConfigSummary {
  const store = configStore(context);
  const value = store.getSync(URL_KEY, '');
  const serviceUrl = typeof value === 'string' ? value : '';
  const cipher = storedBytes(store, CIPHER_KEY);
  const nonce = storedBytes(store, NONCE_KEY);
  return { serviceUrl: serviceUrl, hasKey: serviceUrl.length > 0 && cipher.length > TAG_LENGTH && nonce.length === 12,
    revision: store.getSync(REVISION_KEY, 0) as number };
}

function keyProperties(): huks.HuksParam[] {
  return [
    { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
    { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_128 },
    { tag: huks.HuksTag.HUKS_TAG_PURPOSE,
      value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT }
  ];
}

function cipherProperties(purpose: huks.HuksKeyPurpose, nonce: Uint8Array,
  serviceUrl: string, tag?: Uint8Array): huks.HuksParam[] {
  const encoder = new util.TextEncoder();
  const properties: huks.HuksParam[] = [
    { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
    { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_128 },
    { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: purpose },
    { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
    { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
    { tag: huks.HuksTag.HUKS_TAG_NONCE, value: nonce },
    { tag: huks.HuksTag.HUKS_TAG_ASSOCIATED_DATA, value: encoder.encodeInto(serviceUrl) }
  ];
  if (tag) {
    properties.push({ tag: huks.HuksTag.HUKS_TAG_AE_TAG, value: tag });
  }
  return properties;
}

async function ensureKey(): Promise<void> {
  const nonce = cryptoFramework.createRandom().generateRandomSync(12).data;
  const options: huks.HuksOptions = {
    properties: cipherProperties(huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT, nonce, HUKS_ALIAS)
  };
  try {
    const session = await huks.initSession(HUKS_ALIAS, options);
    await huks.abortSession(session.handle, { properties: [] });
    return;
  } catch (error) {
    if ((error as BusinessError).code !== 12000011) {
      throw new Error('HUKS_KEY_FAILED');
    }
  }
  await huks.generateKeyItem(HUKS_ALIAS, { properties: keyProperties() });
}

async function finishCipher(properties: huks.HuksParam[], input: Uint8Array): Promise<Uint8Array> {
  const options: huks.HuksOptions = { properties: properties, inData: input };
  const session = await huks.initSession(HUKS_ALIAS, options);
  try {
    const result = await huks.finishSession(session.handle, options);
    if (!result.outData) {
      throw new Error('EMPTY_CIPHER_RESULT');
    }
    return result.outData;
  } catch (error) {
    try {
      await huks.abortSession(session.handle, { properties: [] });
    } catch (_abortError) {
    }
    throw new Error('HUKS_OPERATION_FAILED');
  }
}

async function encryptAdminKey(adminKey: string, serviceUrl: string, nonce: Uint8Array): Promise<Uint8Array> {
  const plain = new util.TextEncoder().encodeInto(adminKey);
  try {
    return await finishCipher(cipherProperties(huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT,
      nonce, serviceUrl), plain);
  } finally {
    plain.fill(0);
  }
}

async function decryptAdminKey(cipher: Uint8Array, serviceUrl: string, nonce: Uint8Array): Promise<string> {
  if (cipher.length <= TAG_LENGTH || nonce.length !== 12) {
    throw new Error('INVALID_CIPHER');
  }
  const tag = cipher.slice(cipher.length - TAG_LENGTH);
  const payload = cipher.slice(0, cipher.length - TAG_LENGTH);
  const plain = await finishCipher(cipherProperties(huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT,
    nonce, serviceUrl, tag), payload);
  try {
    return util.TextDecoder.create('utf-8').decodeWithStream(plain);
  } finally {
    plain.fill(0);
  }
}

export async function saveLocalConfig(context: common.Context,
  rawUrl: string, rawKey: string): Promise<LocalConfigSummary> {
  const serviceUrl = normalizeServiceUrl(rawUrl);
  const adminKey = rawKey.trim();
  const previous = loadConfigSummary(context);
  if (!adminKey) {
    if (!previous.hasKey || previous.serviceUrl !== serviceUrl) {
      throw new Error('KEY_REQUIRED');
    }
    return previous;
  }
  if (adminKey.length > 4096 || /[\r\n]/.test(adminKey)) {
    throw new Error('INVALID_KEY');
  }

  await ensureKey();
  const nonce = cryptoFramework.createRandom().generateRandomSync(12).data;
  const cipher = await encryptAdminKey(adminKey, serviceUrl, nonce);
  if (await decryptAdminKey(cipher, serviceUrl, nonce) !== adminKey) {
    throw new Error('CIPHER_CHECK_FAILED');
  }

  const store = configStore(context);
  store.putSync(CIPHER_KEY, cipher);
  store.putSync(NONCE_KEY, nonce);
  store.putSync(URL_KEY, serviceUrl);
  store.putSync(REVISION_KEY, previous.revision + 1);
  await store.flush();
  return { serviceUrl: serviceUrl, hasKey: true, revision: previous.revision + 1 };
}

export async function loadLocalCredentials(context: common.Context): Promise<LocalCredentials | undefined> {
  const summary = loadConfigSummary(context);
  if (!summary.hasKey) {
    return undefined;
  }
  const store = configStore(context);
  const adminKey = await decryptAdminKey(storedBytes(store, CIPHER_KEY), summary.serviceUrl,
    storedBytes(store, NONCE_KEY));
  return { serviceUrl: summary.serviceUrl, adminKey: adminKey };
}

export async function clearLocalConfig(context: common.Context): Promise<void> {
  const store = configStore(context);
  const revision = loadConfigSummary(context).revision;
  store.deleteSync(CIPHER_KEY);
  store.deleteSync(NONCE_KEY);
  store.deleteSync(URL_KEY);
  store.putSync(REVISION_KEY, revision + 1);
  await store.flush();
  try {
    await huks.deleteKeyItem(HUKS_ALIAS, { properties: [] });
  } catch (_error) {
    // The ciphertext is already gone, so the remaining key cannot recover the Admin Key.
  }
}
