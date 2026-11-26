# Monitor Immich with metrics and logs

## Components

- Immich built-in telemetry provides API latency, database/I/O timings, host usage and processing job metrics.
- `immich-exporter` reads the Immich REST API and provides library content, storage, users, jobs, integrity and backup metrics.
- Alloy collects Kubernetes pod logs and writes them to Loki.
- Grafana provides the Prometheus and Loki datasources and the `immich-exporter` dashboard.

## Prerequisites

Create an Immich API key in **Account Settings → API Keys** for an administrator account with the `all` permission.

Add the key to the production SOPS secret:

```bash
sops kubernetes/config/prod/secrets/cluster-secrets.enc.yaml
```

Add:

```yaml
IMMICH_EXPORTER_API_TOKEN: <the Immich API key>
```

Flux substitutes this value into `media/immich-exporter`.

The key should be read-only through the exporter. Do not expose the exporter Service outside the cluster. The `/metrics` endpoint contains library metadata such as names and locations.

## Built-in telemetry

The Immich server is configured with:

```yaml
IMMICH_TELEMETRY_INCLUDE: all
IMMICH_LOG_FORMAT: json
```

The chart also creates Immich metrics ServiceMonitors. If job metrics are missing, verify that both Immich metrics ports are scraped. Immich exposes API metrics on port `8081` and microservices/worker metrics on port `8082`.

## Exporter

The exporter runs in the `media` namespace and is scraped every minute by Prometheus. It uses:

- Poll interval: `2m`
- Breakdown interval: `15m`
- Per-person collection: disabled

## Grafana

After reconciliation, Grafana should contain:

- `Prometheus` datasource, UID `prometheus`
- `Loki` datasource, UID `loki`
- **Immich Library** dashboard, Grafana ID `26030`

Useful Loki queries:

```logql
{namespace="media", app="immich"}
```

```logql
{namespace="media", pod=~"immich-machine-learning.*"} |= "error"
```

Useful Prometheus checks:

```promql
up{namespace="media", service="immich-exporter"}
```

```promql
{__name__=~"immich.*"}
```

## Verification

```bash
kubectl -n media get deploy immich-server immich-machine-learning immich-exporter
kubectl -n media get svc immich-exporter
kubectl -n media get servicemonitor immich-exporter
kubectl -n media logs deploy/immich-exporter --tail=100
kubectl -n media port-forward svc/immich-exporter 8000:8000
```

Open `http://localhost:8000/metrics` and verify it contains `immich_up` and `immich_*` series. In Grafana, verify the Immich dashboard resolves the `Prometheus` datasource.

## Rollback

Disable only the exporter resources by removing `exporter.yaml` and `exporter-credentials.yaml` from the Immich kustomization. Remove the API key from the SOPS secret if it is no longer required.

To disable built-in telemetry and structured logs, remove `IMMICH_TELEMETRY_INCLUDE` and `IMMICH_LOG_FORMAT` from the Immich values.
