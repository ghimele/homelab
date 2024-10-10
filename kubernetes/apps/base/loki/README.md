# Loki

## Introduction

Grafana Loki is a set of open source components that can be composed into a fully featured logging stack. A small index and highly compressed chunks simplifies the operation and significantly lowers the cost of Loki.

## Created Resources

| Kind                                | Name             |
| ----------------------------------- | ---------------- |
| [`HelmRelease`][ref-helm-release]   | `loki`           |
| [`Certificate`][ref-certificate]    | `loki.${DOMAIN}` |
| [`IngressRoute`][ref-ingress-route] | `loki`           |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/
[ref-certificate]: https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.Certificate
[ref-ingress-route]: https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroute

## Links

- [Documentation](https://grafana.com/docs/loki/latest/)
- [GitHub Repository](https://github.com/grafana/loki/)
- [Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/loki)
