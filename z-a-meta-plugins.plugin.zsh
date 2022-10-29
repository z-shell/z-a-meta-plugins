# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
# Copyright (c) 2021 Z-Shell Community
#
# Zsh Plugin Standard
# https://wiki.zshell.dev/community/zsh_plugin_standard#zero-handling
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# https://wiki.zshell.dev/community/zsh_plugin_standard/#funtions-directory
if [[ $PMSPEC != *f* ]] {
  fpath+=( "${0:h}/functions" )
}

# Standard hash for plugins:
# https://wiki.zshell.dev/community/zsh_plugin_standard#standard-plugins-hash
typeset -gA zi_annex_meta_plugins
zi_annex_meta_plugins[0]="$0" 
zi_annex_meta_plugins[repo-dir]="${0:h}"

typeset -gA Plugins
Plugins[META_PLUGINS_DIR]="${0:h}"

# Autoload functions
# TODO: meta-cmd  meta-cmd-help-handler
autoload -Uz →za-meta-plugins-before-load-handler 

# An empty stub to fill the handler fields
→za-meta-plugins-null-handler() { :; }

# The meta-plugins-support hook.
@zi-register-annex "z-a-meta-plugins" hook:before-load-4 \
  →za-meta-plugins-before-load-handler \
  →za-meta-plugins-null-handler "skip''" # Add new ice

# The subcommand `meta'.
#@zi-register-annex "z-a-meta-plugins" subcommand:meta \
#  →za-meta-plugins-meta-cmd \
#  →za-meta-plugins-meta-cmd-help-handler # Add subcommand

# The map in which the definitions of the meta-plugins are being stored.
typeset -gA zi_annex_meta_plugins_map
zi_annex_meta_plugins_map=(

  # Required annexes
  annexes "z-shell/z-a-unscope z-shell/z-a-default-ice z-shell/z-a-bin-gem-node z-shell/z-a-readurl z-shell/z-a-patch-dl z-shell/z-a-rust"

  # Recommended + required annexes
  annexes+ "annexes z-shell/z-a-submods z-shell/z-a-test"
  
  # @z-shell
  z-shell     "z-shell/F-Sy-H z-shell/H-S-MW z-shell/zsh-diff-so-fancy"
  z-shell+    "z-shell/zsh-select z-shell/zconvey z-shell/zui z-shell/zflai"

  # @zsh-users
  zsh-users       "zsh-users/zsh-syntax-highlighting zsh-users/zsh-autosuggestions zsh-users/zsh-completions"
  zsh-users+fast  "z-shell/F-Sy-H zsh-users/zsh-autosuggestions zsh-users/zsh-completions z-shell/zsh-fancy-completions"

  # @romkatv
  romkatv    "romkatv/powerlevel10k"

  # @zunit
  zunit      "zdharma/color zdharma/revolver zdharma/zunit"

  # @sharkdp
  sharkdp    "sharkdp/fd sharkdp/bat sharkdp/hexyl sharkdp/hyperfine sharkdp/vivid"

  # Development-related utilities. color and revolver are zunit' dependencies.
  # Tig is being built from source (Git).
  # The gitignore plugin has a Zsh template automatically set up — gi zsh to see it.
  # TODO: github-issues github-issues-srv
  developer   "zdharma/color zdharma/revolver zdharma/zunit voronkovich/gitignore.plugin.zsh jonas/tig"

  # General console utilities. Includes also a LS_COLORS theme with the Zsh completion configured.
  console-tools "dircolors-material sharkdp/fd sharkdp/bat sharkdp/hexyl sharkdp/hyperfine sharkdp/vivid ogham/exa BurntSushi/ripgrep jonas/tig"

  # Fuzzy searchers (4 of them).
  fuzzy       "fzf fzy lotabout/skim peco/peco"
  fuzzy-src   "fzf-go fzy skim-cargo peco-go"

  # Git extensions.
  ext-git     "paulirish/git-open paulirish/git-recent davidosomething/git-my arzzen/git-quick-stats iwata/git-now tj/git-extras wfxr/forgit"

  # Node Managment
  tj-node     "tj/n"

  # Rust toolchain + cargo extensions.
  rust-utils  "rust-toolchain cargo-extensions"

  # Python utilities.
  py-utils    "pyenv"

  # A few Prezto modules.
  prezto      "PZTM::archive PZTM::directory PZTM::utility"
)

# The map in which the default sets of ices for the real plugins are being stored.
typeset -gA zi_annex_meta_plugins_config_map
typeset -g _std="lucid"

zi_annex_meta_plugins_config_map=(
  # @z-shell (all annexes + extensions, without Meta-Plugins, obviously)
  z-shell/z-a-bin-gem-node  "$_std compile'functions/.*{handler,body,cygwin}'"
  z-shell/z-a-default-ice   "$_std"
  z-shell/z-a-readurl       "$_std"
  z-shell/z-a-patch-dl      "$_std"
  z-shell/z-a-unscope       "$_std"
  z-shell/z-a-submods       "$_std"
  z-shell/z-a-linkbin       "$_std"
  z-shell/z-a-rust          "$_std"
  z-shell/z-a-eval          "$_std"
  z-shell/z-a-test          "$_std compile'*handler'"
  z-shell/z-a-man           "$_std compile'*handler'"

  # @zsh-users
  zsh-users/zsh-syntax-highlighting   "$_std atinit'ZI[COMPINIT_OPTS]=-C; zicompinit; zicdreplay;'"
  zsh-users/zsh-autosuggestions       "$_std atload'_zsh_autosuggest_start;'"
  zsh-users/zsh-completions           "$_std atpull'zi creinstall -q .' pick'/dev/null'"

  # @z-shell
  z-shell/F-Sy-H                      "$_std atinit'ZI[COMPINIT_OPTS]=-C; zicompinit; zicdreplay;' atload'fast-theme z-shell &>/dev/null;'"
  z-shell/H-S-MW                      "$_std atinit'zstyle :history-search-multi-word page-size 7;'"
  z-shell/zsh-diff-so-fancy           "$_std null sbin'bin/git-dsf;bin/diff-so-fancy'"
  z-shell/zsh-fancy-completions       "$_std"

  # @z-shell, less popular
  z-shell/zui             "$_std blockf"
  z-shell/zconvey         "$_std sbin'cmds/zc-bg-notify;cmds/plg-zsh-notify'"
  z-shell/zsh-select      "$_std"
  z-shell/zsh-unique-id   "$_std"
  z-shell/zi-console      "$_std"
  z-shell/zflai           "$_std"
  github-issues           "$_std pack"
  github-issues-srv       "$_std pack atinit'GIT_PROJECTS=z-shell/zi GIT_SLEEP_TIME=700;'"

  # @zdharma
  zdharma/zunit            "$_std binary sbin atclone'./build.zsh;' atpull'%atclone'"
  zdharma/color            "$_std binary sbin'color.zsh -> color'"
  zdharma/revolver         "$_std as'program' pick'revolver'"

  # @zpm-zsh
  dircolors-material      "$_std pack"

  # @pyenv
  pyenv                   "$_std pack'bgn'"

  # @sharkdp
  sharkdp/fd              "$_std binary lucid from'gh-r' mv'fd* fd' sbin'**/fd(.exe|) -> fd'"
  sharkdp/bat             "$_std binary lucid from'gh-r' mv'bat* bat' sbin'**/bat(.exe|) -> bat'"
  sharkdp/hexyl           "$_std binary lucid from'gh-r' mv'hexyl* hexyl' sbin'**/hexyl(.exe|) -> hexyl'"
  sharkdp/hyperfine       "$_std binary lucid from'gh-r' mv'hyperfine* hyperfine' sbin'**/hyperfine(.exe|) -> hyperfine'"
  sharkdp/vivid           "$_std binary lucid from'gh-r' mv'vivid* vivid' sbin'**/vivid(.exe|) -> vivid'"

  # @ogham
  ogham/exa               "$_std binary from'gh-r' sbin'**/exa -> exa' atclone'cp -vf completions/exa.zsh _exa' atpull'%atclone'"
  exa-cargo               "$_std binary cargo='!exa' teleid'z-shell/null'"

  # @BurntSushi
  BurntSushi/ripgrep      "$_std binary from'gh-r' mv'rip* ripgrep' sbin'**/rg(.exe|) -> rg'"

  # @jonas
  jonas/tig               "$_std binary as'program' atclone'make configure; ./configure' atpull'%atclone' make'prefix=$ZPFX install'"

  # Fuzzy searchers
  fzf                     "$_std pack'bgn-binary'"
  fzy                     "$_std pack'bgn' git"
  lotabout/skim           "$_std binary from'gh-r' sbin'**/sk(.exe|) -> sk'"
  peco/peco               "$_std binary from'gh-r' mv'peco* peco' sbin'**/peco(.exe|) -> peco'"

  # Fuzzy searchers – from sources
  fzf-go                  "$_std pack'bgn' teleid'fzf' git"
  skim-cargo              "$_std binary cargo='!skim -> sk' teleid'z-shell/null'"
  peco-go                 "$_std binary make'build' sbin'**/peco(.exe|) -> peco' teleid'peco/peco'"

  # no username → a rust-annex usage to install Rust toolchain
  rust-toolchain          "$_std binary sbin='bin/*' rustup teleid'z-shell/null' atload='[[ ! -f \${ZI[COMPLETIONS_DIR]}/_cargo ]] && zi creinstall rust; export CARGO_HOME=\$PWD RUSTUP_HOME=\$PWD/rustup'"

  # see: https://dev.to/cad97/rust-must-know-crates-5ad8
  cargo-extensions        "$_std binary cargo'cargo-edit;cargo-outdated;cargo-tree; cargo-update; cargo-expand;cargo-modules;cargo-audit;cargo-clone' sbin'bin/*' teleid'z-shell/null'"

  # A few utility plugins
  hlissner/zsh-autopair         "$_std"
  urbainvaes/fzf-marks          "$_std"
  z-shell/zsh-navigation-tools  "$_std"
  z-shell/zsh-editing-workbench "$_std atinit'local zew_word_style=whitespace;'"

  # @marzocchi, a notifier, configured to use zconvey
  marzocchi/zsh-notify      "$_std atinit'zstyle \":notify:*\" command-complete-timeout 3; zstyle \":notify:*\" notifier plg-zsh-notify"

  # Git extensions
  Fakerr/git-recall         "$_std null sbin"
  paulirish/git-open        "$_std null sbin"
  paulirish/git-recent      "$_std null sbin"
  davidosomething/git-my    "$_std null sbin"
  arzzen/git-quick-stats    "$_std null sbin atload'export _MENU_THEME=legacy;'"
  iwata/git-now             "$_std null sbin"
  wfxr/forgit               "$_std atinit'forgit_ignore=fgi'"
  tj/git-extras             "$_std as'completion' blockf atclone'cp -vf etc/git-extras-completion.zsh _git-extras-completion' atpull'%atclone' make'PREFIX=$ZPFX MANPREFIX=${ZI[MAN_DIR]}/man1' nocompile"
  tj/n                      "$_std as'program' atinit'export N_PREFIX=\$PWD; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"' pick'bin/n'"

  # @sindresorhus
  sindresorhus/pure           "$_std pick'async.zsh' src'pure.zsh' atload'prompt_pure_precmd' nocd"

  # @agkozak
  agkozak/agkozak-zsh-prompt  "$_std atload'_agkozak_precmd' atinit'AGKOZAK_FORCE_ASYNC_METHOD=subst-async' nocd"

  # @romkatv
  romkatv/powerlevel10k       "$_std depth=1 atinit'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' atload'[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' nocd"

  # @woefe
  woefe/git-prompt.zsh        "$_std atload'_zsh_git_prompt_precmd_hook' nocd"
)

# Snippets
_std+=" is-snippet"

zi_annex_meta_plugins_config_map+=(
  # Prezto
  PZTM::archive       "$_std svn silent nocompile"
  PZTM::directory     "$_std"
  PZTM::utility       "$_std"
)

unset _std
