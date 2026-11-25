<!--
title: New Engagement Onboarding Automation
version: 0.1
status: draft
author: Engagement Manager, Business Development
date: 2026-11-24
supersedes:
-->

# Intent: New Engagement Onboarding Automation

---

## Problem Statement

> _What cannot be done today, and who is experiencing the friction?_

The firm's CRM platform is used by business development staff to manage prospects and track deals through close. When a deal reaches Closed Won, nothing happens automatically. An administrative coordinator receives a notification and spends 30–45 minutes manually re-entering the same information — client details, contacts, and engagement parameters — into the firm's practice management system before billable work can begin.

This process is error-prone, depends on a single person being available, and creates a 1–2 business-day delay before the new engagement appears in the scheduling and billing system. During that window, project managers cannot assign staff, billing cannot set up invoicing, and partners have no confirmation that the client record exists in the system of record.

The firm has grown its CRM usage significantly over the past two years — from marketing only to firmwide business development — and the volume of closed deals has outpaced what manual coordination can absorb without risk of error or delay.

### Affected Roles

| Role | How they are currently blocked |
|------|-------------------------------|
| Administrative Coordinator | Spends 30–45 minutes per closed deal on manual re-entry; responsible for catching and correcting errors between two systems |
| Engagement Partner | Cannot confirm practice management setup until 1–2 days after close; sometimes learns of data errors from the new client |
| Billing Manager | Sees new engagements 1–2 days late; initial invoicing and billing rate configuration is delayed |
| Business Development Representative | Receives no confirmation that the downstream system was updated; must follow up manually with the coordinator |
| Project Manager | Cannot assign staff or begin scheduling until the engagement record exists in the practice management system |

---

## Proposed Outcome

> _What does success looks like to someone who is not technical?_

When a deal is marked Closed Won in the CRM — after all required information has been reviewed and confirmed in the deal record — the client record, associated contacts, and engagement record are automatically created in the practice management system within minutes. No one has to do anything.

The CRM deal record updates to display the practice management client number and engagement ID, so everyone involved can see that the downstream setup completed successfully. If the new client requires committee approval before their record becomes active, the deal record reflects that status too — "Pending Committee Review" — and updates automatically once approval is granted.

The administrative coordinator's role shifts from data entry to exception handling. If a sync fails — for example, because a required field was left blank or the engagement type could not be matched — the coordinator receives a notification with enough context to resolve it without having to decode a technical error. For the first time, they can trust that the data in both systems matches without manually checking.

For partners and project managers, the engagement is visible and schedulable on the same day the deal closes. For billing, invoicing setup begins within hours rather than days.

---

## Systems Involved

> _List every system touched by this effort. Then explicitly state what is in scope and what is not._

| System | Role in this effort | Owned by |
|--------|---------------------|----------|
| CRM platform | Authoritative source for deal, client contact, and engagement parameters at time of close | Implementation vendor (configuration); firm (data) |
| Internal data warehouse | Intermediary — receives outbound payload from CRM and routes to practice management; sends return confirmation back to CRM | Firm's internal IT team |
| Practice management system | Destination for client, contact, and engagement records; assigns client number and engagement ID after record creation | Firm's operations team (via third-party practice management vendor API) |

### Scope Boundary

**This effort covers:**
- Outbound: CRM → data warehouse (payload sent when a deal stage changes to Closed Won and all required fields pass a completeness check)
- Inbound: data warehouse → CRM (practice management client number and engagement ID written back to the CRM deal record and company record once the practice management system confirms record creation)
- Error notification to the administrative coordinator when a sync fails, with enough context to identify the cause

**This effort does NOT cover:**
- Data warehouse → practice management system: this leg is built and owned by the firm's internal IT team under a separate workstream; this effort ends at the data warehouse boundary
- Historical migration of existing clients or past engagements
- Bidirectional field updates after the initial record is created (the return sync is for identifiers only, not ongoing changes)
- User provisioning, role configuration, or SSO in either system
- Reporting or dashboard configuration in the practice management system
- Any deal pipeline stage other than Closed Won

---

## Integration Specifics

> _Complete this section for integration and data-sync efforts._

### Data Flow Direction

- [x] Bidirectional
  - Outbound: CRM → data warehouse (triggered on deal close)
  - Inbound: data warehouse → CRM (triggered on practice management confirmation)

### Trigger Type

- [x] Hybrid — describe: Outbound is event-driven (deal stage change to Closed Won, plus completeness check). Inbound is event-driven (the data warehouse fires a callback to the CRM once practice management confirms the records were created). There is no scheduled batch component in this scope.

### Primary Data Entities

| Entity | Direction | Authoritative Source | Notes |
|--------|-----------|---------------------|-------|
| Company / Client record | Outbound | CRM at time of send; practice management after client number is assigned | Practice management client number must not be overwritten by CRM after assignment |
| Primary Contact | Outbound | CRM | Name and email authoritative in CRM |
| Billing Contact | Outbound | CRM | May be the same person as Primary Contact; must be sent as a distinct role |
| Engagement / Job record | Outbound | CRM at time of send; practice management after engagement number is assigned | Engagement type in CRM is a single field; practice management requires a composite key (service line + engagement type) — see Constraints |
| Client number (identifier) | Inbound | Practice management system | Written back to CRM company record after assignment |
| Engagement number (identifier) | Inbound | Practice management system | Written back to CRM deal record after assignment |
| Approval status | Inbound | Practice management system | "Pending Committee Review" or "Active"; written to CRM deal record |

### Field Ownership on Conflict

The CRM is authoritative for all fields at the time the outbound payload is sent. The integration does not update CRM fields from practice management data except for the three identifiers listed in the inbound row above (client number, engagement number, approval status). Any discrepancy in name, address, or engagement parameters after go-live is resolved manually — the integration does not perform ongoing field reconciliation.

### Approval and Workflow Gates

New clients require committee approval inside the practice management system before their client record becomes active. The integration must:
1. Send the outbound payload regardless of whether committee approval is required
2. Write "Pending Committee Review" to the CRM deal record immediately after the payload is accepted
3. Update the CRM deal record to "Active" when the data warehouse receives confirmation that committee approval was granted

Existing clients — those already in the practice management system — skip committee review. The integration must detect whether a matching client record exists before creating a new one, to avoid duplicate records and unnecessary committee reviews.

Deals above a defined contract value threshold require a second-level review. It is currently unconfirmed whether this review gate is enforced before the outbound payload is sent (CRM side) or inside the practice management system after the payload is received. See Open Questions.

---

## Constraints

### Technical
- The practice management system exposes a REST API only; no direct database access is available
- API rate limits for the practice management system have not yet been confirmed by the vendor
- Engagement type in the CRM is a single dropdown field; the practice management system requires a composite key (service line + engagement type). A translation table must be maintained as configuration outside the core integration code. Any new engagement type requires a configuration update before it can be synced
- The data warehouse interface specification — the exact format, field names, and authentication method the data warehouse expects — is owned by the firm's internal IT team and has not yet been shared

### Business
- Client data may not be stored or processed outside the firm's approved cloud region
- The integration must not create duplicate client records in the practice management system; detection of an existing client must happen before any write operation

### Organizational
- The firm's internal IT team owns the data warehouse → practice management leg; the implementation vendor's scope ends at the data warehouse boundary. Changes to the data warehouse interface require coordination with the internal IT team, not the implementation vendor
- The practice management vendor must approve any new API consumer before credentials are issued; this process typically takes 2–3 weeks from the time the request is submitted
- Internal IT handles all credential and secrets provisioning for the integration runtime

### Timeline
- Target completion: before fiscal year end
- Hard deadline: the firm enters a system freeze for the last two weeks of the fiscal year — no new deployments during that period
- Known blackout periods: fiscal year-end freeze (exact dates to be confirmed with IT)

---

## Open Questions

> _Every unresolved item that must be answered before design can begin. This section should be empty before status is updated to `committed`._

| # | Question | Who can answer | Needed by | Status |
|---|----------|---------------|-----------|--------|
| 1 | How does the integration identify whether a client already exists in the practice management system — by company name, tax ID, or another unique identifier? What is the match confidence threshold? | Operations Lead / Practice Management Vendor | Before design begins | Open |
| 2 | What authentication method does the practice management API use — API key, OAuth 2.0, mutual TLS, or other? | Practice Management Vendor / IT | Before design begins | Open |
| 3 | Which cloud platform will host the integration runtime between the CRM and the data warehouse? | Engineering Lead / IT | Before design begins | Open |
| 4 | What fields make up the composite key for engagement type in the practice management system — specifically, is "service line" a separate field or embedded in the engagement type value? Is the full mapping table already documented anywhere? | Operations / Practice Management Admin | Before design begins | Open |
| 5 | For the committee approval gate: does the CRM need to surface approval status in real time (minutes), or is an end-of-day batch update from the data warehouse sufficient? | Billing Manager / Engagement Partner | Before build of return sync | Open |
| 6 | What should happen if the outbound payload is sent for a client who already has an active record in the practice management system but the duplicate-detection logic did not catch the match? Should the integration update the existing record, reject the payload, or notify a human? | Operations Lead | Before build of outbound | Open |
| 7 | Is there a maximum number of contacts that can be associated with a single client record in the practice management system? | Practice Management Admin | Before build of contact sync | Open |
| 8 | Does the second-level review requirement for high-value deals apply before the outbound payload is sent (enforced by the CRM) or after receipt inside the practice management system? Who defines the contract value threshold? | Managing Partner / Compliance | Before build of outbound gate | Open |

---

## Success Criteria

### Leading Indicators _(measurable before full delivery)_
- [ ] All 8 open questions above are resolved and recorded in this document
- [ ] The firm's internal IT team and implementation vendor have jointly signed off on the scope boundary diagram (specifically: what the data warehouse expects and what the implementation vendor delivers to it)
- [ ] Practice management vendor has issued API credentials to the integration runtime environment
- [ ] The composite key translation table (engagement type → service line + engagement type) is complete and covers all active engagement types in the CRM
- [ ] Three test scenarios pass in a non-production environment: new client, existing client (duplicate detection), and new client requiring committee approval

### Lagging Indicators _(measurable after go-live)_
- [ ] Administrative coordinator records zero manual data-entry hours for standard Closed Won deals after go-live
- [ ] CRM deal records display the practice management client number and engagement ID within 5 minutes of a successful downstream setup
- [ ] Error or sync failure rate is below 2% of Closed Won deals per month (excluding deals with intentionally incomplete required fields)
- [ ] Zero duplicate client records created in the practice management system as a result of this integration in the first 90 days

### Module 1 Process Metrics
- Time from first conversation to committed intent.md: _[to record after commit]_
- Number of review cycles before sign-off: _[to record after sign-off]_

---

## Related Documents

| Document | Location | Notes |
|----------|----------|-------|
| CRM field mapping / configuration workbook | To be created in Stage 2 — Specification | Downstream from this document |
| Practice management API documentation | To be provided by vendor — not yet received | Required before design begins |
| Data warehouse interface specification | Owned by firm's internal IT team — to be requested | Required before design begins; defines the exact payload format and auth method |
| Composite key translation table (engagement type) | To be created before build begins | Maintenance responsibility to be agreed with Operations |
