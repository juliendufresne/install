#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../tools/_all_tools.sh"
declare -r PACKAGE='docker'

function check_exists()
{
    if ! hash "$PACKAGE" &>/dev/null
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

    ensure_user_is_in_sudoers || return "$?"

    declare -r apt_source_list="/etc/apt/sources.list.d/docker.list"
    declare release_distributor_id
    declare release_codename
    identify_release "release_distributor_id" "release_codename" || return "$?"

    declare -r output="$(mktemp)"
    declare gpg_key_url
    declare apt_source_list_content

    case "$release_distributor_id" in
        "ubuntu")
            if [[ "$release_codename" = "trusty" ]]
            then
                install_package "linux-image-extra-$(uname -r)" "linux-image-extra-virtual" &>"$output" || {
                    error_with_output_file "$output" "Something went wrong while installing the following packages" \
                          "- linux-image-extra-$(uname -r)" \
                          "- linux-image-extra-virtual"

                    return 1
                }
            fi

            case "$release_codename" in
                "trusty"|"xenial"|"yakkety"|"zesty"|"artful")
                    install_package "apt-transport-https" "ca-certificates" "curl" "software-properties-common" &>"$output" || {
                        error_with_output_file "$output" "Something went wrong while installing the following packages" \
                              "- apt-transport-https" \
                              "- ca-certificates" \
                              "- curl" \
                              "- software-properties-common"

                        return 1
                    }

                    gpg_key_url="https://download.docker.com/linux/ubuntu/gpg"
                    apt_source_list_content="deb [arch=amd64] https://download.docker.com/linux/ubuntu $release_codename stable"
                    ;;
                *)
                    error "This version of ubuntu is not compatible with docker"
                    rm "$output"
                    return 1
                    ;;
            esac
            ;;
        "debian")
            case "$release_codename" in
                "jessie"|"stretch")
                    install_package "apt-transport-https" "ca-certificates" "curl" "gnupg2" "software-properties-common" &>"$output" || {
                        error_with_output_file "$output" "Something went wrong while installing the following packages" \
                              "- apt-transport-https" \
                              "- ca-certificates" \
                              "- curl" \
                              "- gnupg2" \
                              "- software-properties-common"

                        return 1
                    }

                    gpg_key_url="https://download.docker.com/linux/debian/gpg"
                    apt_source_list_content="deb [arch=amd64] https://download.docker.com/linux/debian $release_codename stable"
                    ;;
                *)
                    error "This version of debian is not compatible with docker"
                    rm "$output"

                    return 1
                    ;;
            esac
            ;;
    esac

    curl -fsSL "$gpg_key_url" | sudo apt-key add - &>"$output" || {
        error_with_output_file "$output" "Something went wrong while adding docker apt key"

        return 1
    }

    printf "%s\n" "$apt_source_list_content" | sudo tee "$apt_source_list" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while generating docker apt source list"

        return 1
    }

    update_package_list &>"$output" || {
        error_with_output_file "$output" "Something went wrong while updating apt package list"

        return 1
    }

    install_package "docker-ce" &>"$output" || {
        error_with_output_file "$output" "Something went wrong while installing docker-ce package"

        return 1
    }

    sudo usermod -aG docker "$(whoami)" &>"$output" || {
        warning "Unable to add you to the docker group." "You won't be able to run docker without super user privileged."
    }

    rm "$output"
}

function display_software_version()
{
    declare -n name="$1"
    declare -n version="$2"
    name="Docker"

    if ! hash "docker" &>/dev/null
    then
        version="not installed"

        return 0
    fi

    version="$(docker --version | awk '{ print $3; }'|sed 's/,//')"

    return 0
}

main "$@"

