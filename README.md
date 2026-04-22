# Spec Kit Lite

A lightweight framework for spec-driven development using markdown + an AI
agent. No heavyweight process, no ceremony.

## Idea

Three documents per feature, three roles, no overlap:

| Document  | Role       | Answers                             |
|-----------|------------|-------------------------------------|
| `spec.md` | WHAT + WHY | What the feature does, and why      |
| `tech.md` | HOW IS     | How it's designed and wired in code |
| `plan.md` | HOW TO DO  | How to build it right now           |

## Structure

```
docs/
└── features/
    ├── _template/          ← templates
    │   ├── spec.md
    │   ├── tech.md
    │   └── plan.md
    └── pdf-export/         ← one folder = one feature
        ├── spec.md         ← committed
        ├── tech.md         ← committed
        └── .plan/          ← local (recommended in .gitignore)
            └── R3-background.md
```

## Commands

| Command       | What it does                                                          |
|---------------|-----------------------------------------------------------------------|
| `/specl-sync` | sync docs with code — or scaffold them from existing code on adoption |
| `/specl-take` | take a ticket / description — create or extend a feature              |
| `/specl-plan` | create an implementation plan for some R                              |
| `/specl-go`   | execute a plan                                                        |

Details and examples below.

### `/specl-sync`

Syntax: `/specl-sync [spec | tech | all | <feature> | <code-path>]`

Usually the first command you run on an existing project: point it at
a code path and it scaffolds `spec.md` + `tech.md` from the actual
code. On features that already have docs, the same command reconciles.

Two modes, picked automatically by whether the feature's `spec.md`
exists:

- **Bootstrap** (spec.md missing) — scaffolds initial `spec.md` and
  `tech.md` from existing code, inferring R from observed behavior.
  Use this when adopting SpecKitLite on a codebase that already has
  features implemented. Runs once per feature; subsequent runs
  reconcile.
- **Reconcile** (spec.md exists) — syncs docs with code state: R
  statuses, `[planned]` markers, Structure, components. Never touches
  requirement text, Decisions, Open questions, or Extension points —
  those are edited by hand or via chat with the agent.

```
/specl-sync              # interactive: pick feature and target
/specl-sync modules/pdf/ # bootstrap from existing code
/specl-sync pdf-export   # sync a specific feature
/specl-sync spec         # reconcile, R statuses and divergence
/specl-sync tech         # reconcile, structure + components
/specl-sync all          # reconcile, both in turn
```

### `/specl-take`

Syntax: `/specl-take <description | Jira ticket | GitHub/GitLab issue | URL>`

Accepts a free-form description, any URL, a Jira ticket, or a GitHub/GitLab
issue or PR/MR (content is pulled via Atlassian MCP, GitHub MCP, `gh` /
`glab` CLI, or `WebFetch`), then classifies:

- **new feature** → creates `docs/features/<name>/` with `spec.md`,
  `tech.md`, and an empty `.plan/`;
- **extend existing** → appends new R to `spec.md`, adds `[planned]`
  components to `tech.md`.

Classification is the agent's proposal; the user confirms or redirects.
Existing R, Decisions, and Open questions are never touched.

```
/specl-take Export document to PDF with A4/Letter format selection
/specl-take ELF-7777
/specl-take https://tango.atlassian.net/browse/ELF-7777
/specl-take https://github.com/acme/api/issues/42
/specl-take acme/api#42
/specl-take ELF-7777 focus on A4/Letter, skip watermarks
```

### `/specl-plan`

Syntax: `/specl-plan <description>`

Creates an implementation plan in `.plan/`. R numbers are extracted
explicitly from the text (`R3,R4`) or inferred from meaning with
confirmation; the rest flows into Approach.

```
/specl-plan R3
/specl-plan R3,R4 using Celery for the async flow
/specl-plan background PDF generation for large documents
/specl-plan R3 via Celery, name the plan ELF-7777-bg
```

### `/specl-go`

Syntax: `/specl-go [plan] [mode | hints]`

Executes a plan: walks through milestones, checks them off `[x]`, stops at
checkpoints. Never commits automatically. Optionally accepts a mode
(`resume` / `restart`) or free-form hints for the agent.

```
/specl-go                                         # shows the list of plans
/specl-go R3-R4-background                        # runs that plan
/specl-go R3-R4-background.md                     # extension is also fine
/specl-go R3-R4-background resume                 # continue from the first non-[x]
/specl-go R3-R4-background redo                   # clear all [x], start over
/specl-go R3-R4-background use AWS SDK v3         # free-form hints for the agent
```

If the plan already has `[x]` milestones and no mode was given, the
command will ask `continue` / `redo` / `cancel`.

## Feature lifecycle

Two entry paths: **adopting** an existing codebase (bootstrap from
code), or starting a **new feature** from scratch (take a description).

### Adoption (existing codebase)

```
        existing codebase (feature implemented, no docs)
                    │
                    ▼
        /specl-sync <code-path>
                    │  (bootstrap: spec.md is missing)
                    ▼
        docs/features/<name>/
                    │
                    ├── spec.md — R inferred from code
                    │             ([done] / [wip], never [todo])
                    ├── tech.md — real Structure, components,
                    │             integrations (no [planned])
                    └── .plan/
                    │
                    ▼
        review [NEEDS CLARIFICATION] + priorities in spec.md
                    │
                    ▼
        feature is tracked — next change goes through the
        new-feature flow below; /specl-sync now reconciles
                    │
                    ▼
        repeat /specl-sync for the next feature
```

### New feature

```
           task / ticket / URL
                    │
                    ▼
        /specl-take <description>
                    │
         ┌──────────┴──────────┐
         ▼                     ▼
     new feature         extend existing
     (new folder,        (append R to spec.md,
      spec.md, tech.md)   [planned] in tech.md)
                    │
                    ▼
        /specl-plan <description>
                    │
                    └── .plan/<name>.md (milestones)
                    │
                    ▼
        /specl-go [plan-name]
                    │
                    ├── code lands in the repo
                    └── .plan/<name>.md (milestones → [x])
                    │
                    ▼
            /specl-sync
                    │
                    ├── spec.md: R[wip] → R[done],
                    │           divergence into Open questions
                    └── tech.md: drop [planned],
                                 refresh Structure
```

### Cycle variants

**Iterating on a feature.** After `/specl-sync` you can see some R still
`[todo]` or new `[NEEDS CLARIFICATION]` items — add/clarify requirements
and create the next plan:

```
spec.md (add R5)  →  /specl-plan R5  →  /specl-go ...  →  /specl-sync
```

**Restarting a plan.** If the plan failed or you reverted code changes:

```
/specl-go <plan> redo      # clear all [x], run from the top
/specl-go <plan> resume    # continue from the first non-[x]
```

**Multiple plans per feature.** Split big work by R groups —
`.plan/R3-R4-background.md`, `.plan/R5-password.md`. Each runs
independently; `[x]` flags don't cross plans.

**Code vs. spec divergence.** `/specl-sync` drops `[NEEDS CLARIFICATION:
...]` into Open questions on mismatch. You edit the spec (via chat with
the agent or by hand), then sync again:

```
/specl-sync  →  NEEDS CLARIFICATION
             →  edit spec.md
             →  /specl-sync  →  consistent
```

## Requirements

Requirement format in `spec.md`:

| Priority      | Meaning                                      |
|---------------|----------------------------------------------|
| **Must**      | Without this the feature doesn't make sense  |
| **Should**    | Important, but the feature still makes sense |
| **Could**     | Nice-to-have extension                       |
| **Non-goals** | Deliberately out of scope                    |

| Status   | Meaning                 |
|----------|-------------------------|
| `[done]` | Implemented and in prod |
| `[wip]`  | In progress             |
| `[todo]` | Not started             |

Numbering is continuous: `R1, R2, R3, ...` across all groups. Deleted
numbers are not reused.

**Example:**

```markdown
**Must:**

- [done] R1. User MUST be able to export document to PDF
- [wip]  R2. System MUST support A4 and Letter formats
    - SC1: sync generation completes within 10 sec for docs <100 pages
- [todo] R3. System MUST generate PDF in background for large docs

**Could:**

- [todo] R4. System MUST support password-protected PDF

**Non-goals:**

- Batch export of multiple documents at once
```

## Markers in Open questions

| Marker                       | Purpose                                        |
|------------------------------|------------------------------------------------|
| No prefix                    | Open question up for discussion                |
| `[assumed: ...]`             | Assumption without confirmation — needs review |
| `[NEEDS CLARIFICATION: ...]` | Critical gap, blocks understanding             |

## Marker in tech.md

| Marker      | Where it goes                                               | Where it does NOT go                                    |
|-------------|-------------------------------------------------------------|---------------------------------------------------------|
| `[planned]` | Key components, Integration points, Data model — list items | Overview, Decisions, Extension points, section headings |

Removed by `/specl-sync` once the item is implemented.

## Install

Remotely via `curl` (run from the root of your project):

```bash
curl -sSL https://raw.githubusercontent.com/n1rmataqq/spec-kit-lite/master/install.sh | bash
```

Or locally from a clone of this repo:

```bash
cd /path/to/your/project
/path/to/spec-kit-lite/install.sh
```

Local mode activates automatically when `install.sh` sits next to
`templates/` and `commands/` — files are copied directly, `curl` isn't
touched.

The script:

- drops templates into `docs/features/_template/`
- drops commands into `.claude/commands/`
- adds `docs/features/*/.plan/` to `.gitignore`

Re-running is safe: existing files aren't overwritten and the
`.gitignore` line isn't duplicated.

## Principles

1. **KISS.** Four commands, three documents, four mandatory sections in
   spec. Everything else is optional.
2. **Separation by timescale.** Spec — permanent. Tech — current state.
   Plan — ephemeral working notebook.
3. **Code is the source of truth for implementation.** `sync` updates
   docs from code, never the reverse.
4. **Requirements are the source of truth for intent.** Commands can
   **add** new R (via `/specl-take`), but never rewrite existing R —
   that's a manual edit or a chat with the agent.
5. **Explicit confirmation.** No doc mutation or commit happens without
   an explicit yes/no from the user.

## When NOT to use

- Regulated domains (HIPAA, SOX, medical) — you need a full
  specification with traceability. Use
  [spec-kit](https://github.com/github/spec-kit).
- Team >3 devs and epics >1 month — SpecKitLite scales, but may need
  ADRs and design docs on top.
- Features <1 hour of work — the overhead isn't worth it, just write
  the code.
