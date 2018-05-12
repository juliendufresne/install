#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../tools/_all_tools.sh"

function check_exists()
{
    if ! dpkg --get-selections| grep -q -E "gnome-tweak-tool\s*install"
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
    declare -r output="$(mktemp)"

    section "gnome-tweak-tool"

    install_package "gnome-tweak-tool" &>"$output" || {
        error_with_output_file "$output" "Unable to install gnome-tweak-tool package"

        return 1
    }

    rm "$output"
}

main

