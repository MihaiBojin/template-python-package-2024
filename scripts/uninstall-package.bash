#!/bin/bash
set -ueo pipefail

PROJECT_NAME=$(python -c "import tomllib; print(tomllib.load(open('pyproject.toml','rb'))['project']['name'])")
echo "Uninstalling $PROJECT_NAME..."
pip uninstall -y "$PROJECT_NAME"
echo "Done."
