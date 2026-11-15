# ADR-012: Host the VPS Cluster in the Homelab Repository with a Shared Base

## Status

Proposed

## Date

2026-11-14

## Context and Problem Statement

The k3s cluster on the Hostinger VPS is managed by Flux from a separate repository, `ghimele/vpslab`. That repository was created from this one and has the same layout (`clusters/`, `config/{base,prod}`, `infrastructure/{base,prod}`, `repositories/`),
the same SOPS + Age secrets flow and the same Renovate and CI setup.

Keeping two repositories has these costs:

- **Drifting copies of `base`.** The `base` folders started as copies and have diverged:
  different CRD sets (`config/base/crds`), a different Traefik release (OIDC plugin and `kubernetesIngress` here, DEBUG and access logs there),
  a different Tailscale `oauth` block, a Prometheus ServiceMonitor in cert-manager that the VPS cannot use, and an agent plan and CRDs for `system-upgrade`.
  Every chart bump or fix has to be made twice.
- **Cross-repository changes.** [ADR-011](ADR-011-CNPG-Backup-To-Vpslab-Garage.md) already spans both repositories (Garage and its NetworkPolicies on the VPS, the Tailscale egress and the CNPG `ObjectStore` here), so one feature needs two PRs and two reviews.
- **Duplicated tooling.** There are two Renovate configurations, two CI pipelines and two sets of documentation.

Constraints:

- The VPS is internet-facing, so it must not hold the prod Age key.
- The VPS has only about 430m of unreserved CPU, so it must not reconcile the whole HelmRepository catalogue of the homelab.
- The VPS cluster is live and Flux prunes (`prune: true`), so the move must not change what is rendered.

## Solution (Decision)

Move the VPS cluster into this repository as a new `vps` environment, next to `prod` and `test`, sharing the same `base`.

```text
kubernetes/
├── apps/            base/  prod/  test/  vps/
├── clusters/        prod/  test/  vps/
├── config/          base/  prod/  test/  vps/
├── infrastructure/  base/  prod/  test/  vps/
└── repositories/    (catalogue)  + vps/
```

Rules:

- **`base` only holds what is identical on every cluster.** Differences become patches in the environment overlay (`values.yaml` patches, as `infrastructure/prod/traefik` already does).
  A `base` item used by `vps` must not need CRDs or components the VPS does not run.
- **CRDs are selected per environment.** `config/base/crds` keeps the common ones (cert-manager, traefik).
  The cluster-specific ones (metallb, kube-prometheus-stack, cnpg, barman-cloud for `prod`/`test`; mariadb and system-upgrade for `vps`) are referenced by the overlays that need them.
- **VPS-only apps live in `apps/vps/<app>`** (garage, mariadb, phpmyadmin, wordpress, monitoring). They move to `apps/base` only when a second cluster needs them.
- **Repositories are selected per cluster.** `kubernetes/repositories` stays the catalogue used by `prod` and `test`, and `kubernetes/repositories/vps` references only the entries the VPS needs.
  The three VPS-only entries (bitnami, bitnami-oci, mariadb-operator) are added to the catalogue.
- **Secrets keep a separate key.** `.sops.yaml` gets a `.*/vps/.*\.enc\.yaml$` rule with the VPS Age key. The VPS never receives the `prod` key.
- **Flux on the VPS** points to this repository with a read-only credential and the path `./kubernetes/clusters/vps`. Kustomization and object names do not change, so the cutover prunes nothing.
- **History is not preserved.** The files are copied and `ghimele/vpslab` is archived after a soak period. Its paths are spread across the tree and cannot be mapped with `git subtree`.

Rollout, verification and rollback: [vps-cluster-monorepo-migration.md](../tips-and-tricks/vps-cluster-monorepo-migration.md).

## Alternatives

- **Keep two repositories and sync `base` by hand (status quo)**: no risk now, but the drift continues and every cross-cluster change needs two PRs.
- **Move the VPS into this repository with its own copy of `base`**: consolidates CI, Renovate and docs at low risk, but keeps the drift. It is a valid fallback if the `base` refactor proves too risky for `prod`.
- **A third repository (or OCI artifact) that holds only `base`**: removes the drift and keeps the repositories isolated, but adds a repository, a versioning scheme and a second Flux source for two clusters.
- **Preserve the vpslab history with `git filter-repo` and a merge**: possible, but it changes the paths anyway and the 150 commits are not worth the complexity.

## Comparison Table

| Feature/Criteria | Monorepo, shared base | Two repositories (today) | Monorepo, separate bases | Shared `base` repository |
| ---------------- | --------------------- | ------------------------ | ------------------------ | ------------------------ |
| **Drift between bases** | Removed | Continuous | Continuous | Removed |
| **Cross-cluster change (ADR-011)** | One PR | Two PRs | One PR | Two or more PRs |
| **Risk to `prod` from a VPS change** | Low to medium (through `base`) | None | None | Low (pinned version) |
| **Effort** | High (`base` refactor) | None | Low | High |
| **Renovate and CI to maintain** | One | Two | One | Two or more |
| **VPS read access** | Whole repository | VPS repository only | Whole repository | VPS and `base` repositories |

## Consequences

### Positive Outcomes

- One place for a change that spans both clusters, and one Renovate, CI and documentation set.
- `base` drift stops. Differences are explicit patches in `prod` or `vps`.
- The overlay builds become the contract between environments, so enabling the `kustomize build` validation in `scripts/flux-validate.sh` is justified and catches breakage before it reaches either cluster.

### Negative Outcomes

- A change to `base`, including a Renovate chart bump, can hit `prod` and `vps` in the same merge. Before, the two repositories were upgraded independently.
- The VPS cluster receives credentials that can read the whole homelab repository (topology and hostnames, but not secrets, which stay encrypted with the `prod` key). This is acceptable while the repository is private.
- The `base` refactor touches live `prod` manifests, so it needs a zero-diff `kustomize build` check for `prod` and `test` before and after.
- The vpslab commit history is no longer part of the active repository.

### Trade-offs

- Separate Age keys keep a compromised VPS from decrypting homelab secrets, at the cost of one more `.sops.yaml` rule to maintain.
- Keeping vps-only apps out of `base` avoids premature sharing. Sharing the VPS monitoring stack (alloy, kube-state-metrics) with `apps/base/monitoring` can be done later when it is worth the refactor.
