#!/bin/bash
set -ueo pipefail

# Emits image build metadata as KEY=value lines, for '>> "$GITHUB_ENV"'.
#
# Lives here rather than inline in the workflow so both registry jobs read the
# same values from the same place, and so you can run it locally to see what
# they will be:
#
#   GITHUB_REPOSITORY=owner/repo GITHUB_REF_NAME=v0.1.0 scripts/image-metadata.bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DIR

# shellcheck disable=SC1091
source "$DIR/functions.bash"

# Registry paths are lowercase-only; GitHub owners and repositories are not.
OWNER_REPO="$(tr '[:upper:]' '[:lower:]' <<<"${GITHUB_REPOSITORY:?}")"
readonly OWNER_REPO
REPO_NAME="${OWNER_REPO##*/}"
readonly REPO_NAME

# The tag is the version. The build job already refused to publish unless it
# matched 'version' in pyproject.toml, so there is nothing left to reconcile
# here -- and reading the ref keeps this usable without a git checkout depth.
VERSION="${GITHUB_REF_NAME:?}"
VERSION="${VERSION#v}"
readonly VERSION

echo "OWNER_REPO=$OWNER_REPO"
echo "REPO_NAME=$REPO_NAME"
echo "VERSION=$VERSION"
echo "DESCRIPTION=$(get_project_description)"
