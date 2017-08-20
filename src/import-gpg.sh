#!/usr/bin/env bash

function main
{
    PRIVATE_KEY=
    PUBLIC_KEY_FILE="public.asc"
    PRIVATE_KEY_FILE="secret.asc"

    [ -n "$1" ] && PRIVATE_KEY="$1"
    [ -n "$2" ] && PUBLIC_KEY_FILE="$2"
    [ -n "$3" ] && PRIVATE_KEY_FILE="$3"
    # if the file does not exist, unset var
    [ ! -f "$PUBLIC_KEY_FILE" ] && PUBLIC_KEY_FILE=
    [ ! -f "$PRIVATE_KEY_FILE" ] && PRIVATE_KEY_FILE=

    if [ -z "$PRIVATE_KEY" ]
    then
        echo "Usage: $0 \$PRIVATE_KEY \$PUBLIC_KEY_FILE \$PRIVATE_KEY_FILE"
        echo "------------------------------------------------------------"
        gpg -K
    fi

    echo "import public key"
    if [ -z "$PUBLIC_KEY_FILE" ]
    then
        echo "\$ gpg --import \$PUBLIC_KEY_FILE"
    else
        gpg --import "$PUBLIC_KEY_FILE"
    fi

    echo "import private key"
    if [ -z "$PRIVATE_KEY_FILE" ] || [ -z "$PRIVATE_KEY" ]
    then
        echo "\$ gpg --import \$PRIVATE_KEY_FILE"
        echo "\$ gpg --edit-key \$PRIVATE_KEY"
    else
        gpg --import "$PRIVATE_KEY_FILE"
        gpg --edit-key "$PRIVATE_KEY"
    fi

}

main $@
