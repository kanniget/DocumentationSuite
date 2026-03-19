# Low-Level Design (DLD): Order Status Platform Event Processing

- **Status:** In Review
- **Version:** 0.8
- **Date:** 2026-03-19
- **Owner:** Commerce Platform Engineering
- **Reviewers:** SRE, Data Engineering
- **Related Documents:** high-level-design.md, interface-control.md, ../requirements/srs.md

## 1. Purpose

Capture component-level behavior for event validation, canonical mapping, deduplication, persistence, and notification publication.

## 2. Scope

### 2.1 In Scope

- Carrier webhook request handling
- Warehouse event consumer behavior
- State projection algorithm
- Timeline persistence schema
- Notification publication rules

### 2.2 Out of Scope

- Support UI implementation details
- Carrier adapter service internals

## 3. Component Design

### 3.1 Ingestion Worker

- Validates authentication context.
- Parses payloads against versioned schemas.
- Derives a deterministic idempotency key from source system, shipment ID, source event ID, and status code.
- Writes invalid payloads to the DLQ with rejection reason.

### 3.2 Canonical Mapper

Mapping rules convert source-specific states such as `manifested`, `in_transit`, and `exception_delay` into canonical states like `packed`, `shipped`, `in_transit`, and `delayed`. Late-arriving events are stored but only update current state when their event time is newer than the active snapshot or when they fill a missing earlier milestone.

### 3.3 State Projection Service

For each accepted event:

1. Read the current shipment snapshot.
2. Compare idempotency key and source ordering metadata.
3. Append the normalized event to the timeline table.
4. Recalculate current state, latest estimated delivery date, and milestone flags.
5. Commit timeline write and snapshot update in a single transaction.
6. Enqueue notification publication if a publishable milestone changed.

### 3.4 Notification Publisher

The publisher consumes an internal outbox table and emits milestone events with order ID, shipment ID, canonical status, event time, and customer contact reference. Retries use exponential backoff; poison messages are sent to a publisher DLQ.

## 4. Data Structures

### 4.1 `shipment_timeline_events`

| Column | Type | Notes |
| --- | --- | --- |
| event_id | UUID | Internal unique identifier |
| order_id | String | Business order key |
| shipment_id | String | Shipment grouping key |
| source_system | String | Warehouse or carrier identifier |
| source_event_id | String | Idempotency input |
| canonical_status | String | Normalized state |
| event_time | Timestamp | Source event time |
| ingested_at | Timestamp | Processing time |
| payload_ref | String | Pointer to raw payload store |

### 4.2 `shipment_current_state`

| Column | Type | Notes |
| --- | --- | --- |
| shipment_id | String | Primary key |
| order_id | String | Query index |
| current_status | String | Latest active canonical status |
| last_event_time | Timestamp | Snapshot freshness |
| estimated_delivery_date | Date | Optional prediction field |
| last_published_status | String | Notification dedupe helper |

## 5. Sequence Overview

1. Source event arrives through webhook or event bus.
2. Ingestion worker validates schema and auth.
3. Canonical mapper creates normalized event.
4. Projection service writes timeline event and updates snapshot.
5. Outbox record is created when state changed to a publishable milestone.
6. Notification publisher emits downstream event and records success.

## 6. Failure Handling

- Schema failures go to the ingestion DLQ.
- Database transaction failures are retried up to three times.
- Publisher failures remain in the outbox until retry threshold is met.
- Reprocessing uses source offsets for bus events and replay files for webhook traffic.

## 7. Observability Hooks

- Metric: `order_status_event_processing_latency_ms`
- Metric: `order_status_timeline_write_failures_total`
- Metric: `order_status_dlq_depth`
- Log fields: `order_id`, `shipment_id`, `source_system`, `source_event_id`, `canonical_status`, `correlation_id`
