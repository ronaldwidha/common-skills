#!/bin/sh
# install.sh: copy this repo's skills to where agents read them. Deterministic; no LLM.
# POSIX sh; runs on macOS and Linux (needs find, sed, awk, cp, mv, and sha256sum or shasum).
#
#   ./install.sh [install|check|uninstall]                  global skills  -> ~/.agents/skills
#   ./install.sh [install|check|uninstall] --project <dir>  project skills -> <dir>/.agents/skills
#
#   install    add or update copies, then print what changed (default)
#   check      show what would change; exit 0 up to date, 4 changes pending, 2 conflict
#   uninstall  remove the copies this repo installed (only copies nobody edited)
#
# A skill is a top-level folder containing SKILL.md. Skills named in project-skills.txt are
# project skills: they are only copied into projects (--project), never into ~/.agents/skills.
# Everything else is a global skill.
#
# Each copy's content hash is kept in a manifest: ~/.common-agents/installed/<repo>.tsv for
# global skills, <dir>/.agents/installed/<repo>.tsv for a project (commit it with the project
# so any machine can update the copies). Only copies this script made, and nobody edited since,
# are updated or removed. Anything replaced or removed is moved to
# ~/.common-agents/backups/<timestamp>-<repo>[-<project>]/, never deleted.
#
# The same file can be used by any skills repo that follows this layout; keep the copies identical.
set -u

TAB=$(printf '\t')
NL='
'
REPO=$(cd "$(dirname "$0")" && pwd -P) || exit 1
NAME=$(basename "$REPO")
STATE=${COMMON_AGENTS_STATE:-$HOME/.common-agents}
PROJECT=''
DEST=$HOME/.agents/skills
MANIFEST=$STATE/installed/$NAME.tsv
BK_TAG=$NAME

if [ -t 1 ]; then
  ESC=$(printf '\033'); G="$ESC[32m"; R="$ESC[31m"; D="$ESC[2m"; O="$ESC[0m"
else G=''; R=''; D=''; O=''; fi
say()  { printf '%s\n' "$*"; }
disp() { case $1 in "$HOME"*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }
ok()   { say "  ${G}✓${O} $*"; }
info() { say "  ${D}·${O} $*"; }
bad()  { say "  ${R}✗${O} $*"; }
die()  { printf 'install.sh: %s\n' "$*" >&2; exit 1; }

usage() { say "Usage: ./install.sh [install|check|uninstall] [--project <dir>]   (repo: $NAME)"; }

if command -v sha256sum >/dev/null 2>&1; then sha() { sha256sum; }
elif command -v shasum >/dev/null 2>&1; then sha() { shasum -a 256; }
else die "need sha256sum or shasum"; fi

# Hash of a skill folder: paths, executable bit and contents (.DS_Store ignored). Only the
# executable bit is hashed, not the full mode, so checkouts with a different umask still match.
tree_hash() {
  ( cd -- "$1" && find . \( -type f -o -type l \) ! -name .DS_Store | LC_ALL=C sort | while IFS= read -r f; do
      if [ -L "$f" ]; then printf 'L %s %s\n' "$f" "$(readlink "$f")"
      else
        if [ -x "$f" ]; then x=x; else x=-; fi
        printf 'F %s %s %s\n' "$f" "$x" "$(sha < "$f" | cut -c1-64)"
      fi
    done ) | sha | cut -c1-64
}

HAVE=''          # lines "skill<TAB>hash": what this repo last installed here
SKILLS=''        # space-separated skill names this run manages
PROJECT_SKILLS=''
OPS=''           # lines "op<TAB>skill<TAB>message"
CONFLICTS=''     # lines
NCONF=0

get_have() { printf '%s\n' "$HAVE" | awk -F"$TAB" -v n="$1" '$1 == n { print $2; exit }'; }
unset_have() { HAVE=$(printf '%s\n' "$HAVE" | awk -F"$TAB" -v n="$1" '$1 != n && NF'); }
set_have() { unset_have "$1"; HAVE=$HAVE$NL$1$TAB$2; }
have_names() { printf '%s\n' "$HAVE" | awk -F"$TAB" 'NF { print $1 }' | LC_ALL=C sort; }
in_list() { case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
conflict() { CONFLICTS=$CONFLICTS$NL$1; NCONF=$((NCONF + 1)); }
op() { OPS=$OPS$NL$1$TAB$2$TAB$3; }
exists() { [ -e "$1" ] || [ -L "$1" ]; }

load() {
  if [ -f "$REPO/project-skills.txt" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      line=$(printf '%s' "${line%%#*}" | tr -d '[:space:]')
      [ -n "$line" ] && PROJECT_SKILLS="$PROJECT_SKILLS $line"
    done < "$REPO/project-skills.txt"
  fi
  for n in $PROJECT_SKILLS; do
    [ -f "$REPO/$n/SKILL.md" ] || conflict "project-skills.txt lists '$n', but there is no $n/SKILL.md"
  done
  if [ -f "$MANIFEST" ]; then
    while IFS="$TAB" read -r n h; do [ -n "$n" ] && set_have "$n" "$h"; done < "$MANIFEST"
  fi
  for d in "$REPO"/*/; do
    d=${d%/}
    [ -f "$d/SKILL.md" ] || continue
    n=$(basename "$d")
    # project mode takes only project skills; global mode takes everything else
    if [ -n "$PROJECT" ]; then in_list "$n" "$PROJECT_SKILLS" || continue
    else ! in_list "$n" "$PROJECT_SKILLS" || continue; fi
    case $n in -*|*[!a-z0-9-]*) conflict "$n: folder name must be lowercase letters, digits and dashes"; continue ;; esac
    v=$(sed -n 's/^name:[[:space:]]*//p' "$d/SKILL.md" | head -1)
    [ "$v" = "$n" ] || conflict "$n: SKILL.md says 'name: $v'; it must match the folder name"
    [ -z "$(find "$d" -name SKILL.md ! -path "$d/SKILL.md")" ] || conflict "$n: has a nested SKILL.md; skills must be flat (rename templates, e.g. assets/<name>-skill.md)"
    [ -z "$(find "$d" -type l)" ] || conflict "$n: contains symlinks; installed copies must be self-contained"
    SKILLS="$SKILLS $n"
  done
}

plan_remove() { # skill reason
  pr_n=$1
  pr_h=$(get_have "$pr_n")
  if ! exists "$DEST/$pr_n"; then op forget "$pr_n" "forget $pr_n (already gone)"
  elif [ "$(tree_hash "$DEST/$pr_n")" = "$pr_h" ]; then op remove "$pr_n" "remove $pr_n ($2)"
  else conflict "$(disp "$DEST/$pr_n") was edited after it was installed; left alone. Move it away by hand if unwanted, then rerun"; fi
}

plan_install() {
  for n in $SKILLS; do
    hs=$(tree_hash "$REPO/$n")
    have=$(get_have "$n")
    if ! exists "$DEST/$n"; then op copy "$n" "add $n"; continue; fi
    hd=$(tree_hash "$DEST/$n")
    if [ "$hd" = "$hs" ]; then
      [ "$have" = "$hs" ] || op adopt "$n" "record $n (already identical)"
    elif [ -n "$have" ] && [ "$hd" = "$have" ]; then op update "$n" "update $n"
    elif [ -n "$have" ]; then
      conflict "$(disp "$DEST/$n") was edited after it was installed. Copy your edits into $(disp "$REPO/$n") (or move the folder away), then rerun"
    else
      conflict "$(disp "$DEST/$n") already exists and was not installed from $NAME. Compare with: diff -r '$REPO/$n' '$DEST/$n'"
    fi
  done
  for n in $(have_names); do
    in_list "$n" "$SKILLS" && continue
    if [ -n "$PROJECT" ]; then kind=project; else kind=global; fi
    plan_remove "$n" "not a $kind skill in $NAME any more"
  done
}

write_manifest() { # from HAVE, atomically
  tmp=$MANIFEST.tmp
  mkdir -p "$(dirname "$MANIFEST")" || return 1
  : > "$tmp" || return 1
  for n in $(have_names); do printf '%s\t%s\n' "$n" "$(get_have "$n")" >> "$tmp"; done
  if [ -n "$(have_names)" ]; then mv -- "$tmp" "$MANIFEST"
  else rm -f -- "$tmp" "$MANIFEST"; rmdir "$(dirname "$MANIFEST")" 2>/dev/null; fi
  return 0
}

# Global installs record where this repo lives, so skills (e.g. common-project-setup) can
# find install.sh on any machine: $(cat ~/.common-agents/installed/<repo>.source)/install.sh
write_source() {
  [ -z "$PROJECT" ] || return 0
  if [ -n "$(have_names)" ]; then mkdir -p "$STATE/installed" && printf '%s\n' "$REPO" > "$STATE/installed/$NAME.source"
  else rm -f -- "$STATE/installed/$NAME.source"; fi
}

apply() {
  stg=$STATE/staging
  bk=$STATE/backups/$(date +%Y%m%d-%H%M%S)-$BK_TAG
  mkdir -p "$stg" "$DEST" || die "cannot create $(disp "$stg") or $(disp "$DEST")"
  while IFS="$TAB" read -r o n msg; do
    [ -n "$o" ] || continue
    case $o in
      copy|update)
        if [ "$o" = update ]; then mkdir -p "$bk" && mv -- "$DEST/$n" "$bk/$n" || { bad "failed: $msg"; return 1; }; fi
        { rm -rf -- "${stg:?}/$n" && cp -R -- "$REPO/$n" "$stg/$n" && find "$stg/$n" -name .DS_Store -exec rm -f {} + && mv -- "$stg/$n" "$DEST/$n"; } \
          || { bad "failed: $msg"; return 1; }
        set_have "$n" "$(tree_hash "$DEST/$n")" ;;
      adopt)  set_have "$n" "$(tree_hash "$DEST/$n")" ;;
      remove) mkdir -p "$bk" && mv -- "$DEST/$n" "$bk/$n" || { bad "failed: $msg"; return 1; }; unset_have "$n" ;;
      forget) unset_have "$n" ;;
    esac
    write_manifest || die "cannot write $(disp "$MANIFEST")"
    ok "$msg"
  done <<EOF
$OPS
EOF
  rmdir "$stg" 2>/dev/null
  [ -d "$bk" ] && info "previous copies saved in $(disp "$bk")"
  return 0
}

main() {
  cmd=install
  while [ $# -gt 0 ]; do
    case $1 in
      install|check|uninstall) cmd=$1 ;;
      --project) [ $# -ge 2 ] || die "--project needs a directory"; PROJECT=$2; shift ;;
      -h|--help|help) usage; return 0 ;;
      *) usage >&2; return 1 ;;
    esac
    shift
  done
  if [ -n "$PROJECT" ]; then
    [ -d "$PROJECT" ] || die "project folder not found: $PROJECT"
    PROJECT=$(cd "$PROJECT" && pwd -P)
    DEST=$PROJECT/.agents/skills
    MANIFEST=$PROJECT/.agents/installed/$NAME.tsv
    BK_TAG=$NAME-$(basename "$PROJECT")
  fi
  load
  if [ -n "$PROJECT" ] && [ -z "$PROJECT_SKILLS" ]; then die "$NAME has no project skills (see project-skills.txt)"; fi
  if [ "$cmd" = uninstall ]; then
    for n in $(have_names); do plan_remove "$n" uninstall; done
  else
    plan_install
  fi

  say "$NAME -> $(disp "$DEST")"
  if [ "$NCONF" -gt 0 ]; then
    while IFS= read -r c; do [ -n "$c" ] && bad "$c"; done <<EOF
$CONFLICTS
EOF
    say "Stopped: $NCONF conflict(s). Nothing was changed."
    return 2
  fi
  if [ -z "$OPS" ]; then
    [ "$cmd" = install ] && write_source
    say "Up to date ($(set -- $SKILLS; echo $#) skill(s))."; return 0
  fi
  if [ "$cmd" = check ]; then
    while IFS="$TAB" read -r o n msg; do [ -n "$o" ] && info "would $msg"; done <<EOF
$OPS
EOF
    return 4
  fi
  mkdir -p "$STATE" || die "cannot create $(disp "$STATE")"
  mkdir "$STATE/lock" 2>/dev/null || die "another common-agents run holds $(disp "$STATE/lock") (remove it if stale)"
  trap 'rmdir "$STATE/lock" 2>/dev/null' EXIT
  apply || { say "Stopped partway; rerun to finish (finished steps are recorded)."; return 1; }
  write_source
  say "Done."
}

main "$@"
exit $?
