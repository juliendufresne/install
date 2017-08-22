#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../tools/_all_tools.sh"

function main
{
    if ! [[ -f /usr/share/applications/defaults.list ]]
    then
        return 0
    fi
    declare -r file="$(mktemp)"

    note "Setting default applications"

    sed 's/org.gnome.Totem/vlc/g' /usr/share/applications/defaults.list > "$file"
    sed -i 's/^\(text.*=\)libreoffice-calc.desktop/\1sublime_text.desktop/g' "$file"
    sed -i 's/firefox.desktop/google-chrome.desktop/g' "$file"

    sudo mv "$file" /usr/share/applications/defaults.list
    sudo chmod 0644 /usr/share/applications/defaults.list
    sudo sed -i 's/MimeType=//' /usr/share/applications/vim.desktop
}

main
