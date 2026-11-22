# KI-005 — Unraid NFS fails when rpcbind is detected in another namespace

## Status

Mitigated

## First observed

2026-11-21

## Last updated

2026-11-21

## Affected components

- Unraid host RPC and NFS services
- Docker container running a separate `rpcbind`
- Kubernetes NFS CSI driver and NFS-backed applications

---

## Summary

The Unraid host was online and its NFS exports existed, but its NFS server
had zero kernel threads and was not listening on TCP 2049. Several pods could
not mount their media or photos shares.

## Impact

- Media and home-automation workloads remained in `ContainerCreating` or
  initialization while NFS mounts timed out.
- The NFS CSI driver logged connection refusals and, intermittently,
  missing-path errors.
- Longhorn volume health was a separate concern; healthy Longhorn volumes did
  not imply that the external NFS server was available.
- No export or share was intentionally deleted. The incident did not
  establish whether any application data was lost.

## Root cause

An `rpcbind` process was running inside a Docker container in a different
network namespace. Unraid's RPC startup script checked for the process by
name and treated it as the host's `rpcbind`, even though the host had no
listener on port 111. Host RPC registration failed, so `rpc.nfsd` could not
start.

Unraid's NFS startup script also treated a running `rpc.mountd` as evidence
that NFS was started. Consequently it reported success even when
`/proc/fs/nfsd/threads` was `0` and TCP 2049 was closed.

## Detection

- `exportfs -v` lists shares, but `/proc/fs/nfsd/threads` is `0`.
- No host listener exists on TCP 2049 or RPC port 111.
- Syslog reports RPC registration failures and `rpc.nfsd` reports that it
  cannot set up sockets.
- Compare the network namespace of the `rpcbind` process with the host's
  namespace and inspect its cgroup. Do not stop a container process merely
  because it has the same name as a host service.

See the [recovery runbook](../runbooks/unraid-nfs-rpcbind-namespace.md) for
diagnostic and recovery steps.

## Resolution

A separate host `rpcbind` was started with the existing Unraid bind options,
without stopping the container process. The Unraid NFS service was then
restarted. Eight NFS threads and a TCP 2049 listener were observed, and
Kubernetes workloads recovered as their mount retries completed.

This was a runtime workaround. It has not been demonstrated to survive a
reboot, and the startup-script process-name check was not fixed.

## Data safety

- Shares and export definitions were preserved.
- Restarting NFS temporarily unexports shares and can interrupt other NFS
  clients; obtain approval before doing so.
- Do not delete, recreate or force-detach storage as a substitute for
  restoring the NFS service.

## Prevention

- Investigate namespace-aware service detection and startup ordering so a
  container's `rpcbind` cannot mask the host service.
- Monitor the host's actual port 111 and 2049 listeners and NFS thread count,
  not just the presence of `rpcbind` or `rpc.mountd`.
- Review firewall exposure: the incident's host `rpcbind` listened on TCP
  port 111 on all interfaces despite the configured bind arguments.

## Related runbooks

- [Recovering Unraid NFS and host rpcbind](../runbooks/unraid-nfs-rpcbind-namespace.md)

## References

- [Unraid NFS server guidance](https://unraid.net/blog/deploying-an-unraid-nfs-server)
