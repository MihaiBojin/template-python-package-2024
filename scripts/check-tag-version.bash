#!/bin/bash
set -ueo pipefail

# The version lives in pyproject.toml and is bumped in a pull request, so a
# release tag must agree with what was merged. This replaces the old
# detect-and-set-tag-version.bash, which wrote the tag into a VERSION file at
# publish time; nothing rewrites the version any more, it is only verified.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DIR

# shellcheck disable=SC1091
source "$DIR/functions.bash"

TAGS="$(get_tags_at_head)"
readonly TAGS
if [ -z "$TAGS" ]; then
    echo "No version tag found at HEAD, cannot proceed..." >&2
    exit 1
fi

PROJECT_VERSION="$(get_project_version)"
readonly PROJECT_VERSION

# A commit can carry more than one tag, so it is enough that one of them
# matches; requiring a single tag would fail on legitimately re-tagged commits.
if ! grep -qxF "$PROJECT_VERSION" <<<"$TAGS"; then
    echo "Tag/version mismatch, refusing to publish." >&2
    echo "  tag(s) at HEAD:         $(tr '\n' ' ' <<<"$TAGS")" >&2
    echo "  pyproject.toml version: $PROJECT_VERSION" >&2
    echo >&2
    echo "Bump 'version' in pyproject.toml (and run 'uv lock') to match the tag." >&2
    exit 1
fi

echo "Tag matches the project version: $PROJECT_VERSION"
