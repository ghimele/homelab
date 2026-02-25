# Known Issues

This section documents **known, recurring, or historically significant issues**
that have affected the homelab.

The goal of this section is to:
- Explain **what happened and why**
- Capture **impact and scope**
- Document **resolution and prevention**
- Provide a long-term reference for operations and on-call engineers

> **Note**
> Known issues are not runbooks.
> They may reference runbooks, but they focus on *root cause and context* rather than step-by-step recovery.

---

## Index

| ID | Title | Affected Components | Status |
|----|-------|---------------------|--------|
| KI-001 | Longhorn webhook blocks Flannel bootstrap in k3s HA | k3s, Flannel, Longhorn | Mitigated |

---

## Status definitions

- **Active** – Issue can still occur and has no mitigation in place
- **Mitigated** – Safeguards or procedures exist, but risk remains
- **Resolved** – Issue cannot reoccur under current architecture

---

## How to add a new known issue

1. Create a new file in this directory using the naming convention:

   ```
   KI-<number>-<short-kebab-case-title>.md
   ```

   Example:
   ```
   KI-002-etcd-quorum-loss-after-power-outage.md
   ```

2. Use the standard structure:
   - Summary
   - Impact
   - Root cause
   - Detection
   - Resolution
   - Prevention

3. Add the issue to the **Index table** above.

4. Never delete known issues.
   If an issue is no longer relevant, update its **Status** to `Resolved`.

---

## References

- Runbooks: `docs/runbooks/`
- Architecture docs: `docs/architecture/`
- Operations docs: `docs/operations/`
