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
└── .claude/
    └── skills/
        └── create-intent/
            ├── SKILL.md                   — /create-intent skill
            └── intent-template.md         — template the skill reads at runtime
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
