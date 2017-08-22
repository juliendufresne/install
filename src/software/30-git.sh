#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../tools/_all_tools.sh"
declare -r LATEST_VERSION="$(curl -sSL https://www.kernel.org/pub/software/scm/git/ | grep --only-matching "git-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*.tar.gz" | sort -rV | head -n 1 | sed -e 's/^git-//' -e 's/\.tar\.gz$//')"

function check_exists
{
    if ! hash 'git' &>/dev/null
    then
        return 1
    fi

    if [[ "$(git --version | awk '{ print $3 }')" != "$LATEST_VERSION" ]]
    then
        return 1
    fi

    return 0
}

function main
{
    parse_opt "$@" || return "$?"

    if check_exists
    then
        return 0
    fi

    ensure_user_is_in_sudoers || return "$?"
    declare -r output="$(mktemp)"

    install_package "make" "libssl-dev" "libcurl4-openssl-dev" "zlib1g-dev" "libexpat1-dev" "gettext" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while installing the following packages" \
              "- make" \
              "- libssl-dev" \
              "- libcurl4-openssl-dev" \
              "- zlib1g-dev" \
              "- libexpat1-dev" \
              "- gettextl"

        return 1
    }

    if sudo dpkg -s git &>/dev/null
    then
        purge_package "git" &>"$output" || {
            error_with_output_file "$output" "Something went wrong while removing git from apt repository"
            # do not stop even if it fails
        }
    fi

    declare -r tmp_folder="$(mktemp --directory)"
    declare -r current_folder="$(pwd)"
    cd "$tmp_folder"

    declare -r url="https://www.kernel.org/pub/software/scm/git/git-${LATEST_VERSION}.tar.gz"
    curl -sSL -o git.tar.gz "$url" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while trying to download file at $url"

        return 1
    }
    tar xzf git.tar.gz &>"$output" || {
        error_with_output_file "$output" "Something went wrong while extracting archive downloaded at $url"

        return 1
    }
    cd git-* &>"$output" || {
        error_with_output_file "$output" "The extracted archive downloaded at $url does not contain a git-* folder"

        return 1
    }

    make prefix=/usr/local all &>"$output" || {
        error_with_output_file "$output" "Something went wrong while running 'make prefix=/usr/local all'"

        return 1
    }
    sudo make prefix=/usr/local install &>"$output" || {
        error_with_output_file "$output" "Something went wrong while running 'sudo make prefix=/usr/local install'"

        return 1
    }

    cd "$current_folder"
    rm --recursive --force "$tmp_folder"
    rm "$output"
}

function display_software_version
{
    declare -n name="$1"
    declare -n version="$2"
    name="git"

    if ! hash "git" &>/dev/null
    then
        version="not installed"

        return 0
    fi

    version="$(git --version | awk '{ print $3 }')"

    return 0
}

main "$@"
