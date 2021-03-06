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
    if ! hash "google-chrome-stable" &>/dev/null
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

    ensure_user_is_in_sudoers || return "$?"

    declare -r output="$(mktemp)"
    install_package "apt-transport-https" "curl" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while installing the following packages" \
              "- apt-transport-https" \
              "- curl"

        return 1
    }
    
    declare -r src_list="/etc/apt/sources.list.d/google-chrome.list"
    declare -r line="deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main"

    curl -sSL https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - &>"$output" || {
        error_with_output_file "$output" "Something went wrong while adding google chrome apt key"

        return 1
    }

    printf "%s\n" "$line" | sudo tee "$src_list" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while generating google chrome apt source list"

        return 1
    }

    update_package_list &>"$output" || {
        error_with_output_file "$output" "Something went wrong while updating apt package list"

        return 1
    }

    install_package "google-chrome-stable" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while installing google-chrome-stable package"

        return 1
    }

    rm "$output"
}

function display_software_version()
{
    declare -n name="$1"
    declare -n version="$2"
    name="Google Chrome"

    if ! hash "google-chrome" &>/dev/null
    then
        version="not installed"

        return 0
    fi

    version="$(google-chrome --version | awk '{ print $3; }')"

    return 0
}

main "$@"

