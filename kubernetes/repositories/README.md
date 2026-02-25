# Charts

All [services](/cluster/services/) inside the cluster are deployed by Flux using [Helm charts](https://helm.sh/docs/topics/charts/).
To ensure the existence of all chart repositories before the service reconciliation they're grouped together and applied as a [`Kustomization`](https://fluxcd.io/docs/components/kustomize/kustomization/) dependency for all services.

The following chart repositories will be created as [`HelmRepository` declarations](https://fluxcd.io/docs/components/source/helmrepositories/) by this section:

- `jetstack` → <https://charts.jetstack.io>
- `ghimele` → <https://ghimele.github.io/helm-charts/>
- `traefik` → <https://helm.traefik.io/traefik>

Flux checks these helm repositories regularly at the specified intervals of `10m0s` and updates the [`HelmRelease`](https://fluxcd.io/docs/components/helm/helmreleases/) objects accordingly.

Below there is an "Example of a `HelmRepository` declaration"

    ```yaml
    apiVersion: source.toolkit.fluxcd.io/v1
    kind: HelmRepository
    metadata:
      name: ghimele
      namespace: flux-system
    spec:
      interval: 10m0s
      url: <https://ghimele.github.io/helm-charts/
    ```
