#!/bin/zsh
# install.sh: copy this repo's skills into ~/.agents/skills, the shared skill folder that
# common-agents sets up and every agent reads. Deterministic; no LLM.
#
#   ./install.sh              install or update, then print what changed
#   ./install.sh check        show what would change (exit 0 up to date, 4 changes pending, 2 conflict)
#   ./install.sh uninstall    remove the skills this repo installed (only copies nobody edited)
#
# A skill is a top-level folder containing SKILL.md. The content hash of each copy is kept
# in ~/.common-agents/installed/<repo>.tsv, so a later run only updates or removes copies
# this script made and nobody edited since. Anything replaced or removed is moved to
# ~/.common-agents/backups/<timestamp>-<repo>/, never deleted.
#
# The same file is used by every skills repo (common-skills, meetpi-skills); keep them identical.
emulate -R zsh
setopt no_unset pipe_fail

REPO=${0:A:h}
NAME=${REPO:t}
DEST=$HOME/.agents/skills
STATE=${COMMON_AGENTS_STATE:-$HOME/.common-agents}
MANIFEST=$STATE/installed/$NAME.tsv

if [[ -t 1 ]]; then G=$'\e[32m' Y=$'\e[33m' R=$'\e[31m' D=$'\e[2m' O=$'\e[0m'; else G='' Y='' R='' D='' O=''; fi
disp() { local p=$1; [[ $p == $HOME* ]] && p="~${p#$HOME}"; print -r -- $p; }
ok()   { print -r -- "  ${G}✓${O} $*"; }
info() { print -r -- "  ${D}·${O} $*"; }
bad()  { print -r -- "  ${R}✗${O} $*"; }
die()  { print -r -- "install.sh: $*" >&2; exit 1; }

usage() {
  print -r -- "Usage: ./install.sh [install|check|uninstall]   (repo: $NAME, target: $(disp $DEST))"
}

# Hash of a skill folder: paths, file modes and contents (.DS_Store ignored).
tree_hash() {
  ( cd -- $1 && find . \( -type f -o -type l \) ! -name .DS_Store | LC_ALL=C sort | while IFS= read -r f; do
      if [[ -L $f ]]; then print -r -- "L $f $(readlink -- $f)"
      else print -r -- "F $f $(stat -f %Lp -- $f) $(shasum -a 256 < $f | cut -c1-64)"; fi
    done ) | shasum -a 256 | cut -c1-64
}

typeset -A HAVE      # skill -> hash recorded when this repo last installed it
typeset -a SKILLS OPS MSGS CONFLICTS

load() {
  local n h d v
  if [[ -f $MANIFEST ]]; then
    while IFS=$'\t' read -r n h; do [[ -n $n ]] && HAVE[$n]=$h; done < $MANIFEST
  fi
  for d in $REPO/*(N/); do
    [[ -f $d/SKILL.md ]] || continue
    n=${d:t}
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
    plan_remove $n "no longer in $NAME"
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
  if (( ${#HAVE} )); then mv -- $tmp $MANIFEST; else rm -f -- $tmp $MANIFEST; fi
}

apply() {
  local i op n bk stg=$STATE/staging
  bk=$STATE/backups/$(date +%Y%m%d-%H%M%S)-$NAME
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
  local cmd=${1:-install} c
  case $cmd in
    install|check|uninstall) ;;
    -h|--help|help) usage; return 0 ;;
    *) usage >&2; return 1 ;;
  esac
  [[ -d $DEST ]] || die "$(disp $DEST) not found. This repo depends on common-agents: run its installer first (common-agents install)."
  load
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
  if (( ! ${#OPS} )); then print -r -- "Up to date (${#SKILLS} skill(s))."; return 0; fi
  if [[ $cmd == check ]]; then
    for c in $MSGS; do info "would $c"; done
    return 4
  fi
  mkdir -p $STATE || die "cannot create $(disp $STATE)"
  mkdir $STATE/lock 2>/dev/null || die "another common-agents run holds $(disp $STATE/lock) (remove it if stale)"
  trap 'rmdir $STATE/lock 2>/dev/null' EXIT
  apply || { print -r -- "Stopped partway; rerun to finish (finished steps are recorded)."; return 1; }
  print -r -- "Done."
}

main "$@"
