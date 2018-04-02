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
    section "Handling dotfiles"

    note "dotfiles is the name of all hidden files (starting with a dot)" \
         "This script suppose that you have a repository for your common dotfiles (.zshrc, .vimrc, ...)"

    if ! [[ -d "$HOME/.files" ]]
    then
        cd "$HOME"

        if ! yes_no "Do you have a git repository for your dotfiles" "yes"
        then
            return 0
        fi

        clone_repo || return 0
    fi

    if [[ -f "$HOME/.files/install.sh" ]]
    then
        /usr/bin/env bash "$HOME/.files/install.sh"
    fi
}

function yes_no()
{
    declare -r question="$1"
    declare -r default="$2"
    declare -i tries=0
    declare    answer

    while true
    do
        let tries++
        if [[ "$(( tries % 10))" -eq 1 ]]
        then
            printf '\e[32m%s? (yes/no) \e[39m[\e[33m%s\e[39m]:\n' "$question" "$default"
        fi
        printf '> '

        read answer
        if [[ -z "$answer" ]]
        then
            answer="$default"
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

function clone_repo()
{
    declare url="git"

    printf "\e[32mWhat is the project's git provider?\e[39m\n"
    PS3='> '
    select provider in 'bitbucket' 'github' 'gitlab'
    do
        case "$provider" in
            bitbucket)
                url="$url@bitbucket.org"
                break
                ;;
            github)
                url="$url@github.com"
                break
                ;;
            gitlab)
                url="$url@gitlab.com"
                break
                ;;
            *)
                >&2 printf '\e[31mPlease chose the number corresponding to your provider\e[39m\n'
                ;;
        esac
    done

    printf "\e[32mOrganization or user\e[39m [\e[33mjuliendufresne\e[39m]:\n> "
    read -e organisation
    if [[ -z "$organisation" ]]
    then
        url="${url}:juliendufresne"
    else
        url="${url}:${organisation}"
    fi

    declare repo=""
    while [[ -z "$repo" ]]
    do
        printf "\e[32mRepository name (without .git)\e[39m:\n> "
        read -e repo
    done

    url="${url}/${repo}.git"

    note "Cloning $url into $HOME/.files"
    git clone --quiet "$url" $HOME/.files
}

main

