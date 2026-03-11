# AGENTS.md - Agent Coding Guidelines for Homelab

This repository contains Kubernetes manifests, Ansible playbooks, and automation scripts for a homelab environment managed by FluxCD.

## Build/Lint/Test Commands

### YAML Linting

```bash
# Lint all YAML files
yamllint .

# Lint specific file
yamllint path/to/file.yaml

# Lint with custom config
yamllint -c .yamllint .
```

### Ansible Linting

```bash
# Install ansible-lint
pip install ansible ansible-lint

# Lint Ansible playbooks
ansible-lint ansible/

# Lint specific playbook
ansible-lint ansible/playbooks/<name>.yaml
```

### Kubernetes Manifest Validation

```bash
# Prerequisites (install via brew/apt):
# - yq v4.34+
# - kustomize v5.3+
# - kubeconform v0.6+

# Validate Kubernetes manifests (downloads Flux schemas automatically)
./scripts/flux-validate.sh

# Manual yq validation
yq -e 'true' path/to/file.yaml

# Manual kubeconform (with Flux schemas)
kubeconform -strict -ignore-missing-schemas \
  -schema-location default \
  -schema-location /tmp/flux-crd-schemas \
  path/to/manifest.yaml
```

### Full CI Pipeline

```bash
# Run CI locally (what GitHub Actions does)
./scripts/flux-validate.sh
yamllint .
ansible-lint ansible/
```

## Code Style Guidelines

### YAML Conventions

- **Indentation**: 2 spaces (enforced by yamllint)
- **Document markers**: Use `---` at the start of each YAML document
- **Line length**: Max 250 characters (warning level)
- **Booleans**: Use lowercase `true`/`false` (not `yes`/`no`)
- **Quotes**: Use quotes for strings that could be interpreted as other types

### Kubernetes Manifests

- **Directory structure**: Follow the established pattern:

  ```shell
  kubernetes/
  ├── apps/
  │   ├── base/          # Base configurations (shared across environments)
  │   ├── dev/           # Development environment overrides
  │   ├── test/          # Testing environment overrides
  │   └── prod/          # Production environment overrides
  ├── clusters/          # Cluster-specific Flux configuration
  ├── config/            # CRDs, issuers, network policies
  └── infrastructure/   # Core infrastructure (Traefik, cert-manager, etc.)
  ```

- **HelmRelease**: Use `apiVersion: helm.toolkit.fluxcd.io/v2`
- **Naming**: Use lowercase with hyphens (e.g., `sonarr`, `jellyfin`)
- **Namespaces**: Use descriptive names (media, monitoring, home-automation)
- **Resources**: Always set resource requests and limits
- **Security**: Enable security contexts, drop all capabilities

### Ansible Playbooks

- **Profile**: Use `shared` profile (configured in `.ansible-lint`)
- **Modules**: Prefer FQCN (Fully Qualified Collection Names) but warned only
- **Idempotency**: Ensure tasks are idempotent
- **Documentation**: Comment complex tasks

### Secrets Management

- **Encryption**: Use SOPS with Age for secrets
- **Patterns**:
  - `test/` environment: `age1987m5wdr5t8z9kvhun4sa8nm9ygpt8mrh63mysv7x57fk52xacvqpmnp27`
  - `prod/` environment: `age1xv8cuqcr09e3845unmja9x5jct30q9rmgz7awjc6dwrnq5m79etsvkz2z6`
- **Encrypted fields**: `user.*`, `pass.*`, `*Bearer*`, `*Key*`, `*Token*`, `salt`, `data`, `stringData`

### Git Conventions

- **Commits**: Use conventional commit format (optional but recommended)
- **Branches**: Feature branches for changes, PRs for review
- **CI triggers**: Workflows ignore changes to `README.md`, `assets/`, `docs/`

## Documentation and ADR Guidelines

### Documentation Structure

All documentation should follow the established structure:

```
docs/
├── adr/                    # Architecture Decision Records
├── known-issues/           # Known issues with templates
├── tips-and-tricks/        # Tips and tricks with templates
├── Architecture.md         # System architecture overview
├── Installation.md         # Installation procedures
├── Secrets.md              # Secrets documentation
└── assets/                 # Screenshots and images
```

### ADR (Architecture Decision Record) Creation

1. **Create Issue First**: Document the problem/decision as an issue with:
   - Problem statement
   - Proposed solution
   - Alternatives considered
   - Decision context

2. **Template Structure**: Use the ADR template at `docs/adr/ADR-000-Template.md`:

   ```bash
   Title: <Clear, concise title>
   Status: Accepted | Rejected | Deprecated | Superseded
   Date: YYYY-MM-DD
   
   ## Context
   - Background information
   - Problem statement
   - Technical constraints
   
   ## Decision
   - The decision we made
   - Rationale for the decision
   
   ## Alternatives
   - Other options considered
   - Why they were rejected
   
   ## Consequences
   - Positive outcomes
   - Negative outcomes
   - Trade-offs
   
   ## Comparison
   | Feature/Criteria | Option A | Option B | Option C |
   |-------------------|----------|----------|----------|
   | Cost              |          |          |          |
   | Community Support |          |          |          |
   ```

3. **ADR Naming Convention**: `ADR-XXX-<description>`, e.g., `ADR-001-Add-Cert-Manager`

4. **Link from Code**: Reference ADRs in code comments and documentation:
   - Kubernetes manifests: Add `// ADR: <ADR-XXX-<description>>`
   - Ansible playbooks: Document in README.md or separate docs

5. **Review Process**:
   - All ADRs require review by at least 2 team members
   - Update status if decision is superseded
   - Archive old ADRs in a separate branch if no longer relevant

### Documentation Writing Guidelines

- **Clarity**: Write for the audience (developers, ops, stakeholders)
- **Conciseness**: Be direct and to the point
- **Examples**: Include code examples and configurations
- **Links**: Reference related ADRs, issues, and PRs
- **Versioning**: Tag documentation with relevant versions
- **Review**: All documentation should be reviewed before merging

### Error Handling

- **Bash scripts**: Use `set -o errexit` and `set -o pipefail`
- **Ansible**: Always check task results when critical
- **Kubernetes**: Set `install/upgrade/uninstall` remediation with retries

### Common Patterns

- **Kustomization overlays**:

  ```yaml
  # Base reference
  resources:
    - ../../../base/<app>
  
  # Environment patches
  patches:
    - path: values.yaml
      target:
        kind: HelmRelease
  ```

- **Helm values**: Use `controllers.<name>.containers.app` structure (app-template schema)

### Testing New Changes

1. Validate YAML syntax: `yamllint path/to/file.yaml`
2. Validate Kubernetes manifests: `yq -e 'true' path/to/file.yaml`
3. Run full validation: `./scripts/flux-validate.sh`
4. Test Ansible: `ansible-lint ansible/` (if changed)
5. Create PR and verify CI passes before merging
