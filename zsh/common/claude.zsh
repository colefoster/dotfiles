export CLAUDE_CODE_NO_FLICKER=1

# A leftover `claude` alias (from an earlier source of this file) makes the
# function definitions below a parse error, so clear it first.
unalias claude 2>/dev/null

ch() {
	command claude -p "Answer the following question - it may or may not be related to the currently open project & files. Answer very briefly, limiting your response to 1 or 2 lines. Don't add any code to the project. The question is: How do I $*"
}

# tmux session name for a directory: cc-<basename>-<hash>, so two dirs sharing a
# basename don't collide onto the same session.
_cc_session() {
	local dir=${1:-$PWD}
	local base=${${dir:t}//[^a-zA-Z0-9_-]/-}
	local hash=$(print -rn -- "$dir" | cksum | cut -d' ' -f1)
	print -r -- "cc-${base}-${hash:0:6}"
}

# On exit, tmux restores the terminal to its pre-launch state, discarding
# Claude's parting output (the resume hint). Capture the pane's visible text
# just before the session dies and replay it into the outer terminal, so
# quitting matches bare `claude`: no extra keypress, hint still on screen.
# Detaching (cmd-Q) never reaches the capture, so it stays silent.
_cc_flush() {
	local f="${TMPDIR:-/tmp}/cc-exit-$1"
	# Drop trailing blank lines so the prompt lands right under the hint.
	[[ -s $f ]] && awk 'NF{b=b sep $0; sep="\n"; next}{sep=sep "\n"}END{if(b)print "\n" b}' "$f"
	rm -f -- "$f"
}

# Path to the session-list helper, resolved when this file is sourced.
_CC_SESSIONS=${0:A:h}/cc-sessions

# Reap detached sessions nobody has attached to in CC_PURGE_DAYS days (default
# 10; set 0 to disable). Killing a session ends its Claude process, but the
# transcript is already on disk, so `claude --resume` in that directory still
# brings the conversation back.
_cc_purge() {
	local days=${CC_PURGE_DAYS:-10}
	(( days > 0 )) || return 0
	local cutoff=$(( $(date +%s) - days * 86400 ))
	local -a stale
	stale=("${(@f)$(tmux ls -F '#{session_name} #{session_attached} #{session_last_attached} #{session_created}' 2>/dev/null |
		awk -v cutoff=$cutoff '$1 ~ /^cc-/ && $2 == 0 && ($3 > 0 ? $3 : $4) < cutoff { print $1 }')}")
	stale=(${stale:#})
	(( ${#stale} )) || return 0
	local name
	for name in $stale; do
		tmux kill-session -t "=$name" 2>/dev/null
	done
	print -u2 "claude: reaped ${#stale} session(s) untouched for ${days}+ days"
}

# Picker shown when `claude` runs bare: choose a detached session to resume, or
# start a fresh one. Prints the chosen session name or __new__; returns 1 when
# the user cancels. Falls back to __new__ when fzf is missing or nothing is
# resumable, so the picker never stands between you and a new session.
_cc_pick() {
	local cmd="CC_CWD=${(q)PWD} ${(q)_CC_SESSIONS}"
	if ! command -v fzf >/dev/null || [[ ! -x $_CC_SESSIONS ]]; then
		print -r -- __new__
		return 0
	fi

	local -a rows=("${(@f)$(eval $cmd)}")
	# Row 1 is always __new__; anything less means there is nothing to resume.
	if (( ${#rows} < 2 )); then
		print -r -- __new__
		return 0
	fi

	local sel
	sel=$(print -rl -- "${rows[@]}" | fzf \
		--delimiter=$'\t' --with-nth=2.. --no-multi \
		--height=70% --layout=reverse --border=rounded \
		--prompt='claude ❯ ' \
		--header='enter resume   ctrl-n new   ctrl-x kill   esc cancel' \
		--preview='[ {1} = __new__ ] && echo "Start a new Claude session here." || tmux capture-pane -pt {1}' \
		--preview-window='right,62%,wrap' \
		--bind='ctrl-n:become(echo __new__)' \
		--bind="ctrl-x:execute(printf 'kill %s? [y/N] ' {1}; read -r yn; [ \"\$yn\" = y ] && tmux kill-session -t '={1}')+reload($cmd)") || return 1

	print -r -- "${sel%%$'\t'*}"
}

# Run claude inside a per-directory tmux session so quitting the terminal
# (cmd-Q) detaches instead of killing the session.
#
#   claude              open the picker: resume any detached session (this
#                       directory's first) or start a new one. With no
#                       resumable session, or CC_NO_PICK=1, it starts one
#                       straight away.
#   claude <args...>    always a fresh session, so --resume/--model/etc are
#                       never silently swallowed
#   one-shot / non-TUI  runs bare — nothing worth keeping alive
#
# Every launch first reaps sessions untouched for CC_PURGE_DAYS days.
#
# Work dirs get their own config dir (separate login/auth/history) so the
# Blockskye account never bleeds into personal projects. The label is only
# cosmetic — the status line reads it to show which account is in use.
claude() {
	local -x CLAUDE_CONFIG_DIR CLAUDE_ACCOUNT_LABEL
	case ${PWD:l} in
		${HOME:l}/work|${HOME:l}/work/*)
			CLAUDE_CONFIG_DIR=$HOME/.claude-blockskye
			CLAUDE_ACCOUNT_LABEL=Blockskye ;;
		*)
			CLAUDE_CONFIG_DIR=$HOME/.claude
			CLAUDE_ACCOUNT_LABEL=Personal ;;
	esac

	if [[ -n $TMUX || ! -o interactive ]] || ! command -v tmux >/dev/null; then
		command claude --dangerously-skip-permissions "$@"
		return
	fi

	# Subcommands and print/info modes exit on their own; don't wrap them.
	case ${1-} in
		mcp|config|plugin|agents|update|doctor|install|migrate-installer|setup-token|-v|--version|-h|--help)
			command claude "$@"
			return ;;
	esac
	if (( $@[(I)-p] || $@[(I)--print] )); then
		command claude --dangerously-skip-permissions "$@"
		return
	fi

	local s=$(_cc_session)
	_cc_purge
	if (( $# == 0 )) && [[ -z $CC_NO_PICK ]]; then
		local pick
		pick=$(_cc_pick) || return 130          # esc / ctrl-c: do nothing
		if [[ -n $pick && $pick != __new__ ]]; then
			tmux attach -t "=$pick"
			local attach_status=$?
			_cc_flush "$pick"
			return $attach_status
		fi
	fi
	# Attaching a second client to a live session mirrors it (and forces both
	# windows to the smaller size), so an attached session is never reused: take
	# the next free sibling name instead.
	local n=2
	while tmux has-session -t "=$s" 2>/dev/null; do
		s="$(_cc_session)-$n"
		(( n++ ))
	done
	# ${(q)a} inside quotes would join the array into ONE argument; ${(q)a[@]}
	# quotes each element and joins with spaces, which is what sh needs.
	local -a a=("$@")
	local cap="${TMPDIR:-/tmp}/cc-exit-$s"
	rm -f -- "$cap"
	local run="claude --dangerously-skip-permissions ${(q)a[@]}"
	run+="; _cc_status=\$?; tmux capture-pane -p > ${(q)cap} 2>/dev/null; exit \$_cc_status"
	# -e explicitly: a new session's env otherwise comes from the tmux server,
	# which may predate this shell and carry the wrong account.
	tmux new-session -s "$s" -c "$PWD" \
		-e "CLAUDE_CONFIG_DIR=$CLAUDE_CONFIG_DIR" \
		-e "CLAUDE_ACCOUNT_LABEL=$CLAUDE_ACCOUNT_LABEL" \
		"$run"
	local status=$?
	_cc_flush "$s"
	return $status
}

# List live claude sessions; with an argument, attach to the first match.
#   ccl -s <name>   steal it, detaching whatever window has it open
ccl() {
	local steal=
	[[ $1 == -s ]] && { steal=-d; shift }
	if [[ -n $1 ]]; then
		local t=$(tmux ls -F '#S' 2>/dev/null | grep -m1 -- "$1")
		[[ -z $t ]] && { print -u2 "ccl: no session matching '$1'"; return 1 }
		tmux attach $steal -t "=$t"
		return
	fi
	tmux ls -F '#{session_name}	#{session_path}	(#{session_attached} attached)' 2>/dev/null | grep '^cc-'
}
