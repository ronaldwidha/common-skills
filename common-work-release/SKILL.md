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

Created from [the release index template](assets/releases-index.md). It holds:

- **The published-baseline contract:** version, build, tag, and the evidence it
  actually shipped (tag, archive, deployment record, store metadata). It
  advances only on publication evidence, never on intent.
- **The current target:** version, build, branch, status.
- **Branch lines**, only when the repository maintains more than one (differing
  platform floors, distribution channels, deployment targets): each line, its
  branch, and what distinguishes it. Every release record says which line it
  describes.
- **The release index:** each target with its baseline, build, status, branch,
  and links to its records.

Point at the file that holds the canonical version declaration
(`package.json`, `project.yml`, `Cargo.toml`, ...).

## One folder per target: releases/<version>/

Create it as soon as a target version is assigned. It holds at least:

- `launch-requirements.md` from [the launch template](assets/launch-requirements.md):
  migration, compatibility, deployment, rollout, rollback, and verification
  gates from the baseline. Add gates as they are discovered. An open gate stays
  listed as a row with its status; a pending check is not an omission.
- `release-notes.md` from [the release-note template](assets/release-notes.md):
  the customer-facing and internal delta from that same baseline, accumulated as
  it is built. Customer-facing copy covers only shipped, enabled, verified
  behavior.

Keep whatever the release must ship with beside those records: store or
distribution listing copy, and generated launch assets such as screenshots.
Generate assets with a script kept in the repository, so a later version
reproduces them instead of recapturing by hand.

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
  build, date, source commit or tag, and artifact or deployment identity.

## Set up (used by common-project-setup)

If `releases/README.md` doesn't exist, create it from the template. Don't invent
a baseline: use verified tags, artifacts, deployment records, or store metadata,
or mark it unknown.

## Before finishing

Baseline and target versions are explicit where known, the baseline cites
publication evidence, each target names its branch (and its line where there is
more than one), and all record links resolve.
