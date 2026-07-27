# Python Package template

![Build Status](https://github.com/MihaiBojin/template-python-package/actions/workflows/python-tests.yml/badge.svg)
[![License](https://img.shields.io/github/license/MihaiBojin/template-python-package.svg)](LICENSE)

Use this repo as a template for starting multi-package Python projects.

## Quickstart

Press **Use this template** on GitHub, or clone it:

```shell
git clone https://github.com/MihaiBojin/template-python-package.git my-project
```

This template uses [uv](https://docs.astral.sh/uv/). Install it, then one
command gets you a working development environment:

```shell
cd my-project
uv sync --all-extras
```

That creates `.venv/`, installs everything from the committed `uv.lock`, and
provisions a Python interpreter if you do not have a suitable one. Run
commands through `uv run` (`uv run pytest tests`) or activate the environment
with `source .venv/bin/activate`.

To also install the git hooks, run `make setup`. The `Makefile` targets are
thin wrappers over `uv` and are kept for convenience.

Then claim the name as your own: `name` and `[project.urls]` in
`pyproject.toml`, the package directories under `src/`, and the entry point
under `[project.scripts]`.

### Dependencies

Declare them in `pyproject.toml`, then refresh the lock file:

```shell
uv lock
```

Commit `uv.lock` alongside the `pyproject.toml` change; CI runs
`uv sync --locked` and fails if the two disagree.

This template is not published to PyPI, and it is not meant to be. Nobody
installs a template; you copy it. Note that `template-python-package` on PyPI
is an unrelated project by another author, so choose your own name before you
publish anything. The publish workflow stays disabled (`if: false`) until you
do.

## Publishing to PyPI

### GitHub-based version publishing

The simplest way to publish a new version (if you have committer rights) is to tag a commit and push it to the repo:

```shell
# At a certain commit, ideally after merging a PR to main
git tag v0.1.x
git push origin v0.1.x
```

A [GitHub Action](https://github.com/MihaiBojin/template-python-package/actions) will run, build the library and publish it to PyPI.

### Manual

These steps can also be performed locally. For these commands to work, you will need to export two environment variables:

```shell
export TESTPYPI_PASSWORD=... # token for https://test.pypi.org/legacy/
export PYPI_PASSWORD=... # token for https://upload.pypi.org/legacy/
```

The `Makefile` passes these to `uv publish` as `UV_PUBLISH_TOKEN`; the test
index is defined as `testpypi` under `[[tool.uv.index]]` in `pyproject.toml`.

First, publish to the test repo and inspect the package:

```shell
make publish-test
```

If correct, distribute the wheel to the PyPI index:

```shell
make publish
```

Verify the distributed code

```shell
make publish-verify
```

## Building a Docker image

Build an image with:

```shell
make docker
```

and run it with

```shell
make docker-run
# or
make docker-run ARGS="--arg1 --arg2 --etc"
```
