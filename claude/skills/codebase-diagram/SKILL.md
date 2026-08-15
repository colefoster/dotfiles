---
name: codebase-diagram
description: Turn a repository into an explorable isometric blueprint — a single self-contained HTML page where each subsystem is an extruded block sized by its weight, data flows animate along the edges, and a side panel explains what each part does and how it's built. Use when the user wants to see, map, visualise, or diagram a codebase, wants a visual to discuss architecture against, or asks for a "codebase diagram" / "architecture map" / "system blueprint".
---

# Codebase Diagram

Produce **one HTML file**: an isometric technical drawing of a repository that a person can hover, pin, drill into, and pan around while discussing the system.

The value is in the **analysis**, not the renderer. The renderer ships with this skill (`assets/template.html`). Your job is to understand the repo well enough to say, in plain language, what each part does, how it's built, and what flows between the parts — then fill the data blob.

## Procedure

1. **Analyse the repo.** Delegate the sweep to subagents if it's large; you need real numbers, not guesses.
   - Identify **12–30 subsystems** — conceptual units ("combat engine", "shop economy", "asset pipeline"), never individual files. A subsystem may span several files or be one large one.
   - For each: source paths, real LOC (`wc -l`), what it does, how it's built, its execution steps, and its **outgoing data flows** (what actually travels the edge — "unit stats", "combat events", not "calls").
   - Get real domain counts by reading the data files (how many entities, moves, routes, tests, migrations…).
   - Read the README / CLAUDE.md / docs for the system's purpose and for what is currently **broken, unfinished, or not switched on**.
2. **Copy the template** to the output path, then replace the block between `// ==== DATA START ====` and `// ==== DATA END ====` with the real `DATA` object.
3. **Lay out the grid by hand** (see Layout). Do not leave positions to chance.
4. **Verify** in a browser (serve the file — `file:` is often blocked): no console errors, every edge endpoint id exists, every `sections[].nodes` id exists, and the auto-fitted view is neither cramped nor mostly empty paper.
5. Report the file path and how to open it.

## Data schema

```js
const DATA = {
  repo: "repo-name",                    // shown top-left
  title: "The Evolution Harness",       // a real title for the system, not the repo name again
  subtitle: "one line, lowercase, what this is",
  stats: [ {label:"UNITS", value:"50 lines"}, ... ],   // 4–6 headline numbers, real
  what: "<p>…</p>",                     // HTML. 2–4 paragraphs. <mark> for key terms.
  how:  "<p>…</p>",                     // HTML. how to read the diagram + how it's built.
  sections: [ {name:"THE GAME LOOP", nodes:["combat","shop"]} ],   // 4–6 groups, index order
  nodes: [{
    id:"combat", key:"C",               // key = single char, keyboard-selectable, drawn on the block
    name:"Combat Engine", count:14,     // count = files / entities in it (shown in index)
    gx:6, gy:2, w:3, d:3, mag:0.9,      // grid pos, footprint, height 0.15–1.0 (relative weight)
    what:"One sentence, plain language. No jargon, no file names.",
    how:"One or two sentences: data structures, patterns, libraries.",
    condition:["what's broken or unfinished here"],   // omit or [] if healthy
    steps:[{name:"resolve targets", what:"…", how:"…", mag:.4, flow:"target list"}]   // optional, 3–8, execution order
  }],
  edges: [ {from:"shop", to:"combat", flow:"purchased units"} ]
}
```

## Two views

The page ships both, on a toggle:

- **Compact** — your authored grid, de-occluded. A dense skyline; good for "how big is what".
- **Expanded** — computed, not authored. Nodes are ranked by longest path through the edge graph, so the lane axis becomes *how far the data has travelled*; each section becomes a labelled swimlane stacked down the depth axis. Towers shrink so the flow stays legible.

Expanded mode is only as good as your `edges` and `sections`: **the rank axis is derived entirely from edge direction**, so an edge pointing the wrong way puts a subsystem in the wrong column. Cycles are handled (back edges are dropped for ranking), but get the direction of the main pipeline right.

## Layout

Grid coordinates are isometric: `+gx` goes down-right, `+gy` goes down-left. Both grow downward on screen, so `gx+gy` is depth order.

- Think in **lanes** (`gx - gy`, horizontal) and **depth** (`gx + gy`, vertical). Give each section its own band of lanes; order nodes along depth so flow runs top to bottom.
- The renderer runs a de-occlusion pass at boot: it keeps your lanes exactly and pushes depth apart until no block's silhouette can hide another. So **space the lanes deliberately and let depth sort itself out** — a tall block needs roughly `height/17` extra depth units of clearance, which the pass adds for you.
- Aim for a scene roughly as wide as it is tall; the view auto-fits, so an over-wide layout just zooms everything out. Around 6 lanes of clusters for ~25 nodes works.
- **`mag` carries meaning**: make it proportional to weight (LOC, or importance). The tall structures should be the ones that genuinely dominate the codebase — a reader should be able to read the skyline.
- **`w`/`d` footprint** encodes breadth: a subsystem of many small files is wide and flat; one dense algorithm is small and tall.
- Route the eye: put upstream producers at low `gx+gy`, downstream consumers at high.

## Writing rules

The panel prose is the product. Hold it to this bar:

- **Plain language, no file names, no class names** in `what`. A non-author should understand the sentence. Save the machinery for `how`.
- **Name the real difficulty.** Every codebase has 2–3 problems that turned out harder than they looked. Say what they were in `what` at the top level — that paragraph is what makes the page worth reading.
- `<mark>` 3–6 load-bearing phrases across the top-level prose. Not more.
- **Flow labels are nouns** — the thing that travels ("board state", "damage rolls"), never verbs ("calls", "uses").
- **`condition` is honest.** Broken, half-migrated, dead, or not-switched-on parts get said out loud. A diagram that hides the rot is decoration.
- All-caps is for labels only; prose is sentence case.

## House style (do not restyle)

Tan paper, black hairlines, hatched extrusions, monospace, no colour. It reads as a technical drawing on purpose. Keep it. The only things you change in the template are the `DATA` block and, if asked, the page `<title>`.
