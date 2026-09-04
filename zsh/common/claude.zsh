export CLAUDE_CODE_NO_FLICKER=1

# A leftover `claude` alias (from an earlier source of this file) makes the
# function definitions below a parse error, so clear it first.
unalias claude 2>/dev/null

# Picks the account the same way claude() does: a one-shot question asked in a
# work directory has to answer on the work account, and a bare shell carries
# whatever CLAUDE_CONFIG_DIR it inherited — including none at all.
ch() {
	local -x CLAUDE_CONFIG_DIR CLAUDE_ACCOUNT_LABEL
	_cc_account "$PWD"
	command claude -p "Answer the following question - it may or may not be related to the currently open project & files. Answer very briefly, limiting your response to 1 or 2 lines. Don't add any code to the project. The question is: How do I $*"
}

# Pick the config dir (login, auth, history) for a directory. Work dirs get
# their own so the work account never bleeds into personal projects. The
# label is only cosmetic — the status line reads it to show which account is in
# use. Assigns to the caller's CLAUDE_CONFIG_DIR / CLAUDE_ACCOUNT_LABEL.

# Set the real values in the gitignored zsh/<platform>/local.zsh.
export CC_WORK_CONFIG="${CC_WORK_CONFIG:-$HOME/.claude-work}"
export CC_WORK_LABEL="${CC_WORK_LABEL:-Work}"

_cc_account() {
	case ${1:l} in
		${HOME:l}/work|${HOME:l}/work/*)
			CLAUDE_CONFIG_DIR=$CC_WORK_CONFIG
			CLAUDE_ACCOUNT_LABEL=$CC_WORK_LABEL ;;
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
_CC_LAYOUT=${0:A:h}/cc-layout
_CC_STATE=${0:A:h}/cc-state
_CC_NOTIFY=${0:A:h}/cc-notify

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

	# "open" means different things depending on where the picker runs: from a
	# bare terminal it steals the session away from the window holding it;
	# inside tmux it only moves this client.
	local open_hint='steal it back from the other window'
	[[ -n $TMUX ]] && open_hint='jump this window to it'
	local header=$'enter resume   ctrl-n new   ctrl-x kill   esc cancel\n'
	header+="open = $open_hint   ended = resume the transcript"
	# The dots are the only part of a row that says what the agent is doing
	# rather than where it lives, so name them.
	header+=$'\n\033[31m●\033[0m blocked   \033[33m●\033[0m working   \033[34m●\033[0m done, not looked at'

	local sel
	sel=$(print -rl -- "${rows[@]}" | fzf \
		--delimiter=$'\t' --with-nth=3.. --no-multi --ansi \
		--height=70% --layout=reverse --border=rounded \
		--prompt='claude ❯ ' \
		--header="$header" \
		--preview="CC_CWD=${(q)PWD} ${(q)_CC_PREVIEW} {1}" \
		--preview-window='right,50%,wrap,<150(down,55%,wrap)' \
		--bind='ctrl-n:become(echo __new__)' \
		--bind="ctrl-x:execute(${(q)_CC_KILL} {1})+reload($cmd)") || return 1

	print -r -- "${sel%%$'\t'*}"
}

# A GUI app launched from inside tmux passes TMUX and TMUX_PANE on to
# everything it spawns, so a brand-new terminal window can inherit them and
# claim to be inside tmux while owning no pane at all. AeroSpace restarted
# from a pane is the usual source: every Super+Enter after that opens a
# Ghostty whose shell carries the pane it was launched from. The in-tmux
# path then hands the session to whichever client that stale TMUX names --
# the window it came from -- and leaves the new one sitting at a prompt.
# A real pane's tty is this shell's tty; a borrowed one is somebody else's.
_cc_disown_stale_tmux() {
	[[ -n $TMUX ]] || return 0
	local pane_tty=$(tmux display -pt "${TMUX_PANE:-none}" '#{pane_tty}' 2>/dev/null)
	[[ $pane_tty == ${TTY:-$(tty)} ]] && return 0
	unset TMUX TMUX_PANE
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
# Inside tmux it behaves the same, except the client switches sessions rather
# than attaching, so the picker stands in for prefix+s and every session is a
# tmux session — no Ghostty split has to hold one.
#
# Every launch first reaps sessions untouched for CC_PURGE_DAYS days.
#
claude() {
	_cc_disown_stale_tmux
	local -x CLAUDE_CONFIG_DIR CLAUDE_ACCOUNT_LABEL
	_cc_account "$PWD"

	if [[ ! -o interactive ]] || ! command -v tmux >/dev/null; then
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
			# A row names one Claude, and one Claude is one pane: a session split
			# by cc-spawn holds two of them. Reduce the row to the session to open
			# and, when the row carries one, the pane to land the cursor on. A row
			# that is a bare session name has no pane to select.
			local psess=$pick ppane=
			if [[ $pick == pane:* ]]; then
				local key=${pick#pane:}
				psess=${key%%:*}
				ppane=${key##*.}
			fi
			# Opening a session counts as looking at it: one that finished
			# while you were elsewhere stops flagging itself for attention.
			${_CC_STATE} seen "${ppane:-$psess}" 2>/dev/null
			# Inside tmux, moving this client is the whole job. Attaching from
			# here would nest a client inside a session; switch-client walks over
			# instead. Whoever else holds it is sent away first, for the reason the
			# outside path steals: two clients mirror the session and both get
			# squeezed to the smaller size.
			if [[ -n $TMUX ]]; then
				if [[ $(tmux display -p '#{session_name}') == $psess ]]; then
					[[ -n $ppane ]] && tmux select-pane -t "$ppane" 2>/dev/null
					return 0
				fi
				tmux detach-client -s "=$psess" 2>/dev/null
				[[ -n $ppane ]] && tmux select-pane -t "$ppane" 2>/dev/null
				tmux switch-client -t "=$psess"
				return
			fi
			# A session open in another window has to be stolen; attaching a second
			# client would mirror it and force both windows to the smaller size.
			local steal=
			# A "=" exact-match target works for has-session and kill-session but
			# comes back empty from display, and a plain name PREFIX-matches: once
			# cc-foo-123456 exits, display resolves it to its sibling
			# cc-foo-123456-2 and the steal decision is read off the wrong session.
			# Match the name exactly out of the session list instead.
			local row=$(tmux ls -F $'#{session_name}\t#{session_attached}\t#{session_path}' 2>/dev/null |
				awk -F'\t' -v s="$psess" '$1 == s { print $2 "\t" $3; exit }')
			[[ ${row%%$'\t'*} == 0 ]] || steal=-d
			# The footer names where the session lives, not where it was picked
			# from: resuming one from another project told you to run claude in
			# this directory, where it does not exist.
			local pdir=${row#*$'\t'}
			[[ -n $pdir ]] || pdir=$PWD
			# Selection is session state, so it survives the attach that follows.
			[[ -n $ppane ]] && tmux select-pane -t "$ppane" 2>/dev/null
			tmux attach $steal -t "=$psess"
			local attach_status=$?
			_cc_ended "$psess" "$pdir"
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
	# sh gets this as one string, so each argument has to arrive separately
	# quoted. ${(q)a[@]} inside double quotes does NOT do that: it joins the
	# array first and then escapes the spaces between elements, so --resume
	# <uuid> reached claude as a single unknown flag and the session died on
	# startup. ${(@q)a} quotes element by element; (j: :) joins the result. The
	# ${a:+ } guard keeps an empty array from adding a stray '' argument.
	local -a a=("$@")
	local run="claude --dangerously-skip-permissions${a:+ ${(j: :)${(@q)a}}}"
	# -e explicitly: a new session's env otherwise comes from the tmux server,
	# which may predate this shell and carry the wrong account.
	# Inside tmux, build it detached and walk the client over: a foreground
	# new-session would nest one session inside another. The session this was
	# typed in stays alive behind you, one picker away.
	if [[ -n $TMUX ]]; then
		tmux new-session -d -s "$s" -c "$dir" \
			-e "CLAUDE_CONFIG_DIR=$CLAUDE_CONFIG_DIR" \
			-e "CLAUDE_ACCOUNT_LABEL=$CLAUDE_ACCOUNT_LABEL" \
			"$run" || return
		tmux switch-client -t "=$s"
		return
	fi

	tmux new-session -s "$s" -c "$dir" \
		-e "CLAUDE_CONFIG_DIR=$CLAUDE_CONFIG_DIR" \
		-e "CLAUDE_ACCOUNT_LABEL=$CLAUDE_ACCOUNT_LABEL" \
		"$run"
	# Not "status": zsh keeps that read-only as an alias for $?.
	local st=$?
	_cc_ended "$s" "$dir"
	return $st
}

# Save and restore a window full of Claude sessions:
#   cclay save [name]   cclay list   cclay restore <name>   cclay rm <name>
# Same stale-$TMUX guard as claude(): restore would otherwise switch the window
# the env was inherited from, and save would snapshot that window's session.
cclay() { _cc_disown_stale_tmux; ${_CC_LAYOUT} "$@" }

# List live claude sessions; with an argument, attach to the first match.
#   ccl -s <name>   steal it, detaching whatever window has it open
ccl() {
	# Without this, an inherited $TMUX makes tmux refuse the attach below as a
	# nested session.
	_cc_disown_stale_tmux
	local steal=
	[[ $1 == -s ]] && { steal=-d; shift }
	if [[ -n $1 ]]; then
		# Only cc-* sessions are ours; the bare listing matched anything.
		local t=$(tmux ls -F '#S' 2>/dev/null | grep '^cc-' | grep -m1 -- "$1")
		[[ -z $t ]] && { print -u2 "ccl: no session matching '$1'"; return 1 }
		tmux attach $steal -t "=$t"
		return
	fi
	tmux ls -F '#{session_name}	#{session_path}	(#{session_attached} attached)' 2>/dev/null | grep '^cc-'
}

# Agent state for the wrapped sessions — what each Claude is doing, rather than
# where it lives.
#
#   ccstate list                what every live session is doing
#   ccstate summary             the counts the tmux status line shows
#   ccwait <pane|session> done  block until it finishes (2 = it needs input)
ccstate() { ${_CC_STATE} "$@" }
ccwait()  { ${_CC_STATE} wait "$@" }

# Notifications: what they say, what they sound like, and — via a bundle built
# for the purpose — what icon they wear.
#
#   ccnotify install-app [ICON] [NAME]   own the icon and the sender name
#   ccnotify test [state]                fire one now
#   ccnotify config                      what every knob currently resolves to
ccnotify() { ${_CC_NOTIFY} "$@" }
