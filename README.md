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
work through [Enabling the publish workflow](#enabling-the-publish-workflow).

## Publishing to PyPI

### Enabling the publish workflow

`python-publish.yml` is written for [PyPI Trusted
Publishing](https://docs.pypi.org/trusted-publishers/): GitHub mints a
short-lived OIDC token that PyPI exchanges for an upload token. There is no
API token to create, store or rotate, and no secret in the repository.

It is wired up but deliberately switched off, because it cannot work until
you have done the four steps below. Nothing here has been exercised against a
live index.

**1. Claim a project name you own.** A trusted publisher binds a PyPI project
name to this repository, so you cannot register one for a name someone else
holds. Rename `name` in `pyproject.toml` first (see the Quickstart).

**2. Register a pending publisher, once on each index.** PyPI and TestPyPI are
separate registries with separate accounts, so do this twice:
[pypi.org](https://pypi.org/manage/account/publishing/) and
[test.pypi.org](https://test.pypi.org/manage/account/publishing/). Both live
under the account sidebar's *Publishing* page — the project sidebar only
offers this for projects that already exist. Choose GitHub Actions and fill
in:

| Field | Value |
| --- | --- |
| PyPI project name | your `project.name` from `pyproject.toml` |
| Owner | your GitHub user or org |
| Repository name | this repository |
| Workflow name | `python-publish.yml` (filename only, not a path) |
| Environment name | `pypi` on PyPI, `testpypi` on TestPyPI |

A pending publisher does **not** reserve the name; if someone else registers
it before your first upload, yours is invalidated. On first successful
publish it converts to a normal publisher.

**3. Create the two GitHub environments.** Under *Settings → Environments*,
add `pypi` and `testpypi`. The names have to match what you registered above,
because PyPI verifies the environment as part of the OIDC claim. This is also
where you would add required reviewers, if you want a human gate before a
release goes out.

**4. Enable the workflow.** Delete the `if: false` line from the `build` job
in `.github/workflows/python-publish.yml`. The `publish-test` and `publish`
jobs are chained to it through `needs`, so that one line gates all three.

### GitHub-based version publishing

Once the above is done, publishing a new version (if you have committer
rights) is a tag push:

```shell
# At a certain commit, ideally after merging a PR to main
git tag v0.1.x
git push origin v0.1.x
```

A [GitHub Action](https://github.com/MihaiBojin/template-python-package/actions)
builds the distributions once, publishes them to TestPyPI, then to PyPI, and
finally installs the released version from PyPI to verify it works.

### Manual

These steps can also be performed locally. Trusted Publishing only exists
inside GitHub Actions, so local publishing still uses API tokens. Export two
environment variables:

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
