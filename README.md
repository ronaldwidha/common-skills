# common-skills

My general workflow skills for coding projects. They are versioned here and copied into the shared skill folder
`~/.agents/skills/`, where every agent reads them: Codex, Claude Code, Cursor and Kiro. Every skill here has the
`common-` prefix.

## Depends on

- **[common-agents](../common-agents)**. It creates `~/.agents/skills/` and points each agent at it. Run its
  installer first (`common-agents install`). Without it, `install.sh` stops and says so.
- **`common-agent-setup`** comes with common-agents, not with this repo. It sets up one repository's agent
  adapters (`AGENTS.md`, `CLAUDE.md`, `.agents/skills`). `common-project-setup` runs it first.

## Skills

Status: **planned**. They will be built from the current `project-setup` and `project-records` skills, which stay in
use until these replace them.

| Skill | What it does |
|---|---|
| `common-project-setup` | Sets up or reconciles a coding project. It runs `common-agent-setup`, adds `.gitignore`, creates `worklog/`, `bugs/` and `releases/` with their index files, and adds the lifecycle section to `AGENTS.md`. It coordinates the skills below and holds no record rules itself. |
| `common-work-start` | How to work in `worklog/<slug>-<id>/`: `intent.md` before starting, `plan.md` before implementing, `output.md` when done. Also covers the ID rule, the worklog index, and evidence proportional to regression risk. |
| `common-work-bug-register` | How to register a bug in `bugs/bug-<slug>-<id>/README.md`: what to record, linking it to the work item, and keeping `bugs/README.md` and its counts current. |
| `common-work-release` | How to keep `releases/` current: the published-baseline contract and release index in `releases/README.md`, and `launch-requirements.md` and `release-notes.md` for each version, updated alongside the work. |

Each template (intent, plan, output, bug, indexes, launch requirements, release notes) belongs to exactly one of these
skills. No rule is written in two places.

## Install and update (zsh)

```zsh
cd ~/Coding/common-skills
./install.sh check       # what would change; changes nothing
./install.sh             # copy new or changed skills into ~/.agents/skills
./install.sh uninstall   # remove the copies this repo installed
tests/run.zsh            # install.sh tests (scratch HOME; never touches ~/.agents)
```

- **Copies, not links.** After editing a skill here, run `./install.sh` again. The agents only see the copy.
- **Edit here, not in `~/.agents/skills`.** If an installed copy was edited in place, `install.sh` stops and tells you,
  instead of overwriting the edit.
- `install.sh` records what it installed in `~/.common-agents/installed/common-skills.tsv`. It updates or removes only
  those copies. Anything it replaces or removes is kept in `~/.common-agents/backups/<timestamp>-common-skills/`.
- The same `install.sh` is used in [meetpi-skills](../meetpi-skills). Keep the two copies identical.

## Adding a skill

1. Create `<name>/SKILL.md`. The folder name must start with `common-` and match the `name:` field.
2. Keep skills flat: no `SKILL.md` below the top-level folder (store skill templates as e.g. `assets/<name>-skill.md`),
   and no symlinks inside a skill.
3. Run `./install.sh`, then start a new agent session to see the skill.
