# template-python-package Helm chart

Deploys the container image built by this repository. Rename the directory and
the `name` in `Chart.yaml` when you claim the template as your own — the
scripts locate the chart by globbing `charts/*`, so nothing else needs editing.

## Install

```shell
helm install my-release charts/template-python-package
```

The chart creates its own namespace, named after the chart. Set
`namespaceOverride` to deploy somewhere else.

## Versioning

`version` and `appVersion` are tracked at `0.0.0`, the same placeholder
convention the `VERSION` file uses. The real number is written in at release
time by `scripts/helm-set-version.bash`, from the git tag, with the leading
`v` stripped. Do not bump them by hand.

## Values

| Key | Default | Description |
| --- | --- | --- |
| `replicaCount` | `1` | Deployment replicas |
| `image.repository` | `ghcr.io/mihaibojin/template-python-package` | Image to run |
| `image.tag` | `""` | Defaults to `.Chart.AppVersion` |
| `image.pullPolicy` | `Always` | |
| `command` / `args` | `[]` | Override the image entrypoint |
| `config` | `{LOG_LEVEL: INFO}` | Rendered into a ConfigMap, injected via `envFrom` |
| `secrets` | `{}` | Rendered into a Secret, injected via `envFrom` |
| `namespaceOverride` | `""` | Deploy into a namespace other than the chart name |
| `podSecurityContext` | runs as uid/gid 30000 | |
| `securityContext` | non-root, no privilege escalation, read-only rootfs, all caps dropped | |
| `resources.requests` | `100m` CPU, `128Mi` memory | |

Both `config` and `secrets` are free-form maps: every key becomes an
environment variable. Never commit real secret values — pass them with
`--set-string` or an unversioned values file.

## A note on the default workload

The bundled demo CLI prints one line and exits, so the Deployment restarts it
forever. That is deliberate for a template: it proves the image is wired up
without pretending to be a real service. Point `command`/`args` at a
long-running process, or swap the Deployment for a `CronJob`, once there is
something real to run.

## Tests

```shell
helm test my-release
```

The test runs the application image once and asserts a clean exit, which
proves the image is pullable, the tag resolves and the entrypoint works. It
deliberately does not assert "the Deployment's pod is Running" — that needs
`kubectl` in the test image plus RBAC to list pods, and a test that cannot
pass is worse than no test.
