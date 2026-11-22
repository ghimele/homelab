# Recovering Unraid NFS and host rpcbind

Use this runbook when Unraid is online but NFS-backed Kubernetes workloads
cannot mount shares. See [KI-005](../known-issues/KI-005-unraid-rpcbind-network-namespace.md)
for the namespace-related incident.

## 1. Identify the failure

On the Unraid host:

```bash
cat /proc/fs/nfsd/threads
sudo ss -lnptu '( sport = :111 or sport = :2049 )'
sudo rpcinfo -p 127.0.0.1
sudo exportfs -v
ls -ld /mnt/user/Media /mnt/user/Photos
```

In the incident the shares existed, but the thread count was `0`, ports 111
and 2049 were not listening on the host, and RPC registration was refused.
An export listed by `exportfs` or an NFS service script reporting `Started`
does not by itself prove that NFS is serving clients.

If `rpcbind` is present but host port 111 is not listening, identify the
process before acting. Substitute its current PID; do not reuse an old PID:

```bash
ps -o pid,ppid,stat,args -p <rpcbind-pid>
sudo cat /proc/<rpcbind-pid>/cgroup
sudo readlink /proc/<rpcbind-pid>/ns/net
sudo readlink /proc/1/ns/net
```

Different network namespace identifiers and a Docker cgroup identified the
container-owned process in this incident. Do not stop that process: it may be
needed by the container.

## 2. Restore the host services

> Obtain approval before starting RPC or restarting NFS. Restarting NFS
> temporarily unexports shares and may interrupt other clients. Do not
> delete or recreate the exports.

1. Inspect `/etc/default/rpc` and confirm `RPCBIND_OPTS` contains the intended
   bind addresses. Review the network and firewall implications before
   starting the host service. In this incident TCP port 111 listened on all
   interfaces even with `-h` options.
2. When the host has no rpcbind listener and the existing process belongs to
   another namespace, start the host instance using the current Unraid
   options:

   ```bash
   sudo bash -c '. /etc/default/rpc; exec /sbin/rpcbind -w $RPCBIND_OPTS'
   sudo ss -lnptu '( sport = :111 )'
   sudo rpcinfo -p 127.0.0.1
   ```

   Stop if it fails or the expected listener is absent. `-w` can restore
   stale RPC registrations; they are not proof that NFS is listening.
3. Restart NFS with the Unraid service script:

   ```bash
   sudo /etc/rc.d/rc.nfsd restart
   cat /proc/fs/nfsd/threads
   sudo ss -lnt | grep ':2049'
   sudo exportfs -v
   ```

   Verify a nonzero thread count, the expected listeners and exports.
   If startup fails, inspect `/var/log/syslog`; do not assume the script's
   `Started` message is sufficient.

## 3. Verify workloads and follow up

- Check connectivity to TCP 2049 from the affected workers and allow
  Kubernetes to retry mounts.
- Verify the affected pods become Ready and their application data is
  accessible. Do not force-detach or delete volumes to accelerate recovery.
- The manually started host rpcbind is a runtime workaround, not a verified
  persistent fix. Investigate namespace-aware process detection and startup
  order before the next reboot.
