#!/usr/bin/env zsh
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et

typeset repo_dir=${0:A:h:h}
setopt err_exit
typeset -gA ICE ZI _z_a_meta_plugins_state _z_a_meta_plugins_map

run_handler() {
  source "$repo_dir/functions/_z_a_meta_plugins_before_load_handler" \
    plugin owner/name owner/name '' '' hook subtype
}

unsetopt xtrace
run_handler
[[ $options[xtrace] == off ]]

setopt xtrace
run_handler 2>/dev/null
[[ $options[xtrace] == on ]]
unsetopt xtrace

print 'before-load handler preserves caller option scope'

ICE=( wait 2 )
_z_a_meta_plugins_state[default-ices]='wait 1 lucid 1'
run_handler
[[ $ICE[wait] == 2 && $ICE[lucid] == 1 ]]

unset '_z_a_meta_plugins_state[default-ices]'
ICE=( wait 2 )
run_handler
[[ $ICE[wait] == 2 && ${#ICE} == 1 ]]

print 'before-load handler lets label ices win over default ices'
