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
    declare -r current_script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    if ! hash 'ssh-keygen' &>/dev/null
    then
        return 0
    fi

    section "Generate SSH key"

    declare -r ssh_dir="$HOME/.ssh"

    for git_provider in 'bitbucket' 'github' 'gitlab'
    do
        if check_ssh_key_already_exists "$ssh_dir" "$git_provider"
        then
            continue
        fi

        if ! user_want_key
        then
            printf '\n'

            continue
        fi

        generate_ssh_key "$ssh_dir" "$git_provider"
    done

    return 0
}
readonly -f "main"

function check_ssh_key_already_exists()
{
    declare -r ssh_dir="$1"
    declare -r private_key="$2"
    declare -r check_ok="\e[32m\xE2\x9C\x94\e[39m"
    declare -r check_fail="\e[31m\xE2\x9C\x98\e[39m"

    if [[ -f "$ssh_dir/$private_key" ]]
    then
        printf "  \e[32m\xE2\x9C\x94\e[39m ssh key for \e[32m%s\e[39m already exists\n" "$private_key"

        return 0
    fi

    printf "  \e[31m\xE2\x9C\x98\e[39m ssh key for \e[32m%s\e[39m does not exists\n\n" "$private_key"

    return 1
}

function user_want_key()
{
    declare -i tries=0
    declare answer
    while true
    do
        if [[ "$(( tries % 10))" -eq 0 ]]
        then
            printf '\e[32mDo you want to generate one? (yes/no) \e[39m[\e[33myes\e[39m]:\n'
        fi
        printf '> '
        let tries++

        read answer
        if [[ -z "$answer" ]]
        then
            answer='yes'
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
                printf '\e[33m Valid answers are: yes or no\e[39m\n'
            ;;
        esac
    done
}

function generate_ssh_key()
{
    declare -r ssh_dir="$1"
    declare -r provider="$2"

    printf "\e[32mEnter passphrase (empty for no passphrase)\e[39m:\n> "
    declare passphrase=""
    read -s passphrase

    ssh-keygen -q -t rsa -b 4096 -N "$passphrase" -f "$HOME/.ssh/$git_provider"

    chmod 0600 "$ssh_dir/$git_provider" "$ssh_dir/$git_provider.pub"

    note "Please add the following SSH KEY to $git_provider"
    open_browser_for_provider "$provider"

    declare -r -i terminal_length="$(tput cols)"
    declare -r    pad="$(printf "%${terminal_length}s" | tr ' ' '-')"
    printf "%s\n" "$pad"
    cat "$HOME/.ssh/${provider}.pub"
    printf "%s\n" "$pad"

    printf "Press [ENTER] when you're ready"
    read one_char
    verify_provider_reachable "$provider"
}

function open_browser_for_provider()
{
    declare -r provider="$1"
    declare    url=""

    case "$provider" in
        bitbucket)
            url="https://bitbucket.org/"
        ;;
        github)
            url="https://github.com/settings/keys"
        ;;
        gitlab)
            url="https://gitlab.com/profile/keys"
        ;;
    esac
    if ! hash 'xdg-open' &>/dev/null || ! xdg-open "$url" &>/dev/null
    then
        printf 'Url: %s\n' "$url"
    fi
}

function verify_provider_reachable()
{
    declare -r provider="$1"
    declare    server=""

    note "Check that $provider provider is reachable over ssh"

    case "$provider" in
        bitbucket)
            server="git@bitbucket.org"
        ;;
        github)
            server="git@github.com"
        ;;
        gitlab)
            server="git@gitlab.com"
        ;;
    esac

    ssh -T "$server"

    printf "\n  \e[32m\xE2\x9C\x94\e[39m ssh key for \e[32m%s\e[39m is now created\n\n" "$provider"
}

main
