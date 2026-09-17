#!/usr/bin/env zsh
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
# The cluster counter is private runtime state: the catalog holds only labels,
# so `@recon-count` is unknown at every point in a session.
builtin emulate -R zsh
setopt extended_glob

typeset repo_dir=${0:A:h:h}

fail() { builtin print -u2 -r -- "not ok - $1"; exit 1 }

typeset -gA ICE ZI ZI_EXTS ZI_EXTS2 ZI_SNIPPETS
typeset -ga zsh_loaded_plugins ZI_REGISTERED_PLUGINS ZI_TASKS ZI_RUN messages
.zi-get-object-path() { return 0 }
.zi-two-paths() { : }
.zi-any-colorify-as-uspl2() { REPLY=$1 }
+zi-message() { [[ $1 == -n ]] && shift; messages+=( "$*" ) }

builtin source "$repo_dir/z-a-meta-plugins.plugin.zsh" >/dev/null 2>&1 ||
  fail 'source the annex'

expand() {  # expand <label> [<following args>]; status in $?, queue in ZI[...]
  builtin source "$repo_dir/functions/_z_a_meta_plugins_before_load_handler" \
    plugin "$1" "$1" "${2-}" '' before-load-4 load 2>/dev/null
}

unknown() {  # unknown <label>; the handler leaves an unknown label to Zi
  integer handler_status
  messages=()
  expand $1 '@following'
  handler_status=$?
  (( handler_status == 0 )) || fail "@$1 must be unknown, got status $handler_status"
  [[ -z ${ZI[annex-before-load:new-@]} ]] ||
    fail "@$1 must queue nothing, queued [${ZI[annex-before-load:new-@]}]"
  (( ${#messages} == 0 )) || fail "@$1 must print nothing: ${(F)messages}"
}

typeset -a catalog=( "${(@ok)_z_a_meta_plugins_map}" )
(( ${#catalog} )) || fail 'the catalog is empty'
(( ! $+_z_a_meta_plugins_map[recon-count] )) || fail 'the catalog ships a counter key'

unknown recon-count

# Every recognised group advances the counter and numbers its own cluster.
integer expected=0 handler_status
counted() {  # counted <label>; the expansion is numbered as the next cluster
  expected+=1
  messages=()
  expand $1
  handler_status=$?
  (( handler_status == 2 )) || fail "@$1 must be recognised, got status $handler_status"
  (( ${_z_a_meta_plugins_state[recon-count]:-0} == expected )) ||
    fail "counter after @$1 is [${_z_a_meta_plugins_state[recon-count]}], expected $expected"
  [[ ${messages[1]} == "{hi}$expected{rst} " ]] ||
    fail "@$1 cluster must be numbered $expected, got: ${messages[1]}"
}
ICE=( debug 1 )
typeset label
for label in zsh-users annexes zsh-users; do
  counted $label
done

# The counter is session state: a re-source of the entrypoint keeps it, like
# the once-per-session notice keys, so numbering continues rather than restarts.
builtin source "$repo_dir/z-a-meta-plugins.plugin.zsh" >/dev/null 2>&1 ||
  fail 're-source the annex'
(( ${_z_a_meta_plugins_state[recon-count]:-0} == expected )) ||
  fail "re-source reset the counter to [${_z_a_meta_plugins_state[recon-count]}]"
counted annexes
ICE=()

# Expansion leaves the catalog as it was declared.
[[ ${(j: :)${(ok)_z_a_meta_plugins_map}} == ${(j: :)catalog} ]] ||
  fail "expansion changed the catalog keys: ${(j: :)${(ok)_z_a_meta_plugins_map}}"

unknown recon-count

builtin print -r -- 'ok - the message counter is runtime state and not a label'
