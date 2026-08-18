# KI-002 — CloudNativePG CRD/operator version skew causes hot reconcile loop

## Status

Resolved

## First observed

2026-08-18

## Last updated

2026-08-18

## Affected components

- CloudNativePG operator (`cloudnative-pg` 1.30.0)
- CloudNativePG CRDs (vendored under `kubernetes/config/base/crds/cnpg`)
- FluxCD (GitOps CRD management)

---

## Summary

The CloudNativePG operator entered a **hot reconcile loop**, reconciling the
`postgres-cluster` resource hundreds of times per second and flooding the
operator logs.

The loop was caused by a **version skew** between the running operator image
(`1.30.0`) and the **vendored CRDs**, which were generated from an older
CloudNativePG release and did not define fields the newer operator expected.

---

## Impact

- Continuous, high-frequency reconciliation of the `Cluster` resource
- Excessive operator CPU usage and massive log volume
- Operator unable to reach a stable desired state
- No data loss; PostgreSQL instances and volumes remained healthy

---

## Root cause

Starting with CloudNativePG **1.30.0**, defaulting and validation run **during
reconciliation as a fallback** when the admission webhook is unavailable or set
to ignore failures. During defaulting, the 1.30.0 operator sets the new field
`spec.probes.liveness.isolationCheck`.

The CRDs installed in the cluster were **vendored from an older release**
(generated with `controller-gen v0.17.2`) and did **not** define
`spec.probes.liveness.isolationCheck`. As a result:

1. The operator defaulted the `Cluster` object, adding `isolationCheck`.
2. The API server rejected the unknown field against the older CRD schema
   (`unknown field "spec.probes.liveness.isolationCheck"`).
3. The stored object never matched the operator's desired state.
4. The operator immediately re-reconciled, producing an infinite loop.

The underlying condition was **dual CRD management**: the operator Helm chart
was configured with `crds.create: true`, while CRDs were **also** vendored and
applied by Flux under `kubernetes/config/base/crds/cnpg`. Because Helm never
*upgrades* CRDs after first install, the stale vendored CRDs became the
effective schema and drifted behind the operator image.

---

## Detection

- Operator logs show a storm of reconciles with rapidly changing `reconcileID`s
- Repeated log lines:

  ```text
  Defaulting for Cluster
  unknown field "spec.probes.liveness.isolationCheck"
  Mutating webhook seems not installed, applying changes
  ```

- Confirmation commands:

  ```bash
  # Running operator version
  kubectl -n cnpg-system get deploy -l app.kubernetes.io/name=cloudnative-pg \
    -o jsonpath='{.items[0].spec.template.spec.containers[0].image}'

  # Installed CRD missing the new field (returns 0)
  kubectl get crd clusters.postgresql.cnpg.io -o json | grep -c isolationCheck
  ```

---

## Resolution

The vendored CRDs were regenerated from the CloudNativePG **1.30.0** release
manifest so the schema matched the running operator, then applied via Flux.

```bash
curl -sL https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v1.30.0/cnpg-1.30.0.yaml \
  | yq -y 'select(.kind == "CustomResourceDefinition")' \
  > kubernetes/config/base/crds/cnpg/crd.yaml
```

Once the CRD included `spec.probes.liveness.isolationCheck`, the defaulted
object converged and the reconcile loop stopped.

---

## Data safety

- No data loss
- PostgreSQL instances, PVCs, and Longhorn volumes unaffected
- Change was schema-only (CRD definition), not a data path

---

## Prevention

- Keep vendored CRDs **in lockstep** with the operator chart/image version.
  Whenever the `cloudnative-pg` chart is bumped, regenerate the vendored CRDs
  from the matching release tag.
- Establish a **single source of truth** for CRDs. Prefer Flux-managed vendored
  CRDs and set `crds.create: false` on the operator HelmRelease to avoid
  dual management and silent drift.
- Note the tooling caveat: the vendored-CRD regeneration expects a specific
  `yq` flavor. The Python `yq` (jq wrapper) uses `yq -y '<jq filter>'`, whereas
  the Go `mikefarah/yq` uses `yq eval '<expr>'`.

---

## References

- CloudNativePG v1.30.0 release notes:
  <https://github.com/cloudnative-pg/cloudnative-pg/releases/tag/v1.30.0>
- Related fix commit: vendored CNPG CRDs bumped to v1.30.0
