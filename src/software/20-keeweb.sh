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
    if ! hash 'KeeWeb' &>/dev/null
    then
        return 1
    fi

    return 0
}

function main()
{
    parse_opt "$@" || return "$?"

    if check_exists
    then
        return 0
    fi

    declare -r output="$(mktemp)"

    section "KeeWeb"

    install_package "curl" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while installing packages required to install KeeWeb:" \
              "- curl"

        return 1
    }

    declare -r folder="$(mktemp -d)"

    declare -r url="https://github.com/keeweb/keeweb/releases/download/v1.5.4/KeeWeb-1.5.4.linux.x64.deb"
    curl -fsSL -o "$folder/keeweb.deb" "$url" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while trying to download file at $url"

        return 1
    }

    sudo dpkg -i "$folder/keeweb.deb" &>"$output" || {

        sudo apt-get install --yes -f &>"$output" && sudo dpkg -i "$folder/keeweb.deb" &>"$output" || {
            error_with_output_file "$output" "Something went wrong while trying to install keeweb from deb file"
            rm -rf "$folder"

            return 1

        }
    }

    rm -rf "$folder"
    rm "$output"
}

main "$@"

