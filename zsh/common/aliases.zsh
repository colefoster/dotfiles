# ──────────────────────────────────────────────
# General
# ──────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias rl='source ~/.zshrc'
alias hosts='sudo vim /etc/hosts'
alias ports='lsof -i -P -n | grep LISTEN'
alias mkd='mkdir -p'
alias path='echo $PATH | tr ":" "\n"'
alias week='date +%V'
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time command cat && date'

# ──────────────────────────────────────────────
# Modern CLI Replacements (only alias if installed)
# ──────────────────────────────────────────────

# eza (ls)
if command -v eza &>/dev/null; then
  alias ls='eza'
  alias ll='eza -la --git --icons'
  alias lt='eza -T --level=2 --icons'
  alias lta='eza -Ta --level=2 --icons'
fi

# bat (cat)
if command -v bat &>/dev/null; then
  alias cat='bat --paging=never'
  alias catp='bat --plain'
fi

# ripgrep (grep)
if command -v rg &>/dev/null; then
  alias rg='rg --smart-case'
  alias rgf='rg --files | rg'
fi

# fd (find)
if command -v fd &>/dev/null; then alias find='fd'; fi

# zoxide (cd)
if command -v zoxide &>/dev/null; then alias cd='z'; fi

# dust (du) / duf (df)
if command -v dust &>/dev/null; then alias du='dust'; fi
if command -v duf &>/dev/null; then alias df='duf'; fi

# procs (ps)
if command -v procs &>/dev/null; then alias ps='procs'; fi

# sd (sed)
if command -v sd &>/dev/null; then alias sed='sd'; fi

# difftastic (diff)
if command -v difft &>/dev/null; then alias diff='difft'; fi

# lazygit / lazydocker
if command -v lazygit &>/dev/null; then alias lg='lazygit'; fi
if command -v lazydocker &>/dev/null; then alias lzd='lazydocker'; fi

# glow (markdown)
if command -v glow &>/dev/null; then alias md='glow'; fi

# curlie (curl)
if command -v curlie &>/dev/null; then alias curl='curlie'; fi

# ──────────────────────────────────────────────
# fzf Workflows
# ──────────────────────────────────────────────
alias fcd='cd $(fd --type d | fzf)'
alias fe='$EDITOR $(fzf)'
alias gcof='git checkout $(git branch --all | fzf | tr -d "[:space:]")'
alias glf='git log --oneline | fzf --preview "git show {+1}"'

# ──────────────────────────────────────────────
# Git
# ──────────────────────────────────────────────
alias gs='git status'
alias gp='git push'
alias gl='git pull'
alias gc='git commit -m'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate -20'
alias nah='git reset --hard && git clean -df'
alias ga='git add'
alias gaa='git add --all'
alias gcam='git commit -am'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias grb='git rebase'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
alias gcp='git cherry-pick'
alias gbl='git blame'
alias gtag='git tag'
alias gcount='git shortlog -sn'
alias gwip='git add -A && git commit -m "wip"'
alias gunwip='git log -1 --pretty=%B | grep -q "wip" && git reset HEAD~1'

# ──────────────────────────────────────────────
# Laravel / PHP
# ──────────────────────────────────────────────
alias a='php artisan'
alias amt='php artisan migrate'
alias amf='php artisan migrate:fresh --seed'
alias mfs='php artisan migrate:fresh --seed'
alias arl='php artisan route:list'
alias at='php artisan test'
alias atf='php artisan test --filter'
alias tinker='php artisan tinker'
alias sail='./vendor/bin/sail'
alias s='./vendor/bin/sail'
alias saila='./vendor/bin/sail artisan'
alias sailc='./vendor/bin/sail composer'
alias smfs='sail artisan migrate:fresh --seed'
alias pest='./vendor/bin/pest'

alias sailrun="sail restart && \
	sleep 3 && \
	sail ps && \
	sailc install && \
	sail npm install && \
	saila cache:clear && \
	saila optimize:clear && \
	sailc run dev"

alias sailrunfresh="sail restart && \
	sleep 3 && \
	sail ps && \
	saila migrate:fresh && \
	sailc install && \
	sail npm install && \
	saila cache:clear && \
	saila optimize:clear && \
	sailc run dev"

# ──────────────────────────────────────────────
# Composer
# ──────────────────────────────────────────────
alias ci='composer install'
alias cu='composer update'
alias cr='composer require'
alias cda='composer dump-autoload'

# ──────────────────────────────────────────────
# npm / Node
# ──────────────────────────────────────────────
alias ni='npm install'
alias nd='npm run dev'
alias nb='npm run build'
alias nw='npm run watch'

# ──────────────────────────────────────────────
# Docker
# ──────────────────────────────────────────────
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dce='docker compose exec'
alias dcl='docker compose logs -f'
alias dcr='docker compose restart'
alias dcps='docker compose ps'
alias dcp='docker compose pull'
alias dcb='docker compose build'
alias dprune='docker system prune -af'
alias dvol='docker volume ls'
if command -v ctop &>/dev/null; then alias dtop='ctop'; fi
if command -v dive &>/dev/null; then alias ddive='dive'; fi

# ──────────────────────────────────────────────
# pnpm / bun
# ──────────────────────────────────────────────
alias pi='pnpm install'
alias pa='pnpm add'
alias pd='pnpm dev'
alias pb='pnpm build'
alias pr='pnpm run'
alias bi='bun install'
alias ba='bun add'
alias br='bun run'

# ──────────────────────────────────────────────
# Processes & System
# ──────────────────────────────────────────────
if command -v procs &>/dev/null; then alias psg='procs --search'; fi
alias kill9='kill -9'
if command -v tokei &>/dev/null; then alias loc='tokei'; fi
if command -v hyperfine &>/dev/null; then alias bench='hyperfine'; fi

# ──────────────────────────────────────────────
# Dev Tools
# ──────────────────────────────────────────────
if command -v mkcert &>/dev/null; then alias certs='mkcert -install'; fi
if command -v watchexec &>/dev/null; then alias watch='watchexec'; fi

# ──────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────
alias ping='ping -c 5'
if command -v curlie &>/dev/null; then alias headers='curlie -I'; alias wget='curlie -O'; fi
if command -v doggo &>/dev/null; then alias dig='doggo'; fi

# ──────────────────────────────────────────────
# Python
# ──────────────────────────────────────────────
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv .venv'
alias activate='source .venv/bin/activate'
alias pipreq='pip freeze > requirements.txt'
alias pipinstall='pip install -r requirements.txt'

# ──────────────────────────────────────────────
# SSH / Keys
# ──────────────────────────────────────────────
alias sshconfig='$EDITOR ~/.ssh/config'
alias sshkeys='ssh-add -l'
alias keygen='ssh-keygen -t ed25519 -C'

# ──────────────────────────────────────────────
# Tar / Archives
# ──────────────────────────────────────────────
alias tarc='tar -czvf'
alias tarx='tar -xzvf'
alias tarl='tar -tzvf'

# ──────────────────────────────────────────────
# neovim
# ──────────────────────────────────────────────
if command -v nvim &>/dev/null; then alias vim="nvim"; alias vi="nvim"; fi
