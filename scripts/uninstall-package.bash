#!/bin/bash
set -ueo pipefail

echo "Uninstalling locally installed packages..."
for package_name in $(pip list | grep "$HOME" | cut -f 1 -d ' '); do
    echo "Uninstalling $package_name..."
    pip uninstall -y "$package_name"
done
echo "Done."
