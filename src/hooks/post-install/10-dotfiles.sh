#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../tools/_all_tools.sh"

function main
{
    handle_dotfiles
    post_handle
}

function handle_dotfiles
{
    section "Handling dotfiles"
    declare -r current_dir="$(pwd)"
    declare -r phpstorm_dir=".PhpStorm2017.2"

    if ! [[ -d "$HOME/.files" ]]
    then
        cd "$HOME"

        note "Please clone your dotfiles git repository in $HOME/.files"
        printf "
        git clone --quiet git@git_provider:username/files.git .files
"

        printf "Press [ENTER] when you're ready\n"
        read one_char
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

function link
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
