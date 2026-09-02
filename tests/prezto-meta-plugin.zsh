#!/usr/bin/env zsh
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et

builtin emulate -R zsh
setopt extended_glob pipe_fail

typeset repo_dir=${0:A:h:h}

fail() {
  builtin emulate -L zsh
  builtin print -u2 -r -- "not ok - $1"
  exit 1
}

function @zi-register-annex() { :; }

typeset -g PMSPEC=f
typeset -gA ICE ZI
typeset -ga zsh_loaded_plugins
builtin source "$repo_dir/z-a-meta-plugins.plugin.zsh" >/dev/null || fail "source meta-plugins annex"

[[ ${_z_a_meta_plugins_map[prezto]} = "PZTM::archive PZTM::directory PZTM::utility" ]] || \
  fail "register @prezto members"
[[ ${_z_a_meta_plugins_config_map[PZTM::archive]} = "lucid is-snippet svn silent nocompile" ]] || \
  fail "configure archive as a directory snippet"
[[ ${_z_a_meta_plugins_config_map[PZTM::directory]} = "lucid is-snippet" ]] || \
  fail "configure directory as a file snippet"
[[ ${_z_a_meta_plugins_config_map[PZTM::utility]} = "lucid is-snippet" ]] || \
  fail "configure utility as a file snippet"
(( !${+_z_a_meta_plugins_map[ohmyzsh-svn-lib]} )) || fail "leave @ohmyzsh-svn-lib unavailable"

function .zi-get-object-path() { return 1; }
function .zi-any-colorify-as-uspl2() { REPLY=$1; }
function .zi-two-paths() { :; }
function +zi-message() { :; }

run_prezto_handler() {
  builtin source "$repo_dir/functions/_z_a_meta_plugins_before_load_handler" \
    plugin @prezto @prezto '' '' hook subtype
}

run_prezto_handler
integer handler_rc=$?
(( handler_rc == 2 )) || fail "expand @prezto through the before-load handler"
typeset -a expected_parts=(
  "lucid is-snippet svn silent nocompile @PZTM::archive"
  "lucid is-snippet @PZTM::directory"
  "lucid is-snippet @PZTM::utility"
)
typeset expected_expansion=${(j: :)expected_parts}
typeset actual_expansion=${ZI[annex-before-load:new-@]%%[[:space:]]#}
[[ $actual_expansion = "$expected_expansion" ]] || fail "apply restored Prezto ice configuration"

builtin print -r -- "ok - register only the restored Prezto meta-plugin"
