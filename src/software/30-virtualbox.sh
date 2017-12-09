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
    if ! hash "VBoxManage" &>/dev/null
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

    section "Virtualbox"

    ensure_user_is_in_sudoers || return "$?"

    declare release_distributor_id
    declare release_codename
    identify_release "release_distributor_id" "release_codename" || return "$?"

    install_package "curl"

    curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo apt-key add -

    # TODO remove this once virtualbox package is available in artful
    [[ "$release_codename" = "artful" ]] && release_codename="zesty"

    add_source_list "virtualbox.list" "deb http://download.virtualbox.org/virtualbox/debian $release_codename contrib"
    install_package "dkms" "virtualbox-5.2"

    printf "Add extension pack\n"
    declare -r version="$(VBoxManage -v)"
    declare -r var1="$(echo "$version" | cut -d 'r' -f 1)"
    declare -r var2="$(echo "$version" | cut -d 'r' -f 2)"
    declare -r file="Oracle_VM_VirtualBox_Extension_Pack-$var1-$var2.vbox-extpack"
    curl -sSL -o "/tmp/$file" "http://download.virtualbox.org/virtualbox/$var1/$file"
    echo "y" | sudo VBoxManage extpack install "/tmp/$file" --replace
    rm "/tmp/$file"

    return 0
}

function display_software_version()
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

