#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../tools/_all_tools.sh"
declare -r PACKAGE='vlc'

function check_exists
{
    if ! hash "$PACKAGE" &>/dev/null
    then
        return 1
    fi

    return 0
}

function main
{
    parse_opt "$@" || return "$?"

    if check_exists
    then
        return 0
    fi

    section "$PACKAGE"
    install_package "$PACKAGE" 'browser-plugin-vlc'
    success "$PACKAGE has been installed"
}

function display_software_version
{
    declare -n name="$1"
    declare -n version="$2"
    name="VLC"

    if ! hash "vlc" &>/dev/null
    then
        version="not installed"

        return 0
    fi

    version="$(vlc --version 2>/dev/null | grep "VLC version" | sed 's/VLC version \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/g')"

    return 0
}

main "$@"

