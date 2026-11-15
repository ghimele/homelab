# Move the VPS cluster from `vpslab` into this repository

Runbook for [ADR-012](../adr/ADR-012-Host-VPS-Cluster-In-Homelab-Repo.md). The VPS cluster is currently reconciled by Flux from `ghimele/vpslab` (path `./kubernetes/clusters/vpslab`).
After the move it is reconciled from this repository (path `./kubernetes/clusters/vps`), sharing `kubernetes/*/base` with `prod` and `test`.

The safety net for the whole procedure is the rendered output: `prod` and `test` must render exactly as before, and `vps` must render exactly as `vpslab` does today. Flux prunes, so an object missing from the new tree is deleted from the cluster.

## Prerequisites

- Tools: `kustomize` v5.3+, `kubeconform`, `yq` v4.34+, `flux` and `sops`. `kubectl` access to the VPS cluster (for `flux diff` and the cutover).
- The VPS Age private key (`age14cx…`), to prove the moved secrets still decrypt.
- A read-only credential for `ghimele/homelab` for the VPS. The current `flux-system` secret on the VPS is used with an HTTPS URL, so a fine-grained token with read access to the contents of this repository is enough.
- An issue for the change (per [AGENTS.md](../../AGENTS.md)). Reference ADR-012 in the manifests that depend on it with `# ADR: ADR-012-Host-VPS-Cluster-In-Homelab-Repo`.
- Disable Renovate on `ghimele/vpslab` before Phase 4, so the two trees cannot diverge during the move.

## Target layout

```text
kubernetes/
├── apps/
│   ├── base/
│   ├── prod/
│   ├── test/
│   └── vps/            # garage, mariadb, phpmyadmin, wordpress, monitoring
├── clusters/
│   ├── prod/
│   ├── test/
│   └── vps/            # apps, config, infrastructure, repositories, flux-system
├── config/
│   ├── base/           # crds/: cert-manager, traefik (common only)
│   ├── prod/
│   ├── test/
│   └── vps/            # secrets/ + crds mariadb, system-upgrade
├── infrastructure/
│   ├── base/
│   ├── prod/
│   ├── test/
│   └── vps/            # cert-manager, traefik, tailscale, system-upgrade
└── repositories/       # catalogue for prod/test
    └── vps/            # selection + vps-only entries
```

## Phase 0: baseline renders

Record what every environment renders today. These files are the reference for all later checks.

```bash
# in this repository, before any change
mkdir -p /tmp/baseline/home
for env in prod test; do
  for layer in config infrastructure apps; do
    [ -d kubernetes/$layer/$env ] && \
      kustomize build kubernetes/$layer/$env --load-restrictor=LoadRestrictionsNone > /tmp/baseline/home/$layer-$env.yaml
  done
done
kustomize build kubernetes/repositories --load-restrictor=LoadRestrictionsNone > /tmp/baseline/home/repositories.yaml

# in the vpslab repository
mkdir -p /tmp/baseline/vps
kustomize build kubernetes/config/prod         --load-restrictor=LoadRestrictionsNone > /tmp/baseline/vps/config.yaml
kustomize build kubernetes/infrastructure/prod --load-restrictor=LoadRestrictionsNone > /tmp/baseline/vps/infrastructure.yaml
kustomize build kubernetes/apps                --load-restrictor=LoadRestrictionsNone > /tmp/baseline/vps/apps.yaml
kustomize build kubernetes/repositories        --load-restrictor=LoadRestrictionsNone > /tmp/baseline/vps/repositories.yaml
```

Secrets stay SOPS-encrypted in the output, so the comparison also proves that the encrypted files were not altered.

## Phase 1: make `base` common (touches prod and test)

Move what is not common out of `base` into overlay patches, then re-render `prod` and `test` and diff them against the baseline. The result must be empty.

| Item | `base` keeps | Moves to the overlay |
| ---- | ------------ | -------------------- |
| `config/base/crds` | cert-manager, traefik | `prod` and `test` add metallb, kube-prometheus-stack, cnpg, barman-cloud. `vps` adds mariadb and system-upgrade. |
| `infrastructure/base/traefik` | chart, namespace, shared values | `prod`/`test`: OIDC plugin, `kubernetesIngress`, `allowExternalNameServices` (patch in `values.yaml`). `vps`: log level and access log. |
| `infrastructure/base/tailscale` | chart, namespace | `prod`/`test`: `defaultTags`. `vps`: `oauth` with the `${TAILSCALE_*}` variables. |
| `infrastructure/base/cert-manager` | chart, namespace | `prod`/`test`: `prometheus.servicemonitor` (the VPS has no Prometheus CRDs). |
| `infrastructure/base/system-upgrade` | controller, server plan | `prod`: `crds/` and the agent plan. |

```bash
for env in prod test; do
  for layer in config infrastructure apps; do
    [ -d kubernetes/$layer/$env ] && \
      kustomize build kubernetes/$layer/$env --load-restrictor=LoadRestrictionsNone | \
      diff -u /tmp/baseline/home/$layer-$env.yaml - || echo "DIFF in $layer/$env"
  done
done
```

Merge Phase 1 on its own and let Flux reconcile `prod`. It must report no changes before going on. If it cannot be made zero-diff, fall back to the "own copy of `base`" alternative in ADR-012.

## Phase 2: add the `vps` environment

Copy the files from `ghimele/vpslab` unchanged, except for the paths and the references below.

| vpslab | This repository |
| ------ | --------------- |
| `kubernetes/clusters/vpslab/` | `kubernetes/clusters/vps/` |
| `kubernetes/config/prod/` | `kubernetes/config/vps/` |
| `kubernetes/config/base/crds/{mariadb,system-upgrade}` | `kubernetes/config/base/crds/{mariadb,system-upgrade}`, referenced only by `config/vps` |
| `kubernetes/infrastructure/prod/` | `kubernetes/infrastructure/vps/` |
| `kubernetes/apps/<app>/` | `kubernetes/apps/vps/<app>/` |
| `kubernetes/repositories/{bitnami,bitnami-oci,mariadb-operator}.yaml` | `kubernetes/repositories/` (catalogue) |
| `kubernetes/repositories/kustomization.yaml` | `kubernetes/repositories/vps/kustomization.yaml` (references `../<name>.yaml` for the 10 repositories the VPS uses) |

Changes to make while copying:

- `clusters/vps/{apps,config,infrastructure,repositories}.yaml`: set `path` to `./kubernetes/{apps,config,infrastructure}/vps` and `./kubernetes/repositories/vps`. Keep every Kustomization `name` and namespace.
- `clusters/vps/flux-system/gotk-sync.yaml`: set `url: https://github.com/ghimele/homelab.git`, `path: ./kubernetes/clusters/vps` and `secretRef.name: flux-system-homelab`
  (the new secret created in Phase 5, so the old `flux-system` secret stays available for a rollback). Keep the interval. Copy `gotk-components.yaml` and `.sops.pub.asc` as they are.
- `infrastructure/vps/*`: reference `../../base/<name>/` and carry the VPS patches from Phase 1.
- `.sops.yaml`: add, with the VPS Age key and the same `encrypted_regex` as the other rules:

  ```yaml
  - path_regex: .*/vps/.*\.enc\.yaml$
    encrypted_regex: '^(user.*|pass.*|.*[Bb]earer.*|.*[Kk]ey|.*[Kk]eys|salt|sentry.*|.*[Tt]oken|data|stringData|match|href)$'
    age: age14cxw37cj5xm4xvsdeewgz8ex54qg4rgcyqj2w9c6g4ra3jh6sa2sggq7pf
  ```

  Rules are matched in order, so keep the `vps` rule scoped with `.*/vps/.*` and do not widen the `prod` rule.

Do not run `sops updatekeys`. The recipients are stored in each file, so a moved file still decrypts with the same key.

## Phase 3: CI and Renovate

- `scripts/flux-validate.sh` already walks `./kubernetes`, so the `vps` YAML and `clusters/vps` are validated. Enable the commented-out `kustomize build` loop for the overlay folders
  (`kubernetes/{config,infrastructure,apps}/{prod,test,vps}` and `kubernetes/repositories/vps`), since `base` is now a contract between environments.
- Run `yamllint .` on the copied files with this repository's `.yamllint` (250-character limit, `---` document markers).
- `renovate.json` already matches `/kubernetes/.+\.ya?ml$/`, so it covers the new folders. Both repositories group `flux` and `traefik` and automerge patch updates, so nothing needs to be ported.

## Phase 4: prove that `vps` renders as `vpslab`

```bash
kustomize build kubernetes/config/vps          --load-restrictor=LoadRestrictionsNone | diff -u /tmp/baseline/vps/config.yaml -
kustomize build kubernetes/infrastructure/vps  --load-restrictor=LoadRestrictionsNone | diff -u /tmp/baseline/vps/infrastructure.yaml -
kustomize build kubernetes/apps/vps            --load-restrictor=LoadRestrictionsNone | diff -u /tmp/baseline/vps/apps.yaml -
kustomize build kubernetes/repositories/vps    --load-restrictor=LoadRestrictionsNone | diff -u /tmp/baseline/vps/repositories.yaml -
```

All four diffs must be empty. If only the order of the documents differs, sort them before comparing. Then check the secrets decrypt with the VPS key only:

```bash
export SOPS_AGE_KEY_FILE=/path/to/vps-age.key
find kubernetes -path '*/vps/*' -name '*.enc.yaml' -exec sops -d {} \; > /dev/null
```

Re-run the Phase 0 renders for `vpslab` right before the cutover and repeat the diffs. If vpslab changed in between, port the change first.

## Phase 5: cutover on the live VPS cluster

Run against the VPS cluster context, after the Phase 1 to 4 changes are merged to `main`.

```bash
# 1. Freeze reconciliation so nothing is pruned while switching
flux suspend kustomization --all -n flux-system

# 2. The new tree must match the live state, layer by layer (expect no output)
export SOPS_AGE_KEY_FILE=/path/to/vps-age.key
flux diff kustomization config         --path ./kubernetes/config/vps
flux diff kustomization infrastructure --path ./kubernetes/infrastructure/vps
flux diff kustomization apps           --path ./kubernetes/apps/vps

# 3. Give Flux the credential for this repository
flux create secret git flux-system-homelab -n flux-system \
  --url=https://github.com/ghimele/homelab.git --username=git --password=<read-only-token>

# 4. Re-point the source and the root Kustomization (must match clusters/vps/flux-system/gotk-sync.yaml)
kubectl -n flux-system patch gitrepository flux-system --type merge \
  -p '{"spec":{"url":"https://github.com/ghimele/homelab.git","secretRef":{"name":"flux-system-homelab"}}}'
kubectl -n flux-system patch kustomization flux-system --type merge \
  -p '{"spec":{"path":"./kubernetes/clusters/vps"}}'

# 5. Resume the root first, then the rest
flux resume kustomization flux-system -n flux-system
flux resume kustomization --all -n flux-system
flux get sources git,kustomizations -A
```

Keep the Flux version in `gotk-components.yaml` as it is during the move (do not run `flux bootstrap` at the same time), so the cutover changes only the source.

Verify afterwards:

- `flux get kustomizations -A` shows every Kustomization `Ready` on the new revision.
- Nothing was pruned: the pods, PVCs (WordPress, MariaDB, Garage), HelmReleases and Tailscale devices (`garage-vpslab`, `garage-ui-vpslab`) are all still present, and the homelab CNPG archiving to Garage is healthy (see [cnpg-backup-vpslab-garage.md](cnpg-backup-vpslab-garage.md)).
- The old `flux-system` secret is kept for the rollback and deleted only when `ghimele/vpslab` is archived.

### Rollback

While `ghimele/vpslab` is untouched, switch back by patching the same objects to the old values:

```bash
flux suspend kustomization --all -n flux-system
kubectl -n flux-system patch gitrepository flux-system --type merge \
  -p '{"spec":{"url":"https://github.com/ghimele/vpslab.git","secretRef":{"name":"flux-system"}}}'
kubectl -n flux-system patch kustomization flux-system --type merge \
  -p '{"spec":{"path":"./kubernetes/clusters/vpslab"}}'
flux resume kustomization --all -n flux-system
```

Do not commit to `ghimele/vpslab` after the cutover, or the rollback would deploy a stale tree.

## Phase 6: cleanup and documentation

After a soak period (suggested: two weeks without incident):

- Archive `ghimele/vpslab` on GitHub. Replace its README with a pointer to this repository.
- Update [ADR-011](../adr/ADR-011-CNPG-Backup-To-Vpslab-Garage.md) and the guides that mention the `ghimele/vpslab` repository:
  [cnpg-backup-vpslab-garage.md](cnpg-backup-vpslab-garage.md) and [vpslab-alloy-tailscale.md](vpslab-alloy-tailscale.md).
  The cluster keeps its name, and only the repository and path wording changes.
- Move the useful parts of the vpslab README into `docs/Installation.md` and `docs/Architecture.md`, and add the VPS environment to the layout in [AGENTS.md](../../AGENTS.md).
- Set the ADR-012 status to `Accepted`.
