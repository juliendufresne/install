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

    install_package "openssh-client" "openssh-server"

    declare -r ssh_folder="${HOME}/.ssh"
    declare -r output_file="$(mktemp)"

    if ! [[ -d "$ssh_folder" ]]
    then
        mkdir --parents "$ssh_folder" &>"$output_file" || {
            declare -r -i return_code="$?"

            error_with_output_file "$output_file" "Something went wrong while creating $ssh_folder"

            return "$return_code"
        }
        rm "$output_file"
    fi

    declare passphrase=""
    for git_provider in 'bitbucket' 'github' 'gitlab'
    do
        generate_ssh_key "$git_provider"
    done
}

function generate_ssh_key()
{
    declare -r provider="$1"

    if [[ -f "$HOME/.ssh/$git_provider" ]] || ! ask_generate_a_key "$provider"
    then
        return 0
    fi

    printf "\e[32m Please provide a passphrase \e[39m]: "
    passphrase=""
    read -s passphrase

    if [[ -z "$passphrase" ]]
    then
        ssh-keygen -q -t rsa -b 4096 -f "$HOME/.ssh/$git_provider"
    else
        ssh-keygen -q -t rsa -b 4096 -N "$passphrase" -f "$HOME/.ssh/$git_provider"
    fi

    chmod 0600 "$HOME/.ssh/$git_provider" "$HOME/.ssh/$git_provider.pub"
    note "Please add the following SSH KEY to $git_provider"
    declare -r -i terminal_length="$(tput cols)"
    declare -r    pad="$(printf "%${terminal_length}s" | tr ' ' '-')"
    printf "%s\n" "$pad"
    cat "$HOME/.ssh/${provider}.pub"
    printf "%s\n" "$pad"

    printf "Press [ENTER] to continue"
    read one_char
}

function ask_generate_a_key()
{
    declare -r provider="$1"
    declare answer
    while true
    do
        printf "\e[32m Do you want to generate an ssh key for %s it? (yes/no) \e[39m[\e[33myes\e[39m]:\n > " "$provider"
        read answer
        if [[ -z "$answer" ]]
        then
            answer="yes"
        fi
        answer="$(tr '[:upper:]' '[:lower:]' <<<${answer})"

        case "$answer" in
            y|yes)
                return 0
            ;;
            n|no)
                return 1
            ;;
            *)
                printf "\e[33m Valid answers are: yes or no\e[39m\n\n"
            ;;
        esac
    done
}
main "$@"
