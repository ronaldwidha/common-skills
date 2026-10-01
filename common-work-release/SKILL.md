---
name: common-work-release
description: Keep this repository's releases/ folder current - the published baseline and release index in releases/README.md, and launch-requirements.md and release-notes.md for each target version. Use when work has a target version, a version is assigned, a migration or launch gate appears, or a release is published.
---

# Release records

`releases/` is a living draft, not a changelog written at the end. Each target
version's records describe the delta from the last **published** baseline to
that target, and are updated in the same change as the work they describe, so
they never need reconstructing from memory.

Read `releases/README.md` first.

## releases/README.md

Created from [the release index template](assets/releases-index.md). **Follow
the template exactly:** its sections, field lines, and table columns, in its
order, and keep its rules comment in the file. Write `unknown` or `none` instead
of dropping a field. It holds:

- **Published baseline:** version, build, date, source tag and commit, and the
  evidence it actually shipped (store record, archive, deployment ID). It
  advances only on publication evidence, never on intent.
- **What's in the field:** the inventory of everything the published baseline
  left on users' devices, accounts, or servers that a later release must read or
  migrate and never silently drop: stores and schemas, preference or config
  keys, cloud containers and record types, file formats, URL schemes,
  entitlements, public APIs.
- **Compatibility rules:** the project's standing rules for changing that state
  (for example "schema changes are additive", "never rename the store").
- **Branch lines**, only when the repository maintains more than one (differing
  platform floors, distribution channels, deployment targets): each line, its
  branch, and what distinguishes it. Every release record says which line it
  describes.
- **The release index:** one row per target, newest first: version, build,
  baseline it starts from, branch, line, status (`Planned`, `In development`,
  `Candidate`, `Published`, or `Folded into X.Y.Z`), and links to its records.
  Open gates live in `launch-requirements.md`, not in the row.

The first lines point at the file that holds the canonical version declaration
(`package.json`, `project.yml`, `Cargo.toml`, ...).

This is the one home for the baseline, the inventory, and the rules. `AGENTS.md`
only points here ("read `releases/README.md` before changing persisted data");
it doesn't restate them. State that an unpublished target adds goes in that
target's `launch-requirements.md` and moves into the inventory when the target
is published.

## One folder per target: releases/<version>/

Create it as soon as a target version is assigned. It holds at least:

- `launch-requirements.md` from [the launch template](assets/launch-requirements.md):
  migration, compatibility, deployment, rollout, rollback, and verification
  gates from the baseline. Add gates as they are discovered. An open gate stays
  listed as a row with its status; a pending check is not an omission.
- `release-notes.md` from [the release-note template](assets/release-notes.md):
  the customer-facing and internal delta from that same baseline, accumulated as
  it is built. Customer-facing copy covers only shipped, enabled, verified
  behavior. **This is the running change log** for the target: don't keep a
  second one elsewhere (a `worklog/release-X.md`, a draft `CHANGELOG.md`). If the
  project also publishes a changelog, fill it from these notes at publication.

Keep whatever the release must ship with beside those records: store or
distribution listing copy, policy pages, and generated launch assets such as
screenshots. Generate assets with a script kept in the repository, so a later
version reproduces them instead of recapturing by hand.

Mind the repository's size. Commit the script, its inputs, and the final upload
set when it's small; don't commit intermediate renders or large media (video,
PSD) a script can regenerate. If large binaries must be kept, use Git LFS or
store them outside the repository and link them, and say which in
`releases/README.md`.

Historical versions keep the files they have, whatever their names (for example
an old `RELEASE_NOTES.md`); the index links them as they are. New targets use
the names above.

## Rules

- **Migrations** preserve legacy data, are idempotent when retried, and record
  completion only after success. If no migration is needed, record the audit
  basis instead of leaving the question open.
- **Branches:** name the branch after the version once one is assigned.
- **Build numbers** are global per distribution identity. When two lines share
  one, allocate monotonically across both.
- **Unpublished targets** are not deleted. Fold an implemented-but-unpublished
  target's delta into the next target, say so in both records, and carry its
  open gates forward.
- **Publication:** advance the baseline only with evidence: exact version and
  build, date, source commit or tag, and artifact or deployment identity. In the
  same change, move the target's new persisted state into *What's in the field*.

## Set up (used by common-project-setup)

If `releases/README.md` doesn't exist, create it from the template, keeping
every section and field line. Don't invent
a baseline: use verified tags, artifacts, deployment records, or store metadata,
or mark it unknown.

When reconciling, rewrite an existing `releases/README.md` into the template's
shape (add rows for historical versions, linking their files as they are), and
move a baseline, state inventory, or compatibility rules found
in `AGENTS.md` (or elsewhere) into `releases/README.md` and leave a one-line
pointer behind. Fold a separate running change log into the target's
`release-notes.md` and remove it once nothing is lost; ask first if the two
disagree.

## Before finishing

`releases/README.md` still has the template's shape, baseline and target
versions are explicit where known, the baseline cites
publication evidence, the field inventory reflects the published baseline only,
each target names its branch (and its line where there is more than one), and
all record links resolve.
