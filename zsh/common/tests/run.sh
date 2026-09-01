#!/bin/bash
# Regression tests for the tmux-wrapped claude launcher.
#
#   ./tests/run.sh            run everything
#   ./tests/run.sh stale      run tests whose name matches "stale"
#
# Each test is named for the bug it locks down. See lib.sh for why these run
# against a real tmux server and real ptys rather than mocks.

cd "$(dirname "$0")" || exit 1
. ./lib.sh

PROJ_NAME=omacosy-hq

# The session name claude() computes for a directory, asked of the code itself
# so the test can never drift from the implementation.
wrapper_session() { # <dir>
	zsh -c "source '$COMMON_DIR/claude.zsh'; _cc_session '$1'"
}

# ---------------------------------------------------------------------------
# A terminal that inherited TMUX from a GUI app owns no pane. The launcher must
# not believe it: switch-client would move whichever window that stale TMUX
# names, leaving the terminal you typed in at a prompt.
#
# Regression: AeroSpace restarted from inside a pane passed TMUX/TMUX_PANE to
# every Ghostty it spawned.
# ---------------------------------------------------------------------------
test_stale_tmux_does_not_hijack_another_window() {
	t_setup "stale TMUX does not hijack another window"
	local proj=$HOME/$PROJ_NAME
	mkdir -p "$proj"

	# A real session with a real client, standing in for the window the stale
	# TMUX was inherited from.
	tmux new-session -d -s donor -c "$HOME"
	local pane; pane=$(tmux display -pt donor '#{pane_id}')
	local tmuxvar; tmuxvar=$(tmux display -pt donor '#{socket_path},#{pid},0')
	tile_bg "tmux attach -t donor" >/dev/null
	if ! wait_for 10 test -n "$(tmux list-clients -F x -t donor 2>/dev/null)"; then
		fail "donor client attached"; t_teardown; return
	fi
	local donor_tty; donor_tty=$(tmux list-clients -t donor -F '#{client_tty}' | head -1)

	# The new tile: its own pty, carrying somebody else's TMUX and TMUX_PANE.
	tile_bg "cd '$proj' && claude" \
		"CC_NO_PICK=1" "TMUX=$tmuxvar" "TMUX_PANE=$pane" >/dev/null

	local want; want=$(wrapper_session "$proj")
	if ! wait_for 20 have_session "$want"; then
		fail "session $want created" "sessions: $(sessions | tr '\n' ' ')"
		t_teardown; return
	fi
	ok "session $want created"

	# The donor window must still be showing the donor session.
	local donor_now
	donor_now=$(tmux list-clients -F '#{client_tty} #{client_session}' | awk -v t="$donor_tty" '$1 == t { print $2 }')
	assert_eq "donor" "$donor_now" "the inherited window kept its own session"

	# And the new session must be on a client of its own — the tile.
	local new_client
	new_client=$(tmux list-clients -F '#{client_session}' | grep -cx "$want")
	assert_eq "1" "$new_client" "the new session attached to the tile that asked for it"

	t_teardown
}

# ---------------------------------------------------------------------------
# A genuine pane must still take the in-tmux path: build detached, walk the
# client over. Guarding against inherited TMUX must not break the real case.
# ---------------------------------------------------------------------------
test_real_pane_switches_in_place() {
	t_setup "a real pane switches the client instead of nesting"
	local proj=$HOME/$PROJ_NAME
	mkdir -p "$proj"

	tmux new-session -d -s host -c "$proj"
	tile_bg "tmux attach -t host" >/dev/null
	wait_for 10 test -n "$(tmux list-clients -F x -t host 2>/dev/null)" || { fail "host client"; t_teardown; return; }

	# Type the command inside the pane, so $TMUX is real and $TTY is the pane's.
	tmux send-keys -t host "CC_NO_PICK=1 zsh -i -c 'cd \"$proj\" && claude'" Enter

	local want; want=$(wrapper_session "$proj")
	if ! wait_for 20 have_session "$want"; then
		fail "session $want created from inside a pane" "sessions: $(sessions | tr '\n' ' ')"
		t_teardown; return
	fi
	ok "session $want created from inside a pane"

	# The client walked over rather than opening a second one.
	local n; n=$(tmux list-clients -F '#{client_session}' | grep -cx "$want")
	assert_eq "1" "$n" "the pane's own client moved to the new session"
	t_teardown
}

# ---------------------------------------------------------------------------
# Two launches in one directory must not collide onto one session: the second
# takes the first free -N suffix.
# ---------------------------------------------------------------------------
test_second_launch_gets_a_sibling_name() {
	t_setup "a second launch in the same directory gets its own session"
	local proj=$HOME/$PROJ_NAME
	mkdir -p "$proj"
	local base; base=$(wrapper_session "$proj")

	tile_bg "cd '$proj' && claude" "CC_NO_PICK=1" >/dev/null
	wait_for 20 have_session "$base" || { fail "first session"; t_teardown; return; }
	tile_bg "cd '$proj' && claude" "CC_NO_PICK=1" >/dev/null
	if wait_for 20 have_session "$base-2"; then
		ok "second launch created $base-2"
	else
		fail "second launch created $base-2" "sessions: $(sessions | tr '\n' ' ')"
	fi
	assert_eq "1" "$(have_session "$base" && echo 1)" "the first session survived"
	t_teardown
}

# ---------------------------------------------------------------------------
# cc-sessions walks both config roots. The glob suffix used to bind to the last
# root only, so every personal transcript vanished from the picker.
# ---------------------------------------------------------------------------
test_picker_lists_transcripts_from_both_roots() {
	t_setup "the picker lists transcripts from both config roots"
	local now; now=$(date +%s)
	local when; when=$(date -u -r "$((now - 600))" +%Y-%m-%dT%H:%M:%SZ)

	_fixture() { # <root> <slug> <uuid> <cwd> <text>
		mkdir -p "$1/projects/$2"
		printf '{"type":"user","cwd":"%s","timestamp":"%s","message":{"role":"user","content":"%s"}}\n' \
			"$4" "$when" "$5" > "$1/projects/$2/$3.jsonl"
	}
	_fixture "$HOME/.claude" "-personal-proj" "11111111-1111-1111-1111-111111111111" \
		"$HOME/personal-proj" "PERSONAL_MARKER"
	_fixture "$CC_WORK_CONFIG" "-work-proj" "22222222-2222-2222-2222-222222222222" \
		"$HOME/Work/work-proj" "WORK_MARKER"

	mkdir -p "$HOME/elsewhere"
	local out; out=$(CC_CWD=$HOME/elsewhere "$COMMON_DIR/cc-sessions" 2>/dev/null)
	assert_contains "$out" "PERSONAL_MARKER" "a ~/.claude transcript is offered"
	assert_contains "$out" "WORK_MARKER" "a work-account transcript is offered"
	assert_not_contains "$out" "projects$(printf '\t')" "no bare root leaked into the rows"
	t_teardown
}

# ---------------------------------------------------------------------------
# cc-handoff must land in the same session family claude() would compute, which
# means folding the path to lowercase before hashing.
# ---------------------------------------------------------------------------
test_handoff_names_match_the_wrapper() {
	t_setup "cc-handoff names a session the wrapper agrees with"
	local dir=/Users/cole/Dev/Mixed-Case-Proj
	local want; want=$(wrapper_session "$dir")
	# The naming block of cc-handoff, evaluated the way the script does it.
	local got
	got=$(sh -c '
		dir=$1
		lower=$(printf "%s" "$dir" | tr "[:upper:]" "[:lower:]")
		base=$(printf "%s" "${lower##*/}" | tr -c "a-zA-Z0-9_-" "-")
		hash=$(printf "%s" "$lower" | cksum | cut -d" " -f1 | cut -c1-6)
		printf "cc-%s-%s\n" "$base" "$hash"
	' sh "$dir")
	assert_eq "$want" "$got" "same session name for a mixed-case path"
	grep -q 'tr .\[:upper:\]. .\[:lower:\].' "$COMMON_DIR/cc-handoff" \
		&& ok "cc-handoff folds case before hashing" \
		|| fail "cc-handoff folds case before hashing"
	t_teardown
}

# ---------------------------------------------------------------------------
# `cclay save -t` with no value used to spin forever: shift 2 fails without
# consuming, so $# never drains.
# ---------------------------------------------------------------------------
test_cc_layout_bare_flag_exits() {
	t_setup "cc-layout rejects a bare -t instead of hanging"
	local rc=0
	CC_LAYOUT_TIMEOUT=$( { timeout 5 "$COMMON_DIR/cc-layout" save -t >/dev/null 2>&1; echo $?; } )
	rc=$CC_LAYOUT_TIMEOUT
	if [ "$rc" = "124" ]; then
		fail "exits rather than looping" "timed out — still spinning"
	else
		ok "exits rather than looping"
		assert_ne "0" "$rc" "a bare -t is an error"
	fi
	t_teardown
}

# ---------------------------------------------------------------------------
# The steal decision reads one session's attached flag. A plain-name tmux
# target prefix-matches, so a dead session used to resolve to its -2 sibling.
# ---------------------------------------------------------------------------
test_steal_lookup_is_exact() {
	t_setup "the steal decision does not prefix-match a sibling"
	tmux new-session -d -s cc-proj-123456-2 -c "$HOME"
	tile_bg "tmux attach -t cc-proj-123456-2" >/dev/null
	wait_for 10 test -n "$(tmux list-clients -F x -t cc-proj-123456-2 2>/dev/null)" \
		|| { fail "sibling client"; t_teardown; return; }

	# The exact name is gone; only the sibling remains.
	local row
	row=$(tmux ls -F $'#{session_name}\t#{session_attached}\t#{session_path}' 2>/dev/null |
		awk -F'\t' -v s="cc-proj-123456" '$1 == s { print $2 "\t" $3; exit }')
	assert_eq "" "$row" "a missing session matches nothing"

	# And the old expression is what it used to resolve to.
	local loose; loose=$(tmux display -pt "cc-proj-123456" '#{session_name}' 2>/dev/null)
	assert_eq "cc-proj-123456-2" "$loose" "the plain-name target really does prefix-match"
	grep -q 'awk -F' "$COMMON_DIR/claude.zsh" && ok "claude.zsh uses the exact lookup" \
		|| fail "claude.zsh uses the exact lookup"
	t_teardown
}

# ---------------------------------------------------------------------------
# Work directories get their own config root, in every entry point.
# ---------------------------------------------------------------------------
test_account_follows_the_directory() {
	t_setup "the work account never bleeds into personal projects"
	local work=$HOME/Work/proj personal=$HOME/personal
	mkdir -p "$work" "$personal"

	for pair in "$work:${CC_WORK_CONFIG##*/}" "$personal:.claude"; do
		local dir=${pair%%:*} want=${pair#*:}
		local got
		got=$(zsh -c "source '$COMMON_DIR/claude.zsh'; _cc_account '$dir'; print -r -- \$CLAUDE_CONFIG_DIR")
		assert_eq "$HOME/$want" "$got" "$(basename "$dir") resolves to $want"
	done

	# ch is a separate entry point and used to skip the account entirely.
	grep -q '_cc_account "\$PWD"' "$COMMON_DIR/claude.zsh" && ok "ch picks an account" \
		|| fail "ch picks an account"
	local n; n=$(grep -c '_cc_account "\$PWD"' "$COMMON_DIR/claude.zsh")
	assert_eq "2" "$n" "both ch and claude select an account"
	t_teardown
}

# ---------------------------------------------------------------------------
# The launcher passes the chosen account into the session it builds, so a
# resumed transcript opens on the account that can actually read it.
# ---------------------------------------------------------------------------
test_session_env_carries_the_account() {
	t_setup "the session is built with the account's config dir"
	local work=$HOME/Work/proj
	mkdir -p "$work"
	tile_bg "cd '$work' && claude" "CC_NO_PICK=1" >/dev/null
	local want; want=$(wrapper_session "$work")
	wait_for 20 have_session "$want" || { fail "work session created"; t_teardown; return; }
	ok "work session created"
	if wait_for 10 test -s "$HOME/last-claude-cfg"; then
		assert_eq "$CC_WORK_CONFIG" "$(cat "$HOME/last-claude-cfg")" \
			"claude ran with the work config dir"
	else
		fail "claude ran with the work config dir" "no config recorded"
	fi
	t_teardown
}

# ---------------------------------------------------------------------------
# ccl only manages our own sessions, and works from inside tmux.
# ---------------------------------------------------------------------------
test_ccl_only_matches_cc_sessions() {
	t_setup "ccl ignores sessions that are not ours"
	tmux new-session -d -s notours-proj -c "$HOME"
	local out
	out=$(zsh -c "source '$COMMON_DIR/claude.zsh'; ccl proj" 2>&1)
	assert_contains "$out" "no session matching" "a non-cc session is not a match"
	grep -q "grep '\^cc-' | grep -m1" "$COMMON_DIR/claude.zsh" \
		&& ok "ccl filters to cc-*" || fail "ccl filters to cc-*"
	grep -q '_cc_disown_stale_tmux' <(grep -A4 '^ccl()' "$COMMON_DIR/claude.zsh") \
		&& ok "ccl guards against inherited TMUX" || fail "ccl guards against inherited TMUX"
	grep -q '_cc_disown_stale_tmux' <(grep '^cclay()' "$COMMON_DIR/claude.zsh") \
		&& ok "cclay guards against inherited TMUX" || fail "cclay guards against inherited TMUX"
	t_teardown
}

# ---------------------------------------------------------------------------
# The preview must not go blank when a transcript ends on tool traffic.
# ---------------------------------------------------------------------------
test_preview_falls_back_to_the_whole_file() {
	t_setup "the preview survives a transcript that ends in tool traffic"
	local uuid=33333333-3333-3333-3333-333333333333
	local dir=$HOME/.claude/projects/-tail-proj
	mkdir -p "$dir"
	local when; when=$(date -u +%Y-%m-%dT%H:%M:%SZ)
	{
		printf '{"type":"user","cwd":"%s","timestamp":"%s","message":{"role":"user","content":"REAL_TURN"}}\n' \
			"$HOME/tail-proj" "$when"
		# Enough tool traffic to push the real turn past the 256 KB tail window.
		i=0
		while [ $i -lt 2000 ]; do
			printf '{"type":"user","toolUseResult":{"x":"%s"},"timestamp":"%s","message":{"role":"user","content":"tool"}}\n' \
				"$(head -c 200 /dev/zero | tr '\0' 'x')" "$when"
			i=$((i + 1))
		done
	} > "$dir/$uuid.jsonl"

	local turns; turns=$("$COMMON_DIR/cc-sessions" --turns "resume:$uuid" 5 2>/dev/null)
	assert_contains "$turns" "REAL_TURN" "cc_turns re-reads the whole file"
	t_teardown
}

# ---------------------------------------------------------------------------

ALL=$(declare -F | awk '{print $3}' | grep '^test_' | sort)
FILTER=${1:-}
for t in $ALL; do
	[ -n "$FILTER" ] && case "$t" in *"$FILTER"*) ;; *) continue ;; esac
	"$t"
done
summary
