# Product Requirements Document: Order Status Platform

- **Status:** In Delivery
- **Owner:** Commerce Product Team
- **Date:** 2026-03-19
- **Target Release:** 2026 Q3

## 1. Summary

Build a unified order status platform that aggregates shipment events from warehouse and carrier systems, exposes a canonical order timeline, and sends customer notifications for key milestones such as packed, shipped, out for delivery, delayed, and delivered.

## 2. Problem Statement

Customers currently receive inconsistent or delayed order updates because warehouse events, carrier scans, and support tooling all use different status models. Support agents spend too much time reconciling these sources during “where is my order?” contacts, which increases handle time and reduces customer trust.

## 3. Goals and Non-Goals

### Goals

- Provide a single order timeline with a normalized status model.
- Deliver shipment milestone updates to customers within five minutes of source-system receipt.
- Reduce support contact handle time for shipment-status inquiries.
- Give internal teams a documented API for retrieving current order state and status history.

### Non-Goals

- Replacing the existing order management system.
- Optimizing carrier routing or warehouse pick-pack workflows.
- Building a full customer self-service returns experience.

## 4. Users and Stakeholders

| Persona / Stakeholder | Need | Priority |
| --- | --- | --- |
| Customer | Timely and accurate shipment updates | Must |
| Support agent | Trusted timeline for troubleshooting delivery issues | Must |
| Notification platform team | Stable event contract for outbound messaging | Should |
| Fulfillment operations | Visibility into delayed handoffs and carrier exceptions | Should |

## 5. User Scenarios

1. As a customer, I want to receive a shipment update when my package goes out for delivery so that I know when to expect it.
2. As a support agent, I want to view the full order timeline in one place so that I can resolve status inquiries without switching systems.
3. As an internal service, I want to query the current canonical order state so that downstream workflows can react consistently.

## 6. Scope

### In Scope

- Canonical order status data model
- Event ingestion from warehouse and carrier systems
- Internal read API for current state and timeline history
- Notification triggers for key milestones and exception states
- Basic support-agent timeline view fed by the same API

### Out of Scope

- Editing orders after checkout
- Refund decisioning
- International customs workflows

## 7. Requirements

| ID | Requirement | Type | Priority | Rationale |
| --- | --- | --- | --- | --- |
| PRD-001 | The platform must normalize inbound warehouse and carrier events into a canonical status model. | Functional | Must | Removes ambiguity across systems. |
| PRD-002 | The platform must make current order state and timeline history available through an internal API. | Functional | Must | Enables support and downstream automation. |
| PRD-003 | The platform must trigger customer notifications for shipped, out-for-delivery, delayed, and delivered milestones. | Functional | Must | Improves customer transparency. |
| PRD-004 | The platform should process 95% of inbound events within five minutes of receipt. | NFR | Must | Supports freshness expectations. |
| PRD-005 | The platform should reduce average handle time for shipment-status contacts by 20%. | NFR | Should | Measures operational value. |

## 8. Success Metrics

| Metric | Baseline | Target | Measurement Method |
| --- | --- | --- | --- |
| Event-to-customer notification latency | 18 minutes | Under 5 minutes at p95 | Event pipeline telemetry |
| Support handle time for shipment inquiries | 9 minutes | 7 minutes or less | Support reporting dashboard |
| Canonical timeline API availability | Not available | 99.9% monthly | Service SLO dashboard |
| Orders with complete shipment timeline | 62% | 98% | Daily data quality audit |

## 9. Dependencies

- Warehouse events topic must publish package handoff and exception events.
- Carrier integration team must deliver a normalized webhook feed for top three carriers.
- Notification platform must support the new order timeline event schema.

## 10. Risks and Open Questions

### Risks

- Carrier data quality may vary by market and service level.
- Legacy support tools may cache stale order state.
- Event volume during seasonal peaks may create ingestion backlogs.

### Open Questions

- Which delayed-delivery scenarios should trigger proactive customer messaging versus agent-only visibility?
- Should support agents be able to annotate timeline events in a later phase?
