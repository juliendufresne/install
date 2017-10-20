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
    for package in 'openssh-client' 'openssh-server'
    do
        if ! dpkg -s "$package" &>/dev/null
        then
            return 1
        fi
    done

    return 0
}

function main()
{
    parse_opt "$@" || return "$?"

    if check_exists
    then
        return 0
    fi

    install_package 'openssh-client' 'openssh-server'

    declare -r ssh_folder="${HOME}/.ssh"

    if ! [[ -d "$ssh_folder" ]]
    then
        mkdir --parents "$ssh_folder"
        chmod 0700 "$ssh_folder"
    fi
}

main "$@"

