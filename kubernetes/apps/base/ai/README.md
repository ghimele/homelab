# AI Namespace Configuration

This directory contains the configuration for the AI namespace, including:

- **Namespace**: The `ai` namespace with ServiceAccount and RBAC roles for open-webui
- **Certificate**: TLS certificate for `webui.homelab.local` using Let's Encrypt production issuer
- **Ingress**: Traefik ingress route for the open-webui service

## Resources

- `namespace.yaml`: Namespace, ServiceAccount, Role, and RoleBinding for open-webui
- `certificate.yaml`: ClusterIssuer and Certificate for TLS encryption
- `kustomization.yaml`: Kustomization configuration

## Usage

To apply these configurations:
```bash
flux create source helm ai-certs --url=https://fluxcd.io/flux --interval=10m
kubectl apply -k kubernetes/config/certs/ai/
```

## Notes

- The certificate is automatically renewed by cert-manager
- Ingress uses Traefik with compression middleware
- TLS is enabled for `webui.homelab.local`
