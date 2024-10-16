# CloudNativePG

## Introduction

CloudNativePG is a comprehensive platform designed to seamlessly manage PostgreSQL databases within Kubernetes environments, covering the entire operational lifecycle from initial deployment to ongoing maintenance

## Created Resources

| Kind                                | Name             |
| ----------------------------------- | ---------------- |
| [`HelmRelease`][ref-helm-release]   | `cloudnative-pg` |
| [`Certificate`][ref-certificate]    | `loki.${DOMAIN}` |
| [`IngressRoute`][ref-ingress-route] | `loki`           |

[ref-helm-release]: https://fluxcd.io/docs/components/helm/helmreleases/
[ref-certificate]: https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.Certificate
[ref-ingress-route]: https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroute

## Links

- [Documentation](https://cloudnative-pg.io/documentation/current/)
- [GitHub Repository](https://github.com/cloudnative-pg/cloudnative-pg/)
- [Helm Chart](https://github.com/cloudnative-pg/charts)
