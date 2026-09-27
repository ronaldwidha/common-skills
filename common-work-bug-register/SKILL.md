---
name: common-work-bug-register
description: Register, update, or resolve a bug or known limitation in this repository's bugs/ folder and keep bugs/README.md and its counts current. Use as soon as evidence shows a defect, when a bug's status changes, or when reconciling the bug index.
---

# Bug register

Record a defect the moment evidence shows it, not at the end of the work. A bug
record is durable: a future reader should understand what happened, how bad it
is, and what closes it without asking anyone.

Read `bugs/README.md` first and check whether the bug is already registered.

## What counts

Defects, material limitations, and correctness safeguards worth tracking (for
example a guard that hides a known problem). Not ideas or feature requests; those
belong in a work record.

## Register

1. Create `bugs/bug-<slug>-<id>/README.md` from [the bug template](assets/bug.md).
   Use a descriptive kebab-case slug plus 12 independently generated lowercase
   hex characters, the same ID rule as work records (no shared counter; never
   reuse or rename an ID).
2. Fill in: observed behavior, impact, evidence or repro (or "not yet
   reproduced"), containment in place, and the closure condition.
3. In the same change:
   - add the row to `bugs/README.md` and update the counts;
   - link the bug from the work record that found it, and link that record from
     the bug.

## Update and resolve

- Status values: open, open; blocks release, open; product limitation,
  resolved, won't fix, duplicate (with useful qualifiers).
- Mark a bug **resolved** only when there is both a fix and verification of it.
  Keep everything above and append a `## Resolution` section: what changed, the
  commit, and the check actually performed.
- On reopen or a material reclassification, update the status, the index row,
  and the counts in the same change.

## Set up (used by common-project-setup)

If `bugs/README.md` doesn't exist, create it from
[the index template](assets/bugs-index.md) with zero counts and an empty table.
Seed bugs only from evidence; don't invent history.

## Before finishing

Every bug folder has an index row, the counts match the rows, and links between
bugs and work records resolve.
