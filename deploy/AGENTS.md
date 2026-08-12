# AGENTS.md — deploy/

Parent guide: [`../AGENTS.md`](../AGENTS.md)

## Purpose

Shell scripts that install/restart/delete the `mosip/artifactory` Helm
release (which deploys the image `../artifacts/` builds) into the
`esignet` namespace of a MOSIP cluster.

## Layout

```text
deploy/
├── README.md      # short usage note
├── install.sh       # first-time install
├── restart.sh          # rollout restart of all deployments in the esignet namespace
└── delete.sh              # interactive helm uninstall (prompts Y/n)
```

## Script details

- **`install.sh`** — usage: `./install.sh [kubeconfig]`. Creates the
  `esignet` namespace, labels it for Istio sidecar injection
  (`istio-injection=enabled` — note this differs from some other MOSIP
  repos' `deploy/install.sh`, which set `disabled`; check the actual
  script rather than assuming a repo-wide convention), then `helm
  install`s `mosip/artifactory` pinned to `CHART_VERSION=0.0.1-develop`
  with `--set image.repository=mosipdev/esignet-artifactory-server
  --set image.tag=develop`. All `set -e`/`set -o nounset`/
  `set -o pipefail` — any missing var or failed step aborts the script.
- **`restart.sh`** — usage: `./restart.sh [kubeconfig]`. Runs
  `kubectl rollout restart deploy` across the **whole `esignet`
  namespace** (not scoped to just the artifactory deployment), then
  waits for rollout status on every Deployment found there. Running
  this restarts everything in the `esignet` namespace, not only
  `esignet-artifactory`.
- **`delete.sh`** — interactive-only (no non-interactive/CI-safe flag);
  prompts "Are you sure you want to delete artifactory helm chart?
  (Y/n)" before running `helm -n esignet delete esignet-artifactory`.

## Configuration

No `.env`/secrets files — the only externally supplied value is the
optional `[kubeconfig]` positional argument each script accepts (sets
`KUBECONFIG` if given). `CHART_VERSION` and the image repository/tag are
hardcoded in `install.sh` — update them there if the chart version or
image location changes (see root `AGENTS.md`'s Configuration section).

## Agent rules

### Do

1. Keep `CHART_VERSION` in `install.sh` in sync with whatever chart
   version is actually published for `mosip/artifactory` if you bump it.
2. Remember `restart.sh` restarts the entire `esignet` namespace, not
   just this service — mention that scope if documenting or scripting
   around it.

### Do not

1. Do not assume Istio injection is `enabled` in every MOSIP repo's
   `install.sh` by copying this pattern elsewhere without checking —
   it varies by repo.
2. Do not remove the interactive confirmation in `delete.sh` without
   flagging it — it's the only guard against an accidental delete.
