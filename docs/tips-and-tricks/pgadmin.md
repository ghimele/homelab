# Flux-managed pgAdmin

The production pgAdmin overlay is prepared but **not enabled**. It will run
in `cnpg-db` at `https://pgadmin.<DOMAIN>` with a 1 GiB Longhorn volume.
It is separate from the temporary `pgadmin-restore` pod: neither its
configuration nor saved server connections are migrated automatically.

## Provision and enable

1. In Pocket ID, create a confidential OIDC client for pgAdmin. Set its
   callback to `https://pgadmin.<DOMAIN>/oauth2/authorize` and restrict
   **Allowed User Groups** to `administrators`. Confirm the intended users
   belong to that group. Store the client ID and secret securely.
2. Ensure `pgadmin.<DOMAIN>` resolves to the production Traefik ingress and
   the existing `lets-encrypt` issuer can issue its certificate.
3. On a trusted workstation with the production SOPS age key, create
   `kubernetes/apps/prod/cloudnative-pg/pgadmin/secret.enc.yaml` using SOPS
   and an editor that waits until it closes:

   ```bash
   sops kubernetes/apps/prod/cloudnative-pg/pgadmin/secret.enc.yaml
   ```

   Replace the initial contents in the editor with the following, filling in
   all four values. Use a new strong, unique password for the internal
   break-glass account; do not reuse the restore pod's credentials. The
   `stringData` values are encrypted on save by the production SOPS rule.
   Do not save an unencrypted copy, commit placeholders, or paste credentials
   into chat. Protect editor temporary files and backups.

   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: pgadmin
     namespace: cnpg-db
     labels:
       kustomize.toolkit.fluxcd.io/substitute: disabled
   type: Opaque
   stringData:
     admin-email: "<internal administrator email>"
     admin-password: "<new internal administrator password>"
     oidc-client-id: "<Pocket ID client ID>"
     oidc-client-secret: "<Pocket ID client secret>"
   ```

   The substitution-disabled label preserves literal `$` characters in
   credentials. Check that the file contains SOPS-encrypted `stringData`
   and SOPS metadata before committing it.
4. Add `secret.enc.yaml` to the resources in
   `kubernetes/apps/prod/cloudnative-pg/pgadmin/kustomization.yaml`, and
   uncomment `./pgadmin` in
   `kubernetes/apps/prod/cloudnative-pg/kustomization.yaml`. Commit both
   changes and the encrypted Secret together for Flux to reconcile.
5. Verify the HelmRelease, deployment, PVC and certificate, then open the
   HTTPS page. Test Pocket ID login with an administrator and confirm that
   a user outside the allowed group is denied. Also test the internal
   break-glass login.

   ```bash
   kubectl --context PROD-KHC -n cnpg-db get helmrelease pgadmin
   kubectl --context PROD-KHC -n cnpg-db get deployment,pvc,certificate
   kubectl --context PROD-KHC -n cnpg-db rollout status deployment/pgadmin
   ```

## Server registration

The production primary is deployed automatically in `servers.json` as
`Production PostgreSQL (primary)`. Flux mounts that ConfigMap at
`/pgadmin4/servers.json`; pgAdmin imports it for the bootstrap account.

- Host: `postgres-cluster-rw.cnpg-db.svc.cluster.local`
- Port: `5432`
- Maintenance database: `postgres`
- SSL mode: `prefer`

The YAML intentionally contains no database password. Enter the password when
connecting and use pgAdmin's master password to save it. The
`postgres-cluster-superuser` Kubernetes Secret contains the bootstrap
superuser credential:

```bash
kubectl --context PROD-KHC -n cnpg-db get secret postgres-cluster-superuser \
  -o jsonpath='{.data.password}' | base64 --decode
```

## Accounts and operations

- The bootstrap account is an **internal** pgAdmin administrator. Pocket ID
  users are separate OAuth accounts, even when their email matches; they are
  created automatically and are not automatically pgAdmin administrators.
  Manage their pgAdmin roles through the internal administrator account.
  The Pocket ID client restriction applies to OAuth login, not to the
  internal break-glass login. Protect that account with a strong password.
- OAuth users need a pgAdmin master password to save database passwords.
  PostgreSQL permissions remain governed by the database credentials.
- Rotate the Pocket ID secret in Pocket ID and the SOPS Secret, then restart
  `deployment/pgadmin` after Flux reconciles: Secret environment variables do
  not update in an existing container. Expect a brief interruption. Changing
  `admin-password` in the Secret does **not** change an existing internal
  account password; change it in pgAdmin and update the Secret separately.
- The PVC contains pgAdmin's settings database, user accounts, connections
  and potentially saved database credentials. Arrange and test a separate
  backup of this volume; the CNPG backups do not cover it. Back it up before
  pgAdmin upgrades because configuration database migrations are
  forward-only. `Recreate` prevents old and new pods sharing it during an
  upgrade.
- TLS terminates at Traefik. pgAdmin trusts one `X-Forwarded-Proto` value
  for HTTPS redirects; restrict direct access to the ClusterIP to trusted
  cluster workloads. If Pocket ID is unavailable, the internal account is
  still available on the login page or through a trusted port-forward:

  ```bash
  kubectl --context PROD-KHC -n cnpg-db port-forward svc/pgadmin 5050:5050
  ```

  Open `http://localhost:5050` and use the internal login.

References: [pgAdmin OIDC](https://www.pgadmin.org/docs/pgadmin4/9.19/oauth2.html)
and [container deployment](https://www.pgadmin.org/docs/pgadmin4/9.19/container_deployment.html).
