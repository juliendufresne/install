#!/usr/bin/env bash

function parse_opt
{
    while [[ "$#" -gt 0 ]]
    do
        declare key="$1"
        case "$key" in
            -v|--version)
                if type -t "display_software_version" | grep -q ^function$
                then
                    declare _name
                    declare _version
                    display_software_version "_name" "_version" || exit "$?"
                    printf "\e[0;34m %s \e[0;35m %s\e[0;39m\n" "$_name" "$_version"
                fi
                # end the script now
                exit 0
                ;;
            --exists)
                if type -t "check_exists" | grep -q ^function$
                then
                    check_exists
                    exit $?
                fi
                # end the script now
                exit 10
                ;;
        esac
        shift
    done
}
