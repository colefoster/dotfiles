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

# Run claude inside a per-directory tmux session so quitting the terminal
# (cmd-Q) detaches instead of killing the session.
#
#   claude              reattach the dir's detached session, else start one;
#                       if it's already open in another window, start a sibling
#                       rather than mirroring it
#   claude <args...>    always a fresh session, so --resume/--model/etc are
#                       never silently swallowed
#   one-shot / non-TUI  runs bare — nothing worth keeping alive
claude() {
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
	if (( $# == 0 )); then
		if tmux has-session -t "=$s" 2>/dev/null; then
			# Attaching a second client to a live session mirrors it (and forces
			# both windows to the smaller size). Only reattach if nothing else
			# is watching; otherwise fall through and start a sibling session.
			if [[ $(tmux display -p -t "=$s" '#{session_attached}') == 0 ]]; then
				tmux attach -t "=$s"
				return
			fi
			print -u2 "claude: $s is open in another window — starting a new session (ccl -s to steal it)"
		fi
	fi
	if (( $# > 0 )) || tmux has-session -t "=$s" 2>/dev/null; then
		local n=2
		while tmux has-session -t "=$s" 2>/dev/null; do
			s="$(_cc_session)-$n"
			(( n++ ))
		done
	fi
	# ${(q)a} inside quotes would join the array into ONE argument; ${(q)a[@]}
	# quotes each element and joins with spaces, which is what sh needs.
	local -a a=("$@")
	# Keep the pane open after Claude exits so its final resume command remains
	# visible instead of being replaced immediately by tmux's `[exited]` notice.
	local run="claude --dangerously-skip-permissions ${(q)a[@]}"
	run+="; _cc_status=\$?; printf '\\nPress Enter to return to the shell...'; read -r _cc_reply; exit \$_cc_status"
	tmux new-session -s "$s" -c "$PWD" "$run"
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
