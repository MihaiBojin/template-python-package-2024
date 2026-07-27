#!/bin/bash
set -euo pipefail
DIR=.

# Ensure the up-to-date requirements are installed
cd "$DIR"
# shellcheck disable=SC1091
source "$HOME/.local/bin/env"
make setup
