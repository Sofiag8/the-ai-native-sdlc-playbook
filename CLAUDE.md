# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository is a neutral, anonymized template demonstrating the AI-native software development lifecycle (SDLC). It is a teaching artifact built alongside an Anthropic course on the AI-native SDLC playbook.

**No real client names, company names, proprietary system names, or person names should appear in any file here.** Use generic labels: `source system`, `target CRM`, `downstream ERP`, `accounting platform`, `practice management system`, `business stakeholder`, etc.

## Repository Structure

```
the-ai-native-sdlc-playbook/
├── CLAUDE.md                              — this file
├── Makefile                               — verify target: runs scripts/verify.sh
├── intent/                                — Stage 1: generated intent documents live here
├── spec/                                  — Stage 2: generated spec documents live here
├── plan/                                  — Stage 3: generated plan documents live here
├── scripts/
│   ├── check-git-branch.sh               — PreToolUse hook: enforces branch conventions
│   ├── protect-templates.sh              — PreToolUse hook: guards policy/template files
│   └── verify.sh                         — document integrity checks (run via make verify)
└── .claude/
    ├── settings.json                      — registers all PreToolUse hooks (team-wide)
    ├── agents/
    │   ├── verifier.md                    — subagent: runs make verify, reports only
    │   ├── researcher.md                  — subagent: explores codebase/web, read-only
    │   └── simplifier.md                 — subagent: reviews artifacts, proposes cuts
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

Intent documents live in the `intent/` folder. File names are kebab-case.

### Lifecycle states

| Status | Meaning |
|--------|---------|
| `draft` | Being written; not yet reviewed |
| `under-review` | Shared for stakeholder input; open questions being resolved |
| `committed` | All open questions resolved; approved by the product owner; ready to advance to Stage 2 |

An intent document cannot be marked `committed` while it has open rows in its Open Questions table. The merge into main is the recorded approval event.

### Creating an intent document

Any team member can create an intent document by invoking the `/create-intent` skill.

```
/create-intent
```

---

## Module 2: Requirements and Design

The second stage takes an approved `intent.md` and produces a full Integration Requirements Document (spec.md) that engineering can plan against.

A product owner or technical lead invokes `/create-spec` with the intent file path. The skill reads the intent, applies the three policy files in `.claude/skills/policies/` as constraints, and generates the spec in one pass.

```
/create-spec intent/crm-to-practice-management-sync.md
```

### Lifecycle states

| Status | Meaning |
|--------|---------|
| `draft` | Generated; not yet reviewed by product owner |
| `under-review` | Product owner reviewing Areas of Concern with policy owners |
| `approved` | All concerns resolved; ready to advance to Stage 3 (Build) |

---

## Module 3: Plan

The third stage takes an approved `spec.md` and produces a phased implementation plan (`plan.md`) that engineers can build against.

An engineer or technical lead invokes `/create-plan` with the spec file path. The skill runs in plan mode: it reads the spec and codebase, drafts the plan, asks three interview questions one at a time, then calls ExitPlanMode for approval before writing the file.

```
/create-plan spec/crm-to-practice-management-sync.md
```

### Lifecycle states

| Status | Meaning |
|--------|---------|
| `draft` | Generated; not yet reviewed by engineering lead |
| `in-progress` | Implementation underway; plan updated to reflect actual progress |
| `complete` | All phases done; deployed to production |

---

## Module 4: Hooks as Build-Time Guardrails

Skills and CLAUDE.md rules are advisory — Claude can reason past them. Hooks are deterministic: they fire on every matching tool call and block the action before it runs.

`scripts/check-git-branch.sh` is registered as a `PreToolUse` hook on the `Bash` tool in `.claude/settings.json`. It fires before every Bash call.

**What it blocks (exit 2 — blocked, message shown to Claude):**
1. `git add`, `git commit`, or `git push` while on branch `main`
2. Those same commands while on a branch that does not match `^(intent|spec|plan|policy|template)/[a-z0-9][a-z0-9-]*$`
3. `git commit -m "..."` where the subject line exceeds 72 characters

`.claude/settings.json` is committed to the repository. Personal overrides go in `.claude/settings.local.json` (gitignored).

---

## Module 5: Parallel Sessions and Subagents

Subagent definitions live in `.claude/agents/` with `name:`, `description:`, and `tools:` frontmatter. Three subagents ship with this repo: `verifier` (runs make verify, reports only), `researcher` (read-only codebase and web exploration), and `simplifier` (reviews completed artifacts, proposes cuts). Check definitions into Git so the whole team shares them. See README.md for full detail.

---

## Module 6: Give Claude a Feedback Loop

Run `make verify` before reporting a task done. It checks spec/intent and plan/spec pairing, agent frontmatter completeness, and CLAUDE.md line count. Paste the output.

Policy files, SKILL.md files, `*-template.md` files, and `scripts/verify.sh` are protected by `protect-templates.sh` (PreToolUse on Edit and Write). They can only be modified on `policy/<name>` or `template/<name>` branches. See README.md for detail.

---

## Commands

| Command | What it does |
|---------|-------------|
| `make verify` | Runs all four document integrity checks |

---

## Git and GitHub workflow

Branch naming follows the stage of the artifact being created or revised:

| Branch pattern | When to use |
|----------------|-------------|
| `intent/<kebab-name>` | Adding or revising a Stage 1 intent document |
| `spec/<kebab-name>` | Adding or revising a Stage 2 spec document |
| `plan/<kebab-name>` | Adding or revising a Stage 3 plan document |
| `policy/<kebab-name>` | Modifying any file in `.claude/skills/policies/` |
| `template/<kebab-name>` | Modifying any SKILL.md, `*-template.md`, or `scripts/verify.sh` |

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
