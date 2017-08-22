#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../tools/_all_tools.sh"
declare -r PACKAGE='tree'

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
    install_package "$PACKAGE"
    success "$PACKAGE has been installed"
}

main "$@"
