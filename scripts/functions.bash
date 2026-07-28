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

# Function to get any tags matching the current HEAD
get_tag_at_head() {
    # Get the tag and remove the 'v' prefix
    TAG="$(git tag --contains HEAD)"
    echo "${TAG#v}"
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
