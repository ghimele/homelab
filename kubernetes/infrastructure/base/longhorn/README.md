# Longhorn

## Introduction

Longhorn is a lightweight, reliable and easy-to-use distributed block storage system for Kubernetes.

## Production pod placement

The [production overlay](../../prod/longhorn/values.yaml) spreads the global manager and UI across eligible workers by hostname, with a maximum skew of one pod per component. It does not set a minimum number of domains, so replicas can share the remaining eligible workers after a node outage. The CSI controllers retain Longhorn's preferred (not required) pod anti-affinity.

To redistribute already-running CSI controllers after an outage, use a maintenance window. Check that Longhorn and the destination workers are healthy and avoid concurrent volume operations. Cordon the crowded worker without draining it, then use the Kubernetes Eviction API to move **one** `csi-attacher`, `csi-provisioner`, `csi-resizer`, or `csi-snapshotter` pod at a time. Wait for the replacement to become Ready on another worker and the Deployment to recover its ready replica count before continuing. Stop if eviction is blocked or a replacement cannot schedule, and uncordon the worker when done. Do not evict the CSI plugin, instance managers, or share managers for this rebalance.

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
