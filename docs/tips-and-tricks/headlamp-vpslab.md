# Access vpslab from Headlamp over Tailscale

The homelab Headlamp instance can use the vpslab Kubernetes API through the Tailscale Kubernetes Operator's API server proxy. The API is not exposed publicly. The proxy authenticates the homelab egress device, and vpslab RBAC grants that identity read-only access.

Headlamp users authenticate to the homelab instance through Pocket ID. Requests to vpslab use the shared Tailscale egress identity, so every authenticated Headlamp user receives the same vpslab `view` permissions.

## Prerequisites

- HTTPS certificates are enabled for the tailnet.
- The homelab `TAILSCALE_PROXY_TAG` value identifies the source tag used by the Tailscale egress proxy.
- The tag of the vpslab operator device. Check it in the admin console or with `tailscale whois <operator-ip>` from a proxy pod. This guide assumes the default `tag:k8s-operator`.

## Deploy and configure

1. Reconcile the vpslab repository. The Tailscale operator API proxy is enabled in auth mode and the vpslab cluster binds `headlamp-vpslab-ro` to the built-in `view` role.
2. In the Tailscale access policy, allow the homelab proxy tag to reach the vpslab operator on TCP 443, and map that source to the Kubernetes read-only group. Replace the source placeholder with the exact `TAILSCALE_PROXY_TAG` value, including its `tag:` prefix, and the destination with the operator device's actual tag:

   ```json
   {
     "grants": [
       {
         "src": ["<value-of-TAILSCALE_PROXY_TAG>"],
         "dst": ["tag:k8s-operator"],
         "ip": ["tcp:443"],
         "app": {
           "tailscale.com/cap/kubernetes": [
             {
               "impersonate": {
                 "groups": ["headlamp-vpslab-ro"]
               }
             }
           ]
         }
       }
     ]
   }
   ```

3. Find the full MagicDNS name of the vpslab operator device in the Tailscale admin console (for example, `vpslab-operator.<tailnet>.ts.net`). Add it as `TAILSCALE_VPSLAB_API_FQDN` under `stringData` in the SOPS-encrypted homelab `cluster-secrets`.
4. Reconcile homelab infrastructure. The Tailscale egress Service forwards TCP 443 to that device, and the Headlamp init container adds a `VPS-LAB` context. Headlamp ignores contexts without a user, so the context uses the placeholder token `unused`; the API proxy authenticates by tailnet identity and does not use it. A NetworkPolicy allows only Headlamp pods to use this egress proxy.

The vpslab RBAC and API-proxy configuration are in `ghimele/vpslab` under `kubernetes/infrastructure/prod/tailscale`. The homelab egress Service and kubeconfig context are under `kubernetes/infrastructure/prod`.

## Verify

- In Headlamp, choose the `VPS-LAB` cluster and confirm that resources such as nodes and namespaces are visible.
- Verify that viewing Secrets is forbidden; the bound `view` role does not grant Secret access.
- Check the homelab egress Service condition with `kubectl --context <homelab-context> -n kube-system get service vpslab-api -o yaml` and inspect its `TailscaleEgressSvcReady` condition. Check the vpslab operator logs if the API proxy is not ready.

## Troubleshooting

- `VPS-LAB` is not listed in Headlamp: check the `headlamp` container logs for `error in context VPS-LAB`. Headlamp drops contexts that have no user, and skips the context entirely if `TAILSCALE_VPSLAB_API_FQDN` is empty.
- `VPS-LAB` is listed but every resource is Forbidden for `User "<proxy>.<tailnet>.ts.net"` with no `headlamp-vpslab-ro` group: the grant does not match. Its `dst` must be the tag the operator device actually has. `OPERATOR_INITIAL_TAGS` only applies when a device is first registered, so changing `defaultTags` later does not retag an existing operator.
- The first request can fail with `TLS handshake timeout` while the proxy obtains its certificate. Retry after a minute.
- Connections from a brand-new pod can be refused for a few seconds until the NetworkPolicy has synced its pod label.
- Confirm that the egress Service reports `TailscaleProxyReady=True` and the MagicDNS name in `TAILSCALE_VPSLAB_API_FQDN` matches the operator device.

## Security notes

- Do not use `noauth` mode or add a vpslab service-account token to Headlamp's kubeconfig.
- Keep the grant scoped to the homelab proxy tag and the vpslab operator tag. The custom Kubernetes group is mapped by that grant; do not bind it to a privileged role. To scope the grant tighter than the shared `tag:k8s-operator`, register the vpslab operator under a dedicated tag (delete the device and the `operator` state Secret so it re-registers) and point `dst` at it.
- The homelab NetworkPolicy restricts the egress proxy to Headlamp pods; retain its pod label if the Headlamp release name or chart configuration changes.
- The egress identity is shared by requests from Headlamp, so protect the Headlamp UI with its existing Pocket ID authentication.

References:

- [Tailscale Kubernetes API server proxy setup](https://tailscale.com/docs/kubernetes-operator/api-server-access/setup-api-over-tailscale)
- [Tailscale API proxy authentication and RBAC](https://tailscale.com/docs/kubernetes-operator/api-server-access/auth-and-rbac)
- [Tailscale cluster egress](https://tailscale.com/docs/kubernetes-operator/egress)
