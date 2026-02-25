# ADR-002: Choose Debian as the Operating System for Server

## Status

Accepted

## Date

2024-09-13

## Context and Problem Statement

We need to select an operating system for our servers that offers stability, security, and a strong package
management system. The operating system should be compatible with our existing tools and provide long-term
support.

## Solution (Decision)

We will use Debian as the operating system for our servers. Debian is known for its stability, security, and an
extensive repository of packages. It has a long-term support policy, making it suitable for a reliable and secure
server environment.

## Alternatives

- **Ubuntu Server**: Considered for its ease of use and regular updates, but Debian was chosen for its slightly longer release cycles and perceived stability in a production environment.
- **CentOS**: Considered for its enterprise-level stability and compatibility with Red Hat, but Debian was preferred due to its broader package repository and longer support cycle.

## Comparison Table

| Feature/Criteria | Debian | Ubuntu Server | CentOS |
| ---------------- | ------ | ------------- | ------ |
| **Stability** | High | High | High |
| **Release Cycle** | Longer (2 years) | Shorter (6 months) | Rolling (CentOS Stream) |
| **EOL** | 5 years for LTS | 5 years for LTS versions | Rolling for CentOS Stream |
| **Package Repository** | Extensive | Extensive | More limited |
| **Support** | Long-term support (LTS) | Regular and LTS versions | Long-term support (CentOS 7) |
| **Community Support** | Strong | Strong | Strong |
| **Compatibility** | Broad | Broad | Limited to Red Hat-based tools |

## Consequences

- **Positive**: Debian provides a stable and secure environment with a strong focus on long-term support.
Its extensive package repository and community support make it a robust choice for server operations.
- **Negative**: The release cycle is longer compared to Ubuntu, which might delay access to newer features and updates.
