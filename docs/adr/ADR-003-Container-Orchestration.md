# ADR-003: Choosing Kubernetes for Container Orchestration in the Homelab

## Status

Accepted

## Date

2024-09-13

## Context and Problem Statement

The homelab requires a platform to manage the deployment, scaling, and operation of containerized
applications. We need an orchestration tool that provides service discovery, load balancing,
self-healing, and scaling while integrating with our existing infrastructure automation tools (Ansible,
Helm, GitOps). The challenge is to choose a solution that meets these requirements and can scale with
future needs, while balancing ease of use and operational complexity.

## Solution (Decision)

We have chosen **Kubernetes** as the orchestration platform for the homelab. Kubernetes offers the
required scalability, automation, and operational features such as self-healing and load balancing. It
integrates well with tools like Helm, Ansible, and GitOps, allowing for seamless deployment management.
Although Kubernetes introduces some complexity, it is the best fit for our long-term goals due to its
maturity, community support, and ability to handle complex environments.

## Alternatives

1. **Docker Swarm**:

   - Simpler to set up and use but lacks the advanced features of Kubernetes, such as self-healing and
     large-scale orchestration.

2. **Nomad**:

   - Lightweight and easier to learn, integrates with HashiCorp tools, but doesn't offer the same level of
     ecosystem support and advanced networking features as Kubernetes.

## Comparison Table

| Feature/Criteria | Kubernetes | Docker Swarm | Nomad |
| ---------------- | ---------- | ------------ | ----- |
| **Ease of Use** | Moderate to Hard | Easy | Moderate |
| **Scalability** | High | Limited | High |
| **Self-Healing** | Yes | Partial | Partial |
| **Declarative Config** | Yes (Helm, Kustomize) | Partial | Yes |
| **Cost** | Free, open-source | Free | Free |
| **Community Support** | Large and mature | Smaller | Small |

## Consequences

- **Positive Impacts**:

  - Kubernetes offers scalability and flexibility that can grow with the homelab setup.
  - It has a robust ecosystem and community support for troubleshooting and further development.
  - It supports automation and self-healing, which reduces manual intervention.

- **Drawbacks**:

  - Kubernetes has a steep learning curve, which may require additional time for setup and understanding.
  - The resource overhead is higher than simpler solutions like Docker Swarm.
  - Operational complexity increases, as managing a Kubernetes cluster requires attention to detail with
    networking, monitoring, and storage.
