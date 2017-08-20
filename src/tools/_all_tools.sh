#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

declare -r TOOLS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$TOOLS_DIR/../../lib/loader.bash"
loader_addpath "$TOOLS_DIR"

include "apt.sh"
include "os_detection.sh"
include "output.sh"
include "parse_opt.sh"
include "sudoers.sh"
loader_finish
