#!/bin/bash
set -ueo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DIR

VERSION_FILE="$DIR/../VERSION"
readonly VERSION_FILE

# shellcheck disable=SC1091
source "$DIR/functions.bash"

# Retrieve current git sha
TAG="$(get_git_sha)"
VERSION="$(cat "$VERSION_FILE")"
if [ -z "$(is_dirty)" ]; then
    # Working dir is clean, attempt to use tag
    GITTAG="$(get_tag_at_head)"

    # If git tag found, use it
    if [ -n "$GITTAG" ]; then
        TAG="$GITTAG"
        VERSION="$GITTAG"
    fi
fi
readonly TAG

# Load project name from project manifest
PROJECT_NAME="$(get_project_name)"
readonly PROJECT_NAME

# The image builds the package from source, reading VERSION during the docker
# build, so the release value has to stay in place until the build finishes.
# Restoring the previous contents (rather than `git checkout --`) keeps an
# uncommitted VERSION edit from being thrown away.
PREVIOUS_VERSION="$(cat "$VERSION_FILE")"
readonly PREVIOUS_VERSION
restore_version() {
    echo "Reverting version to repository value..."
    echo "$PREVIOUS_VERSION" >"$VERSION_FILE"
}
trap restore_version EXIT

echo "Updating version in '$VERSION_FILE' to: $VERSION"
echo "$VERSION" >"$VERSION_FILE"

# Build the image
echo "Building $PROJECT_NAME:$TAG..."
docker build \
    -t "$PROJECT_NAME:$TAG" \
    "$DIR/.."
