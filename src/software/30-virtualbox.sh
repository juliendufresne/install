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

    declare -r package_name="htop"
    if hash "virtualbox" &>/dev/null
    then
        return 0
    fi

    ensure_user_is_in_sudoers || return "$?"

    declare release_distributor_id
    declare release_codename
    identify_release "release_distributor_id" "release_codename" || return "$?"

    declare -r output="$(mktemp)"
    install_package "curl" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while installing the following packages" \
              "- curl"

        return 1
    }

    curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo apt-key add - &>"$output" || {
        error_with_output_file "$output" "Something went wrong while adding VirtualBox apt key"

        return 1
    }

    printf "deb http://download.virtualbox.org/virtualbox/debian $release_codename contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list &>"$output" || {
        error_with_output_file "$output" "Something went wrong while generating VirtualBox apt source list"

        return 1
    }

    update_package_list &>"$output" || {
        error_with_output_file "$output" "Something went wrong while updating apt package list"

        return 1
    }
    install_package "dkms" "virtualbox-5.1" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while installing the following packages" \
              "dkms" \
              "virtualbox-5.1"

        return 1
    }

    declare -r version="$(VBoxManage -v)"
    declare -r var1="$(echo "$version" | cut -d 'r' -f 1)"
    declare -r var2="$(echo "$version" | cut -d 'r' -f 2)"
    declare -r file="Oracle_VM_VirtualBox_Extension_Pack-$var1-$var2.vbox-extpack"
    curl -sSL -o "/tmp/$file" "http://download.virtualbox.org/virtualbox/$var1/$file"
    echo "y" | sudo VBoxManage extpack install "/tmp/$file" --replace &>"$output" || {
        error_with_output_file "$output" "Something went wrong while installing VirtualBox extension pack"

        return 1
    }

    rm "/tmp/$file"

    return 0
}

function display_software_version
{
    declare -n name="$1"
    declare -n version="$2"
    name="VirtualBox"

    if ! hash "VBoxManage" &>/dev/null
    then
        version="not installed"

        return 0
    fi

    version="$(VBoxManage -v)"

    return 0
}

main "$@"
