#!/bin/bash
set -ueo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DIR

VERSION_FILE="$DIR/../VERSION"
readonly VERSION_FILE

# Fetch the latest tags
git fetch --tags

# Get the latest tag
TAG="$(git describe --tags "$(git rev-list --tags --max-count=1)")"

if ! [[ "$TAG" == v* ]]; then
    echo "No version tag found."
    exit 1
fi

# Print the detected tag
echo "Detected tag: $TAG"

VERSION="${TAG#v}"

echo "Updating version in '$VERSION_FILE' to: $VERSION"
echo "$VERSION" >"$VERSION_FILE"
