# Reach the vpslab API only over Tailscale

Use `kubectl` and Headlamp Desktop on the vpslab cluster through the Tailscale Kubernetes Operator's API server proxy, then close port 6443 on the VPS.
The proxy is reachable only on the tailnet and authenticates you by your Tailscale identity, so the kubeconfig holds no cluster credential.

The homelab Headlamp instance uses the same proxy with a read-only group; see [headlamp-vpslab.md](headlamp-vpslab.md).

## How it works

- The vpslab operator serves the Kubernetes API proxy on `https://<operator-fqdn>` (TCP 443, tailnet only). The certificate comes from the tailnet HTTPS feature and is publicly trusted, so the kubeconfig needs no CA.
- The proxy runs in auth mode and impersonates the caller. For a user-owned device, the Kubernetes user is the Tailscale login name. The Kubernetes groups come from the `tailscale.com/cap/kubernetes` grants that match the caller.
- The token in the kubeconfig is the placeholder `unused`, which the proxy ignores. Clients such as Headlamp still need a user entry in the context.
- Access is the Tailscale grant (which group you get) plus the vpslab RBAC (what the group may do).

## Prerequisites

- The setup in [headlamp-vpslab.md](headlamp-vpslab.md) is deployed: HTTPS certificates are enabled for the tailnet and the vpslab operator runs the API proxy in auth mode.
- The operator device has the tag `tag:k8s-operator` (used in the grant below) and the MagicDNS name `<operator-fqdn>`, for example `vpslab-operator.<tailnet>.ts.net`.
- Tailscale runs on your workstation and `tailscale ping <operator-fqdn>` succeeds.

## Deploy the admin binding

Reconcile the vpslab repository. `admin-rbac.yaml` in `ghimele/vpslab` under `kubernetes/infrastructure/prod/tailscale` binds the group `vpslab-admins` to `cluster-admin`.
The group has no members until the access policy assigns it, so the binding grants nothing by itself.

## Configure kubectl and Headlamp Desktop

kubectl and Headlamp Desktop both read `~/.kube/config`. Back up the file first.

If a `VPS-LAB` entry already exists with the public IP, the k3s CA and the admin client certificate, delete its cluster and user so that none of it is kept:

```shell
kubectl config delete-cluster VPS-LAB
kubectl config delete-user VPS-LAB
```

Create the entries that point to the proxy. The server URL uses `https` without a port, and the user holds only the placeholder token:

```shell
kubectl config set-cluster VPS-LAB --server=https://<operator-fqdn>
kubectl config set-credentials VPS-LAB --token=unused
kubectl config set-context VPS-LAB --cluster=VPS-LAB --user=VPS-LAB
```

An existing context keeps its namespace; add `--namespace=<name>` to set one. Restart Headlamp Desktop; it lists every context of the file.

As an alternative, `tailscale configure kubeconfig <operator-fqdn>` (alpha) creates a context named `<operator-fqdn>` with a `tailscale-auth` user, and makes it the current context.

Read your Tailscale login name from the proxy. Until the grant exists, the groups are only `system:authenticated` and every resource request is forbidden:

```shell
kubectl --context VPS-LAB auth whoami
```

## Grant cluster-admin to your user

In the Tailscale access policy, map your login (the `Username` printed above) to the `vpslab-admins` group.
Use this dedicated group instead of `system:masters`: the built-in group bypasses RBAC, so deleting the binding would not revoke it.

```json
{
  "grants": [
    {
      "src": ["<tailscale-login>"],
      "dst": ["tag:k8s-operator"],
      "ip": ["tcp:443"],
      "app": {
        "tailscale.com/cap/kubernetes": [
          {
            "impersonate": {
              "groups": ["vpslab-admins"]
            }
          }
        ]
      }
    }
  ]
}
```

Set `dst` to the operator device's actual tag. Keep `src` to your own login; do not use `autogroup:member`.
This grant does not affect the Headlamp grant, which only matches the homelab proxy tag.

## Verify

Run these before closing the port:

```shell
kubectl --context VPS-LAB auth whoami
kubectl --context VPS-LAB auth can-i '*' '*'
kubectl --context VPS-LAB get nodes -o wide
```

- `auth whoami` lists `vpslab-admins` in the groups.
- `auth can-i` prints `yes`.
- `get nodes` lists the nodes. Note how many there are: the next section assumes a single node.
- In Headlamp Desktop, open `VPS-LAB` and confirm that Nodes and Secrets load.

## Close port 6443

Outside the VPS, only k3s agent nodes need port 6443. Pods, Flux and the Tailscale operator reach the API server through the in-cluster `kubernetes` service, which the node forwards to its own port 6443 without using the public interface.
If the cluster has agent nodes that join over the public address, allow only their IPs on 6443 instead of closing it.

ufw is not installed on Debian by default, and this setup does not need it. Close the port in the Hostinger firewall (option 1), with a dedicated nftables table on the VPS (option 2), or with both. Keep an SSH session open while you change either one.

### Option 1: Hostinger firewall

The Hostinger firewall filters traffic before it reaches the VPS, so it never sees the traffic from pods to the API server. In hPanel, open the VPS, then **Security** → **Firewall**:

- If a firewall group is active on the server, edit it and delete the accept rule for TCP 6443. A single node needs no public access to the kubelet port 10250 either, so delete that rule too if it exists.
- If no group is active, create one that accepts only what the VPS serves publicly, then activate it. Typically that is SSH (22), plus HTTP (80) and HTTPS (443) for Traefik; `sudo ss -tulpn` lists the listening ports.
  An active group drops every port without an accept rule, and a group without any rule blocks everything, including SSH.
- Tailscale needs no inbound rule, because the operator connects outbound. Accept UDP 41641 only if you want direct instead of relayed tailnet connections.

Changes apply within two minutes and do not interrupt established connections.

### Option 2: nftables on the VPS

A separate nftables table drops tcp/6443 on the public interface only and leaves the rules that k3s manages alone.
Pods reach the node through the pod network bridge (`cni0` with the default flannel setup) and local clients through `lo`. Neither is the public interface, so Flux, the Tailscale operator and `sudo k3s kubectl` keep working.

Install nftables if `nft` is missing, then read the public interface name after `dev`:

```shell
command -v nft || sudo apt install -y nftables
ip route show default
```

Create `/etc/k3s-api-guard.nft` and replace `eth0` with that interface name:

```text
# Drop tcp/6443 arriving on the public interface. Pods (cni0) and the node itself (lo) are unaffected.
table inet k3s_api_guard
delete table inet k3s_api_guard

table inet k3s_api_guard {
  chain input {
    type filter hook input priority -10; policy accept;
    iifname "eth0" tcp dport 6443 counter drop
  }
}
```

The first two lines make loading repeatable: the file replaces the table instead of adding rules to it. `inet` covers IPv4 and IPv6. To close the kubelet port as well, write `tcp dport { 6443, 10250 }`.

Check the syntax and load the rule. It is not persistent yet, so a reboot removes it:

```shell
sudo nft -c -f /etc/k3s-api-guard.nft
sudo nft -f /etc/k3s-api-guard.nft
```

After the checks in the next section pass, make the rule persistent with a systemd unit that loads the table before the network comes up. Create `/etc/systemd/system/k3s-api-guard.service`:

```ini
[Unit]
Description=Block public access to the k3s API (tcp/6443)
Wants=network-pre.target
Before=network-pre.target
After=nftables.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/nft -f /etc/k3s-api-guard.nft
ExecStop=-/usr/sbin/nft delete table inet k3s_api_guard

[Install]
WantedBy=multi-user.target
```

```shell
sudo systemctl daemon-reload
sudo systemctl enable --now k3s-api-guard
```

The unit starts after `nftables.service`, which the Debian package enables and whose default `/etc/nftables.conf` begins with `flush ruleset`.
Do not run `nft flush ruleset` or restart `nftables.service` while the cluster runs: they remove the rules that k3s manages as well as the guard. Do not save the ruleset with `netfilter-persistent`, which would store the rules that k3s creates dynamically.

### Check the result

```powershell
Test-NetConnection <vps-public-ip> -Port 6443
kubectl --context VPS-LAB get pods -A
kubectl --context VPS-LAB -n flux-system get kustomizations
```

- `Test-NetConnection` reports `TcpTestSucceeded : False`. On Linux, use `nc -vz -w 5 <vps-public-ip> 6443`.
- Pods and Kustomizations stay healthy, which shows that in-cluster clients still reach the API server.
- With option 2, `sudo nft list table inet k3s_api_guard` shows a packet counter that grows with every attempt from outside. If the port stays open and the counter stays at 0, the interface name in the rule is wrong.

### Roll back

- Option 1: add the accept rule for TCP 6443 again.
- Option 2: run `sudo systemctl disable --now k3s-api-guard`. Before the unit exists, run `sudo nft delete table inet k3s_api_guard` instead.

## Recover access

If the proxy is unavailable, for example when the operator pod is down, connect to the VPS with SSH and run `sudo k3s kubectl get pods -A`.
It uses `/etc/rancher/k3s/k3s.yaml` and the loopback address, so the firewall does not affect it. Confirm that SSH works before you close the port.

## Troubleshooting

- `the server rejected our request for an unknown reason`: the server URL uses `http://`. Use `https://<operator-fqdn>` without a port.
- `x509: certificate signed by unknown authority`: the cluster entry still has the k3s CA. The proxy certificate is publicly trusted, so delete the cluster entry and create it again without a CA.
- `forbidden` and `auth whoami` lists only `system:authenticated`: the grant does not match. Compare `src` with the printed `Username` and `dst` with the operator device's tag, then retry after a few seconds.
- `forbidden` although `auth whoami` lists `vpslab-admins`: the binding is missing. On the VPS, run `sudo k3s kubectl get clusterrolebinding tailscale-vpslab-admins` and check that Flux applied the vpslab repository.
- The first request times out: Tailscale is still establishing the connection. Run `tailscale ping <operator-fqdn>` and retry.

## Security notes

- The access policy now decides who is cluster-admin on the vpslab. Restrict who can edit it and keep the grant `src` to the admin login.
- The kubeconfig holds no cluster credential, so a copied file is useless without a tailnet device of the granted user.
- Kubernetes cannot revoke a client certificate. After you close port 6443, the old k3s admin certificate is unusable from the internet but stays valid on the cluster; rotate the cluster CA if it may have leaked.

References:

- [Tailscale API proxy authentication and RBAC](https://tailscale.com/docs/kubernetes-operator/api-server-access/auth-and-rbac)
- [Tailscale Kubernetes API server proxy setup](https://tailscale.com/docs/kubernetes-operator/api-server-access/setup-api-over-tailscale)
- [K3s requirements: firewall and inbound rules](https://docs.k3s.io/installation/requirements)
- [Hostinger: how to use a managed VPS firewall](https://www.hostinger.com/support/8172641-how-to-use-a-managed-vps-firewall-at-hostinger/)
- [Tailscale: what firewall ports should I open](https://tailscale.com/docs/reference/faq/firewall-ports)
