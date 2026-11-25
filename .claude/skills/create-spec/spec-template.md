<!--
title:
version: 0.1
status: draft
author:
date:
intent-ref:
google-doc-url:
reviewers:
supersedes:
-->

# Spec: [Short Title]

From: `[intent-ref]` ([author of intent], [their role]). Status: ready for product owner review.

Policies applied: `integration-security` v1.0 · `integration-standards` v1.0 · `infrastructure-ownership` v1.0

---

## Overview

> _One paragraph. Plain language. What this integration does and why it exists. No technical jargon._

[Describe the integration at a level a business stakeholder can understand: which systems are connected, what data moves, and what problem it solves once live.]

---

## Important Definitions

> _Define every term that is used throughout this document with a non-obvious meaning. Neutral labels only — no real system or company names._

| Term | Definition |
|------|-----------|
| [Source system] | [What it is and its role in this integration] |
| [Target system] | [What it is and its role in this integration] |
| [Key business term] | [Plain-language definition] |

---

## Scope Boundary

> _Carried from the intent and extended with technical specifics confirmed during spec generation._

**This spec covers:**
- [e.g., Outbound: source system → intermediary system, triggered on [event]]
- [e.g., Inbound: intermediary system → source system, return of [identifiers]]
- [e.g., Error notification to [role] when sync fails]

**This spec does NOT cover:**
- [e.g., [intermediary system] → [target system] leg — owned by [team] under a separate workstream]
- [e.g., Historical data migration — separate project]
- [e.g., User provisioning, SSO, or role configuration]

---

## Infrastructure & Ownership

> _Who provisions what. The client owns all cloud infrastructure. The implementation vendor owns the code._

| Component | Cloud Service | Owner | Notes |
|-----------|--------------|-------|-------|
| Integration runtime | [Lambda / Azure Function / etc.] | Client (provisioned); implementation vendor (code) | |
| Message queue | [SQS / Service Bus / etc.] | Client | |
| Secrets storage | [Secrets Manager / Key Vault / etc.] | Client | |
| Logging | [CloudWatch / Monitor / etc.] | Client | |
| [Add rows as needed] | | | |

**Cloud platform:** [AWS / Azure / GCP — or TO CONFIRM if unconfirmed]

---

## Proposed Flow

> _Step-by-step numbered flows. One subsection per direction._

### Outbound — [Source System] → [Intermediary / Target]

1. [Step 1, e.g., Deal stage changes to Closed Won in source system]
2. [Step 2, e.g., Webhook fires to integration runtime]
3. [Step 3, e.g., Integration runtime validates required fields]
4. [Step 4, e.g., If validation fails → Category A error]
5. [Step 5, e.g., If validation passes → payload constructed and sent]
6. [Continue until confirmation is received or failure is handled]

### Inbound — [Source] → [Source System] _(if applicable)_

1. [Step 1]
2. [Continue...]

---

## Source System Integration Points

> _Technical connection details for every system the integration touches._

| System | API Type | Auth Method | Rate Limit | Trigger | Notes |
|--------|---------|-------------|-----------|---------|-------|
| [Source system] | REST / GraphQL / SOAP / File | OAuth 2.0 / API key / [TO CONFIRM] | [requests/sec or TO CONFIRM] | Webhook on [event] / Polling every [interval] | |
| [Target system] | REST | [TO CONFIRM] | [TO CONFIRM] | Callback / response | |

---

## Volume

> _How much data moves, how often, and what the peak looks like._

| Metric | Estimate | Basis |
|--------|---------|-------|
| Records per [day/week/month] | [number] | [source of estimate] |
| Payload size per record | [KB] | [fields × average field size] |
| Peak concurrent operations | [number] | [basis] |
| File size (if file-based) | [MB] | [TO CONFIRM] |

---

## Data Transformation

> _Every field that moves between systems. PII fields must be noted._

| Source Field | Target Field | Type | Transformation Rule | Notes |
|-------------|-------------|------|---------------------|-------|
| [Source system: Field Name] | [Target system: Field Name] | String / Number / Boolean / Date / Enum / Object | None / [describe transformation] | PII — do not log / Config-managed / [TO CONFIRM] |
| [Add rows for every field] | | | | |

**Idempotency key pattern:** `[sourceId]:[operationType]:[version]` — e.g., `deal-12345:create:v1`

---

## Source of Truth

> _When both systems hold the same field and they disagree, which one wins?_

| Entity | Field | Authoritative System | Rule |
|--------|-------|---------------------|------|
| [Entity name] | All fields | [Source system] at time of send | [Source system] value overwrites [target system] on sync |
| [Entity name] | [Specific field, e.g., External ID] | [Target system] after assignment | Write-back only — do not overwrite once assigned |
| [Add rows as needed] | | | |

---

## Error Handling & Exception Playbook

> _Every failure scenario categorized, with behavior and notification defined. See integration-standards policy for category definitions._

| Category | Scenario | Behavior | Notification | Owner |
|----------|---------|---------|-------------|-------|
| A | Required field missing or null | Reject before send; write error status to source record | Notify [operations role] with field name | [Operations role] |
| A | Field value has no mapping in translation table | Reject before send | Notify [operations role] and [table owner] | [Operations role] |
| B | Target system rejects payload | Log rejection with response body; write error status | Notify [operations role] and implementation vendor | Implementation vendor |
| B | Duplicate record detected in target system | Do not create; write existing ID to source record | Notify [operations role] | [Operations role] |
| C | Target system unreachable after [5] retries | Quarantine in dead-letter queue | Alert implementation vendor and client IT | Implementation vendor + Client IT |
| C | Inbound confirmation not received within [24 hours] | Flag record for manual follow-up | Notify [operations role] | [Operations role] |
| [Add rows for scenario-specific cases] | | | | |

---

## Responsibilities

> _Every task assigned to either the implementation vendor or the client. No task may be left unassigned._

| Task | Implementation Vendor | Client |
|------|-----------------------|--------|
| Integration runtime code | ✓ | |
| Cloud infrastructure provisioning | | ✓ |
| Secrets provisioning (API credentials) | | ✓ |
| Translation table / mapping configuration content | | ✓ ([team]) |
| Sandbox test data | | ✓ |
| Third-party system API credentials | | ✓ |
| Production monitoring and alerting | | ✓ |
| [Add rows as needed] | | |

---

## Assumptions and Limitations

> _Numbered. Each item is something the design depends on that has not been fully confirmed._

1. [e.g., The target system API supports idempotent record creation. If not, the integration must implement a pre-write deduplication check.]
2. [e.g., The source system supports webhooks on [event]. If not, polling at [interval] will be used as a fallback.]
3. [e.g., The translation table covers all active [entity types] at go-live. New values added after go-live require a configuration update.]
4. [Add assumptions surfaced during spec generation]

---

## Definition of Done

> _Checklist. All items must be checked before this spec is marked `approved` and advanced to Stage 3._

- [ ] All open items in this document are resolved
- [ ] Required credentials and API access confirmed and provisioned to sandbox
- [ ] Translation table / field mapping configuration complete and reviewed
- [ ] Three test scenarios pass in non-production environment: [list scenarios specific to this integration]
- [ ] Error scenarios (Category A, B, C) all produce correct notifications in non-production
- [ ] Product owner has reviewed Areas of Concern and each one has a named resolution or accepted risk

---

## Costs and Ownership

> _Monthly cloud infrastructure estimate and warranty scope._

**Estimated monthly cloud infrastructure cost:** [$ range] / month

| Component | Estimated cost |
|-----------|---------------|
| [Lambda / Function invocations] | $[x]/month |
| [SQS / Service Bus messages] | $[x]/month |
| [Secrets Manager] | $[x]/month |
| [CloudWatch / Monitor logs] | $[x]/month |
| **Total estimate** | **$[range]/month** |

**Ownership:** Client provisions and pays for all infrastructure.

**Code warranty:** Implementation vendor covers defects in its own code for 10 business days after go-live. Infrastructure failures, third-party API changes, and data quality issues are outside warranty scope.

---

## Omissions

> _Explicitly NOT in scope for this spec. Numbered list._

1. [e.g., [System] → [system] leg — owned by [team] under a separate workstream]
2. [e.g., Historical data migration — separate project]
3. [e.g., User provisioning and SSO]
4. [e.g., Bidirectional field updates after initial record creation]
5. [e.g., Performance SLAs beyond those stated in Definition of Done]
6. [e.g., Disaster recovery beyond standard cloud provider guarantees]

---

## Open Items

> _Carried from intent.md Open Questions, plus any new items surfaced during spec generation. All must be resolved before status advances to `approved`._

| # | Item | Who can answer | Needed by | Status |
|---|------|---------------|-----------|--------|
| 1 | [Carried from intent Open Question 1] | [Owner from intent] | [Date] | Open |
| [Add rows — number continues from intent's last question for new spec-surfaced items] | | | | |

---

## Decision Record

> _Decisions made during spec generation that constrain the design. Add decisions as they are made during review._

| Decision | Rationale | Date | Owner |
|----------|-----------|------|-------|
| [e.g., Implementation vendor scope ends at [system] boundary] | [Reason] | [Date] | [Role] |

---

## Areas of Concern

> _Flagged by policy review. Product owner resolves each one with the named policy owner before engineering sees the spec._

| # | Concern | Policy / Gap | Owner | Resolution Status |
|---|---------|-------------|-------|------------------|
| 1 | [Description of concern] | [Which policy is violated or which gap triggered it] | [Named owner] | Open |

---

## Related Documents

| Document | Location | Notes |
|----------|----------|-------|
| Source intent document | `intent/[same-kebab-name].md` | Input to this spec |
| Google Doc version | [TO CONFIRM: filled in by /create-spec after Doc is created] | Stakeholder-facing copy |
| Field mapping workbook | [link or path — to be created] | Downstream from this spec |
| Source system API documentation | [link — to be provided] | Required before build |
| Target system API documentation | [link — to be provided] | Required before build |
