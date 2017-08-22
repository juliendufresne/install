#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../tools/_all_tools.sh"
declare -r LATEST_VERSION="$(curl -sSL "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release&build=&_=$(date +%s%N | cut -b1-13)" | grep -o "https://download.jetbrains.com/toolbox/jetbrains-toolbox-[0-9\.][0-9\.]*.tar.gz" | grep -o '[0-9][0-9\.]*[0-9]' | head -n 1)"

function check_exists
{
    if ! [[ -e "/opt/jetbrains-toolbox-$LATEST_VERSION" ]]
    then
        return 1
    fi

    return 0
}

function main
{
    parse_opt "$@" || return "$?"
    if check_exists
    then
        return 0
    fi

    ensure_user_is_in_sudoers || return "$?"

    declare -r output="$(mktemp)"
    declare -r symlink="JetBrains-ToolBox"

    # tricks: allow to watch more files than the default one
    printf "fs.inotify.max_user_watches = 524288\n" | sudo tee /etc/sysctl.d/jetbrains.conf &>"$output" && \
    sudo sysctl -p --system &>"$output" || {
        error_with_output_file "$output" "Something went wrong while trying to update sysctl in order to allow more watched files"
        # do not break even if it fails
    }

    declare -r tmp_folder="$(mktemp -d)"
    declare -r current_folder="$(pwd)"
    cd "$tmp_folder"

    declare -r url="https://download.jetbrains.com/toolbox/jetbrains-toolbox-${LATEST_VERSION}.tar.gz"
    curl -sSL -o jetbrains-toolbox.tar.gz "$url" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while trying to download file at $url"

        return 1
    }

    tar xzf jetbrains-toolbox.tar.gz &>"$output" || {
        error_with_output_file "$output" "Something went wrong while extracting archive downloaded at $url"

        return 1
    }

    sudo mkdir -p /opt &>"$output" && \
    sudo mv "jetbrains-toolbox-${LATEST_VERSION}" /opt &>"$output" && \
    cd /opt &>"$output" || {
        error_with_output_file "$output" "Something went wrong while trying to move extracted archive to /opt/"

        return 1
    }

    [[ -e "$symlink" ]] && sudo rm "$symlink"

    sudo ln -s jetbrains-toolbox-${LATEST_VERSION} "$symlink" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while trying to make the new version the current one"

        return 1
    }

    cd "/opt/$symlink"
    nohup ./jetbrains-toolbox &>/dev/null &

    user_instructions

    cd "$current_folder"
    rm --recursive "$tmp_folder"
    rm "$output"

}

function user_instructions
{
    note "Please install phpstorm from JetBrains-ToolBox"

    sleep 5
}

main "$@"
