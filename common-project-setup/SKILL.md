---
name: common-project-setup
description: Set up or reconcile a coding project - agent adapters, .gitignore, worklog/bugs/releases folders and indexes, the project lifecycle skills, and the lifecycle section in AGENTS.md. Use when asked to set up a new or existing repository, apply the standard project lifecycle, or migrate a repository from the old project-lifecycle/project-records skills.
---

# Project setup

Turn a repository into a coding project that follows the standard lifecycle,
without erasing project-specific rules or starting a parallel tracking system.
This skill only coordinates; the record rules live in the three lifecycle
skills it installs.

## 0. Is this a coding project?

The lifecycle skills are for software projects only. If the folder is not one
(notes, a document vault, a personal folder), stop after step 2 and tell the
user: they get shared agent instructions, but no lifecycle skills or record
folders.

## 1. Audit first

Inspect, without changing anything:

- `git status` (preserve unrelated changes; treat existing content as the user's);
- root and nested `AGENTS.md` / `CLAUDE.md`, `.agents/`, `.claude/`, and any
  project skills;
- existing worklog, bug, changelog, migration, launch, and release files;
- `.gitignore`, version declarations, tags, and published or deployed baselines.

Skip generated dependencies and build output. Choose a mode:

- **New repository:** create everything with empty indexes; invent no history.
- **Existing, no records:** set up, then seed only facts supported by commits,
  tags, artifacts, or evidence the user provides.
- **Existing, with records:** reconcile in place. Keep stable IDs and paths, add
  compatibility pointers instead of rewrites, and adopt the rules going forward.

If two instruction sources materially conflict, stop and ask which one governs.
Formatting differences and compatible conventions don't need approval.

## 2. Agent adapters

Run the `common-agent-setup` skill for this repository (canonical `AGENTS.md`,
`CLAUDE.md` adapter, `.agents/skills/`). It comes with common-agents. If it isn't
available, stop and tell the user to install common-agents; don't hand-roll the
adapters.

## 3. .gitignore

Create or extend `.gitignore`. Never remove or reorder the user's entries; add
only what's missing, under a short comment.

- Always: the entries in [the base list](assets/gitignore-base.txt) (OS and
  editor files, local secrets such as `.env`, local agent settings).
- Plus what the detected stack produces, for example `node_modules/`, `dist/`,
  `build/`, `coverage/` (Node); `.venv/`, `__pycache__/` (Python);
  `DerivedData/`, `*.xcuserstate`, `xcuserdata/` (Xcode); `target/` (Rust).
- Never ignore `.agents/`, `worklog/`, `bugs/`, `releases/`, `AGENTS.md`,
  `CLAUDE.md`, or `.claude/skills`. They are the shared, tracked setup.

If a file that should be ignored is already tracked (for example `.env`), tell
the user; don't untrack it yourself.

## 4. Lifecycle skills

Copy the lifecycle skills into the project:

```zsh
zsh "$(cat ~/.common-agents/installed/common-skills.source)/install.sh" --project "<repo>"
```

This installs `common-work-start`, `common-work-bug-register` and
`common-work-release` into `<repo>/.agents/skills/`, plus
`.agents/installed/common-skills.tsv`. Commit both with the project. If the
`.source` file is missing, common-skills isn't installed on this Mac; tell the
user. If `install.sh` reports a conflict, show it to the user and stop.

## 5. Record folders

Follow the **Set up** section of each installed skill (read them in
`<repo>/.agents/skills/`):

- `common-work-start` creates `worklog/README.md`;
- `common-work-bug-register` creates `bugs/README.md`;
- `common-work-release` creates `releases/README.md`, with the published baseline
  taken from evidence or marked unknown.

## 6. AGENTS.md

Add the lifecycle section and the layout entries from
[the AGENTS.md section](assets/agents-section.md), adapted to the repository's
existing structure. Keep it short: the skills hold the detail.

## 7. Migrating from the old skills

Earlier setups copied `.agents/skills/project-lifecycle/` into the repository
and referred to `project-lifecycle` or `project-records` in `AGENTS.md`.

1. Compare the old `project-lifecycle/SKILL.md` with the new skills. Move any
   repository-specific rules into `AGENTS.md`; ask first if it isn't clear
   whether a difference is intentional.
2. Remove `.agents/skills/project-lifecycle/` (once step 4 has installed the
   replacements) and update `AGENTS.md` references to the new skill names.
3. Other home-made lifecycle skills in the repository (for example a
   worklog/bug tracker): list them to the user and ask whether they are
   replaced. Don't remove them unasked.
4. Existing records stay valid as they are. Numbered or otherwise nonstandard
   records keep their paths; only new records follow the ID rule.

## 8. Verify

- `install.sh check --project "<repo>"` reports up to date.
- `worklog/README.md`, `bugs/README.md`, and `releases/README.md` exist, and
  their indexes cover every existing record (bug counts match).
- `AGENTS.md` has the lifecycle section, and `CLAUDE.md` reaches it.
- Relative links resolve, no generated or local state became tracked, and
  `git diff --check` passes.

For a non-trivial reconciliation, create a work record with
`common-work-start` and finish it with `output.md`. Don't commit unless asked.
