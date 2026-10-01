# common-skills

**Give your coding agents a memory that outlives the chat.**

common-skills is a small set of agent skills that make every change leave a trail: what you meant to do, how you planned it, what actually shipped, and what broke along the way. It works with Codex, Claude Code, Cursor, and Kiro, all reading the same skills.

## Why

Chats end, context windows reset, and six months later nobody remembers why that function looks the way it does. Not you, and not your agent.

These skills keep a plain-Markdown record of each piece of work right inside the repository. You can read it to understand how the project got here. Your agent reads it too, so it can reason about past decisions instead of guessing from the diff.

### You don't write these files. Your agent does.

`intent.md`, `plan.md`, and `output.md` aren't paperwork. Keep working with your agent however you like. It already works out the intent, makes a plan, and checks the result. These skills just have it save that thinking to a file instead of letting it vanish with the chat.

That also saves money. Thinking is output tokens, the expensive kind. Reading earlier thinking back from a file is input tokens, which are usually much cheaper. So a later session reads the reasoning instead of producing it all over again.

## How it works

Three folders, each with a simple index, cover the whole lifecycle:

- **`worklog/`: small units of work, not a big upfront spec.** No long specification written before any code. Each piece of work is small and gets its own folder: `intent.md` (what and why), `plan.md` (how, just for this piece), and `output.md` (what shipped and how it was verified). `worklog/README.md` lists every item with a one-word status.
- **`releases/`: where small pieces come together.** Some work does need to line up with a bigger milestone, like an App Store version or a launch. A release folder tracks which pieces of work make up that version. Its change log grows as each piece lands, so `release-notes.md` is already written when you ship. Keep release material there too: App Store notes, store descriptions, marketing copy.
- **`bugs/`: a parking lot.** A bug found halfway through a task is a distraction. Fixing it on the spot pulls you and your agent off course. Log it in `bugs/` and keep the context on the work in front of you. Nothing gets lost, and `bugs/README.md` shows what's open at a glance.

### What a project looks like

After `/common-project-setup`, a project looks like this (the work items, bugs, and versions are examples):

```
my-app/
├── AGENTS.md                         # shared instructions; points agents at the skills
├── CLAUDE.md                         # adapter so Claude Code reads AGENTS.md
├── .gitignore
├── .agents/
│   ├── skills/                       # lifecycle skills, copied in by install.sh
│   │   ├── common-work-start/
│   │   ├── common-work-bug-register/
│   │   └── common-work-release/
│   └── installed/
│       └── common-skills.tsv         # what was installed, so it can be updated
├── worklog/
│   ├── README.md                     # index: Work | Status | Target | Summary
│   ├── decisions.md                  # standing decisions that outlive one item
│   ├── add-offline-sync-3f9a1c2b7d4e/
│   │   ├── intent.md                 # what and why
│   │   ├── plan.md                   # how, for this piece only
│   │   └── output.md                 # what shipped, and the evidence
│   └── fix-login-redirect-a1b2c3d4e5f6/
│       ├── intent.md
│       ├── plan.md
│       └── output.md
├── bugs/
│   ├── README.md                     # index: Bug | Status | Severity | Summary
│   └── bug-crash-on-empty-list-9e8d7c6b5a43/
│       └── README.md                 # what happened, impact, what closes it
└── releases/
    ├── README.md                     # published baseline, what's in the field, release index
    └── 2.0.0/
        ├── launch-requirements.md    # migration, rollout, and verification gates
        ├── release-notes.md          # change log, built up as work lands
        └── app-store/                # listing copy, screenshots, marketing material
```

## Get started

Install [common-agents](https://github.com/ronaldwidha/common-agents) (optional, best results) and this repo once (see [Install and update](#install-and-update)). Then, in any project, ask your coding agent to run:

```
/common-project-setup
```

It sets up the agent adapters, `.gitignore`, the three record folders, and the lifecycle section in `AGENTS.md`, all in one pass. It works on new repositories, and it can bring existing ones into line. To copy just the skills by hand, use `./install.sh --project <dir>`.

## Works out of the box with Codex and Cursor

The skills follow the shared convention: instructions in `AGENTS.md`, skills in `.agents/skills/`. Codex and Cursor read both natively, so common-agents is optional for them. `install.sh` creates `.agents/skills/` if it's missing, and `/common-project-setup` carries on without `common-agent-setup`.

Claude Code and Kiro don't read that layout on their own. Claude Code wants a `CLAUDE.md` and `.claude/skills`; Kiro needs its own agent config. **For the best result, and for those two, use [common-agents](https://github.com/ronaldwidha/common-agents).** Its `common-agent-setup` skill adds thin adapters (for example `CLAUDE.md` with `@AGENTS.md`, and a `.claude/skills` link to `.agents/skills`) without copying anything. `/common-project-setup` runs it automatically when it's installed.

## Depends on

- **A POSIX shell and common Unix tools**, on macOS or Linux. `install.sh` and the tests are plain `sh` scripts (they use `find`, `sed`, `awk`, `cp`, and `sha256sum` or `shasum`). The skills themselves are plain Markdown and work anywhere an agent reads them. I've run the tests on macOS only; Linux should work but is untested.
- **[common-agents](https://github.com/ronaldwidha/common-agents)** is optional but recommended. It sets up `~/.agents/skills/` and points each agent at it, and provides `common-agent-setup`. Without it, `install.sh` creates the folders it needs, and the skills work in Codex and Cursor.

## Skills

| Skill | Scope | What it does |
|---|---|---|
| `common-project-setup` | global | Sets up or reconciles a **coding** project. It runs `common-agent-setup`, sets up `.gitignore`, copies the three lifecycle skills below into the project, creates `worklog/`, `bugs/` and `releases/` with their indexes, and adds the lifecycle section to `AGENTS.md`. It also migrates repositories from the old `project-lifecycle` / `project-records` skills. It coordinates the other skills and holds no record rules itself. |
| `common-work-start` | project | How to work in `worklog/<slug>-<id>/`: `intent.md` before starting, `plan.md` before implementing, `output.md` when done, and how every item closes. Also the ID rule, the worklog index, `worklog/decisions.md`, and evidence proportional to regression risk. |
| `common-work-bug-register` | project | How to register a bug in `bugs/bug-<slug>-<id>/README.md`: what to record, linking it to the work item, resolving it only with a verified fix, and keeping `bugs/README.md` and its counts current. |
| `common-work-release` | project | How to keep `releases/` current: the published baseline, what's in the field (persisted state), compatibility rules, and the release index in `releases/README.md`; `launch-requirements.md` and `release-notes.md` (the running change log) for each target version, updated alongside the work. |

**Global** skills are copied into `~/.agents/skills` and are available in every folder. **Project** skills are listed in `project-skills.txt` and are copied only into the coding projects that use them, at `<repo>/.agents/skills/`. Folders that aren't coding projects never see them.

Each template (intent, plan, output, bug, indexes, decisions, launch requirements, release notes) belongs to exactly one skill. No rule is written in two places: a project's `AGENTS.md` only points at the skills.

The three indexes are all `README.md` (`worklog/`, `bugs/`, `releases/`), so a folder view shows them. The worklog and bug indexes share one shape: one line per item, a one-word status (`Open` / `Resolved` / …), a counts line, and no evidence in the rows. Agents read them at the start of every task, so they stay small.

## Install and update

```sh
git clone https://github.com/ronaldwidha/common-skills.git && cd common-skills
./install.sh check                        # what would change; changes nothing
./install.sh                              # global skills -> ~/.agents/skills
./install.sh --project ~/Coding/my-app    # project skills -> ~/Coding/my-app/.agents/skills
./install.sh uninstall [--project <dir>]  # remove the copies this repo installed there
tests/run.sh                              # install.sh tests (scratch HOME; never touches ~/.agents)
```

- **Copies, not links.** After editing a skill here, run `./install.sh` again (and `--project <dir>` for each project you want to update). The agents only see the copies.
- **Edit here, not in the copies.** If an installed copy was edited in place, `install.sh` stops and tells you, instead of overwriting the edit. Project-specific rules go in the project's `AGENTS.md`, never in a copy; that keeps every project on the same version.
- **Finding stale projects:** each project that has the skills also has a manifest, so this checks them all (change `~/Coding` to where your projects live):

  ```sh
  for m in ~/Coding/*/.agents/installed/common-skills.tsv; do [ -e "$m" ] && ./install.sh check --project "$(dirname "$(dirname "$(dirname "$m")")")"; done
  ```
- **What it records:**
  - Installed copies go in a manifest: `~/.common-agents/installed/common-skills.tsv` for global skills, or `<repo>/.agents/installed/common-skills.tsv` for a project. Commit the project's manifest with its copies, so any machine can update them.
  - The global install also records where this repo lives, in `~/.common-agents/installed/common-skills.source`. That's how `common-project-setup` finds `install.sh`.
  - Anything it replaces or removes is kept in `~/.common-agents/backups/<timestamp>-common-skills[-<project>]/`.
- Other skills repos can reuse the same `install.sh` unchanged; keep the copies identical.

## Adding a skill

1. Create `<name>/SKILL.md`. The folder name must start with `common-` and match the `name:` field.
2. If it should only be available in coding projects, add its name to `project-skills.txt`.
3. Keep skills flat: no `SKILL.md` below the top-level folder (store skill templates as e.g. `assets/<name>-skill.md`), and no symlinks inside a skill.
4. Run `./install.sh` (and `--project` where needed), then start a new agent session to see the skill.

## Status and contributions

This is my personal workflow, shared as-is. It's opinionated, so it may not suit every team. Issues and pull requests are welcome, but I may not accept changes that don't fit how I work. Run `tests/run.sh` before sending a change to `install.sh`.

## License

[MIT](LICENSE). Anyone can use, copy, modify, and distribute this.
