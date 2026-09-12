#!/usr/bin/env zsh
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et

builtin emulate -R zsh
setopt extended_glob

typeset repo_dir=${0:A:h:h}

fail() { builtin print -u2 -r -- "not ok - $1"; exit 1 }

typeset -gA ICE ZI ZI_EXTS ZI_EXTS2 ZI_SNIPPETS
typeset -ga zsh_loaded_plugins ZI_REGISTERED_PLUGINS ZI_TASKS ZI_RUN
.zi-get-object-path() { return 0 }
.zi-two-paths() { : }
.zi-any-colorify-as-uspl2() { REPLY=$1 }
+zi-message() { : }

builtin source "$repo_dir/z-a-meta-plugins.plugin.zsh" >/dev/null 2>&1 ||
  fail 'source the annex'

expand() {  # expand <group>; leaves the status in $? and the queue in ZI[...]
  builtin source "$repo_dir/functions/_z_a_meta_plugins_before_load_handler" \
    plugin "$1" "$1" '' '' before-load-4 load
}

# A group whose members are neither loaded nor provisioned expands to a queue,
# and an odd status would abort the load, so this must stay even.
expand annexes
integer first=$?
[[ -n ${ZI[annex-before-load:new-@]//[[:space:]]/} ]] ||
  fail "first expansion queued nothing"
(( (first & 1) == 0 )) ||
  fail "first expansion returned odd status $first, which Zi reads as an error"

# The contract this test exists for. Every member loaded and every capability
# registered means the group is fully consumed: an empty replacement, and a
# success status. Returning 1 here made Zi report a hook error, because Zi
# reads an odd status as a failure. See z-shell/zi#511.
typeset -ga members=(
  z-shell/z-a-bin-gem-node z-shell/z-a-readurl
  z-shell/z-a-patch-dl z-shell/z-a-rust
)
zsh_loaded_plugins=( $members )
ZI_EXTS[ice-mods]="0-sbin''|0-dlink''|0-dl''|0-cargo''"

expand annexes
integer repeated=$?
[[ -z ${ZI[annex-before-load:new-@]//[[:space:]]/} ]] ||
  fail "repeated group queued [${ZI[annex-before-load:new-@]}] instead of consuming it"
(( (repeated & 1) == 0 )) ||
  fail "repeated group returned odd status $repeated; Zi reads that as a hook error"
(( repeated & 2 )) ||
  fail "repeated group returned $repeated without the replace-arguments bit"

# The other route to an empty replacement: every member filtered by `skip''`,
# with nothing loaded and nothing provisioned. The status must be the same,
# because "nothing left to load" is the condition, not "already loaded".
zsh_loaded_plugins=()
ZI_EXTS[ice-mods]=""
ICE[skip]='bin-gem-node;readurl;patch-dl;rust'

expand annexes
integer skipped=$?
ICE[skip]=""
[[ -z ${ZI[annex-before-load:new-@]//[[:space:]]/} ]] ||
  fail "a fully skipped group queued [${ZI[annex-before-load:new-@]}]"
(( (skipped & 1) == 0 )) ||
  fail "a fully skipped group returned odd status $skipped; Zi reads that as an error"
(( skipped & 2 )) ||
  fail "a fully skipped group returned $skipped without the replace-arguments bit"

# An unrecognised name is not this annex's business and must stay untouched.
expand definitely-not-a-group
(( $? == 0 )) || fail "an unrecognised id must return 0"

builtin print -r -- "ok - a fully consumed group returns a successful replacement"
