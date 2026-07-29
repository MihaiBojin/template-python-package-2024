# Python Package template

![Build Status](https://github.com/MihaiBojin/template-python-package/actions/workflows/cicd.yml/badge.svg)
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

### Versioning

`version` under `[project]` in `pyproject.toml` is the single source of truth,
and it is static: the checked-in value is always what a dev install reports.
`uv.lock` records it too, so a bump means `uv lock` in the same commit.

This template is not published to PyPI, and it is not meant to be. Nobody
installs a template; you copy it. Note that `template-python-package` on PyPI
is an unrelated project by another author, so choose your own name before you
publish anything. The publish workflow stays disabled (`if: false`) until you
do.

## The pipeline

`.github/workflows/cicd.yml` is the whole of CI and CD, as one job graph:

```
lint-test (3.11 → 3.14) ─> build ─> publish-test ─> publish ─┬─> push-dockerhub ─┐
helm-lint                                                    └─> push-ghcr ──────┴─> release ─> helm
```

`lint-test` and `helm-lint` run on every pull request and every push to `main`.
Everything from `build` onwards runs only on a `v0.*` tag.

PyPI gates the image builds on purpose: a PyPI upload cannot be undone or
replaced, so if it fails there is nothing worth pinning images against and the
run stops. The two registry jobs are independent of each other and run in
parallel; `release` waits for both, then `helm` publishes the chart against the
release.

`push-dockerhub` is opt-in — it is skipped unless the `DOCKERHUB_USERNAME`
repository variable is set (see below), and `release` tolerates that skip.

## Publishing to PyPI

This template publishes nothing itself. The pipeline is wired up and switched
off, so a project started from it needs a name, a trusted publisher, and two
deleted words.

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
   | Workflow | `cicd.yml` (filename only, not a path) |
   | Environment | `pypi` on PyPI, `testpypi` on TestPyPI |

   A pending publisher does **not** reserve the name. If someone else registers
   it before your first upload, yours is invalidated. On the first successful
   publish it converts to a normal publisher.

3. **Create the GitHub environments** `pypi` and `testpypi` under *Settings →
   Environments*. Add a required reviewer on `pypi` if you want a human gate
   before anything reaches the real index.

4. **Enable the pipeline** by deleting the words `false &&` from the `if:` on
   the `build` job in `.github/workflows/cicd.yml`. Every job downstream
   reaches `build` through `needs`, so that one edit gates all of them, and
   what is left — `startsWith(github.ref, 'refs/tags/v0.')` — is the condition
   that keeps them to tag builds.

5. **Enable releasing** by deleting the `if: false` line from the `tag` job in
   `.github/workflows/tag-release.yml`. Leave it in place if you would rather
   push tags by hand.

6. **Optionally, add Docker Hub.** Set a `DOCKERHUB_USERNAME` repository
   *variable* and a `DOCKERHUB_TOKEN` secret under *Settings → Secrets and
   variables → Actions*. Without the variable the `push-dockerhub` job is
   skipped and only GHCR is published, which needs no setup at all.

No API tokens for PyPI, and nothing to store in repository secrets for it.
GitHub mints a short-lived OIDC token per run and PyPI exchanges it for a
scoped credential.

> [!IMPORTANT]
> PyPI matches the request against the workflow **filename**. Renaming
> `cicd.yml` breaks publishing with an unhelpful error; re-register the
> publisher if you move it.

### Publishing a version

Releasing is merging a version bump. Nothing is tagged or published by hand.

```shell
# In a release branch: set the new version in pyproject.toml, then
#   (uv.lock records the project version, so CI's `uv sync --locked` fails without this)
uv lock
```

Open a pull request with that change. Once it merges, `tag-release.yml` reads
`version` from `pyproject.toml` and, if no matching tag exists yet, tags the
merge commit `v<version>` and starts `cicd.yml` against it. Pushes to `main`
that do not change the version find their tag already present and do nothing.

A tag pushed by a workflow does not raise a `push` event — GitHub suppresses
events made with `GITHUB_TOKEN` so workflows cannot trigger themselves.
`tag-release.yml` therefore starts `cicd.yml` through `workflow_dispatch`,
which is exempt from that rule, so no long-lived personal access token is
needed. Pushing a `v0.*` tag by hand still works and takes the ordinary `push`
path.

`build` runs `scripts/check-tag-version.bash` first and refuses to publish if
the tag and `pyproject.toml` disagree, so a forgotten bump fails the release
rather than republishing the previous version. From there the pipeline builds
once and hands that same artifact to TestPyPI and then PyPI, verifies it
installs from the real index, builds and pushes multi-platform images with a
provenance attestation and an SBOM, cuts a GitHub release with the SBOMs
attached, and publishes the Helm chart.

### Publishing by hand

Local publishing needs a token, since trusted publishing only works from CI:

```shell
export UV_PUBLISH_TOKEN=...   # a PyPI API token
make publish-test             # test.pypi.org first
make build-inspect            # list the wheel and archive contents
make publish                  # then the real index
make publish-verify           # confirm it installs
```

Every target publishes the version currently in `pyproject.toml`, so set it
there first, and note that **uploads are irreversible** — a version number can
never be reused, even after deleting a release. This path runs no linters or
tests, and nothing checks the version against a tag.

Prefer the release flow. A token that lives on a laptop is the thing trusted
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

These build for the host architecture only, which is what you want locally. On
a tag, the `push-ghcr` and `push-dockerhub` jobs build `linux/amd64` and
`linux/arm64` through Buildx instead, push `:<sha>`, `:<version>` and
`:latest`, and attach a provenance attestation and an SBOM to each.
`scripts/image-metadata.bash` computes the tags and OCI labels both jobs use;
run it locally to see what they will be:

```shell
GITHUB_REPOSITORY=owner/repo GITHUB_REF_NAME=v0.1.0 scripts/image-metadata.bash
```

## Publishing the Helm chart

`charts/` holds a chart that deploys the image built above. See
[its README](charts/template-python-package/README.md) for values and
install instructions.

Locally:

```shell
make helm-lint     # lint and render
make helm-package  # package into out/charts/
```

The chart is linted and rendered on every pull request by the `helm-lint` job.
The `helm` job publishes it, last in the pipeline, using
[chart-releaser](https://github.com/helm/chart-releaser-action): the packaged
chart goes to its own GitHub release and the index is served from the
`gh-pages` branch.

### Enabling the chart release

Like the rest of the pipeline, this is wired up but switched off, because it
needs one-time setup that cannot be done from a commit.

**1. Create the `gh-pages` branch.** chart-releaser publishes `index.yaml`
there; it must exist before the first run.

```shell
git checkout --orphan gh-pages
git rm -rf .
echo "Helm charts" > index.html
git add index.html
git commit -m "Init gh-pages"
git push origin gh-pages
git checkout main
rm -f index.html
```

**2. Serve it.** *Settings → Pages*, deploy from branch `gh-pages`, folder
`/ (root)`. The chart's `home` URL in `Chart.yaml` points at the resulting
Pages site, so update it when you rename the project.

**3. Enable the job.** Delete the `if: false` line from the `helm` job in
`.github/workflows/cicd.yml`. The `helm-lint` job runs regardless.

Once live, consumers add the repo with:

```shell
helm repo add template-python-package https://MihaiBojin.github.io/template-python-package/
```

### How the version reaches the chart

Worth understanding before changing any of it, because the failure modes are
silent.

`Chart.yaml` is tracked at `0.0.0` and rewritten from the git tag at release
time by `scripts/helm-set-version.bash`. The `v` prefix is stripped: Helm chart
versions are SemVer without one, and published artifacts are named
`template-python-package-0.1.0.tgz`.

The `helm` job drives `cr` itself rather than letting `chart-releaser-action`
run its own release step, which is why it installs the action with
`install_only`. The action publishes a chart only when it sees a **committed**
change to a tracked file under `charts/`, and the version rewrite above is
neither committed nor could usefully be: a commit made on the runner is one
GitHub has never seen, and the action's `cr upload -c "$(git rev-parse HEAD)"`
would then aim the release at it and fail with a 422 on `target_commitish`.
Packaging and uploading directly needs no commit and aims at `$GITHUB_SHA`.

Three flags on those calls are load-bearing:

- `--commit "$GITHUB_SHA"` — the release target GitHub can actually resolve.
- `--make-release-latest=false` — `cr` defaults it to `true`, and the `release`
  job has already marked the product release as latest. Without this the chart
  release takes that badge.
- `--index-path .cr-index/index.yaml` alongside `mkdir -p .cr-index` — that is
  `cr`'s own default path, but nothing creates the directory and the write
  fails with `ENOENT` if it is missing.

`--skip-existing` keeps re-runs idempotent, which also means a failed upload
exits 0 — and an index that was never pushed does not show up in the release
either. The final step therefore asserts both: the release exists, and the
chart resolves from the published `gh-pages` index.

One consequence worth knowing: `cr` tags each chart release
`<chart>-<version>` on the **same commit** as `v<version>`, so from the first
release onwards a release commit carries two tags. `get_tags_at_head` in
`scripts/functions.bash` filters to `v*` for exactly that reason — unfiltered,
git's refname ordering hands back the chart tag first.
