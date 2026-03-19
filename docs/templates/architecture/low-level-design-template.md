# Low-Level Design (DLD): <component-or-service-name>

- **Status:** Draft | In Review | Approved | Superseded
- **Version:** <version>
- **Date:** <yyyy-mm-dd>
- **Owner:** <name / team>
- **Reviewers:** <names>
- **Related Documents:** <HLD / SRS / ADRs / ICDs / Runbook>

## 1. Purpose

Describe the implementation-oriented detail captured in this document and the component, service, or module it covers.

## 2. Scope and Context

### 2.1 Scope

Describe the precise implementation boundary for this design.

### 2.2 Upstream and Downstream Dependencies

| Dependency | Relationship | Interface / Contract | Notes |
| --- | --- | --- | --- |
| <dependency> | <upstream/downstream/internal> | <interface> | <notes> |

## 3. Detailed Design

### 3.1 Component Breakdown

| Module / Class / Process | Responsibility | Inputs | Outputs |
| --- | --- | --- | --- |
| <element> | <responsibility> | <inputs> | <outputs> |

### 3.2 Control Flow / Sequence

Describe request handling, event processing, orchestration, and failure paths. Link sequence diagrams if available.

### 3.3 State Management

Describe state transitions, caching, concurrency handling, and lifecycle expectations.

### 3.4 Data Model

| Entity / Structure | Description | Source of Truth | Validation Rules |
| --- | --- | --- | --- |
| <entity> | <description> | <system> | <rules> |

### 3.5 Persistence Design

Describe schema, indexing, retention, migration, and consistency requirements.

## 4. Interface Details

### 4.1 API / Message Details

| Endpoint / Topic / Method | Input | Output | Errors | Notes |
| --- | --- | --- | --- | --- |
| <interface> | <input> | <output> | <errors> | <notes> |

### 4.2 Validation and Error Handling

- Input validation rules
- Retry behavior
- Idempotency strategy
- Dead-letter or fallback behavior

## 5. Security Design

- Authentication and authorization checks
- Secret usage and storage
- Data protection controls
- Audit and logging requirements

## 6. Performance and Capacity

- Expected throughput / concurrency
- Latency budgets
- Resource sizing assumptions
- Bottlenecks and optimization considerations

## 7. Observability and Operations

- Metrics, logs, and traces to emit
- Alert conditions
- Runbook links
- Deployment and rollback considerations

## 8. Testing Strategy

| Test Type | Scope | Owner | Notes |
| --- | --- | --- | --- |
| <unit/integration/e2e/performance> | <scope> | <owner> | <notes> |

## 9. Implementation Plan

| Task | Owner | Dependency | Status |
| --- | --- | --- | --- |
| <task> | <owner> | <dependency> | <status> |

## 10. Risks, Tradeoffs, and Technical Debt

| Item | Type | Impact | Mitigation / Follow-up |
| --- | --- | --- | --- |
| <item> | <risk/tradeoff/debt> | <impact> | <plan> |

## 11. Open Questions

- <question>

## 12. References

- <reference>
