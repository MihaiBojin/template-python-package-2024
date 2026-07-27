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

This template publishes nothing itself. The workflow is wired up and switched
off, so a project started from it needs a name, a trusted publisher, and one
deleted line.

### One-time setup

1. **Name the package.** Set `name` in `pyproject.toml` and check it is free on
   PyPI first. `template_python_package` is taken by an unrelated project, so
   leaving the template's name in place will fail.

2. **Register a pending publisher, once on each index.** PyPI and TestPyPI are
   separate registries with separate accounts, so do this twice:
   [pypi.org](https://pypi.org/manage/account/publishing/) and
   [test.pypi.org](https://test.pypi.org/manage/account/publishing/). Both live
   under the *account* sidebar's Publishing page — the project sidebar only
   offers this for projects that already exist.

   | Field | Value |
   | --- | --- |
   | Owner | your GitHub user or org |
   | Repository | your repository name |
   | Workflow | `python-publish.yml` (filename only, not a path) |
   | Environment | `pypi` on PyPI, `testpypi` on TestPyPI |

   A pending publisher does **not** reserve the name. If someone else registers
   it before your first upload, yours is invalidated. On the first successful
   publish it converts to a normal publisher.

3. **Create the GitHub environments** `pypi` and `testpypi` under *Settings →
   Environments*. Add a required reviewer on `pypi` if you want a human gate
   before anything reaches the real index.

4. **Enable publishing** by deleting the `if: false` line from the `build` job
   in `.github/workflows/python-publish.yml`. The `publish-test` and `publish`
   jobs are chained to it through `needs`, so that one line gates all three.

No API tokens, and nothing to store in repository secrets. GitHub mints a
short-lived OIDC token per run and PyPI exchanges it for a scoped credential.

> [!IMPORTANT]
> PyPI matches the request against the workflow **filename**. Renaming
> `python-publish.yml` breaks publishing with an unhelpful error; re-register the
> publisher if you move it.

### Publishing a version

Tag a commit and push it:

```shell
# At a certain commit, ideally after merging a PR to main
git tag v0.1.x
git push origin v0.1.x
```

The workflow lints and tests across every supported Python, builds once, then
publishes that same artifact to TestPyPI and to PyPI, and finally verifies the
package installs from the real index.

### Publishing by hand

Local publishing needs a token, since trusted publishing only works from CI:

```shell
export UV_PUBLISH_TOKEN=...   # a PyPI API token
make publish-test             # test.pypi.org first
make publish                  # then the real index
make publish-verify           # confirm it installs
```

Prefer the tag flow. A token that lives on a laptop is the thing trusted
publishing exists to avoid.

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
