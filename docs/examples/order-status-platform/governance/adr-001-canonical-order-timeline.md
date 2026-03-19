# ADR-001: Adopt a Canonical Order Timeline Model

- **Status:** Accepted
- **Date:** 2026-03-19
- **Owners:** Commerce Platform Architecture
- **Related Documents:** ../requirements/prd.md, ../architecture/high-level-design.md

## Context

Shipment status is produced by multiple systems with inconsistent state names, different timing semantics, and varying reliability. Downstream consumers need one stable representation for support workflows, customer notifications, and operational reporting.

## Decision Drivers

- Need consistent status semantics across systems
- Need auditability for support and incident review
- Need low-friction downstream integrations

## Considered Options

1. Pass through source-specific statuses and let each consumer translate them.
2. Store only the latest snapshot without event history.
3. Adopt a canonical timeline with immutable events and a current-state projection.

## Decision

Adopt a canonical timeline model owned by the Order Status Platform. All accepted inbound events are mapped into a normalized status vocabulary, stored as immutable timeline events, and projected into a current-state snapshot for low-latency reads.

## Consequences

### Positive

- Downstream systems integrate once to a stable contract.
- Support agents gain a complete, auditable event history.
- Reprocessing and replay are simpler because raw source semantics are preserved in event metadata.

### Negative

- Initial implementation requires careful mapping design and governance.
- The platform becomes responsible for semantic correctness of status translation.

### Neutral / Trade-offs

- Storage footprint increases because both event history and current state are retained.
- Some carrier-specific nuance may need supplemental metadata outside the core canonical status field.

## Follow-up Actions

- [ ] Publish canonical status dictionary with examples.
- [ ] Review mapping coverage with fulfillment and support teams each quarter.
