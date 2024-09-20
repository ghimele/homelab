# ADR-004: Repository Structure for Homelab Configuration

## Status
Accepted

## Date
2024-09-13

## Context and Problem Statement
To effectively manage the homelab configuration, it is essential to have a well-organized repository structure. The repository will store Ansible playbooks and packages, Kubernetes manifests, Helm charts, and documentation. Additionally, integrating GitHub Actions for CI/CD requires a dedicated folder to manage workflows and configurations. The challenge is to create a repository structure that is both clear and maintainable, supporting various automation and configuration needs.

## Solution (Decision)
The repository will be organized into distinct folders to separate different types of configurations and automation tasks. The structure will include:

- **ansible/**: For Ansible playbooks, packages, and inventory files.
- **kubernetes/**: For Kubernetes manifests and Helm charts, with subfolders for Kustomize overlays and environment-specific Helm values.
- **docs/**: For Architecture Decision Records (ADRs).
- **.github/**: For GitHub Actions workflows and configurations.
- **scripts/**: For any additional automation or management scripts.

This structure provides a clear separation of concerns and supports the integration of GitHub Actions, making it easier to manage and navigate the repository.

## Alternatives
1. **Single Folder for All Kubernetes Configurations**:
   - **Pros**: Simplicity in structure.
   - **Cons**: Less clarity between Kustomize and Helm configurations, potentially harder to manage as the repository grows.

2. **Separate Repositories for Different Components**:
   - **Pros**: Clear separation of concerns and modularity.
   - **Cons**: More complex management of multiple repositories, potential difficulties in synchronizing changes across repositories.

## Comparison Table

| Feature/Criteria      | Proposed Structure     | Single Kubernetes Folder | Separate Repositories |
|-----------------------|-------------------------|---------------------------|------------------------|
| **Clarity**           | High                    | Moderate                  | High                   |
| **Ease of Navigation**| Easy                    | Moderate                  | Moderate               |
| **Management**        | Centralized             | Slightly complex          | Complex                |
| **Integration with CI/CD** | Straightforward       | Requires additional setup | Requires coordination  |
| **Scalability**       | Good                    | Good                      | Excellent              |

## Consequences
- **Positive Impacts**:
  - The repository structure is organized and clear, making it easier to manage and understand.
  - Integrates GitHub Actions workflows directly into the repository, streamlining CI/CD processes.
  - Provides a scalable structure that can accommodate future growth and additional configurations.

- **Drawbacks**:
  - Requires initial setup and organization effort.
  - The `.github` folder introduces an additional layer of configuration that must be managed.
