export CLAUDE_CODE_NO_FLICKER=1

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
# (cmd-Q) detaches instead of killing the session. Re-running in the same dir
# reattaches to the live session.
claude() {
	if [[ -n $TMUX || ! -o interactive ]] || ! command -v tmux >/dev/null; then
		command claude --dangerously-skip-permissions "$@"
		return
	fi

	local s=$(_cc_session)
	if tmux has-session -t "=$s" 2>/dev/null; then
		tmux attach -t "=$s"
	else
		tmux new-session -s "$s" -c "$PWD" "claude --dangerously-skip-permissions ${(q)@}"
	fi
}

# List live claude sessions; with an argument, attach to the matching one.
ccl() {
	if [[ -n $1 ]]; then
		tmux attach -t "$(tmux ls -F '#S' 2>/dev/null | grep -m1 -- "$1")"
		return
	fi
	tmux ls -F '#{session_name}	#{session_path}	(#{session_attached} attached)' 2>/dev/null | grep '^cc-'
}
