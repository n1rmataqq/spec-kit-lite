---
description: Sync spec.md and tech.md with the current state of the code
---

# specl-sync

Updates feature docs based on the real state of the code. Does not touch
requirement text, Decisions, Open questions, or Extension points — those
are edited by hand or via chat with the agent.

## What to do

1. `$ARGUMENTS` — optional target: `spec` | `tech` | `all` | empty.

2. Determine the target:
    - If `spec`, `tech`, or `all` was passed — use it.
    - If empty — ask:

```
     What do you want to sync with the code?
     - spec  — R statuses and divergence detection in spec.md
     - tech  — tech.md (structure, components, integrations)
     - all   — both
     
     Pick: spec / tech / all
```

3. Locate the current feature folder:
    - If the user is in `docs/features/<name>/` — use it.
    - If the prompt names a feature — use that.
    - If unclear — ask:

```
     Can't tell which feature to sync.
     Available: <list of docs/features/ folders>
     Give me the feature name.
```

4. Check: the feature folder must exist. If not:

```
   Folder docs/features/<name>/ does not exist.
   To create a new feature or extend an existing one: /specl-take <description>
```

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
