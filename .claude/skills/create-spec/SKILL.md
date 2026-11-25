---
name: create-spec
description: >
  Use this skill whenever a product owner or technical lead wants to turn an
  approved intent.md into a full Integration Requirements Document (spec.md)
  ready for engineering review. Trigger when someone says "generate a spec from
  this intent", "produce the IRD for...", "write the spec for...", "create-spec
  for...", or attaches an intent.md and asks for a spec, requirements document,
  or IRD. Also trigger when someone says "take this intent and make it into
  something engineering can build against." Invoke with /create-spec followed
  by the path to the intent file. Do not trigger when the user is asking about
  an existing spec, is already in build or development, or is asking a general
  question rather than producing a new document.
argument-hint: "[path to intent file, e.g. intent/crm-to-practice-management-sync.md]"
---

# create-spec skill

You are producing a formal Integration Requirements Document (spec.md) from an approved intent.md. This is a **single-pass skill** — you generate the full spec in one turn, without asking clarifying questions. Use `[TO CONFIRM: description]` for every gap, and flag policy violations or design risks as Areas of Concern.

---

## Core rules (apply throughout)

- **Single-pass.** Do not ask the user questions during generation. Flag gaps as `[TO CONFIRM: ...]` and add them to Open Items or Areas of Concern.
- **Never fabricate.** If information is not in the intent, use `[TO CONFIRM: description of what is needed]`. Never invent field names, system behaviors, or cost figures beyond reasonable estimates.
- **Neutralize names.** If the intent mentions real company names, client names, proprietary system names, or person names, use neutral labels in the spec — e.g., `source CRM`, `target practice management system`, `intermediary data warehouse`, `engagement partner`. Note the mapping in an HTML comment inside the file.
- **Carry forward.** Every Open Question from the intent must appear in the spec's Open Items section. Add new items for gaps the spec surfaces.
- **Every concern names an owner.** Every row in Areas of Concern must name the person or role responsible for resolving it.
- **Responsibilities are exhaustive.** Every task in the spec must be assigned to either the implementation vendor or the client in the Responsibilities table. Nothing left unassigned.

---

## Phase 0 — Identify the intent file

Check whether an intent file path was provided as an argument.

**If a path was provided:** Read the file at that path and proceed to Phase 1.

**If no path was provided:** List the files in `intent/`. Present them and ask:
> "Which intent document should I generate a spec from? Name the file or paste the path."

Wait for the response, then read the file and proceed.

---

## Phase 1 — Read the intent

Read the intent file fully. Extract:
- Problem statement and affected roles
- Proposed outcome
- Systems involved and scope boundary
- Integration specifics (direction, trigger, entities, field ownership, workflow gates)
- Constraints (technical, business, organizational, timeline)
- Open questions (carry all of these forward)
- Success criteria

---

## Phase 2 — Load and apply policies

Read each of the following policy files:

```
${CLAUDE_SKILL_DIR}/../policies/integration-security.md
${CLAUDE_SKILL_DIR}/../policies/integration-standards.md
${CLAUDE_SKILL_DIR}/../policies/infrastructure-ownership.md
```

For each policy, note the concern triggers. You will apply these as you fill in each section of the spec. Do not surface concerns until Phase 3 — collect them as you go and write them all into the Areas of Concern section at the end.

---

## Phase 3 — Generate the spec

Read the template from:

```
${CLAUDE_SKILL_DIR}/spec-template.md
```

Fill in every section of the template using the information from the intent (Phase 1) and the policy constraints (Phase 2).

**Rules for each section:**

- **Metadata comment block:** Set `intent-ref` to the path of the source intent file. Set `status: draft`. Set `date` to today. Leave `google-doc-url` blank — it will be filled in Phase 5.
- **Overview:** Write one plain-language paragraph. No jargon. A business stakeholder should be able to understand it.
- **Important Definitions:** Include every system and every business term used in the spec.
- **Scope Boundary:** Carry directly from intent. Add any technical clarifications the spec requires.
- **Infrastructure & Ownership:** Apply the `infrastructure-ownership` policy. If the cloud platform is unconfirmed, state "AWS (assumed — see Open Items)" and add an open item.
- **Proposed Flow:** Write numbered steps for every direction. If a step involves a system not in scope (e.g., a downstream leg owned by another team), note it as a boundary: "This step is out of scope — owned by [team]."
- **Source System Integration Points:** Apply `integration-security` policy on auth method. Flag unconfirmed auth methods as open items and add to Areas of Concern.
- **Volume:** Use estimates from the intent where available. If none, write `[TO CONFIRM: estimated volume not provided in intent]`.
- **Data Transformation:** Build the field mapping table from the entities and fields in the intent. Mark PII fields per `integration-security` policy. If engagement type requires a composite key (or similar mapping), note the translation table requirement and flag the maintenance owner as a concern if undefined.
- **Source of Truth:** Apply the field ownership rules from the intent.
- **Error Handling & Exception Playbook:** Apply `integration-standards` policy. Write at minimum the six required scenarios. Add integration-specific scenarios from the intent.
- **Responsibilities:** Assign every task. Apply `infrastructure-ownership` policy defaults.
- **Assumptions and Limitations:** Include every assumption made during spec generation due to unconfirmed information.
- **Definition of Done:** Include three integration-specific test scenarios based on the integration's unique conditions (e.g., new record, existing record for deduplication, workflow gate scenario).
- **Costs and Ownership:** Apply `infrastructure-ownership` policy. Estimate costs based on the cloud platform and components described.
- **Omissions:** Carry from intent and add any additional exclusions the spec requires.
- **Open Items:** Carry all Open Questions from the intent (renumbered starting from 1). Add new items surfaced during spec generation, numbered sequentially after the last carried item.
- **Decision Record:** Add any decisions made during spec generation (e.g., "Assumed AWS as cloud platform per infrastructure-ownership policy default").
- **Areas of Concern:** Collect all concerns flagged during Phases 2 and 3. Write one row per concern with: description, which policy or gap triggered it, named owner, and status = Open.

Present the full spec in a Markdown code block and ask:

> "Does this look right? Is there anything I misunderstood, anything that is missing, or anything you would like to change?"

Incorporate any corrections. Do not proceed to Phase 4 until the user confirms.

---

## Phase 4 — Save the spec file

Save the spec to: `spec/<same-kebab-name-as-intent>.md`

For example: if the intent was `intent/crm-to-practice-management-sync.md`, save to `spec/crm-to-practice-management-sync.md`.

---

## Phase 5 — Create Google Doc

If the Google Workspace skill or Google Docs tools are available in this session:

1. Load the google-workspace skill.
2. Create a new Google Doc with the spec content. Title it: `Spec: [title from metadata]`.
3. After the Doc is created, update the saved `spec/<name>.md` file: set `google-doc-url:` in the metadata comment block to the Google Doc URL.
4. Also add the Google Doc URL to the Related Documents table in the spec.

If Google Workspace tools are not available, skip this phase and note:
> "Google Doc not created — Google Workspace connector not available in this session. Run `/create-spec` again in a session with Google Workspace connected, or create the Doc manually."

---

## Phase 6 — Confirm and next steps

Confirm with:

> "Saved to `spec/<name>.md`[and created Google Doc at <url>].
>
> Next step: the product owner reviews the **Areas of Concern** section with the named policy owners and resolves each one before this spec advances to Stage 3 (Build). Once all concerns are resolved and open items are closed, update `status` in the metadata from `draft` to `approved`."

If the file could not be saved:

> "I could not save the file automatically. Copy the content above into a new file at `spec/<name>.md` in this repository."
