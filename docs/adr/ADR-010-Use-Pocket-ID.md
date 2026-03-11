# ADR-010: Use Pocket-ID as OIDC Provider for SSO with Passkeys

## Status

Accepted

## Date

2026-03-11

## Context

The homelab environment requires centralized Single Sign-On (SSO) with modern authentication methods including Passkeys. The previous OIDC provider choice needs to be documented and justified.

### Problem Statement

- Need a secure, self-hosted OIDC provider for homelab SSO
- Must support Passkeys (FIDO2/WebAuthn) for passwordless authentication
- Requires integration with existing Kubernetes infrastructure (FluxCD)
- Must be maintainable in a homelab environment

### Technical Constraints

- Self-hosted solution preferred for control and security
- Must work with Kubernetes services and FluxCD
- Needs to support both traditional passwords and passkeys
- Should be lightweight and easy to maintain

## Decision

Use Pocket-ID as the OIDC provider for SSO with Passkeys support.

## Rationale

Pocket-ID offers several advantages for this use case:

1. **Passkeys Native Support**: Built-in FIDO2/WebAuthn support without additional plugins
2. **Self-Hosted**: Full control over security and data
3. **Lightweight**: Minimal resource footprint compared to full Identity Servers
4. **Easy Integration**: Simple OIDC/OpenID Connect implementation
5. **Active Development**: Regular updates and community support
6. **Homelab Friendly**: Designed for home lab and small business use cases

## Alternatives

| Option | Pros | Cons |
| ------ | ---- | ---- |
| **Pocket-ID** | Native passkeys, lightweight, self-hosted | Smaller community |
| Authelia | Full IAM, passkeys supported | More complex setup |
| Keycloak | Industry standard, extensive features | Heavy resource usage, complex |
| HashiCorp Vault | Enterprise-grade, flexible | Overkill for homelab, complex |
| Google Identity Platform | Easy setup, good passkeys | Cloud dependency, cost |

| Feature/Criteria | Pocket-ID | Authelia | Keycloak | Vault | Google Cloud |
| ---------------- | --------- | -------- | -------- | ----- | ------------ |
| Cost | Free | Free | Free | Free | Paid |
| Community Support | Active | Active | Large | Large | Large |
| Passkeys | Native | Yes | Yes | Yes | Yes |
| Resource Usage | Low | Medium | High | High | Medium |
| Setup Complexity | Low | Medium | High | High | Low |
| Maintenance | Easy | Medium | Complex | Complex | Easy |

## Consequences

### Positive Outcomes

- Simplified SSO implementation
- Modern passwordless authentication
- Reduced operational overhead
- Better security through passkeys
- Lower resource consumption

### Negative Outcomes

- Smaller community compared to Keycloak
- Fewer enterprise features
- Limited third-party integrations

### Trade-offs

- Chose simplicity and maintainability over feature richness
- Accepted smaller community in favor of lighter footprint
- Prioritized passkeys support over extensive IAM features

## Implementation Notes

- Deploy via Kubernetes Helm chart
- Configure OIDC issuer in FluxCD installations
- Use Age encryption for secrets management
- Integrate with existing user management systems

## References

- [Pocket-ID GitHub](https://github.com/pocket-id/pocket-id)
- [Pocket-ID Documentation](https://pocket-id.org/docs)
- [FIDO2/WebAuthn Support](https://pocket-id.org/docs/setup/installation)
