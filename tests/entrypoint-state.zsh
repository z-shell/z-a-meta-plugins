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
    for source_mode in direct manager_zero; do
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
typeset -gA Plugins

if [[ $3 == manager_zero ]]; then
  typeset -g ZERO=$entrypoint
else
  unset ZERO
fi

typeset caller_zero=$0
builtin source "$entrypoint" >/dev/null || fail 'source annex entrypoint'
[[ $0 == "$caller_zero" ]] || fail 'preserve caller 0'
[[ ${zi_annex_meta_plugins[0]} == "$entrypoint" ]] || fail 'record source path'
[[ ${zi_annex_meta_plugins[repo-dir]} == "$repo_dir" ]] || fail 'record annex directory'
[[ ${Plugins[META_PLUGINS_DIR]} == "$repo_dir" ]] || fail 'record plugin directory'

builtin source "$entrypoint" >/dev/null || fail 're-source annex entrypoint'
[[ $0 == "$caller_zero" ]] || fail 'preserve caller 0 after re-source'
