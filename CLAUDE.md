# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

SpecKitLite is **not** an application — it's a distribution package for a spec-driven workflow. The artifacts here (
`templates/*.md`, `commands/*.md`, `install.sh`) are copied **into other projects** by `install.sh`, where they become
`docs/features/_template/*.md` and `.claude/commands/specl-*.md` respectively.

There is no build, no test suite, no lint. Verifying a change means running `./install.sh` in a scratch project and
exercising the resulting `/specl-*` commands through Claude Code.

The README is the user-facing spec for the framework. When the workflow or format changes, README and the affected
command/template files must move together — they describe the same contract from different angles.

## The three-document model

Every feature in a consuming project lives in `docs/features/<name>/` with three documents, each owned by a different
timescale:

- `spec.md` — **WHAT + WHY**, permanent. Requirements (`R1, R2, ...`), statuses (`[done]`/`[wip]`/`[todo]`),
  priorities (Must/Should/Could/Non-goals), Open questions.
- `tech.md` — **HOW IS**, reflects current code. Components, integrations, data model. Items planned-but-not-implemented
  get a `[planned]` marker that `/specl-sync` removes once code lands.
- `.plan/<name>.md` — **HOW TO DO**, ephemeral. Lives in `.plan/` (recommended `.gitignore`), gets milestones checked
  `[x]` as `/specl-go` executes them.

The four commands form a lifecycle: `/specl-take` → `/specl-plan` → `/specl-go` → `/specl-sync`. `/specl-take` branches
internally: it classifies the input (description / Jira-ticket / URL) and either creates a new feature folder or appends
new R to an existing `spec.md` (extend mode). Each command file (`commands/specl-*.md`) is a prompt that instructs the
agent step-by-step; they are not code.

## Invariants that cut across all commands

When editing any command or template, preserve these — they're the contract users rely on:

- **Explicit user confirmation before any write or commit.** No command mutates docs or runs `git commit` without a
  `yes`. `/specl-go` in particular never auto-commits — it proposes messages at checkpoints and waits.
- **Requirement numbering is sequential and append-only** across Must/Should/Could. Deleted `R` numbers are not reused.
- **`[planned]` goes on list items only** — in Key components, Integration points, Data model. Never on section headers,
  never in Overview, never in Decisions, never in Extension points (those three describe intent/architecture, not
  implementation state).
- **`/specl-sync` is code → docs, never the reverse.** It updates R statuses, `[planned]` markers, Structure, component
  lists. It never touches requirement text, Problem, Edge cases, Non-goals, Decisions, Extension points, or existing
  Open questions — those are human-edited only.
- **Divergence detection goes into Open questions as `[NEEDS CLARIFICATION: ...]`**, not as silent edits to
  requirements.
- **Commands share a "locate the current feature" step** (from cwd, from prompt, or ask). Keep the three wordings
  aligned when one changes.

## Template editing notes

Templates include blockquote hints prefixed with `📝` and marked *Delete when filled in*. The commands instruct the
agent to strip these on feature creation — when adding a new hint, follow the same format so the stripping logic keeps
working.