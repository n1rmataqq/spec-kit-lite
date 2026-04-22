---
description: Execute an implementation plan from .plan/ — walk the milestones, stop at checkpoints
---

# specl-go

Executes an implementation plan: walks the milestones, writes code,
marks completed milestones `[x]` in the plan file.

Never commits automatically — the user always decides on commits.

## What to do

1. Parse `$ARGUMENTS` — a single free-form text (every part optional).
   From it derive:
    - **Plan name** — a substring matching a file in `.plan/`
      (with or without `.md`). If no match — see step 4.
    - **Mode** — keywords in the text:
        - `resume` / `continue` → when `[x]` milestones exist, skip
          the question (step 7) and continue from the first
          non-completed one.
        - `restart` / `redo` → clear every `[x]` without asking and
          run from the top.
    - **Hints** — everything else: extra guidance for the agent
      ("don't touch tests, I'll do them myself", "use AWS SDK v3",
      "focus on M3-M5"). Keep them in context while working on each
      milestone.

   Examples:
    - `/specl-go` — shows the list of plans
    - `/specl-go R3-R4-background` — runs that specific plan
    - `/specl-go R3-R4-background resume` — continue without asking
    - `/specl-go redo` — restart (plan is picked at step 4)
    - `/specl-go R3-R4-background use AWS SDK v3, don't touch tests`

2. Locate the current feature folder:
    - If the user is in `docs/features/<name>/` — use it.
    - If the prompt names a feature — use that.
    - If unclear — ask:

```
     Can't tell which feature to run the plan in.
     Available: <list of docs/features/ folders>
     Give me the feature name.
```

3. Check: `docs/features/<name>/.plan/` must exist and contain at
   least one plan. If empty:

```
   No plans in docs/features/<name>/.plan/.
   Create one: /specl-plan <description>
```

4. Determine which plan to execute:
    - If the plan name was recognized (from step 1) — look for a file
      with that name (with or without `.md`). If not found — show the
      list of available plans and ask to clarify.
    - If no name was recognized — show the list and ask:

```
     Plans available in docs/features/<name>/.plan/:
     1. R3-R4-background-generation.md
     2. R5-password-protection.md
     
     Pick a number or name: _
```

5. Read the selected plan, `spec.md`, `tech.md` for context.

6. Show the plan and request confirmation:

```
   Plan: R3-R4-background-generation.md
   Covers: R3, R4
   Milestones: 7 (4 in group R3, 3 in group R4)
   Checkpoints: 2 (after R3, after R4)
   
   Approach:
   <first 2-3 sentences of Approach>
   
   Run execution? [yes/no]
```

If `no` — stop.

7. If the plan already has `[x]` milestones:

    - If a mode was given in `$ARGUMENTS` (from step 1):
        - `resume` / `continue` → continue from the first
          non-completed milestone without asking.
        - `restart` / `redo` → clear every `[x]` without asking, run
          from the top.
    - If no mode was given — ask:

```
     The plan already has completed milestones: M1, M2, M3.
     Options:
     - continue — continue from the first non-completed (M4)
     - redo     — start over (every [x] is cleared)
     - cancel   — cancel
     
     Pick: _
```

8. Execution:

   Walk the milestones in order (ignore `[P]` marks — order is top to
   bottom). If hints were extracted from `$ARGUMENTS` (step 1) — keep
   them in context as additional constraints while working on each
   milestone. For each milestone:

    - Implement the milestone: write the code, touch the needed files.
    - On success, update the plan file: `- [ ]` → `- [x]`.
    - Report to the user that the milestone is done (short, one line):

```
     ✓ M3. Implement generate_pdf_async → modules/export/tasks.py
```

Stops:

- **At a Checkpoint** (a line like `**Checkpoint R3:**` after a group
  of milestones) — stop and ask:

```
     Checkpoint R3: submit → poll → download for a 150-page doc.
     
     Completed milestones: M1, M2, M3, M4, M5.
     
     Commit the current progress? [yes/no]
     Continue with the next group? [yes/no]
```

     - If the user chose to commit — propose a commit message based
       on the completed milestones, wait for confirmation or edits.
       Never commit without explicit confirmation.
     - If they chose not to continue — stop.

- **At the end of a logical block without a Checkpoint** (e.g., the
  milestones for one R are done and the next R's milestones begin) —
  also ask about commit and continuation.

- **On an error** (compile, test, runtime) — stop, show the error,
  ask:

```
     Error while running M5:
     <error text>
     
     Options:
     - retry  — try again
     - skip   — mark as [x] and move on (not recommended)
     - fix    — describe what to fix
     - stop   — stop execution
```

9. After the final milestone:

```
   Plan complete: 7 of 7 milestones.
   
   Commit the final changes? [yes/no]
   
   Next:
   - Update R statuses in spec.md and tech.md: /specl-sync
   - The plan stays in .plan/ — delete or keep it, your call.
```

## Rules

- **Never commit without explicit confirmation.** The agent may
  propose a commit message and ask — but the final decision and the
  actual `git commit` happen only after a `yes` from the user.
- **Always mark `[x]`** on successful milestone completion. If the
  work on a milestone crashed mid-way — no `[x]`.
- **`[P]` marks** (parallel) are ignored in MVP — we go in order.
- **Stop priority:** error > checkpoint > end of logical block >
  nothing (keep going).
