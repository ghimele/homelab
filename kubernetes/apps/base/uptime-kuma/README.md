# Uptime Kuma

## Introduction

Uptime Kuma is an easy-to-use self-hosted monitoring tool.

## Created Resources

| Kind                                | Name             |
| ----------------------------------- | ---------------- |
| [`HelmRelease`][ref-helm-release]   | `uptime-kuma`           |
| [`Certificate`][ref-certificate]    | `uptime-kuma.${DOMAIN}` |
| [`IngressRoute`][ref-ingress-route] | `uptime-kuma`           |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/
[ref-certificate]: https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.Certificate
[ref-ingress-route]: https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroute

## Links

- [Documentation](https://github.com/louislam/uptime-kuma/wiki)
- [GitHub Repository](https://github.com/louislam/uptime-kuma)
- [Helm Chart](https://github.com/dirsigler/uptime-kuma-helm/tree/main)
