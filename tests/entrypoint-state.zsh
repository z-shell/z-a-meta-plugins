#!/usr/bin/env zsh
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et

builtin emulate -R zsh

typeset repo_dir=${0:A:h:h}
typeset entrypoint=$repo_dir/z-a-meta-plugins.plugin.zsh

fail() {
  builtin print -u2 -r -- "not ok - $1"
  exit 1
}

if [[ $1 != --case ]]; then
  for option_mode in default no_function_argzero posix_argzero; do
    for source_mode in \
      direct direct_relative manager_zero manager_zero_relative; do
      zsh -f "${0:A}" --case "$option_mode" "$source_mode" ||
        fail "$option_mode/$source_mode"
    done
  done
  builtin print -r -- 'ok - preserve caller state and resolve the annex directory'
  exit 0
fi

case $2 in
  default) ;;
  no_function_argzero) unsetopt function_argzero ;;
  posix_argzero) setopt posix_argzero ;;
  *) fail "unknown option mode: $2" ;;
esac

function @zi-register-annex() { :; }
typeset -g PMSPEC=f

typeset source_target=$entrypoint
case $3 in
  direct)
    unset ZERO
    ;;
  direct_relative)
    unset ZERO
    builtin cd -- "$repo_dir" || fail 'enter repository directory'
    source_target=./z-a-meta-plugins.plugin.zsh
    ;;
  manager_zero)
    typeset -g ZERO=$entrypoint
    ;;
  manager_zero_relative)
    builtin cd -- "$repo_dir" || fail 'enter repository directory'
    typeset -g ZERO='./discarded [literal]*? segment/../z-a-meta-plugins.plugin.zsh'
    ;;
  *) fail "unknown source mode: $3" ;;
esac

typeset caller_zero=$0
builtin source "$source_target" >/dev/null || fail 'source annex entrypoint'
[[ $0 == "$caller_zero" ]] || fail 'preserve caller 0'
[[ ${_z_a_meta_plugins_state[0]} == "$entrypoint" ]] || fail 'record source path'
[[ ${_z_a_meta_plugins_state[repo-dir]} == "$repo_dir" ]] || fail 'record annex directory'
(( ${+functions[z-a-meta-plugins_plugin_unload]} )) || fail 'define unload function'

builtin source "$source_target" >/dev/null || fail 're-source annex entrypoint'
[[ $0 == "$caller_zero" ]] || fail 'preserve caller 0 after re-source'

z-a-meta-plugins_plugin_unload || fail 'execute unload function'
(( ! ${+functions[z-a-meta-plugins_plugin_unload]} )) || fail 'self-destruct unload function'
(( ! ${+_z_a_meta_plugins_state} )) || fail 'unset _z_a_meta_plugins_state'

# Zi keeps the before-load-4 registration after unload, so the handler must
# stay callable and inert rather than disappear from under Zi's dispatch.
(( ${+functions[_z_a_meta_plugins_before_load_handler]} )) || fail 'keep handler callable'
_z_a_meta_plugins_before_load_handler plugin id id_as '' '' before-load-4 load ||
  fail 'neutralized handler returns success'
