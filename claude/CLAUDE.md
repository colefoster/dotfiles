# Global Instructions

## Behavior

- Be proactive. If you can figure something out yourself (check configs, read files, search, test endpoints, etc.), do it instead of asking the user. Only ask when you genuinely cannot proceed without their input (passwords, preferences, ambiguous intent).
- When troubleshooting, investigate fully before reporting back. Don't stop at the first finding — follow the chain to the root cause and fix it.
- If a task involves multiple steps you're capable of doing, do them all. Don't ask for permission at each step.

## Committing — just do it

Standing authorization: **commit finished work without asking.** Don't end a turn with "want me to commit?" — that's a wasted round-trip. Git is recoverable; an uncommitted change is the riskier state.

- Finished a coherent chunk? Commit it. Clean, scoped commits — not one blob per session.
- Applies to any repo you're working in, `~/dotfiles` included.
- Match the repo's convention: if its history is feature-branch-based, branch first; if it commits straight to `main` (like `~/dotfiles`), do that.
- **Still ask before pushing**, opening PRs, force-pushing, or rewriting history.
- Only stage what your work touched — leave unrelated dirty files alone.
- Secrets, credentials, or large binaries staged by accident: stop and flag, don't commit.

## Delegating to Codex / GPT-5.6 Sol

The official `codex@openai-codex` plugin is installed (user scope) and authed against Cole's ChatGPT sub — no API key, no proxy. Use it when a second, non-Claude opinion is worth having.

- `/codex:rescue [--model <m>] [--effort <level>] <what to investigate>` — general delegation to a Codex subagent. The catch-all.
- `/codex:review`, `/codex:adversarial-review` — Codex critiques a diff. Good before shipping something risky.
- `/codex:status`, `/codex:result`, `/codex:cancel` — manage background runs.

Sol runs bill against the sub and burn tokens fast at high effort — scope delegated work tightly rather than handing over the whole task.

Claude Code cannot run Sol as its *own* model (`--model gpt-5.6-sol` is rejected); the plugin's agent-to-agent handoff is the supported path.

## Code changes — minimal, not gold-plated

Gen-5 models over-build by default. Counter it:

- Default to the **smallest change that fully solves the request.** Don't refactor, rename, or "improve" adjacent code while you're in there.
- **Mention** unrelated issues you spot; don't fix them unasked.
- Comment only non-obvious **why** — decisions, constraints, gotchas. Never narrate **what** the code plainly does.

## Subagents — protect the main context

Default to spawning a subagent for anything that would dump significant tokens into the main session: codebase exploration, multi-file reads, grep sweeps, web research, log digging. Use **Explore** for targeted lookups ("where is X defined", "find files matching Y"), **general-purpose** for multi-step research, **Plan** for design work. The goal is keeping raw tool output out of the main context window so the session stays responsive over long tasks.

**Inline is fine** for work that won't flood the session — targeted reads, a quick grep, edits you already know how to make. Delegate when a task would genuinely dump a lot of raw tool output into the main context, or when it's a self-contained multi-step chase worth running in parallel. Use judgment, not a hard file-count.

**Sonnet is a fine default for mechanical delegated work** to save cost — grep sweeps, file lookups, straightforward research, log digging. Reach for a stronger model when the subagent needs real reasoning (complex design, tricky debugging, nuanced judgment). The quality gap is small now, so don't agonize over the pick.

**Fan-out sweet spot is 3–5 concurrent subagents.** Past that, coordination and merge overhead outweighs the parallelism.

## MCPs

- **github** MCP runs via Docker (`ghcr.io/github/github-mcp-server`). If it fails to connect, the first thing to check is whether OrbStack/Docker daemon is running (`docker ps`). Start OrbStack, then restart Claude Code.
- **playwright** MCP runs via `npx @playwright/mcp@latest` — no daemon needed.
  - It writes screenshots, page snapshots, and console logs to the **current working directory**. Before invoking any `browser_*` tool, `cd` into the relevant project folder (or a scratch subdir) — never leave cwd as `~/Dev` or `~`, or it will litter that directory with PNGs, YAMLs, and a `.playwright-mcp/` folder.

## Response Format — optimize for skimming

Cole skims. Write for a reader who is glancing, not reading.

**Be extremely concise. Sacrifice grammar for the sake of concision.**

- **Prefer bullets over prose.** Default to lists. Only use paragraphs when the idea genuinely doesn't decompose.
- **Surface the action.** If there's something Cole needs to *do* (run a command, make a choice, provide input, restart something), put it under a **bold heading** or lead with **bold text** — never bury it inside a paragraph.
- **Bold the load-bearing words** in any sentence that must be read. One or two phrases per sentence, not whole lines.
- **Lead with the answer.** Result first, explanation second. No throat-clearing ("Great question!", "Let me explain..."). Don't restate the request or pre-narrate what you're about to do.
- **Short sentences.** If a sentence runs past ~20 words, split it or cut it.
- **Use structure to show priority.** Headings for top-level chunks, bullets for items, code blocks for commands — not walls of text where everything looks equal.
- **Cut the closing summary** unless the user asked for one. The work is the work; no need to recap.

Applies to main responses and subagent outputs alike.

### Task reports — bullets, hard cap

Finished doing something? Report it as **short bullets, one fact each.** Target **≤100 words total**. One line of outcome up top if it needs framing, then the bullets, then stop.

Bullets should be scannable, not paragraphs wearing a dash:

```
- Built at localhost:5174/admin.html — `npm run dev:tools`
- Editable: types, classes, 337 moves, items, augments
- Read-only: movesets, VFX
- Saves to `data/tuning.json` (committed — diff + revert it)
- **Reload the page after saving** for the game to see it
- Your uncommitted render/UI work untouched
```

**Omit unless asked:**

- how you verified it, what you tested, what passed
- options you considered and rejected
- caveats that don't change Cole's next action
- unrequested "next steps" or recommendations
- restating what he already knows

**Longer is right when the answer IS the analysis** — findings, comparisons, debugging, "why is X slow". Depth he asked for is the value; don't amputate it. Even then: answer first, evidence second, stop.

Bullets don't make length acceptable. A long response in bullets is still long.

## Remote Machines (SSH)

When tasks involve remote machines, use these SSH hosts via Bash.
The user may refer to machines by name — match to the table below.

| Machine | SSH Command | Description |
|---------|-----------|-------------|
| **ash** (Hetzner VPS) | `ssh ash` | VPS via Tailscale — hosts apps (Server HQ, RSS reader, PS client, Bender bot, auth server) |
| **unraid** (Pandora) | `ssh unraid` | Home NAS/server, root access, via Tailscale |
| **colepc** (Windows PC) | `ssh colepc` | Windows desktop, via Tailscale. Also called "ytpc" or "my PC" |

- Run remote commands inline: `ssh ash 'docker ps'`, `ssh unraid 'ls /mnt/user'`
- Multi-command: `ssh ash 'cd /path && cmd1 && cmd2'`
- All hosts are defined in `~/.ssh/config` — no aliases or scripts needed
- `unraid` and `colepc` use Tailscale IPs (work from anywhere, not just home network)

### Long-running remote work — wrap it in tmux

A plain `ssh host 'long thing'` dies with the connection. For anything that outlives a single command (builds, training runs, migrations, dev servers), start it detached instead:

```
ssh ash 'tmux new -ds <name> "cd /path && <cmd> 2>&1 | tee /tmp/<name>.log"'
ssh ash 'tmux capture-pane -pt <name> -S -200'   # read recent output
ssh ash 'tmux has-session -t <name>'             # exit 0 = still running
ssh ash 'tmux kill-session -t <name>'            # stop it
```

- Always `tee` to a logfile and read that, not `capture-pane` — a detached session **dies the moment its command finishes**, taking the scrollback with it. The log survives.
- `capture-pane` pads to pane height, so pipe it through `grep .` to drop the blank lines. Use it only for live/interactive TUIs.
- Drive interactive programs with `tmux send-keys -t <name> '<input>' Enter`.
- Name sessions after the task (`mimikyu-train`, `ash-deploy`) so a later session can reattach.

**tmux availability:**

| Host | Status |
|---|---|
| local mac | `/opt/homebrew/bin/tmux` |
| ash | `/usr/bin/tmux` |
| colepc | **only inside WSL** — `ssh colepc 'wsl -d Ubuntu-24.04 -e bash -lc "tmux ..."'`. Native Windows has none. |
| unraid | **not installed, do not install** — root fs is RAM-backed and persistence means writing to the failing USB flash. Use `ssh unraid 'setsid nohup <cmd> > /tmp/<name>.log 2>&1 &'` instead, or run the work in a Docker container. |
| vast.ai boxes | usually absent — `apt-get install -y tmux` on first use |

Local long-running work does **not** need tmux — `run_in_background` already survives the turn and notifies on exit. tmux is for surviving a dropped SSH connection or a new session.

## Cloudflare Developer Mode

When iterating on assets behind a Cloudflare-proxied domain (`colefoster.ca`, `fostered.dev`, `emilyrank.com`, etc.), enable **Development Mode** to bypass the edge cache for 3h so edits show up on hard reload instead of 5–30 min later. Run `cfdev on` (helper from `~/dotfiles/zsh/macos/local.zsh`; `cfdev on <domain>` targets another zone, `cfdev off` disables). Raw-API fallback, zone-ID lookup, and new-zone setup live in the **`deployer` agent**.

## Skills

The full set of available skills is surfaced each session by the harness — check that list rather than relying on a hardcoded roster here. When a task clearly fits one, proactively suggest or invoke it.

The `mattpocock-skills` plugin is installed and worth reaching for: `tdd` (red-green-refactor), `diagnosing-bugs`, `research` (delegate reading legwork to a background agent), `codebase-design` / `domain-modeling` (deep-module design), `code-review`, `grilling` (stress-test a plan by interviewing relentlessly), `wizard`, `writing-for-agents` (use when editing skills or CLAUDE.md/AGENTS.md).
