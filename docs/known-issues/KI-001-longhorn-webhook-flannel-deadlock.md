# KI-001 — Longhorn validating webhook blocks Flannel bootstrap (k3s HA)

## Status

Mitigated

## First observed

2026-02-23

## Affected components

- k3s (HA control plane and agents)
- Flannel (CNI)
- Kubernetes API server
- Longhorn

---

## Summary

In k3s clusters using Flannel as the CNI, a **cluster-wide outage** can occur when the
Longhorn validating admission webhook blocks API server operations during cluster
bootstrap or recovery.

This results in Flannel failing to initialize, preventing **all pods** (including
core system components) from starting on both control-plane and agent nodes.

---

## Impact

- Complete loss of pod scheduling across the cluster
- Control-plane and agent nodes affected
- Core system pods (`local-path-provisioner`, `coredns`) unavailable
- Application workloads stuck in `ContainerCreating`
- **No data loss** (Longhorn volumes remain intact)

---

## Root cause

This issue is caused by a **bootstrap deadlock** between the following components:

1. **Flannel**
   - Requires PodCIDRs assigned by the control plane
   - Creates `/run/flannel/subnet.env` only after successful initialization

2. **k3s control-plane controllers**
   - Require an unblocked Kubernetes API server to assign PodCIDRs

3. **Longhorn validating admission webhook**
   - Runs as a pod and therefore depends on networking
   - Configured with `failurePolicy: Fail` (fail closed)

4. **Kubernetes API server**
   - Attempts to call the Longhorn webhook during reconciliation
   - Webhook has no endpoints because networking is not available
   - API requests fail, blocking controller progress

### Deadlock sequence

1. Node reboot, partial restart, or network outage occurs
2. `/run` (tmpfs) is cleared → Flannel runtime state is lost
3. Flannel cannot initialize without PodCIDRs
4. Longhorn webhook pods cannot start due to missing CNI
5. API server calls the Longhorn validating webhook
6. Webhook has no endpoints → API calls fail
7. Control-plane controllers are blocked
8. PodCIDRs are never assigned → Flannel never initializes

The cluster cannot recover automatically.

---

## Detection

### Symptoms

- Pods stuck in `ContainerCreating` across all namespaces
- Errors similar to:

```bash
failed to setup network for sandbox:
plugin type="flannel" failed (add):
failed to load flannel 'subnet.env':
open /run/flannel/subnet.env: no such file or directory
```

### Control-plane logs

`k3s` logs repeatedly show:

```bash
failed calling webhook "validator.longhorn.io":
no endpoints available for service "longhorn-admission-webhook"
```

---

## Resolution

1. Identify and remove the Longhorn validating webhook:

   ```bash
   kubectl get validatingwebhookconfigurations
   kubectl delete validatingwebhookconfiguration longhorn-webhook-validator
   ```

2. Restart k3s control-plane nodes **sequentially**:

   ```bash
   sudo systemctl restart k3s
   ```

   Wait for each node to become `Ready` before proceeding.

3. Restart all agent nodes:

   ```bash
   sudo systemctl restart k3s-agent
   ```

4. Verify Flannel initialization:

   ```bash
   ls -l /run/flannel/subnet.env
   kubectl get nodes -o wide
   ```

5. Restore Longhorn after the cluster is stable (Helm or manifest).

---

## Data safety

- No Longhorn volumes are deleted
- Replicas remain on disk
- PVCs remain bound
- Admission webhooks do not interact with data paths

---

## Prevention

- Configure Longhorn validating admission webhook with:

  ```yaml
  failurePolicy: Ignore
  ```

- Avoid fail-closed admission webhooks for storage components
- Restart k3s HA control-plane nodes sequentially
- Treat CNI initialization as a bootstrap-critical dependency

---

## References

- Internal incident: 2026-02-23 Longhorn / Flannel outage
- Longhorn admission webhook documentation
- k3s HA networking and Flannel behavior
