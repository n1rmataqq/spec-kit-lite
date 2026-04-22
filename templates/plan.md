# <Feature name> — implementation plan

> 📝 An implementation plan for a whole feature or part of one.
> By default `.plan/` is a local working directory (recommended in
> `.gitignore`). Committing plans is an optional alternative if you
> want the implementation history in the repo.
> After merge the plan is either deleted, archived in
> `.plan/_archive/`, or left as is.
>
> Unlike spec.md and tech.md — a short-lived working artifact.
>
> File name:
> - If tied to a ticket: `ELF-7777-background-generation.md`
> - No ticket: `R3-background-generation.md`
    > *Delete when filled in.*

> Covers: R1, R2

> 📝 Covers lists the R numbers from spec.md in the same feature
> folder. The path isn't written — spec sits next to it, implicit.
> *Delete when filled in.*

## Approach

> 📝 One paragraph: how exactly these R are being built.
>
> Concrete details are welcome and needed: classes, methods, files,
> tables. This is an implementation document, not documentation.
>
> Good: "PdfExporter lands in modules/export/. New endpoint
> POST /documents/{id}/export. WeasyPrint via DI."
>
> Bad (repeats the spec): "Export to PDF."
> Bad (code): "class PdfExporter with render(doc: Document)..."
>
> ASCII trees, version tables, DB schemas — not here.
> *Delete when filled in.*

## Milestones

> 📝 Checkbox list of implementation steps.
>
> Rules:
> - Each milestone is a concrete verifiable step.
> - Size: 30 minutes – 2 hours of work.
> - Order top to bottom = the default sequence.
> - Commit after each milestone or logical group.
>
> Optional marks:
> - `[P]` — milestone is independent; ordering with other `[P]`
    >   doesn't matter.
    >   Example: `- [ ] [P] M4. Email template — doesn't depend on M3.`
> - Checkpoint: after a group of milestones for one R — a short
    >   validation scenario. Not for every group, only when the plan
    >   is long.
>
> TDD pattern (optional): the test is a separate milestone BEFORE
> the implementation, with an explicit `(FAIL)`:
>   - [ ] M2. Test: generate_pdf_async happy path (FAIL)
>   - [ ] M3. Implement generate_pdf_async
      > *Delete when filled in.*

- [ ] M1. ...
- [ ] M2. ...

## Notes

> 📝 Scratchpad. Anything that helps you work:
> - Oddities and edge cases you've found.
> - Links to docs, wiki.
> - Questions for yourself or the reviewer.
> - Chunks of code.
> - Decisions made along the way.
>
> Grows organically, no order required. Working notebook.
> *Delete when filled in.*

- ...
