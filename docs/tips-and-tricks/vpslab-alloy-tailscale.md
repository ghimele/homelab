# Send vpslab metrics and logs to the homelab with Alloy and Tailscale

`vpslab` (repository `ghimele/vpslab`) is the single-node k3s cluster running on the Hostinger VPS.
Grafana Alloy runs there as a DaemonSet, scrapes the VPS node-exporter and kube-state-metrics, tails the pod logs and pushes everything to the homelab production stack over Tailscale, so it can be queried in the homelab Grafana.

## How it works

| Item | Metrics | Logs |
| ---- | ------- | ---- |
| Source in vpslab | `prometheus-node-exporter` and `kube-state-metrics` pods of the same node, scraped every 60s | Pod logs of the same node, read through the Kubernetes API |
| vpslab egress Service | `homelab-prometheus` (`monitoring`) | `homelab-loki` (`monitoring`) |
| Tailnet device | `prometheus-prod` | `loki-prod` |
| Homelab target | Prometheus remote-write receiver, port `9090` | Loki push API, port `3100` |

- The homelab exposes both devices with the Tailscale operator (`tailscale-service.yaml` next to `kube-prometheus-stack` and `loki`). The data is pushed from vpslab, so the homelab does not scrape anything.
- Alloy is a plain DaemonSet: no `hostNetwork`, no host mounts. Its ClusterRole only allows `get`, `list` and `watch` on `pods` and `pods/log`.
  It scrapes the existing `prometheus-node-exporter` instead of Alloy's built-in unix exporter, which would need `hostNetwork` and would expose Alloy's HTTP port on the VPS public IP.
- Metrics carry `cluster="VPS-LAB"` (from `CLUSTER_NAME` in the vpslab `cluster-settings`), `job="node-exporter"` and `instance` / `nodename` set to the node name, like the in-cluster homelab node metrics.
- kube-state-metrics series carry `cluster="VPS-LAB"`, `job="kube-state-metrics"` and `nodename`, like the homelab kube-state-metrics job.
  They are scraped with `honor_labels`, as the kube-prometheus-stack ServiceMonitor does, so the `namespace`, `pod` and `container` labels of the described objects are kept.
  Only the Alloy pod on the node running kube-state-metrics scrapes it, so the series are never sent twice.
- Logs use the same labels as the homelab Alloy (`app`, `instance`, `component`, `namespace`, `pod`, `container`, `node_name`, `job`) plus `cluster="VPS-LAB"`.

## Files

| Repository | Path | Purpose |
| ---------- | ---- | ------- |
| homelab | `kubernetes/apps/prod/monitoring/kube-prometheus-stack/tailscale-service.yaml` | Exposes Prometheus as `prometheus-prod` |
| homelab | `kubernetes/apps/prod/monitoring/loki/tailscale-service.yaml` | Exposes Loki as `loki-prod` |
| vpslab | `kubernetes/repositories/grafana.yaml` | Grafana Helm repository |
| vpslab | `kubernetes/apps/monitoring/alloy/release.yaml` | Alloy HelmRelease and its configuration |
| vpslab | `kubernetes/apps/monitoring/alloy/rbac.yaml` | Minimal ClusterRole for Alloy |
| vpslab | `kubernetes/apps/monitoring/alloy/egress-homelab.yaml` | Tailscale egress Services to the two homelab devices |
| vpslab | `kubernetes/apps/monitoring/alloy/network-policy.yaml` | Only Alloy can use those egress proxies |

## Rollout

Order matters: the homelab devices must exist before vpslab can point at them.

1. Merge the homelab change and wait for Flux. Then read the tailnet IP of the two new devices:

   ```bash
   tailscale status | grep -E 'prometheus-prod|loki-prod'
   tailscale ip -4 prometheus-prod
   tailscale ip -4 loki-prod
   ```

2. In the vpslab repository add the two IPs to the SOPS-encrypted secret, under `stringData`:

   ```bash
   sops kubernetes/config/prod/secrets/cluster-secrets.enc.yaml
   ```

   ```yaml
   TAILSCALE_HOMELAB_PROMETHEUS_IP: <tailnet IP of prometheus-prod>
   TAILSCALE_HOMELAB_LOKI_IP: <tailnet IP of loki-prod>
   ```

3. Allow only the vpslab proxies to reach those two ports in the Tailscale policy (see [Security notes](#security-notes)). The tags are the ones used by each operator for its proxies; in vpslab it is the value of `TAILSCALE_PROXY_TAG`:

   ```json
   {
     "grants": [
       {
         "src": ["tag:<vpslab-proxy-tag>"],
         "dst": ["tag:<homelab-proxy-tag>"],
         "ip": ["tcp:9090", "tcp:3100"]
       }
     ]
   }
   ```

4. Merge the vpslab change.

If vpslab is merged before step 2, Flux substitutes an empty string and the operator ignores the egress Services (an empty `tailscale.com/tailnet-ip` is not a target).
Nothing else breaks: Alloy keeps retrying and starts delivering once the keys exist and Flux reconciles.

## Verify

On vpslab:

```bash
kubectl --context VPS-LAB -n monitoring get helmrelease alloy
kubectl --context VPS-LAB -n monitoring get pods -l app.kubernetes.io/instance=alloy
kubectl --context VPS-LAB -n monitoring get svc homelab-prometheus homelab-loki \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="TailscaleProxyReady")].status}{"\n"}{end}'
kubectl --context VPS-LAB -n monitoring logs -l app.kubernetes.io/instance=alloy -c alloy --since=10m
```

Both Services must report `True`, and the Alloy log must not show `remote_write` or `loki.write` errors.

In Grafana Explore, with a recent time range, select the Prometheus datasource and run:

```promql
up{job="node-exporter", cluster="VPS-LAB"}
node_uname_info{cluster="VPS-LAB"}
up{job="kube-state-metrics", cluster="VPS-LAB"}
kube_deployment_status_replicas_available{cluster="VPS-LAB"}
```

Then select the Loki datasource and run:

```logql
{cluster="VPS-LAB", namespace="monitoring", app="alloy"}
```

Dashboards that select `job="node-exporter"` can now show the VPS node, identified by its node name in `instance`.
The `Kubernetes / Views` dashboards take their `cluster` variable from `kube_node_info`, so they now list `VPS-LAB`. A series that stops updating means Alloy or the tunnel is down.

| Symptom in the Alloy log | Check |
| ------------------------ | ----- |
| `lookup ... no such host` | The egress Service was not reconciled: the SOPS key is missing or empty, or the operator is not running. |
| `i/o timeout` | The Tailscale policy does not allow vpslab to reach the port, or the `homelab-egress-alloy-only` NetworkPolicy does not match the Alloy pods. |
| `404` on `/api/v1/write` | The Prometheus remote-write receiver is disabled (`enableRemoteWriteReceiver` in the kube-prometheus-stack values). |

## Security notes

- The tailnet device exposes the whole Prometheus port, not only `/api/v1/write`: the query API and, because Prometheus runs with `--web.enable-lifecycle`, the `/-/reload` and `/-/quit` endpoints.
  Loki runs with `auth_enabled: false`, so anyone reaching port `3100` can also read the logs (and use the delete API if it is enabled).
  The Tailscale policy above is therefore the real access control: allow only the vpslab proxy tag and only `tcp:9090` and `tcp:3100`.
  For a narrower rule, give the two homelab Services a dedicated tag with the `tailscale.com/tags` annotation.
- The Tailscale egress proxy forwards everything it receives, so without a NetworkPolicy any pod in vpslab, including the public WordPress sites, could call those APIs.
  `homelab-egress-alloy-only` (namespace `tailscale`) only admits the Alloy pods, and k3s enforces it with its embedded network policy controller.
  It was validated offline only: if Alloy cannot connect after the rollout, remove it first to rule it out.
- node-exporter runs with `hostNetwork` and listens on port `9100` of the VPS public IP. Check that the VPS firewall blocks that port from the internet; Alloy reaches it from inside the node.

## Heads-up

- The default node alerts of kube-prometheus-stack select `job="node-exporter"`, so they now also evaluate the VPS series.
  The `kubernetes-apps` and `kubernetes-storage` alerts select `job="kube-state-metrics"`, so they now also cover vpslab workloads (crash loops, replica mismatches, failed jobs); the `cluster` label tells the two clusters apart.
- Every vpslab pod log, including Alloy's own, goes to the homelab Loki. Watch the size of the Loki volume. To ship less, restrict `discovery.kubernetes "pods"` with a `namespaces` block in the vpslab `release.yaml`.
- The Alloy push replaces the old VictoriaMetrics pull path, which has been removed. VictoriaMetrics is no longer deployed in homelab prod.
  The vpslab node-exporter and kube-state-metrics Services no longer carry `tailscale.com/expose`.
  The homelab egress Services `vps-node-exporter` and `vps-kube-state-metrics` and the vmagent jobs `VPSLAB` and `VPSLAB-KUBESTAT` are gone.
  The SOPS keys `TAILSCALE_VPSLAB_NODE_EXPORTER_IP` and `TAILSCALE_VPSLAB_KUBE_STATE_METRICS_IP` are now unused and can be deleted.
  Any Tailscale policy rule that allowed homelab to reach vpslab on `tcp:9100` or `tcp:8080` can be deleted too.
- The kubelet and cAdvisor metrics of vpslab are not forwarded, so the `Kubernetes / Views` panels based on container CPU, memory and network usage (`container_*`) stay empty for `VPS-LAB`.
- vpslab never ran Promtail, so there was nothing to remove there. Alloy replaces it for log shipping. The homelab repository still has unreferenced Promtail manifests under `kubernetes/apps`, left untouched.
- The egress Services use `tailscale.com/tailnet-ip`, like the existing homelab egress Services. If a device is recreated its IP changes and the SOPS key must be updated; `tailscale.com/tailnet-fqdn` avoids that.

## References

- [Tailscale Kubernetes operator: cluster egress](https://tailscale.com/kb/1438/kubernetes-operator-cluster-egress)
- [Tailscale Kubernetes operator: cluster ingress](https://tailscale.com/kb/1439/kubernetes-operator-cluster-ingress)
- [Alloy `discovery.kubernetes`](https://grafana.com/docs/alloy/latest/reference/components/discovery/discovery.kubernetes/)
- [Alloy `prometheus.remote_write`](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.remote_write/)
- [Alloy `loki.source.kubernetes`](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.source.kubernetes/)
- [Alloy `loki.write`](https://grafana.com/docs/alloy/latest/reference/components/loki/loki.write/)
- [Prometheus remote-write specification](https://prometheus.io/docs/specs/prw/remote_write_spec/)
