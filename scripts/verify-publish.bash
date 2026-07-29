#!/bin/bash
set -ueo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DIR

# Load name and version from the project manifest. Read inline rather than
# through functions.bash: this script is the one thing under scripts/ that ships
# in the sdist (see the re-include in pyproject.toml), so it has to run from an
# unpacked archive where the other helpers are absent.
VERSION="$(uv run --no-project python -c "import tomllib; print(tomllib.load(open('$DIR/../pyproject.toml','rb'))['project']['version'])")"
readonly VERSION

PROJECT_NAME="$(uv run --no-project python -c "import tomllib; print(tomllib.load(open('$DIR/../pyproject.toml','rb'))['project']['name'])")"
readonly PROJECT_NAME

# Retries a command, backing off exponentially.
#
# This exists for one reason: a freshly uploaded release takes time to appear on
# the index that just accepted it. A budget of three retries 5s apart gave up
# after ~30s and failed releases that had in fact published correctly, so the
# delays now grow to cover several minutes.
#
# Callers must also pass --refresh-package. uv caches index responses, negative
# answers included, so a bare retry re-reads the cached "no such version" in
# about 2ms and the whole ladder expires without ever asking the index again;
# pip re-fetched on its own, which is why this only began to matter once the
# toolchain moved to uv.
retry() {
    # One attempt plus five retries: 15s, 30s, 60s, 120s, 240s (~7.75 min).
    MAX_ATTEMPTS=6
    count=0
    base=15
    local command="$*"
    while [ "$count" -lt "$MAX_ATTEMPTS" ]; do
        count=$((count + 1))
        # shellcheck disable=SC2086
        eval $command && break

        if [ "$count" -eq "$MAX_ATTEMPTS" ]; then
            echo
            echo "Failed after $MAX_ATTEMPTS attempts" >&2
            exit 1
        fi

        echo
        echo "Retrying ($count/$((MAX_ATTEMPTS - 1)))..."
        delay=$((base * 2 ** (count - 1)))
        echo "Sleeping for $delay seconds before retrying..."
        sleep "$delay"
    done
}

if [[ "$#" -eq 0 ]]; then
    echo "You must specify --test or --prod as arguments" >&2
    echo
    exit 1
fi

echo "Creating a virtual env..."
VENV="$(mktemp -d)/venv"
readonly VENV
# '--no-project' keeps the env detached from the working tree, so the check
# really does exercise the published artifact rather than the local source.
uv venv --no-project "$VENV"
# 'uv pip' targets this env instead of the project's .venv
export VIRTUAL_ENV="$VENV"

echo "Copying verification script..."
cp "$DIR"/../src/scripts/verify_install.py "$VENV/verify_install.py"

echo "Attempting to install version ($VERSION) in virtualenv ($VENV)..."
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --test)
        # The cli extras come from the main index because test.pypi does not
        # carry every third-party package.
        CLI_DEPS="$(uv run --no-project python -c "import tomllib; print(' '.join(tomllib.load(open('$DIR/../pyproject.toml','rb'))['project'].get('optional-dependencies', {}).get('cli', [])))")"
        if [ -n "$CLI_DEPS" ]; then
            echo "Installing cli extras from main index, since not all packages are available in test.pypi..."
            # shellcheck disable=SC2086
            uv pip install $CLI_DEPS
        fi
        echo "Attempting install: ${PROJECT_NAME}==$VERSION"
        retry uv pip install --refresh-package "$PROJECT_NAME" --index-url https://test.pypi.org/simple/ "${PROJECT_NAME}==$VERSION"
        ;;
    --prod)
        echo "Attempting install: ${PROJECT_NAME}==$VERSION"
        retry uv pip install --refresh-package "$PROJECT_NAME" "${PROJECT_NAME}[cli]==$VERSION"
        ;;
    --*= | -*)
        echo "Error: Unsupported flag $1" >&2
        echo
        exit 1
        ;;
    esac
    shift
done

pushd "$VENV" >/dev/null 2>&1
"$VENV/bin/python" verify_install.py
popd >/dev/null 2>&1

echo "Virtualenv location: $VENV"
