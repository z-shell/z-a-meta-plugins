#!/usr/bin/env zsh
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et

typeset repo_dir=${0:A:h:h}
typeset -gA ICE ZI zi_annex_meta_plugins zi_annex_meta_plugins_map

run_handler() {
  source "$repo_dir/functions/.za-meta-plugins-before-load-handler" \
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
