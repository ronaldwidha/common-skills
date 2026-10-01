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

Skip generated dependencies and build output.

If uncommitted changes touch instructions or records (`AGENTS.md`, `CLAUDE.md`,
`.agents/`, `worklog/`, `bugs/`, `releases/`), stop and ask the user to commit or
stash them first, so the reconciliation is one reviewable diff.

List, for the user, anything record-like outside the standard folders: running
change logs, decision logs, requirement documents, launch checklists, policy
pages, stray output folders, and large media committed in records. Propose a
home for each (the owning skill says where), and move nothing without a yes.

Choose a mode:

- **New repository:** create everything with empty indexes; invent no history.
- **Existing, no records:** set up, then seed only facts supported by commits,
  tags, artifacts, or evidence the user provides.
- **Existing, with records:** reconcile in place. Keep stable IDs and paths, add
  compatibility pointers instead of rewrites, and adopt the rules going forward.

If two instruction sources materially conflict, stop and ask which one governs.
Formatting differences and compatible conventions don't need approval.

## 2. Agent adapters

If the `common-agent-setup` skill is available (it comes with common-agents), run
it for this repository (canonical `AGENTS.md`, `CLAUDE.md` adapter,
`.agents/skills/`). That gives the best result: Codex, Claude Code, Cursor and
Kiro all read the same files.

If it isn't available, don't stop. Codex and Cursor read `AGENTS.md` and
`.agents/skills/` natively, so create or reconcile `AGENTS.md` at the repository
root and let `install.sh --project` create `.agents/skills/`. Tell the user that
Claude Code and Kiro need the adapters from common-agents (`CLAUDE.md` with
`@AGENTS.md`, a `.claude/skills` link) and offer to add them later.

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

```sh
sh "$(cat ~/.common-agents/installed/common-skills.source)/install.sh" --project "<repo>"
```

This installs `common-work-start`, `common-work-bug-register` and
`common-work-release` into `<repo>/.agents/skills/`, plus
`.agents/installed/common-skills.tsv`. Commit both with the project. If the
`.source` file is missing, common-skills isn't installed on this machine; tell the
user. If `install.sh` reports a conflict, show it to the user and stop.

Never edit these copies to fit the project; that is how per-project copies
drift apart. Project-specific rules go in `AGENTS.md`, and changes to the rules
themselves go into common-skills, then out to every project with `install.sh`.

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
existing structure. It only points at the skills; it restates none of their
rules, because `AGENTS.md` is loaded into every session and a restated rule
drifts from its skill.

If `AGENTS.md` already has a lifecycle, records, or workflow section, **replace**
it with this one rather than adding a second. Keep only rules that are unique to
the repository (for example which test devices to use) and aren't already in a
skill. A published baseline, field-state inventory, or compatibility rules in
`AGENTS.md` move to `releases/README.md` (see `common-work-release`), leaving the
pointer from the section.

## 7. Migrating from the old skills

Earlier setups copied `.agents/skills/project-lifecycle/` into the repository
and referred to `project-lifecycle` or `project-records` in `AGENTS.md`.

1. Compare the old `project-lifecycle/SKILL.md` with the new skills. Move any
   repository-specific rules into `AGENTS.md` (only if no skill already covers
   them); ask first if it isn't clear whether a difference is intentional.
2. Remove `.agents/skills/project-lifecycle/` (once step 4 has installed the
   replacements) and update `AGENTS.md` references to the new skill names.
3. Other home-made lifecycle skills in the repository (for example a
   worklog/bug tracker): list them to the user and ask whether they are
   replaced. Don't remove them unasked. Also list project skills whose job
   overlaps a global skill (for example a project `appstore-screenshots` next
   to a global screenshots skill), so the user can decide which one agents
   should pick.
4. Existing records stay valid as they are. Numbered or otherwise nonstandard
   records keep their paths; only new records follow the ID rule.
5. Convert the three indexes to the current shape (one-word status, one-line
   rows, counts), following each skill's **Set up** section.

## 8. Verify

- `install.sh check --project "<repo>"` reports up to date.
- `worklog/README.md`, `bugs/README.md`, and `releases/README.md` exist, and
  their indexes cover every existing record (counts match; bug `Status:` lines
  agree with the index).
- `AGENTS.md` has exactly one lifecycle section, it restates no skill rule, and
  `CLAUDE.md` reaches it.
- Relative links resolve, no generated or local state became tracked, and
  `git diff --check` passes.

For a non-trivial reconciliation, create a work record with
`common-work-start` and finish it with `output.md`. Don't commit unless asked.
