# ──────────────────────────────────────────────
# Utility Functions
# ──────────────────────────────────────────────

# Create directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# Extract any archive
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.tar.xz)  tar xJf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.tbz2)    tar xjf "$1" ;;
      *.tgz)     tar xzf "$1" ;;
      *.zip)     unzip "$1" ;;
      *.Z)       uncompress "$1" ;;
      *.7z)      7z x "$1" ;;
      *)         echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Quickly serve current directory over HTTP
serve() { python3 -m http.server "${1:-8000}"; }

# Git commit with message shorthand
gcm() { git add -A && git commit -m "$*"; }

# Whats on a port?
whats-on() { lsof -i :"$1"; }

# Quick note to a scratchpad
note() { echo "$(date '+%Y-%m-%d %H:%M'): $*" >> ~/notes.txt; }

# Weather
weather() { command curl -s "wttr.in/${1:-}"; }

# Diff two files side by side with delta
ddiff() { command diff -u "$1" "$2" | delta; }

# Community cheatsheets (no install needed)
cheat() { local q="${*// /+}"; command curl -s "cheat.sh/$q" | command bat --plain; }

# Check node package version
nv() { node -p "require('$1/package.json').version"; }

# ──────────────────────────────────────────────
# Project Awareness
# ──────────────────────────────────────────────

# View project README
readme() { glow README.md 2>/dev/null || glow README.* 2>/dev/null || echo "No README found"; }

# Find TODOs/FIXMEs in codebase
todo() { command rg --smart-case "TODO|FIXME|HACK|XXX" "${1:-.}"; }

# Show project dependencies at a glance
deps() {
  [[ -f package.json ]] && echo "── package.json ──" && jq '.dependencies,.devDependencies' package.json
  [[ -f composer.json ]] && echo "── composer.json ──" && jq '.require,.require-dev' composer.json
  [[ -f requirements.txt ]] && echo "── requirements.txt ──" && command bat --plain requirements.txt
  [[ -f Gemfile ]] && echo "── Gemfile ──" && command bat --plain Gemfile
}

# ──────────────────────────────────────────────
# Git Helpers
# ──────────────────────────────────────────────

# Open repo in browser (uses xdg-open on Linux, open on macOS)
gopen() {
  local url
  url="$(git remote get-url origin | command sed -E 's|git@(.+):(.+)\.git|https://\1/\2|')"
  ${DOTFILES_OPEN_CMD:-open} "$url"
}

# Open PR creation page for current branch
gpr() {
  local url
  url="$(git remote get-url origin | command sed -E 's|git@(.+):(.+)\.git|https://\1/\2|')"
  ${DOTFILES_OPEN_CMD:-open} "$url/compare/$(git branch --show-current)"
}

# ──────────────────────────────────────────────
# Environment / Debugging
# ──────────────────────────────────────────────

# Search environment variables
envs() { env | sort | command rg "${1:-.}"; }

# Kill whatever is on a port
portfree() { lsof -ti :"$1" | xargs kill -9 2>/dev/null && echo "Port $1 freed" || echo "Port $1 already free"; }

# Restart the pi-lead app: stop whatever's on its ports (old server.mjs or the new
# harness+web split), then relaunch start.mjs detached. Caddy fronts it on :8443.
pilead() {
  local dir=/Users/cole/Dev/pi
  local pids
  pids=$(lsof -t -iTCP:5178 -iTCP:5179 -sTCP:LISTEN 2>/dev/null)
  # Pipe to xargs: zsh does NOT word-split $pids, so a multiline list (5178 +
  # 5179 = always 2+ pids) would reach `kill` as one illegal arg and no-op.
  [ -n "$pids" ] && print -r -- "$pids" | xargs kill 2>/dev/null
  pkill -f "$dir/start.mjs" 2>/dev/null
  sleep 1
  # Launch with the absolute path so the cmdline matches the pkill above on the
  # next restart (relative `node start.mjs` orphaned old parents → port pileup).
  ( cd "$dir" && nohup node "$dir/start.mjs" >/tmp/pi-lead.log 2>&1 &! )
  sleep 2
  echo "pi-lead restarted → http://localhost:5178 (caddy :8443) · logs: tail -f /tmp/pi-lead.log"
}

# ──────────────────────────────────────────────
# Data Utilities
# ──────────────────────────────────────────────

# URL encode/decode
urlencode() { python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$*"; }
urldecode() { python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" "$*"; }

# ──────────────────────────────────────────────
# File Managers
# ──────────────────────────────────────────────

# yazi wrapper: cd into the directory yazi was in when you quit (with q)
y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    command rm -f -- "$tmp"
}
