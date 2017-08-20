#!/usr/bin/env bash

function identify_release
{
    declare -n _distributor_id="$1"
    declare -n _codename="$2"

    if hash lsb_release &>/dev/null
    then
        _distributor_id="$(lsb_release --short --id | tr '[:upper:]' '[:lower:]')"
        _codename="$(lsb_release --short --codename | tr '[:upper:]' '[:lower:]')"

        return 0
    fi

    if [[ -f "/etc/os-release" ]]
    then
        . /etc/os-release
        _distributor_id="$(echo "$ID" | tr '[:upper:]' '[:lower:]')"
        if [[ -v VERSION_CODENAME ]]
        then
            _codename="$(echo "$VERSION_CODENAME" | tr '[:upper:]' '[:lower:]')"
        elif [[ -v VERSION ]]
        then
            _codename="$(echo "$VERSION" | sed -e 's/^.*(//g' -e 's/).*$//' | tr '[:upper:]' '[:lower:]')"
        else
            error "Unable to guess your OS release codename from /etc/os-release"

            return 1
        fi

        return 0
    fi

    error "Your operating system does not provide any known tools to guess its name and version."

    return 1
}
