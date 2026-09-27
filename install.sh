#!/bin/zsh
# install.sh: copy this repo's skills to where agents read them. Deterministic; no LLM.
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
# so any Mac can update the copies). Only copies this script made, and nobody edited since,
# are updated or removed. Anything replaced or removed is moved to
# ~/.common-agents/backups/<timestamp>-<repo>[-<project>]/, never deleted.
#
# The same file is used by every skills repo (common-skills, meetpi-skills); keep them identical.
emulate -R zsh
setopt no_unset pipe_fail

REPO=${0:A:h}
NAME=${REPO:t}
STATE=${COMMON_AGENTS_STATE:-$HOME/.common-agents}
PROJECT=''
DEST=$HOME/.agents/skills
MANIFEST=$STATE/installed/$NAME.tsv
BK_TAG=$NAME

if [[ -t 1 ]]; then G=$'\e[32m' R=$'\e[31m' D=$'\e[2m' O=$'\e[0m'; else G='' R='' D='' O=''; fi
disp() { local p=$1; [[ $p == $HOME* ]] && p="~${p#$HOME}"; print -r -- $p; }
ok()   { print -r -- "  ${G}✓${O} $*"; }
info() { print -r -- "  ${D}·${O} $*"; }
bad()  { print -r -- "  ${R}✗${O} $*"; }
die()  { print -r -- "install.sh: $*" >&2; exit 1; }

usage() {
  print -r -- "Usage: ./install.sh [install|check|uninstall] [--project <dir>]   (repo: $NAME)"
}

# Hash of a skill folder: paths, executable bit and contents (.DS_Store ignored). Only the
# executable bit is hashed, not the full mode, so checkouts with a different umask still match.
tree_hash() {
  ( cd -- $1 && find . \( -type f -o -type l \) ! -name .DS_Store | LC_ALL=C sort | while IFS= read -r f; do
      if [[ -L $f ]]; then print -r -- "L $f $(readlink -- $f)"
      else print -r -- "F $f $([[ -x $f ]] && print x || print -) $(shasum -a 256 < $f | cut -c1-64)"; fi
    done ) | shasum -a 256 | cut -c1-64
}

typeset -A HAVE      # skill -> hash recorded when this repo last installed it here
typeset -a SKILLS PROJECT_SKILLS OPS MSGS CONFLICTS

load() {
  local n h d v line
  if [[ -f $REPO/project-skills.txt ]]; then
    while IFS= read -r line; do
      line=${line%%\#*}; line=${line//[[:space:]]/}
      [[ -n $line ]] && PROJECT_SKILLS+=($line)
    done < $REPO/project-skills.txt
  fi
  for n in $PROJECT_SKILLS; do
    [[ -f $REPO/$n/SKILL.md ]] || CONFLICTS+=("project-skills.txt lists '$n', but there is no $n/SKILL.md")
  done
  if [[ -f $MANIFEST ]]; then
    while IFS=$'\t' read -r n h; do [[ -n $n ]] && HAVE[$n]=$h; done < $MANIFEST
  fi
  for d in $REPO/*(N/); do
    [[ -f $d/SKILL.md ]] || continue
    n=${d:t}
    # project mode takes only project skills; global mode takes everything else
    if [[ -n $PROJECT ]]; then (( ${PROJECT_SKILLS[(Ie)$n]} )) || continue
    else (( ${PROJECT_SKILLS[(Ie)$n]} )) && continue; fi
    if [[ ! $n =~ '^[a-z0-9][a-z0-9-]*$' ]]; then CONFLICTS+=("$n: folder name must be lowercase letters, digits and dashes"); continue; fi
    v=$(sed -n 's/^name:[[:space:]]*//p' $d/SKILL.md | head -1)
    [[ $v == $n ]] || CONFLICTS+=("$n: SKILL.md says 'name: $v'; it must match the folder name")
    [[ -z $(find $d -mindepth 2 -name SKILL.md) ]] || CONFLICTS+=("$n: has a nested SKILL.md; skills must be flat (rename templates, e.g. assets/<name>-skill.md)")
    [[ -z $(find $d -type l) ]] || CONFLICTS+=("$n: contains symlinks; installed copies must be self-contained")
    SKILLS+=($n)
  done
}

plan_install() {
  local n hs hd
  for n in $SKILLS; do
    hs=$(tree_hash $REPO/$n)
    if [[ ! -e $DEST/$n && ! -L $DEST/$n ]]; then OPS+=("copy $n"); MSGS+=("add $n"); continue; fi
    hd=$(tree_hash $DEST/$n)
    if [[ $hd == $hs ]]; then
      [[ ${HAVE[$n]:-} == $hs ]] || { OPS+=("adopt $n"); MSGS+=("record $n (already identical)"); }
    elif [[ -n ${HAVE[$n]:-} && $hd == ${HAVE[$n]} ]]; then
      OPS+=("update $n"); MSGS+=("update $n")
    elif [[ -n ${HAVE[$n]:-} ]]; then
      CONFLICTS+=("$(disp $DEST/$n) was edited after it was installed. Copy your edits into $(disp $REPO/$n) (or move the folder away), then rerun")
    else
      CONFLICTS+=("$(disp $DEST/$n) already exists and was not installed from $NAME. Compare with: diff -r '$REPO/$n' '$DEST/$n'")
    fi
  done
  for n in ${(ok)HAVE}; do
    (( ${SKILLS[(Ie)$n]} )) && continue
    plan_remove $n "not a $([[ -n $PROJECT ]] && print project || print global) skill in $NAME any more"
  done
}

plan_remove() { # skill reason
  local n=$1
  if [[ ! -e $DEST/$n && ! -L $DEST/$n ]]; then OPS+=("forget $n"); MSGS+=("forget $n (already gone)")
  elif [[ $(tree_hash $DEST/$n) == ${HAVE[$n]} ]]; then OPS+=("remove $n"); MSGS+=("remove $n ($2)")
  else CONFLICTS+=("$(disp $DEST/$n) was edited after it was installed; left alone. Move it away by hand if unwanted, then rerun"); fi
}

write_manifest() { # from HAVE, atomically
  local n tmp=$MANIFEST.tmp
  mkdir -p ${MANIFEST:h} || return 1
  : > $tmp || return 1
  for n in ${(ok)HAVE}; do print -r -- "$n"$'\t'"${HAVE[$n]}" >> $tmp; done
  if (( ${#HAVE} )); then mv -- $tmp $MANIFEST
  else rm -f -- $tmp $MANIFEST; rmdir ${MANIFEST:h} 2>/dev/null; fi
  return 0
}

# Global installs record where this repo lives, so skills (e.g. common-project-setup) can
# find install.sh on any Mac: $(cat ~/.common-agents/installed/<repo>.source)/install.sh
write_source() {
  [[ -z $PROJECT ]] || return 0
  if (( ${#HAVE} )); then mkdir -p $STATE/installed && print -r -- $REPO > $STATE/installed/$NAME.source
  else rm -f -- $STATE/installed/$NAME.source; fi
}

apply() {
  local i op n bk stg=$STATE/staging
  bk=$STATE/backups/$(date +%Y%m%d-%H%M%S)-$BK_TAG
  mkdir -p $stg || die "cannot create $(disp $stg)"
  for (( i = 1; i <= ${#OPS}; i++ )); do
    op=${OPS[i]%% *}; n=${OPS[i]#* }
    case $op in
      copy|update)
        if [[ $op == update ]]; then mkdir -p $bk && mv -- $DEST/$n $bk/$n || { bad "failed: ${MSGS[i]}"; return 1; }; fi
        rm -rf -- ${stg:?}/$n && cp -R -- $REPO/$n $stg/$n && find $stg/$n -name .DS_Store -delete && mv -- $stg/$n $DEST/$n \
          || { bad "failed: ${MSGS[i]}"; return 1; }
        HAVE[$n]=$(tree_hash $DEST/$n) ;;
      adopt)  HAVE[$n]=$(tree_hash $DEST/$n) ;;
      remove) mkdir -p $bk && mv -- $DEST/$n $bk/$n || { bad "failed: ${MSGS[i]}"; return 1; }; unset "HAVE[$n]" ;;
      forget) unset "HAVE[$n]" ;;
    esac
    write_manifest || die "cannot write $(disp $MANIFEST)"
    ok ${MSGS[i]}
  done
  rmdir $stg 2>/dev/null
  [[ -d $bk ]] && info "previous copies saved in $(disp $bk)"
  return 0
}

main() {
  local cmd=install c
  while (( $# )); do
    case $1 in
      install|check|uninstall) cmd=$1 ;;
      --project) (( $# >= 2 )) || die "--project needs a directory"; PROJECT=$2; shift ;;
      -h|--help|help) usage; return 0 ;;
      *) usage >&2; return 1 ;;
    esac
    shift
  done
  if [[ -n $PROJECT ]]; then
    [[ -d $PROJECT ]] || die "project folder not found: $PROJECT"
    PROJECT=${PROJECT:A}
    DEST=$PROJECT/.agents/skills
    MANIFEST=$PROJECT/.agents/installed/$NAME.tsv
    BK_TAG=$NAME-${PROJECT:t}
    [[ -d $DEST ]] || die "$(disp $DEST) not found. Set up the project's agent folders first (the common-agent-setup skill)."
  else
    [[ -d $DEST ]] || die "$(disp $DEST) not found. This repo depends on common-agents: run its installer first (common-agents install)."
  fi
  load
  if [[ -n $PROJECT ]] && (( ! ${#PROJECT_SKILLS} )); then die "$NAME has no project skills (see project-skills.txt)"; fi
  if [[ $cmd == uninstall ]]; then
    for c in ${(ok)HAVE}; do plan_remove $c "uninstall"; done
  else
    plan_install
  fi

  print -r -- "$NAME -> $(disp $DEST)"
  if (( ${#CONFLICTS} )); then
    for c in $CONFLICTS; do bad $c; done
    print -r -- "Stopped: ${#CONFLICTS} conflict(s). Nothing was changed."
    return 2
  fi
  if (( ! ${#OPS} )); then
    [[ $cmd == install ]] && write_source
    print -r -- "Up to date (${#SKILLS} skill(s))."; return 0
  fi
  if [[ $cmd == check ]]; then
    for c in $MSGS; do info "would $c"; done
    return 4
  fi
  mkdir -p $STATE || die "cannot create $(disp $STATE)"
  mkdir $STATE/lock 2>/dev/null || die "another common-agents run holds $(disp $STATE/lock) (remove it if stale)"
  trap 'rmdir $STATE/lock 2>/dev/null' EXIT
  apply || { print -r -- "Stopped partway; rerun to finish (finished steps are recorded)."; return 1; }
  write_source
  print -r -- "Done."
}

main "$@"
