# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
# Copyright (c) 2021 Z-Shell Community
#
# https://wiki.zshell.dev/community/zsh_plugin_standard#zero-handling
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# https://wiki.zshell.dev/community/zsh_plugin_standard/#funtions-directory
if [[ $PMSPEC != *f* ]] {
  fpath+=( "${0:h}/functions" )
}

# https://wiki.zshell.dev/community/zsh_plugin_standard#standard-plugins-hash
typeset -gA zi_annex_meta_plugins
zi_annex_meta_plugins[0]="$0"
zi_annex_meta_plugins[repo-dir]="${0:h}"

typeset -gA Plugins
Plugins[META_PLUGINS_DIR]="${0:h}"

# Autoload functions
# TODO: meta-cmd  meta-cmd-help-handler
autoload -Uz .za-meta-plugins-before-load-handler

# An empty stub to fill the handler fields
.za-meta-plugins-null-handler() { :; }

# The meta-plugins-support hook.
@zi-register-annex "z-a-meta-plugins" hook:before-load-4 \
  .za-meta-plugins-before-load-handler \
  .za-meta-plugins-null-handler "skip''" # Add new ice

# The subcommand `meta'.
#@zi-register-annex "z-a-meta-plugins" subcommand:meta \
#  .za-meta-plugins-meta-cmd \
#  .za-meta-plugins-meta-cmd-help-handler # Add subcommand

# The map in which the definitions of the meta-plugins are being stored.
typeset -gA zi_annex_meta_plugins_map
zi_annex_meta_plugins_map=(
  # ---------------------------------------------------------------------- #
  # Required annexes
  annexes "z-shell/z-a-bin-gem-node z-shell/z-a-readurl z-shell/z-a-patch-dl z-shell/z-a-rust"

  # Required + recommended annexes
  annexes+ "annexes z-shell/z-a-submods z-shell/z-a-default-ice z-shell/z-a-test z-shell/z-a-unscope z-shell/z-a-eval"

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

  # ---------------------------------------------------------------------- #
  # Command line productivity, creativity and style.
  console-tools "sharkdp/fd sharkdp/bat sharkdp/hexyl sharkdp/hyperfine ogham/exa BurntSushi/ripgrep"
  console-style "dircolors-material sharkdp/vivid"

  # Zsh toolchain for creators and tinkers.
  zsh-tools "z-shell/zui zsh-cmd-architect zsh-editing-workbench z-shell/zbrowse" 

  # Fuzzy searchers (4 of them).
  fuzzy       "fzf fzy lotabout/skim peco/peco"
  fuzzy-src   "fzf-go fzy skim-cargo peco-go"

  # Git extensions.
  ext-git     "paulirish/git-open paulirish/git-recent davidosomething/git-my arzzen/git-quick-stats iwata/git-now tj/git-extras wfxr/forgit voronkovich/gitignore.plugin.zsh jonas/tig"

  # Node Managment
  node-utils  "tj/n"

  # Rust toolchain + cargo extensions.
  rust-utils  "rust-toolchain cargo-extensions"

  # Python utilities.
  py-utils    "pyenv"

  # A few Prezto modules.
  prezto      "PZTM::archive PZTM::directory PZTM::utility"

  # Oh-My-Zsh library with positive or commonly required effects.
  ohmyzsh-lib "OMZL::git OMZL::history OMZL::vcs_info OMZL::clipboard OMZL::completion OMZL::theme-and-appearance OMZL::prompt_info_functions"
  # Oh-My-Zsh library using subversion
  ohmyzsh-svn-lib "OMZ::lib"
)

# The map in which the default sets of ices for the real plugins are being stored.
typeset -gA zi_annex_meta_plugins_config_map
typeset -g _std="lucid"

zi_annex_meta_plugins_config_map=(
  # @z-shell (all annexes + extensions, without Meta-Plugins, obviously)
  z-shell/z-a-bin-gem-node  "$_std compile'functions/.*bgn*~*.zwc'"
  z-shell/z-a-default-ice   "$_std"
  z-shell/z-a-readurl       "$_std compile'functions/.*readurl*~*.zwc'"
  z-shell/z-a-patch-dl      "$_std compile'functions/.*patch-dl*~*.zwc'"
  z-shell/z-a-unscope       "$_std"
  z-shell/z-a-submods       "$_std compile'functions/.*submods*~*.zwc'"
  z-shell/z-a-linkbin       "$_std"
  z-shell/z-a-linkman       "$_std compile'functions/.*lman*~*.zwc'"
  z-shell/z-a-rust          "$_std compile'functions/.*rust*~*.zwc'"
  z-shell/z-a-eval          "$_std compile'functions/.*ev*~*.zwc'"
  z-shell/z-a-test          "$_std compile'*handler'"
  z-shell/z-a-man           "$_std compile'*handler'"

  # @zsh-users
  zsh-users/zsh-syntax-highlighting   "$_std atinit'ZI[COMPINIT_OPTS]=-C; zicompinit; zicdreplay;'"
  zsh-users/zsh-autosuggestions       "$_std compile'{src/*.zsh*~*.zwc,src/strategies/*~*.zwc}' atload'!_zsh_autosuggest_start;'"
  zsh-users/zsh-completions           "$_std atpull'zi creinstall -q .' pick'/dev/null'"

  # @z-shell
  z-shell/F-Sy-H                      "$_std atinit'ZI[COMPINIT_OPTS]=-C; zicompinit; zicdreplay;' atload'fast-theme z-shell &>/dev/null;' compile'{functions/{.fast,fast}-*~*.zwc,chroma/*~*.zwc}'"
  z-shell/H-S-MW                      "$_std atinit'zstyle :history-search-multi-word page-size 7;' compile'functions/h*~*.zwc'"
  z-shell/zsh-diff-so-fancy           "$_std null sbin'bin/git-dsf;bin/diff-so-fancy;bin/fancy-diff;'"
  z-shell/zsh-fancy-completions       "$_std compile'{lib/*.zsh*~*.zwc,functions/{.*,*}*~*.zwc}'"

  # @z-shell, less popular
  z-shell/zui                   "$_std blockf"
  z-shell/zbrowse               "$_std compile'functions/zbr*~*.zwc}'"
  z-shell/zconvey               "$_std sbin'cmds/zc-bg-notify;cmds/plg-zsh-notify'"
  z-shell/zsh-select            "$_std"
  z-shell/zsh-unique-id         "$_std"
  z-shell/zi-console            "$_std"
  z-shell/zflai                 "$_std"
  z-shell/zsh-navigation-tools  "$_std"
  z-shell/zsh-cmd-architect     "$_std compile'functions/{h-*,zca*}*~*.zwc'"
  z-shell/zsh-editing-workbench "$_std atinit'local zew_word_style=whitespace;' compile'functions/zew*~*.zwc'"
  github-issues                 "$_std pack"
  github-issues-srv             "$_std pack atinit'GIT_PROJECTS=z-shell/zi GIT_SLEEP_TIME=700;'"

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
  exa-cargo               "$_std binary cargo='!exa' teleid'z-shell/0'"

  # @BurntSushi
  BurntSushi/ripgrep      "$_std binary from'gh-r' mv'rip* ripgrep' sbin'**/rg(.exe|) -> rg'"

  # @jonas
  jonas/tig               "$_std binary as'program' atclone'make configure; ./configure' atpull'%atclone' make'prefix=$ZPFX install'"

  # Fuzzy searchers
  fzf                     "$_std pack'bgn-binary'"
  fzy                     "$_std pack'bgn' git"
  lotabout/skim           "$_std binary lucid sbin'*/sk' atclone'ln -s shell/completion.zsh _sk; cp -f man/man1/sk.1 $ZI[MAN_DIR]/man1; ./install >/dev/null;' atpull'%atclone'"
  peco/peco               "$_std binary from'gh-r' mv'peco* peco' sbin'**/peco(.exe|) -> peco'"

  # Fuzzy searchers – from sources
  fzf-go                  "$_std pack'bgn' teleid'fzf' git"
  skim-cargo              "$_std binary cargo='!skim -> sk' teleid'z-shell/0'"
  peco-go                 "$_std binary make'build' sbin'**/peco(.exe|) -> peco' teleid'peco/peco'"

  # no username → a rust-annex usage to install Rust toolchain
  rust-toolchain          "$_std binary sbin='bin/*' rustup teleid'z-shell/0' atload='[[ ! -f \${ZI[COMPLETIONS_DIR]}/_cargo ]] && zi creinstall rust; export CARGO_HOME=\$PWD RUSTUP_HOME=\$PWD/rustup'"

  # see: https://dev.to/cad97/rust-must-know-crates-5ad8
  cargo-extensions        "$_std binary cargo'cargo-edit;cargo-outdated;cargo-tree; cargo-update; cargo-expand;cargo-modules;cargo-audit;cargo-clone' sbin'bin/*' teleid'z-shell/0'"

  # A few utility plugins
  hlissner/zsh-autopair         "$_std"
  urbainvaes/fzf-marks          "$_std"

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

  # Oh-My-Zsh Library
  OMZ::lib                    "$_std svn multisrc'{git,clipboard,history,completion,prompt_info_functions,theme-and-appearance,vcs_info}.zsh' pick'/dev/null'"
  OMZL::git                   "$_std"
  OMZL::history               "$_std"
  OMZL::vcs_info              "$_std"
  OMZL::clipboard             "$_std"
  OMZL::completion            "$_std"
  OMZL::theme-and-appearance  "$_std"
  OMZL::prompt_info_functions "$_std"
)

unset _std
