# Interface Control Document: Order Status Platform Interfaces

- **Status:** Approved
- **Version:** 1.0
- **Date:** 2026-03-19
- **Owner:** Commerce Platform Engineering
- **Reviewers:** Fulfillment Engineering, Customer Messaging
- **Related Documents:** system-architecture.md, high-level-design.md, ../requirements/srs.md

## 1. Purpose

Define the key contracts between the Order Status Platform and its upstream and downstream systems.

## 2. Scope

### 2.1 In Scope

- Warehouse event bus contract
- Carrier webhook contract
- Internal status API
- Notification milestone event contract

### 2.2 Out of Scope

- UI presentation details
- Raw carrier-specific payload schemas beyond referenced adapters

## 3. Interface Inventory

| Interface | Direction | Protocol | Owner | Notes |
| --- | --- | --- | --- | --- |
| `fulfillment.shipment-events.v1` | Inbound | Kafka | Fulfillment Engineering | Warehouse-originated shipment events |
| `/ingestion/carrier-events` | Inbound | HTTPS JSON | Integrations Team | Carrier adapter forwards validated events |
| `/internal/orders/{orderId}/status` | Outbound to clients | HTTPS JSON | Commerce Platform Engineering | Returns current state and timeline |
| `customer.order-status-events.v1` | Outbound | Kafka | Commerce Platform Engineering | Notification trigger events |

## 4. Interface Details

### 4.1 Warehouse Event Bus

Required fields: `orderId`, `shipmentId`, `sourceEventId`, `eventType`, `eventTime`, `locationCode`.

Behavioral expectations:

- Events are delivered at least once.
- `sourceEventId` is unique per producing system.
- `eventTime` is in UTC ISO 8601 format.

### 4.2 Carrier Webhook

Request body fields: `carrier`, `trackingNumber`, `shipmentId`, `carrierEventCode`, `eventTime`, `estimatedDeliveryDate`, `signature`.

Validation rules:

- Requests must include an integration signature header.
- Payload schema version must be supported.
- Unknown carrier event codes are rejected with a 202 response and routed to review.

### 4.3 Internal Status API

`GET /internal/orders/{orderId}/status`

Response example fields:

- `orderId`
- `currentStatus`
- `lastUpdatedAt`
- `estimatedDeliveryDate`
- `shipments[]`
- `timeline[]`

Access rules:

- Support tools require `order-status.read.support`.
- Internal services require `order-status.read.service`.

### 4.4 Notification Event Topic

Published event fields:

- `orderId`
- `shipmentId`
- `canonicalStatus`
- `eventTime`
- `customerContactRef`
- `correlationId`

Publication rules:

- Events publish only for `shipped`, `out_for_delivery`, `delayed`, and `delivered`.
- Duplicate publication for the same shipment and canonical status is suppressed.

## 5. Change Management

Breaking contract changes require versioned interface updates and consumer notification at least one release before enforcement.
