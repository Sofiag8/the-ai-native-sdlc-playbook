# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository is a neutral, anonymized template demonstrating the AI-native software development lifecycle (SDLC). It is a teaching artifact built alongside an Anthropic course on the AI-native SDLC playbook.

**No real client names, company names, proprietary system names, or person names should appear in any file here.** Use generic labels: `source system`, `target CRM`, `downstream ERP`, `accounting platform`, `practice management system`, `business stakeholder`, etc.

## Repository Structure

```
the-ai-native-sdlc-playbook/
├── CLAUDE.md                              — this file
├── intent/                                — Stage 1: generated intent documents live here
├── spec/                                  — Stage 2: generated spec documents live here
├── plan/                                  — Stage 3: generated plan documents live here
└── .claude/
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

## Module 1: Captured as Intent

The first stage of the AI-native SDLC is capturing intent — turning a vague idea, ticket, or business problem into a structured, version-controlled artifact before any design or development begins.

### What an intent document is

An `intent.md` captures, in the originator's own words:
- What cannot be done today and who is blocked
- What the proposed outcome looks like
- Which systems are involved and what the scope boundary is
- What constraints apply
- What open questions must be resolved before design begins

Intent documents live in the `intent/` folder. The file for a project called "Contact Sync to CRM" would be `intent/contact-sync-to-crm.md`. File names are kebab-case.

### Lifecycle states

The metadata block at the top of each intent file (an HTML comment, invisible in rendered Markdown) tracks status:

| Status | Meaning |
|--------|---------|
| `draft` | Being written; not yet reviewed |
| `under-review` | Shared for stakeholder input; open questions being resolved |
| `committed` | All open questions resolved; approved by the product owner; ready to advance to Stage 2 (Specification) |

An intent document cannot be marked `committed` while it has open rows in its Open Questions table.

The merge of an intent file into the main branch is the recorded approval event. The Git history provides the author, timestamp, and full revision record.

### Process metrics (Module 1)

- **Leading indicator**: time from first conversation to a committed `intent.md`, read from Git history
- **Lagging indicator**: share of committed intent files accepted into Stage 2 rather than closed

### Creating an intent document

Any team member — technical or not — can create an intent document by invoking the `/create-intent` skill. No Git knowledge is required to run the conversation; a technical team member commits the resulting file.

**Basic invocation:**
```
/create-intent
```
Claude will ask questions one at a time, like an analyst would, until it has enough information to draft the document.

**With seed context** (a Slack message, a brief description, etc.):
```
/create-intent We need contacts created in the HR system to automatically
appear in our sales CRM within 24 hours of onboarding.
```
Claude uses the pasted context as a starting point and asks only for what is missing.

The skill reads `intent/intent-template.md` to generate the draft, iterates with the originator until the content is confirmed accurate, then saves the file to `intent/<kebab-case-name>.md`.

### Template

The blank template lives at `.claude/skills/create-intent/intent-template.md`. It documents every section and its purpose and can be filled in manually without the skill.

---

---

## Module 2: Requirements and Design

The second stage takes an approved `intent.md` and produces a full Integration Requirements Document (spec.md) that engineering can plan against.

### What a spec document is

A spec captures:
- Overview and definitions
- Scope boundary (confirmed and extended from intent)
- Infrastructure ownership and cloud components
- Proposed data flow (step-by-step, per direction)
- Field mapping and data transformation
- Error handling and exception playbook (Categories A, B, C)
- Responsibilities (vendor vs. client)
- Assumptions, definition of done, costs
- Open items (carried from intent, plus spec-surfaced gaps)
- Areas of Concern (policy violations or design risks flagged for product owner review)

Spec documents live in the `spec/` folder with the same kebab-case name as the source intent.

### Lifecycle states

| Status | Meaning |
|--------|---------|
| `draft` | Generated; not yet reviewed by product owner |
| `under-review` | Product owner reviewing Areas of Concern with policy owners |
| `approved` | All concerns resolved; ready to advance to Stage 3 (Build) |

### Creating a spec document

A product owner or technical lead invokes `/create-spec` with the intent file path. The skill reads the intent, applies the three policy skills, and generates the spec in one pass.

```
/create-spec intent/crm-to-practice-management-sync.md
```

The skill also creates a Google Doc version for stakeholder sharing (requires Google Workspace connection).

### Policy skills

The spec is constrained by three policy files in `.claude/skills/policies/`. These are read automatically by `/create-spec` — they do not need to be invoked separately.

| Policy file | Enforces |
|-------------|---------|
| `integration-security.md` | Auth methods, PII handling, encryption, secrets management |
| `integration-standards.md` | Error categories (A/B/C), retry, idempotency, deduplication, logging |
| `infrastructure-ownership.md` | Client owns infrastructure, vendor owns code, warranty terms, cost estimation |

---

## Module 3: Plan

The third stage takes an approved `spec.md` and produces a phased implementation plan (`plan.md`) that engineers can build against.

### What a plan document is

A plan captures:
- Phase-by-phase implementation tasks derived from the spec
- Explicit Testing & UAT phase with per-scenario subsections
- Sandbox and production deployment phases with checklists and rollback plan
- Files that change, grouped by phase
- Risks, architecture decisions, and open items (all spec open items carried forward)
- Confirmed references: live API endpoints and field names verified before build

Plan documents live in the `plan/` folder with the same kebab-case name as the source spec and intent.

### Lifecycle states

| Status | Meaning |
|--------|---------|
| `draft` | Generated; not yet reviewed by engineering lead |
| `in-progress` | Implementation underway; plan updated to reflect actual progress |
| `complete` | All phases done; deployed to production |

### Creating a plan document

An engineer or technical lead invokes `/create-plan` with the spec file path. The skill runs in plan mode: it reads the spec and codebase, drafts the plan, asks three interview questions one at a time, then calls ExitPlanMode for approval before writing the file.

```
/create-plan spec/crm-to-practice-management-sync.md
```

Set `source-of-truth:` in the plan.md metadata to `repo`, `jira:<ticket-id>`, or `github-issue:<number>` to record which system is authoritative for this plan. Default is `repo`.

---

## Git and GitHub workflow

Branch naming follows the stage of the artifact being created or revised:

| Branch pattern | When to use |
|----------------|-------------|
| `intent/<kebab-name>` | Adding or revising a Stage 1 intent document |
| `spec/<kebab-name>` | Adding or revising a Stage 2 spec document |
| `plan/<kebab-name>` | Adding or revising a Stage 3 plan document |

**To add a new intent document:**
1. Create a branch: `git checkout -b intent/<kebab-name>`
2. Run `/create-intent` and let the skill generate the file
3. Commit the file and push the branch
4. Open a PR — the PR merge is the recorded approval event for this artifact
5. Once all open questions are resolved and the PR checklist passes, merge to main

**To add a new spec document:**
1. Create a branch: `git checkout -b spec/<kebab-name>`
2. Run `/create-spec intent/<kebab-name>.md` and let the skill generate the file
3. Commit both the spec and any Google Doc URL update, then push the branch
4. Open a PR — resolve Areas of Concern before merging
5. Merge when status is `approved`

**To add a new plan document:**
1. Create a branch: `git checkout -b plan/<kebab-name>`
2. Run `/create-plan spec/<kebab-name>.md` and let the skill interview and generate the file
3. Commit the plan and push the branch
4. Open a PR — engineering lead reviews phases and open items before merging
5. Merge when status is `draft` and the team is ready to begin implementation

The `main` branch is protected — no direct pushes. All changes go through a PR.
