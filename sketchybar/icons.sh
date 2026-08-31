#!/usr/bin/env bash
# App → glyph. Uses the Nerd Font you already have rather than pulling in
# sketchybar-app-font, so there's nothing extra to install and the map is one
# you can read and edit. Unknown apps fall back to a generic window.
#
#   app_icon "Ghostty"  ->  the terminal glyph
app_icon() {
  case "$1" in
    Ghostty|Terminal|iTerm2|kitty|Alacritty|WezTerm) printf '' ;;
    Safari)                                          printf '' ;;
    Firefox|"Firefox Developer Edition")             printf '' ;;
    "Google Chrome"|Chromium|Arc)                    printf '' ;;
    Zed|Code|VSCodium|"Visual Studio Code"|Cursor)   printf '' ;;
    Xcode)                                           printf '' ;;
    Slack)                                           printf '' ;;
    Discord)                                         printf '' ;;
    WhatsApp|Messages|Signal|Telegram)               printf '' ;;
    Mail|Spark|Superhuman)                           printf '' ;;
    Obsidian|Notes|Notion|Bear)                      printf '' ;;
    Finder)                                          printf '' ;;
    Music|Spotify)                                   printf '' ;;
    Photos|Preview|Figma|Sketch)                     printf '' ;;
    Calendar|Fantastical)                            printf '' ;;
    KeePassXC|1Password)                             printf '' ;;
    Steam)                                           printf '' ;;
    OBS|"OBS Studio")                                printf '' ;;
    Docker|OrbStack)                                 printf '' ;;
    "System Settings"|"System Preferences")          printf '' ;;
    TablePlus|Postico)                               printf '' ;;
    *)                                               printf '' ;;
  esac
}
