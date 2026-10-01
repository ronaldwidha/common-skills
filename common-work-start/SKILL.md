---
name: common-work-start
description: Start, maintain, and complete a unit of work in this repository's worklog/ folder (intent.md, plan.md, output.md, the worklog index, and the decisions log). Use for any non-trivial change, before implementing it and again when it is done, when recording a standing decision, or when reconciling work status.
---

# Work records

Keep durable project history that a future contributor can read cold. Status
follows evidence: never turn an uncertain observation into a fact, and keep
unknowns explicit.

Read `AGENTS.md`, `worklog/README.md`, and `worklog/decisions.md` first, then
open only the records you need. Preserve unrelated changes and historical record
paths. If the repository already uses a different but coherent shape, adapt it
going forward; don't rename durable history just for uniformity.

## When to create a record

Create one when the work is non-trivial enough that a future reader could ask
why the system behaves this way. Trivial fixes (a typo, a one-line obvious bug)
don't need one.

## IDs

Each record lives in `worklog/<slug>-<id>/`: a descriptive kebab-case slug plus
12 independently generated lowercase hex characters, for example
`improve-export-reliability-a1b2c3d4e5f6` (a UUID is a convenient source). Never
scan for or allocate a shared sequence number: parallel worktrees must be able
to create records without coordinating. Never reuse, rename, or delete an ID.

## Start

1. Create `intent.md` from [the intent template](assets/intent.md) **before
   implementation**: requested outcome, scope, constraints, starting status,
   target release or `Unassigned`, and known related bugs.
2. Add the worklog index row in the same change.
3. Create `plan.md` from [the plan template](assets/plan.md) before
   implementation: requirements, design, regression strategy,
   migration/release assessment, decisions worth keeping, and concrete
   acceptance gates.

## During work

- Found a defect or material limitation? Register it now with the
  `common-work-bug-register` skill and link it from this record. Don't postpone
  it to the end.
- Prevent regressions in proportion to risk. Add or update focused coverage when
  practical and run the relevant existing checks. Say what kind of evidence you
  have (unit, integration, simulator, device, production, archive, manual).
  Pending checks stay listed as explicit gates.
- If the work has a target version, keep that version's release records current
  in the same change, using the `common-work-release` skill.
- Evidence files (screenshots, logs, renders) may sit in the record folder when
  they are small. Don't commit large media (video, PSD, full capture sets) or
  output a script regenerates; keep the script and name the output path instead.

## Complete

1. Create `output.md` from [the output template](assets/output.md): delivered
   outcome, what changed, evidence actually collected, bugs filed or fixed,
   regression assessment, release and migration impact, and remaining gates.
2. State the release impact, or say explicitly that the work has none. Don't
   invent customer-facing copy.
3. Reconcile `intent.md`, `plan.md`, `output.md`, linked bugs, and the index to
   the strongest evidence.

### Closing an item

Every item ends **Resolved** or **Abandoned**; none stays open just because a
check is pending.

- **Resolved:** `output.md` exists and no gate is left only in this record.
  Hand each remaining check to the place that owns it, with a link: a launch
  gate in `releases/<version>/launch-requirements.md` when a release depends on
  it, otherwise a bug. Then the item can close.
- **Abandoned:** stopped or superseded. Still write a short `output.md`: why,
  what replaced it (link), and anything salvaged.
- Work that shipped also gets an `output.md`, even if it was written late.

## Index: worklog/README.md

`README.md`, like `bugs/README.md` and `releases/README.md`, so the index is what
a folder view shows. Created from [the index template](assets/worklog-index.md).
**Follow the template exactly:** its counts line and its four columns, no extra
columns or sections, and keep its rules comment in the file.

- One row per work item, Open rows first, then newest first: link, **Status**,
  **Target**, one-sentence summary.
- **Status is one word**: `Open`, `Resolved`, or `Abandoned` (see *Closing an
  item*). The detailed state (proposed, in progress, implemented, merged,
  shipped in X.Y) lives on the `Status:` line of `intent.md` / `output.md`.
- **Target** is the release version, or `—`.
- The summary says what the work is, not its evidence (under 120 characters).
  Commits, test results, branches, and pending checks belong in `output.md`.
  Agents read this index at the start of every task, so keep each row to one
  line.
- The counts line matches the rows.

Update the index in the same change whenever a record is created or its Status
changes.

## Decisions: worklog/decisions.md

A decision that should shape future work but isn't a unit of work (a scope cut,
a platform choice, a policy) goes in `worklog/decisions.md`, from
[the decisions template](assets/decisions.md), newest first. A decision made
inside a work item stays in that item's `plan.md` and gets a decisions entry
only if it outlives the item. Link the file from the top of `worklog/README.md`.

## Set up (used by common-project-setup)

If `worklog/README.md` doesn't exist, create it from
[the index template](assets/worklog-index.md) with an empty table. Seed rows only
for work supported by commits, tags, or evidence the user provides; don't invent
history. Also create `worklog/decisions.md` from
[the decisions template](assets/decisions.md) (the index links it).

When reconciling an existing index, rewrite it into the template's exact shape:
one-word statuses, the Target column, one-line summaries, the counts line. Move
evidence, commits, and branches out of the rows into `output.md` (or drop them
if `output.md` already has them). Don't rename record folders.

## Before finishing

Check that the index still has the template's shape, links resolve, the index
covers every record, the counts match, and `git diff --check` passes. For
documentation-only changes, don't claim application tests; say why structural
checks are proportionate.
