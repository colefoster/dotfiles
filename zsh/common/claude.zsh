export CLAUDE_CODE_NO_FLICKER=1

# A leftover `claude` alias (from an earlier source of this file) makes the
# function definitions below a parse error, so clear it first.
unalias claude 2>/dev/null

ch() {
	command claude -p "Answer the following question - it may or may not be related to the currently open project & files. Answer very briefly, limiting your response to 1 or 2 lines. Don't add any code to the project. The question is: How do I $*"
}

# Pick the config dir (login, auth, history) for a directory. Work dirs get
# their own so the Blockskye account never bleeds into personal projects. The
# label is only cosmetic — the status line reads it to show which account is in
# use. Assigns to the caller's CLAUDE_CONFIG_DIR / CLAUDE_ACCOUNT_LABEL.
_cc_account() {
	case ${1:l} in
		${HOME:l}/work|${HOME:l}/work/*)
			CLAUDE_CONFIG_DIR=$HOME/.claude-blockskye
			CLAUDE_ACCOUNT_LABEL=Blockskye ;;
		*)
			CLAUDE_CONFIG_DIR=$HOME/.claude
			CLAUDE_ACCOUNT_LABEL=Personal ;;
	esac
}

# tmux session name for a directory: cc-<basename>-<hash>, so two dirs sharing a
# basename don't collide onto the same session. The path is folded to lowercase
# first: the filesystem is case-insensitive, so ~/Dev and ~/dev are one
# directory, and hashing them apart split one project into two session families.
_cc_session() {
	local dir=${${1:-$PWD}:l}
	local base=${${dir:t}//[^a-zA-Z0-9_-]/-}
	local hash=$(print -rn -- "$dir" | cksum | cut -d' ' -f1)
	print -r -- "cc-${base}-${hash:0:6}"
}

# Working directory a transcript was recorded in, so resuming one from another
# project opens where that conversation actually lives.
_cc_resume_dir() {
	local dir=$(${_CC_SESSIONS} --dir "resume:$1" 2>/dev/null)
	print -r -- "${dir:-$PWD}"
}

# tmux restores the terminal to its pre-launch state on exit, wiping Claude's
# parting words along with everything else. Rather than replay that screen,
# say the one thing worth knowing: the session is over, and the picker will
# offer its transcript back the next time you run claude here. A session that
# merely detached is still alive, so it stays quiet.
_cc_ended() {
	tmux has-session -t "=$1" 2>/dev/null && return 0
	# The tmux client prints a bare "[exited]" as the session dies. Step back
	# over that line and reuse it, so the footer lands where the noise was.
	print -n $'\033[1A\033[2K\r'
	print
	print -r -- "  session ended · run claude in ${2/#$HOME/~} to pick it back up"
}

# Path to the session-list helper, resolved when this file is sourced.
_CC_SESSIONS=${0:A:h}/cc-sessions
_CC_PREVIEW=${0:A:h}/cc-preview
_CC_KILL=${0:A:h}/cc-kill

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
		--delimiter=$'\t' --with-nth=3.. --no-multi --ansi \
		--height=70% --layout=reverse --border=rounded \
		--prompt='claude ❯ ' \
		--header=$'enter resume   ctrl-n new   ctrl-x kill   esc cancel\nopen = steal it back from the other window   ended = resume the transcript' \
		--preview="CC_CWD=${(q)PWD} ${(q)_CC_PREVIEW} {1}" \
		--preview-window='right,50%,wrap,<150(down,55%,wrap)' \
		--bind='ctrl-n:become(echo __new__)' \
		--bind="ctrl-x:execute(${(q)_CC_KILL} {1})+reload($cmd)") || return 1

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
claude() {
	local -x CLAUDE_CONFIG_DIR CLAUDE_ACCOUNT_LABEL
	_cc_account "$PWD"

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

	local dir=$PWD
	local s=$(_cc_session)
	if (( $# == 0 )) && [[ -z $CC_NO_PICK ]]; then
		local pick
		pick=$(_cc_pick) || return 130          # esc / ctrl-c: do nothing
		if [[ $pick == resume:* ]]; then
			# No session left to attach to: start a fresh one on the transcript,
			# in the directory that conversation was held in.
			dir=$(_cc_resume_dir "${pick#resume:}")
			s=$(_cc_session "$dir")
			_cc_account "$dir"
			set -- --resume "${pick#resume:}"
		elif [[ -n $pick && $pick != __new__ ]]; then
			# A session open in another window has to be stolen; attaching a second
			# client would mirror it and force both windows to the smaller size.
			local steal=
			# A "=" exact-match target works for has-session and kill-session but
			# comes back empty from display, so match on the plain name.
			[[ $(tmux display -pt "$pick" '#{session_attached}') == 0 ]] || steal=-d
			tmux attach $steal -t "=$pick"
			local attach_status=$?
			_cc_ended "$pick" "$PWD"
			return $attach_status
		fi
	else
		# The picker reaps stale sessions as a side effect of listing them; when
		# it is skipped, do that in the background so it costs no startup time.
		(${_CC_SESSIONS} >/dev/null 2>&1 &) 2>/dev/null
	fi
	# An explicit --resume names a transcript that may have been recorded in
	# another project. Follow it: the directory, session name, and account all
	# come from where that conversation lives, not from wherever the command
	# happened to be typed. Without this, resuming a personal transcript from a
	# work directory opens it on the work account, which cannot read it.
	# Match on the uuid shape rather than a repetition pattern: extended globs
	# are not guaranteed to be on in the shell sourcing this file.
	if [[ ( $1 == --resume || $1 == -r ) && $2 == *-*-*-*-* ]]; then
		local rdir=$(_cc_resume_dir "$2")
		if [[ -n $rdir && $rdir != $dir ]]; then
			dir=$rdir
			s=$(_cc_session "$dir")
			_cc_account "$dir"
		fi
	fi

	# Attaching a second client to a live session mirrors it (and forces both
	# windows to the smaller size), so an attached session is never reused: take
	# the next free sibling name instead.
	local n=2
	while tmux has-session -t "=$s" 2>/dev/null; do
		s="$(_cc_session "$dir")-$n"
		(( n++ ))
	done
	# ${(q)a} inside quotes would join the array into ONE argument; ${(q)a[@]}
	# quotes each element and joins with spaces, which is what sh needs.
	local -a a=("$@")
	local run="claude --dangerously-skip-permissions ${(q)a[@]}"
	# -e explicitly: a new session's env otherwise comes from the tmux server,
	# which may predate this shell and carry the wrong account.
	tmux new-session -s "$s" -c "$dir" \
		-e "CLAUDE_CONFIG_DIR=$CLAUDE_CONFIG_DIR" \
		-e "CLAUDE_ACCOUNT_LABEL=$CLAUDE_ACCOUNT_LABEL" \
		"$run"
	# Not "status": zsh keeps that read-only as an alias for $?.
	local st=$?
	_cc_ended "$s" "$dir"
	return $st
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
