# Secrets

Almost all services require some kind of secret value at runtime. In order to store those secrets safely inside the Git repository I use Mozilla SOPS which is natively supported by Flux and age as an algorithm for encryption.

[SOPS](https://github.com/getsops/sops) is an editor of encrypted files, it supports AWS KMS, GCP KMS, Azure Key Vault, and more. But hold on a second, weren’t we trying to keep our secrets separate from the cloud?
Don’t worry, SOPS also extends its support to age and PGP.

[age](https://github.com/FiloSottile/age) is a secure file encryption tool with its own format, it can be used as a CLI or as a Go library and can be extended through plugins. You can even use your existing SSH keys

## Install SOPS

To install sops[^1], download one of the pre-built binaries provided for your platform from the artifacts attached to this release.

```bash
# Download the binary
curl -LO https://github.com/getsops/sops/releases/download/v3.9.1/sops-v3.9.1.linux.amd64

# Move the binary in to your PATH
mv sops-v3.9.1.linux.amd64 /usr/local/bin/sops

# Make the binary executable
chmod +x /usr/local/bin/sops
```

## Install age

To install age[^2] we can use apt:

```bash
apt install age
```

## Configure SOPS ang age with Flux

Generate an age key with age using age-keygen [^3]

```bash
age-keygen -o age.agekey
```

Create a secret with the age private key, the key name must end with .agekey to be detected as an age key:

```bash
cat age.agekey |
kubectl create secret generic sops-age \
--namespace=flux-system \
--from-file=age.agekey=/dev/stdin
```

Update the .sops.yaml config file to tell SOPS which key to use to encrypt the files.

```yaml
---
# Tell to SOPS which key to use to encrypt the files.
creation_rules:
  - path_regex: .*/test/.*
    encrypted_regex: '^(user.*|pass.*|.*[Bb]earer.*|.*[Kk]ey|.*[Kk]eys|salt|sentry.*|.*[Tt]oken|data|stringData|match|href)$'
    age: age1987m5wdr5t8z9kvhun4sa8nm9ygpt8mrh63mysv7x57fk52xacvqpmnp27
  - path_regex: .*/prod/.*
    encrypted_regex: '^(user.*|pass.*|.*[Bb]earer.*|.*[Kk]ey|.*[Kk]eys|salt|sentry.*|.*[Tt]oken|data|stringData|match|href)$'
    age: age1xv8cuqcr09e3845unmja9x5jct30q9rmgz7awjc6dwrnq5m79etsvkz2z6
```

## References

[^1]: [SOPS Installation](https://github.com/getsops/sops/releases)
[^2]: [age](https://github.com/FiloSottile/age?tab=readme-ov-file#installation)
[^3]: [Manage Kubernetes secrets with SOPS](https://fluxcd.io/flux/guides/mozilla-sops/)
