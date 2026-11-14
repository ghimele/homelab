# ADR-011: Back Up CNPG to Garage on the vpslab with the Barman Cloud Plugin

## Status

Accepted

## Date

2026-11-14

## Context and Problem Statement

The production CloudNativePG cluster `postgres-cluster` (Home Assistant, Immich, Gotify, Pocket-ID, about 3.4 GB) had no off-site backup: only Longhorn replicas inside the homelab.
The Hostinger VPS managed by the `ghimele/vpslab` repository is already joined to the tailnet and has about 80 GB of free disk, but only about 430m of unreserved CPU.

The backup must:

- allow point-in-time recovery, not only nightly dumps
- use few resources on the VPS
- be managed by Flux in both repositories, with secrets in SOPS
- be restorable with standard CNPG tooling

## Solution (Decision)

Use the CloudNativePG **Barman Cloud plugin** (CNPG-I) for continuous WAL archiving and daily base backups. The target is a single-node **Garage** S3 server on the vpslab, reached over the **Tailscale** operator (homelab egress, vpslab ingress).

- Garage is a small Rust binary (about 10 MiB of memory at idle), purpose-built for self-hosted S3, actively maintained, and bootstrapped declaratively through its admin API by an idempotent Job.
- The plugin is the upstream replacement for the in-tree `barmanObjectStore`, deprecated since CNPG 1.26. It gives PITR within a 14-day window, `zstd` compression, retention, metrics and declarative restores.
- Only the S3 port is published on the tailnet for the homelab, protected by a Tailscale grant and by NetworkPolicies on both sides.
  A small admin web UI ([garage-webui](https://github.com/khairul169/garage-webui)) is also published on the tailnet only, behind its own login.

Details, rollout and restore procedure: [cnpg-backup-vpslab-garage.md](../tips-and-tricks/cnpg-backup-vpslab-garage.md).

## Alternatives

- **pg_dump + restic to the VPS**: encrypted and simple, but only daily logical snapshots (no PITR). It also costs CPU on every run. It stays an option as an encrypted second layer.
- **Longhorn backup target on the VPS (NFS/S3)**: crash-consistent volume copies, not database-consistent backups, and no PITR.
- **CNPG replica cluster on the VPS**: always-on PostgreSQL on a CPU-constrained node, and it replicates logical errors (a dropped table) immediately.
- **MinIO**: the community edition repository was archived in February 2026, and the image is heavier than Garage.
- **SeaweedFS / Ceph RGW**: more components and memory than needed for a single bucket.

## Comparison Table

| Feature/Criteria | Barman plugin → Garage | pg_dump + restic | Longhorn backup target | Replica cluster |
| ---------------- | ---------------------- | ---------------- | ---------------------- | --------------- |
| **Point-in-time recovery** | Yes (14 days) | No (daily) | No | Latest only |
| **VPS resources** | Very low | Low | Low | High (PostgreSQL) |
| **Encryption at rest** | No | Yes | Optional | No |
| **Restore tooling** | Native CNPG | Manual | Longhorn | Promote replica |
| **Cost** | Free | Free | Free | Free |
| **Community Support** | CNPG + Garage, active | Large | Large | CNPG, active |

## Consequences

### Positive Outcomes

- Off-site, point-in-time recoverable backups, restorable declaratively with a new `Cluster`.
- Small footprint: Garage requests 25m CPU / 128Mi, and the plugin sidecar requests 50m / 128Mi per instance.
- Backup health is monitored with the plugin metrics and a WAL backlog alert.

### Negative Outcomes

- Backups are stored unencrypted on the VPS disk, and the homelab key can delete them.
- If archiving stops (tunnel, Garage or quota), WAL accumulates on the 30Gi WAL volume, which lasts about 5 days before the primary stops.
- Single copy on a single node: losing the VPS disk loses the backups (the live cluster is unaffected).

### Trade-offs

- PITR and native restores were preferred over client-side encryption. An encrypted logical dump can be added later as a second layer.
- Plain HTTP between the plugin and Garage is acceptable because the hop that leaves the cluster is WireGuard-encrypted by Tailscale.
