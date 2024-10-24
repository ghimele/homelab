# How to uninstall traefik from K3S

1. Create a file named traefik.yaml.skip on folder /var/lib/rancher/k3s/server/manifests like this:

    ```bash
    touch /var/lib/rancher/k3s/server/manifests/traefik.yaml.skip
    ```

2. After that, run

    ```bash
    kubectl -n kube-system delete helmcharts.helm.cattle.io traefik
    ```

    to remove traefik in the case it was deployed.

3. Restart k3s

    ```bash
    sudo systemctl restart k3s
    ```

## References

[k3s server --disable traefik does not correctly remove existing Traefik](https://github.com/k3s-io/k3s/issues/5103)
