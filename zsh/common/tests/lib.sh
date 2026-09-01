#!/bin/bash
# Shared harness for the cc-* regression tests.
#
# Every test runs against a REAL tmux server and REAL terminals, because every
# bug this suite covers lives in the seam between them — which client a command
# resolves to, whether a shell is really inside a pane, which session a name
# matches. A mocked tmux would have passed while all of them were live.
#
# Isolation comes from two variables:
#   TMUX_TMPDIR  puts the server on its own socket, so tests never see or kill
#                the sessions you are working in
#   HOME         is a scratch dir holding fixture transcripts and session json,
#                so cc-sessions reads test data instead of your real history
#
# A "tile" is a command run under script(1), which gives it a genuine pty. That
# is what makes the inherited-$TMUX tests meaningful: a tile has its own tty, so
# a borrowed TMUX_PANE points at somebody else's.

set -uo pipefail

COMMON_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REAL_HOME=$HOME

PASS=0
FAIL=0
FAILED_NAMES=()
CURRENT=

# ---------------------------------------------------------------- reporting

_red()   { printf '\033[31m%s\033[0m' "$1"; }
_green() { printf '\033[32m%s\033[0m' "$1"; }
_dim()   { printf '\033[2m%s\033[0m' "$1"; }

ok() {
	PASS=$((PASS + 1))
	printf '  %s %s\n' "$(_green ✓)" "$1"
}

fail() {
	FAIL=$((FAIL + 1))
	FAILED_NAMES+=("$CURRENT: $1")
	printf '  %s %s\n' "$(_red ✗)" "$1"
	[ $# -gt 1 ] && printf '      %s\n' "$(_dim "$2")"
	return 0
}

assert_eq() { # <want> <got> <label>
	if [ "$1" = "$2" ]; then ok "$3"; else fail "$3" "want [$1] got [$2]"; fi
}

assert_ne() { # <unwanted> <got> <label>
	if [ "$1" != "$2" ]; then ok "$3"; else fail "$3" "did not want [$1]"; fi
}

assert_contains() { # <haystack> <needle> <label>
	case "$1" in
		*"$2"*) ok "$3" ;;
		*) fail "$3" "[$2] not found in [$(printf '%s' "$1" | head -c 200)]" ;;
	esac
}

assert_not_contains() { # <haystack> <needle> <label>
	case "$1" in
		*"$2"*) fail "$3" "[$2] should not appear" ;;
		*) ok "$3" ;;
	esac
}

# ---------------------------------------------------------------- sandbox

t_setup() {
	CURRENT=$1
	printf '\n%s\n' "$(_dim "── $1")"
	SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/cc-test.XXXXXX")
	export HOME=$SANDBOX/home
	export TMUX_TMPDIR=$SANDBOX/tmux
	# Pin the work account inside the sandbox. The real name lives in the
	# gitignored local.zsh; the suite must not depend on it either way.
	export CC_WORK_CONFIG=$HOME/.claude-work
	export CC_WORK_LABEL=Work
	mkdir -p "$HOME" "$TMUX_TMPDIR" "$SANDBOX/bin" \
		"$HOME/.claude/sessions" "$CC_WORK_CONFIG/sessions" \
		"$HOME/Work"
	export PATH=$SANDBOX/bin:$PATH

	# A stand-in for claude: records the tmux session it was started in the way
	# the real one does, then parks so the session stays alive to assert against.
	cat > "$SANDBOX/bin/claude" <<'FAKE'
#!/bin/sh
sid=${CC_FAKE_SID:-$(printf 'fake-%s' "$$")}
cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
mkdir -p "$cfg/sessions"
printf '{"tmux":"%s","sessionId":"%s","args":"%s","cfg":"%s"}\n' \
	"${TMUX_SESSION:-$(tmux display -p '#{session_name}' 2>/dev/null)}" \
	"$sid" "$*" "$cfg" > "$cfg/sessions/$$.json"
printf '%s\n' "$*" > "$HOME/last-claude-args"
printf '%s\n' "$cfg" > "$HOME/last-claude-cfg"
while :; do sleep 1; done
FAKE
	chmod +x "$SANDBOX/bin/claude"

	# The interactive shell a tile starts: nothing but the code under test.
	cat > "$HOME/.zshrc" <<ZRC
source "$COMMON_DIR/claude.zsh"
ZRC
}

t_teardown() {
	tmux kill-server 2>/dev/null
	[ -n "${SANDBOX:-}" ] && rm -rf "$SANDBOX"
	export HOME=$REAL_HOME
	unset TMUX_TMPDIR
}

# ---------------------------------------------------------------- terminals

# Run a command in a real pty, detached from this shell's terminal, and return
# once it exits. script(1) is the portable way to get a tty without a terminal
# emulator.
tile() { # <shell-command> [env assignments...]
	local cmd=$1; shift
	local envs=("$@")
	( for e in "${envs[@]+"${envs[@]}"}"; do export "${e?}"; done
	  script -q /dev/null zsh -i -c "$cmd" ) </dev/null >/dev/null 2>&1
}

# Same, but leave it running in the background and print its pid: the shell
# stays attached to whatever session it opened, the way a real window does.
tile_bg() { # <shell-command> [env assignments...]
	local cmd=$1; shift
	local envs=("$@")
	( for e in "${envs[@]+"${envs[@]}"}"; do export "${e?}"; done
	  script -q /dev/null zsh -i -c "$cmd" ) </dev/null >/dev/null 2>&1 &
	printf '%s\n' $!
}

# Poll until a command succeeds. Every assertion about tmux state needs one:
# a session appears some milliseconds after the command that created it.
wait_for() { # <timeout-seconds> <command...>
	local deadline=$(( $(date +%s) + $1 )); shift
	while [ "$(date +%s)" -lt "$deadline" ]; do
		"$@" >/dev/null 2>&1 && return 0
		sleep 0.2
	done
	return 1
}

sessions() { tmux ls -F '#{session_name}' 2>/dev/null | sort; }
clients()  { tmux list-clients -F '#{client_tty} #{client_session}' 2>/dev/null | sort; }
have_session() { tmux has-session -t "=$1" 2>/dev/null; }

summary() {
	printf '\n'
	if [ "$FAIL" -eq 0 ]; then
		printf '%s\n' "$(_green "all $PASS passed")"
		return 0
	fi
	printf '%s\n' "$(_red "$FAIL failed")$(_dim ", $PASS passed")"
	for n in "${FAILED_NAMES[@]}"; do printf '  %s\n' "$(_red "✗ $n")"; done
	return 1
}
