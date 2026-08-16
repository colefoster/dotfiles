# A leftover `codex` alias prevents the function below from being defined.
unalias codex 2>/dev/null

# tmux session name for a directory. The path hash keeps directories with the
# same basename from sharing a session.
_codex_session() {
	local dir=${1:-$PWD}
	local base=${${dir:t}//[^a-zA-Z0-9_-]/-}
	local hash=$(print -rn -- "$dir" | cksum | cut -d' ' -f1)
	print -r -- "codex-${base}-${hash:0:6}"
}

# Keep interactive Codex sessions alive when the terminal closes.
#
#   codex             reattach the directory's detached session, else start it
#   codex <args...>   start a fresh sibling session with every argument intact
#   codex exec/...    run non-interactive and administrative commands directly
codex() {
	if [[ -n $TMUX || ! -o interactive ]] || ! command -v tmux >/dev/null; then
		command codex "$@"
		return
	fi

	# These commands are non-interactive, launch another app/server, or only
	# print information. Interactive commands such as resume/fork stay in tmux.
	case ${1-} in
		exec|review|login|logout|mcp|plugin|mcp-server|app-server|remote-control|app|completion|update|doctor|sandbox|debug|apply|archive|delete|unarchive|exec-server|features|help|-V|--version|-h|--help)
			command codex "$@"
			return ;;
	esac

	local s=$(_codex_session)
	if (( $# == 0 )) && tmux has-session -t "=$s" 2>/dev/null; then
		if [[ $(tmux display -p -t "=$s" '#{session_attached}') == 0 ]]; then
			tmux attach -t "=$s"
			return
		fi
		print -u2 "codex: $s is open in another window — starting a new session (cxl -s to steal it)"
	fi

	if (( $# > 0 )) || tmux has-session -t "=$s" 2>/dev/null; then
		local n=2
		while tmux has-session -t "=$s" 2>/dev/null; do
			s="$(_codex_session)-$n"
			(( n++ ))
		done
	fi

	local -a args=("$@")
	tmux new-session -s "$s" -c "$PWD" "codex ${(q)args[@]}"
}

# List live Codex sessions; with an argument, attach to the first match.
#   cxl -s <name>   steal it, detaching the currently attached client
cxl() {
	local steal=
	[[ $1 == -s ]] && { steal=-d; shift }
	if [[ -n $1 ]]; then
		local target=$(tmux ls -F '#S' 2>/dev/null | grep -m1 -- "$1")
		[[ -z $target ]] && { print -u2 "cxl: no session matching '$1'"; return 1 }
		tmux attach $steal -t "=$target"
		return
	fi
	tmux ls -F '#{session_name}\t#{session_path}\t(#{session_attached} attached)' 2>/dev/null | grep '^codex-'
}
