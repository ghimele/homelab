# ADR-009: Secrets Managment

## Status

Accepted

## Date

2025-02-11

## Context and Problem Statement

By default, Kubernetes stores secrets as **base64-encoded** values in etcd, which does not provide sufficient security against unauthorized access to the database. If an attacker gains access to the etcd database, they can retrieve and decode sensitive information.

To mitigate this risk, Kubernetes provides **secrets encryption**, which encrypts secrets at rest in etcd. In K3s, this can be enabled using the `--secrets-encryption` flag during installation.

Additionally, to ensure secure secret management and version control, secrets will be stored in Git encrypted using **age** and **SOPS**.

## Solution (Decision)

Enable **secrets encryption** in K3s by using the `--secrets-encryption` flag and store secrets in Git encrypted with **age** and **SOPS**.

### Implementation

- When installing K3s, pass the `--secrets-encryption` flag:

  ```sh
  k3s server --secrets-encryption
  ```

- K3s will automatically generate and manage the encryption keys in:

  ```sh
  /var/lib/rancher/k3s/server/cred/encryption-config.json
  ```

- The encryption mechanism uses AES-CBC with a generated key to secure secrets at rest.
- Only components with the correct encryption key can decrypt the secrets.
- Secrets will be stored in Git encrypted using **age** and **SOPS**:
  - Encrypt secrets using `sops`:

    ```sh
    sops --encrypt --age <your-age-key> -i secret.yaml
    ```

  - Store encrypted secrets in the Git repository.
  - Decrypt secrets during deployment using SOPS integration with Flux or other CI/CD tools.

## Alternatives

- **Do nothing (default)**
- **Use external vault (e.g., HashiCorp Vault, AWS KMS)**
- **Enable Kubernetes native encryption** and store secrets in Git using **SOPS** and **age**

## Comparison Table

| Feature/Criteria         | Do Nothing (Default) | External Vault (e.g., HashiCorp Vault, AWS KMS) | K3s Native Encryption + SOPS and age (Our Choice) |
|--------------------------|----------------------|--------------------------------------------|----------------------------------|
| **Security**             | Low (Base64-encoded secrets) | High (External key management) | High (Built-in encryption, Git versioning + encryption) |
| **Complexity**           | Low                  | High                                     | Moderate                              |
| **Key Management**       | None                 | Centralized                              | Managed via `age` keys                        |
| **Integration**          | N/A                  | Requires additional infrastructure       | Requires CI/CD configuration                   |
| **Cost**                 | None                 | High (Managed service fees)              | None                             |
| **Community Support**    | High                 | High                                     | High                             |

## Consequences

### **Positive Consequences**

✅ Protects secrets from unauthorized access if etcd is compromised.\
✅ Transparent encryption without changes to applications.\
✅ Simple to enable with a single flag.\
✅ Ensures **GitOps-friendly secret management** with encrypted version control.\
✅ Secrets remain encrypted both in Kubernetes and in Git.

### **Negative Consequences**

❌ Encryption keys are stored locally, which can be a risk if the node is compromised.\
❌ Key rotation requires manual intervention.\
❌ Performance impact is minimal but present when reading/writing secrets.\
❌ Requires additional tooling (`sops`, `age`) and integration with CI/CD workflows.

## Next Steps

- Monitor etcd encryption status with `kubectl get secrets -o yaml | grep -i data`.
- Consider implementing key rotation for enhanced security.
- Ensure proper backup and recovery of `encryption-config.json` to avoid data loss.
- Automate the encryption and decryption process within the GitOps workflow.

---

This ADR documents the decision to enable **secrets encryption** in K3s to enhance cluster security while leveraging **age** and **SOPS** for secure secret storage in Git. Future enhancements may include external key management for better security and compliance.
