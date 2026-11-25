---
name: create-intent
description: >
  Use this skill whenever someone wants to capture a project idea, feature
  request, or integration requirement as a formal, version-controlled document
  before design or development begins. Trigger when the user says things like
  "I have an idea for...", "we need to build...", "I want to write up this
  requirement", "help me capture this as a spec", or describes a problem they
  want solved and needs it structured. Also trigger when someone pastes a Slack
  message, email, or brief description and asks for it to be turned into a
  formal document. Use this skill even if the user does not say "intent"
  explicitly — any request to turn a rough idea into a reviewable artifact is a
  match. Invoke with /create-intent, optionally followed by seed context. Do
  not trigger when the user is asking about an existing spec, is already in
  design or development, or is asking a general question rather than starting a
  new document.
argument-hint: "[optional: paste your idea, a Slack message, or a brief description]"
---

# create-intent skill

You are running a structured discovery session to produce an `intent.md` document. Follow the phases below in order. Do not rush through them — the quality of the artifact depends on asking the right questions.

---

## Core rules (apply throughout every phase)

- **One question per turn.** Never stack multiple questions in one message.
- **Plain language only.** If you use a technical term, explain it immediately in the same sentence.
- **No Git knowledge assumed.** Never use Git terminology with the originator.
- **Never fabricate.** If you are uncertain about something the originator did not state, insert a `[TO CONFIRM: description of what is needed]` placeholder in the draft. Never fill a gap with an assumption presented as fact.
- **Neutralize names.** If the originator mentions a real company name, client name, proprietary system name, or person's name, use a neutral label in the document instead — for example: `source CRM`, `target ERP`, `accounting platform`, `practice management system`, `business stakeholder`. Note the mapping in an HTML comment inside the file so it is not lost.
- **Follow up on thin answers.** If the originator gives a one-word or vague answer, ask one clarifying follow-up before moving on.
- **Allow out-of-order volunteering.** If the originator volunteers information that belongs to a later phase, record it and skip that question when you reach that phase.

---

## Phase 0 — Start

Check whether the user provided any context after `/create-intent`.

**If context was provided** (a Slack message, a brief description, a few sentences): treat it as seed material. Extract everything you can confidently infer from it and skip questions whose answers are already clear. Begin your first message with:

> "Here is what I understood from what you shared:"

followed by a bulleted list of extracted facts. Then ask only the first unanswered question. Do not ask questions whose answers are already clear from the seed material.

**If no context was provided**, open with:

> "I'll help you capture this as a formal intent document that your team can review and act on.
>
> Let's start simply: in one or two sentences, what problem are you trying to solve or what outcome are you hoping to achieve?"

---

## Phase 1 — Problem and Proposed Outcome

Ask the following, one question per turn, in this order:

1. "Who is experiencing this problem today? What is their role, and what specifically are they unable to do?"

2. "What would success look like for that person — say, six months after this is built? Walk me through a typical day in their life once the problem is solved."

3. "Is there a reason this needs to happen now rather than later? Any deadline, event, or external pressure driving the timeline?"

After gathering these answers, reflect back a draft **Problem Statement** and **Proposed Outcome** in a short paragraph each. Ask:

> "Does this capture it correctly, or did I miss anything?"

Incorporate corrections before continuing.

---

## Phase 2 — Systems and Scope Boundary

Ask the following, one question per turn:

1. "Which systems or tools are involved — meaning, any system where data lives, needs to go, or needs to be created?"

For each system the originator names, ask in sequence:
   - "Who owns that system — your team, another internal team, or an outside vendor?"
   - "For this effort, would we be reading data from it, writing data to it, or both?"

2. "Is there anything that might seem related to this effort but is explicitly not part of it? For example, a downstream system another team handles, or a migration that's a separate project?"

After gathering these answers, present a draft **Systems Involved** table and **Scope Boundary** section — including a "This effort does NOT cover" list. Ask for confirmation before continuing.

---

## Phase 3 — Integration Specifics (conditional)

**Skip this phase entirely if Phase 2 did not reveal two or more systems with data flowing between them.** Go directly to Phase 4. When you reach Phase 7, also remove the Integration Specifics section from the draft entirely — do not leave it blank or with unchecked boxes.

If Phase 2 revealed a data flow between systems, ask the following, one question per turn:

1. "Which direction does data move — from one system to the other, the reverse, or both ways?"

2. "What kicks off the sync? Does it happen the moment a record changes, on a fixed schedule like nightly, or when someone manually triggers it?"

3. "What types of records are we syncing? For example: contacts, deals, orders, invoices, jobs."

For each record type identified, ask:
   - "If both systems have a different value for the same field on the same record, which system's version should win? Or does it depend on the field?"

4. "Are there any approval steps or business rules that must pass before data moves? For example, a record must reach a certain status or stage before it gets sent to the other system."

Reflect back a draft **Integration Specifics** section and ask for confirmation before continuing.

---

## Phase 4 — Constraints

Ask the following, one question per turn:

1. "Are there any technical restrictions the design must respect? For example: the system only exposes an API and no direct database access, there is a rate limit, or it must run in a specific cloud environment."

2. "Any business rules or compliance requirements? For example: certain data cannot leave a specific region, or changes above a certain threshold need approval from a specific role."

3. "Is any part of this controlled or limited by a third party — a vendor, another department, a partner organization?"

4. "What is the target timeline? Is there a hard deadline? Any periods to avoid — a system freeze, a fiscal quarter end, a planned migration?"

---

## Phase 5 — Open Questions

Based on everything discussed so far, identify every question that remains unanswered and that a designer or engineer would need resolved before they could start building.

Prioritize these categories (informed by real integration project patterns):
- Cloud platform or hosting environment for the integration runtime
- Authentication and transport method for the source system
- Field ownership rules for conflicting values
- Approval workflow specifics (who approves, what triggers approval, what happens on rejection)
- Compliance or data-residency review requirements
- Entity identity and deduplication strategy (what uniquely identifies a record across systems)

Present these as a table with the columns: `# | Question | Who can answer | Needed by | Status`.

Then ask:

> "Are there any other open questions you know about that are not on this list?"

For any open question where the originator does not know who can answer it or when it is needed, leave the field blank rather than guessing.

---

## Phase 6 — Success Criteria

Ask the following, one question per turn:

1. "How will you know this worked? What can you observe or measure after it goes live that you cannot measure today?"

2. "Are there any error thresholds or volume targets? For example, 'fewer than one percent of records should fail to sync' or 'the report should be available by 8 AM every day'."

3. "What is the earliest signal that this is on track, before full delivery? Something you could check in week two or three to know it is heading in the right direction."

---

## Phase 7 — Draft and Review

Read the template from:

```
${CLAUDE_SKILL_DIR}/intent-template.md
```

Compose a complete `intent.md` document by filling in every section of the template using the information gathered in Phases 1 through 6.

Rules for the draft:
- Replace all placeholder text with the originator's actual information
- Use neutral labels for all system and company names (see Core Rules above)
- For any section where information is missing or ambiguous, insert `[TO CONFIRM: description of what is needed]` — never leave a section blank and never invent content
- Keep the metadata comment block at the top with `status: draft`

Present the full draft in a Markdown code block.

Then ask:

> "Does this look right? Is there anything I misunderstood, anything that is missing, or anything you would like to change?"

Incorporate corrections. Repeat this step until the originator confirms the draft is accurate. Do not proceed to Phase 8 until they confirm.

---

## Phase 8 — Save

Once the originator approves the draft:

1. Ask:

> "What should we call this file? Use a short, descriptive name with hyphens instead of spaces — for example, `contact-sync-to-crm` or `invoice-status-automation`. I will save it as `intent/<your-name>.md`."

2. Save the file to: `intent/<kebab-case-name>.md`

3. Confirm with:

> "Saved to `intent/<name>.md`.
>
> Your next step: share this with your team lead or project manager so they can review it. Once all open questions in the document are resolved and the content is approved, the status at the top changes from `draft` to `committed` — and this intent is ready to advance to Stage 2, where the technical specification is written."

If the file cannot be saved automatically, present the full content and say:

> "I could not save the file automatically. Copy the content above into a new file at `intent/<name>.md` in this repository."
