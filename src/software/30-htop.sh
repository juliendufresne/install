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
    parse_opt "$@" || return "$?"

    declare -r package_name="htop"
    if hash "$package_name" &>/dev/null
    then
        return 0
    fi

    declare -r output="$(mktemp)"

    install_package "$package_name" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while installing $package_name package"

        return 1
    }

    rm "$output"
}

main "$@"
