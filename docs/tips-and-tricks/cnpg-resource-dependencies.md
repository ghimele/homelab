# CloudNativePG production resource dependencies

The production CloudNativePG deployment is assembled from
`kubernetes/apps/prod/cloudnative-pg/kustomization.yaml` and depends on the
following Flux, Kubernetes, and external resources.

## Resource dependency graph

```mermaid
flowchart TD
  subgraph flux["Flux production resources"]
    K["cloudnative-pg Kustomization"]
  end

  subgraph operators["cnpg-system"]
    OP["CloudNativePG HelmRelease<br/>cloudnative-pg 0.29.2"]
    CRD["Cluster CRD"]
    BP["Barman Cloud HelmRelease<br/>plugin-barman-cloud 0.9.0"]
  end

  subgraph cluster["cnpg-db namespace"]
    NS["Namespace cnpg-db"]
    SEC["Application role secrets"]
    ST["Longhorn StorageClasses"]
    C["PostgreSQL Cluster<br/>postgres-cluster, 3 instances"]
    DB1["Database gotify"]
    DB2["Database homeassistant"]
    DB3["Database immich"]
    DB4["Database pocket-id"]
    CERT["PostgreSQL certificate"]
    ING["PostgreSQL ingress TCP"]
  end

  subgraph backup["Backup resources"]
    BSEC["SOPS Garage credentials"]
    EG["Tailscale ExternalName Service<br/>garage-vpslab"]
    OS["ObjectStore<br/>vpslab-garage"]
    SB["ScheduledBackup<br/>03:00 UTC"]
  end

  subgraph pgadmin["pgAdmin"]
    HR["pgAdmin HelmRelease"]
    PSEC["SOPS pgAdmin secret"]
    PVC["Longhorn 1 GiB PVC"]
    PCERT["pgAdmin certificate"]
    PING["pgAdmin ingress"]
  end

  subgraph external["External services"]
    LH["Longhorn"]
    CM["cert-manager"]
    TR["Traefik"]
    OIDC["Pocket ID"]
    GAR["vpslab Garage S3"]
  end

  K --> OP
  K --> BP
  K --> NS
  K --> C
  K --> HR

  OP --> CRD
  CRD --> C
  BP -. "depends on CloudNativePG" .-> OP
  BP --> OS

  NS --> SEC
  NS --> ST
  NS --> C
  SEC --> C
  ST --> C
  LH --> ST

  C --> DB1
  C --> DB2
  C --> DB3
  C --> DB4
  C --> CERT
  CM --> CERT
  CERT --> ING
  TR --> ING

  C --> SB
  BP --> SB
  BSEC --> OS
  EG --> OS
  OS --> GAR
  EG -. "Tailnet FQDN" .-> GAR
  SB --> C

  PSEC --> HR
  HR --> PVC
  LH --> PVC
  HR --> PCERT
  CM --> PCERT
  PCERT --> PING
  TR --> PING
  OIDC --> HR
  C -. "registered database servers" .-> HR
```

## Kustomize resource order

The top-level production Kustomization includes these resources:

1. `cnpg-operator`
2. `barman-cloud-plugin`
3. `cluster`
4. `pgadmin`

The `cluster` Kustomization creates the namespace and cluster dependencies in
this order:

- `cnpg-db` namespace
- PostgreSQL role/password Secrets
- Longhorn `StorageClass` configuration
- the three-instance `postgres-cluster`
- PostgreSQL certificate and ingress route
- application databases
- backup resources

## Runtime dependencies

- **CloudNativePG operator**: Requires Flux and the CNPG CRDs. It reconciles
  `Cluster`, `Database`, and `ScheduledBackup` resources.
- **Barman Cloud plugin**: Requires the CloudNativePG operator. It provides WAL
  archiving and base backups through the CNPG-I plugin.
- **`postgres-cluster`**: Requires the CNPG operator, role Secrets, and a
  Longhorn `StorageClass`. It runs three PostgreSQL 17 instances with vector
  support.
- **Application databases**: Require `postgres-cluster` and role Secrets. They
  create the Gotify, Home Assistant, Immich, and Pocket ID databases.
- **`ObjectStore`**: Requires Barman credentials and the Tailscale egress
  Service. It configures the off-site vpslab Garage S3 destination.
- **`ScheduledBackup`**: Requires `postgres-cluster`, the Barman plugin, and
  `ObjectStore`. It runs the daily 03:00 UTC base backup.
- **pgAdmin**: Requires the `pgadmin` SOPS Secret, Longhorn, cert-manager, and
  Traefik. It provides browser access and Pocket ID OIDC login.

## Rollout considerations

- Deploy the CloudNativePG operator before the `Cluster` resource.
- Install the Barman Cloud CRDs before enabling the plugin and `ObjectStore`.
- Create the role Secrets before the cluster is reconciled.
- Configure the Longhorn storage classes before provisioning cluster or pgAdmin
  volumes.
- Create the Garage Tailscale egress and S3 credentials before expecting
  backups to succeed.
- Create the Pocket ID OIDC client and pgAdmin SOPS Secret before enabling
  pgAdmin authentication.

For backup operations and recovery, see
[Back up the CNPG cluster to Garage on the vpslab](cnpg-backup-vpslab-garage.md).
