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
    section "Generate gpg key"

    ask_generate_a_key || return 0

    declare -r tmp="$(mktemp)"
    printf "\e[32m Real name\e[39m\n > "
    read -e real_name
    printf "\e[32m Email address\e[39m\n > "
    read -e email
    printf "\e[32m Passphrase\e[39m\n > "
    read -e -s passphrase
       
    cat >"$tmp" <<EOF
Key-Type: RSA
Key-Length: 4096
Key-Usage: sign
Subkey-Type: RSA
Subkey-Length: 4096
Subkey-Usage: sign
Name-Real: $real_name
Name-Email: $email
Expire-Date: 0
Passphrase: $passphrase
EOF
    note "Generating the key. This may take more than 25 minutes"
    gpg --batch --gen-key "$tmp"
    rm "$tmp"
    declare id="$(gpg --list-secret-keys --keyid-format LONG | grep -B 1 "$real_name <$email>" | head -n 1 | grep -o "rsa4096/\S*\s" | sed -e "s/rsa4096\///g" -e "s/\s//g")"

    gpg --armor --export "$id"

    printf "Press [ENTER] to continue"
    read -e
}

function ask_generate_a_key()
{
    declare answer
    while true
    do
        printf "\e[32m Do you want to generate a gpg key? (yes/no) \e[39m[\e[33myes\e[39m]:\n > "

        read -e answer

        if [[ -z "$answer" ]]
        then
            answer="yes"
        fi
        answer="$(tr '[:upper:]' '[:lower:]' <<<${answer})"
        case "$answer" in
            y|yes)
                return 0
            ;;
            n|no)
                return 1
            ;;
            *)
                printf "\e[33m Valid answers are: yes or no\e[39m\n\n"
            ;;
         esac
     done
}

main
