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
    handle_dotfiles
    post_handle
}

function handle_dotfiles
{
    section "Handling dotfiles"

    note "dotfiles is the name of all hidden files (starting with a dot)" \
         "This script suppose that you have a repository for your common dotfiles (.zshrc, .vimrc, ...)"

    declare -r current_dir="$(pwd)"
    declare -r phpstorm_dir=".PhpStorm2018.1"

    if ! [[ -d "$HOME/.files" ]]
    then
        cd "$HOME"

        if ! yes_no "Do you have a git repository for your dotfiles" "yes"
        then
            return 0
        fi

        clone_repo
    fi

    if ! [[ -d "$HOME/.files" ]]
    then
        return 0
    fi

    cd "$HOME/.files"

    link .config/filezilla/sitemanager.xml || return_code="$?"
    link .config/terminator/config || return_code="$?"
    link .gitconfig || return_code="$?"
    link .gitignore_global || return_code="$?"
    link .mysql/workbench/connections.xml || return_code="$?"
    link .mysql/workbench/server_instances.xml || return_code="$?"
    link .mysql/workbench/snippets/DB_Management.txt || return_code="$?"
    link .mysql/workbench/snippets/SQL_DDL_Statements.txt || return_code="$?"
    link .mysql/workbench/snippets/SQL_DML_Statements.txt || return_code="$?"
    link "${phpstorm_dir}/config/disabled_plugins.txt" || return_code="$?"
    link "${phpstorm_dir}/config/fileTemplates" || return_code="$?"
    link "${phpstorm_dir}/config/plugins" || return_code="$?"

    for file in "$(ls -1 "${phpstorm_dir}/config/options")"
    do
        link "${phpstorm_dir}/config/options/${file}" || return_code="$?"
    done
    link .vim || return_code="$?"
    link .vimrc || return_code="$?"
    link .zsh || return_code="$?"
    link .zshrc || return_code="$?"

    cd "$current_dir"
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

function link()
{
    declare -r relative_path="$1"
    declare -r path_in_repo="$HOME/.files/$relative_path"
    declare path_in_home="$HOME/$relative_path"
    if [[ "$#" -gt 1 ]]
    then
        path_in_home="$HOME/$2"
    fi

    if ! [[ -e "$path_in_repo" ]]
    then
        return 1
    fi

    declare -r parent_directory="$(dirname "$path_in_home")"

    if [[ -n "$parent_directory" ]] && ! [[ -d "$parent_directory" ]]
    then
        mkdir --parents "$parent_directory"
    fi

    # Test if the file or symbolic link exists even if the target is broken:
    # -h return true
    # -e return false
    if [[ -h "$path_in_home" ]] || [[ -e "$path_in_home" ]]
    then
        rm --recursive "$path_in_home"
    fi

    ln --symbolic "$path_in_repo" "$path_in_home"

    return 0
}

function post_handle
{
    mkdir -p "$HOME/.vim/bundle"
    cd $_
    if ! [[ -d vim-fugitive ]]
    then
        git clone git://github.com/tpope/vim-fugitive.git
        vim -u NONE -c "helptags vim-fugitive/doc" -c q
    fi
}
main
