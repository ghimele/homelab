# ADR 006: Use Static DHCP Leases Instead of Static IP Addresses

## Status

Accepted

## Date

2024-10-04

## Context and Problem Statement

In the homelab environment, certain devices (like printers, servers, and IoT devices) require consistent IP addresses for reliable communication. There are two main approaches to assigning fixed IP addresses:

1. **Static IP Addresses**, manually configured on each device.
2. **Static DHCP Leases**, where the DHCP server consistently assigns the same IP to a device based on its MAC address.

The challenge is to choose the method that balances ease of management with network stability, particularly in a dynamic home network environment.

## Solution (Decision)

I have decided to use **Static DHCP Leases** for assigning consistent IP addresses to devices. This method provides ease of management while ensuring that key devices maintain consistent IPs without requiring manual configuration on each device.

## Alternatives Considered

### 1. **Static IP Addresses**

- **Pros**:
  - Absolute control over IP assignment.
    - Guarantees that the IP will not change unless manually altered.
- **Cons**:
  - Requires manual configuration on each device.
  - Risk of IP conflicts if not properly coordinated with the DHCP pool.
  - More time-consuming for large environments.

### 2. **Static DHCP Leases** (Chosen)

- **Pros**:
  - Easier to manage via the router’s DHCP settings.
  - Devices receive consistent IPs automatically.
  - Simplifies network changes (e.g., router replacements).
- **Cons**:
  - Depends on the DHCP server; if the DHCP server fails, devices may not receive their IPs.
  - Slightly less control compared to static IPs.

## Comparison Table

| Feature/Criteria | Static IP Address | Static DHCP Lease (Chosen) |
| ---------------- | ----------------- | -------------------------- |
| **Configuration Method** | Manual on device | Automatic via DHCP router |
| **Ease of Management** | Harder to manage at scale | Easier via centralized control |
| **Control** | Full control over IPs | Less direct control |
| **Potential for Conflicts** | Higher, if not planned properly | Managed by DHCP server |
| **Failover Concerns** | No dependency on DHCP | DHCP server failure can disrupt |

## Consequences

By choosing **Static DHCP Leases**, we ensure easier management for the home network, especially with multiple devices requiring fixed IPs. This approach streamlines changes, such as replacing routers, without needing to reconfigure each device.
However, there is a dependency on the DHCP server’s availability, which could affect devices if the server fails.
