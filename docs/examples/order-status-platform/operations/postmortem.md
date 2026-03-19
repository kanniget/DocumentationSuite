# Incident Report / Postmortem: Delayed Carrier Webhook Processing on 2026-02-11

- **Status:** Complete
- **Date of Incident:** 2026-02-11
- **Authors:** Commerce Platform Engineering, SRE
- **Severity:** SEV-2
- **Related Services:** Carrier webhook ingestion, timeline processor, notification publisher

## 1. Summary

Carrier webhook traffic accumulated for 47 minutes after a certificate rotation caused signature validation failures on one integration path. During the incident, delivered and delayed shipment updates from one carrier were not incorporated into customer timelines, and milestone notifications were delayed.

## 2. Customer / Business Impact

- Approximately 18,400 shipment events were delayed.
- 6,900 customers received delivery notifications late.
- Support contacts regarding order status increased 14% during the incident window.

## 3. Detection

The on-call engineer was paged by the “carrier webhook rejection rate” alert at 14:12 UTC after rejection rate exceeded 10% for five minutes.

## 4. Timeline

| Time (UTC) | Event |
| --- | --- |
| 14:07 | Certificate rotation completed on ingress gateway |
| 14:12 | Alert fired for carrier rejection rate |
| 14:18 | On-call identified signature validation mismatch |
| 14:29 | Correct certificate chain applied |
| 14:36 | Replay of rejected events started |
| 14:54 | Backlog fully drained and timelines caught up |

## 5. Root Cause

The gateway trusted certificate bundle was updated, but the carrier adapter validation service was still using the previous signing chain. This mismatch caused all requests from one carrier integration to fail signature validation.

## 6. Contributing Factors

- Certificate rotation runbook did not include a cross-check for the adapter validation service.
- Synthetic webhook validation covered only the primary carrier integration.
- Alerting detected the issue quickly but did not identify the specific integration automatically.

## 7. Corrective and Preventive Actions

- [x] Update certificate rotation checklist to include adapter validation service verification.
- [x] Add synthetic webhook tests for all supported carriers.
- [ ] Add alert labels to isolate affected carrier integration.
- [ ] Automate pre-rotation validation in staging and production.

## 8. Lessons Learned

Shared trust configuration across independently deployed components must be verified explicitly during credential rotations. Replay tooling was effective, but diagnosis would have been faster with per-carrier alert segmentation.
