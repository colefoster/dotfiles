#!/usr/bin/env python3
"""Regenerate mullion/preview.html from the real style and layout files.

The page is a chooser: pick a style, pick a layout, see the combination and the
command that applies it. Everything it draws comes from styles/*.sh and
layouts/*.sh, so the preview cannot drift from what the daemons read.

    python3 build-preview.py
"""

import json
import pathlib
import re

HERE = pathlib.Path(__file__).parent
STYLE_ORDER = ["console", "dock", "instrument", "system",
               "deck", "ubuntu", "nord", "gruvbox", "dense", "daylight"]
LAYOUT_ORDER = ["console", "dock", "instrument", "system",
                "classic", "islands", "readout", "ambient", "bottom"]


def blurb_of(text):
    return " ".join(l.lstrip("#").strip() for l in text.splitlines()
                    if l.startswith("#") and not l.startswith("#!")).strip()


def argb_to_css(v):
    """0xAARRGGBB -> #RRGGBBAA"""
    v = v[2:]
    return "#" + v[2:] + v[:2]


def read_styles():
    out = {}
    for name in STYLE_ORDER:
        txt = (HERE / "styles" / f"{name}.sh").read_text()
        pairs = dict(re.findall(r"\b([A-Z_]+)=([0-9a-zA-Z.$_]+)", txt))
        out[name] = {
            "label": re.search(r'NAME="([^"]+)"', txt).group(1),
            "blurb": blurb_of(txt),
            "c": {k: argb_to_css(v) for k, v in pairs.items() if v.startswith("0x")},
            "g": {k: v for k, v in pairs.items() if not v.startswith("0x")},
        }
    return out


def read_layouts():
    out = {}
    for name in LAYOUT_ORDER:
        txt = (HERE / "layouts" / f"{name}.sh").read_text()
        # strip trailing "# comment" — the shell ignores it, the parser must too
        v = {k: val.split("#")[0].strip().strip('"')
             for k, val in re.findall(r'^([A-Z_]+)=(.*)$', txt, re.M)}
        out[name] = {
            "label": v.get("LAYOUT_NAME", name),
            "blurb": blurb_of(txt),
            "v": v,
        }
    return out


PAGE = """<meta charset="utf-8">
<title>Mullion</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Archivo:wght@600;700&family=IBM+Plex+Mono:wght@400;500;600&family=IBM+Plex+Sans:wght@400;500;600&display=swap">
<style>
:root{
  --page:#EDF0F4; --card:#FFFFFF; --sunk:#E4E9EF; --line:#D3DBE4; --line2:#C0CAD6;
  --ink:#141C25; --ink2:#33404E; --dim:#5F6D7E; --faint:#8B98A7; --accent:#0E6A79;
}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){
  --page:#0B1016; --card:#141C25; --sunk:#0E151D; --line:#26313F; --line2:#33404E;
  --ink:#E7ECF2; --ink2:#C3CCD7; --dim:#8795A6; --faint:#65727F; --accent:#4FB3C4;}}
:root[data-theme="dark"]{
  --page:#0B1016; --card:#141C25; --sunk:#0E151D; --line:#26313F; --line2:#33404E;
  --ink:#E7ECF2; --ink2:#C3CCD7; --dim:#8795A6; --faint:#65727F; --accent:#4FB3C4;}
*{box-sizing:border-box}
body{margin:0;background:var(--page);color:var(--ink);
  font-family:"IBM Plex Sans",-apple-system,BlinkMacSystemFont,sans-serif;
  font-size:14px;line-height:1.5;-webkit-font-smoothing:antialiased}
h1,h2,h3{font-family:Archivo,sans-serif;margin:0;letter-spacing:-.02em;text-wrap:balance}
button{font:inherit;color:inherit;background:none;border:none;cursor:pointer}
button:focus-visible{outline:2px solid var(--accent);outline-offset:2px}
.mono{font-family:"IBM Plex Mono",ui-monospace,Menlo,monospace}

.wrap{max-width:1180px;margin:0 auto;padding:22px 20px 48px;display:flex;flex-direction:column;gap:18px}
header{border-bottom:1px solid var(--line);padding-bottom:14px;display:flex;
  align-items:flex-end;justify-content:space-between;gap:20px;flex-wrap:wrap}
header h1{font-size:26px}
header .sub{font-family:"IBM Plex Mono",monospace;font-size:12px;text-transform:uppercase;
  letter-spacing:.06em;color:var(--dim);margin-left:10px}
header p{margin:0;color:var(--dim);font-size:12.5px;max-width:52ch}

.main{display:grid;grid-template-columns:230px minmax(0,1fr);gap:16px;align-items:start}
@media (max-width:860px){.main{grid-template-columns:1fr}}

.rail{display:flex;flex-direction:column;gap:14px;position:sticky;top:14px}
@media (max-width:860px){.rail{position:static}}
.group{background:var(--card);border:1px solid var(--line);border-radius:7px;overflow:hidden}
.group > h3{font-size:10.5px;text-transform:uppercase;letter-spacing:.11em;color:var(--faint);
  font-family:"IBM Plex Mono",monospace;font-weight:500;padding:9px 12px;
  border-bottom:1px solid var(--line);display:flex;justify-content:space-between;gap:8px}
.opt{display:flex;align-items:center;gap:9px;width:100%;padding:7px 12px;text-align:left;
  border-left:2px solid transparent;transition:background .12s}
.opt:hover{background:var(--sunk)}
.opt.on{border-left-color:var(--accent);background:var(--sunk)}
.opt .sw{width:16px;height:16px;border-radius:4px;flex:none;border:1px solid rgba(128,128,128,.4);
  display:grid;place-items:center}
.opt .sw i{width:6px;height:6px;border-radius:2px;display:block}
.opt .nm{font-size:13px}
.opt.on .nm{font-weight:600}
.opt .meta{margin-left:auto;font-family:"IBM Plex Mono",monospace;font-size:10px;color:var(--faint)}

.stage{display:flex;flex-direction:column;gap:12px;min-width:0}
.shot{background:var(--card);border:1px solid var(--line);border-radius:7px;padding:16px;
  background-image:repeating-conic-gradient(rgba(128,128,128,.05) 0% 25%,transparent 0% 50%);
  background-size:16px 16px}
.screen{aspect-ratio:16/10;position:relative;overflow:hidden;border-radius:5px;
  border:1px solid rgba(0,0,0,.4);transition:background .2s}
.barwrap{position:absolute;z-index:3;transition:all .2s}
.bar{display:flex;align-items:center;gap:5px;width:100%;position:relative;
  font-family:"IBM Plex Mono",monospace;transition:all .2s}
.bar .right{margin-left:auto;display:flex;align-items:center}
.pip{display:inline-flex;align-items:center;justify-content:center;font-weight:600;
  white-space:nowrap;transition:all .15s}
.tiles{position:absolute;left:0;right:0;display:grid;grid-template-columns:1.6fr 1fr;
  grid-template-rows:1fr 1fr;transition:all .2s}
.win{overflow:hidden;display:flex;flex-direction:column;transition:padding .2s}
.win:first-child{grid-row:span 2}
.winner{flex:1;display:flex;flex-direction:column;overflow:hidden;transition:all .2s}
.wbar{display:flex;align-items:center;gap:4px;padding:0 6px;flex:none;
  font-family:"IBM Plex Mono",monospace;font-size:8.5px}
.wdot{width:5px;height:5px;border-radius:50%}
.wbody{flex:1;padding:7px;display:flex;flex-direction:column;gap:3px}
.ln{height:2.5px;border-radius:2px}

.readout{background:var(--card);border:1px solid var(--line);border-radius:7px;
  padding:12px 14px;display:flex;flex-direction:column;gap:10px}
.readout .titles{display:flex;align-items:baseline;gap:9px;flex-wrap:wrap}
.readout h2{font-size:17px}
.readout .x{color:var(--faint);font-size:15px}
.readout p{margin:0;color:var(--dim);font-size:12.4px}
.cmd{display:flex;align-items:center;gap:9px;background:var(--sunk);border:1px solid var(--line);
  border-radius:5px;padding:7px 10px}
.cmd code{font-family:"IBM Plex Mono",monospace;font-size:12px;color:var(--accent);flex:1;
  overflow-x:auto;white-space:nowrap}
.cmd button{font-family:"IBM Plex Mono",monospace;font-size:11px;color:var(--dim);
  border:1px solid var(--line2);border-radius:4px;padding:2px 8px;flex:none}
.cmd button:hover{color:var(--accent);border-color:var(--accent)}
.facts{display:flex;flex-wrap:wrap;gap:5px}
.f{display:flex;align-items:center;gap:5px;border:1px solid var(--line);border-radius:5px;
  padding:2px 7px;font-family:"IBM Plex Mono",monospace;font-size:10.5px;color:var(--dim)}
.f b{color:var(--ink2);font-weight:600}
.f i{width:11px;height:11px;border-radius:3px;display:block;border:1px solid rgba(128,128,128,.35)}
.hint{color:var(--faint);font-size:11.5px;font-family:"IBM Plex Mono",monospace}
footer{color:var(--faint);font-size:12px;border-top:1px solid var(--line);padding-top:12px}
footer code{font-family:"IBM Plex Mono",monospace;color:var(--accent)}
@media (prefers-reduced-motion:reduce){*{transition:none !important}}
</style>

<div class="wrap">
  <header>
    <div><h1>Mullion<span class="sub">appearance only</span></h1></div>
    <p>Two independent axes: a <b>style</b> is colour and geometry, a <b>layout</b> is the bar's
       shape and contents. Pick one of each. Four of them were designed as pairs — those are the Looks. Every number is read from
       <span class="mono">~/dotfiles/mullion/</span>, and none of it touches a keybinding.</p>
  </header>

  <div class="main">
    <div class="rail">
      <div class="group">
        <h3>Look <span>designed pairs</span></h3>
        <div id="lookList"></div>
      </div>
      <div class="group">
        <h3>Style <span>colour · geometry</span></h3>
        <div id="styleList"></div>
      </div>
      <div class="group">
        <h3>Layout <span>bar</span></h3>
        <div id="layoutList"></div>
      </div>
      <div class="hint">↑ ↓ to change style · ← → for layout</div>
    </div>

    <div class="stage">
      <div class="shot"><div class="screen" id="screen"></div></div>
      <div class="readout">
        <div class="titles">
          <h2 id="sName"></h2><span class="x">×</span><h2 id="lName"></h2>
        </div>
        <p id="sBlurb"></p>
        <p id="lBlurb"></p>
        <div class="cmd">
          <code id="cmd"></code>
          <button id="copy">copy</button>
        </div>
        <div class="facts" id="facts"></div>
      </div>
    </div>
  </div>

  <footer>Each command rewrites one word under <code>mullion/</code>, pushes the gap numbers into the
    marked block in <code>aerospace.toml</code>, then reloads SketchyBar, JankyBorders and the AeroSpace
    config in place. AeroSpace is never restarted, so windows keep their places — the gaps re-flow
    around them. A bottom bar moves the reserved strip to the foot of the screen and hands the notch
    back to macOS. In the workspace pips, <b>gh / zd / sf</b> stand in for app glyphs; the real bar
    draws Nerd Font app icons there, which this page can't load.</footer>
</div>

<script>
"use strict";
const STYLES = __STYLES__;
const LAYOUTS = __LAYOUTS__;
// The four that were designed as pairs; the rest mix freely.
const LOOKS = ["console", "dock", "instrument", "system"];
const SCALE = 0.78;

const ITEMS = {
  cpu:     {v:"18%",   col:"CYAN"},
  battery: {v:"100%",  col:"GOOD"},
  clock:   {v:"20:45", col:"CYAN"},
  net:     {v:"ts",    col:"GOOD"},
  claude:  {v:"2",     col:"CYAN"},
  rec:     {v:"cam",   col:"BAD"}
};
// Two-letter stand-ins for the Nerd Font app glyphs the real bar draws.
const WS_APPS = {1:["gh","zd"], 2:["sf","sl"], 3:["ob"], 4:[]};

let sKey = "console", lKey = "console";
try {
  const a = localStorage.getItem("mullion-style"); if (STYLES[a]) sKey = a;
  const b = localStorage.getItem("mullion-layout"); if (LAYOUTS[b]) lKey = b;
} catch (e) {}

const px = v => +(parseFloat(v) * SCALE).toFixed(2);
const el = (t, cls) => { const n = document.createElement(t); if (cls) n.className = cls; return n; };

function pipHTML(c, g, n, active, v) {
  const r = px(g.ITEM_RADIUS), h = px(g.ITEM_HEIGHT), fs = px(g.FONT_SIZE) + 2;
  const apps = WS_APPS[n] || [];
  const chrome = g.CHROME || "chips";
  const form = v.PIP_FORM || v.PIP_MODE;

  // A status line writes [1:gh zd]; a bar of buttons draws a chip.
  if (form === "bracket") {
    const inner = apps.length ? `${n}:${apps.join(" ")}` : `${n}`;
    const col = active ? c.AMBER : (apps.length ? c.INK : c.FAINT);
    return `<span class="pip" style="height:${h}px;font-size:${fs}px;padding:0 3px;color:${col}">[${inner}]</span>`;
  }

  const glyphs = (form === "icons" && apps.length)
    ? `<span style="font-size:${fs - 1.5}px;opacity:.95;margin-left:4px">${apps.join(" ")}</span>` : "";
  const pad = px(8) + (glyphs ? 6 : 0);
  let style = `height:${h}px;border-radius:${r}px;font-size:${fs}px;padding:0 ${pad}px;`;
  if (chrome === "outline")
    style += `background:${c.PANEL};border:${g.ITEM_OUTLINE || 1}px solid ${c.LINE};`;
  if (!active) {
    style += `color:${apps.length ? c.INK : c.FAINT}`;
    return `<span class="pip" style="${style}">${n}${glyphs}</span>`;
  }
  if (g.PIP_STYLE === "underline")
    style += `color:${c.AMBER};box-shadow:inset 0 -2px 0 ${c.AMBER}`;
  else if (g.PIP_STYLE === "dot")
    style += `color:${c.AMBER}`;
  else
    style += `color:${c.AMBER};` + (chrome === "outline" ? "" : `background:${g.ITEM_BG === "on" ? c.PANEL : "transparent"}`);
  return `<span class="pip" style="${style}">${n}${glyphs}</span>`;
}

// A sparkline drawn from block characters, so it needs no font we can't load.
function sparkHTML(c) {
  const bars = [2, 3, 1, 4, 6, 5, 3, 2, 4, 7, 5, 3];
  const ch = "▁▂▃▄▅▆▇";
  return `<span style="color:${c.AMBER};letter-spacing:-1px">` +
    bars.map(b => ch[b]).join("") + `</span>`;
}

function winHTML(c, g, name, focused, lines) {
  const bw = px(g.BORDER_WIDTH);
  const ring = focused ? c.AMBER : (g.BORDER_INACTIVE === "on" ? c.LINE : "transparent");
  const rad = g.BORDER_STYLE === "round" ? 4 : 0;
  const body = [92, 68, 84, 55, 78, 61, 88].slice(0, lines)
    .map(w => `<div class="ln" style="width:${w}%;background:${c.LINE}"></div>`).join("");
  return `<div class="win" style="padding:${px(g.GAP_INNER) / 2}px">
    <div class="winner" style="background:${c.PANEL};border:${bw}px solid ${ring};border-radius:${rad}px">
      <div class="wbar" style="background:${c.DECK};color:${focused ? c.INK : c.FAINT};height:${px(18)}px">
        <span class="wdot" style="background:${focused ? c.AMBER : c.CYAN}"></span>${name}</div>
      <div class="wbody">${body}</div></div></div>`;
}

function render() {
  const S = STYLES[sKey], L = LAYOUTS[lKey];
  const c = S.c, g = S.g, v = L.v;
  const islands = v.BAR_ISLANDS === "on";
  const clear = v.BAR_TRANSPARENT === "on";
  const top = v.BAR_POSITION === "top";

  // Islands need breathing room and rounder chips than a flush slab does.
  const gm = Object.assign({}, g);
  if (islands) { gm.BAR_MARGIN = "8"; gm.BAR_RADIUS = "0"; gm.ITEM_RADIUS = "8"; }

  const bh = px(gm.BAR_HEIGHT), bm = px(gm.BAR_MARGIN), br = px(gm.BAR_RADIUS);
  const bp = px(gm.BAR_PADDING), byo = px(gm.BAR_YOFF), fs = px(gm.FONT_SIZE);
  const isleCSS = islands
    ? `background:${c.DECK};border-radius:${px(gm.ITEM_RADIUS)}px;padding:2px 4px;display:flex;align-items:center;gap:4px;`
    : "display:flex;align-items:center;gap:4px;";

  const chrome = g.CHROME || "chips";
  const sep = (g.SEP_STYLE === "pipe")
    ? `<span style="color:${c.LINE};padding:0 3px">│</span>` : "";

  const hide = v.HIDE_EMPTY === "on";
  let pips = "";
  for (const n of [1, 2, 3, 4]) {
    if (hide && !(WS_APPS[n] || []).length && n !== 1) continue;
    pips += pipHTML(c, gm, n, n === 1, v);
  }
  const pipGroup = `<span style="${isleCSS}">${pips}</span>`;

  const fieldHTML = k => {
    const it = ITEMS[k]; if (!it) return "";
    const inner = (k === "cpu" && v.CPU_FORM === "graph")
      ? sparkHTML(c)
      : `<span style="width:5px;height:5px;border-radius:50%;background:${c[it.col]};display:block"></span>
         <span style="color:${c.DIM}">${it.v}</span>`;
    const box = chrome === "outline"
      ? `background:${c.PANEL};border:${g.ITEM_OUTLINE || 1}px solid ${c.LINE};height:${px(gm.ITEM_HEIGHT)}px;`
      : "";
    return `<span style="display:flex;align-items:center;gap:4px;padding:0 5px;${box}">${inner}</span>`;
  };
  const joinFields = ks => ks.map(fieldHTML).filter(Boolean).join(sep);

  const frontApp = () => {
    const box = chrome === "outline"
      ? `background:${c.PANEL};border:${g.ITEM_OUTLINE || 1}px solid ${c.LINE};height:${px(gm.ITEM_HEIGHT)}px;display:flex;align-items:center;` : "";
    return `<span style="color:${c.AMBER};font-weight:600;padding:0 7px;${box}">Ghostty</span>`;
  };

  let left = "";
  if (v.ITEMS_LEFT.includes("spaces")) left += pipGroup;
  if (v.ITEMS_LEFT.includes("front_app"))
    left += (left ? sep : "") + (islands ? `<span style="${isleCSS}">${frontApp()}</span>` : frontApp());

  const centreItems = (v.ITEMS_CENTER || "").trim();
  const centre = centreItems.includes("spaces")
    ? `<span style="${isleCSS}">${pips}</span>` : "";

  const right = joinFields(v.ITEMS_RIGHT.split(/\\s+/).filter(Boolean));
  const rightWrap = islands ? `<span style="${isleCSS}">${right}</span>`
                            : `<span style="display:flex;align-items:center">${right}</span>`;

  const edge = (bm || islands) ? "box-shadow:0 2px 12px rgba(0,0,0,.35);"
             : (clear ? "" : `border-bottom:1px solid ${c.LINE};`);
  const barHTML = `<div class="bar" style="height:${bh}px;
      background:${clear ? "transparent" : c.DECK};border-radius:${br}px;
      padding:0 ${bp}px;font-size:${fs}px;color:${c.DIM};${edge}">
      ${left}
      ${centre ? `<span style="position:absolute;left:50%;transform:translateX(-50%)">${centre}</span>` : ""}
      <span class="right">${rightWrap}</span></div>`;

  // A layout can hand the top strip back to macOS instead of covering it.
  const nativeBar = v.KEEP_NATIVE_MENUBAR === "on"
    ? `<div style="position:absolute;top:0;left:0;right:0;height:${px(22)}px;z-index:2;
         background:rgba(240,240,242,.92);border-bottom:1px solid rgba(0,0,0,.12);
         display:flex;align-items:center;gap:9px;padding:0 8px;
         font-family:'IBM Plex Sans',sans-serif;font-size:${px(11)}px;color:#2b2b2e">
         <b style="font-weight:700"></b><span>Ghostty</span><span style="opacity:.6">File</span>
         <span style="margin-left:auto;opacity:.75">100%  20:52</span></div>`
    : "";

  const strip = bh + bm + byo;
  const outer = px(g.GAP_OUTER);
  const pad = Math.max(outer - px(g.GAP_INNER) / 2, 0);
  const barPos = top ? `top:${bm + byo}px;left:${bm}px;right:${bm}px`
                     : `bottom:${bm + byo}px;left:${bm}px;right:${bm}px`;
  const nativeH = v.KEEP_NATIVE_MENUBAR === "on" ? px(22) : 0;
  const tilesPos = top ? `top:${Math.max(strip, nativeH)}px;bottom:0`
                       : `top:${nativeH}px;bottom:${strip}px`;

  document.getElementById("screen").style.background = c.DECK;
  document.getElementById("screen").innerHTML =
    nativeBar +
    `<div class="barwrap" style="${barPos}">${barHTML}</div>
     <div class="tiles" style="${tilesPos};padding:${pad}px">
       ${winHTML(c, g, "Ghostty", true, 7)}${winHTML(c, g, "Zed", false, 4)}${winHTML(c, g, "Safari", false, 4)}
     </div>`;

  document.getElementById("sName").textContent = S.label;
  document.getElementById("lName").textContent = L.label;
  document.getElementById("sBlurb").textContent = S.blurb;
  document.getElementById("lBlurb").textContent = L.blurb;
  document.getElementById("cmd").textContent = (sKey === lKey && LOOKS.includes(sKey))
    ? `mull look ${sKey}`
    : `mull theme ${sKey} && mull layout ${lKey}`;

  const shape = islands ? "islands" : (clear ? "transparent" : "slab");
  document.getElementById("facts").innerHTML = [
    `<span class="f"><b>gaps</b> ${g.GAP_INNER}px</span>`,
    `<span class="f"><b>ring</b> ${g.BORDER_WIDTH}px ${g.BORDER_STYLE}${g.BORDER_INACTIVE === "on" ? "" : ", focused only"}</span>`,
    `<span class="f"><b>bar</b> ${g.BAR_HEIGHT}px ${v.BAR_POSITION}, ${shape}</span>`,
    `<span class="f"><b>chrome</b> ${g.CHROME || "chips"}</span>`,
    `<span class="f"><b>pips</b> ${v.PIP_FORM || v.PIP_MODE} · ${g.PIP_STYLE}</span>`,
    v.CPU_FORM === "graph" ? `<span class="f"><b>load</b> sparkline</span>` : "",
    v.KEEP_NATIVE_MENUBAR === "on" ? `<span class="f"><b>menu bar</b> native kept</span>` : "",
    `<span class="f"><b>empty</b> ${v.HIDE_EMPTY === "on" ? "hidden" : "shown"}</span>`,
    `<span class="f"><b>accordion</b> ${g.ACCORDION_PADDING}px</span>`,
    `<span class="f"><i style="background:${c.AMBER}"></i>focus</span>`,
    `<span class="f"><i style="background:${c.DECK}"></i>ground</span>`
  ].join("");

  document.querySelectorAll("[data-style]").forEach(b =>
    b.classList.toggle("on", b.dataset.style === sKey));
  document.querySelectorAll("[data-layout]").forEach(b =>
    b.classList.toggle("on", b.dataset.layout === lKey));
  document.querySelectorAll("[data-look]").forEach(b =>
    b.classList.toggle("on", b.dataset.look === sKey && b.dataset.look === lKey));

  try {
    localStorage.setItem("mullion-style", sKey);
    localStorage.setItem("mullion-layout", lKey);
  } catch (e) {}
}

function buildRail() {
  const kl = document.getElementById("lookList");
  LOOKS.forEach(k => {
    const s = STYLES[k], b = el("button", "opt");
    b.dataset.look = k;
    b.innerHTML = `<span class="sw" style="background:${s.c.DECK}"><i style="background:${s.c.AMBER}"></i></span>
      <span class="nm">${s.label}</span><span class="meta">${s.g.CHROME || "chips"}</span>`;
    b.addEventListener("click", () => { sKey = k; lKey = k; render(); });
    kl.appendChild(b);
  });
  const sl = document.getElementById("styleList");
  Object.entries(STYLES).forEach(([k, s]) => {
    const b = el("button", "opt"); b.dataset.style = k;
    b.innerHTML = `<span class="sw" style="background:${s.c.DECK}"><i style="background:${s.c.AMBER}"></i></span>
      <span class="nm">${s.label}</span><span class="meta">${s.g.GAP_INNER}px</span>`;
    b.addEventListener("click", () => { sKey = k; render(); });
    sl.appendChild(b);
  });
  const ll = document.getElementById("layoutList");
  Object.entries(LAYOUTS).forEach(([k, l]) => {
    const b = el("button", "opt"); b.dataset.layout = k;
    const shape = l.v.BAR_ISLANDS === "on" ? "islands"
                : (l.v.BAR_TRANSPARENT === "on" ? "clear" : "slab");
    b.innerHTML = `<span class="sw" style="background:var(--sunk)"><i style="background:var(--accent)"></i></span>
      <span class="nm">${l.label}</span><span class="meta">${l.v.BAR_POSITION} · ${shape}</span>`;
    b.addEventListener("click", () => { lKey = k; render(); });
    ll.appendChild(b);
  });
}

const cycle = (obj, cur, d) => {
  const ks = Object.keys(obj);
  return ks[(ks.indexOf(cur) + d + ks.length) % ks.length];
};
document.addEventListener("keydown", e => {
  if (e.metaKey || e.ctrlKey || e.altKey) return;
  const k = e.key;
  if (k === "ArrowDown") sKey = cycle(STYLES, sKey, 1);
  else if (k === "ArrowUp") sKey = cycle(STYLES, sKey, -1);
  else if (k === "ArrowRight") lKey = cycle(LAYOUTS, lKey, 1);
  else if (k === "ArrowLeft") lKey = cycle(LAYOUTS, lKey, -1);
  else return;
  e.preventDefault(); render();
});

document.getElementById("copy").addEventListener("click", () => {
  const btn = document.getElementById("copy");
  navigator.clipboard.writeText(document.getElementById("cmd").textContent).then(
    () => { btn.textContent = "copied"; setTimeout(() => btn.textContent = "copy", 1200); },
    () => { btn.textContent = "failed"; setTimeout(() => btn.textContent = "copy", 1200); });
});

buildRail();
render();
</script>
"""


def main():
    html = (PAGE
            .replace("__STYLES__", json.dumps(read_styles(), indent=1))
            .replace("__LAYOUTS__", json.dumps(read_layouts(), indent=1)))
    out = HERE / "preview.html"
    out.write_text(html)
    print("wrote %s (%d styles, %d layouts, %d bytes)"
          % (out, len(STYLE_ORDER), len(LAYOUT_ORDER), len(html)))


if __name__ == "__main__":
    main()
