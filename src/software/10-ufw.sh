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
    if ! which 'ufw' &>/dev/null
    then
        return 1
    fi

    return 0
}

function main
{
    parse_opt "$@" || return "$?"

    declare -r output="$(mktemp)"

    section "Firewall"

    if ! check_exists
    then
        install_package "ufw" &>"$output" || {
            error_with_output_file "$output" "Unable to install ufw package"

            return 1
        }
    fi

    if sudo ufw status | grep -q "Status: inactive"
    then
        sudo ufw enable &>"$output" || {
            error_with_output_file "$output" "Unable to enable firewall"

            return 1
        }
    fi

    rm "$output"
}

main

