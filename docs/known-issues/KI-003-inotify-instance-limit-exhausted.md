# KI-003 — inotify instance limit exhausted crashes Jellyfin on startup

## Status

Resolved

## First observed

2026-11-13

## Last updated

2026-11-13

## Affected components

- Jellyfin (`media` namespace, .NET runtime)
- k3s worker nodes (Linux kernel `fs.inotify.*` limits)
- Any .NET / Node.js / Go workload that uses file system watchers

---

## Summary

Jellyfin crashed during startup with an unhandled `System.IO.IOException`
because the node had run out of **inotify instances** for the container's
user.

The default kernel limit `fs.inotify.max_user_instances=128` is shared by
**every process on the node running as the same UID** (most containers run
as root or a small set of UIDs), so as more workloads are scheduled the pool
is exhausted and new watchers fail.

---

## Impact

- Jellyfin pod enters `CrashLoopBackOff`; media streaming unavailable
- Other pods on the same node can fail in the same way when creating
  file watchers (config reload, library monitoring, hot reload)
- No data loss

---

## Root cause

Each .NET `FileSystemWatcher` (used by `reloadOnChange` JSON configuration
providers and Jellyfin's real-time library monitor) opens an inotify
instance. The kernel caps instances **per real UID** across the whole host,
not per container.

`fs.inotify.*` sysctls are **not namespaced**, so they cannot be raised via a
pod's `securityContext.sysctls`; they must be changed on the node itself.
Nodes were installed with distribution defaults (`max_user_instances=128`).

---

## Detection

Pod logs show:

```text
Unhandled exception. System.IO.IOException: The configured user limit (128) on
the number of inotify instances has been reached, or the per-process limit on
the number of open file descriptors has been reached.
   at System.IO.FileSystemWatcher.StartRaisingEvents()
```

Check the current values on a node:

```bash
sysctl fs.inotify.max_user_instances fs.inotify.max_user_watches
```

---

## Resolution

A `node-sysctl` DaemonSet was added to `kube-system`
(`kubernetes/infrastructure/base/node-sysctl/`). A privileged busybox init
container raises the limits on every node, then a non-privileged `pause`
container keeps the pod alive so the settings are reapplied after node
reboots or when new nodes join:

| Sysctl | Value |
| ------ | ----- |
| `fs.inotify.max_user_instances` | `8192` |
| `fs.inotify.max_user_watches` | `524288` |

The script only **raises** values; if a kernel already has a higher default
(newer kernels scale `max_user_watches` with RAM), it is left unchanged.

For immediate relief before Flux reconciles, run on the affected node:

```bash
sudo sysctl -w fs.inotify.max_user_instances=8192
```

---

## Data safety

- No data loss
- Jellyfin config/cache PVCs unaffected

---

## Prevention

- Kernel limits are managed declaratively via the `node-sysctl` DaemonSet;
  add future non-namespaced sysctls (e.g. `vm.max_map_count`) there.
- New nodes inherit the tuning automatically when they join the cluster.

---

## References

- `inotify(7)` — `/proc/sys/fs/inotify/max_user_instances`:
  <https://man7.org/linux/man-pages/man7/inotify.7.html>
- Kubernetes namespaced vs. node-level sysctls:
  <https://kubernetes.io/docs/tasks/administer-cluster/sysctl-cluster/>
