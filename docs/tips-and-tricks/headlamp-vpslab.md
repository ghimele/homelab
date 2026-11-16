# Access vpslab from Headlamp over Tailscale

The homelab Headlamp instance can use the vpslab Kubernetes API through the Tailscale Kubernetes Operator's API server proxy. The API is not exposed publicly. The proxy authenticates the homelab egress device, and vpslab RBAC grants that identity read-only access.

Headlamp users authenticate to the homelab instance through Pocket ID. Requests to vpslab use the shared Tailscale egress identity, so every authenticated Headlamp user receives the same vpslab `view` permissions.

## Prerequisites

- HTTPS certificates are enabled for the tailnet.
- The vpslab Tailscale operator's OAuth client is allowed to create devices tagged `tag:vpslab-k8s-operator`.
- The homelab `TAILSCALE_PROXY_TAG` value identifies the source tag used by the Tailscale egress proxy.

## Deploy and configure

1. Add `tag:vpslab-k8s-operator` to the vpslab Tailscale OAuth client's permitted tags, then reconcile the vpslab repository. The Tailscale operator API proxy is enabled in auth mode and the vpslab cluster binds `headlamp-vpslab-ro` to the built-in `view` role.
2. In the Tailscale access policy, allow the homelab proxy tag to reach only the vpslab operator on TCP 443, and map that source to the Kubernetes read-only group. Replace the source placeholder with the exact `TAILSCALE_PROXY_TAG` value, including its `tag:` prefix:

   ```json
   {
     "grants": [
       {
         "src": ["<value-of-TAILSCALE_PROXY_TAG>"],
         "dst": ["tag:vpslab-k8s-operator"],
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
4. Reconcile homelab infrastructure. The Tailscale egress Service forwards TCP 443 to that device, and the Headlamp init container adds a `VPS-LAB` context without a Kubernetes bearer token. A NetworkPolicy allows only Headlamp pods to use this egress proxy.

The vpslab RBAC and API-proxy configuration are in `ghimele/vpslab` under `kubernetes/infrastructure/prod/tailscale`. The homelab egress Service and kubeconfig context are under `kubernetes/infrastructure/prod`.

## Verify

- In Headlamp, choose the `VPS-LAB` cluster and confirm that resources such as nodes and namespaces are visible.
- Verify that viewing Secrets is forbidden; the bound `view` role does not grant Secret access.
- Check the homelab egress Service condition with `kubectl --context <homelab-context> -n kube-system get service vpslab-api -o yaml` and inspect its `TailscaleEgressSvcReady` condition. Check the vpslab operator logs if the API proxy is not ready.

If access fails, confirm that the egress Service reports `TailscaleEgressSvcReady=True`, the MagicDNS name matches the operator device, the grant allows TCP 443, and the vpslab operator is tagged `tag:vpslab-k8s-operator`.

## Security notes

- Do not use `noauth` mode or add a vpslab service-account token to Headlamp's kubeconfig.
- Keep the grant scoped to the homelab proxy tag and vpslab operator tag. The custom Kubernetes group is mapped by that grant; do not bind it to a privileged role.
- The homelab NetworkPolicy restricts the egress proxy to Headlamp pods; retain its pod label if the Headlamp release name or chart configuration changes.
- The egress identity is shared by requests from Headlamp, so protect the Headlamp UI with its existing Pocket ID authentication.

References:

- [Tailscale Kubernetes API server proxy setup](https://tailscale.com/docs/kubernetes-operator/api-server-access/setup-api-over-tailscale)
- [Tailscale API proxy authentication and RBAC](https://tailscale.com/docs/kubernetes-operator/api-server-access/auth-and-rbac)
- [Tailscale cluster egress](https://tailscale.com/docs/kubernetes-operator/egress)
