# CNPG cluster

## Introduction

The CNPG cluster chart follows a convention over configuration approach

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `postgres-cluster` |
| [`Certificate`][ref-certificate] | `postgres-cluster.${DOMAIN}` |
| [`IngressRoute`][ref-ingress-route] | `postgres-cluster` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/
[ref-certificate]: https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.Certificate
[ref-ingress-route]: https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroute

## Backups

The prod cluster archives its WAL and takes daily base backups to the Garage bucket on the vpslab through the Barman Cloud plugin (`kubernetes/apps/prod/cloudnative-pg/cluster/backup`).
See [cnpg-backup-vpslab-garage.md](/docs/tips-and-tricks/cnpg-backup-vpslab-garage.md) for rollout, monitoring and the restore procedure.

## Links

- [Documentation](https://github.com/cloudnative-pg/charts/blob/main/charts/cluster/docs/Getting%20Started.md)
- [GitHub Repository](https://github.com/cloudnative-pg/cloudnative-pg/)
- [Helm Chart](https://github.com/cloudnative-pg/charts)
