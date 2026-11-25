<!--
title:
version: 0.1
status: draft
author:
date:
reviewers:
supersedes:
-->

# Intent: [Short Title]

---

## Problem Statement

> _What cannot be done today, and who is experiencing the friction?_

[Describe the current situation in plain language. Focus on the gap between what should be possible and what is. Avoid solution language here.]

### Affected Roles

| Role | How they are currently blocked |
|------|-------------------------------|
| e.g., Sales Representative | Cannot see real-time record status after a deal closes |
| e.g., Operations Manager | Must manually reconcile data between two systems each week |

---

## Proposed Outcome

> _What does success look like to someone who is not technical?_

[Describe the future state in one to three plain-language paragraphs. If possible, write a "day in the life" story for one of the affected roles after this is built. Avoid implementation details.]

---

## Systems Involved

> _List every system touched by this effort. Then explicitly state what is in scope and what is not._

| System | Role in this effort | Owned by |
|--------|---------------------|----------|
| [Source System] | Authoritative record of [entity] | [team or vendor] |
| [Target System] | Destination for [data or action] | [team or vendor] |

### Scope Boundary

**This effort covers:**
- [e.g., syncing Contact records from the source system to the target CRM on record creation]
- [e.g., mapping fields as defined in the Integration Specifics section]

**This effort does NOT cover:**
- [e.g., the downstream ERP connection — handled by a separate internal team engagement]
- [e.g., historical data migration — separate project]
- [e.g., user provisioning and SSO — handled by IT]

---

## Integration Specifics

> _Complete this section for integration and data-sync efforts. Remove this section for new features, operational changes, or incident responses._

### Data Flow Direction

- [ ] Inbound (external system sends data to our system)
- [ ] Outbound (our system sends data to external system)
- [ ] Bidirectional
- [ ] Fan-out (one source to multiple targets)

### Trigger Type

- [ ] Event-driven (record created / updated / deleted triggers immediate sync)
- [ ] Scheduled batch (runs every ___ minutes / hours / days)
- [ ] Manual / on-demand (user-initiated action)
- [ ] Hybrid — describe: ___

### Primary Data Entities

| Entity | Direction | Authoritative Source | Notes |
|--------|-----------|---------------------|-------|
| e.g., Contact | Bidirectional | Source system | CRM is read-only for phone number |
| e.g., Deal | Outbound only | Target CRM | |

### Field Ownership on Conflict

> _When both systems hold the same field and they disagree, which system wins?_

[e.g., "Email address is authoritative in the source system. If the CRM holds a different value, it is overwritten on next sync."]

[If it varies by field, list each field and its owner here.]

### Approval and Workflow Gates

[Describe any human approval steps or business rules that must pass before data moves. e.g., "A deal must reach the 'Closed Won' stage before its record is transmitted to the downstream system."]

---

## Constraints

### Technical
- [e.g., source system exposes a REST API only — no direct database access]
- [e.g., API rate limit: 100 requests per 10 seconds]
- [e.g., must run within the organization's approved cloud environment]

### Business
- [e.g., personal data may not be stored outside the approved region]
- [e.g., changes above a defined threshold require change-control approval]

### Organizational
- [e.g., a third-party vendor owns the target system; the integration must use their published API]
- [e.g., internal IT handles all credential and secrets provisioning]

### Timeline
- Target completion: ___
- Hard deadline (if any): ___ — reason: ___
- Known blackout periods: ___

---

## Open Questions

> _Every unresolved item that must be answered before design can begin. This section should be empty before status is updated to `committed`._

| # | Question | Who can answer | Needed by | Status |
|---|----------|---------------|-----------|--------|
| 1 | Which cloud platform will host the integration runtime? | [Engineering Lead] | [date] | Open |
| 2 | What authentication method does the source system support? | [Vendor / IT] | [date] | Open |
| 3 | When both systems have conflicting values for the same field, which one wins? | [Business Owner] | [date] | Open |
| 4 | Does this effort require a compliance or data-residency review? | [Legal / Compliance] | [date] | Open |

---

## Success Criteria

### Leading Indicators _(measurable before full delivery)_
- [ ] All open questions in the table above are resolved
- [ ] Affected roles have reviewed and confirmed the Proposed Outcome
- [ ] Scope boundary has been acknowledged in writing by the relevant stakeholders
- [ ] [add project-specific criteria]

### Lagging Indicators _(measurable after go-live)_
- [ ] [Affected role] can perform [task] without [current friction]
- [ ] Error or exception rate for [data entity] sync is below [threshold]
- [ ] [add project-specific criteria]

### Module 1 Process Metrics
- Time from first conversation to committed intent.md: ___
- Number of review cycles before sign-off: ___

---

## Related Documents

| Document | Location | Notes |
|----------|----------|-------|
| [Field mapping / configuration workbook] | [link or path] | Downstream from this doc |
| [Prior version of this intent] | [link or path] | Superseded by this file |
| [Vendor or system API documentation] | [link or path] | Reference only |
