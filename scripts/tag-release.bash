#!/bin/bash
set -ueo pipefail

# Tags HEAD with the version in pyproject.toml, unless that tag already exists.
#
# Run on every push to main: pushes that do not change the version find their
# tag already present and do nothing, so only a merged version bump creates a
# release.
#
# Writes the created tag to stdout and nothing at all when there was nothing to
# do, so a caller can branch on it. All commentary goes to stderr.
#
# Pass --dry-run to skip creating and pushing the tag.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DIR

# shellcheck disable=SC1091
source "$DIR/functions.bash"

DRY_RUN=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --dry-run)
        DRY_RUN="yes"
        ;;
    *)
        echo "Error: unsupported argument $1" >&2
        exit 1
        ;;
    esac
    shift
done
readonly DRY_RUN

# The version is read from the working copy, so an uncommitted bump would tag
# a commit that does not carry it. CI checkouts are clean; this catches the
# local run.
if [ -n "$(is_dirty)" ]; then
    echo "Working directory is dirty, cannot proceed..." >&2
    git status --porcelain >&2
    exit 1
fi

VERSION="$(get_project_version)"
readonly VERSION
TAG="v$VERSION"
readonly TAG

# Ask the remote rather than the local clone: a CI checkout may not have
# fetched tags, and the remote is what decides whether the tag is taken.
#
# Exit 2 is git's "no such ref", the one case that means carry on. Anything
# else -- no network, no permission, no origin -- is a failure to answer the
# question, and tagging anyway would be guessing.
set +e
git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null
LS_REMOTE_STATUS=$?
set -e
readonly LS_REMOTE_STATUS
case "$LS_REMOTE_STATUS" in
0)
    echo "Tag $TAG already exists on origin; nothing to release." >&2
    exit 0
    ;;
2) ;; # Not on origin: this is the release.
*)
    echo "Could not ask origin about $TAG (git exited $LS_REMOTE_STATUS); refusing to tag." >&2
    exit 1
    ;;
esac

if [ -n "$DRY_RUN" ]; then
    echo "[dry-run] would tag HEAD ($(git rev-parse --short HEAD)) as $TAG" >&2
    echo "$TAG"
    exit 0
fi

echo "Tagging HEAD ($(git rev-parse --short HEAD)) as $TAG..." >&2
# '-f': the check above only asks origin, so a previous run that created the
# tag and then failed to push it leaves one behind locally. Without this, the
# retry aborts on "tag already exists" and the only fix is manual.
git tag -af "$TAG" -m "Release $VERSION"
git push origin "$TAG" >&2

echo "$TAG"
