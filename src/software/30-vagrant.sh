#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../tools/_all_tools.sh"
declare -r LATEST_VERSION="$(curl -sSL https://releases.hashicorp.com/vagrant/ | grep -o "/vagrant/[0-9][0-9\.]*" | sed 's/\/vagrant\///g' | sort -rV | head -n 1)"

function check_exists
{
    if ! hash 'vagrant' &>/dev/null
    then
        return 1
    fi

    if [[ "$(vagrant --version | awk '{ print $2; }')" != "$LATEST_VERSION" ]]
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

    declare -r tmp_folder="$(mktemp --directory)"
    declare -r current_folder="$(pwd)"
    cd "$tmp_folder"

    declare -r output="$(mktemp)"
    declare -r url="https://releases.hashicorp.com/vagrant/${LATEST_VERSION}/vagrant_${LATEST_VERSION}_x86_64.deb"
    curl -sSL -o vagrant.deb "$url" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while trying to download file at $url"

        return 1
    }
    install_deb_file "vagrant.deb" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while installing vagrant.deb file (downloaded at $url)"

        return 1
    }
    vagrant plugin install vagrant-hostmanager vagrant-vbguest &>"$output" || {
        error_with_output_file "$output" "Something went wrong while installing vagrant plugins"
    }

    cd "$current_folder"
    rm --recursive "$tmp_folder"
}

function display_software_version
{
    declare -n name="$1"
    declare -n version="$2"
    name="vagrant"

    if ! hash "vagrant" &>/dev/null
    then
        version="not installed"

        return 0
    fi

    version="$(vagrant --version | awk '{ print $2; }')"

    return 0
}

main "$@"
