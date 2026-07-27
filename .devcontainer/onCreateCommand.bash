#!/bin/bash
set -euo pipefail
DIR=.

cd "$DIR"

echo "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh
# shellcheck disable=SC2016
echo 'source "$HOME/.local/bin/env"' >>~/.bashrc
# shellcheck disable=SC2016
echo 'source "$HOME/.local/bin/env"' >>~/.zshrc

# shellcheck disable=SC1091
source "$HOME/.local/bin/env"

# Create the virtualenv; uv provisions the interpreter itself
uv sync --all-extras
