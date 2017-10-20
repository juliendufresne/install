#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../tools/_all_tools.sh"
declare -r PACKAGE='zsh'

function check_exists()
{
    if ! [[ -d "$HOME/.oh-my-zsh" ]]
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
    hash "git" &>/dev/null || install_package "git" || {
        error_with_output_file "$output" "Something went wrong while installing git package"

        return 1
    }

    install_package "zsh" || {
        error_with_output_file "$output" "Something went wrong while installing zsh package"

        return 1
    }

    if [[ -f /etc/pam.d/chsh ]]
    then
        sudo sed -i 's/required/sufficient/g' /etc/pam.d/chsh || true
    fi

    declare -r tmp_folder="$(mktemp -d)"
    cd "$tmp_folder"

    declare -r url="https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh"
    curl -fsSL -o install.sh "$url" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while trying to download file at $url"

        return 1
    }

    sed -i 's/env zsh//g' install.sh &>"$output" && \
    chmod u+x install.sh &>"$output" && \
    sh install.sh &>"$output" || {
        error_with_output_file "$output" "Something went wrong while running script downloaded at $url"

        return 1
    }

    cd "$OLDPWD"
    rm --recursive "$tmp_folder"
    rm "$output"
}

main "$@"

