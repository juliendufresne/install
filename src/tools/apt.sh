#!/usr/bin/env bash

# this file is not compatible with package manager other than apt

function add_source_list()
{
    declare file="$1"
    declare need_add=false
    shift
    if [[ ${file:0:1} != "/" ]]
    then
        file="/etc/apt/sources.list.d/$file"
    fi

    if ! [[ -f "$file" ]]
    then
        sudo touch "$file"
    fi

    for line in "$@"
    do
        if ! grep -q "$line" "$file"
        then
            if ! ${need_add}
            then
                printf "Add sources list\n"
            fi
            need_add=true
            printf "%s\n" "$line" | sudo tee -a "$file" >/dev/null
        fi
    done

    if $need_add
    then
        update_package_list
    fi
}

function install_package()
{
    sudo apt-get install -qq --yes --allow-unauthenticated "$@"
}

function install_deb_file()
{
    for file in "$@"
    do
        sudo dpkg --install "$file"
    done
}

function purge_package()
{
    sudo apt-get --yes purge "$@"
    sudo apt-get --yes clean
    sudo apt-get --yes autoremove
}

function update_package_list()
{
    sudo apt-get update -qq
}

