# phpMyAdmin for VPS Lab MariaDB

## Overview

The production homelab cluster runs phpMyAdmin and protects it with the
Pocket ID Traefik OIDC middleware. It reaches the VPS Lab MariaDB instance
through a Tailscale Kubernetes operator egress Service.

- URL: `https://phpmyadmin.<DOMAIN>`
- Database host entered in phpMyAdmin: `mariadb-vpslab.phpmyadmin.svc.cluster.local`
- Tailnet FQDN used by the Tailscale operator: `mariadb-vpslab.${TAILSCALE_VPSLAB_MARIADB_FQDN}`
- Database port: `3306`
- MariaDB service on the VPS: `mariadb.mariadb.svc.cluster.local:3306`

The tailnet FQDN is stored as `TAILSCALE_VPSLAB_MARIADB_FQDN` in the SOPS-
encrypted production `cluster-secrets` Secret. The VPS MariaDB Service is
also marked with `tailscale.com/expose: "true"` and
`tailscale.com/hostname: mariadb-vpslab`.

## Database login

phpMyAdmin is configured with `PMA_ARBITRARY=1`, so enter the VPS database
host and credentials in the phpMyAdmin login screen. Do not add MariaDB
passwords to the Kubernetes manifests.

Use the MariaDB administrator account configured in the VPS cluster for
administrative work. Application-specific accounts should be used for
application operations where possible.

## Verification

```bash
kubectl --context VPS-LAB -n mariadb get svc mariadb
kubectl --context VPS-LAB -n tailscale get pods -l tailscale.com/parent-resource=mariadb

kubectl --context PROD-KHC -n phpmyadmin get helmrelease,deploy,pod,svc
kubectl --context PROD-KHC -n phpmyadmin get certificate
kubectl --context PROD-KHC -n phpmyadmin get svc mariadb-vpslab
kubectl --context PROD-KHC -n phpmyadmin rollout status deployment/phpmyadmin
```

A connection test can be performed from a temporary database client pod, but
phpMyAdmin should be verified in the browser first. The expected login route
is `mariadb-vpslab.${TAILSCALE_VPSLAB_MARIADB_FQDN}:3306`.
