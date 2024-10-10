# Promtail

## Introduction

Promtail is an agent which ships the contents of local logs to a private Grafana Loki instance or Grafana Cloud. It is usually deployed to every machine that runs applications which need to be monitored.

## Created Resources

| Kind                                | Name             |
| ----------------------------------- | ---------------- |
| [`HelmRelease`][ref-helm-release]   | `promtail`           |
| [`Certificate`][ref-certificate]    | `promtail.${DOMAIN}` |
| [`IngressRoute`][ref-ingress-route] | `promtail`           |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/
[ref-certificate]: https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.Certificate
[ref-ingress-route]: https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroute

## Links

- [Documentation](https://grafana.com/docs/loki/latest/send-data/promtail/)
- [GitHub Repository](https://github.com/grafana)
- [Helm Chart](https://github.com/grafana/helm-charts/blob/main/charts/promtail/Chart.yaml)
