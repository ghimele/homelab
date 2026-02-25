# ADR 007: Use FluxCD for Kubernetes Cluster Management

## Status

Accepted

## Date

2024-10-02

## Context and Problem Statement

I need a reliable tool for managing Continuous Deployment (CD) and applying GitOps principles to my Kubernetes clusters.
The tool should align well with my GitOps workflow, support Kubernetes-native integrations, and allow me to manage both infrastructure and applications declaratively.

## Solution (Decision)

I have chosen **FluxCD** as the primary tool to manage Kubernetes cluster configurations and application deployments.
FluxCD offers a lightweight, GitOps-first approach, making it easy to continuously reconcile the desired state of my clusters based on the configuration stored in Git.

### Key Advantages of FluxCD

- **GitOps-Centric**: FluxCD strictly adheres to GitOps principles, continuously ensuring the cluster matches the desired state defined in Git.
- **Lightweight**: No need for additional UI or API server components, which reduces resource overhead.
- **Native Support for Helm & Kustomize**: Seamless integration with Helm charts and Kustomize overlays, which I already use in my repository.
- **Infrastructure and Application Management**: FluxCD can manage both infrastructure components and applications in the same workflow.

## Alternatives

1. **Argo CD**:
   - Provides a richer feature set, including a web-based UI and more control over synchronization and deployments.
   - However, Argo CD is more resource-intensive, and the focus on UI-driven management is unnecessary for my current setup.

2. **Jenkins X**:
   - Jenkins X is an advanced CI/CD tool but focuses heavily on CI workflows, which aren't a primary requirement for my setup. It also introduces unnecessary complexity and resource usage.

## Comparison Table

| Feature/Criteria | FluxCD | Argo CD | Jenkins X |
| ---------------- | ------ | ------- | --------- |
| **GitOps Focus** | Strong GitOps principles | GitOps but with added UI control | Primarily focused on CI/CD |
| **Resource Usage** | Low | Medium (UI/API overhead) | High |
| **Deployment Strategies** | Supports Helm/Kustomize | Advanced (hooks, waves, etc.) | Complex, focuses more on CI |
| **Multi-tenancy Support** | Available with setup | Strong native support | Available but not as mature |
| **Ease of Use** | Simple Git-based workflows | UI-driven, more flexible | High complexity |

## Consequences

- **Positive**:
  - Streamlined GitOps workflow with a lightweight, resource-efficient tool.
  - Easy integration with my existing infrastructure and Kubernetes cluster management.
  - FluxCD’s Git-centric approach keeps the configuration declarative and easily auditable.
  
- **Negative**:
  - Lack of a built-in web UI could be a drawback for those who prefer visual interfaces for managing applications.
  - Multi-tenancy and RBAC may require additional configuration compared to other tools like Argo CD.
