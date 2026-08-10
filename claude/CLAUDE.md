# Global Instructions

## Behavior

- Be proactive. If you can figure something out yourself (check configs, read files, search, test endpoints, etc.), do it instead of asking the user. Only ask when you genuinely cannot proceed without their input (passwords, preferences, ambiguous intent).
- When troubleshooting, investigate fully before reporting back. Don't stop at the first finding — follow the chain to the root cause and fix it.
- If a task involves multiple steps you're capable of doing, do them all. Don't ask for permission at each step.

## Subagents — protect the main context

Default to spawning a subagent for anything that would dump significant tokens into the main session: codebase exploration, multi-file reads, grep sweeps, web research, log digging. Use **Explore** for targeted lookups ("where is X defined", "find files matching Y"), **general-purpose** for multi-step research, **Plan** for design work. The goal is keeping raw tool output out of the main context window so the session stays responsive over long tasks.

**Inline is fine for:** a single targeted Read of a known file, a one-line Bash command, an Edit you already know how to make. Anything beyond ~2 file reads or 1 grep — delegate.

**Prefer Sonnet subagents to save tokens.** When a delegated task is mechanical or well-scoped enough that Sonnet can do it reliably — targeted searches, file lookups, grep sweeps, straightforward research, log digging — spawn the subagent on Sonnet (`model: "sonnet"`) rather than defaulting to Opus. Reserve Opus subagents for work that genuinely needs deeper reasoning (complex design, tricky debugging, nuanced multi-step judgment). The point is to keep the cheaper model doing the heavy-token grunt work.

## MCPs

- **github** MCP runs via Docker (`ghcr.io/github/github-mcp-server`). If it fails to connect, the first thing to check is whether OrbStack/Docker daemon is running (`docker ps`). Start OrbStack, then restart Claude Code.
- **playwright** MCP runs via `npx @playwright/mcp@latest` — no daemon needed.
  - It writes screenshots, page snapshots, and console logs to the **current working directory**. Before invoking any `browser_*` tool, `cd` into the relevant project folder (or a scratch subdir) — never leave cwd as `~/Dev` or `~`, or it will litter that directory with PNGs, YAMLs, and a `.playwright-mcp/` folder.

## Response Format — optimize for skimming

Cole skims. Write for a reader who is glancing, not reading.

- **Prefer bullets over prose.** Default to lists. Only use paragraphs when the idea genuinely doesn't decompose.
- **Surface the action.** If there's something Cole needs to *do* (run a command, make a choice, provide input, restart something), put it under a **bold heading** or lead with **bold text** — never bury it inside a paragraph.
- **Bold the load-bearing words** in any sentence that must be read. One or two phrases per sentence, not whole lines.
- **Lead with the answer.** Result first, explanation second. No throat-clearing ("Great question!", "Let me explain...").
- **Short sentences.** If a sentence runs past ~20 words, split it or cut it.
- **Use structure to show priority.** Headings for top-level chunks, bullets for items, code blocks for commands — not walls of text where everything looks equal.
- **Cut the closing summary** unless the user asked for one. The work is the work; no need to recap.

Applies to main responses and subagent outputs alike.

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

## Cloudflare Developer Mode

Whenever you're iterating on a deployed asset behind a Cloudflare-proxied domain (`colefoster.ca`, `fostered.dev`, `emilyrank.com`, or any other zone in Cole's account), **enable Cloudflare Development Mode programmatically** before/while pushing changes. It disables the edge cache for **3 hours** so your edits show up immediately on a hard reload instead of 5–30 min later.

`CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and `CLOUDFLARE_ZONE_ID` are exported from **`~/dotfiles/zsh/macos/local.zsh`** (gitignored), so they're already on `$PATH` for any interactive shell. The same file defines a `cfdev` helper:

```bash
cfdev on               # enable for $CLOUDFLARE_ZONE_ID (default colefoster.ca)
cfdev off              # disable
cfdev on fostered.dev  # look up zone by domain, then enable
```

Use it directly. If you need raw API access (e.g. inside a script that doesn't source the shell rc):

```bash
curl -sX PATCH "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/settings/development_mode" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"value":"on"}'
```

- **When to enable:** any deploy that updates static assets (CSS/JS/HTML/images), nginx config changes, anything where stale cache could mask the change.
- **Auto-expires after 3 hours**, so re-enable on each working session if needed.
- Look up a new zone ID by domain: `curl -s "https://api.cloudflare.com/client/v4/zones?name=DOMAIN" -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | jq '.result[0].id'` — then add it to `local.zsh` as `CLOUDFLARE_ZONE_<UPPER_NAME>`.
- Confirm success by checking the response: `"result": {"value": "on"}`.

## Skills

The full set of available skills is surfaced each session by the harness — check that list rather than relying on a hardcoded roster here. When a task clearly fits one, proactively suggest or invoke it.

The `mattpocock-skills` plugin is installed and worth reaching for: `tdd` (red-green-refactor), `diagnosing-bugs`, `research` (delegate reading legwork to a background agent), `codebase-design` / `domain-modeling` (deep-module design), `code-review`, `grilling` (stress-test a plan by interviewing relentlessly), `wizard`, `writing-for-agents` (use when editing skills or CLAUDE.md/AGENTS.md).
