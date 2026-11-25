<!--
title: New Engagement Onboarding Automation
version: 0.1
status: draft
author: Technical Lead, Implementation Vendor
date: 2026-11-24
spec-ref: spec/crm-to-practice-management-sync.md
intent-ref: intent/crm-to-practice-management-sync.md
source-of-truth: repo
supersedes:
-->

# Plan: New Engagement Onboarding Automation

---

## Summary

This plan implements the two-Lambda integration that connects the firm's CRM platform to its internal data warehouse, triggering on Closed Won deals. The outbound Lambda performs a completeness check and engagement-type translation, constructs the client/contact/engagement payload, and delivers it to the data warehouse via SQS. The inbound Lambda receives the callback from the data warehouse and writes the practice management client number, engagement number, and approval status back to the CRM. The scope ends at the data warehouse boundary — the data warehouse to practice management leg is owned by the client's internal IT team and is out of scope for this engagement.

---

## Status

| Phase | Status | Completion Date | Notes |
|-------|--------|----------------|-------|
| Phase 0: Environment Setup | Not started | | Blocked on Open Items 3, 9 |
| Phase 1: Outbound Lambda | Not started | | Blocked on Open Items 3, 4, 9 |
| Phase 2: Inbound Lambda | Not started | | Blocked on Open Items 1, 2 |
| Phase 3: Error Handling & Notification | Not started | | |
| Testing & UAT | Not started | | Blocked on Open Items 1, 5, 6 |
| Deployment — Sandbox | Not started | | |
| Deployment — Production | Not started | | |

---

## Files That Change

**Phase 0 (prerequisites — no code written)**
- None

**Phase 1: Outbound Lambda**
- `src/handlers/outbound.js` — created — CRM webhook handler; completeness check; payload construction; SQS send
- `src/lib/completeness.js` — created — required field validation logic
- `src/lib/translation-table.js` — created — engagement type → composite key lookup
- `config/translation-table.json` — created — engagement type mapping configuration (maintained by operations team)
- `src/lib/payload-builder.js` — created — constructs the data warehouse payload from CRM deal fields
- `src/lib/crm-client.js` — created — CRM REST API wrapper (read and write)

**Phase 2: Inbound Lambda**
- `src/handlers/inbound.js` — created — data warehouse callback handler; CRM write-back
- `src/lib/callback-validator.js` — created — validates callback payload structure

**Phase 3: Error Handling & Notification**
- `src/lib/notify.js` — created — notification dispatch (email/SNS) for all error categories
- `src/lib/errors.js` — created — error type constants and CRM error message templates
- `src/handlers/outbound.js` — modified — integrate Category A/B/C error branches
- `src/handlers/inbound.js` — modified — integrate Category C timeout handling

**Testing & UAT**
- `tests/outbound.test.js` — created — unit and integration tests for outbound handler
- `tests/inbound.test.js` — created — unit and integration tests for inbound handler
- `tests/translation-table.test.js` — created — translation table lookup coverage
- `tests/scenarios/` — created — UAT scenario scripts (Scenarios A, B, C)

**Deployment**
- `infrastructure/lambda.tf` or `template.yaml` — created — Lambda and SQS infrastructure definition [TBD: Terraform or SAM — see Architecture Decisions]
- `infrastructure/secrets.tf` — created — Secrets Manager secret definitions
- `infrastructure/cloudwatch.tf` — created — alarm and log group definitions

---

## Phase 0: Environment Setup

### Dependencies

| Prerequisite | Owner | Status | Notes |
|-------------|-------|--------|-------|
| Cloud platform confirmed (AWS or Azure) | Engineering Lead / Client IT | Pending | **Blocking** — see Open Item 3; this plan assumes AWS |
| AWS environment provisioned (Lambda, SQS, Secrets Manager, CloudWatch) | Client IT | Pending | Client provisions, vendor deploys code |
| CRM sandbox credentials stored in Secrets Manager | Client IT | Pending | OAuth 2.0 assumed — see Open Item 2 |
| Data warehouse interface specification received | Client IT | Pending | **Blocking** — see Open Item 9; required before Phase 1 |
| Data warehouse auth credentials stored in Secrets Manager | Client IT | Pending | Auth method TBD — see Open Item 9 |
| Practice management API credentials issued for sandbox | Practice Management Vendor | Pending | Vendor approval ~2–3 weeks from request |
| Translation table: all active CRM engagement types mapped to composite keys | Operations team | Pending | Required before Phase 1; see Open Item 4 |
| Sandbox CRM deal with all required fields (test data) | Client | Pending | Needed for Phase 1 smoke testing |
| Non-production environment provisioned | Client | Pending | |

### Local Development Setup

1. Clone the repository and install Node.js dependencies: `npm install`
2. Copy `.env.example` to `.env.local` and populate: `CRM_SECRET_ARN`, `DW_SECRET_ARN`, `SQS_OUTBOUND_QUEUE_URL`, `AWS_REGION`
3. Configure AWS CLI profile with sandbox IAM access
4. Confirm connectivity to CRM sandbox: `npm run verify:crm`
5. Confirm SQS queue exists: `aws sqs get-queue-attributes --queue-url $SQS_OUTBOUND_QUEUE_URL`

---

## Phase 1: Outbound Lambda

### Scope

Build the Lambda that handles the CRM Closed Won webhook: validates required fields, looks up the composite engagement type key, constructs the outbound payload, and sends it to the data warehouse via SQS. Writes `Pending` status to the CRM deal record after successful dispatch. This phase does not include error notification routing (Phase 3) — it emits errors for the notification layer to handle.

**Deferred to later phases:** inbound callback handling (Phase 2), notification dispatch (Phase 3), UAT (Testing & UAT).

### Tasks

1. **Create `src/handlers/outbound.js`** — entry point for the CRM webhook. Parses the incoming deal payload, calls the completeness checker, calls the translation table lookup, calls the payload builder, and places the constructed payload on the SQS outbound queue. On success, writes `Pending` to the CRM deal record via `crm-client.js`. Returns HTTP 200 to the CRM webhook dispatcher.
2. **Create `src/lib/completeness.js`** — validates that all required fields are present and non-null: company name, primary contact email, engagement type, contract value. Returns `{ valid: true }` or `{ valid: false, missingField: '<field name>' }`. Do not log email or phone values.
3. **Create `src/lib/translation-table.js`** — loads `config/translation-table.json` and exports a `lookup(engagementType)` function. Returns `{ serviceLine, engagementType }` or throws `UnmappedEngagementTypeError` if the value is not in the table. Table is loaded once at cold start and cached in module scope.
4. **Create `config/translation-table.json`** — empty mapping object `{}` as placeholder. Operations team populates before testing. File comment documents the expected schema: `{ "CRM value": { "serviceLine": "...", "engagementType": "..." } }`.
5. **Create `src/lib/payload-builder.js`** — constructs the data warehouse payload object from CRM deal fields. Field mapping follows the Data Transformation table in the spec. Applies ISO 8601 date formatting to `engagement.closeDate`. Maps address fields per [TO CONFIRM: data warehouse payload schema — Open Item 9].
6. **Create `src/lib/crm-client.js`** — thin wrapper around the CRM REST API. Methods: `getDeal(dealId)`, `updateDeal(dealId, fields)`, `updateCompany(companyId, fields)`. Uses credentials from Secrets Manager via `CRM_SECRET_ARN`. PII fields (email, phone) are never logged.
7. **Idempotency** — before placing a payload on SQS, check whether the CRM deal record already has a `Pending` or later status. If so, skip and return 200. Idempotency key: `deal-{crmDealId}:create:v1`.
8. **Unit tests in `tests/outbound.test.js`** — cover: valid deal triggers SQS send, missing required field returns Category A, unmapped engagement type returns Category A, duplicate deal is skipped, data warehouse unreachable after retries triggers Category C.

### Verification

- [ ] Webhook fires from CRM sandbox → Lambda invoked (visible in CloudWatch)
- [ ] Valid test deal → payload appears on SQS queue with correct field values
- [ ] `Pending` status written to CRM deal record after SQS send
- [ ] Deal with missing company name → Category A error, no SQS send
- [ ] Deal with unmapped engagement type → Category A error, no SQS send
- [ ] Idempotency: re-sending same deal does not create a second SQS message

### Blockers / Open Items

- Blocked on **Open Item 9** (data warehouse interface spec) — payload field names and types cannot be finalized until spec is received
- Blocked on **Open Item 4** (composite key mapping) — translation table cannot be populated until fields are confirmed
- Blocked on **Open Item 3** (cloud platform) — this phase assumes AWS Lambda and SQS

---

## Phase 2: Inbound Lambda

### Scope

Build the Lambda that receives the callback from the data warehouse after the practice management system has created the client and engagement records. Validates the callback payload, writes the client number to the CRM company record, and writes the engagement number and approval status to the CRM deal record. This phase handles the two approval status values (`Active` and `Pending Committee Review`).

**Deferred:** Category C timeout handling for missing callbacks (Phase 3).

### Tasks

1. **Create `src/handlers/inbound.js`** — entry point for the data warehouse callback. Parses the callback payload, calls `callback-validator.js`, calls `crm-client.js` to write client number, engagement number, and approval status. Returns HTTP 200 on success. Idempotency key: `callback-{practiceManagementClientNumber}:writeback:v1`.
2. **Create `src/lib/callback-validator.js`** — validates that the callback payload contains all three required fields: `clientNumber`, `engagementNumber`, `approvalStatus`. Validates that `approvalStatus` is one of `Active` or `Pending Committee Review`. Returns `{ valid: true }` or `{ valid: false, reason: '...' }`.
3. **Write-back logic in `src/handlers/inbound.js`:**
   - Write `clientNumber` to CRM company record field `PM Client ID`
   - Write `engagementNumber` to CRM deal record field `PM Engagement ID`
   - Write `approvalStatus` to CRM deal record field `PM Approval Status`
   - If `approvalStatus === 'Active'`: also set CRM deal status to `Active`
   - If `approvalStatus === 'Pending Committee Review'`: set CRM deal status to `Pending Committee Review`
4. **Guard against overwrite** — if the CRM company record already has a non-null `PM Client ID`, do not overwrite. Log the conflict for review and return 200.
5. **Unit tests in `tests/inbound.test.js`** — cover: valid callback writes all three fields, missing clientNumber returns 400, existing PM Client ID is not overwritten, approval status Active sets deal status, approval status Pending Committee Review sets deal status.

### Verification

- [ ] Simulated callback (via test HTTP POST to Lambda URL) → `PM Client ID` written to CRM company record
- [ ] `PM Engagement ID` written to CRM deal record
- [ ] `PM Approval Status` = `Active` → CRM deal status updated to `Active`
- [ ] `PM Approval Status` = `Pending Committee Review` → CRM deal status updated correctly
- [ ] Callback with missing `engagementNumber` → rejected; CRM record unchanged
- [ ] Second callback for same deal → `PM Client ID` not overwritten

### Blockers / Open Items

- Blocked on **Open Item 1** (client match key) — the `guard against overwrite` logic depends on knowing what field uniquely identifies a CRM company record in the practice management system
- Blocked on **Open Item 2** (CRM auth method) — `crm-client.js` auth implementation depends on confirmed method; OAuth 2.0 assumed

---

## Phase 3: Error Handling & Notification

### Scope

Wire all Category A, B, and C error branches to produce the correct CRM record updates and notifications. This phase connects the error types emitted by Phases 1 and 2 to the notification dispatch layer and the CRM write-back for error states.

### Tasks

1. **Create `src/lib/errors.js`** — define error type constants (`MISSING_FIELD`, `UNMAPPED_ENGAGEMENT_TYPE`, `MALFORMED_EMAIL`, `DW_PAYLOAD_REJECTED`, `DUPLICATE_CLIENT`, `DW_UNREACHABLE`, `CALLBACK_TIMEOUT`) and CRM error message templates (`Sync Error: missing [field name]`, etc.).
2. **Create `src/lib/notify.js`** — dispatches notifications to the correct recipient(s) for each error type. Uses AWS SNS or SES [TBD — confirm notification mechanism with client IT]. Recipients per error type follow the Error Handling & Exception Playbook in the spec.
3. **Category A wiring in `src/handlers/outbound.js`:**
   - Missing or null required field → write `Sync Error: missing [field name]` to CRM deal; notify administrative coordinator
   - Unmapped engagement type → write `Sync Error: unmapped engagement type [value]` to CRM deal; notify administrative coordinator and operations team
   - Malformed email → write error to CRM deal; notify administrative coordinator
4. **Category B wiring:**
   - Data warehouse rejects payload (non-2xx response) → log full response body; write `Sync Error: data warehouse rejected payload` to CRM deal; notify administrative coordinator and implementation vendor
   - Duplicate client detected (practice management returns existing record) → write existing client number to CRM company; notify administrative coordinator; flag for review
5. **Category C wiring:**
   - Data warehouse unreachable after 5 exponential-backoff retries → move payload to SQS dead-letter queue; write `Sync Error: data warehouse unreachable` to CRM deal; alert implementation vendor and client IT via CloudWatch alarm
   - Inbound callback not received within 24 hours → flag CRM deal with `Sync Warning: awaiting PM confirmation`; notify administrative coordinator [implementation note: requires a scheduled check or CloudWatch Events rule — see Open Item 11]
6. **PII log filter** — confirm that `src/lib/crm-client.js` and all handlers mask or exclude `primaryContact.email`, `primaryContact.phone`, `billingContact.email` from all CloudWatch log output.
7. **Update tests** — add error scenario coverage to `tests/outbound.test.js` and `tests/inbound.test.js`.

### Verification

- [ ] Missing required field → error message written to CRM deal; administrative coordinator notified; nothing sent to SQS
- [ ] Unmapped engagement type → error message written to CRM deal; administrative coordinator and operations team notified
- [ ] DW unreachable (5 retries exhausted) → payload in dead-letter queue; CloudWatch alarm fires
- [ ] CloudWatch logs for a full end-to-end flow contain no plaintext email addresses
- [ ] Category C callback timeout → CRM deal flagged with warning; administrative coordinator notified

### Blockers / Open Items

- **Open Item 8** (high-value deal review gate) — if enforced before payload send, an additional Category B branch must be added to the outbound handler; design blocked until resolved
- **Open Item 11** (new, plan-surfaced) — 24-hour callback timeout requires a scheduler. Mechanism not specified in spec. Options: CloudWatch Events rule polling a DynamoDB state table, or SQS message with visibility timeout. Confirm approach with client IT before build.

---

## Testing & UAT

### Scenario A: New client — full outbound and inbound flow

**What to verify:** A Closed Won deal for a client with no existing practice management record triggers the full flow. The client number and engagement number are written back to the CRM within 5 minutes.

**Setup:** Create a test deal in the CRM sandbox with all required fields populated. Confirm the client does not exist in the practice management system. Confirm the engagement type is in the translation table.

**Steps:**
1. Set the CRM sandbox deal stage to Closed Won
2. Confirm the outbound Lambda is invoked (CloudWatch)
3. Confirm the payload appears on the SQS outbound queue
4. Confirm the data warehouse receives the payload (sandbox DW log or test stub)
5. Trigger a simulated callback from the data warehouse with a test client number, engagement number, and `approvalStatus: Active`
6. Confirm the CRM deal record shows `PM Client ID`, `PM Engagement ID`, `PM Approval Status = Active`, and deal status = Active

**Expected result:** CRM deal and company records updated with practice management identifiers within 5 minutes of Closed Won. No manual action required.

**Actual result:** _(fill in during UAT)_

**Bugs found:** _(fill in during UAT)_

---

### Scenario B: Existing client — duplicate detection

**What to verify:** A Closed Won deal for a client who already has a practice management record does not create a duplicate. The existing client number is written to the CRM company record.

**Setup:** Create a test deal for a company that already has a practice management client record. Configure the duplicate detection response from the data warehouse or practice management system to return the existing client number.

**Steps:**
1. Set the CRM sandbox deal stage to Closed Won
2. Confirm outbound Lambda is invoked
3. Confirm the data warehouse (or practice management system) returns the existing client number instead of creating a new record
4. Trigger the inbound callback with the existing client number and a new engagement number
5. Confirm the CRM company record receives the existing `PM Client ID` (not a new one)
6. Confirm the CRM deal record receives the new engagement number

**Expected result:** No new client record created in practice management. CRM company record shows existing client number. Administrative coordinator receives a notification flagging the existing client match for review.

**Actual result:** _(fill in during UAT)_

**Bugs found:** _(fill in during UAT)_

---

### Scenario C: New client requiring committee approval

**What to verify:** A Closed Won deal for a new client that requires committee approval shows `Pending Committee Review` status in the CRM, then transitions to `Active` once approval is granted.

**Setup:** Create a test deal for a new client. Configure the practice management sandbox or test stub to return `approvalStatus: Pending Committee Review` on first callback, then `approvalStatus: Active` on a second callback.

**Steps:**
1. Set the CRM sandbox deal stage to Closed Won
2. Confirm outbound Lambda is invoked and payload sent
3. Trigger inbound callback with `approvalStatus: Pending Committee Review`
4. Confirm CRM deal status = `Pending Committee Review` and `PM Approval Status` field updated
5. Trigger a second inbound callback with `approvalStatus: Active`
6. Confirm CRM deal status transitions to `Active`

**Expected result:** CRM deal shows `Pending Committee Review` after first callback, then `Active` after second. No manual status update required.

**Actual result:** _(fill in during UAT)_

**Bugs found:** _(fill in during UAT)_

---

## Deployment — Sandbox

### Pre-deployment checklist

- [ ] All phases (1–3) complete and verified locally
- [ ] All three UAT scenarios pass in local or staging environment
- [ ] Open Items 3, 4, 9, and 10 resolved (cloud platform, translation table, DW interface spec, idempotency behavior)
- [ ] Code reviewed and approved by technical lead
- [ ] PII log filter confirmed (no email addresses in CloudWatch logs)

### Deployment steps

1. **Deploy Lambda functions** — `outbound` and `inbound` — to sandbox AWS environment using IaC (`terraform apply` or `sam deploy`)
2. **Configure SQS outbound queue** — confirm dead-letter queue is attached with 14-day retention
3. **Set Secrets Manager values** — verify CRM credentials and data warehouse credentials are present and correct in sandbox
4. **Register CRM webhook** — configure the CRM sandbox to send deal stage change events to the outbound Lambda URL
5. **Set up CloudWatch alarms** — confirm alarm for dead-letter queue depth > 0, Lambda error rate > 0
6. **Smoke test Scenario A** — close a test deal in the CRM sandbox and walk through the full flow manually

### Post-deployment verification

- [ ] Lambda invocations visible in CloudWatch for a test deal
- [ ] Test deal generates outbound payload on SQS
- [ ] Simulated callback writes back to CRM deal and company records
- [ ] Category A error (missing field) produces notification and CRM error status
- [ ] Dead-letter queue alarm fires when simulated DW unreachable error occurs

---

## Deployment — Production

### Go/no-go checklist

- [ ] All sandbox UAT scenarios pass (Scenarios A, B, C)
- [ ] All five spec Areas of Concern resolved (or risk accepted in writing by product owner)
- [ ] All blocking open items closed (1, 2, 3, 4, 8, 9, 10)
- [ ] Client IT confirms production AWS environment is provisioned and ready
- [ ] Production credentials stored in Secrets Manager
- [ ] Administrative coordinator briefed on exception handling process
- [ ] Business stakeholder sign-off received in writing
- [ ] Support contact from implementation vendor confirmed for 48-hour monitoring window
- [ ] Rollback procedure reviewed with client IT

### Cutover steps

1. Deploy Lambda functions to production environment
2. Configure production SQS queue and dead-letter queue
3. Set Secrets Manager values for production (CRM credentials, data warehouse credentials)
4. Register production webhook in CRM (replace or supplement sandbox webhook)
5. Set CloudWatch alarms for production
6. Monitor the first 3–5 live Closed Won deals manually to confirm end-to-end flow
7. Notify all affected roles (administrative coordinator, billing manager, engagement partner) that integration is live

### Rollback plan

If a critical error is detected within the 48-hour monitoring window:
1. Disable the CRM production webhook to stop outbound triggers immediately
2. Do not modify or reverse any CRM records already written — log the state for manual review
3. Notify administrative coordinator to resume manual data-entry process for new Closed Won deals
4. Engage client IT to review CloudWatch logs for root cause
5. Do not re-enable webhook until root cause is identified and a fix is deployed and tested in sandbox

### 48-hour monitoring window

After go-live, the implementation vendor monitors:
- Lambda error rates in CloudWatch (target: 0 unhandled errors per hour)
- Dead-letter queue depth (target: 0)
- CRM deal records for each Closed Won deal during the window (verify write-back completes)
- Notify all parties immediately if any Category C error fires

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Data warehouse REST API rate limits are lower than expected, causing throttling during a burst of Closed Won deals | Low | Medium | SQS queue provides natural buffering; monitor queue depth; implement exponential backoff on data warehouse send |
| Translation table has gaps at go-live (new or unusual engagement types not mapped) | Medium | Medium | Run translation table coverage check against all active CRM engagement types before sandbox deployment; operations team sign-off required as a go/no-go gate |
| Cloud platform unconfirmed — if Azure is required instead of AWS, infrastructure components change materially | Medium | High | Confirm cloud platform (Open Item 3) before any infrastructure work begins; this plan assumes AWS throughout |
| Practice management API does not support idempotent record creation | Low | High | If confirmed non-idempotent (Open Item 10), add pre-write deduplication check using the confirmed match key (Open Item 1) before any write; adjust Phase 2 scope |
| 24-hour callback timeout mechanism not designed (plan-surfaced gap) | Medium | Medium | Resolve Open Item 11 before Phase 3 build; options documented in Phase 3 task list |

---

## Architecture Decisions

| Decision | Rationale | Alternatives rejected |
|----------|-----------|----------------------|
| AWS assumed as cloud platform | Infrastructure-ownership policy default; not yet confirmed by client IT — see Open Item 3 | Azure (data warehouse may run on Azure infrastructure; if confirmed, revisit) |
| Event-driven (webhook + SQS) rather than polling | Deal closings are sparse and time-sensitive; polling at 15-minute intervals would add unnecessary latency and cost; webhook + SQS provides near-real-time delivery with decoupled retry | Polling CRM API on a schedule |
| Implementation vendor scope ends at the data warehouse boundary | Client IT team already owns the DW → practice management leg; splitting ownership at this boundary prevents architecture conflict | Vendor owning the full CRM → practice management chain (rejected due to IT team constraint) |
| Translation table as a JSON config file, not database | Low volume, infrequent changes, owned by operations team; a flat config file is easier to audit and update than a database table | Database lookup table (unnecessary complexity for this volume) |

---

## Open Items

| # | Description | Blocks (phase) | Owner | Status |
|---|-------------|---------------|-------|--------|
| 1 | How does the integration identify whether a client already exists in the practice management system — by company name, tax ID, or another unique identifier? What is the match confidence threshold? | Phase 2 (inbound guard against overwrite); UAT Scenario B | Operations Lead / Practice Management Vendor | Open |
| 2 | What authentication method does the CRM API use — OAuth 2.0, API key, mutual TLS, or other? | Phase 1 (crm-client.js) | Practice Management Vendor / IT | Open |
| 3 | Which cloud platform will host the integration runtime — AWS or Azure? This plan assumes AWS throughout. | Phase 0, all infrastructure | Engineering Lead / Client IT | Open |
| 4 | What fields make up the composite key for engagement type in the practice management system? Is the full mapping table already documented? | Phase 1 (translation table) | Operations / Practice Management Admin | Open |
| 5 | For the committee approval gate: does the CRM need to surface approval status in real time (minutes) or is an end-of-day batch update sufficient? | UAT Scenario C | Billing Manager / Engagement Partner | Open |
| 6 | What should happen if the outbound payload is sent for a client who already exists in the practice management system but the duplicate-detection logic did not catch the match? Update, reject, or notify? | Phase 2; UAT Scenario B | Operations Lead | Open |
| 7 | Is there a maximum number of contacts per client record in the practice management system? | Phase 1 (payload builder) | Practice Management Admin | Open |
| 8 | Does the second-level review requirement for high-value deals apply before the outbound payload is sent (CRM side) or inside the practice management system? Who defines the threshold? | Phase 3 (error handling — high-value gate) | Managing Partner / Compliance | Open |
| 9 | Data warehouse interface specification: exact REST endpoint URL, payload schema (field names, types, required fields), and authentication method. | Phase 1 (payload builder); Phase 0 (DW credentials) | Client IT team | Open — spec-surfaced |
| 10 | Does the practice management API support idempotent record creation? If the same deal payload is submitted twice, will it create a duplicate or return the existing record? | Phase 2 (pre-write deduplication guard) | Practice Management Vendor | Open — spec-surfaced |
| 11 | The 24-hour callback timeout (Category C) requires a scheduling mechanism. Options: CloudWatch Events rule polling a DynamoDB state table, or SQS message with visibility timeout. Confirm approach with client IT before Phase 3 build. | Phase 3 (callback timeout handling) | Implementation Vendor / Client IT | Open — plan-surfaced |

---

## Confirmed References

<!-- Fill in as each item is verified against the live systems. Build against these; do not re-verify unless the system changes. -->

| Item | Value | Confirmed by | Date |
|------|-------|-------------|------|
| CRM webhook endpoint (sandbox) | | | |
| CRM webhook endpoint (production) | | | |
| Data warehouse REST base URL (sandbox) | | | |
| Data warehouse auth method and secret ARN | | | |
| CRM auth method and secret ARN | | | |
| SQS outbound queue URL (sandbox) | | | |
| SQS dead-letter queue URL (sandbox) | | | |
| Translation table location in repo | `config/translation-table.json` | Technical Lead | 2026-11-24 |
| CRM deal field: PM Client ID | | | |
| CRM deal field: PM Engagement ID | | | |
| CRM deal field: PM Approval Status | | | |
| CRM company field: PM Client ID | | | |

---

## Source of Truth Linkage

**Authoritative system:** `repo`

This `.md` file is the authoritative record for this plan. Link to this file (or its Git commit SHA) from any external ticket or project tracker.

| Artifact | Location |
|----------|----------|
| Source spec | `spec/crm-to-practice-management-sync.md` |
| Source intent | `intent/crm-to-practice-management-sync.md` |
| External ticket / issue | _(not applicable — repo is authoritative)_ |
