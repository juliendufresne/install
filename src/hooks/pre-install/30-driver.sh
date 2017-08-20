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
    declare manufacturer
    detect_graphic_card_manufacturer "manufacturer" || return "$?"
    declare package

    declare distributor_id
    declare codename

    identify_release "distributor_id" "codename"

    case "$manufacturer" in
        nvidia)

            for pattern in '^nvidia-[0-9][0-9\.]*\s' '^nvidia-current\s' '^nvidia-driver\s'
            do
                package="$(apt-cache search nvidia | grep -o "$pattern" | sed 's/\s//g' | sort -rV | head -n 1)"
                if [[ -n "$package" ]]
                then
                    break
                fi
            done

            if [[ -z "$package" ]]
            then
                error "unable to find an nvidia package for your distribution." \
                      "Did you activated other source list (contrib, non-free, multiverse, ...)"

                return 1
            fi

            if dpkg -s "$package" &>/dev/null
            then
                # already installed
                return 0
            fi

            install_package "$package"

            warning "Driver $package installed successfully. You should reboot."
            sleep 20
            ;;
        intel)
            ;;
    esac
}

function detect_graphic_card_manufacturer
{
    declare -n _manufacturer="$1"

    if ! hash "lspci" &>/dev/null
    then
        error "Unable to guess your graphic card manufacturer: lspci module does not exists"

        return 1
    fi

    if lspci -nnk | egrep -iA3 "VGA" | grep -q -i "NVIDIA"
    then
        _manufacturer="nvidia"

        return 0
    fi

    if lspci -nnk | egrep -iA3 "VGA" | grep -q -i "intel"
    then
        _manufacturer="intel"

        return 0
    fi

    error "Unknown graphic card manufacturer. You can determine it from this line:"
    lspci -nnk | egrep -iA3 "VGA"

    return 1
}

main
