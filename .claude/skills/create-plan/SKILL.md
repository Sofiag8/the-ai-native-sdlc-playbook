---
name: create-plan
description: >
  Use this skill at the start of a build session to turn an approved spec.md
  into a phased implementation plan that engineers can build against. Trigger
  when an engineer says "create a plan for this spec", "let's plan the
  implementation", "plan mode for this feature", or opens a session with a
  spec.md attached and asks how to implement it. Invoke with /create-plan
  followed by the spec path, e.g. /create-plan spec/crm-to-practice-management-sync.md.
  This skill runs in plan mode — it reads files and interviews the engineer
  before writing anything. Do not trigger when the engineer is already
  implementing or when they are asking about an existing plan.
argument-hint: "[path to spec file, e.g. spec/my-project.md]"
---

# create-plan skill

You are producing a phased implementation plan (`plan.md`) from an approved `spec.md`. This skill **runs in plan mode** — you read files and interview the engineer before writing anything. Do not write any files until Phase 6 (after ExitPlanMode approval).

---

## Core rules (apply throughout)

- **Plan mode only.** Do not create or modify any files until Phase 6. All work before that is reading and reasoning.
- **One question per turn** during the interview phase (Phase 4). Do not front-load multiple questions.
- **Never fabricate.** If the codebase cannot be read or does not exist yet, note which files need to be created and in what order. Use `[TBD]` for values that must be confirmed.
- **Detail threshold.** The plan must be specific enough that an engineer who has never seen this conversation could implement the change from the plan alone — exact file names, function names, task steps, and verification criteria.
- **Carry open items forward.** Every Open Item from the spec must appear in the plan's Open Items table. Add new plan-surfaced items numbered after the last spec item.
- **Neutralize names.** If the spec contains any real client, company, person, or system names, replace them with neutral labels in the plan.

---

## Phase 0 — Identify the spec file

Check whether a spec file path was provided as an argument.

**If a path was provided:** Read the file at that path and proceed to Phase 1.

**If no path was provided:** List the files in `spec/`. Present them and ask:
> "Which spec should I build a plan from? Name the file or paste the path."

Wait for the response, then read the file and proceed.

---

## Phase 1 — Read the spec and intent

Read the spec file fully. Extract:
- Overview and scope boundary
- Systems involved (names, auth methods, trigger types)
- Infrastructure components (Lambda, SQS, etc.)
- Proposed data flow — every step, both directions
- Field mapping and transformation rules
- Error handling scenarios (Category A, B, C)
- Responsibilities table (vendor vs. client tasks)
- Open items and Areas of Concern
- Definition of Done test scenarios

Also read the matching intent file if it exists at `intent/<same-name>.md`. Extract any additional context, constraints, or timeline requirements.

---

## Phase 2 — Read the codebase

Use Glob and Read to find files in the repository that will be touched based on the systems named in the spec. Look for:
- Existing Lambda handlers or similar entry points
- Configuration files (translation tables, environment configs)
- Test files and testing patterns
- Deployment scripts or infrastructure-as-code
- Any existing integrations with the same systems

If no relevant files exist yet, note the files that will need to be created and in what order. This shapes Phase 0 of the plan.

---

## Phase 3 — Draft the plan

Read the template from:

```
${CLAUDE_SKILL_DIR}/plan-template.md
```

Fill in every section using the spec (Phase 1) and codebase context (Phase 2).

**Rules for each section:**

- **Metadata comment block:** Set `spec-ref` and `intent-ref` to the paths of the source files. Set `status: draft`. Set `date` to today. Set `source-of-truth: repo` unless the engineer specifies otherwise.
- **Summary:** One paragraph. Plain language. What is being built, the trigger, and the outcome.
- **Status table:** All phases start as `Not started`. Do not pre-fill completion dates.
- **Files That Change:** List every file that will be created, modified, or deleted. Group by phase. If files are not known yet, write `[TBD — pending Phase 2 codebase read]`.
- **Phase 0:** List every prerequisite that must be true before code is written — AWS access, sandbox credentials, data warehouse interface spec, translation table, etc. Cross-reference responsibilities from the spec.
- **Phases 1–N:** Derive one phase per major workstream from the spec's Proposed Flow sections. Each phase gets: scope description, numbered tasks, verification steps, and open item cross-references.
- **Testing & UAT:** Create one subsection per Definition of Done scenario from the spec. Include: what to verify, expected behavior, and blank rows for actual result and any bugs found.
- **Deployment — Sandbox:** Step-by-step deployment checklist for the non-production environment. Reference specific AWS components and configuration items.
- **Deployment — Production:** Go/no-go checklist, cutover steps, rollback plan, and 48-hour monitoring window.
- **Risks:** Carry risks from the spec's Areas of Concern plus any implementation-specific risks identified during codebase reading.
- **Architecture Decisions:** Document every significant technical choice made during planning — cloud platform, trigger mechanism, state management approach.
- **Open Items:** Carry all spec Open Items. Add any plan-surfaced items numbered sequentially after.
- **Confirmed References:** Leave blank for the engineer to fill in when they verify live API endpoints, field names, and object IDs against the actual systems.
- **Source of Truth Linkage:** Record which system is authoritative for this plan. Default `repo`. Cross-reference any linked ticket or issue numbers.

Do not present the full plan to the user yet — proceed directly to Phase 4.

---

## Phase 4 — Interview the engineer

Present the draft plan summary (phases and open items only — not the full text) and ask the following three questions **one at a time**. Wait for a response before asking the next one.

**Question 1:**
> "What could this change break that isn't already covered in the Risks section?"

Incorporate the answer into the Risks table before asking Question 2.

**Question 2:**
> "Which phase or step feels most uncertain to you — where would you want to pause and verify before continuing?"

Incorporate the answer (add verification gates or update phase scope) before asking Question 3.

**Question 3:**
> "Is there anything in the approach I've proposed that you'd do differently?"

Incorporate the answer. If the engineer's preference changes architecture, update the Architecture Decisions table with the rationale.

After all three answers are incorporated, present the updated plan and ask:
> "Does this plan capture what you want to build? Say 'looks good' or tell me what to adjust."

Iterate until the engineer confirms the plan is ready.

---

## Phase 5 — Request approval

Call `ExitPlanMode` to present the final plan for user approval. Do not write any files before this call completes and the user approves.

---

## Phase 6 — Save the plan file

After approval, save the plan to: `plan/<same-kebab-name-as-spec>.md`

For example: if the spec was `spec/crm-to-practice-management-sync.md`, save to `plan/crm-to-practice-management-sync.md`.

---

## Phase 7 — Confirm and next steps

Confirm with:

> "Saved to `plan/<name>.md`. This plan joins the audit trail alongside the intent and spec.
>
> As you implement: update `plan.md` in the same commit if implementation departs from it. The plan is the record of intent — the diff between plan and code is the record of what changed and why."

If the file could not be saved:
> "I could not save the file automatically. Copy the content above into a new file at `plan/<name>.md` in this repository."
