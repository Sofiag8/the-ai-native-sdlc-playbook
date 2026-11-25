# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository is a neutral, anonymized template demonstrating the AI-native software development lifecycle (SDLC). It is a teaching artifact built alongside an Anthropic course on the AI-native SDLC playbook.

**No real client names, company names, proprietary system names, or person names should appear in any file here.** Use generic labels: `source system`, `target CRM`, `downstream ERP`, `accounting platform`, `practice management system`, `business stakeholder`, etc.

## Repository Structure

```
the-ai-native-sdlc-playbook/
├── CLAUDE.md                              — this file
├── intent/                                — Module 1: generated intent documents live here
└── .claude/
    └── skills/
        └── create-intent/
            ├── SKILL.md                   — /create-intent skill
            └── intent-template.md         — template the skill reads at runtime
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

## Git and GitHub workflow

Branch naming follows the stage of the artifact being created or revised:

| Branch pattern | When to use |
|----------------|-------------|
| `intent/<kebab-name>` | Adding or revising a Stage 1 intent document |
| `spec/<kebab-name>` | Stage 2 specification _(future)_ |

**To add a new intent document:**
1. Create a branch: `git checkout -b intent/<kebab-name>`
2. Run `/create-intent` and let the skill generate the file
3. Commit the file and push the branch
4. Open a PR — the PR merge is the recorded approval event for this artifact
5. Once all open questions are resolved and the PR checklist passes, merge to main

The `main` branch is protected — no direct pushes. All changes go through a PR.
