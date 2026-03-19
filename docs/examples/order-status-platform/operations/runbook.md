# Operational Runbook: Order Status Platform

- **Status:** Active
- **Owner:** Commerce Platform Engineering
- **Service Tier / Criticality:** Tier 1 customer-impacting internal platform
- **Last Reviewed:** 2026-03-19

## 1. Service Overview

The Order Status Platform processes shipment events, maintains canonical order status data, and supports customer notification triggers plus support-agent troubleshooting workflows. Failures can delay customer updates and increase support contact volume.

## 2. Contacts and Escalation

| Role | Contact | Hours / Escalation Path |
| --- | --- | --- |
| Primary On-Call | Commerce Platform Pager | 24x7 pager rotation |
| Secondary On-Call | SRE Escalation | 24x7 after 15 minutes |
| Service Owner | Commerce Platform Manager | Business hours / incident commander backup |

## 3. Dependencies

- Warehouse event bus
- Carrier adapter service
- Managed relational database
- Notification event cluster
- Centralized logging and metrics platform

## 4. Monitoring and Alerts

| Signal | Source | Threshold / Alert | Dashboard / Link |
| --- | --- | --- | --- |
| Event processing latency p95 | Metrics | Over 5 minutes for 10 minutes | `order-status-overview` |
| DLQ depth | Metrics | Over 50 messages for 5 minutes | `order-status-ops` |
| Read API error rate | Metrics | Over 2% for 5 minutes | `order-status-api` |
| Database write failures | Logs / metrics | Any sustained spike over baseline | `order-status-db` |

## 5. Routine Operations

### Start-up

1. Confirm database connectivity and secrets sync.
2. Enable event consumers and verify checkpoint health.
3. Confirm API health endpoint and dashboard freshness.

### Shutdown

1. Disable ingress and pause consumers.
2. Wait for in-flight outbox publication to drain.
3. Confirm no replay or backfill jobs are active.

### Health Checks

1. Query `/health` and `/ready` endpoints.
2. Check backlog, DLQ depth, and event freshness dashboards.
3. Run a sample status API lookup for a known test order.

## 6. Common Procedures

### Deploy

1. Verify release checklist approval.
2. Roll out processor pods first, then API pods.
3. Monitor p95 latency, error rate, and outbox lag for 30 minutes.

### Roll Back

1. Pause new deployments.
2. Revert to previous application version.
3. If schema changes were involved, apply backward-compatible rollback migration.
4. Replay missed events after service recovery.

### Restore Service

1. Identify whether the fault is ingress, processing, database, or publisher related.
2. Clear or isolate bad messages into the DLQ if needed.
3. Restore healthy capacity, then replay from checkpoint or outbox.
4. Verify customer milestone publication resumed.

## 7. Failure Modes and Troubleshooting

| Symptom | Likely Cause | Diagnostic Steps | Recovery Actions |
| --- | --- | --- | --- |
| Timeline updates are delayed | Event backlog or DB latency | Check consumer lag and DB write metrics | Scale processors, stabilize DB, replay backlog |
| Carrier events rejected | Signature or schema issue | Review gateway logs and rejection counts | Coordinate with integration team and replay corrected payloads |
| Notifications missing for delivered orders | Outbox stuck or subscriber issue | Inspect outbox lag and publisher DLQ | Restart publisher, drain outbox, notify messaging team |
| Support API returns stale status | Snapshot update failure | Compare timeline and snapshot rows | Rebuild projection for impacted shipments |

## 8. References

- ../quality/test-plan.md
- release-readiness.md
- postmortem.md
