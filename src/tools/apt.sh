#!/usr/bin/env bash

# this file is not compatible with package manager other than apt

function install_package
{
    sudo apt-get install -qq --yes --allow-unauthenticated "$@"
}

function install_deb_file
{
    for file in "$@"
    do
        sudo dpkg --install "$file"
    done
}

function purge_package
{
    sudo apt-get --yes purge "$@"
    sudo apt-get --yes clean
    sudo apt-get --yes autoremove
}

function update_package_list
{
    sudo apt-get update -qq
}
