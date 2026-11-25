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
├── plan/                                  — Stage 3: generated plan documents live here
│   └── crm-to-practice-management-sync.md — example (filled in)
├── scripts/
│   └── check-git-branch.sh               — PreToolUse hook: enforces branch conventions
└── .claude/
    ├── settings.json                      — registers the PreToolUse hook (team-wide)
    └── skills/
        ├── create-intent/
        │   ├── SKILL.md                   — /create-intent skill
        │   └── intent-template.md         — template the skill reads at runtime
        ├── create-spec/
        │   ├── SKILL.md                   — /create-spec skill
        │   └── spec-template.md           — IRD-shaped template the skill reads at runtime
        ├── create-plan/
        │   ├── SKILL.md                   — /create-plan skill
        │   └── plan-template.md           — phased plan template the skill reads at runtime
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

## Stage 3: Plan

**Status: complete**

The third stage takes an approved `spec.md` and produces a phased implementation plan — a `plan.md` committed to the repository that engineers can build against. This is the bridge between "what are we building" (spec) and "how are we building it" (code).

In a traditional workflow, implementation planning is informal: an engineer reads the spec, makes decisions in their head or in a Jira ticket, and starts coding. What was decided and why is rarely captured. The AI-native version makes the plan explicit and version-controlled — giving the team a shared understanding before the first line of code is written.

### The artifact

A plan document captures:
- A plain-language summary of what will be built
- Status table: all phases with completion tracking
- Files that change, grouped by phase — a pre-flight check for each phase
- Phase 0: environment setup and all prerequisites
- Phases 1–N: implementation phases derived from the spec's proposed flow, each with scoped tasks, verification steps, and open item cross-references
- Testing & UAT: one subsection per Definition of Done scenario with expected vs. actual tracking
- Deployment — Sandbox: step-by-step deployment checklist for non-production
- Deployment — Production: go/no-go checklist, cutover steps, rollback plan, and 48-hour monitoring window
- Risks, architecture decisions, open items (all spec open items carried forward)
- Confirmed references: live API endpoints, field names, and object IDs verified before build

Files live in `plan/` with the same kebab-case name as the source spec. The intent, spec, and plan are always chained — each is the input to the next stage, and all three together form the complete record of why something was built and how.

**Lifecycle states:**

| Status | Meaning |
|--------|---------|
| `draft` | Generated; not yet reviewed by engineering lead |
| `in-progress` | Implementation underway; plan updated to reflect actual progress |
| `complete` | All phases done; deployed to production |

### How to create a plan document

Run the `/create-plan` skill with the path to the approved spec file. This skill runs in **plan mode**: it reads the spec and codebase, drafts the plan, asks the engineer three interrogation questions one at a time, then calls `ExitPlanMode` for approval before writing any files.

```
/create-plan spec/crm-to-practice-management-sync.md
```

The three interview questions:
1. "What could this change break that isn't already covered in the Risks section?"
2. "Which phase or step feels most uncertain to you — where would you want to pause and verify before continuing?"
3. "Is there anything in the approach I've proposed that you'd do differently?"

After approval, the file is saved to `plan/<name>.md`.

### Reference files

| File | Purpose |
|------|---------|
| `.claude/skills/create-plan/plan-template.md` | Blank template — all sections with inline guidance |
| `plan/crm-to-practice-management-sync.md` | Filled example — the same professional services scenario carried through to a full implementation plan |
| `.claude/skills/create-plan/SKILL.md` | The `/create-plan` skill source |

---

## Module 4: Hooks as Build-Time Guardrails

**Status: complete**

The first three stages established *advisory* controls: CLAUDE.md rules tell Claude what conventions to follow, and skills enforce a particular workflow. Advisory controls work well until they don't — if Claude reasons past a rule or a skill is not invoked, the guardrail fails silently.

Module 4 adds the *deterministic* layer. Hooks fire on every matching tool call and block the action before it executes. Claude cannot reason past a hook; it sees the error message and must fix the problem before retrying.

### The difference: advisory vs. deterministic

| Control type | Example | Can Claude bypass it? |
|---|---|---|
| CLAUDE.md rule | "Do not push directly to main" | Yes — it is advice |
| Skill | `/create-intent` guides the workflow | Yes — only runs when invoked |
| Hook | `PreToolUse` on `Bash` | No — fires on every matching call |

A skill or CLAUDE.md rule is the right tool when the guidance is conditional or contextual. A hook is the right tool when the rule must hold without exception.

### The hook: `scripts/check-git-branch.sh`

The hook script runs before every `Bash` tool call. It inspects the `command` field of the JSON input and applies three checks for `git add`, `git commit`, and `git push`.

**Check 1 — Block on main branch**

If the current branch is `main`, the command is blocked with a message naming the three valid branch patterns. This prevents accidental direct commits to the protected branch even when Claude generates the git commands itself.

**Check 2 — Enforce branch naming convention**

If the branch name does not match `^(intent|spec|plan)/[a-z0-9][a-z0-9-]*$`, the command is blocked. This ensures every commit is traceable to a stage and a named artifact — not to an arbitrary branch like `feature/something` or `fix`.

**Check 3 — Commit subject line length (soft gate)**

If the command is `git commit -m "..."` and the first line of the message exceeds 72 characters, the command is blocked with a request to shorten it. This is a soft gate: Claude can retry immediately with a shorter message.

### Exit code semantics

| Exit code | Meaning |
|---|---|
| `0` | Allow — command proceeds |
| `2` | Block — the hook's stderr output is shown to Claude as an error message |

Any non-git Bash command (e.g. `ls`, `python3`, `npm install`) passes check 1 immediately and exits 0. The hook adds no overhead to unrelated commands.

### Governance

`.claude/settings.json` is committed to the repository. Every team member who opens a Claude Code session in this repo picks up the same hook configuration automatically.

For personal overrides — if a team member needs to bypass the hook for a specific session — they add an entry to `.claude/settings.local.json`, which is gitignored and never shared.

### Limitation

This hook fires on `Bash` tool calls. It does not fire when a shell command rewrites a file through the `Edit` or `Write` tools. For full coverage, the same branch-convention check should also run as a CI step (e.g. a GitHub Actions workflow that inspects the target branch on every pull request).

### Reference files

| File | Purpose |
|---|---|
| `scripts/check-git-branch.sh` | The hook script — branch and commit message checks |
| `.claude/settings.json` | Registers the `PreToolUse` hook on the `Bash` tool |

---

## Source of Truth Configurations

When a plan is committed to this repository, the `source-of-truth:` field in its metadata records which system is the authoritative record for that plan. Three configurations are supported:

### Option 1: `repo` (default)

The `.md` file in this repository is the authoritative record. All decisions, task status, and updates are made directly in `plan.md` and committed to Git. If an external ticket exists, link it to the plan's Git commit SHA — do not duplicate content there.

```
source-of-truth: repo
```

Best for: teams that live in their code editor and want the plan co-located with the code.

### Option 2: `jira:<ticket-id>`

The Jira ticket is authoritative. The `plan.md` in this repository is a working copy — synced from Jira at the start of each Claude Code session (if the Jira MCP connector is available). Updates to task status and notes are made in Jira; the `plan.md` is regenerated or updated from Jira rather than edited directly.

```
source-of-truth: jira:ENG-1234
```

Best for: teams where project tracking happens in Jira and engineers expect to find status there, not in Markdown files.

### Option 3: `github-issue:<number>`

The GitHub issue is authoritative. The `plan.md` is a working copy. Cross-reference the issue in the plan and in pull request descriptions. Status updates happen on the issue; the plan is updated when implementation decisions change.

```
source-of-truth: github-issue:42
```

Best for: open-source or GitHub-native teams where issues are the primary coordination mechanism.

---

**Note:** No MCP connectors are built in this repository. The three configurations above are documented as options. Setting up a live connector to Jira or Linear is deferred until the team's specific ticket system is known. When a connector is available, Claude Code reads from the authoritative system at session start and can sync changes back.

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
