# The AI-Native SDLC Playbook

A neutral, anonymized template repository demonstrating the AI-native software development lifecycle (SDLC). Built alongside the Anthropic AI-native SDLC course as a practical reference — grounded in real integration project patterns but scrubbed of any client, company, or proprietary system names.

The goal is a reusable playbook: anyone on a technical team can fork this, adapt the templates and skills to their organization's conventions, and use it as the shared home for their own AI-native SDLC artifacts.

---

## What "AI-Native SDLC" means here

Traditional SDLC has long handoff queues between roles: an engineer has an idea, waits for a PM to write it up, waits for design, waits for a spec review. Weeks pass before a line of code is written.

The AI-native approach compresses those queues by keeping every human in the loop — but letting Claude handle the structure, the questions an analyst would ask, and the artifact drafting. The originator still owns the content. The product owner still approves. But the cycle from "I have an idea" to "we have something to design against" shrinks from weeks to hours.

Each stage of the SDLC produces a version-controlled Markdown artifact. These artifacts are machine-readable, human-reviewable, and chained: each one is the input to the next stage.

---

## Repository structure

```
the-ai-native-sdlc-playbook/
├── README.md                              — this file
├── CLAUDE.md                              — guidance for Claude Code sessions
├── intent/                                — Stage 1: generated intent documents live here
│   └── crm-to-practice-management-sync.md — example (filled in)
├── spec/                                  — Stage 2: generated spec documents live here
│   └── crm-to-practice-management-sync.md — example (filled in)
└── .claude/
    └── skills/
        ├── create-intent/
        │   ├── SKILL.md                   — /create-intent skill
        │   └── intent-template.md         — template the skill reads at runtime
        ├── create-spec/
        │   ├── SKILL.md                   — /create-spec skill
        │   └── spec-template.md           — IRD-shaped template the skill reads at runtime
        └── policies/
            ├── integration-security.md    — auth, PII, encryption constraints
            ├── integration-standards.md   — error categories, retry, idempotency
            └── infrastructure-ownership.md — ownership model, costs, warranty
```

---

## Stage 1: Captured as Intent

**Status: complete**

The first stage turns a vague idea, ticket, or business problem into a structured proto-spec before any design work begins. The originator — who may not be technical — brainstorms with Claude and the result is committed as `intent.md`.

### The artifact

An intent document captures:
- What cannot be done today and who is blocked
- What the proposed outcome looks like (in plain language)
- Which systems are involved and an explicit scope boundary
- Technical, business, and organizational constraints
- Open questions that must be resolved before design begins
- Success criteria (leading and lagging indicators)

Files live in `intent/` with kebab-case names. Each file has a metadata block (hidden in rendered Markdown) tracking `title`, `version`, `status`, and `supersedes`.

**Lifecycle states:**

| Status | Meaning |
|--------|---------|
| `draft` | Being written; not yet reviewed |
| `under-review` | In stakeholder review; open questions being resolved |
| `committed` | All open questions closed; approved; ready for Stage 2 |

An intent document cannot move to `committed` while its Open Questions table has open rows. The merge of the file into the main branch is the recorded approval event — author, timestamp, and full revision history live in Git.

**Process metrics:**
- Leading: time from first conversation to a committed `intent.md`
- Lagging: share of committed intent files accepted into Stage 2 vs. closed

### How to create an intent document

Run the `/create-intent` skill in Claude Code. No Git knowledge required from the originator — a technical team member commits the result.

**Cold start:**
```
/create-intent
```

**With seed context:**
```
/create-intent We need contacts created in our HR system to automatically
appear in the sales CRM within 24 hours of onboarding.
```

The skill guides the originator through eight conversational phases — one question per turn — covering problem, outcome, systems, scope, integration specifics (if applicable), constraints, open questions, and success criteria. It reads `intent/intent-template.md` to generate the draft, iterates until the originator confirms the content is accurate, and saves the file.

### Reference files

| File | Purpose |
|------|---------|
| `.claude/skills/create-intent/intent-template.md` | Blank template — all sections with inline guidance |
| `intent/crm-to-practice-management-sync.md` | Filled example — a professional services firm automating new engagement onboarding |
| `.claude/skills/create-intent/SKILL.md` | The `/create-intent` skill source |

---

## Stage 2: Requirements and Design

**Status: complete**

The second stage takes an approved `intent.md` and produces a full Integration Requirements Document — what this repo calls `spec.md`. This is the document engineering plans against. It is richer and more technical than the intent, grounded in the organization's policies, and contains flagged concerns the product owner must resolve before build begins.

In a traditional workflow, this document is drafted manually: a technical lead hunts through Slack threads, prior documents, and project memory to assemble it. The AI-native version produces the same artifact in one prompted session.

### The artifact

A spec document captures:
- Overview and important definitions
- Scope boundary (confirmed and technically extended from intent)
- Infrastructure ownership and cloud components
- Proposed data flow — step-by-step, per direction
- Source system integration points (auth, rate limits, trigger mechanism)
- Volume estimates
- Full field mapping / data transformation table
- Source of truth rules (which system wins on conflict)
- Error handling and exception playbook (Categories A, B, C)
- Responsibilities table (vendor vs. client — every task assigned)
- Assumptions and limitations
- Definition of done
- Costs and ownership (monthly cloud estimate + warranty scope)
- Omissions (explicitly not in scope)
- Open items (carried from intent, plus spec-surfaced gaps)
- Decision record
- Areas of Concern (policy violations or design risks for product owner review)

Files live in `spec/` with the same kebab-case name as the source intent. The spec and intent are always committed together — the file pair records what was asked for and what was designed.

**Lifecycle states:**

| Status | Meaning |
|--------|---------|
| `draft` | Generated; not yet reviewed |
| `under-review` | Product owner reviewing Areas of Concern with policy owners |
| `approved` | All concerns resolved; ready to advance to Stage 3 (Build) |

### How to create a spec document

Run the `/create-spec` skill with the path to the approved intent file. This is a single-pass skill — it generates the full spec in one turn without asking questions.

```
/create-spec intent/crm-to-practice-management-sync.md
```

The skill reads the intent, applies the three policy skills as constraints, generates the spec, flags concerns, saves `spec/<name>.md`, and creates a Google Doc for stakeholder sharing (requires Google Workspace connection).

### Policy skills

The spec is automatically constrained by three policy files. These are read by `/create-spec` — they do not need to be invoked separately. Organizations adapt these to their own standards.

| File | Enforces |
|------|---------|
| `.claude/skills/policies/integration-security.md` | Authentication methods, PII field handling, encryption, secrets management |
| `.claude/skills/policies/integration-standards.md` | Error categories (A/B/C), retry policy, idempotency, deduplication, logging |
| `.claude/skills/policies/infrastructure-ownership.md` | Client owns infrastructure, vendor owns code, 10-day warranty, cost estimation |

### The Google Doc

After saving the `.md` file, `/create-spec` creates a Google Doc with the same content. The `.md` file is the version-controlled artifact (tracked in Git, diff-able, chained to the next stage). The Google Doc is the stakeholder-facing copy — the format teams already use to share with clients, partners, and internal reviewers.

### Reference files

| File | Purpose |
|------|---------|
| `.claude/skills/create-spec/spec-template.md` | Blank template — all 19 sections with inline guidance |
| `spec/crm-to-practice-management-sync.md` | Filled example — the same professional services scenario as the intent example, taken through to full spec |
| `.claude/skills/create-spec/SKILL.md` | The `/create-spec` skill source |
| `.claude/skills/policies/` | The three policy constraint files |

---

## Maintaining CLAUDE.md as this repo grows

`CLAUDE.md` is loaded into every Claude Code session and directly affects the quality of responses. As more stages are added to this playbook, it will grow — and a bloated `CLAUDE.md` performs worse than a lean one. Here are the practices this repo follows.

### Size and focus

**Keep the root `CLAUDE.md` under ~200 lines.** This is the threshold where instruction-following degrades measurably. Claude Code's system prompt already occupies context budget; every unnecessary line in `CLAUDE.md` crowds out the actual task. The file should contain only what Claude cannot reliably infer from reading the code itself.

**What belongs in `CLAUDE.md`:**
- Repository purpose and neutrality rule (no real names)
- Folder structure and what each directory is for
- Stage-by-stage workflow overview (commands, lifecycle states)
- Conventions that are genuinely non-obvious

**What does not belong:**
- Style rules that a linter or formatter already enforces
- Code snippets (they go stale; use `file:line` references instead)
- Detailed workflow documentation (that belongs in stage-specific files or the README)
- Task-specific instructions for one-off work

### Layering instead of growing

When a new stage adds meaningful conventions, add a `CLAUDE.md` inside that stage's directory rather than appending to the root file. Claude Code reads up the directory tree and merges them automatically.

```
intent/
  CLAUDE.md          ← intent-stage-specific rules (if needed)
spec/
  CLAUDE.md          ← spec-stage-specific rules (if needed)
CLAUDE.md            ← root: repo purpose, folder map, shared conventions only
```

### Path-scoped rules for conditional guidance

For rules that only apply when working in a specific area, use `.claude/rules/` with a `paths:` frontmatter header. These load only when Claude touches matching files, so they do not consume context in unrelated sessions.

```
.claude/rules/intent-stage.md   ← loaded only when editing files in intent/
.claude/rules/spec-stage.md     ← loaded only when editing files in spec/
```

### Treat it like code

- **Commit `CLAUDE.md` and `.claude/skills/` to Git.** Everyone on the team shares the same agent behavior.
- **Review changes in pull requests.** A new rule affects every future session in this repo — it deserves the same review as a code change.
- **Prune regularly.** When Claude stops making a mistake, the rule that addressed it may no longer be necessary. Remove it.
- **Update after mistakes.** When Claude makes the same error twice, that is a missing or underspecified rule. Add it.
- **Use `CLAUDE.local.md` for personal overrides** (gitignored). Personal preferences — formatting style, verbosity, preferred tools — do not belong in the shared file.

### Signs the file needs attention

- It has grown past 200 lines
- Sections describe how to do things that have not been built yet
- Rules reference files or directories that no longer exist
- The same information appears in both `CLAUDE.md` and `README.md`

---

## Contributing

All content in this repository must be neutral and anonymized. Before adding any file:
- Replace real client, company, person, and proprietary system names with generic labels (`source CRM`, `practice management system`, `downstream ERP`, `business stakeholder`, etc.)
- Verify the content is realistic enough to be useful as a teaching example, but generic enough that it could apply to any professional services or integration context
