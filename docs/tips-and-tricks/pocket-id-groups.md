# Role-based access to apps with Pocket ID groups

Apps without their own login are protected by a Traefik middleware that signs users in through Pocket ID. Two middlewares exist in `kubernetes/infrastructure/prod/traefik/middlewares/`:

| Middleware | Who may pass | Use it for |
|---|---|---|
| `oidc` | Only the account whose `email` claim equals `${EMAIL}` (others get 403) | Admin tools such as Headlamp, code-server and ESPHome |
| `oidc-groups` | Members of the Pocket ID groups `administrators` or `viewers` (others get 403) | Apps that have roles, such as Frigate |

`oidc-groups` also sends two headers to the app: `X-Forwarded-User` (the `preferred_username` claim) and `X-Forwarded-Groups` (the group names, comma separated). The plugin always sets them, so a client cannot spoof them. The app decides what each group may do.

## Prepare the groups

1. In Pocket ID open **Administration → User Groups**, reuse the existing `administrators` group and create `viewers` if needed. The claim contains the group **Name**, not the **Friendly Name**, and matching is case-sensitive.
2. Ensure your own account belongs to `administrators` **before** the change that switches an app to `oidc-groups` is merged, otherwise you lose access.
3. Add each view-only user to `viewers`. A user in both groups is treated as an admin.
4. Check **Administration → OIDC Clients** for the client used by Traefik. **Allowed User Groups** must be *All Users* or include both groups, otherwise Pocket ID itself refuses the sign-in.

## Frigate

Frigate has no OIDC support. Its own login is turned off and it trusts the headers on port 8971 (`kubernetes/apps/prod/home-automation/frigate/values.yaml`):

```yaml
auth:
  enabled: false
tls:
  enabled: false
proxy:
  logout_url: /logout
  default_role: viewer
  header_map:
    user: x-forwarded-user
    role: x-forwarded-groups
    role_map:
      admin: [administrators]
      viewer: [viewers]
```

- `administrators` get the Frigate `admin` role and `viewers` get the read-only `viewer` role for all cameras.
- The route `cameras.${DOMAIN}` uses `oidc-groups` and port 8971. Home Assistant and Gatus keep using port 5000 on the Service, which is unauthenticated and always admin, so do not expose it outside the cluster.
- To limit a user to some cameras, define a custom role under `auth.roles` in the Frigate config and map a Pocket ID group to it in `role_map`.
- If Pocket ID is down you cannot sign in from outside. Use `kubectl port-forward -n home-automation svc/frigate 5000`.

## Add another app

1. Put `oidc-groups` on its IngressRoute.
2. Map `X-Forwarded-User` and `X-Forwarded-Groups` in the app (a "trusted header" or "reverse proxy auth" setting).
3. Make sure only Traefik can reach the port that trusts the headers, because any pod that can reach it can send its own headers.

For an app that must admit only `administrators`, copy `oidc-groups.yaml` and change `AnyOf` to `["administrators"]`.
