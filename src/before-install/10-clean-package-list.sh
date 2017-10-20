#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../tools/_all_tools.sh"

function clean_package_list()
{
    ensure_user_is_in_sudoers

    declare release_distributor_id
    declare release_codename
    declare -r tmp="$(mktemp)"

    identify_release "release_distributor_id" "release_codename" || return "$?"
    case "$release_distributor_id" in
        debian)
            printf "
deb http://ftp.fr.debian.org/debian/ ${release_codename} main
deb http://ftp.fr.debian.org/debian/ ${release_codename} contrib
deb http://ftp.fr.debian.org/debian/ ${release_codename} non-free

deb http://ftp.fr.debian.org/debian/ ${release_codename}-updates main
deb http://ftp.fr.debian.org/debian/ ${release_codename}-updates contrib
deb http://ftp.fr.debian.org/debian/ ${release_codename}-updates non-free

deb http://security.debian.org/debian-security ${release_codename}/updates main
deb http://security.debian.org/debian-security ${release_codename}/updates contrib
" > "$tmp"
            ;;
        ubuntu)
            printf "
deb http://fr.archive.ubuntu.com/ubuntu/ ${release_codename} main
deb http://fr.archive.ubuntu.com/ubuntu/ ${release_codename} restricted
deb http://fr.archive.ubuntu.com/ubuntu/ ${release_codename} universe
deb http://fr.archive.ubuntu.com/ubuntu/ ${release_codename} multiverse

deb http://fr.archive.ubuntu.com/ubuntu/ ${release_codename}-updates main
deb http://fr.archive.ubuntu.com/ubuntu/ ${release_codename}-updates restricted
deb http://fr.archive.ubuntu.com/ubuntu/ ${release_codename}-updates universe
deb http://fr.archive.ubuntu.com/ubuntu/ ${release_codename}-updates multiverse

deb http://fr.archive.ubuntu.com/ubuntu/ ${release_codename}-backports main
deb http://fr.archive.ubuntu.com/ubuntu/ ${release_codename}-backports restricted
deb http://fr.archive.ubuntu.com/ubuntu/ ${release_codename}-backports universe
deb http://fr.archive.ubuntu.com/ubuntu/ ${release_codename}-backports multiverse

deb http://security.archive.ubuntu.com/ubuntu ${release_codename}-security main
deb http://security.archive.ubuntu.com/ubuntu ${release_codename}-security restricted
deb http://security.archive.ubuntu.com/ubuntu ${release_codename}-security universe
deb http://security.archive.ubuntu.com/ubuntu ${release_codename}-security multiverse
" > "$tmp"
            ;;
        *)
            error "This install is not compatible with your distribution '$release_distributor_id'"
            return 1
            ;;
    esac

    declare -r file="/etc/apt/sources.list"
    sudo mv "$tmp" "$file"
    sudo chown root:root "$file"
    sudo chmod 0664 "$file"

}

section 'Clean package list'
clean_package_list
sudo apt-get update
success 'package list cleaned'

section 'Upgrade the system'
sudo apt-get --yes --no-show-upgraded full-upgrade
success 'System upgraded to latest software version'

