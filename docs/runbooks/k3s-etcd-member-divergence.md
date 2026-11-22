# Recovering a divergent k3s etcd member

Use this runbook when control-plane APIs disagree and etcd member data
divergence has been verified. See [KI-004](../known-issues/KI-004-k3s-etcd-member-divergence.md)
for the incident.

> **Warning:** This is a data-recovery procedure, not a routine restart.
> Obtain a maintenance window, stop application writes, and verify backups.
> Do not reset etcd, restore a snapshot, delete a node or force-detach volumes
> while the authoritative state is uncertain. Replacing a member discards
> any Kubernetes state unique to that member from the active cluster.

## 1. Diagnose and preserve evidence

1. Query each API server directly instead of using the shared address:

   ```bash
   kubectl --context PROD-KHC --server=https://<server-ip>:6443 get nodes -o wide
   kubectl --context PROD-KHC --server=https://<server-ip>:6443 \
     get leases -n kube-node-lease
   ```

2. On a control-plane host with `etcdctl`, compare each endpoint's status
   and membership. Substitute the current IPs; do not assume the previous
   incident's leader or member IDs still apply.

   ```bash
   sudo etcdctl --endpoints=https://<server-ip>:2379 \
     --cacert=/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt \
     --cert=/var/lib/rancher/k3s/server/tls/etcd/client.crt \
     --key=/var/lib/rancher/k3s/server/tls/etcd/client.key \
     --command-timeout=8s endpoint status -w json
   ```

   Use the same TLS flags with `member list -w table` and
   `endpoint hashkv --rev=<common-revision> -w json`. Compare hashes only
   when both the requested revision and returned `compact_revision` match.
   If the revision is compacted or unavailable, the comparison is
   inconclusive. A matching Raft index or API `readyz` alone is insufficient.

3. Before changing membership, save and verify a separate etcd snapshot from
   **each** accessible endpoint and preserve the matching K3s server token
   (`/var/lib/rancher/k3s/server/token`). Use `etcdctl snapshot save` and
   `etcdctl snapshot status`, or the appropriate version of `etcdutl`.
   Copy the snapshots and token to access-restricted, preferably encrypted,
   independent storage. Never share them in chat or commit them to Git.

   These snapshots do not contain Longhorn volume or PostgreSQL data. Verify
   application backups and storage state separately.

   For the incident's three endpoint addresses, the following creates a
   root-only directory on a server with `etcdctl`. Check free space and
   confirm the addresses and token first:

   ```bash
   sudo bash -c '
   set -eu
   umask 077
   dir=$(mktemp -d /root/etcd-incident-XXXXXX)
   echo "Backup directory: $dir"
   install -m 600 /var/lib/rancher/k3s/server/token "$dir/server-token"
   for ip in 192.168.10.101 192.168.10.102 192.168.10.103; do
     etcdctl --endpoints="https://$ip:2379" \
       --cacert=/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt \
       --cert=/var/lib/rancher/k3s/server/tls/etcd/client.crt \
       --key=/var/lib/rancher/k3s/server/tls/etcd/client.key \
       --command-timeout=60s snapshot save "$dir/$ip.db"
     etcdctl snapshot status "$dir/$ip.db" -w table
   done
   '
   ```

   Stop if any command fails; keep any partial evidence and investigate
   before proceeding. A readable snapshot is not the same as a tested
   restore.

## 2. Establish the recovery pair

Select the surviving state with operator approval, using application and
storage evidence as well as member hashes. A leader, majority or higher
revision alone does not establish that its data is complete.

In the 2026-11-21 incident, 02 and 03 matched at a common revision and
compaction point, and 01 was the divergent member. Under an approved
maintenance window, 01's k3s service was stopped; 02 and 03 elected a leader
and their hashes were checked again.

With one member stopped or removed, the two remaining voters are both
required for quorum. Do not stop or restart either surviving member. If they
cannot maintain quorum or their hashes do not agree, stop and reassess rather
than proceeding.

## 3. Replace the divergent member

The following describes the incident's replacement procedure. Confirm the
current member ID, host, service configuration and backup locations before
running it. This requires explicit approval because it changes membership
and selects the surviving state.

1. On the stopped host, inspect the systemd unit and any K3s configuration.
   Confirm it joins an existing server using `--server` or `server:` and
   does not enable `--cluster-init`. Do not expose token values.

2. Confirm k3s is stopped on the divergent host and verify that the two
   surviving endpoints are healthy. Remove **only** the divergent member,
   using its current hexadecimal ID from `member list`:

   ```bash
   sudo etcdctl --endpoints=https://<healthy-server-ip>:2379 \
     --cacert=/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt \
     --cert=/var/lib/rancher/k3s/server/tls/etcd/client.crt \
     --key=/var/lib/rancher/k3s/server/tls/etcd/client.key \
     --command-timeout=15s member remove <divergent-member-id>
   ```

   List members again and confirm that only the intended member was removed.
   Stop if removal or quorum verification fails.

3. Preserve the old directory by moving it to a **new, non-existing**
   quarantine path on the same filesystem. Never delete or overwrite it:

   ```bash
   source_dir=/var/lib/rancher/k3s/server/db/etcd
   quarantine="/var/lib/rancher/k3s/server/db/etcd-quarantine-$(date +%Y%m%d-%H%M%S)"
   if systemctl is-active --quiet k3s; then
     echo "Stop: k3s is running" >&2
   elif ! sudo test -d "$source_dir"; then
     echo "Stop: etcd directory is missing" >&2
   elif sudo test -e "$quarantine"; then
     echo "Stop: quarantine path already exists" >&2
   else
     sudo mv -T --no-clobber "$source_dir" "$quarantine"
     if sudo test -e "$source_dir"; then
       echo "Stop: etcd directory was not moved" >&2
     else
       echo "Preserved at $quarantine"
     fi
   fi
   ```

   Stop if the move was not confirmed. K3s ignores its join arguments when
   an existing etcd datastore remains on disk.

4. Start k3s on the replaced host. Confirm that a new member joins, is
   promoted from learner if applicable, and that all three voters share a
   leader. If joining fails, preserve the quarantine and snapshots; do not
   improvise a cluster reset.

## 4. Verify recovery

- Compare all three member hashes at a common revision and compaction point.
- Check all API servers, nodes, Flux reconciliation, Longhorn volumes and
  CloudNativePG instance health.
- Verify application data and service behavior before resuming writes.
- Keep the quarantine, snapshots and token securely until the recovery and
  retention decisions are complete. Remove temporary transfer archives only
  after verifying the protected copies.

## References

- [etcd data corruption recovery](https://etcd.io/docs/v3.5/op-guide/data_corruption/)
- [K3s backup and restore](https://docs.k3s.io/datastore/backup-restore)
- [K3s embedded etcd HA](https://docs.k3s.io/datastore/ha-embedded)
