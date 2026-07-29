#!/bin/bash

# Function to check if the working directory is dirty
is_dirty() {
    if [ -n "$(git status --porcelain)" ]; then
        echo "-dirty"
    else
        echo ""
    fi
}

# Function to get the current Git short SHA
get_git_sha() {
    # Get the current Git short SHA
    GIT_SHA=$(git rev-parse --short HEAD)

    echo "${GIT_SHA}$(is_dirty)"
}

# Function to list the release tags pointing at the current HEAD, 'v' prefix
# removed, one per line. '--points-at' rather than '--contains': the latter
# lists every tag whose history includes HEAD, so checking out an older release
# returned that tag plus all later ones.
#
# Restricted to 'v*' because HEAD does not only carry release tags.
# chart-releaser publishes each chart under a '<chart>-<version>' tag on the
# very commit being released, so from the first chart release onwards a release
# commit has two tags -- and git orders them by refname, which puts the chart
# one first. Unfiltered, a re-run would read the chart tag as the version and
# try to publish 'template-python-package-template-python-package-0.1.0.tgz'.
get_tags_at_head() {
    git tag --list 'v*' --points-at HEAD | sed 's/^v//'
}

# Function to get a single tag at the current HEAD, for naming things.
# A commit can carry several tags; take the first so callers always get one
# line. Use get_tags_at_head when every tag matters.
get_tag_at_head() {
    get_tags_at_head | head -n 1
}

# Locates the single Helm chart under 'charts/'
# Discovered rather than hard-coded, so renaming the chart when you claim this
# template as your own does not mean editing the scripts too.
get_chart_dir() {
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    charts=("$dir"/../charts/*/)
    if [ "${#charts[@]}" -ne 1 ] || [ ! -f "${charts[0]}Chart.yaml" ]; then
        echo "Expected exactly one chart under charts/, found ${#charts[@]}" >&2
        return 1
    fi
    # Trim the trailing slash
    echo "${charts[0]%/}"
}

# Extracts the project name as configured in 'pyproject.toml'
# '--no-project' keeps this usable before the environment has been synced.
get_project_name() {
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    uv run --no-project python -c "import tomllib; print(tomllib.load(open('$dir/../pyproject.toml','rb'))['project']['name'])"
}

# Extracts the project version as configured in 'pyproject.toml'
get_project_version() {
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    uv run --no-project python -c "import tomllib; print(tomllib.load(open('$dir/../pyproject.toml','rb'))['project']['version'])"
}

# Extracts the project description as configured in 'pyproject.toml'.
# Flattened to a single line: it ends up in an OCI image label and in
# GITHUB_ENV, neither of which survives an embedded newline.
get_project_description() {
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    uv run --no-project python -c "import tomllib; print(' '.join(tomllib.load(open('$dir/../pyproject.toml','rb'))['project']['description'].split()))"
}
