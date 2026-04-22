---
description: Take a description / ticket / URL — create a new feature or extend an existing one
---

# specl-take

Accepts a free-form description, Jira tickets, GitHub/GitLab issues & PR/MR,
Confluence pages, or URLs; classifies the input as either a new feature or
an extension of an existing one, and either scaffolds a feature folder
from scratch or appends new requirements to the existing `spec.md` /
`tech.md`.

## What to do

1. `$ARGUMENTS` — a description, Jira ticket, or URL. If empty:

```
   Usage: /specl-take <description | Jira ticket | URL>
   
   Examples:
     /specl-take Export document to PDF with A4/Letter format selection
     /specl-take ELF-7777
     /specl-take https://tango.atlassian.net/browse/ELF-7777
     /specl-take https://github.com/nexuslabsio/users/issues/42
     /specl-take https://github.com/nexuslabsio/users/pull/99
     /specl-take nexuslabsio/users#42
     /specl-take https://gitlab.com/acme/api/-/issues/123
     /specl-take ELF-7777 focus on A4/Letter, skip watermarks
   
   Ticket / link content is pulled automatically via Atlassian MCP,
   GitHub MCP, `gh` / `glab` CLI, or `WebFetch`.
```

2. Enrich the description from links and identifiers.

   If `$ARGUMENTS` contains a URL or a ticket identifier (e.g.,
   `ELF-7777`) — first pull the content, then use the result as the
   description in the following steps.

   What to recognize:
    - Any URL (`http://`, `https://`) — not restricted by domain.
    - Jira-style ticket-id: `[A-Z][A-Z0-9_]+-[0-9]+`.
    - GitHub / GitLab short-ref: `<owner>/<repo>#<number>`
      (e.g., `nexuslabsio/users#42`).

   Fetch order (per URL / ticket-id / short-ref):

    - **Atlassian** — a bare ticket-id, or a URL on `*.atlassian.net`,
      `*/browse/*`, `*/wiki/*`.
      Try Atlassian MCP first (`getJiraIssue`, `getConfluencePage`,
      `searchConfluenceUsingCql`) if connected; fallback — `WebFetch`.

    - **GitHub** — URL of the form `github.com/<owner>/<repo>/issues/<N>`
      or `.../pull/<N>`, or the short-ref `owner/repo#N`.
      Try GitHub MCP first (`mcp__github__issue_read`,
      `mcp__github__pull_request_read`) if connected; fallback —
      `gh issue view <N> --repo <owner>/<repo>` / `gh pr view <N> ...`
      via Bash; fallback — `WebFetch` (public repos only).

    - **GitLab** — URL of the form `*/<owner>/<repo>/-/issues/<N>` or
      `*/-/merge_requests/<N>` (gitlab.com and self-hosted).
      Try `glab issue view <N> --repo <owner>/<repo>` /
      `glab mr view <N> ...` via Bash first, if installed; fallback —
      `WebFetch` (public repos only).

    - **Other URLs** — `WebFetch` against the full URL.

    - If this is a bare ticket-id / short-ref and no matching tool is
      available:

   ```
   <ID> recognized (Jira / GitHub / GitLab), but neither the MCP nor
   the CLI is connected. Pass a full URL or paste the ticket text into
   the description directly.
   ```

    - If no tool returned any content:

   ```
   Cannot open <URL> (no tool available, no access to a private repo,
   or network error). Paste the ticket / doc text into the description
   directly:
   /specl-take <description text>
   ```

   If `$ARGUMENTS` contains both links/tickets and free-form text —
   merge the pulled content with the text as a single description.
   Free-form text wins on conflicts — it's closer to the user's intent.

   Keep the original URLs / ticket-ids — they'll go into **Links** when
   spec.md is created or extended.

3. Classify: new feature or extension of an existing one.

   Read every `docs/features/*/spec.md` (except `_template/`). Match the
   description (after enrichment) against each feature by:
    - Problem (subject area).
    - Wording of existing R.
    - Overview in tech.md (if present).

   Branching:

    - **No features** (empty `docs/features/` or only `_template/`) —
      go straight to step 4b (new), no questions.

    - **No semantic match.** Report and offer:

   ```
   No similar features found.
   Create a new feature? [yes / name of an existing one / cancel]
   ```

    - **One match.** Show the top candidate with evidence:

   ```
   Looks like a continuation of feature pdf-export:
     - R1 [done] User MUST be able to export document to PDF
     - R3 [todo] System MUST generate PDF in background
   
   Options:
     - extend pdf-export — add new R to the existing feature
     - new — create a new feature
     - other <name> — add to a different feature (specify the name)
     - cancel
   
   Pick: _
   ```

    - **Several strong matches.** Sort by descending relevance, show
      up to 3:

   ```
   Possible features to extend:
     1. pdf-export (matches R1, R3)
     2. document-sharing (matches R5)
   
   Options:
     - extend 1 / extend pdf-export
     - extend 2 / extend document-sharing
     - new
     - cancel
   ```

   If the user picked `extend <name>` or `other <name>` — check that
   `docs/features/<name>/` exists. If not:

   ```
   Folder docs/features/<name>/ not found.
   Existing features: <list>.
   ```

4. Branch by choice: `extend` — step 4a, `new` — step 4b.

   **4a. Extend — extend an existing feature.**

   Read `docs/features/<name>/spec.md` and
   `docs/features/<name>/tech.md`.

   **Update spec.md.**

   - Extract the new requirements from the enriched description (the
     business side).
   - Numbers — next free ones: take the max from existing R (continuous
     numbering across Must/Should/Could) and go +1, +2, ... Deleted
     numbers are never reused.
   - All new R — status `[todo]`.
   - Spread across Must / Should / Could — append to the end of each
     group.
   - If the description explicitly names Non-goals — add them.
   - New SC — under the corresponding R, continuous SC numbering.
   - New Open questions — add with markers (`[assumed: ...]` /
     `[NEEDS CLARIFICATION: ...]`).
   - Original URLs / ticket-ids from step 2 — into the Links section
     (create it if absent).

   **Do NOT touch in spec.md.**

   - Text and status of existing R.
   - Problem, Edge cases, existing Non-goals.
   - Existing Open questions (only append new ones).

   **Update tech.md.**

   - If the description includes tech details (components, integrations,
     tables, tools) — add list items with `[planned]` into the relevant
     sections: Key components, Integration points, Data model.
   - If the relevant section is missing in tech.md — create it
     (Data flows / Data model / Integration points are optional, added
     on demand).
   - Touch Overview only if a new R radically changes the architecture.
     When in doubt, leave it alone.

   **Do NOT touch in tech.md.**

   - Existing list items.
   - Decisions, Extension points.
   - Structure (that's updated by `/specl-sync` based on actual
     implementation).

   **Refactor-only description without new R.** If the description
   yields no new behavioral requirements (pure refactor, performance
   tuning, library swap without contract change) — ask:

   ```
   The description contains no new behavioral requirements.
   Options:
     - decision — add to Decisions in tech.md as an architectural decision
     - planned — add a [planned] component to tech.md
     - manual — /specl-take doesn't fit, edit spec/tech directly
     - cancel
   
   Pick: _
   ```

   **Confirmation.** Show the proposed diff and request confirmation:

   ```
   Changes in docs/features/<name>/:
   
   spec.md:
   + Must / Should / Could:
     + [todo] R5. System MUST ...
     + [todo] R6. User MUST be able to ...
   + Open questions:
     + [NEEDS CLARIFICATION: ...]
   + Links:
     + Jira: <URL>
   
   tech.md:
   + Integration points:
     + <Component> [planned] — <description>
   
   Apply? [yes/no]
   ```

   If `yes` — apply. If `no` — stop.

   **4b. New — create a new feature.**

   Analyze the description and propose a feature name:

   - Format: kebab-case, 2-4 words, captures the essence.
   - Based on the key action + object ("export to PDF" → `pdf-export`).
   - Not tied to a ticket (not `ELF-7777`).

   Ask for confirmation:

   ```
   Proposed feature name: <name>
   
   Continue with it? Or give another name (kebab-case, no spaces).
   ```

   Wait for the answer.

   Check: `docs/features/<name>/` must not exist. If it does:

   ```
   Folder docs/features/<name>/ already exists.
   If this is a continuation of the same feature — rerun /specl-take
   and pick `extend <name>` at step 3.
   Or pick a different name.
   ```

   Create `docs/features/<name>/` and an empty `.plan/`.

   **Populate spec.md** (from `docs/features/_template/spec.md`):

   - Strip every blockquote hint with the `📝` prefix.
   - **Problem:** 2-3 sentences on the pain and the audience.
     WHAT + WHY, not HOW.
   - **Requirements:**
       - Format: "System MUST ..." or "User MUST be able to ..."
       - All new R — status `[todo]`.
       - Continuous numbering R1, R2, R3, ...
       - Spread across Must/Should/Could. If unclear — Must.
       - Non-goals: fill only when the description explicitly names them.
   - **SC:** under R, only when there's a concrete measurable threshold.
     Continuous numbering: SC1, SC2, ...
   - **Edge cases:** delete the section if the description has no
     explicit edge cases.
   - **Open questions:**
       - No prefix — open questions up for discussion.
       - `[assumed: ...]` — implicit assumptions.
       - `[NEEDS CLARIFICATION: ...]` — critical gaps in the description.
   - **Links:** if the original `$ARGUMENTS` had a URL or Jira ticket —
     add them. Otherwise, delete the section.

   **Populate tech.md** (from `docs/features/_template/tech.md`).

   Strip the blockquote hints.

   Decide whether the description has tech details:

   - Mentions of libraries, frameworks, tools.
   - Architectural decisions.
   - Integrations with external systems.
   - Mentions of modules, code paths.

   **If tech details ARE present:**

   - **Overview:** 2-3 sentences on the feature's structure. No
     `[planned]`, phrase it naturally ("generation is planned via
     Celery").
   - **Structure:** if paths are named — add them with `[planned]`.
     Otherwise — the line `TBD — will be determined during
     implementation`.
   - **Key components:** intended components with `[planned]`.
   - **Data flows / Data model / Integration points:** fill in only
     what the description explicitly implies, with `[planned]`.
   - **Decisions:** key decisions from the description, no `[planned]`.
   - **Extension points:** optional.

   **If tech details are NOT present:**

   - Mandatory sections (Overview, Structure, Key components) contain
     the line `TBD — will be determined during implementation`.
   - Optional sections (Data flows, Data model, Integration points,
     Decisions, Extension points) are deleted.

5. Print the summary.

   **For extend:**

   ```
   Feature updated: docs/features/<name>/
   R added: R5, R6 (all [todo])
   [planned] added to tech.md: K
   New Open questions / [NEEDS CLARIFICATION]: M
   
   Next:
   - If there are [NEEDS CLARIFICATION] items — clarify them.
   - To create an implementation plan — /specl-plan <description>.
   ```

   **For new:**

   ```
   Created:
   - docs/features/<name>/spec.md
   - docs/features/<name>/tech.md
   - docs/features/<name>/.plan/
   
   Requirements: N (all [todo])
   Components with [planned] in tech.md: M  (if > 0)
   Open questions / [NEEDS CLARIFICATION]: K
   
   Next:
   - If there are [NEEDS CLARIFICATION] items — clarify them.
   - To create an implementation plan — /specl-plan <description>.
   ```
