#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../../tools/_all_tools.sh"

note "upgrade the system"

function upgrade_package
{
    ensure_user_is_in_sudoers
    update_package_list

    sudo apt-get -qq --yes --no-show-upgraded full-upgrade >/dev/null
}

upgrade_package
