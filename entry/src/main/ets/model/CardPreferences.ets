export type CardTheme = 'pine' | 'graphite' | 'mist' | 'coral' | 'glass';
export type CardAppearance = 'system' | 'light' | 'dark';

export interface CardPreferences {
  title: string;
  theme: CardTheme;
  appearance: CardAppearance;
  transparency: number;
  cardPeriodMinutes: number;
  autoIntervalMinutes: number;
  failureBackoffMinutes: number;
}

export function defaultCardPreferences(): CardPreferences {
  return { title: 'Sub2API', theme: 'pine', appearance: 'system', transparency: 0, cardPeriodMinutes: 60,
    autoIntervalMinutes: 60, failureBackoffMinutes: 15 };
}

export function normalizeCardPreferences(value: CardPreferences): CardPreferences {
  const defaults = defaultCardPreferences();
  const title = typeof value.title === 'string' ? value.title.replace(/[\r\n]/g, '').slice(0, 24) : defaults.title;
  const themes: string[] = ['pine', 'graphite', 'mist', 'coral', 'glass'];
  const appearances: string[] = ['system', 'light', 'dark'];
  const periods: number[] = [30, 60, 120, 240];
  const backoffs: number[] = [5, 15, 30, 60];
  return {
    title: title.trim() || defaults.title,
    theme: themes.includes(value.theme) ? value.theme : defaults.theme,
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
  warning: string;
  error: string;
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

export function cardPalette(theme: CardTheme, transparency: number, dark: boolean = false): CardPalette {
  const colors: CardPalette = theme === 'glass' ?
    dark ?
      { surface: '#354D57', surfaceEnd: '#1B3039', edge: '#B6D8DD', shadow: '#6608161B', ink: '#F6FBFA',
        muted: '#D1E3DF', line: '#8091ADB1', healthy: '#91E9C9', warning: '#FFCA79', error: '#FF9C9B' } :
      { surface: '#E1F0F1', surfaceEnd: '#BDD6DA', edge: '#FFFFFFFF', shadow: '#383B3B3E', ink: '#173139',
        muted: '#395E63', line: '#809FB9B6', healthy: '#176F63', warning: '#895A19', error: '#A6383D' } :
    theme === 'graphite' ?
    { surface: '#252D32', surfaceEnd: '#252D32', edge: '#00000000', shadow: '#00000000', ink: '#F4F5F2', muted: '#B5C5C2', line: '#52605F',
      healthy: '#7FD2AD', warning: '#F1B95E', error: '#FF8D83' } :
    theme === 'mist' ?
      { surface: '#EAF3F7', surfaceEnd: '#EAF3F7', edge: '#00000000', shadow: '#00000000', ink: '#203B4C', muted: '#5E7682', line: '#CADDE5',
        healthy: '#2879A4', warning: '#A87124', error: '#B94E56' } :
      theme === 'coral' ?
        { surface: '#FFF7F4', surfaceEnd: '#FFF7F4', edge: '#00000000', shadow: '#00000000', ink: '#392B31', muted: '#7F686D', line: '#EADBD9',
          healthy: '#277B66', warning: '#A66A24', error: '#AE5561' } :
        { surface: '#F9FBFA', surfaceEnd: '#F9FBFA', edge: '#00000000', shadow: '#00000000', ink: '#24332F', muted: '#64746E', line: '#DCE5E0',
          healthy: '#187B59', warning: '#A66D1D', error: '#B44842' };
  if (theme === 'glass') {
    const brightness = Math.max(0, Math.min(50, transparency)) / 50;
    colors.surface = blendColor(colors.surface, dark ? '#63858B' : '#F8FFFF', brightness);
    colors.surfaceEnd = blendColor(colors.surfaceEnd, dark ? '#344F59' : '#DBF1F2', brightness);
  } else {
    const alpha = Math.round(255 * (1 - Math.max(0, Math.min(50, transparency)) / 100));
    colors.surface = `#${alpha.toString(16).padStart(2, '0').toUpperCase()}${colors.surface.slice(1)}`;
    colors.surfaceEnd = colors.surface;
  }
  return colors;
}
