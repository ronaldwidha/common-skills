---
name: common-work-start
description: Start, maintain, and complete a unit of work in this repository's worklog/ folder (intent.md, plan.md, output.md, and the worklog index). Use for any non-trivial change, before implementing it and again when it is done, or when reconciling work status.
---

# Work records

Keep durable project history that a future contributor can read cold. Status
follows evidence: never turn an uncertain observation into a fact, and keep
unknowns explicit.

Read `AGENTS.md` and `worklog/README.md` first, then open only the records you
need. Preserve unrelated changes and historical record paths. If the repository
already uses a different but coherent shape, adapt it going forward; don't
rename durable history just for uniformity.

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

## Complete

1. Create `output.md` from [the output template](assets/output.md): delivered
   outcome, what changed, evidence actually collected, bugs filed or fixed,
   regression assessment, release and migration impact, and remaining gates.
2. State the release impact, or say explicitly that the work has none. Don't
   invent customer-facing copy.
3. Reconcile `intent.md`, `plan.md`, `output.md`, linked bugs, and the index to
   the strongest evidence.

## Index and status

`worklog/README.md` lists every work item with status, a one-line summary, and
links. Update it whenever a record is created or its high-level status changes.
Statuses: proposed, in progress, implemented, merged, shipped in X.Y, or
abandoned, with useful qualifiers.

## Set up (used by common-project-setup)

If `worklog/README.md` doesn't exist, create it from
[the index template](assets/worklog-index.md) with an empty table. Seed rows only
for work supported by commits, tags, or evidence the user provides; don't invent
history.

## Before finishing

Check that links resolve, the index covers every record, and `git diff --check`
passes. For documentation-only changes, don't claim application tests; say why
structural checks are proportionate.
