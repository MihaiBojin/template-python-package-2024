#!/bin/bash
set -ueo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DIR

# shellcheck disable=SC1091
source "$DIR/functions.bash"

CHART_DIR="$(get_chart_dir)"
readonly CHART_DIR

# Helm chart versions are SemVer *without* a leading 'v', while git tags here
# carry one (v0.1.0). get_tag_at_head already strips it; the second strip
# holds that invariant if the helper is ever swapped for one that does not.
# Getting this wrong publishes template-python-package-v0.1.0.tgz, which
# breaks the naming convention of every chart already in the index.
VERSION="$(get_tag_at_head)"
VERSION="${VERSION#v}"

if [ -z "$VERSION" ]; then
    echo "No version tag found at HEAD, cannot set the chart version..." >&2
    exit 1
fi
readonly VERSION

sed -i.bak \
    -e "s/^version: .*/version: \"$VERSION\"/" \
    -e "s/^appVersion: .*/appVersion: \"$VERSION\"/" \
    "$CHART_DIR/Chart.yaml"
rm -f "$CHART_DIR/Chart.yaml.bak"

echo "Updated Helm chart version to $VERSION" >&2
