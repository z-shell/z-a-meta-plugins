#!/usr/bin/env zsh
# Entrypoint parsing alone cannot detect invalid shell stored inside recipes.
builtin emulate -R zsh
typeset repo_dir=${0:A:h:h}
typeset -gA ZI ZI_EXTS ZI_EXTS2
source "$repo_dir/z-a-meta-plugins.plugin.zsh" || exit 1
typeset recipe token hook
for recipe in "${(@k)_z_a_meta_plugins_config_map}"; do
  for token in "${(@Q)${(@z)_z_a_meta_plugins_config_map[$recipe]}}"; do
    case $token in
      atinit*|atload*|atclone*|atpull*)
        hook=${token#at(init|load|clone|pull)}
        zsh -n <<< "$hook" || {
          print -u2 -r -- "not ok - invalid hook in $recipe"
          exit 1
        }
        ;;
    esac
  done
done
print -r -- 'ok - every retained recipe hook passes native Zsh parsing'
