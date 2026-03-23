# Example Documentation Set: Order Status Platform

This directory shows one way to implement the templates in this repository for a fictional product: an order status platform that gives customers, support agents, and internal systems near-real-time shipment updates.

## Scenario Summary

The platform consolidates status changes from warehouse, carrier, and support systems into a single service that:

- publishes a canonical order timeline for customers
- exposes order state through an internal API
- sends milestone notifications for major shipment events
- provides support agents with a troubleshooting view for delayed or failed deliveries

## Document Map

### Requirements

- [Product Requirements Document](requirements/prd.md)
- [Software Requirements Specification](requirements/srs.md)

### Architecture

- [System Architecture](architecture/system-architecture.md)
- [High-Level Design](architecture/high-level-design.md)
- [Low-Level Design](architecture/low-level-design.md)
- [Network Design](architecture/network-design.md)
- [Interface Control Document](architecture/interface-control.md)

### Quality

- [Test Plan](quality/test-plan.md)
- [Verification and Validation Plan](quality/verification-validation-plan.md)

### Operations

- [Operational Runbook](operations/runbook.md)
- [Postmortem Example](operations/postmortem.md)
- [Release Readiness Checklist](operations/release-readiness.md)

### Governance

- [Architecture Decision Record](governance/adr-001-canonical-order-timeline.md)
- [Change Log](governance/change-log.md)

### Project Management

- [Delivery Plan](project-management/delivery-plan.md)

## How to Use This Example

1. Read the PRD to understand the business problem and user goals.
2. Follow the SRS and architecture documents to see how requirements trace into a technical design.
3. Review the quality and operations artifacts to see how the design is prepared for validation and production use.
4. Copy only the documents relevant to your team, then replace names, dates, owners, and assumptions with real project information.
