#!/usr/bin/env zsh
builtin emulate -R zsh

typeset repo_dir=${0:A:h:h}
typeset -gA ZI ZI_EXTS ZI_EXTS2
typeset -gx N_PREFIX=/fixture/before
source "$repo_dir/z-a-meta-plugins.plugin.zsh" || exit 1

typeset token hook
for token in ${(Q)${(z)_z_a_meta_plugins_config_map[tj/n]}}; do
  [[ $token == atinit* ]] && hook=${token#atinit}
done
[[ -n $hook ]] || exit 2
() {
  builtin emulate -L zsh
  local -a path=( /usr/bin /bin )
  local -x N_PREFIX='/fixture/chosen prefix [literal]'
  eval "$hook" || return 3
  [[ $N_PREFIX == '/fixture/chosen prefix [literal]' ]] || return 4
  [[ $path[-1] == "$N_PREFIX/bin" ]] || return 5
  eval "$hook" || return 6
  (( ${#path} == 3 )) || return 7
  [[ $path[1] == /usr/bin && $path[2] == /bin ]] || return 8
  unset N_PREFIX
  local -x XDG_DATA_HOME=/fixture/data
  eval "$hook" || return 9
  [[ $N_PREFIX == /fixture/data/n ]] || return 10
} || exit $?
print -r -- 'ok - node prefix is deferred, preserved, outside plugin storage and appended once'
