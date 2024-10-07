# `kube-prometheus-stack`

## Introduction

The `kube-prometheus-stack` is an easy to manage but powerful way to operate a complete monitoring stack consisting of [Prometheus](https://prometheus.io/docs/introduction/overview/), [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/) and [Grafana](https://grafana.com/grafana/). It makes use of the community managed [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) which makes Kubernetes native Prometheus deployments a breeze.

The Prometheus Operator looks for `ServiceMonitor` and `PodMonitor` objects in all namespaces and adds them to it's list of scrape targets. Most Helm charts already provide those monitor objects behind a values flag. If there was no corresponding flag available a manual declaration was added to this repository as follows:

=== "Example of kind `ServiceMonitor`"

    ```yaml
    apiVersion: monitoring.coreos.com/v1
    kind: ServiceMonitor
    metadata:
      name: cloudflared
      namespace: cloudflared
    spec:
      endpoints:
        - port: http
          path: /metrics
          interval: 30s
      selector:
        matchLabels:
          app.kubernetes.io/name: cloudflared # references the target object (1)
    ```

    1. Selector label which references the target `Service` object to monitor.

=== "Example of kind `PodMonitor`"

    ```yaml
    apiVersion: monitoring.coreos.com/v1
    kind: PodMonitor
    metadata:
      name: cloudflared
      namespace: cloudflared
    spec:
      podMetricsEndpoints:
        - port: http
      selector:
        matchLabels:
          app.kubernetes.io/name: cloudflared # references the target object (1)
    ```

    1. Selector label which references the target `Pod` object to monitor.

## Created Resources

| Kind                                | Name                                                                  |
| ----------------------------------- | --------------------------------------------------------------------- |
| [`HelmRelease`][ref-helm-release]   | `kube-prometheus-stack`                                               |
| [`Certificate`][ref-certificate]    | `prometheus.${DOMAIN}`, `alerts.${DOMAIN}`, `grafana.${DOMAIN}`       |
| [`IngressRoute`][ref-ingress-route] | `dashboard-prometheus`, `dashboard-alertmanager`, `dashboard-grafana` |
| [`ConfigMap`][ref-config-map]       | `grafana-dashboard-nodes`, `grafana-dashboard-containers`             |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/
[ref-certificate]: https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.Certificate
[ref-ingress-route]: https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroute
[ref-config-map]: https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/config-map-v1/

## Links

- [Documentation](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md)
- [GitHub Repository](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Helm Chart](https://prometheus-community.github.io/helm-charts/)