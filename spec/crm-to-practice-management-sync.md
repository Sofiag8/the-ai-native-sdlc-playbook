<!--
title: New Engagement Onboarding Automation
version: 0.1
status: draft
author: Technical Lead, Implementation Vendor
date: 2026-11-24
intent-ref: intent/crm-to-practice-management-sync.md
google-doc-url:
reviewers: Engagement Partner, Administrative Coordinator, Client IT Lead
supersedes:
-->

# Spec: New Engagement Onboarding Automation

From: `intent/crm-to-practice-management-sync.md` (Engagement Manager, Business Development). Status: ready for product owner review.

Policies applied: `integration-security` v1.0 · `integration-standards` v1.0 · `infrastructure-ownership` v1.0

---

## Overview

When a deal is marked Closed Won in the CRM platform, this integration automatically creates the corresponding client, contact, and engagement records in the firm's practice management system — removing the 30–45 minute manual data-entry step currently performed by the administrative coordinator. The implementation vendor's scope covers the CRM-to-data-warehouse leg and the return sync that writes the practice management client number and engagement ID back to the CRM. The data-warehouse-to-practice-management leg is out of scope for this engagement and is owned by the client's internal IT team under a separate workstream.

---

## Important Definitions

| Term | Definition |
|------|-----------|
| CRM platform | The firm's sales and business development system; authoritative source for deal, client contact, and engagement data at time of close |
| Practice management system | The firm's operational system for scheduling, billing, and engagement tracking; assigns client numbers and engagement IDs after record creation |
| Data warehouse | An internal intermediary system owned by the client's IT team that routes payloads between the CRM and practice management system |
| Closed Won | The CRM deal stage that triggers the outbound payload |
| Client number | Unique identifier assigned by the practice management system after a client record is created; written back to the CRM company record |
| Engagement number | Unique identifier assigned by the practice management system after an engagement record is created; written back to the CRM deal record |
| Composite key | The practice management system requires a combination of service line + engagement type (two fields) to classify an engagement; the CRM stores only a single engagement type dropdown |
| Translation table | A configuration file maintained by the client's operations team that maps each CRM engagement type dropdown value to its corresponding service line and engagement type in the practice management system |
| Committee approval | An internal review required by the practice management system before a new client record becomes active |

---

## Scope Boundary

**This spec covers:**
- Outbound: CRM platform → data warehouse (payload sent when a deal stage changes to Closed Won and all required fields pass a completeness check)
- Inbound: data warehouse → CRM platform (practice management client number, engagement ID, and approval status written back to CRM deal and company records once practice management confirms record creation)
- Error notification to the administrative coordinator when a sync fails, with enough context to identify the cause

**This spec does NOT cover:**
- Data warehouse → practice management system: this leg is built and owned by the client's internal IT team under a separate workstream; this spec ends at the data warehouse boundary
- Historical migration of existing clients or past engagements
- Bidirectional field updates after the initial record creation (the return sync covers identifiers and status only)
- User provisioning, role configuration, or SSO in either system
- Reporting or dashboard configuration in the practice management system
- Any deal pipeline stage other than Closed Won
- Disaster recovery beyond standard AWS service guarantees

---

## Infrastructure & Ownership

| Component | Cloud Service | Owner | Notes |
|-----------|--------------|-------|-------|
| Integration runtime | AWS Lambda | Client (provisions); implementation vendor (code) | Event-driven; triggered by CRM webhook |
| Outbound message queue | AWS SQS | Client | Buffers payloads before sending to data warehouse; dead-letter queue for Category C failures |
| Secrets storage | AWS Secrets Manager | Client | CRM API credentials; data warehouse auth credentials |
| Logging | AWS CloudWatch | Client | All record processing events; PII fields excluded from logs |
| Inbound callback handler | AWS Lambda | Client (provisions); implementation vendor (code) | Receives callback from data warehouse; writes identifiers back to CRM |

**Cloud platform:** AWS (assumed per infrastructure-ownership policy default — see Areas of Concern #5 and Open Item 3)

---

## Proposed Flow

### Outbound — CRM Platform → Data Warehouse

1. CRM deal stage changes to Closed Won.
2. CRM webhook fires to outbound Lambda handler.
3. Lambda performs completeness check: validates all required fields (company name, primary contact email, engagement type, contract value) are present and non-null.
4. If validation fails → **Category A error**: write error status and field name to CRM deal record; notify administrative coordinator.
5. If engagement type value has no matching entry in the translation table → **Category A error**: write error status to CRM deal record; notify administrative coordinator and operations team (translation table owner).
6. If validation passes: Lambda constructs the outbound payload (client record, contacts, engagement record) and places it on the SQS outbound queue.
7. SQS triggers Lambda to send the payload to the data warehouse REST endpoint.
8. Lambda writes "Pending" status to the CRM deal record immediately after the payload is accepted by the data warehouse.
9. If the data warehouse is unreachable: exponential backoff retry (up to 5 attempts). After retry exhaustion → **Category C**: payload moved to dead-letter queue; alert sent to implementation vendor and client IT team.

### Inbound — Data Warehouse → CRM Platform

1. Practice management system creates client, contact, and engagement records and assigns a client number and engagement number.
2. Data warehouse receives confirmation from the practice management system.
3. Data warehouse fires callback to the inbound Lambda handler URL.
4. Lambda validates the callback payload (client number, engagement number, approval status present).
5. Lambda writes the client number to the CRM company record.
6. Lambda writes the engagement number and approval status to the CRM deal record.
   - If approval status = "Active": deal record status updated to "Active".
   - If approval status = "Pending Committee Review": deal record status updated to "Pending Committee Review".
7. If callback is not received within 24 hours → **Category C**: flag record for manual follow-up; notify administrative coordinator.

---

## Source System Integration Points

| System | API Type | Auth Method | Rate Limit | Trigger | Notes |
|--------|---------|-------------|-----------|---------|-------|
| CRM platform | REST | [TO CONFIRM: OAuth 2.0 assumed — see Open Item 2] | [TO CONFIRM: not provided in intent] | Webhook on deal stage change to Closed Won | Outbound |
| Data warehouse | REST | [TO CONFIRM: interface spec not yet received — see Open Item 9] | [TO CONFIRM] | Payload POST from outbound Lambda; callback URL for inbound | Boundary of this spec; data warehouse owned by client IT |
| CRM platform (write-back) | REST | Same as above | Same as above | Called by inbound Lambda after callback received | Inbound write-back only |

---

## Volume

| Metric | Estimate | Basis |
|--------|---------|-------|
| Closed Won deals per month | [TO CONFIRM] | Intent states volume has grown but no figure given |
| Payload size per deal | ~5–10 KB | Client record + 2 contacts + engagement record + metadata |
| Peak concurrent operations | Low — event-driven | Deal closings are not expected to cluster simultaneously |
| Dead-letter queue retention | 14 days | Standard SQS DLQ retention before manual review |

---

## Data Transformation

**Idempotency key pattern:** `deal-{crmDealId}:create:v1` for outbound; `callback-{practiceManagementClientNumber}:writeback:v1` for inbound write-back.

| Source Field (CRM) | Target Field (Data Warehouse Payload) | Type | Transformation Rule | Notes |
|---|---|---|---|---|
| Company: Name | `client.name` | String | None | Authoritative in CRM at time of send |
| Company: Billing Address (Street, City, State, Zip) | `client.address` | Object | Map to address object | [TO CONFIRM: exact address field structure in data warehouse payload spec] |
| Primary Contact: First Name | `primaryContact.firstName` | String | None | |
| Primary Contact: Last Name | `primaryContact.lastName` | String | None | |
| Primary Contact: Email | `primaryContact.email` | String | None | **PII — do not log plaintext** |
| Primary Contact: Phone | `primaryContact.phone` | String | None | **PII — do not log plaintext** |
| Billing Contact: First Name | `billingContact.firstName` | String | None | May be same person as primary contact; sent as distinct role |
| Billing Contact: Last Name | `billingContact.lastName` | String | None | |
| Billing Contact: Email | `billingContact.email` | String | None | **PII — do not log plaintext** |
| Deal: Engagement Type (single dropdown) | `engagement.serviceLine` + `engagement.engagementType` | Composite | Look up in translation table: CRM engagement type → {serviceLine, engagementType} | Config-managed; translation table maintained by operations team |
| Deal: Contract Value | `engagement.contractValue` | Decimal | None | Used for second-level review gate — see Open Item 8 |
| Deal: Close Date | `engagement.closeDate` | Date | ISO 8601 format (YYYY-MM-DD) | |
| Client Number (inbound callback) | CRM Company: Practice Management Client ID | String | Write-back only | Authoritative in practice management after assignment; must not be overwritten by CRM |
| Engagement Number (inbound callback) | CRM Deal: Practice Management Engagement ID | String | Write-back only | Authoritative in practice management after assignment |
| Approval Status (inbound callback) | CRM Deal: PM Approval Status | Enum | "Active" or "Pending Committee Review" | Updated by inbound Lambda after each callback |

---

## Source of Truth

| Entity | Field | Authoritative System | Rule |
|--------|-------|---------------------|------|
| Client / Company | All fields except client number | CRM at time of send | CRM value used at payload construction; no ongoing sync |
| Client / Company | Practice Management Client Number | Practice management system | Write-back only after assignment; CRM must not overwrite |
| Contact | Name, email, phone | CRM at time of send | No ongoing sync after initial creation |
| Engagement | All fields except engagement number | CRM at time of send | CRM value used at payload construction; no ongoing sync |
| Engagement | Practice Management Engagement Number | Practice management system | Write-back only after assignment |
| Engagement | PM Approval Status | Practice management system | Updated via inbound callback |

---

## Error Handling & Exception Playbook

| Category | Scenario | Behavior | Notification | Owner |
|----------|---------|---------|-------------|-------|
| A | Required field missing or null at completeness check | Reject before send; write "Sync Error: missing [field name]" to CRM deal record | Email/notification to administrative coordinator with field name | Administrative Coordinator |
| A | Engagement type value not found in translation table | Reject before send; write "Sync Error: unmapped engagement type [value]" to CRM deal | Notify administrative coordinator and operations team | Operations team (must update translation table) |
| A | Contact email address malformed (not a valid email format) | Reject before send | Notify administrative coordinator | Administrative Coordinator |
| B | Data warehouse rejects payload (malformed payload or schema mismatch) | Log rejection with full response body; write "Sync Error: data warehouse rejected payload" to CRM deal | Notify administrative coordinator and implementation vendor | Implementation vendor |
| B | Duplicate client detected by practice management system | Do not create new record; write existing client number to CRM company record | Notify administrative coordinator; flag for review | Administrative Coordinator |
| B | Second-level review required for high-value deal — gate not met | [TO CONFIRM: depends on where this gate is enforced — see Open Item 8] | [TO CONFIRM] | [TO CONFIRM — see Areas of Concern #4] |
| C | Data warehouse unreachable after 5 retry attempts | Quarantine payload in SQS dead-letter queue; write "Sync Error: data warehouse unreachable" to CRM deal | Alert implementation vendor and client IT team via CloudWatch alarm | Implementation vendor + Client IT |
| C | Inbound callback from data warehouse not received within 24 hours | Flag CRM deal record with "Sync Warning: awaiting PM confirmation"; notify | Notify administrative coordinator for manual follow-up | Administrative Coordinator |

---

## Responsibilities

| Task | Implementation Vendor | Client |
|------|-----------------------|--------|
| CRM webhook configuration | ✓ | |
| Outbound Lambda code | ✓ | |
| Inbound callback Lambda code | ✓ | |
| AWS infrastructure provisioning (Lambda, SQS, Secrets Manager, CloudWatch) | | ✓ |
| Secrets provisioning (CRM API credentials, data warehouse auth) | | ✓ |
| Translation table content (engagement type → composite key mapping) | | ✓ (Operations team) |
| Translation table configuration updates after go-live | | ✓ (Operations team) |
| Data warehouse interface specification delivery | | ✓ (IT team) |
| Data warehouse → practice management leg | | ✓ (IT team) |
| Practice management API credentials procurement | | ✓ (Operations / practice management vendor) |
| Sandbox test data (deals, contacts, engagement types) | | ✓ |
| Non-production environment provisioning | | ✓ |
| Production monitoring and alerting | | ✓ |

---

## Assumptions and Limitations

1. The data warehouse exposes a REST endpoint that accepts the outbound payload and can fire a callback URL for inbound confirmation. If the data warehouse uses a file-based or polling-based interface instead, the outbound and inbound architecture will change materially.
2. The CRM platform supports webhooks on deal stage changes. If webhooks are not available, outbound will fall back to polling at a 15-minute interval.
3. The translation table covers all active engagement types in the CRM at go-live. New engagement types added after go-live require a configuration update by the operations team before they can be synced — records with unmapped types will fail with a Category A error until the table is updated.
4. The practice management API supports idempotent record creation (sending the same deal twice does not create a duplicate). If not, the integration must implement a pre-write deduplication check using the confirmed match key.
5. The inbound callback fires within 24 hours of the outbound payload being accepted by the data warehouse. If practice management processing takes longer (e.g., committee approval review), the timeout window may need to be adjusted.
6. The data warehouse callback includes all three return fields: client number, engagement number, and approval status. If only partial data is returned, the inbound Lambda must handle partial write-backs gracefully.

---

## Definition of Done

- [ ] All open items in this document are resolved and recorded
- [ ] Data warehouse interface specification received, reviewed, and confirmed by implementation vendor and client IT team
- [ ] Practice management API credentials issued and stored in AWS Secrets Manager in sandbox environment
- [ ] Translation table complete: all active CRM engagement type values mapped to composite keys; reviewed by operations team
- [ ] Three test scenarios pass in non-production environment:
  - [ ] New client (no existing practice management record): full outbound + inbound flow, client number and engagement number written back to CRM
  - [ ] Existing client (practice management record already exists): duplicate detection fires, existing client number written to CRM, no new record created
  - [ ] New client requiring committee approval: outbound sends, "Pending Committee Review" written to CRM deal, then transitions to "Active" after approval
- [ ] All Category A, B, and C error scenarios produce correct notifications and CRM record updates in non-production
- [ ] Product owner has reviewed and resolved all Areas of Concern (or accepted risk in writing)
- [ ] CRM deal records show practice management client number and engagement ID within 5 minutes of a successful downstream setup (verified in non-production)

---

## Costs and Ownership

**Estimated monthly cloud infrastructure cost: $30–$60/month**

| Component | Estimated cost |
|-----------|---------------|
| AWS Lambda invocations (outbound + inbound, low volume) | < $1/month |
| AWS SQS messages (outbound queue + DLQ) | < $1/month |
| AWS Secrets Manager (2 secrets) | ~$2/month |
| AWS CloudWatch logs and alarms | ~$10–20/month |
| **Total estimate** | **$12–$24/month** (conservative, event-driven, low volume) |

_Note: If volume significantly exceeds current estimates or if real-time monitoring dashboards are added, costs may increase. Re-estimate when volume is confirmed._

**Ownership:** Client provisions and pays for all AWS infrastructure.

**Code warranty:** Implementation vendor covers defects in its own integration code for 10 business days after go-live. Infrastructure failures, AWS service outages, practice management API changes, data warehouse interface changes, and data quality issues in the CRM are outside warranty scope.

---

## Omissions

1. Data warehouse → practice management system leg — built and owned by client's internal IT team under a separate workstream
2. Historical migration of existing clients or past engagements
3. Bidirectional field updates after initial record creation (return sync covers identifiers and approval status only)
4. User provisioning, role configuration, or SSO in CRM or practice management system
5. Reporting or dashboard configuration in the practice management system
6. Performance SLAs beyond the 5-minute write-back latency target in Definition of Done
7. Disaster recovery beyond standard AWS service guarantees
8. Any deal pipeline stage other than Closed Won

---

## Open Items

| # | Item | Who can answer | Needed by | Status |
|---|------|---------------|-----------|--------|
| 1 | How does the integration identify whether a client already exists in the practice management system — by company name, tax ID, or another unique identifier? What is the match confidence threshold? | Operations Lead / Practice Management Vendor | Before design begins | Open |
| 2 | What authentication method does the practice management API use — OAuth 2.0, API key, mutual TLS, or other? | Practice Management Vendor / IT | Before design begins | Open |
| 3 | Which cloud platform will host the integration runtime — AWS or Azure? (This spec assumes AWS.) | Engineering Lead / Client IT | Before design begins | Open |
| 4 | What fields make up the composite key for engagement type in the practice management system — specifically, is "service line" a separate field or embedded in the engagement type value? Is the full mapping table already documented? | Operations / Practice Management Admin | Before design begins | Open |
| 5 | For the committee approval gate: does the CRM need to surface approval status in real time (minutes) or is an end-of-day batch update sufficient? | Billing Manager / Engagement Partner | Before build of return sync | Open |
| 6 | What should happen if the outbound payload is sent for a client who already has an active record in the practice management system but the duplicate-detection logic did not catch the match? Update the existing record, reject the payload, or notify a human? | Operations Lead | Before build of outbound | Open |
| 7 | Is there a maximum number of contacts per client record in the practice management system? | Practice Management Admin | Before build of contact sync | Open |
| 8 | Does the second-level review requirement for high-value deals apply before the outbound payload is sent (enforced by CRM), or after receipt inside the practice management system? Who defines the contract value threshold? | Managing Partner / Compliance | Before build of outbound gate | Open |
| 9 | Data warehouse interface specification: exact REST endpoint URL, payload schema (field names, types, required fields), and authentication method. | Client IT team | Before build begins | Open — spec-surfaced |
| 10 | Does the practice management API support idempotent record creation? If the same deal payload is submitted twice, will it create a duplicate record or return the existing record? | Practice Management Vendor | Before build begins | Open — spec-surfaced |

---

## Decision Record

| Decision | Rationale | Date | Owner |
|----------|-----------|------|-------|
| Implementation vendor scope ends at the data warehouse boundary | Client IT team already owns the data warehouse → practice management leg under a separate workstream; splitting ownership at the data warehouse boundary avoids architectural conflict | 2026-11-24 | Engagement Partner |
| No historical data migration included in this scope | Risk of duplicate record creation is too high to include in initial go-live; a separate migration project with a confirmed deduplication strategy is required | 2026-11-24 | Engagement Partner |
| AWS assumed as cloud platform for cost estimation | Cloud platform not confirmed in intent; AWS used as default per infrastructure-ownership policy. Must be confirmed before build. | 2026-11-24 | Technical Lead |

---

## Areas of Concern

| # | Concern | Policy / Gap | Owner | Resolution Status |
|---|---------|-------------|-------|------------------|
| 1 | The composite key translation table (CRM engagement type → practice management service line + engagement type) has no documented owner for ongoing maintenance. If a new CRM engagement type is added after go-live and the table is not updated, records with that type will fail with a Category A error silently until someone notices. | integration-standards: configuration items must have a named maintenance owner | Operations team | Open — assign maintenance owner before build |
| 2 | Deduplication strategy for existing clients is not fully defined. The integration must check for existing clients before creating a new record, but the match key (company name, tax ID, or other identifier) has not been confirmed. Using the wrong match key risks creating duplicate records in the practice management system. | integration-standards: deduplication required; match key not specified | Operations Lead / Practice Management Vendor | Open — see Open Item 1 |
| 3 | Contact fields — primary contact email and billing contact email — are PII. These fields must not be logged in plaintext in AWS CloudWatch. The outbound Lambda must mask or exclude email fields from all log output. | integration-security: PII must not be logged in plaintext | Implementation vendor | Open — confirm logging filter pattern before build |
| 4 | The second-level review gate for high-value deals (Open Item 8) is unresolved. If this gate is enforced inside the practice management system (not by the CRM), the outbound flow in this spec is unaffected. If it is enforced before the payload is sent, an additional pre-send check must be added to the outbound Lambda. This ambiguity blocks outbound design. | integration-standards: approval workflow must be fully specified | Managing Partner / Compliance | Open — blocked on Open Item 8 resolution |
| 5 | Cloud platform for the integration runtime is not confirmed. This spec assumes AWS. If the client's IT team requires Azure (consistent with their existing data warehouse infrastructure), the cloud component list changes and costs must be re-estimated. | infrastructure-ownership: cloud platform decision required | Engineering Lead / Client IT | Open — see Open Item 3 |

---

## Related Documents

| Document | Location | Notes |
|----------|----------|-------|
| Source intent document | `intent/crm-to-practice-management-sync.md` | Input to this spec |
| Google Doc version | [TO CONFIRM: run /create-spec with Google Workspace connected to generate] | Stakeholder-facing copy |
| Data warehouse interface specification | To be provided by client IT team | Required before build begins — see Open Item 9 |
| Practice management API documentation | To be provided by vendor | Required before design begins — see Open Item 2 |
| Composite key translation table | To be created by operations team | Required before build begins — see Open Item 4 |
| Field mapping workbook | To be created in Stage 3 (Build) | Downstream from this spec |
