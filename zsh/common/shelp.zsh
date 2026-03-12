# ──────────────────────────────────────────────
# Help / Cheatsheet
# ──────────────────────────────────────────────
_shelp_entries() {
  command cat <<'HELP'
GENERAL         ..              cd ..
GENERAL         ...             cd ../..
GENERAL         c               clear
GENERAL         rl              source ~/.zshrc
GENERAL         hosts           edit /etc/hosts
GENERAL         ports           show listening ports
GENERAL         ip              public IP address
GENERAL         localip         local IP address
GENERAL         copyssh         copy SSH pubkey
GENERAL         mkd             mkdir -p
GENERAL         path            print $PATH line by line
GENERAL         week            current week number
GENERAL         timer           simple stopwatch
GENERAL         cleanup         delete .DS_Store files
MODERN CLI      ls              eza
MODERN CLI      ll              eza -la --git --icons
MODERN CLI      lt              tree (2 levels)
MODERN CLI      lta             tree (2 levels, hidden)
MODERN CLI      cat             bat (no paging)
MODERN CLI      catp            bat (plain)
MODERN CLI      rg              ripgrep (smart-case)
MODERN CLI      rgf             ripgrep filenames
MODERN CLI      find            fd
MODERN CLI      cd              zoxide
MODERN CLI      du              dust (visual disk usage)
MODERN CLI      df              duf (disk free table)
MODERN CLI      ps              procs (modern ps)
MODERN CLI      sed             sd (simpler sed)
MODERN CLI      diff            difftastic (syntax-aware)
MODERN CLI      curl            curlie (httpie-style curl)
MODERN CLI      dig             doggo (modern DNS)
MODERN CLI      top             btop (interactive monitor)
MODERN CLI      md              glow (render markdown)
MODERN CLI      lg              lazygit
MODERN CLI      lzd             lazydocker
FZF             fcd             fuzzy cd into directory
FZF             fe              fuzzy open file in $EDITOR
FZF             gcof            fuzzy git checkout branch
FZF             glf             fuzzy git log with preview
GIT             gs              git status
GIT             gp              git push
GIT             gl              git pull
GIT             gc <msg>        git commit -m
GIT             gco             git checkout
GIT             gb              git branch
GIT             gd              git diff
GIT             glog            pretty log (20 entries)
GIT             ga              git add
GIT             gaa             git add --all
GIT             gcam <msg>      git commit -am
GIT             gca             git commit --amend
GIT             gcan            amend, no edit
GIT             gst             git stash
GIT             gstp            git stash pop
GIT             gstl            git stash list
GIT             grb             git rebase
GIT             grbc            rebase --continue
GIT             grba            rebase --abort
GIT             gcp             git cherry-pick
GIT             gbl             git blame
GIT             gtag            git tag
GIT             gcount          contributor count
GIT             gwip            stage all + commit "wip"
GIT             gunwip          undo last wip commit
GIT             nah             reset hard + clean
LARAVEL         a               php artisan
LARAVEL         amt             artisan migrate
LARAVEL         amf             migrate:fresh --seed
LARAVEL         arl             route:list
LARAVEL         at              artisan test
LARAVEL         atf             test --filter
LARAVEL         tinker          artisan tinker
LARAVEL         sail / s        ./vendor/bin/sail
LARAVEL         saila           sail artisan
LARAVEL         sailc           sail composer
LARAVEL         sailrun         restart + install + clear + dev
LARAVEL         sailrunfresh    sailrun + migrate:fresh
LARAVEL         pest            ./vendor/bin/pest
COMPOSER        ci              composer install
COMPOSER        cu              composer update
COMPOSER        cr              composer require
COMPOSER        cda             dump-autoload
NPM             ni              npm install
NPM             nd              npm run dev
NPM             nb              npm run build
NPM             nw              npm run watch
PNPM/BUN        pi              pnpm install
PNPM/BUN        pa              pnpm add
PNPM/BUN        pd              pnpm dev
PNPM/BUN        pb              pnpm build
PNPM/BUN        pr              pnpm run
PNPM/BUN        bi              bun install
PNPM/BUN        ba              bun add
PNPM/BUN        br              bun run
DOCKER          dc              docker compose
DOCKER          dcu             compose up -d
DOCKER          dcd             compose down
DOCKER          dce             compose exec
DOCKER          dcl             compose logs -f
DOCKER          dcr             compose restart
DOCKER          dcps            compose ps
DOCKER          dcp             compose pull
DOCKER          dcb             compose build
DOCKER          dprune          prune all unused
DOCKER          dvol            list volumes
DOCKER          dtop            ctop (container top)
DOCKER          ddive <img>     dive (inspect image layers)
SYSTEM          psg <name>      search processes (procs)
SYSTEM          kill9 <pid>     kill -9
SYSTEM          top             btop interactive monitor
SYSTEM          loc             tokei (count lines of code)
SYSTEM          bench <cmd>     hyperfine (benchmark commands)
SYSTEM          bw              bandwhich (network usage)
NETWORK         localip         local IP address
NETWORK         ports           listening ports
NETWORK         flushdns        flush DNS cache
NETWORK         ping            ping (5 packets)
NETWORK         headers <url>   HTTP headers only
NETWORK         wget <url>      curl -O
NETWORK         dig             doggo (DNS lookup)
NETWORK         bw              bandwhich (who's using bandwidth)
PYTHON          py              python3
PYTHON          pip             pip3
PYTHON          venv            create .venv
PYTHON          activate        activate .venv
PYTHON          pipreq          freeze > requirements.txt
PYTHON          pipinstall      install from requirements.txt
HOMEBREW        brewup          update + upgrade + cleanup (macOS)
HOMEBREW        brewls          brew list (macOS)
HOMEBREW        brewsr          brew search (macOS)
HOMEBREW        brewinfo        brew info (macOS)
SSH             sshconfig       edit SSH config
SSH             sshkeys         list loaded keys
SSH             keygen <email>  new ed25519 key
SSH             copyssh         copy pubkey to clipboard
DEV TOOLS       certs           install local HTTPS certs
DEV TOOLS       watch <cmd>     watchexec (run on file change)
ARCHIVES        tarc            tar create .tar.gz
ARCHIVES        tarx            tar extract .tar.gz
ARCHIVES        tarl            tar list contents
ARCHIVES        extract <file>  auto-extract any archive
FUNCTIONS       mkcd <dir>      mkdir + cd
FUNCTIONS       serve [port]    HTTP server (default 8000)
FUNCTIONS       gcm <msg>       git add all + commit
FUNCTIONS       whats-on <p>    what's using port p
FUNCTIONS       note <text>     append timestamped note
FUNCTIONS       weather [loc]   terminal weather
FUNCTIONS       jsonp           pretty-print JSON from clipboard
FUNCTIONS       ddiff <a> <b>   diff with delta
FUNCTIONS       shelp [term]    this help (filterable)
FUNCTIONS       readme          view project README
FUNCTIONS       todo [dir]      find TODOs/FIXMEs in codebase
FUNCTIONS       deps            show project dependencies
FUNCTIONS       gopen           open repo in browser
FUNCTIONS       gpr             open PR creation page
FUNCTIONS       envs [term]     search environment variables
FUNCTIONS       portfree <p>    kill process on port p
FUNCTIONS       jwt             decode JWT from clipboard
FUNCTIONS       urlencode <s>   URL encode string
FUNCTIONS       urldecode <s>   URL decode string
FUNCTIONS       cheat <query>   cheatsheet from cheat.sh (multi-word ok)
FUNCTIONS       shelpf          fuzzy search this help
HELP
}

# Parse a help line: "SECTION         cmd             description"
_shelp_parse() {
  local line="$1" field="$2"
  case "$field" in
    section) echo "$line" | command sed 's/  .*//' ;;
    cmd)     echo "$line" | command sed 's/^[^ ]*  *//' | command sed 's/  .*//' ;;
    desc)    echo "$line" | command sed 's/^[^ ]*  *[^ ]*  *//' ;;
  esac
}

# Static printed help: shelp [filter]
shelp() {
  local cyan='\033[0;36m'
  local dim='\033[2m'
  local yellow='\033[1;33m'
  local green='\033[0;32m'
  local reset='\033[0m'
  local filter="${1:-}"

  if [[ -n "$filter" ]]; then
    echo ""
    echo -e "${yellow}shelp results for: ${green}${filter}${reset}"
    echo -e "${dim}──────────────────────────────────────${reset}"
    _shelp_entries | grep -i --color=never "$filter" | while IFS= read -r line; do
      local section=$(_shelp_parse "$line" section)
      local cmd=$(_shelp_parse "$line" cmd)
      local desc=$(_shelp_parse "$line" desc)
      printf "  ${dim}%-12s${reset} ${cyan}%-16s${reset} %s\n" "$section" "$cmd" "$desc"
    done
    echo ""
  else
    local last_section=""
    echo ""
    _shelp_entries | while IFS= read -r line; do
      local section=$(_shelp_parse "$line" section)
      local cmd=$(_shelp_parse "$line" cmd)
      local desc=$(_shelp_parse "$line" desc)
      if [[ "$section" != "$last_section" ]]; then
        [[ -n "$last_section" ]] && echo ""
        echo -e "${yellow}${section}${reset}"
        echo -e "${dim}──────────────────────────────────────${reset}"
        last_section="$section"
      fi
      printf "  ${cyan}%-16s${reset} %s\n" "$cmd" "$desc"
    done
    echo ""
    echo -e "${dim}Tip: shelp <term> to filter, or shelpf for fuzzy search${reset}"
    echo ""
  fi
}

# Fuzzy interactive help: shelpf
shelpf() {
  local line
  line=$(_shelp_entries | \
    fzf --no-sort \
        --header 'Shell Tools — fuzzy search, Enter to copy command' \
        --prompt '> ' \
        --color='header:yellow,prompt:green')

  if [[ -n "$line" ]]; then
    local cmd=$(_shelp_parse "$line" cmd)
    local clean="${cmd%% <*}"
    clean="${clean%% \[*}"
    # Use platform clipboard command
    echo -n "$clean" | ${DOTFILES_COPY_CMD:-pbcopy}
    local desc=$(_shelp_parse "$line" desc)
    echo "Copied: $clean  —  $desc"
  fi
}
