#!/bin/bash
set -euo pipefail
DIR=python

# Create a virtualenv
cd "$DIR"
make create-venv
