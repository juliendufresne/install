#!/usr/bin/env bash

function ensure_user_is_in_sudoers
{
    [[ -v USER ]] || USER="$(whoami)"

    if [[ "$USER" = "root" ]]
    then
        error "You should not run this script as root."

        return 1
    fi

    if ! hash "sudo" &>/dev/null
    then
        error "It appears you don't have sudo on your system." "You need to run the following command first:" "su -c ./sudo"

    	return 1
    fi

    if ! sudo -l -U "$USER" &>/dev/null
    then
        error "It appears you are not in the sudoers." "You need to run the following command first:" "su -c ./sudo"

    	return 1
    fi

    return 0
}
