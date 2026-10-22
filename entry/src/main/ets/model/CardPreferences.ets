export type CardTheme = 'aurora' | 'cushion' | 'label' | 'pixel' | 'chrome';
export type CardAppearance = 'system' | 'light' | 'dark';

export interface CardPreferences {
  title: string;
  theme: CardTheme;
  paletteIndex: number;
  appearance: CardAppearance;
  transparency: number;
  cardPeriodMinutes: number;
  autoIntervalMinutes: number;
  failureBackoffMinutes: number;
}

export interface CardColorway {
  name: string;
  surface: string;
  ink: string;
  muted: string;
  line: string;
  accent: string;
  accent2: string;
  warning: string;
  error: string;
  chip: string;
  wash: string;
}

export interface CardStyle {
  id: CardTheme;
  name: string;
  brief: string;
  radius: number;
  fontFamily: string;
  palettes: CardColorway[];
}

// These are the five structures and fifteen calibrated colorways selected in D04.
export const CARD_STYLES: CardStyle[] = [
  { id: 'aurora', name: '晨雾渐层', brief: '浅色晕染 · 连续曲线', radius: 23, fontFamily: 'HarmonyOS Sans', palettes: [
    { name: '蓝紫晨霞', surface: '#E8E9F7', ink: '#29344F', muted: '#555D78', line: '#B9BFD5', accent: '#4A4F91', accent2: '#934E66', warning: '#80500D', error: '#A1324A', chip: '#D8DDF1', wash: '#F8DDD8' },
    { name: '青杏薄雾', surface: '#E5EFEB', ink: '#283F3A', muted: '#526C63', line: '#B0C9BE', accent: '#31665E', accent2: '#8D563D', warning: '#7A5012', error: '#A23446', chip: '#CCE1D9', wash: '#F5E6CC' },
    { name: '粉桃云层', surface: '#F5E7ED', ink: '#513748', muted: '#74566B', line: '#D6B7C8', accent: '#865075', accent2: '#365E86', warning: '#805013', error: '#A02E45', chip: '#EACFDF', wash: '#E2E8FA' },
  ] },
  { id: 'cushion', name: '软垫模块', brief: '圆润浮层 · 嵌套模块', radius: 26, fontFamily: 'HarmonyOS Sans', palettes: [
    { name: '香芋牛奶', surface: '#F5F2FA', ink: '#352B48', muted: '#6E617D', line: '#D1C6DF', accent: '#6B499A', accent2: '#346D79', warning: '#80500E', error: '#A8354F', chip: '#E4DAF1', wash: '#F5F2FA' },
    { name: '开心果乳酪', surface: '#F1F4E9', ink: '#35432D', muted: '#606D53', line: '#C4CFB6', accent: '#4A6C34', accent2: '#925436', warning: '#7C5013', error: '#A13345', chip: '#DDE6CD', wash: '#F1F4E9' },
    { name: '桃子酸奶', surface: '#FBF0EA', ink: '#513A34', muted: '#7B6158', line: '#DFC5B7', accent: '#9A553C', accent2: '#58689C', warning: '#7A5010', error: '#A33149', chip: '#F0D9CA', wash: '#FBF0EA' },
  ] },
  { id: 'label', name: '酒标徽章', brief: '椭圆徽章 · 复古细框', radius: 19, fontFamily: 'serif', palettes: [
    { name: '酒红奶油', surface: '#F5EADF', ink: '#602238', muted: '#835767', line: '#C9A6AA', accent: '#7C2B48', accent2: '#3B6863', warning: '#815210', error: '#A32F3E', chip: '#EAD3CB', wash: '#F5EADF' },
    { name: '橄榄藏品', surface: '#F1EDD9', ink: '#3C4C35', muted: '#5F6C4E', line: '#B8BFA0', accent: '#46623A', accent2: '#98513D', warning: '#7C5011', error: '#A23441', chip: '#DFE2C5', wash: '#F1EDD9' },
    { name: '海盐蓝章', surface: '#E8EEF1', ink: '#2D4A60', muted: '#566E7D', line: '#A5BDCD', accent: '#365F7B', accent2: '#92546C', warning: '#7C5013', error: '#A1314A', chip: '#CFDFE8', wash: '#E8EEF1' },
  ] },
  { id: 'pixel', name: '口袋液晶', brief: '像素点阵 · 掌机屏框', radius: 8, fontFamily: 'monospace', palettes: [
    { name: '苔绿液晶', surface: '#DFE7CC', ink: '#2C3E2A', muted: '#56664B', line: '#A7B693', accent: '#36582E', accent2: '#71502A', warning: '#73500E', error: '#942F3D', chip: '#C4D1B1', wash: '#DFE7CC' },
    { name: '灰蓝电子纸', surface: '#E0E8EE', ink: '#2A3D51', muted: '#52667B', line: '#A4B6C5', accent: '#355777', accent2: '#7F506D', warning: '#79500F', error: '#A12F45', chip: '#C7D5E0', wash: '#E0E8EE' },
    { name: '蜜茶屏幕', surface: '#EEE3C8', ink: '#4A3E24', muted: '#6E6145', line: '#BCAB7F', accent: '#71521F', accent2: '#426753', warning: '#76500D', error: '#9D303D', chip: '#DACEA7', wash: '#EEE3C8' },
  ] },
  { id: 'chrome', name: '轻铝面板', brief: '细腻金属 · 压印轮廓', radius: 14, fontFamily: 'HarmonyOS Sans', palettes: [
    { name: '月光银', surface: '#E5E8EB', ink: '#303944', muted: '#5B6571', line: '#A6B0BA', accent: '#355B7A', accent2: '#80536E', warning: '#7B4E0E', error: '#A33045', chip: '#CBD1D8', wash: '#E5E8EB' },
    { name: '香槟铝', surface: '#ECE6DB', ink: '#494033', muted: '#6E6354', line: '#BEB09A', accent: '#775730', accent2: '#436B69', warning: '#78500F', error: '#A33043', chip: '#D9CFBD', wash: '#ECE6DB' },
    { name: '玫瑰钛', surface: '#EBE1E2', ink: '#49343F', muted: '#705B66', line: '#BFA5B1', accent: '#81556D', accent2: '#3D627A', warning: '#7B5010', error: '#A12F45', chip: '#DAC6CE', wash: '#EBE1E2' },
  ] },
 ];

export function defaultCardPreferences(): CardPreferences {
  return { title: 'Sub2API', theme: 'aurora', paletteIndex: 0, appearance: 'system', transparency: 0,
    cardPeriodMinutes: 60, autoIntervalMinutes: 60, failureBackoffMinutes: 15 };
}

export function normalizeCardPreferences(value: CardPreferences): CardPreferences {
  const defaults = defaultCardPreferences();
  const title = typeof value.title === 'string' ? value.title.replace(/[\r\n]/g, '').slice(0, 24) : defaults.title;
  const appearances: string[] = ['system', 'light', 'dark'];
  const periods: number[] = [30, 60, 120, 240];
  const backoffs: number[] = [5, 15, 30, 60];
  return {
    title: title.trim() || defaults.title,
    theme: CARD_STYLES.some((style: CardStyle) => style.id === value.theme) ? value.theme : defaults.theme,
    paletteIndex: Number.isInteger(value.paletteIndex) && value.paletteIndex >= 0 && value.paletteIndex < 3 ?
      value.paletteIndex : defaults.paletteIndex,
    appearance: appearances.includes(value.appearance) ? value.appearance : defaults.appearance,
    transparency: Number.isFinite(value.transparency) ?
      Math.max(0, Math.min(50, Math.round(value.transparency / 5) * 5)) : defaults.transparency,
    cardPeriodMinutes: periods.includes(value.cardPeriodMinutes) ? value.cardPeriodMinutes : defaults.cardPeriodMinutes,
    autoIntervalMinutes: Number.isFinite(value.autoIntervalMinutes) ?
      Math.max(1, Math.min(1440, Math.round(value.autoIntervalMinutes))) : defaults.autoIntervalMinutes,
    failureBackoffMinutes: backoffs.includes(value.failureBackoffMinutes) ?
      value.failureBackoffMinutes : defaults.failureBackoffMinutes
  };
}

export interface CardPalette {
  surface: string;
  surfaceEnd: string;
  edge: string;
  shadow: string;
  ink: string;
  muted: string;
  line: string;
  healthy: string;
  secondary: string;
  warning: string;
  error: string;
  chip: string;
  panel: string;
  texture: string;
  highlight: string;
}

function blendColor(start: string, end: string, amount: number): string {
  const from = Number.parseInt(start.slice(1), 16);
  const to = Number.parseInt(end.slice(1), 16);
  const channel = (shift: number): string => {
    const value = Math.round(((from >> shift) & 255) * (1 - amount) + ((to >> shift) & 255) * amount);
    return value.toString(16).padStart(2, '0').toUpperCase();
  };
  return `#${channel(16)}${channel(8)}${channel(0)}`;
}

export function cardStyle(theme: CardTheme): CardStyle {
  return CARD_STYLES.find((style: CardStyle) => style.id === theme) || CARD_STYLES[0];
}

export function cardPalette(theme: CardTheme, transparency: number, _dark: boolean = false,
  paletteIndex: number = 0): CardPalette {
  const colorway = cardStyle(theme).palettes[paletteIndex] || cardStyle(theme).palettes[0];
  const alpha = Math.round(255 * (1 - Math.max(0, Math.min(50, transparency)) / 100))
    .toString(16).padStart(2, '0').toUpperCase();
  const surface = theme === 'chrome' ? blendColor(colorway.surface, '#FFFFFF', 0.25) : colorway.surface;
  return { surface: `#${alpha}${surface.slice(1)}`,
    surfaceEnd: `#${alpha}${(theme === 'aurora' ? colorway.wash : colorway.surface).slice(1)}`,
    edge: theme === 'label' ? colorway.accent : colorway.line,
    shadow: theme === 'cushion' ? '#2438304D' : '#18283541', ink: colorway.ink,
    muted: colorway.muted, line: colorway.line, healthy: colorway.accent, secondary: colorway.accent2,
    warning: colorway.warning, error: colorway.error, chip: colorway.chip,
    panel: blendColor(colorway.surface, '#FFFFFF', 0.65), texture: colorway.accent,
    highlight: blendColor(colorway.surface, '#FFFFFF', 0.85) };
}
