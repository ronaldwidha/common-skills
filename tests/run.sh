#!/bin/sh
# Tests for install.sh. Each case uses a scratch HOME and a scratch copy of the repo;
# the real ~/.agents is never touched.   Run: tests/run.sh
SRC=$(cd "$(dirname "$0")/.." && pwd -P)/install.sh
ROOT=$(mktemp -d "${TMPDIR:-/tmp}/skills-install-test.XXXXXX") || exit 1
trap 'rm -rf -- "${ROOT:?}"' EXIT
PASS=0; FAIL=0; RC=0

is() {
  d=$1; shift
  if "$@"; then PASS=$((PASS + 1)); printf '  ok    %s\n' "$d"
  else FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$d"; sed 's/^/        | /' "$ROOT/out" | tail -20; fi
}
case_() { printf '\n== %s\n' "$*"; }
# fresh <name>: scratch HOME ($H) with ~/.agents/skills, scratch repo ($P) holding install.sh
fresh() { H=$ROOT/$1/home; P=$ROOT/$1/repo-skills; mkdir -p "$H/.agents/skills" "$P"; cp "$SRC" "$P/install.sh"; }
skill() { mkdir -p "$P/$1"; printf -- '---\nname: %s\ndescription: t\n---\n%s\n' "$1" "${2:-body}" > "$P/$1/SKILL.md"; }
run() { env -i HOME="$H" PATH="$PATH" /bin/sh "$P/install.sh" "$@" > "$ROOT/out" 2>&1; RC=$?; }
rc()  { [ "$RC" = "$1" ]; }
has() { grep -qF -- "$1" "$ROOT/out"; }
not() { ! "$@"; }
same() { diff -r -x .DS_Store "$P/$1" "$H/.agents/skills/$1" > /dev/null; }
backed_up() { ls -d "$H"/.common-agents/backups/*-"$1" > /dev/null 2>&1; }

case_ "A. no common-agents: ~/.agents/skills is created"
fresh A; rm -rf $H/.agents; skill one
run check;                   is "check: exit 4" rc 4
is "check creates nothing" [ ! -e $H/.agents ]
run;                         is "exit 0" rc 0
is "skill installed" same one

case_ "B. install, idempotent rerun, update, remove, uninstall"
fresh B; skill one; skill two; mkdir -p $P/two/scripts; printf '%s\n' "x" > $P/two/scripts/a.sh; chmod +x $P/two/scripts/a.sh
touch $P/one/.DS_Store; mkdir -p $P/docs; printf '%s\n' "notes" > $P/docs/README.md     # not a skill: no SKILL.md
run check;                   is "check before install: exit 4" rc 4
is "check changes nothing" [ -z "$(ls -A $H/.agents/skills)" ]
run;                         is "install exit 0" rc 0
is "one copied" same one
is "two copied with scripts" same two
is "executable bit kept" [ -x $H/.agents/skills/two/scripts/a.sh ]
is ".DS_Store not copied" [ ! -e $H/.agents/skills/one/.DS_Store ]
is "non-skill folder ignored" [ ! -e $H/.agents/skills/docs ]
is "manifest written" [ -f $H/.common-agents/installed/repo-skills.tsv ]
run;                         is "rerun: up to date" has "Up to date (2 skill(s))"
run check;                   is "check after install: exit 0" rc 0
skill one "body v2"
run;                         is "source edit: updated" has "update one"
is "update copied" same one
is "old copy backed up" backed_up repo-skills/one
rm -rf $P/two
run;                         is "skill removed from repo: removed" [ ! -e $H/.agents/skills/two ]
run uninstall;               is "uninstall exit 0" rc 0
is "uninstall removed one" [ ! -e $H/.agents/skills/one ]
is "manifest gone" [ ! -e $H/.common-agents/installed/repo-skills.tsv ]
is "lock released" [ ! -e $H/.common-agents/lock ]

case_ "C. conflicts stop before changing anything"
fresh C; skill one; skill two
run
printf '%s\n' "local edit" >> $H/.agents/skills/one/SKILL.md; skill two "v2"
run;                         is "edited installed copy: exit 2" rc 2
is "explains the edit" has "was edited after it was installed"
is "other skill not updated either" not same two
run uninstall;               is "uninstall keeps the edited copy: exit 2" rc 2
is "edited copy still there" grep -q "local edit" $H/.agents/skills/one/SKILL.md
fresh C2; skill one; mkdir -p $H/.agents/skills/one; printf '%s\n' "other" > $H/.agents/skills/one/SKILL.md
run;                         is "foreign skill with same name: exit 2" rc 2
is "foreign copy untouched" grep -qx other $H/.agents/skills/one/SKILL.md
fresh C3; skill one; cp -R $P/one $H/.agents/skills/one
run;                         is "identical existing copy: adopted" has "record one (already identical)"
run uninstall;               is "adopted copy is managed" [ ! -e $H/.agents/skills/one ]

case_ "D. skill validation"
fresh D; skill good; mkdir -p $P/bad; printf -- '---\nname: other\n---\n' > $P/bad/SKILL.md
run;                         is "name mismatch: exit 2" rc 2
is "explains name rule" has "must match the folder name"
is "nothing installed" [ -z "$(ls -A $H/.agents/skills)" ]
fresh D2; skill tpl; mkdir -p $P/tpl/assets/inner; printf '%s\n' "x" > $P/tpl/assets/inner/SKILL.md
run;                         is "nested SKILL.md: exit 2" rc 2
fresh D3; skill lnk; ln -s /etc/hosts $P/lnk/hosts
run;                         is "symlink inside skill: exit 2" rc 2

case_ "E. project skills (--project)"
fresh E; skill glob; skill work-a; skill work-b
printf '# copied into projects only\nwork-a\nwork-b  # trailing comment\n' > $P/project-skills.txt
PR=$ROOT/E/proj; mkdir -p $PR
run check --project $PR;     is "no .agents/skills in project: check exit 4" rc 4
is "check creates nothing" [ ! -e $PR/.agents ]
run;                         is "global install exit 0" rc 0
is "global skill installed" same glob
is "project skills not installed globally" [ ! -e $H/.agents/skills/work-a ]
is "source recorded" [ "$(cat $H/.common-agents/installed/repo-skills.source)" = "$(cd "$P" && pwd -P)" ]
run check --project $PR;     is "project check: exit 4" rc 4
run --project $PR;           is "project install exit 0" rc 0
is "work-a in project" diff -r $P/work-a $PR/.agents/skills/work-a
is "work-b in project" diff -r $P/work-b $PR/.agents/skills/work-b
is "global skill not in project" [ ! -e $PR/.agents/skills/glob ]
is "manifest kept in the project" [ -f $PR/.agents/installed/repo-skills.tsv ]
run --project $PR;           is "project rerun: up to date" has "Up to date (2 skill(s))"
skill work-a "v2"
run --project $PR;           is "project update" has "update work-a"
is "project backup tagged with project name" backed_up repo-skills-proj/work-a
chmod 600 $PR/.agents/skills/work-b/SKILL.md
run check --project $PR;     is "mode change other than exec bit is not an edit" rc 0
run uninstall --project $PR; is "project uninstall" [ -z "$(ls -A $PR/.agents/skills)" ]
is "project manifest dir cleaned up" [ ! -e $PR/.agents/installed ]
is "global copy untouched by project uninstall" same glob
: # a skill that becomes project-only is removed from ~/.agents/skills on the next global install
printf '%s\n' "glob" >> $P/project-skills.txt
run;                         is "moved to project-skills: removed globally" [ ! -e $H/.agents/skills/glob ]
is "source file removed when nothing is installed" [ ! -e $H/.common-agents/installed/repo-skills.source ]
printf '%s\n' "missing" >> $P/project-skills.txt
run --project $PR;           is "listed project skill missing: exit 2" rc 2
fresh E2; skill glob
run --project $ROOT/E2;      is "repo without project-skills.txt: exit 1" rc 1

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
