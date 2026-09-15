#!/usr/bin/env zsh
builtin emulate -R zsh

typeset repo_dir=${0:A:h:h}
typeset temp_root=$(command mktemp -d "${TMPDIR:-/tmp}/meta-prompt-config.XXXXXXXX") || exit 1
trap 'command rm -rf -- "$temp_root"' EXIT INT TERM
typeset -gA ZI ZI_EXTS ZI_EXTS2
source "$repo_dir/z-a-meta-plugins.plugin.zsh" || exit 1
[[ $_z_a_meta_plugins_config_map[romkatv/powerlevel10k] != *DISABLE_CONFIGURATION_WIZARD* ]] || exit 2
typeset token hook
for token in ${(Q)${(z)_z_a_meta_plugins_config_map[romkatv/powerlevel10k]}}; do
  [[ $token == atload* ]] && hook=${token#atload}
done
[[ -n $hook ]] || exit 3
export HOME=$temp_root/home ZDOTDIR="$temp_root/chosen config [literal]"
command mkdir -p -- "$HOME" "$ZDOTDIR" || exit 4
print -r -- 'typeset -g prompt_config=chosen' > "$ZDOTDIR/.p10k.zsh"
print -r -- 'typeset -g prompt_config=home' > "$HOME/.p10k.zsh"
eval "$hook" || exit 5
[[ $prompt_config == chosen ]] || exit 6
unset ZDOTDIR
eval "$hook" || exit 7
[[ $prompt_config == home ]] || exit 8
ZDOTDIR=$temp_root/absent
eval "$hook" || exit 9
print -r -- 'ok - prompt recipe preserves wizard preference and resolves optional configuration at load time'
