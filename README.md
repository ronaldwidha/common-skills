# common-skills

My general workflow skills for coding projects. They are versioned here and copied to where agents read them
(Codex, Claude Code, Cursor, Kiro). Every skill here has the `common-` prefix.

## Depends on

- **[common-agents](../common-agents)**. It creates `~/.agents/skills/` and points each agent at it. Run its
  installer first (`common-agents install`). Without it, `install.sh` stops and says so.
- **`common-agent-setup`** comes with common-agents, not with this repo. It sets up one repository's agent
  adapters (`AGENTS.md`, `CLAUDE.md`, `.agents/skills`). `common-project-setup` runs it first.

## Skills

| Skill | Scope | What it does |
|---|---|---|
| `common-project-setup` | global | Sets up or reconciles a **coding** project. It runs `common-agent-setup`, sets up `.gitignore`, copies the three lifecycle skills below into the project, creates `worklog/`, `bugs/` and `releases/` with their indexes, and adds the lifecycle section to `AGENTS.md`. It also migrates repositories from the old `project-lifecycle` / `project-records` skills. It coordinates the other skills and holds no record rules itself. |
| `common-work-start` | project | How to work in `worklog/<slug>-<id>/`: `intent.md` before starting, `plan.md` before implementing, `output.md` when done. Also the ID rule, the worklog index, and evidence proportional to regression risk. |
| `common-work-bug-register` | project | How to register a bug in `bugs/bug-<slug>-<id>/README.md`: what to record, linking it to the work item, resolving it only with a verified fix, and keeping `bugs/README.md` and its counts current. |
| `common-work-release` | project | How to keep `releases/` current: the published-baseline contract and release index in `releases/README.md`, and `launch-requirements.md` and `release-notes.md` for each target version, updated alongside the work. |

**Global** skills are copied into `~/.agents/skills` and are available in every folder. **Project** skills are listed
in `project-skills.txt` and are copied only into the coding projects that use them, at `<repo>/.agents/skills/`.
Folders that aren't coding projects never see them.

Each template (intent, plan, output, bug, indexes, launch requirements, release notes) belongs to exactly one skill.
No rule is written in two places.

## Install and update (zsh)

```zsh
cd ~/Coding/common-skills
./install.sh check                        # what would change; changes nothing
./install.sh                              # global skills -> ~/.agents/skills
./install.sh --project ~/Coding/my-app    # project skills -> ~/Coding/my-app/.agents/skills
./install.sh uninstall [--project <dir>]  # remove the copies this repo installed there
tests/run.zsh                             # install.sh tests (scratch HOME; never touches ~/.agents)
```

- **Copies, not links.** After editing a skill here, run `./install.sh` again (and `--project <dir>` for each project
  you want to update). The agents only see the copies.
- **Edit here, not in the copies.** If an installed copy was edited in place, `install.sh` stops and tells you,
  instead of overwriting the edit.
- **What it records:**
  - Installed copies go in a manifest: `~/.common-agents/installed/common-skills.tsv` for global skills, or
    `<repo>/.agents/installed/common-skills.tsv` for a project. Commit the project's manifest with its copies, so
    any Mac can update them.
  - The global install also records where this repo lives, in `~/.common-agents/installed/common-skills.source`.
    That's how `common-project-setup` finds `install.sh`.
  - Anything it replaces or removes is kept in `~/.common-agents/backups/<timestamp>-common-skills[-<project>]/`.
- The same `install.sh` is used in [meetpi-skills](../meetpi-skills). Keep the two copies identical.

## Adding a skill

1. Create `<name>/SKILL.md`. The folder name must start with `common-` and match the `name:` field.
2. If it should only be available in coding projects, add its name to `project-skills.txt`.
3. Keep skills flat: no `SKILL.md` below the top-level folder (store skill templates as e.g. `assets/<name>-skill.md`),
   and no symlinks inside a skill.
4. Run `./install.sh` (and `--project` where needed), then start a new agent session to see the skill.
