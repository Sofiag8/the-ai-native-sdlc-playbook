<!--
title:
version: 0.1
status: draft
author:
date:
spec-ref:
intent-ref:
source-of-truth:
supersedes:
-->

# Plan: [Title]

---

## Summary

<!-- One paragraph. Plain language. What is being built, the trigger event, the systems involved, and the expected outcome. A product owner and a new team member should both be able to understand this without reading the spec. -->

---

## Status

| Phase | Status | Completion Date | Notes |
|-------|--------|----------------|-------|
| Phase 0: Environment Setup | Not started | | |
| Phase 1: [name] | Not started | | |
| Phase 2: [name] | Not started | | |
| Phase N: [name] | Not started | | |
| Testing & UAT | Not started | | |
| Deployment — Sandbox | Not started | | |
| Deployment — Production | Not started | | |

---

## Files That Change

<!-- List every file that will be created, modified, or deleted. Group by phase. Use this as a pre-flight check before each phase: if you're touching a file not on this list, update the plan. -->

**Phase 0 (prerequisites — no code written)**
- None

**Phase 1: [name]**
- `[path/to/file]` — created / modified — [one-line description]

**Phase 2: [name]**
- `[path/to/file]` — created / modified — [one-line description]

**Testing & UAT**
- `[path/to/test-file]` — created — [description]

**Deployment**
- `[path/to/deployment-config]` — modified — [description]

---

## Phase 0: Environment Setup

<!-- Every prerequisite that must be true before a line of integration code is written. Owner is the person or role responsible. Status is updated as prerequisites are met. -->

### Dependencies

| Prerequisite | Owner | Status | Notes |
|-------------|-------|--------|-------|
| AWS environment provisioned (Lambda, SQS, Secrets Manager, CloudWatch) | Client IT | Pending | |
| Sandbox credentials for source system stored in Secrets Manager | Client IT | Pending | |
| Sandbox credentials for target system stored in Secrets Manager | Client IT | Pending | |
| Non-production environment provisioned | Client | Pending | |
| Data warehouse interface specification received | Client IT | Pending | Required before Phase 1 |
| Translation table complete (all active mapping values) | Operations team | Pending | Required before Phase 1 |
| Target system API credentials issued for sandbox | Target system vendor | Pending | Vendor approval process: ~2–3 weeks |

### Local Development Setup

<!-- Steps an engineer needs to run before they can write and test code locally. -->

1. Clone the repository and install dependencies
2. Configure local environment variables (`.env.local`) — see Confirmed References for required keys
3. Confirm access to sandbox environments for all systems
4. Run existing test suite to establish a baseline

---

## Phase 1: [Implementation Phase Name]

<!-- One phase per major workstream from the spec. Rename the heading to match the work. Add or remove phases as needed. -->

### Scope

<!-- What this phase covers. One to three sentences. What is explicitly deferred to a later phase. -->

### Tasks

1. **[Task name]** — [specific enough to execute; name the file, function, or configuration item]
2. **[Task name]** — [description]
3. **[Task name]** — [description]

### Verification

<!-- How to confirm this phase is complete before moving to the next one. Be specific: what to call, what to check, what the expected response is. -->

- [ ] [Check 1]
- [ ] [Check 2]

### Blockers / Open Items

<!-- Cross-reference open items by number, e.g. "Blocked on Open Item 3 (data warehouse interface spec)." -->

---

## Phase 2: [Implementation Phase Name]

### Scope

### Tasks

1.
2.
3.

### Verification

- [ ]

### Blockers / Open Items

---

## Phase N: [Implementation Phase Name]

### Scope

### Tasks

1.
2.
3.

### Verification

- [ ]

### Blockers / Open Items

---

## Testing & UAT

<!-- One subsection per test scenario. Derive scenarios from the spec's Definition of Done. -->

### Scenario A: [Name]

**What to verify:** [Description of the scenario — which records, which trigger, which expected outcome]

**Setup:** [What must be true in the sandbox before running this scenario]

**Steps:**
1.
2.
3.

**Expected result:** [Specific, verifiable outcome — field values, system states, notifications]

**Actual result:** _(fill in during UAT)_

**Bugs found:** _(fill in during UAT)_

---

### Scenario B: [Name]

**What to verify:**

**Setup:**

**Steps:**
1.
2.
3.

**Expected result:**

**Actual result:** _(fill in during UAT)_

**Bugs found:** _(fill in during UAT)_

---

### Scenario C: [Name]

**What to verify:**

**Setup:**

**Steps:**
1.
2.
3.

**Expected result:**

**Actual result:** _(fill in during UAT)_

**Bugs found:** _(fill in during UAT)_

---

## Deployment — Sandbox

<!-- Step-by-step checklist to deploy the integration to the non-production environment. -->

### Pre-deployment checklist

- [ ] All phases complete and verified
- [ ] All UAT scenarios pass
- [ ] All open items blocking deployment are resolved
- [ ] Code reviewed and approved

### Deployment steps

1. **Deploy Lambda functions** — `[function names]` — via `[deployment method]`
2. **Configure SQS queues** — `[queue names]` — verify dead-letter queue is attached
3. **Set Secrets Manager values** — confirm all credentials are present and correct
4. **Configure webhook / trigger** — register `[trigger endpoint]` in source system
5. **Set up CloudWatch alarms** — confirm alert routing to `[notification target]`
6. **Smoke test** — trigger one end-to-end flow with a test record; confirm all systems update

### Post-deployment verification

- [ ] Lambda invocations visible in CloudWatch
- [ ] Test deal triggers outbound payload to data warehouse
- [ ] Callback received and CRM write-back completes
- [ ] Error scenario triggered and notification delivered

---

## Deployment — Production

### Go/no-go checklist

- [ ] Sandbox deployment verified (all scenarios pass)
- [ ] All spec Areas of Concern resolved
- [ ] All blocking open items closed
- [ ] Client IT confirms production AWS environment is ready
- [ ] Credentials provisioned in production Secrets Manager
- [ ] Rollback plan reviewed and understood by all parties
- [ ] Support contact confirmed for 48-hour monitoring window
- [ ] Business stakeholder sign-off received

### Cutover steps

1. Deploy Lambda functions to production environment
2. Configure production SQS queues and dead-letter queue
3. Register production webhook endpoint in source system
4. Confirm production CloudWatch alarms are active
5. Run one monitored live transaction as smoke test
6. Notify administrative coordinator that integration is live

### Rollback plan

If a critical error is detected within the 48-hour window:
1. Disable the CRM webhook to stop outbound triggers
2. Leave existing records unchanged — do not attempt to reverse any writes
3. Notify administrative coordinator to resume manual process for new deals
4. Investigate root cause using CloudWatch logs before re-enabling

### 48-hour monitoring window

After go-live, monitor:
- CloudWatch Lambda error rates (target: 0 unhandled errors)
- Dead-letter queue depth (target: 0)
- CRM deal records for deals closed after go-live (verify write-back completes)
- Notify all parties if any Category C errors occur

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| [Risk description] | Low / Medium / High | Low / Medium / High | [Mitigation approach] |

---

## Architecture Decisions

| Decision | Rationale | Alternatives rejected |
|----------|-----------|----------------------|
| [Decision] | [Why this was chosen] | [What else was considered and why it was not chosen] |

---

## Open Items

<!-- Carry all open items from the spec. Add plan-surfaced items numbered sequentially after. Update status as items are resolved. -->

| # | Description | Blocks (phase) | Owner | Status |
|---|-------------|---------------|-------|--------|
| 1 | [Carried from spec open item 1] | Phase [N] | [Owner] | Open |
| 2 | [Carried from spec open item 2] | Phase [N] | [Owner] | Open |

---

## Confirmed References

<!-- Verified live values: API endpoint URLs, field names, object IDs, auth scopes. Fill in as you confirm each one against the actual systems. These are the ground truth — build against these, don't re-verify. -->

| Item | Value | Confirmed by | Date |
|------|-------|-------------|------|
| Source system webhook endpoint | | | |
| Target system REST base URL | | | |
| Auth method and credentials location | | | |
| SQS queue ARN | | | |
| Dead-letter queue ARN | | | |
| Translation table location | | | |

---

## Source of Truth Linkage

<!-- Which system is authoritative for this plan. -->

**Authoritative system:** `[repo | jira:<ticket-id> | linear:<issue-id> | github-issue:<number>]`

<!-- If source-of-truth is repo: this .md file is the authoritative record. Link to it from any external ticket. -->
<!-- If source-of-truth is jira:<id>: this .md is a working copy. Claude reads from Jira at session start if connector is available. The plan.md reflects the state at last sync. -->
<!-- If source-of-truth is github-issue:<number>: this .md is a working copy. The GitHub issue is the canonical record. -->

| Artifact | Location |
|----------|----------|
| Source spec | `[spec/name.md]` |
| Source intent | `[intent/name.md]` |
| External ticket / issue | `[URL or ID, if applicable]` |
