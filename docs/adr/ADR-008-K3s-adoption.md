# ADR-008: Use K3s as Kubernetes Distribution

## Status

Accepted

## Date

2025-02-12

## Context and Problem Statement

In our homelab setup, we need to choose a Kubernetes distribution that is lightweight, efficient, and easy to maintain. The goal is to have a Kubernetes solution that is suitable for a small to medium-sized cluster while minimizing resource overhead.

The current options for Kubernetes distributions include K3s, MicroK8s, k0s, and standard Kubernetes. Each option has its trade-offs in terms of performance, ease of setup, and features.

## Solution (Decision)

We will use **K3s** as the Kubernetes distribution for the following reasons:

- **Lightweight**: K3s is optimized for resource-constrained environments and is significantly lighter than the standard Kubernetes distribution, making it suitable for running on VMs or physical hardware with limited resources.
- **Easy Setup**: K3s simplifies Kubernetes setup and management, which is beneficial for our homelab environment where ease of use and quick deployment are important.
- **Built-in components**: K3s bundles essential components (like an internal load balancer and storage) by default, reducing the need for manual configuration of these components.
- **Compatible with standard Kubernetes tools**: K3s is fully compatible with Kubernetes tooling like `kubectl` and Helm, ensuring seamless integration with our existing setup.
- **Good community support**: K3s has strong community support and regular updates, which makes it a reliable choice for a Kubernetes distribution in a homelab scenario.

## Alternatives

1. **MicroK8s**:
   - Pros: Lightweight and easy to set up, similar to K3s.
   - Cons: Limited flexibility in certain configurations compared to K3s, especially with regards to high-availability setups.

2. **k0s**:
   - Pros: Lightweight and fully conformant with Kubernetes, with a focus on simplicity. It also offers features like built-in high availability and is very straightforward to set up.
   - Cons: Fewer ecosystem integrations compared to K3s, smaller community support.

3. **Standard Kubernetes**:
   - Pros: Full feature set and scalability.
   - Cons: Higher resource consumption and more complex setup and maintenance.

## Comparison Table

| Feature/Criteria | K3s | MicroK8s | k0s | Standard Kubernetes |
| ---------------- | --- | -------- | --- | ------------------- |
| **Resource Usage** | Low | Low | Low | High |
| **Setup Complexity** | Simple | Simple | Simple | Complex |
| **Feature Set** | Full Kubernetes, with fewer dependencies | Full Kubernetes, with fewer dependencies | Full Kubernetes, with fewer dependencies | Full Kubernetes, complete set of features |
| **Performance** | Optimized for low-resource environments | Optimized for low-resource environments | Optimized for low-resource environments | Less optimized for low-resource environments |
| **Community Support** | Strong | Strong | Moderate | Very strong |
| **HA (High Availability)** | Supported | Supported | Supported | Fully supported (but more complex) |

## Consequences

- We will rely on the K3s ecosystem for Kubernetes management, which will affect the selection of other tools and services.
- K3s will limit the need for additional resource-heavy components, making it ideal for smaller or resource-constrained nodes in the homelab.
- The decision will simplify the management and maintenance of the Kubernetes cluster, particularly for environments with multiple nodes running in different roles.

### **Positive Consequences**

✅ Lower resource usage in the homelab setup.\
✅ Faster deployment and easier maintenance.\
✅ Lower complexity in Kubernetes cluster setup and management.

### **Negative Consequences**

❌ Potential limitations in some advanced features, although most homelab use cases will be supported by K3s.\
❌ May require adjustments in terms of handling certain workloads compared to a full Kubernetes setup.
