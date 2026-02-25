# ADR-001: Hypervisor Solution

## Status

Accepted

## Date

2024-09-13

## Context and Problem Statement

We need to select a hypervisor for our home lab that offers robust virtualization capabilities, efficient management, and reliable backup options.
The solution should be open-source and supported by a strong community, with a management tool that enhances these features.

## Solution (Decision)

We will use XCP-ng as the hypervisor and Xen Orchestra as the management tool for our home lab. XCP-ng is an open-source virtualization platform with strong performance and scalability.
Xen Orchestra complements XCP-ng by providing a comprehensive web-based management interface with advanced backup, snapshot, and restoration features.

## Alternatives

- **Proxmox VE**: Considered for its integrated container management and backup solutions, but XCP-ng with Xen Orchestra was chosen for its robust virtualization features, advanced management capabilities, and comprehensive backup and restoration options.
- **VMware ESXi**: Known for its enterprise features but involves licensing costs and requires third-party backup solutions, making it less ideal for a home lab environment.

## Comparison Table

| Feature/Criteria | XCP-ng with Xen Orchestra | Proxmox VE | VMware ESXi |
| ---------------- | ------------------------- | ---------- | ----------- |
| **Virtualization** | KVM, Xen | KVM, LXC | KVM |
| **Container Management** | No | Yes | No |
| **Web Interface** | Yes (Xen Orchestra) | Yes | Yes |
| **High Availability** | Yes | Yes | Yes |
| **Licensing Cost** | Free | Free | Paid |
| **Community Support** | Strong | Strong | Strong |
| **Backup and Snapshots** | Advanced backup tools (Xen Orchestra), supports third-party solutions | Built-in backup tools, supports third-party solutions | Requires third-party backup solutions |

## Consequences

- **Positive**: Combining XCP-ng with Xen Orchestra provides a powerful and cost-effective virtualization solution with an advanced management interface and robust backup features.
This setup leverages the strengths of both tools and ensures a reliable and scalable platform for managing virtual machines.
- **Negative**: There will be a learning curve associated with using both XCP-ng and Xen Orchestra, and integrating them into existing workflows may require adjustments.
