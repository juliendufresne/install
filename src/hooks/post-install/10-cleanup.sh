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
    parse_opt "$@" || return "$?"

    declare release_distributor_id
    declare release_codename
    identify_release "release_distributor_id" "release_codename" || return "$?"

    note "Remove unused applications"

    declare -r output="$(mktemp)"
    case "$release_distributor_id" in
        "ubuntu")
            purge_package \
                        aisleriot \
                        gedit \
                        gnome-mahjongg \
                        gnome-mines \
                        gnome-sudoku \
                        gnome-terminal \
                        libreoffice* \
                        nano \
                        thunderbird \
                        totem \
                        transmission-common \
                        transmission-gtk &>"$output" || {
                error "Something went wrong while purging some packages"

                printf >&2 'Following is the output of the command\n'
                printf >&2 '######################################\n'
                cat "$output" >&2
                rm "$output"

                return 1
            }
            ;;
        "debian")
            purge_package \
                        empathy \
                        evolution \
                        evince \
                        five-or-more \
                        four-in-a-row \
                        gedit \
                        gnome-chess \
                        gnome-games \
                        gnome-klotski \
                        gnome-mahjongg \
                        gnome-mines \
                        gnome-nibbles \
                        gnome-sudoku \
                        gnome-terminal \
                        libreoffice* \
                        nano \
                        thunderbird \
                        totem \
                        transmission-common \
                        transmission-gtk &>"$output" || {
                error "Something went wrong while purging some packages"

                printf >&2 'Following is the output of the command\n'
                printf >&2 '######################################\n'
                cat "$output" >&2
                rm "$output"

                return 1
            }
            ;;
    esac

    rm "$output"
}

main
