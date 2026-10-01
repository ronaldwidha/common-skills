# Releases

Each target version's records describe the delta from the published baseline below. Version declaration:
`<path/to/file>` <!-- package.json, project.yml, Cargo.toml, ... -->.

## Published baseline

- **Version:** <X.Y.Z, or unknown>
- **Build:** <build number, or —>
- **Published:** <YYYY-MM-DD>
- **Source:** <tag> → <commit>
- **Evidence:** <store record, archive, deployment ID, or tag; never intent>

## What's in the field

- **Stores and schemas:** <names and versions, or none>
- **Preference / config keys:** <keys, or none>
- **Cloud and server state:** <containers, zones, record types, tables, subscriptions, or none>
- **Formats and entry points:** <file formats, URL schemes, public APIs, entitlements, or none>

## Compatibility rules

- <Standing rule for changing the state above.>

## Release index

| Version | Build | From | Branch | Line | Status | Records |
|---|---|---|---|---|---|---|

<!-- Index rules (from common-work-release; keep this comment in the file).

Shape: exactly these sections in this order: Published baseline, What's in the field, Compatibility rules, (Branch
lines, only if the repository has more than one), Release index. Keep every field line; write "unknown" or "none"
instead of deleting one. Don't add, remove, rename, or reorder table columns. Detail belongs in the version folders.

Published baseline: changes only in the change that records publication evidence. What's in the field lists only
what that baseline shipped; a target's additions stay in its launch-requirements.md until it is published.

Columns:
- Version: X.Y.Z, newest first. One row per target, including published and folded ones.
- Build:   build number, or — if not assigned.
- From:    the published baseline this target's delta starts from (X.Y.Z).
- Branch:  `release/X.Y.Z` or the branch it is built on; — for old releases where it's unknown.
- Line:    the branch line from the Branch lines table, or — when there is only one line.
- Status:  Planned | In development | Candidate | Published | Folded into X.Y.Z. Nothing else; open gates are listed
           in launch-requirements.md, not here.
- Records: [launch](X.Y.Z/launch-requirements.md) · [notes](X.Y.Z/release-notes.md). Historical versions link the files
           they actually have, under their existing names.

Branch lines (add above the Release index only when there is more than one line):

## Branch lines

| Line | Branch | Distinguishing constraint |
|---|---|---|
| main | `main` | iOS 18+, App Store |

Example rows:
| 2.1.0 | 31 | 2.0.0 | `release/2.1.0` | — | In development | [launch](2.1.0/launch-requirements.md) · [notes](2.1.0/release-notes.md) |
| 2.0.0 | 24 | 1.0.0 | `release/2.0.0` | — | Published | [launch](2.0.0/launch-requirements.md) · [notes](2.0.0/release-notes.md) |
| 1.0.0 | 12 | — | — | — | Published | [notes](1.0.0/RELEASE_NOTES.md) |
-->
