---
description: Create an implementation plan for the given feature requirements
---

# specl-plan

Creates a new implementation plan in `.plan/` of the current feature.

## What to do

1. Parse `$ARGUMENTS` — a single free-form text, from which you derive:
    - **List of R** — explicit mentions (`R3`, `R3,R4`, `R3 and R4`,
      `R3 R4`), or inferred from the text when no explicit numbers
      are given.
    - **Approach** — everything that isn't about R numbers or the
      file name.
    - **File name (optional)** — if the text explicitly names one
      ("name the plan X", "call it Y") — carry it to step 5.

   If `$ARGUMENTS` is empty:

```
   Usage: /specl-plan <description>
   
   Examples:
     /specl-plan R3
     /specl-plan R3,R4 using Celery for the async flow
     /specl-plan background PDF generation for large documents
     /specl-plan R3 via Celery, name the plan ELF-7777-bg
```

2. Locate the current feature folder (same as specl-sync):
    - From the current directory.
    - From the prompt.
    - Or ask.

3. Check: `docs/features/<name>/spec.md` must exist. If not:

```
   spec.md not found in docs/features/<name>/.
   Create or extend the feature first: /specl-take <description>.
```

4. Determine the R list.

   **If the R are explicit** (found as `R<N>` in the text) — use them.

   **If R are inferred from meaning** (no explicit numbers) — read
   spec.md, match the text against R wording, and **always** request
   confirmation:

```
   Based on the description, the plan covers:
   - R3 [wip]  System MUST generate PDF in background for large docs
   - R5 [todo] System MUST support password-protected PDF
   
   Correct? [yes / list the right R comma-separated / cancel]
```

Validation (in both cases):

- Read spec.md, find every R.
- For each R in the list, check it exists.
- If missing:

```
     R5 not found in spec.md.
     Existing R: R1, R2, R3, R4.
```

    - If the R is already `[done]`:

```
     R3 is already marked [done]. Possible reasons to create a new plan:
     - A bug was discovered, rework needed
     - Refactoring without behavior change
     - Incorrect [done] mark, implementation is incomplete
     
     Continue creating the plan? [yes/no]
```

5. Determine the file name:
    - If `$ARGUMENTS` had an explicit name (from step 1) — use it.
    - Otherwise, auto-generate:
        - Format: `R<number>[-R<number>...]-<short-description>.md`
        - Short description — 2-4 words from the approach or the R
          wording.
        - Example: `R3-R4-background-generation.md`
    - Request confirmation:

```
     Plan name: R3-R4-background-generation.md
     Accept, or specify a different one?
```

6. Check: `docs/features/<name>/.plan/<name>.md` must not exist. If it
   does:

```
   Plan .plan/<name>.md already exists. Pick a different name or delete
   the existing one.
```

7. Read the template `docs/features/_template/plan.md`. Read spec.md
   (for R context) and tech.md (for architecture context). Fill in:
    - Strip the blockquote hints.
    - Header: `> Covers: R1, R2` (from the determined R list).
    - **Approach:** one paragraph on the approach.
        - If `$ARGUMENTS` included an approach — use it as the basis.
        - Factor in tech.md (components, `[planned]`, integrations).
        - Concrete details are welcome.
    - **Milestones:** break into steps of 30 min – 2 hours.
        - If the plan covers several R — group milestones:
          `### For R3 (...)`.
        - Add a Checkpoint after a group if the plan is long.
        - Mark `[P]` for independent milestones.
    - **Notes:** empty list `- ...`.

8. Drop the file at `docs/features/<name>/.plan/<name>.md`.

9. Print the summary:

```
   Plan created: docs/features/<name>/.plan/<name>.md
   Covers: R1, R2
   Milestones: N
   
   Recommend adding docs/features/*/.plan/ to .gitignore if you
   haven't already.
```
