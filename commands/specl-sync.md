---
description: Sync spec.md and tech.md with code — reconcile if docs exist, or scaffold them from existing code
---

# specl-sync

Two modes, picked automatically by whether the feature's `spec.md`
already exists:

- **Reconcile** (spec.md exists) — updates R statuses, `[planned]`
  markers, Structure, and components. Never rewrites requirement text,
  Decisions, Open questions, or Extension points.
- **Bootstrap** (spec.md missing) — scaffolds initial `spec.md` and
  `tech.md` from the code, inferring R from observed behavior.
  Intended for adopting SpecKitLite on an existing codebase. Runs once
  per feature; subsequent `/specl-sync` runs reconcile.

## What to do

1. Parse `$ARGUMENTS`. Optional, may contain:
    - A target keyword: `spec` | `tech` | `all` (reconcile mode only).
    - A feature-name or a code-path hint.
    - Free text for context.

   Examples:
    - `/specl-sync` — fully interactive
    - `/specl-sync spec` — reconcile, target = spec
    - `/specl-sync tech` — reconcile, target = tech
    - `/specl-sync pdf-export` — sync feature pdf-export (target = all)
    - `/specl-sync pdf-export tech` — feature + target
    - `/specl-sync modules/export/` — bootstrap from that code path

2. Determine target:
    - If `spec`, `tech`, or `all` is present in `$ARGUMENTS` — use it.
    - Otherwise default to `all`.
    - In bootstrap mode, target is always `all` (both files written).
    - If `$ARGUMENTS` is completely empty, ask after step 3:

```
     What do you want to sync with the code?
     - spec  — R statuses and divergence detection in spec.md
     - tech  — tech.md (structure, components, integrations)
     - all   — both
     
     Pick: spec / tech / all
```

3. Locate the feature:
    - If the user is in `docs/features/<name>/` — use that feature.
    - If `$ARGUMENTS` names an existing `docs/features/<name>/` — use
      it.
    - If `$ARGUMENTS` contains a path outside `docs/features/`
      (e.g. `modules/export/`, `src/pdf/`) — treat it as bootstrap
      intent and carry the path to step 5.
    - If nothing resolves and at least one feature exists — ask:

```
     Which feature do you want to sync?
       Existing: <list of docs/features/ folders>
       - <name>       — reconcile that feature
       - bootstrap    — scaffold a new feature from existing code
       - cancel
```

    - If no features exist at all:

```
     No features in docs/features/ yet.
     Bootstrap one from existing code? [yes / cancel]
```

4. Mode detection:
    - Located feature has `spec.md` → **reconcile mode**, continue to
      step 5.
    - `spec.md` is missing (folder empty or the folder doesn't yet
      exist) → **bootstrap mode**, jump to step 8.

---

## Reconcile mode

5. Determine the feature's code area:
    - From Structure in tech.md — if paths are listed there.
    - Auto-discovery: folders/files named after the feature
      (`<name>`, `<name-snake_case>`, camelCase).
    - If nothing found:

```
     Could not auto-discover code for feature '<name>'.
     
     Options:
     1. Specify a path explicitly (e.g., modules/export/ or src/features/pdf/)
     2. Try a more active search (LLM analysis of the project)
     3. Cancel
     
     Pick: 1 / 2 / 3
```

     If 2 — read the project structure (README, package/setup files,
     top-level directories), correlate with the feature name and the
     requirements in spec.md, and propose the discovered paths:

```
     Possible paths:
     - modules/export/ (contains exporter.py, tasks.py) — most likely
     - src/documents/export/ — less likely
     
     Use modules/export/? [yes / <other path> / cancel]
```

6. Read the relevant code and recent commits.

7. Branch by target:

### target = `spec`

**Action 1: update R statuses.**

- R implementation exists and is covered by tests → `[done]`.
- R is partially implemented → `[wip]`.
- No implementation → leave as is.

**Action 2: divergence detection.**

- **R marked `[done]`, implementation not found:**

```
     [NEEDS CLARIFICATION: R3 is marked [done] but the implementation is missing]
```

- **Behavior in code not covered by any R:**

```
     [NEEDS CLARIFICATION: code contains rate limiting (10 req/min in
     export_routes.py:45), no matching R. Add a requirement or remove
     the code?]
```

Count as divergence:

- New public API endpoints / methods.
- Input validation.
- Limits (rate, size, quantity).
- Error handling / retry policies.
- Side effects: notifications, queue writes, external calls.

Do NOT count as divergence:

- Private helpers, utility functions.
- Logging, metrics.
- Configuration.
- Deprecated/legacy code with a marker.

Do NOT touch:

- Requirement text.
- Problem, Edge cases, Non-goals.
- Existing Open questions.
- Links, SC.

Show the plan and request confirmation:

```
   Changes in spec.md:
   
   Statuses:
   - R1: [wip] → [done]   (PdfExporter.render is implemented and tested)
   - R3: [todo] → [wip]   (BackgroundGenerator exists, notifications missing)
   
   Divergence (added to Open questions):
   - [NEEDS CLARIFICATION: R4 [done], notifications implementation not found]
   - [NEEDS CLARIFICATION: rate limiting in code but no matching R]
   
   Apply? [yes/no]
```

### target = `tech`

Update tech.md based on the state of the code:

- **Overview:** refresh if the structure changed.
- **Structure:** add new files/modules, remove stale ones, drop
  `[planned]` from implemented items. If it was `TBD` — replace it.
- **Key components:** drop `[planned]`, add new components, refresh
  descriptions. If it was `TBD` — fill it in.
- **Data flows:** refresh.
- **Data model:** refresh tables, drop `[planned]`.
- **Integration points:** refresh, drop `[planned]`.

Do NOT touch:

- **Decisions** — manual content.
- **Extension points** — manual content.

Show the diff and request confirmation:

```
   Changes in tech.md:
   
   Structure:
   + modules/export/tasks.py
   + modules/export/s3_client.py
   
   Key components (was TBD, now):
   + PdfExporter (implements R1, R2) — synchronous PDF generation
   + BackgroundGenerator (implements R3) — Celery task for the async flow
   
   Integration points:
   + S3 (bucket: documents-exports) — PDF uploads
   
   Decisions and Extension points were not touched.
   
   Apply? [yes/no]
```

### target = `all`

Run both in turn: spec first, then tech. Each with a separate
confirmation.

Combined summary:

```
   spec.md: updated N R statuses, added K divergence questions.
   tech.md: updated M components, added K files to Structure.
```

---

## Bootstrap mode

8. Gather inputs:
    - **Code path(s) to analyze.** If `$ARGUMENTS` carried a path
      (from step 3), use it. Otherwise ask:

```
     Paste one or more code paths (files or directories) that make up
     this feature:
```

    - **Feature name.** If the user was already in
      `docs/features/<name>/`, use `<name>`. Otherwise propose a
      kebab-case name from the code (dominant module, endpoint
      prefix, primary class/package) and ask:

```
     Proposed feature name: pdf-export
     Accept, or give another (kebab-case, no spaces).
```

9. Analyze the code:
    - Read the files in the path(s).
    - Public surface: HTTP endpoints, CLI commands, public
      methods/classes, emitted events, message handlers.
    - Behavior: validations, limits, retries, side effects, error
      handling.
    - Integrations: DB, queues, external APIs, filesystem, other
      internal modules.
    - Data: ORM models, migrations, key data structures.
    - Scan recent commits touching the path for intent clues (commit
      messages, co-changed files).

10. Draft spec.md from observed behavior:
    - **Problem:** 2-3 sentences on the feature's purpose, drawn
      from code and commit evidence. If "why" isn't clear from the
      code, write a narrow "what" statement and drop a
      `[NEEDS CLARIFICATION: what user pain does this solve?]` into
      Open questions instead of inventing motivation.
    - **Requirements:** each piece of observable behavior → one R.
        - Format: "User MUST be able to X" or "System MUST Y".
        - Status:
            - Fully implemented + tests exist → `[done]`.
            - Implemented but partial / no tests → `[wip]`.
            - Never emit `[todo]` — if it isn't in the code, it
              isn't a bootstrap-derived R.
        - Priority guess: core user-facing behavior → Must;
          optional/configurable → Should; extensions / convenience →
          Could. When unclear — Must.
        - Numbering: R1, R2, R3, ... in inferred order.
    - **SC:** add only when the code enforces a concrete threshold
      (timeout, size cap, rate limit). Reference the enforcing file.
    - **Edge cases:** skip unless the code visibly handles a
      specific edge (explicit branch for empty input, etc.).
    - **Open questions:** for any behavior whose intent isn't
      obvious, add
      `[NEEDS CLARIFICATION: <what's ambiguous>, ref: <file:line>]`
      rather than inventing an R.
    - **Non-goals / Links:** leave blank — human-owned.

11. Draft tech.md from the actual code:
    - **Overview:** 2-3 sentences on shape at the code level.
    - **Structure:** real paths discovered in step 9. No `[planned]`.
    - **Key components:** actual classes / services / modules, each
      annotated with the R it implements.
    - **Data flows:** include only when the interaction is
      non-trivial (async, multi-step). Skip for linear CRUD.
    - **Data model:** fill when the feature owns tables / entities.
    - **Integration points:** fill from discovered integrations.
    - **Decisions:** include only when commit history or in-code
      comments reveal a deliberate "why". Don't invent decisions.
    - **Extension points:** include only when the code exposes an
      obvious seam (plugin registry, subclass hook, strategy map).
    - No `[planned]` markers anywhere — the code already exists.

12. Show the proposed files and request confirmation:

```
   Bootstrap: docs/features/<name>/
   
   spec.md: N requirements (K [done], M [wip]),
            P open questions, Q [NEEDS CLARIFICATION]
   tech.md: <section list>
   
   --- spec.md preview ---
   <first ~40 lines>
   
   --- tech.md preview ---
   <first ~40 lines>
   
   Write these files? [yes / show full / no]
```

    If `show full` — print the complete proposed contents, then
    re-ask.

13. On `yes`:
    - Create `docs/features/<name>/` and an empty `.plan/` if they
      don't exist.
    - Write `spec.md` and `tech.md`.
    - Print summary:

```
     Bootstrapped: docs/features/<name>/
       N requirements inferred ([done]: K, [wip]: M)
       Q [NEEDS CLARIFICATION] items to review
     
     Next:
     - Review spec.md — priority assignments and every
       [NEEDS CLARIFICATION] entry.
     - Review tech.md — inferred structure and components.
     - Subsequent /specl-sync runs on this feature will reconcile,
       not re-bootstrap.
```
