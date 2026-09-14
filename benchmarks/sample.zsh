#!/usr/bin/env zsh
# Isolated interactive test fixture. Provisioning belongs outside timed trials.
builtin emulate -R zsh
setopt pipe_fail
zmodload zsh/datetime || exit 1

readonly root=$1 manager=$2 annex=$3 scenario=$4
export HOME=$root/home ZDOTDIR=$root/home TMPDIR=$root/tmp
export XDG_DATA_HOME=$root/xdg-data XDG_CACHE_HOME=$root/cache XDG_CONFIG_HOME=$root/config
export PYENV_ROOT=$root/python
export PATH=$root/deny:/usr/local/bin:/usr/bin:/bin TERM=xterm-256color
command mkdir -p -- "$HOME" "$TMPDIR" "$PYENV_ROOT" "$root/prefix/bin" || exit 1
builtin cd -- "$HOME" || exit 1
typeset -gA ZI=( HOME_DIR $root/data CACHE_DIR $root/cache CONFIG_DIR $root/config )
typeset -gx ZPFX=$root/prefix
source "$manager/zi.zsh" >/dev/null || exit 1
.zi-prepare-home >/dev/null || exit 1
fpath=( "$annex/functions" $fpath )
source "$annex/z-a-meta-plugins.plugin.zsh" || exit 1
ZI[COMPINIT_OPTS]=-i

typeset group
case $scenario in
  loader)
    group=benchmark
    _z_a_meta_plugins_map[$group]='benchmark/fixture'
    ;;
  editor) group=zsh-users ;;
  editor-fast) group=zsh-users+fast ;;
  fzf|pyenv)
    [[ -f $root/package/package.json ]] || exit 1
    builtin cd -- "$root/package" || exit 1
    if [[ $scenario == fzf ]]; then
      group=fuzzy
      _z_a_meta_plugins_config_map[fzf]=${_z_a_meta_plugins_config_map[fzf]/pack\'native+keys\'/pack\'./package.json:native+keys\'}
    else
      group=py-utils
      _z_a_meta_plugins_config_map[pyenv]=${_z_a_meta_plugins_config_map[pyenv]/pack\'default\'/pack\'./package.json:default\'}
    fi
    ;;
  *) exit 2 ;;
esac

# Membership is emitted for comparison checks, not silently normalized.
print -r -- "RUNTIME $ZSH_VERSION $OSTYPE $CPUTYPE"
print -r -- "MEMBERS ${_z_a_meta_plugins_map[$group]}"
float started=$EPOCHREALTIME
zi light-mode for "@$group" >/dev/null 2>&1 || exit 3
float load_ms=$(( (EPOCHREALTIME - started) * 1000 ))

# Run the actual first-prompt setup hooks, without claiming ZLE input latency.
started=$EPOCHREALTIME
typeset callback
for callback in "${precmd_functions[@]}"; do
  "$callback" >/dev/null 2>&1
done
float precmd_ms=$(( (EPOCHREALTIME - started) * 1000 ))
case $scenario in
  loader) (( BENCHMARK_LOAD_COUNT == 1 )) || exit 4 ;;
  editor) (( $+functions[_zsh_highlight] && $+functions[_zsh_autosuggest_start] && $+_comps )) || exit 4 ;;
  editor-fast) (( $+functions[_fsh_zle_highlight] && $+functions[_zsh_autosuggest_start] && $+_comps )) || exit 4 ;;
  fzf) (( $+commands[fzf] && $+functions[fzf-history-widget] )) || exit 4 ;;
  pyenv) [[ $(pyenv version-name) == system && $PYENV_ROOT == $root/python ]] || exit 4 ;;
esac

typeset -A benchmark_before
for benchmark_parameter in path fpath precmd_functions chpwd_functions ZI_REGISTERED_PLUGINS ZI_TASKS ZI_RUN widgets; do
  benchmark_before[$benchmark_parameter]=$(typeset -p "$benchmark_parameter" 2>/dev/null)
done
started=$EPOCHREALTIME
integer iteration
for iteration in {1..100}; do
  zi light-mode for "@$group" >/dev/null 2>&1 || exit 5
done
float repeat_ms=$(( (EPOCHREALTIME - started) * 10 ))
for benchmark_parameter in "${(@k)benchmark_before}"; do
  [[ ${benchmark_before[$benchmark_parameter]} == "$(typeset -p "$benchmark_parameter" 2>/dev/null)" ]] || {
    print -u2 -r -- "repeat state changed: $benchmark_parameter"
    exit 6
  }
done
[[ $scenario != loader || $BENCHMARK_LOAD_COUNT == 1 ]] || { print -u2 -r -- "fixture loads: $BENCHMARK_LOAD_COUNT"; exit 6; }

case $scenario in
  fzf) print -r -- "VERSION $(fzf --version)" ;;
  pyenv) print -r -- "VERSION $(pyenv --version)" ;;
  *) print -r -- "VERSION source-fingerprints" ;;
esac

float operation_ms=0
if [[ $scenario == fzf ]]; then
  started=$EPOCHREALTIME
  typeset selected=$(fzf --filter item-09999 < "$root/items") || exit 7
  operation_ms=$(( (EPOCHREALTIME - started) * 1000 ))
  [[ $selected == item-09999 ]] || exit 7
elif [[ $scenario == pyenv ]]; then
  started=$EPOCHREALTIME
  for iteration in {1..10}; do
    [[ $(pyenv version-name) == system ]] || exit 7
  done
  operation_ms=$(( (EPOCHREALTIME - started) * 100 ))
fi
[[ ! -e $root/network-attempt ]] || exit 8
printf 'RESULT {"load_ms":%.9f,"precmd_ms":%.9f,"repeat_ms":%.9f,"operation_ms":%.9f}\n' "$load_ms" "$precmd_ms" "$repeat_ms" "$operation_ms"
