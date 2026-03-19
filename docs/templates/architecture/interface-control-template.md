# Interface Control Document: <interface-name>

- **Status:** Draft | In Review | Approved | Retired
- **Version:** <version>
- **Owner:** <name / team>
- **Consumers:** <systems / teams>
- **Providers:** <systems / teams>

## 1. Purpose and Scope

Describe the systems, teams, and use cases covered by this interface.

## 2. Interface Summary

| Attribute | Value |
| --- | --- |
| Interface Type | <API / file transfer / event / message queue / hardware / etc.> |
| Protocol / Standard | <protocol> |
| Direction | <producer to consumer / bidirectional> |
| Frequency / Volume | <rate> |
| Criticality | <high / medium / low> |

## 3. Data Contract

| Field / Message | Type | Required | Description | Constraints |
| --- | --- | --- | --- | --- |
| <field> | <type> | <yes/no> | <meaning> | <constraints> |

## 4. Behavioral Contract

- Request/response expectations
- Ordering guarantees
- Idempotency expectations
- Error handling and retry behavior
- Timeout expectations

## 5. Security

- Authentication mechanism
- Authorization model
- Encryption in transit / at rest
- Data sensitivity

## 6. Operational Considerations

- Monitoring signals
- Alert thresholds
- Support ownership
- Change management process

## 7. Versioning and Compatibility

Describe compatibility expectations and deprecation policy.

## 8. Test and Validation

Describe how producers and consumers will validate interoperability.
