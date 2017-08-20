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

    declare -r latest_version="$(curl -sSl https://slack.com/downloads/instructions/linux | grep -o "https://downloads.slack-edge.com/linux_releases/.*.deb" | grep -o 'slack-desktop-[0-9][0-9\.]*[0-9]' | grep -o '[0-9][0-9\.]*[0-9]' | head -n 1)"

    if hash "slack" &>/dev/null && [[ "$(slack --version 2>/dev/null)" = "$latest_version" ]]
    then
        return 0
    fi

    declare -r output="$(mktemp)"
    install_package "gconf2" "curl" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while installing the following packages" \
              "- gconf2" \
              "- curl"

        return 1
    }

    declare -r tmp_folder="$(mktemp -d)"

    cd "$tmp_folder"

    declare -r url="https://downloads.slack-edge.com/linux_releases/slack-desktop-${latest_version}-amd64.deb"
    curl -sSL -o slack.deb "$url" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while trying to download file at $url"

        return 1
    }

    install_deb_file slack.deb &>"$output" || {
        error_with_output_file "$output" "Something went wrong while installing slack.deb file (downloaded at $url)"

        return 1
    }

    cd "$OLDPWD"
    rm --recursive "$tmp_folder" "$output" || true
}

function display_software_version
{
    declare -n name="$1"
    declare -n version="$2"
    name="Slack"

    if ! hash "slack" &>/dev/null
    then
        version="not installed"

        return 0
    fi

    version="$(slack --version 2>/dev/null)"

    return 0
}

main "$@"
