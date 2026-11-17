# Loki

## Introduction

Grafana Loki is a set of open source components that can be composed into a fully featured logging stack. A small index and highly compressed chunks simplifies the operation and significantly lowers the cost of Loki.

## Created Resources

| Kind | Name |
| ---- | ---- |
| [`HelmRelease`][ref-helm-release] | `loki` |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/

Loki has no web UI and no public route: it runs with `auth_enabled: false`, so query it through Grafana.
In-cluster clients use `http://loki.monitoring.svc:3100`; the vpslab pushes through the Tailscale Service in the prod overlay.

## Links

- [Documentation](https://grafana.com/docs/loki/latest/)
- [GitHub Repository](https://github.com/grafana/loki/)
- [Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/loki)
