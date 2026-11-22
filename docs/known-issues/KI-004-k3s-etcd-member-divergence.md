# KI-004 — k3s etcd members report inconsistent cluster state

## Status

Mitigated

## First observed

2026-11-21

## Last updated

2026-11-21

## Affected components

- k3s control-plane servers and embedded etcd
- Kubernetes node readiness and API consumers
- Longhorn, CloudNativePG and application workloads

---

## Summary

The three control-plane API servers returned contradictory node readiness and
lease information. Requests through the shared API address could therefore
show different nodes as `NotReady` depending on which server answered.

The etcd members reported the same cluster ID, leader and Raft term, but
linearizable reads returned different values for the same key. Two members
agreed on a hash at the same revision and compaction point; the third member's
data had diverged.

## Impact

- Node readiness and API responses depended on the control-plane server used.
- Longhorn volumes were reported degraded or faulted and workloads could not
  attach storage.
- The primary CloudNativePG cluster became unavailable during the incident.
- Kubernetes changes unique to the replaced member were not merged into the
  surviving state. The extent of any lost application changes was not
  established.

## Root cause

The immediate cause was inconsistent etcd member data within one Raft cluster;
this was **not proven to be two independent clusters**. Similar Raft indexes
and a healthy API readiness check did not guarantee identical etcd data.

After a restart at approximately 14:08 local time, `svp-khc01` logged a
restored backend consistent index one ahead of its logged commit index. A new
leader subsequently replaced a conflicting Raft entry at that index. This
is a possible contributor to the divergence, not a confirmed root cause.
The reason for the divergence remains unconfirmed.

## Detection

- Query each control-plane API directly rather than relying only on the shared
  address. Compare node conditions and leases.
- Compare etcd member IDs, cluster IDs, leaders, Raft indexes and data
  revisions using `etcdctl endpoint status`.
- Compare `endpoint hashkv` at the **same revision**, and compare its
  compaction revision. A compacted revision or different compaction points
  do not provide a valid hash comparison.
- A linearizable read of the same key from each endpoint can provide further
  evidence of differing member state.

See the [recovery runbook](../runbooks/k3s-etcd-member-divergence.md) for
commands and safety checks.

## Resolution

During an approved maintenance window, application writes were paused and
separate etcd snapshots and the K3s server token were preserved. The
divergent `svp-khc01` member was stopped and removed. After verifying that
`svp-khc02` and `svp-khc03` retained quorum and matching hashes, the old 01
etcd directory was quarantined and 01 rejoined as a new member.

All three members subsequently returned matching hashes at the same revision.
All six nodes became Ready, CloudNativePG reported three healthy instances,
and all 31 Longhorn volumes reported healthy.

## Data safety

- The old member database was retained rather than deleted, and snapshots
  from all three members were retained with the server token.
- etcd snapshots contain Kubernetes state and may contain secrets; they do
  **not** back up Longhorn volume contents or PostgreSQL data.
- Matching etcd hashes and healthy volume status do not prove application
  data completeness or that a database backup can be restored.
- Replacing a member discards its unique state from the active cluster. Do not
  select a recovery source solely because it is leader or has the highest
  revision.

## Prevention

- Investigate the original restart and backend/Raft inconsistency before
  claiming the underlying cause is fixed.
- Monitor member health and compare data hashes at a common revision when
  diagnosing divergent API responses.
- Maintain and test protected, off-host etcd snapshots, the K3s server token,
  and independent application and volume backups.
- Confirm quorum and data consistency before any reset, restore or member
  replacement.

## Related runbooks

- [Recovering a divergent k3s etcd member](../runbooks/k3s-etcd-member-divergence.md)

## References

- [etcd data corruption and recovery](https://etcd.io/docs/v3.5/op-guide/data_corruption/)
- [K3s backup and restore](https://docs.k3s.io/datastore/backup-restore)
- [K3s embedded etcd HA](https://docs.k3s.io/datastore/ha-embedded)
