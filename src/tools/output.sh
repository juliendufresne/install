#!/usr/bin/env bash

function error_with_output_file()
{
    declare -r filename="$1"

    error "$@"

    >&2 printf >&2 'Following is the output of the command\n'
    >&2 printf >&2 '######################################\n'
    >&2 cat "$filename"
    >&2 rm "$filename"
}

function title()
{
    header '=' "${1:-}"
}

function section()
{
    header '-' "${1:-}"
}

function header()
{
    declare -r underline_char="$1"
    declare -r text="$2"

    declare -r -i text_length="$(echo -ne "$text" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | wc -c)"
    declare -r pad="$(printf %${text_length}s|tr ' ' "$underline_char")"

    printf '\e[33m%b\e[39m\n' "$text"
    printf '\e[33m%*.*s\e[39m\n' '0' "$text_length" "$pad"
}

function success()
{
    block " " "OK" "\e[37;44m" false "$@"
}

function error()
{
    block " " "ERROR" "\e[37;41m" true "$@"
}

function note()
{
    block " ! " "NOTE" "\e[33m" false "$@"
}

function warning()
{
    block " " "WARNING" "\e[37;41m" true "$@"
}

function block()
{
    declare -r prefix="$1"
    declare    type="$2"
    declare -r color="$3"
    declare -r is_error="$4"
    shift
    shift
    shift
    shift

    declare -r    color_reset="\e[39;49m"
    declare -r -i terminal_length="$(tput cols)"
    declare -r    pad="$(printf "%${terminal_length}s")"
    declare       file_descriptor="/dev/stdout"
    declare -r -i prefix_length="$(echo -ne "$prefix" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | wc -c)"
    declare -i    type_length=0
    declare       empty_type=""

    if ${is_error}
    then
        file_descriptor="/dev/stderr"
    fi

    if [[ "${#type}" -gt 0 ]]
    then
        type="[$type] "
        type_length="$(echo -ne "$type" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | wc -c)"
        printf -v empty_type '%*.*s' '0' "$type_length" "$pad"
    fi

    declare -r -i fold_length="$((terminal_length - prefix_length - type_length))"

    printf '%b%*.*s%b\n' "$color" '0' "$terminal_length" "$pad" "$color_reset" >"$file_descriptor"
    if [[ $# -eq 0 ]]
    then
        printf '%b%b%b%*.*s%b\n' "$color" "$prefix" "$type" '0' "$((fold_length))" "$pad" "$color_reset" >"$file_descriptor"
    else
        declare is_first_line=true
        for message in "$@"
        do
            while read line_output
            do
                if ${is_first_line}
                then
                    printf '%b%b%b' "$color" "$prefix" "$type" >"$file_descriptor"
                    is_first_line=false
                else
                    printf '%b%b%b' "$color" "$prefix" "$empty_type" >"$file_descriptor"
                fi

                printf '%b%*.*s%b\n' "$line_output" '0' "$((fold_length - ${#line_output}))" "$pad" "$color_reset" >"$file_descriptor"
            done <<< "$(echo -ne "$message" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | fold --spaces --bytes --width="$fold_length")"
        done
    fi
    printf '%b%*.*s%b\n' "$color" '0' "$terminal_length" "$pad" "$color_reset" >"$file_descriptor"
}
