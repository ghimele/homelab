# Longhorn

## Introduction

Longhorn is a lightweight, reliable and easy-to-use distributed block storage system for Kubernetes.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `Longhorn` |
| [`Certificate`][ref-certificate] | `Longhorn.${DOMAIN}` |
| [`IngressRoute`][ref-ingress-route] | `Longhorn` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/
[ref-certificate]: https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.Certificate
[ref-ingress-route]: https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroute

## Links

- [Documentation](https://longhorn.io/docs/1.7.1/)
- [GitHub Repository](https://github.com/longhorn/longhorn)
- [Helm Chart](https://github.com/longhorn/longhorn/blob/fae17df8076a8b8630394f283b556cf17d2a720e/chart/Chart.yaml)
