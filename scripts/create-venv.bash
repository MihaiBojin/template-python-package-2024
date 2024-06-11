#!/bin/bash
readonly VENV="venv"

if [ ! -e "pyproject.toml" ]; then
    echo "Current directory does not appear to be a python package..." >&2
    echo
    exit 1
fi

if [ -d "$VENV" ]; then
    echo "Directory already exists: $VENV" >&2
    echo "Will not recreate it." >&2
    echo
    exit 1
fi

# Create virtualenv
python -m venv "$VENV"

# shellcheck disable=SC1091
source "$VENV"/bin/activate

pip install --upgrade pip
pip install -e .[cli,dev]
