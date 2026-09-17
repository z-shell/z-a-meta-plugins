#!/usr/bin/env zsh
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
# Every label expands to real recipes and every recipe is selected by a label.
# The handler keeps its runtime state out of the map, so the catalog can be
# read at any point in a session (tests/message-counter.zsh).
builtin emulate -R zsh
setopt extended_glob

typeset repo_dir=${0:A:h:h}

fail() { builtin print -u2 -r -- "not ok - $1"; exit 1 }

typeset -gA ZI ZI_EXTS ZI_EXTS2

builtin source "$repo_dir/z-a-meta-plugins.plugin.zsh" >/dev/null 2>&1 ||
  fail 'source the annex'

typeset label member inner recipe
typeset -a members
typeset -A selected
for label in "${(@k)_z_a_meta_plugins_map}"; do
  members=( ${(s: :)_z_a_meta_plugins_map[$label]} )
  (( ${#members} )) || fail "@$label expands to nothing"
  if (( ${#members} == 1 && $+_z_a_meta_plugins_map[$members[1]] )); then
    fail "@$label is a bare alias of @$members[1]"
  fi
  for member in $members; do
    [[ $member != $label ]] || fail "@$label selects itself"
    if (( $+_z_a_meta_plugins_map[$member] )); then
      # The handler forwards skip'' one level into a nested label, so a label
      # member must not nest a label of its own.
      for inner in ${(s: :)_z_a_meta_plugins_map[$member]}; do
        (( $+_z_a_meta_plugins_map[$inner] )) &&
          fail "@$label nests @$member, which nests @$inner"
        selected[$inner]=1
      done
    else
      (( $+_z_a_meta_plugins_config_map[$member] )) ||
        fail "@$label selects $member, which has no recipe"
      selected[$member]=1
    fi
  done
done

for recipe in "${(@k)_z_a_meta_plugins_config_map}"; do
  (( $+selected[$recipe] )) || fail "recipe $recipe is selected by no label"
done

# A notice without a group is a retired label; a notice with a group is a
# deprecation. Both need the guide the notice links.
(( ${#_z_a_meta_plugins_notices} )) || fail 'no deprecation notices declared'
[[ ${_z_a_meta_plugins_state[migration-guide]} == https://wiki.zshell.dev/* ]] ||
  fail 'the migration guide URL must point at the wiki'
for label in "${(@k)_z_a_meta_plugins_notices}"; do
  [[ -n ${_z_a_meta_plugins_notices[$label]} ]] || fail "@$label has an empty notice"
done

# A label whose notices link its own guide subsection must be a label at all,
# and every noticed label has such a subsection.
[[ -n ${_z_a_meta_plugins_state[migration-section]} ]] || fail 'no migration section anchor declared'
typeset -a anchored
anchored=( ${=_z_a_meta_plugins_state[migration-anchored]} )
(( ${#anchored} )) || fail 'no anchored labels declared'
for label in $anchored; do
  (( $+_z_a_meta_plugins_map[$label] || $+_z_a_meta_plugins_notices[$label] )) ||
    fail "$label has a guide anchor but is not a label"
done
for label in "${(@k)_z_a_meta_plugins_notices}"; do
  (( ${anchored[(Ie)$label]} )) || fail "@$label has a notice but no guide anchor"
done

builtin print -r -- 'ok - every label selects real recipes and every recipe has a label'
