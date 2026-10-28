//
//  app.js — Chatterkill tester panel
//
//  Pure front-end. It never watches the keyboard by itself when the native
//  bridge exists: the menu-bar engine feeds every event in, so the panel shows
//  exactly what the engine sees (including the events it swallowed).
//  A tiny local keydown fallback keeps the page usable when opened standalone.
//

'use strict';

// ---------------------------------------------------------------- i18n
const ZH = (navigator.language || 'en').toLowerCase().startsWith('zh');

const T = {
  tagline:        ZH ? '键盘连击检测' : 'key chatter tester',
  listening:      ZH ? '监听中' : 'listening',
  noPermission:   ZH ? '缺辅助功能授权' : 'no accessibility',
  paused:         ZH ? '已暂停' : 'paused',
  demo:           ZH ? '独立预览' : 'standalone preview',
  lastKey:        ZH ? '最近按键' : 'last key',
  threshold:      ZH ? '阈值' : 'threshold',
  interval:       ZH ? '间隔' : 'interval',
  presses:        ZH ? '次数' : 'presses',
  measured:       ZH ? '已测键数' : 'measured keys',
  chatter:        ZH ? '连击次数' : 'chatter hits',
  fastest:        ZH ? '最快间隔' : 'fastest interval',
  single:         ZH ? '本次单键间隔' : 'last single-key rate',
  reset:          ZH ? '重置' : 'RESET',
  done:           ZH ? '完成' : 'DONE',
  untested:       ZH ? '未测' : 'untested',
  normal:         ZH ? '正常' : 'normal',
  tooFast:        ZH ? '太快 / 连击' : 'too fast / chatter',
  slow:           ZH ? '松手过慢' : 'slow release',
  locked:         ZH ? '固件层不上报' : 'not reported by firmware',
  popTitle:       ZH ? '判定窗口' : 'Threshold',
  popHint:        ZH ? '比这个还短的间隔视为同一次抖动，直接吞掉。' : 'Shorter than this = same bounce, blocked.',
  useGlobal:      ZH ? '用全局值' : 'Use global',
  ok:             ZH ? '确定' : 'OK',
  ms:             ZH ? '毫秒' : 'ms'
};

function applyStaticText() {
  const set = (id, text) => { const el = document.getElementById(id); if (el) el.textContent = text; };
  set('tagline', T.tagline);
  set('engineText', hasBridge() ? T.listening : T.demo);
  set('lastLabel', T.lastKey);
  set('thrLabel', T.threshold);
  set('intLabel', T.interval);
  set('cntLabel', T.presses);
  set('s1', T.measured); set('s2', T.chatter); set('s3', T.fastest); set('s4', T.single);
  set('reset', T.reset); set('done', T.done);
  set('l0', T.untested); set('l1', T.normal); set('l2', T.tooFast); set('l3', T.slow); set('l4', T.locked);
  set('popTitle', T.popTitle); set('popHint', T.popHint);
  set('popGlobal', T.useGlobal); set('popOk', T.ok);
}

// ---------------------------------------------------------------- layout
const FN_ROW = [
  ['Esc', 1], ['sp', .5],
  ['F1', 1], ['F2', 1], ['F3', 1], ['F4', 1], ['sp', .5],
  ['F5', 1], ['F6', 1], ['F7', 1], ['F8', 1], ['sp', .5],
  ['F9', 1], ['F10', 1], ['F11', 1], ['F12', 1], ['sp', .5],
  ['F13', 1, 'PrtSc'], ['F14', 1, 'ScrLk'], ['F15', 1, 'Pause']
];

const MAIN_ROWS = [
  [['`', 1], ['1', 1], ['2', 1], ['3', 1], ['4', 1], ['5', 1], ['6', 1], ['7', 1], ['8', 1], ['9', 1], ['0', 1],
   ['-', 1], ['=', 1], ['Delete', 2, 'Del']],
  [['Tab', 1.5], ['Q', 1], ['W', 1], ['E', 1], ['R', 1], ['T', 1], ['Y', 1], ['U', 1], ['I', 1], ['O', 1], ['P', 1],
   ['[', 1], [']', 1], ['\\', 1]],
  [['CapsLock', 1.75, 'Caps'], ['A', 1], ['S', 1], ['D', 1], ['F', 1], ['G', 1], ['H', 1], ['J', 1], ['K', 1], ['L', 1],
   [';', 1], ["'", 1], ['Return', 2.25, 'Enter']],
  [['Shift', 2.25], ['Z', 1], ['X', 1], ['C', 1], ['V', 1], ['B', 1], ['N', 1], ['M', 1], [',', 1], ['.', 1], ['/', 1],
   ['RightShift', 2.75, 'Shift']],
  [['Control', 1.25, 'Ctrl'], ['Option', 1.25, 'Alt'], ['Command', 1.25, 'Cmd'], ['Space', 6.25],
   ['RightCommand', 1.25, 'Cmd'], ['RightOption', 1.25, 'Alt'], ['RightControl', 1.25, 'Ctrl']]
];

const NAV_ROWS = [
  [['Help', 1, 'Ins'], ['Home', 1], ['PageUp', 1, 'PgUp']],
  [['ForwardDelete', 1, 'Del'], ['End', 1], ['PageDown', 1, 'PgDn']],
  ['blank'],
  [['sp', 1], ['UpArrow', 1, '▲'], ['sp', 1]],
  [['LeftArrow', 1, '◀'], ['DownArrow', 1, '▼'], ['RightArrow', 1, '▶']]
];

// 小键盘用 grid 放，行列按物理位置写死
const NUMPAD = [
  { n: 'KeypadClear',   label: 'Num',     col: 1, row: 1 },
  { n: 'KeypadDivide',  label: '/',       col: 2, row: 1 },
  { n: 'KeypadMultiply',label: '*',       col: 3, row: 1 },
  { n: 'KeypadMinus',   label: '-',       col: 4, row: 1 },
  { n: 'Keypad7',       label: '7',       col: 1, row: 2 },
  { n: 'Keypad8',       label: '8',       col: 2, row: 2 },
  { n: 'Keypad9',       label: '9',       col: 3, row: 2 },
  { n: 'KeypadPlus',    label: '+',       col: 4, row: 2, rowSpan: 2 },
  { n: 'Keypad4',       label: '4',       col: 1, row: 3 },
  { n: 'Keypad5',       label: '5',       col: 2, row: 3 },
  { n: 'Keypad6',       label: '6',       col: 3, row: 3 },
  { n: 'Keypad1',       label: '1',       col: 1, row: 4 },
  { n: 'Keypad2',       label: '2',       col: 2, row: 4 },
  { n: 'Keypad3',       label: '3',       col: 3, row: 4 },
  { n: 'KeypadEnter',   label: 'Enter',   col: 4, row: 4, rowSpan: 2 },
  { n: 'Keypad0',       label: '0',       col: 1, row: 5, colSpan: 2 },
  { n: 'KeypadDecimal', label: '.',       col: 3, row: 5 }
];

const LOCKED = ['Fn1', 'Fn2'];

function el(tag, cls, text) {
  const node = document.createElement(tag);
  if (cls) node.className = cls;
  if (text !== undefined) node.textContent = text;
  return node;
}

function makeKey(name, widthUnits, label) {
  if (name === 'sp') {
    const spacer = el('div', 'key spacer');
    spacer.style.width = `calc(var(--u) * ${widthUnits} - var(--gap))`;
    return spacer;
  }
  const key = el('div', 'key', label || name);
  key.dataset.key = name;
  key.dataset.state = 'untested';
  key.style.width = `calc(var(--u) * ${widthUnits} - var(--gap))`;
  if ((label || name).length > 5) key.classList.add('small');
  return key;
}

function buildBoard() {
  const board = document.getElementById('board');
  board.textContent = '';

  const left = el('div', 'col');
  left.style.gap = '10px';

  const fnRow = el('div', 'row fn');
  FN_ROW.forEach(([n, w, l]) => fnRow.appendChild(makeKey(n, w, l)));
  left.appendChild(fnRow);

  const mid = el('div', '');
  mid.style.display = 'flex';
  mid.style.gap = '10px';

  const mainCol = el('div', 'col');
  MAIN_ROWS.forEach(spec => {
    const row = el('div', 'row');
    spec.forEach(([n, w, l]) => row.appendChild(makeKey(n, w, l)));
    mainCol.appendChild(row);
  });
  mid.appendChild(mainCol);

  const navCol = el('div', 'col');
  NAV_ROWS.forEach(spec => {
    if (spec === 'blank') {
      const blank = el('div', 'row');
      blank.style.height = 'var(--h)';
      navCol.appendChild(blank);
      return;
    }
    const row = el('div', 'row');
    spec.forEach(([n, w, l]) => row.appendChild(makeKey(n, w, l)));
    navCol.appendChild(row);
  });
  mid.appendChild(navCol);
  left.appendChild(mid);
  board.appendChild(left);

  // numpad
  const pad = el('div', '');
  pad.style.display = 'grid';
  pad.style.gridTemplateColumns = 'repeat(4, calc(var(--u) - var(--gap)))';
  pad.style.gridAutoRows = 'var(--h)';
  pad.style.gap = 'var(--gap)';

  NUMPAD.forEach(spec => {
    const key = makeKey(spec.n, 1, spec.label);
    key.style.width = '';
    key.style.gridColumn = `${spec.col} / span ${spec.colSpan || 1}`;
    key.style.gridRow = `${spec.row} / span ${spec.rowSpan || 1}`;
    if (spec.label.length > 5) key.classList.add('small');
    pad.appendChild(key);
  });
  board.appendChild(pad);
}

// ---------------------------------------------------------------- state
const keyState = new Map();   // name -> { state, presses, lastInterval, minInterval, threshold }

function ensureState(name) {
  let s = keyState.get(name);
  if (!s) {
    s = { state: 'untested', presses: 0, lastInterval: null, minInterval: null, threshold: null };
    keyState.set(name, s);
  }
  return s;
}

let config = { global: { thresholdMs: 100 }, perKey: {} };

function keyElement(name) {
  return document.querySelector(`.key[data-key="${CSS.escape(name)}"]`);
}

function paintKey(name) {
  const node = keyElement(name);
  const s = keyState.get(name);
  if (!node || !s) return;
  node.dataset.state = s.state;
  node.dataset.badge = s.state === 'normal' ? 'off' : 'on';

  const existing = node.querySelector('.ms');
  if (s.threshold !== null) {
    const badge = existing || el('span', 'ms');
    badge.textContent = s.threshold;
    if (!existing) node.appendChild(badge);
  } else if (existing) {
    existing.remove();
  }
}

// ---------------------------------------------------------------- stats
const totals = { chatter: 0, fastest: null };

function refreshStats() {
  let measured = 0;
  keyState.forEach(s => { if (s.state !== 'untested') measured += 1; });
  document.getElementById('v1').textContent = String(measured);
  document.getElementById('v2').textContent = String(totals.chatter);
  document.getElementById('v3').textContent = totals.fastest === null ? '0' : String(totals.fastest);
}

function stamp() {
  const d = new Date();
  const p = (n, w = 2) => String(n).padStart(w, '0');
  return `${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}.${p(d.getMilliseconds(), 3)}`;
}

// ---------------------------------------------------------------- key events
function renderEvent(ev) {
  const name = ev.name;
  const s = ensureState(name);
  const node = keyElement(name);

  if (node) {
    node.classList.add('pressed');
    setTimeout(() => node.classList.remove('pressed'), 110);
  }

  if (ev.phase === 'down') {
    s.presses += 1;
    if (ev.intervalMs > 0) {
      s.lastInterval = ev.intervalMs;
      if (s.minInterval === null || ev.intervalMs < s.minInterval) s.minInterval = ev.intervalMs;
      if (totals.fastest === null || ev.intervalMs < totals.fastest) totals.fastest = ev.intervalMs;
      document.getElementById('v4').textContent = String(ev.intervalMs);
    }
    if (ev.verdict === 'chatter') {
      s.state = 'chatter';
      totals.chatter += 1;
    } else {
      s.state = 'normal';
    }
  } else if (ev.verdict === 'slow') {
    s.state = 'slow';
  }

  s.threshold = (config.perKey && config.perKey[name] !== undefined) ? config.perKey[name] : null;

  document.getElementById('lastKey').textContent = name;
  document.getElementById('lastTime').textContent = stamp();
  document.getElementById('lastThr').textContent = String(ev.thresholdMs);
  document.getElementById('lastInt').textContent = ev.phase === 'down' ? `${ev.intervalMs}` : `${ev.heldMs}`;
  document.getElementById('lastCnt').textContent = String(s.presses);

  paintKey(name);
  refreshStats();
}

// ---------------------------------------------------------------- bridge
function hasBridge() {
  return !!(window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.chatterkill);
}

function post(message) {
  if (hasBridge()) window.webkit.messageHandlers.chatterkill.postMessage(message);
}

function updateEnginePill() {
  const dot = document.getElementById('engineDot');
  const text = document.getElementById('engineText');
  const pill = document.getElementById('enginePill');
  if (!text) return;

  if (!hasBridge()) {
    text.textContent = T.demo;
    if (dot) dot.className = 'dot';
    if (pill) pill.className = 'pill';
    return;
  }
  if (config.trusted === false) {
    text.textContent = T.noPermission;
    if (dot) dot.className = 'dot warn';
    if (pill) pill.className = 'pill fix';
  } else if (config.enabled === false) {
    text.textContent = T.paused;
    if (dot) dot.className = 'dot warn';
    if (pill) pill.className = 'pill';
  } else {
    text.textContent = T.listening;
    if (dot) dot.className = 'dot';
    if (pill) pill.className = 'pill';
  }
}

window.Chatterkill = {
  key(ev) { try { renderEvent(ev); } catch (e) { /* never let JS break the engine */ } },
  config(cfg) {
    config = cfg || config;
    if (config.perKey) {
      Object.keys(config.perKey).forEach(name => {
        const s = ensureState(name);
        s.threshold = config.perKey[name];
        paintKey(name);
      });
    }
    updateEnginePill();
  }
};

// ---------------------------------------------------------------- threshold popover
const pop = document.getElementById('pop');
const popRange = document.getElementById('popRange');
let popKey = null;

function openPopover(name, anchor) {
  popKey = name;
  const s = ensureState(name);
  const value = config.perKey && config.perKey[name] !== undefined
    ? config.perKey[name]
    : (config.global ? config.global.thresholdMs : 100);
  popRange.value = value;
  document.getElementById('popVal').textContent = String(value);
  document.getElementById('popTitle').textContent = `${T.popTitle} · ${name}`;

  const rect = anchor.getBoundingClientRect();
  pop.classList.add('on');
  const width = pop.offsetWidth;
  let left = rect.left + rect.width / 2 - width / 2;
  left = Math.max(10, Math.min(left, window.innerWidth - width - 10));
  let top = rect.top - pop.offsetHeight - 8;
  if (top < 10) top = rect.bottom + 8;
  pop.style.left = `${left}px`;
  pop.style.top = `${top}px`;
}

function closePopover() {
  pop.classList.remove('on');
  popKey = null;
}

popRange.addEventListener('input', () => {
  document.getElementById('popVal').textContent = popRange.value;
});

document.getElementById('popOk').addEventListener('click', () => {
  if (!popKey) return;
  const ms = Number(popRange.value);
  config.perKey = config.perKey || {};
  config.perKey[popKey] = ms;
  const s = ensureState(popKey);
  s.threshold = ms;
  paintKey(popKey);
  post({ type: 'setThreshold', key: popKey, ms });
  closePopover();
});

document.getElementById('popGlobal').addEventListener('click', () => {
  if (!popKey) return;
  if (config.perKey) delete config.perKey[popKey];
  const s = ensureState(popKey);
  s.threshold = null;
  paintKey(popKey);
  post({ type: 'setThreshold', key: popKey, ms: null });
  closePopover();
});

document.addEventListener('click', e => {
  if (!pop.classList.contains('on')) return;
  if (pop.contains(e.target)) return;
  if (e.target.classList && e.target.classList.contains('key')) return;
  closePopover();
});

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') closePopover();
});

// ---------------------------------------------------------------- board events
document.getElementById('board').addEventListener('click', e => {
  const key = e.target.closest('.key[data-key]');
  if (!key) return;
  const name = key.dataset.key;
  if (LOCKED.includes(name)) return;
  openPopover(name, key);
});

document.getElementById('reset').addEventListener('click', () => {
  keyState.forEach(s => {
    s.state = 'untested';
    s.presses = 0;
    s.lastInterval = null;
    s.minInterval = null;
  });
  totals.chatter = 0;
  totals.fastest = null;
  document.querySelectorAll('.key').forEach(node => paintKey(node.dataset.key));
  document.getElementById('v1').textContent = '0';
  document.getElementById('v2').textContent = '0';
  document.getElementById('v3').textContent = '0';
  document.getElementById('v4').textContent = '0';
  document.getElementById('lastKey').textContent = '—';
  document.getElementById('lastTime').textContent = '--:--:--.---';
  document.getElementById('lastInt').textContent = '—';
  document.getElementById('lastCnt').textContent = '0';
  post({ type: 'reset' });
});

document.getElementById('done').addEventListener('click', () => {
  post({ type: 'done' });
  if (!hasBridge()) window.close();
});

// ---------------------------------------------------------------- standalone fallback
const CODE_TO_NAME = {
  KeyA: 'A', KeyB: 'B', KeyC: 'C', KeyD: 'D', KeyE: 'E', KeyF: 'F', KeyG: 'G', KeyH: 'H', KeyI: 'I',
  KeyJ: 'J', KeyK: 'K', KeyL: 'L', KeyM: 'M', KeyN: 'N', KeyO: 'O', KeyP: 'P', KeyQ: 'Q', KeyR: 'R',
  KeyS: 'S', KeyT: 'T', KeyU: 'U', KeyV: 'V', KeyW: 'W', KeyX: 'X', KeyY: 'Y', KeyZ: 'Z',
  Digit0: '0', Digit1: '1', Digit2: '2', Digit3: '3', Digit4: '4', Digit5: '5', Digit6: '6',
  Digit7: '7', Digit8: '8', Digit9: '9',
  Escape: 'Esc', Tab: 'Tab', Space: 'Space', Enter: 'Return', Backspace: 'Delete',
  ShiftLeft: 'Shift', ShiftRight: 'RightShift', ControlLeft: 'Control', ControlRight: 'RightControl',
  AltLeft: 'Option', AltRight: 'RightOption', MetaLeft: 'Command', MetaRight: 'RightCommand',
  ArrowUp: 'UpArrow', ArrowDown: 'DownArrow', ArrowLeft: 'LeftArrow', ArrowRight: 'RightArrow'
};

const localLast = new Map();
const localDown = new Map();

function localEvent(name, phase) {
  const now = performance.now();
  const threshold = (config.perKey && config.perKey[name] !== undefined)
    ? config.perKey[name]
    : (config.global ? config.global.thresholdMs : 100);

  if (phase === 'down') {
    if (localDown.get(name)) return;
    localDown.set(name, true);
    const last = localLast.get(name);
    const interval = last === undefined ? 0 : Math.round(now - last);
    localLast.set(name, now);
    const chatter = interval > 0 && interval < threshold;
    renderEvent({
      name, phase, intervalMs: interval, heldMs: 0, thresholdMs: threshold,
      verdict: chatter ? 'chatter' : 'normal', blocked: false
    });
  } else {
    localDown.set(name, false);
  }
}

if (!hasBridge()) {
  document.addEventListener('keydown', e => {
    if (e.metaKey || e.ctrlKey) return;
    const name = CODE_TO_NAME[e.code];
    if (!name || e.repeat) return;
    e.preventDefault();
    localEvent(name, 'down');
  });
  document.addEventListener('keyup', e => {
    const name = CODE_TO_NAME[e.code];
    if (!name) return;
    e.preventDefault();
    localEvent(name, 'up');
  });
}

// ---------------------------------------------------------------- sizing
// 面板宽度固定（不是浏览器），24 个键位单位必须挤进「窗口 - 侧栏」里，
// 否则键帽标签会被裁掉。u 由可用宽度反推。
function fitUnit() {
  const stage = document.querySelector('.stage');
  const side = document.querySelector('.side');
  if (!stage || !side) return;
  const available = stage.clientWidth - side.offsetWidth - 12 - 20 - 10;
  const unit = Math.max(32, Math.min(46, Math.floor(available / 22)));
  const root = document.documentElement.style;
  root.setProperty('--u', `${unit}px`);
  root.setProperty('--h', `${Math.round(unit * 1.05)}px`);
  root.setProperty('--fh', `${Math.round(unit * 0.76)}px`);
}

document.getElementById('enginePill').addEventListener('click', () => {
  if (config.trusted === false) post({ type: 'openPermission' });
});

window.addEventListener('resize', fitUnit);

// ---------------------------------------------------------------- boot
applyStaticText();
buildBoard();
fitUnit();
document.querySelectorAll('.key[data-key]').forEach(node => paintKey(node.dataset.key));
document.getElementById('v4').textContent = '0';
post({ type: 'ready' });
