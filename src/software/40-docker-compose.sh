#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../tools/_all_tools.sh"
declare -r LATEST_VERSION="$(curl -sSL https://github.com/docker/compose/releases/ | grep -o '/docker/compose/tree/[0-9][^"]*' | sed 's/\/docker\/compose\/tree\///g' | sort -rV | sed '/[^0-9\.]/d' | head -n 1)"

function check_exists()
{
    if ! hash "docker" &>/dev/null
    then
        return 1
    fi

    if ! hash "docker-compose" &>/dev/null
    then
        return 1
    fi

    if [[ "$(docker-compose version --short)" != "$LATEST_VERSION" ]]
    then
        return 1
    fi

    return 0
}

function main()
{
    parse_opt "$@" || return "$?"

    if check_exists
    then
        return 0
    fi

    if ! hash "docker" &>/dev/null
    then
        warning "docker-compose require docker to be installed"

        return 1
    fi

    ensure_user_is_in_sudoers || return "$?"

    declare -r docker_compose_bin_file="/usr/local/bin/docker-compose"

    declare -r output="$(mktemp)"
    declare -r url="https://github.com/docker/compose/releases/download/${LATEST_VERSION}/docker-compose-Linux-x86_64"
    sudo curl -sSL -o "$docker_compose_bin_file" "$url" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while trying to download file at $url"

        return 1
    }
    sudo chmod +x "$docker_compose_bin_file"

    if ! [[ -d $HOME/.zsh/completions ]]
    then
        mkdir --parents $HOME/.zsh/completions
    fi

    curl -sSL -o $HOME/.zsh/completions/_docker-compose https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/zsh/_docker-compose &>"$output" || {
        error_with_output_file "$output" "Something went wrong while trying to install docker-compose zsh completions"

        return 1
    }
    rm "$output"
}

function display_software_version()
{
    declare -n name="$1"
    declare -n version="$2"
    name="docker-compose"

    if ! hash "docker-compose" &>/dev/null
    then
        version="not installed"

        return 0
    fi

    version="$(docker-compose version --short)"

    return 0
}

main "$@"

