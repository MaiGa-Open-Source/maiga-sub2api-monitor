'use strict';

// Local design candidates only. These tokens do not change the HarmonyOS app.
const directions = [
  { number: '06', batch: 'new', id: 'aurora', name: '晨雾渐层', english: 'SOFT HORIZON', brief: '浅色晕染 · 连续曲线',
    description: '像清晨天空的一层淡彩，让数字浮在柔和的色温里。',
    traits: '浅色渐层、开放式分区、圆头曲线、细环与轻盈数字。',
    fit: '适合想有颜色、又不希望桌面被高饱和色块占满的场景。',
    note: '摘录 Recess 的长春花蓝、奶油与落日渐层，用深色文字承载数据。渐层压浅，保留文字对比，曲线与细环是卡片化改写。',
    sources: [['Recess', '2c7a280c-7cc1-4766-b043-bc8bdd9b868c']], radius: '22px', palettes: [
      { name: '蓝紫晨霞', surface: '#E8E9F7', ink: '#29344F', muted: '#555D78', line: '#B9BFD5', accent: '#4A4F91', accent2: '#934E66', warning: '#80500D', error: '#A1324A', chip: '#D8DDF1', wash: '#F8DDD8' },
      { name: '青杏薄雾', surface: '#E5EFEB', ink: '#283F3A', muted: '#526C63', line: '#B0C9BE', accent: '#31665E', accent2: '#8D563D', warning: '#7A5012', error: '#A23446', chip: '#CCE1D9', wash: '#F5E6CC' },
      { name: '粉桃云层', surface: '#F5E7ED', ink: '#513748', muted: '#74566B', line: '#D6B7C8', accent: '#865075', accent2: '#365E86', warning: '#805013', error: '#A02E45', chip: '#EACFDF', wash: '#E2E8FA' }
    ] },
  { number: '07', batch: 'new', id: 'cushion', name: '软垫模块', english: 'SOFT OBJECTS', brief: '圆润浮层 · 嵌套模块',
    description: '把数据装进圆润的小模块，像桌面上一组柔软的实体按键。',
    traits: '大圆角、局部浅浮影、嵌套指标块、胶囊柱与厚实的无衬线数字。',
    fit: '适合喜欢亲和、轻松、有一点立体感的日常桌面。',
    note: '摘录 Jitter 的浅白画布、扩散阴影、大圆角与少量紫色。把网页的软垫轮廓延展成卡片内的额度与指标模块，不使用整面强色。',
    sources: [['Jitter', 'ab1e41e9-7d21-4762-b498-51b8c63ae7ce']], radius: '25px', palettes: [
      { name: '香芋牛奶', surface: '#F5F2FA', ink: '#352B48', muted: '#6E617D', line: '#D1C6DF', accent: '#6B499A', accent2: '#346D79', warning: '#80500E', error: '#A8354F', chip: '#E4DAF1' },
      { name: '开心果乳酪', surface: '#F1F4E9', ink: '#35432D', muted: '#606D53', line: '#C4CFB6', accent: '#4A6C34', accent2: '#925436', warning: '#7C5013', error: '#A13345', chip: '#DDE6CD' },
      { name: '桃子酸奶', surface: '#FBF0EA', ink: '#513A34', muted: '#7B6158', line: '#DFC5B7', accent: '#9A553C', accent2: '#58689C', warning: '#7A5010', error: '#A33149', chip: '#F0D9CA' }
    ] },
  { number: '08', batch: 'new', id: 'label', name: '酒标徽章', english: 'HOUSE RESERVE', brief: '椭圆徽章 · 复古细框',
    description: '借一张复古酒标的仪式感，把额度变成每日的小徽章。',
    traits: '内外双细框、椭圆额度章、衬线斜体数字、对称标题与点状图表。',
    fit: '适合偏复古、温暖的桌面；比纸感年报更装饰、更有标牌感。',
    note: '摘录 Ghia 的奶油酒红、圆形产品框和衬线/窄体对照。椭圆徽章、内框与额度点尺是自主延展；不同于纸感年报的直线分栏。',
    sources: [['Ghia', '156462ab-7b11-4029-be45-c2dba853e894']], radius: '18px', font: 'Georgia, serif', palettes: [
      { name: '酒红奶油', surface: '#F5EADF', ink: '#602238', muted: '#835767', line: '#C9A6AA', accent: '#7C2B48', accent2: '#3B6863', warning: '#815210', error: '#A32F3E', chip: '#EAD3CB' },
      { name: '橄榄藏品', surface: '#F1EDD9', ink: '#3C4C35', muted: '#5F6C4E', line: '#B8BFA0', accent: '#46623A', accent2: '#98513D', warning: '#7C5011', error: '#A23441', chip: '#DFE2C5' },
      { name: '海盐蓝章', surface: '#E8EEF1', ink: '#2D4A60', muted: '#566E7D', line: '#A5BDCD', accent: '#365F7B', accent2: '#92546C', warning: '#7C5013', error: '#A1314A', chip: '#CFDFE8' }
    ] },
  { number: '09', batch: 'new', id: 'pixel', name: '口袋液晶', english: 'POCKET LCD', brief: '像素点阵 · 掌机屏框',
    description: '让监控卡像一块随身液晶屏，保留小设备的趣味与清楚的数字。',
    traits: '倒角屏框、等宽数字、点阵底纹、方点额度尺与阶梯折线。',
    fit: '适合喜欢掌机、复古数码的桌面；比工业仪表更像一块可玩的显示屏。',
    note: '借用 Playdate 的随身设备语境和灰白承托产品的思路。没有照搬其黄色大色块；液晶点阵、屏框与阶梯图是本稿的自主设计。',
    sources: [['Playdate', '2175034b-96d7-417e-886f-ff5a4d8551ae']], radius: '6px', font: 'Consolas, monospace', palettes: [
      { name: '苔绿液晶', surface: '#DFE7CC', ink: '#2C3E2A', muted: '#56664B', line: '#A7B693', accent: '#36582E', accent2: '#71502A', warning: '#73500E', error: '#942F3D', chip: '#C4D1B1' },
      { name: '灰蓝电子纸', surface: '#E0E8EE', ink: '#2A3D51', muted: '#52667B', line: '#A4B6C5', accent: '#355777', accent2: '#7F506D', warning: '#79500F', error: '#A12F45', chip: '#C7D5E0' },
      { name: '蜜茶屏幕', surface: '#EEE3C8', ink: '#4A3E24', muted: '#6E6145', line: '#BCAB7F', accent: '#71521F', accent2: '#426753', warning: '#76500D', error: '#9D303D', chip: '#DACEA7' }
    ] },
  { number: '10', batch: 'new', id: 'chrome', name: '轻铝面板', english: 'SILVER OBJECT', brief: '细腻金属 · 压印轮廓',
    description: '用浅色金属和压印边缘，让数据像一件精简的桌面硬件。',
    traits: '浅金属色温、细密拉丝、倒角边框、粗体数字与压印按钮。',
    fit: '适合硬件风或简洁桌面；偏浅色实体材质，与现有深色石墨拉开距离。',
    note: '摘录 Desktop.fm 的冷灰画布、银色 CD 物件与紧凑粗体。原站的金属来自 3D 物件，本稿将其自主延展为浅色拉丝面板和倒角，不复制其页面布局。',
    sources: [['Desktop.fm', 'cb266ff9-f168-4a42-a522-f0e84508f90f']], radius: '12px', palettes: [
      { name: '月光银', surface: '#E5E8EB', ink: '#303944', muted: '#5B6571', line: '#A6B0BA', accent: '#355B7A', accent2: '#80536E', warning: '#7B4E0E', error: '#A33045', chip: '#CBD1D8' },
      { name: '香槟铝', surface: '#ECE6DB', ink: '#494033', muted: '#6E6354', line: '#BEB09A', accent: '#775730', accent2: '#436B69', warning: '#78500F', error: '#A33043', chip: '#D9CFBD' },
      { name: '玫瑰钛', surface: '#EBE1E2', ink: '#49343F', muted: '#705B66', line: '#BFA5B1', accent: '#81556D', accent2: '#3D627A', warning: '#7B5010', error: '#A12F45', chip: '#DAC6CE' }
    ] },

];
const $ = id => document.getElementById(id);
const params = new URLSearchParams(location.search);
const state = { style: directions.some(d => d.id === params.get('style')) ? params.get('style') : 'aurora',
  palette: Math.max(0, Math.min(2, Number.parseInt(params.get('palette'), 10) || 0)),
  wallpaper: params.get('wallpaper') === 'dark' ? 'dark' : 'light', status: 'normal', days: 7, metric: 'requests', day: null };
let shortlist = [];
try {
  const saved = JSON.parse(localStorage.getItem('sub2api-visual-shortlist-v1') || '[]');
  if (Array.isArray(saved)) shortlist = [...new Set(saved.filter(value => typeof value === 'string' && directions.some(d =>
    d.palettes.some((_, i) => `${d.id}:${i}` === value))))];
} catch (_) { /* The visual prototype also works without local storage. */ }
const pattern = [28, 36, 31, 47, 54, 42, 58, 49, 63, 37, 45, 72, 68, 51, 59, 76, 66, 55, 82, 71, 64, 88, 74, 69, 92, 84, 78, 103, 95, 87];
const usageHistory = pattern.map((value, index) => {
  const date = new Date(Date.UTC(2026, 8, 23 + index));
  return { date: `${String(date.getUTCMonth() + 1).padStart(2, '0')}.${String(date.getUTCDate()).padStart(2, '0')}`,
    requests: value * 14, cost: value * .17 };
});
const money = n => `$${n.toFixed(2)}`;
const direction = () => directions.find(d => d.id === state.style);
const selectedKey = () => `${state.style}:${state.palette}`;
const statusInfo = () => ({
  normal: { label: '运行正常', remaining: 68, known: true, tone: 'accent', time: '09:41', caption: '剩余额度' },
  low: { label: '额度偏低', remaining: 18, known: true, tone: 'warning', time: '09:41', caption: '剩余额度' },
  empty: { label: '额度用尽', remaining: 0, known: true, tone: 'error', time: '09:41', caption: '剩余额度' },
  unknown: { label: '额度未知', remaining: 0, known: false, tone: 'warning', time: '09:41', caption: '额度未知' },
  offline: { label: '连接失败', remaining: 68, known: true, tone: 'error', time: '08:42', caption: '上次额度' }
})[state.status];
const refreshButton = () => '<button class="refresh" type="button" data-refresh aria-label="模拟刷新卡片">↻</button>';
const heading = (title, status = false) => `<div class="card-header"><span class="card-kicker">01 /</span><strong class="card-title">${title}</strong>${status ? `<span class="card-status">${statusInfo().label}</span>` : ''}${refreshButton()}</div>`;
const footer = (left, time = statusInfo().time) => `<div class="card-footer"><span class="state">${left}</span><span>${time} 更新</span></div>`;
function quotaCard(single) {
  const s = statusInfo(), value = s.known ? `${s.remaining}%` : '--';
  if (single) return `${heading('Sub2API')}<div class="single-identity"><div class="account-name">主账号 · 北区</div><div class="account-meta">Claude Pro · 本周</div></div>
    <div class="single-value"><svg class="ring" viewBox="0 0 70 70" aria-hidden="true"><circle class="ring-track ${s.known ? '' : 'ring-unknown'}" cx="35" cy="35" r="30"/>
    ${s.known ? `<circle class="ring-fill" cx="35" cy="35" r="30" stroke-dashoffset="${188.5 * (1 - s.remaining / 100)}"/>` : ''}</svg>
    <div class="single-number"><strong>${value}</strong><span>${s.caption}</span></div><div class="meter ${s.known ? '' : 'meter-unknown'}" aria-hidden="true"><i></i></div><div class="pixel-meter ${s.known ? '' : 'unknown'}" aria-hidden="true">${Array.from({length: 20}, (_, i) => `<i class="${s.known && i < Math.round(s.remaining / 5) ? 'lit' : ''}"></i>`).join('')}</div></div>${footer(s.label)}`;
  return `${heading('Sub2API', true)}<div class="account-row"><div class="account-identity"><div class="account-name">主账号 · 北区</div><div class="account-meta">Claude Pro · 本周</div></div><div class="account-total"><strong>${value}</strong><small>${s.caption}</small></div></div>
    <div class="account-row"><div class="account-identity"><div class="account-name">团队账号 · 南区</div><div class="account-meta">Claude Max · 本周</div></div><div class="account-total"><strong>${s.known ? '42%' : '--'}</strong><small>${s.caption}</small></div></div>
    <div class="card-footer"><span>${state.status === 'offline' ? '上次成功数据' : state.status === 'unknown' ? '2 个额度未知' : state.status === 'low' || state.status === 'empty' ? '1 个已知异常' : '0 个已知异常'}</span><span>${s.time} 更新</span></div>`;
}
function chartMarkup(large) {
  const values = usageHistory.slice(-state.days), selected = state.day === null ? values.length - 1 : Math.min(state.day, values.length - 1);
  const amount = row => state.metric === 'cost' ? row.cost : row.requests;
  const max = Math.max(...values.map(amount)) * 1.15, left = 28, right = 299, top = 7, bottom = large ? 153 : 34;
  const x = i => left + (i + .5) * (right - left) / values.length;
  const y = v => bottom - v / max * (bottom - top);
  const axis = v => state.metric === 'cost' ? `$${v.toFixed(0)}` : `${Math.round(v / 100) / 10}k`;
  let svg = [0, .5, 1].map(f => `<line class="grid" x1="${left}" x2="${right}" y1="${y(max * f)}" y2="${y(max * f)}"/><text x="23" y="${y(max * f) + 3}" text-anchor="end">${axis(max * f)}</text>`).join('');
  if (state.style === 'label') {
    svg += values.map((row, i) => `<line class="lollipop" x1="${x(i)}" x2="${x(i)}" y1="${bottom}" y2="${y(amount(row))}"/><circle class="mark" cx="${x(i)}" cy="${y(amount(row))}" r="${state.days === 7 ? 3 : 1.6}" opacity="${i === selected ? 1 : .65}"/>`).join('');
  } else if (state.style === 'pixel') {
    const path = values.map((row, i) => i ? `H ${x(i)} V ${y(amount(row))}` : `M ${x(i)} ${y(amount(row))}`).join(' ');
    svg += `<path class="curve" d="${path}"/><rect class="mark" x="${x(selected)-2.5}" y="${y(amount(values[selected]))-2.5}" width="5" height="5"/>`;
  } else if (state.days === 7 && state.style !== 'aurora') {
    svg += values.map((row, i) => `<rect class="mark" x="${x(i) - 9}" y="${y(amount(row))}" width="18" height="${bottom - y(amount(row))}" rx="${state.style === 'cushion' ? 9 : state.style === 'chrome' ? 2 : 0}" opacity="${i === selected ? 1 : .6}"/>`).join('');
  } else {
    const points = values.map((row, i) => `${x(i)},${y(amount(row))}`).join(' ');
    svg += `<path class="area" d="M ${x(0)},${bottom} L ${points.replaceAll(' ', ' L ')} L ${x(values.length - 1)},${bottom} Z"/><polyline class="curve" points="${points}"/><circle class="point" cx="${x(selected)}" cy="${y(amount(values[selected]))}" r="3"/>`;
  }
  values.forEach((row, i) => {
    if (state.days === 7 || i === 0 || i === values.length - 1 || i % 7 === 0 && i < values.length - 3) svg += `<text x="${x(i)}" y="${bottom + 13}" text-anchor="middle">${row.date}</text>`;
    svg += `<rect class="hit" role="button" tabindex="0" data-day="${i}" aria-label="${row.date}，${row.requests} 次请求，费用 ${money(row.cost)}" x="${x(i) - (right - left) / values.length / 2}" y="0" width="${(right - left) / values.length}" height="${bottom + 4}"/>`;
  });
  return svg;
}
function trendCard(large) {
  const rows = usageHistory.slice(-state.days), active = rows[state.day === null ? rows.length - 1 : Math.min(state.day, rows.length - 1)];
  return `<div class="card-header"><span class="card-icon">S2</span><div class="trend-identity"><div class="card-title">用量趋势</div><div class="account-meta">主账号 · 北区</div></div>${refreshButton()}</div>
    <div class="period-row"><button type="button" data-days="7" aria-pressed="${state.days === 7}">近 7 天</button><button type="button" data-days="30" aria-pressed="${state.days === 30}">近 30 天</button><span>${state.status === 'offline' ? '连接失败 · 上次数据' : '09:41 更新'}</span></div>
    <div class="metrics"><button class="metric" style="--metric-color:var(--accent)" type="button" data-metric="requests" aria-pressed="${state.metric === 'requests'}"><span>请求总数</span><strong>${rows.reduce((sum, row) => sum + row.requests, 0).toLocaleString('en-US')}</strong></button>
    <button class="metric" style="--metric-color:var(--accent2)" type="button" data-metric="cost" aria-pressed="${state.metric === 'cost'}"><span>账号费用</span><strong>${money(rows.reduce((sum, row) => sum + row.cost, 0))}</strong></button></div>
    <svg class="chart" viewBox="0 0 304 ${large ? 172 : 51}" preserveAspectRatio="none" aria-label="近 ${state.days} 天每日${state.metric === 'requests' ? '请求数' : '费用'}">${chartMarkup(large)}</svg>
    <div class="card-footer trend-footer"><strong>${active.date} · ${state.metric === 'requests' ? `${active.requests} 次` : money(active.cost)}</strong><span>${state.metric === 'requests' ? '每日请求' : '每日账号费用'}</span></div>`;
}
function renderChoices() {
  $('style-options').innerHTML = directions.map(d => {
    const p = d.palettes[0];
    return `<button type="button" class="style-option" data-direction="${d.id}" aria-pressed="${d.id === state.style}" style="--mini-bg:${p.surface};--mini-ink:${p.accent};--mini-line:${p.line};--mini-radius:${d.radius};--mini-font:${d.font || 'sans-serif'}"><span class="miniature" aria-hidden="true">${d.id === 'instrument' ? '68' : d.id === 'riso' ? '✳' : d.id === 'pixel' ? '▦' : d.id === 'label' ? 'S²' : d.id === 'chrome' ? 'S2' : 'Aa'}</span><span><strong>${d.name}</strong><small>${d.brief}</small></span><span class="style-number">${d.number}</span></button>`;
  }).join('');
  $('palette-options').innerHTML = direction().palettes.map((p, i) => `<button class="palette-option" type="button" data-palette="${i}" aria-pressed="${state.palette === i}"><span class="palette-colors" aria-hidden="true"><i style="background:${p.surface}"></i><i style="background:${p.accent}"></i><i style="background:${p.accent2}"></i></span>${p.name}</button>`).join('');
}
function renderShortlist() {
  const selected = shortlist.includes(selectedKey());
  $('shortlist').textContent = selected ? '已加入候选 ✓ · 点击取消' : '加入候选';
  $('shortlist').setAttribute('aria-pressed', String(selected));
  $('shortlist-message').textContent = shortlist.length ? `已选：${shortlist.map(key => { const [id, i] = key.split(':'); const d = directions.find(item => item.id === id); return `${d.name} / ${d.palettes[i].name}`; }).join('、')}` : '可收藏多套，方便最后比较。';
}
function render() {
  const active = document.activeElement;
  const focusAttribute = active && ['data-direction', 'data-palette', 'data-wallpaper', 'data-days', 'data-metric', 'data-day']
    .find(name => active.hasAttribute(name));
  const focusValue = focusAttribute ? active.getAttribute(focusAttribute) : '';
  const focusCard = active && active.closest('.wcard');
  const focusKind = focusCard ? focusCard.dataset.kind : '';
  const d = direction(), palette = d.palettes[state.palette], status = statusInfo();
  renderChoices();

  $('style-index').textContent = `${d.number} / ${d.english}`;
  $('style-title').textContent = d.name;
  $('style-description').textContent = d.description;
  $('palette-label').textContent = palette.name;
  $('style-traits').textContent = d.traits;
  $('style-fit').textContent = d.fit;
  $('reference-note').textContent = d.note;
  $('reference-links').innerHTML = d.sources.map(([name, id]) => `<a target="_blank" rel="noopener noreferrer" href="https://styles.refero.design/style/${id}">${name} ↗</a>`).join('');
  $('desktop').dataset.wallpaper = state.wallpaper;
  document.querySelectorAll('[data-wallpaper]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.wallpaper === state.wallpaper)));
  $('gallery').innerHTML = [
    ['single', '额度卡 · 单账号', '2×2', quotaCard(true)], ['dual', '额度卡 · 双账号', '2×4', quotaCard(false)],
    ['medium', '趋势卡 · 中卡', '2×4', trendCard(false)], ['large', '趋势卡 · 大卡', '4×4', trendCard(true)]
  ].map(([kind, title, size, content]) => `<figure class="tile"><figcaption class="tile-label"><strong>${title}</strong><span>${size}</span></figcaption><div class="card-holder"><article class="wcard" data-style="${state.style}" data-kind="${kind}" aria-label="${title} ${size}">${content}</article></div></figure>`).join('');
  document.querySelectorAll('.wcard').forEach(card => {
    Object.entries(palette).forEach(([key, value]) => { if (key !== 'name') card.style.setProperty(`--${key}`, value); });
    card.style.setProperty('--tone', `var(--${status.tone})`);
    card.style.setProperty('--remaining', `${status.remaining}%`);
    card.style.setProperty('--chart-color', `var(--${state.metric === 'requests' ? 'accent' : 'accent2'})`);
  });
  renderShortlist();
  if (focusAttribute) {
    const scope = focusKind ? document.querySelector(`.wcard[data-kind="${focusKind}"]`) : document;
    const target = scope && scope.querySelector(`[${focusAttribute}="${focusValue}"]`);
    if (target) target.focus({ preventScroll: true });
  }
  try { const url = new URL(location.href); url.searchParams.set('style', state.style); url.searchParams.set('palette', state.palette); url.searchParams.set('wallpaper', state.wallpaper); window.history.replaceState(null, '', url); } catch (_) { /* File preview needs no URL persistence. */ }
}
document.addEventListener('click', event => {
  const button = event.target.closest('button');
  if (!button) return;
  if (button.dataset.direction) { state.style = button.dataset.direction; state.palette = 0; render(); }
  else if (button.dataset.palette !== undefined) { state.palette = Number(button.dataset.palette); render(); }
  else if (button.dataset.wallpaper) { state.wallpaper = button.dataset.wallpaper; render(); }
  else if (button.dataset.days) { state.days = Number(button.dataset.days); state.day = null; render(); }
  else if (button.dataset.metric) { state.metric = button.dataset.metric; render(); }
  else if (button.hasAttribute('data-refresh')) {
    document.querySelectorAll('[data-refresh]').forEach(item => { item.textContent = '✓'; item.setAttribute('aria-label', '示例刷新完成'); });
  }
});
$('data-state').addEventListener('change', event => { state.status = event.target.value; render(); });
$('gallery').addEventListener('click', event => { const point = event.target.closest('[data-day]'); if (point) { state.day = Number(point.dataset.day); render(); } });
$('gallery').addEventListener('keydown', event => {
  const point = event.target.closest('[data-day]');
  if (point && (event.key === 'Enter' || event.key === ' ')) { event.preventDefault(); state.day = Number(point.dataset.day); render(); }
});
$('shortlist').addEventListener('click', () => {
  const key = selectedKey();
  shortlist = shortlist.includes(key) ? shortlist.filter(item => item !== key) : [...shortlist, key];
  renderShortlist();
  try { localStorage.setItem('sub2api-visual-shortlist-v1', JSON.stringify(shortlist)); }
  catch (_) { $('shortlist-message').textContent += '（当前浏览器无法保存，刷新后会清空。）'; }
});
render();
