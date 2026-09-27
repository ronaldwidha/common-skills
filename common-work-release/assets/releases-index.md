# Releases

Release records describe the delta from the last verified published baseline to
one assigned target version. The canonical version declarations live in
<!-- point at the real file: package.json, project.yml, Cargo.toml, ... -->.

Each target's directory is created when the target is assigned and updated
alongside the work, not written at release time.

## Published baseline

- **Version:**
- **Build:**
- **Tag:**
- **Evidence:** <!-- tag, archive, deployment record, or store metadata -->

This baseline changes only when a later published build is verified from
durable evidence. Intent to ship is not evidence.

## Current target

- **Version:**
- **Build:**
- **Branch:**
- **Status:** <!-- declared / implemented / submitted / published, and what remains -->

<!-- Delete this section if there is no target in flight. -->

## Branch lines

<!-- Only when the repository maintains more than one line. Build numbers are
     global per distribution identity, so lines sharing one allocate
     monotonically across both rather than each keeping its own sequence. -->

| Line | Branch | Distinguishing constraint |
| --- | --- | --- |

## Release index

| Version | Build | Line | Status | Records |
| --- | --- | --- | --- | --- |

<!-- Row format:
| 2.0.0 | 42 | default | Target, unpublished | [launch requirements](2.0.0/launch-requirements.md) · [release notes](2.0.0/release-notes.md) |
-->
