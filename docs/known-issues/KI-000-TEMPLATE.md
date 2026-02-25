# KI-XXX — <Short descriptive title>

## Status
<Active | Mitigated | Resolved>

## First observed
YYYY-MM-DD

## Last updated
YYYY-MM-DD

## Affected components
- <component 1>
- <component 2>
- <component 3>

---

## Summary

Brief, high-level description of the issue.
Explain **what happened** and **why it matters**, without going into recovery steps.

---

## Impact

Describe the user-visible and operational impact.

Examples:
- Cluster-wide outage
- Partial service degradation
- Control-plane instability
- No data loss / Data loss (be explicit)

---

## Root cause

Explain the underlying technical cause.
Focus on **system interactions**, not symptoms.

If useful, describe the sequence of events that led to the failure.

---

## Detection

How the issue can be identified.

Examples:
- Error messages
- Alerts
- Log patterns
- Symptoms observed by users or operators

---

## Resolution

High-level description of how the issue was resolved.

Do **not** include full runbook steps here.
Instead, summarize the actions taken and reference a runbook if available.

Example:
- Admission webhook removed
- Control-plane restarted sequentially
- Networking restored

---

## Data safety

Explicitly state the data impact.

Examples:
- No data loss
- Volumes preserved
- Manual recovery required
- Snapshots affected

---

## Prevention

Describe what prevents this issue from reoccurring.

Examples:
- Configuration changes
- Architectural changes
- Operational guidelines
- Monitoring or alerting improvements

---

## Related runbooks

- `docs/runbooks/<runbook-name>.md`

---

## References

- Incident ID / Ticket
- External documentation
- Postmortem links
