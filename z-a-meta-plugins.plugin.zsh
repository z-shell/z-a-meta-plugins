# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
# Copyright (c) 2021 Z-Shell Community
#
# Preserve caller state while resolving this sourced entrypoint.
() {
  builtin emulate -L zsh

  local -r source_path=${1:a}
  local -r annex_dir=${source_path:h}

# https://wiki.zshell.dev/community/zsh_plugin_standard#functions-directory
if [[ $PMSPEC != *f* ]]; then
  if (( ! ${fpath[(Ie)${annex_dir}/functions]} )); then
    fpath+=( "${annex_dir}/functions" )
  fi
fi

# Private runtime state, project-prefixed per the plugin standard's naming rules.
# https://wiki.zshell.dev/community/zsh_plugin_standard#names-and-persistent-state
typeset -gA _z_a_meta_plugins_state
_z_a_meta_plugins_state[0]="$source_path"
_z_a_meta_plugins_state[repo-dir]="$annex_dir"
# Every deprecation, retirement and unmatched-skip notice links the migration
# section of this page. A label listed in migration-anchored has its own
# subsection there, "#migrate-<label>", and its notices link that instead.
_z_a_meta_plugins_state[migration-guide]="https://wiki.zshell.dev/ecosystem/annexes/meta-plugins"
_z_a_meta_plugins_state[migration-section]="migration-from-earlier-catalogs"
_z_a_meta_plugins_state[migration-anchored]="annexes+ z-shell z-shell+ sharkdp console-tools console-style zsh-users+fast fuzzy fuzzy-src ext-git rust-utils zunit ohmyzsh-lib"

# Autoload functions
# `autoload` does not replace an already-defined function, and unload leaves an
# inert stub behind when Zi has no unregister API, so clear it first to keep a
# reload after an unload idempotent.
unfunction _z_a_meta_plugins_before_load_handler 2>/dev/null
autoload -Uz _z_a_meta_plugins_before_load_handler

# An empty stub to fill the handler fields
_z_a_meta_plugins_null_handler() { :; }

# The meta-plugins-support hook. The name is held in a parameter because a
# literal `@` inside a subscript trips the zsh-lint parser (z-shell/zsh-lint).
local register_annex='@zi-register-annex'
if (( ${+functions[$register_annex]} )); then
  "$register_annex" "z-a-meta-plugins" hook:before-load-4 \
    _z_a_meta_plugins_before_load_handler \
    _z_a_meta_plugins_null_handler "skip''" # Add new ice
fi

# Labels that changed meaning. A label listed here without a group below is
# retired: the handler recognises it, queues nothing and prints the notice. A
# label with a group is deprecated: it still expands, with the notice. Each
# notice is printed once per session and links the migration guide, which
# carries the exact commands for what the label used to install.
typeset -gA _z_a_meta_plugins_notices
_z_a_meta_plugins_notices=(
  annexes+ "is deprecated and loads only @annexes; load optional annexes explicitly"
  z-shell  "is retired and installs nothing; use @zsh-users+fast or z-shell/F-Sy-H, and load z-shell/H-S-MW and z-shell/zsh-diff-so-fancy explicitly"
  z-shell+ "is retired and installs nothing; load z-shell/zui, z-shell/zsh-select, z-shell/zconvey and z-shell/zflai explicitly"
  sharkdp  "is retired and installs nothing; use @console-tools for fd and bat, and load sharkdp/hexyl, sharkdp/hyperfine and sharkdp/vivid explicitly"
)

# The map in which the definitions of the meta-plugins are being stored.
typeset -gA _z_a_meta_plugins_map
local _annexes="z-shell/z-a-bin-gem-node z-shell/z-a-readurl z-shell/z-a-patch-dl z-shell/z-a-rust"
_z_a_meta_plugins_map=(
  # ---------------------------------------------------------------------- #
  # Explicit provisioning bundle; individual groups need only their installers.
  annexes  "$_annexes"
  # Deprecated spelling of the same bundle; optional annexes are selected individually.
  annexes+ "$_annexes"

  # @zsh-users
  zsh-users       "zsh-users/zsh-completions zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting"
  zsh-users+fast  "zsh-users/zsh-completions zsh-users/zsh-autosuggestions z-shell/F-Sy-H"

  # @romkatv
  romkatv    "romkatv/powerlevel10k"

  # @zunit
  zunit      "z-shell/zunit"

  # ---------------------------------------------------------------------- #
  # Command line productivity, creativity and style.
  console-tools "sharkdp/fd sharkdp/bat eza-community/eza BurntSushi/ripgrep"
  console-style "z-shell/zsh-eza"

  # Zsh toolchain for creators and tinkers.
  zsh-tools "z-shell/zui z-shell/zsh-cmd-architect z-shell/zsh-editing-workbench z-shell/zbrowse"

  # Fuzzy finder, choose a release or explicit source build.
  fuzzy       "fzf"
  fuzzy-src   "fzf-go"

  # Git extensions.
  ext-git     "fuzzy wfxr/forgit paulirish/git-open"

  # Node Managment
  node-utils  "tj/n"

  # Optional extensions for an existing Rust toolchain.
  rust-utils  "cargo-extensions"

  # Python utilities.
  py-utils    "pyenv"

  # A few Prezto modules. The archive module uses Zi's Git sparse directory backend.
  prezto      "PZTM::archive PZTM::directory PZTM::utility"

  # Explicit Oh My Zsh compatibility libraries and their prerequisites.
  ohmyzsh-lib "OMZL::async_prompt.zsh OMZL::git.zsh OMZL::history.zsh OMZL::vcs_info.zsh OMZL::clipboard.zsh OMZL::completion.zsh OMZL::theme-and-appearance.zsh OMZL::prompt_info_functions.zsh OMZL::functions.zsh OMZL::termsupport.zsh OMZL::key-bindings.zsh OMZL::compfix.zsh OMZL::directories.zsh"
)

# The map in which the default sets of ices for the real plugins are being stored.
typeset -gA _z_a_meta_plugins_config_map
local _std="lucid"
local _target=unsupported-platform
case $OSTYPE/$CPUTYPE in
  linux*/x86_64) _target=x86_64-unknown-linux-musl ;;
  linux*/aarch64|linux*/arm64) _target=aarch64-unknown-linux-musl ;;
  darwin*/x86_64) _target=x86_64-apple-darwin ;;
  darwin*/aarch64|darwin*/arm64) _target=aarch64-apple-darwin ;;
esac

_z_a_meta_plugins_config_map=(
  # Every recipe below is selected by a label above; tests/catalog-consistency.zsh
  # enforces that. Recipes for tools no label selects live in the migration
  # guide as plain `zi ... for` commands instead.

  # @annexes
  z-shell/z-a-bin-gem-node  "$_std compile'functions/.*bgn*~*.zwc'"
  z-shell/z-a-readurl       "$_std compile'functions/.*readurl*~*.zwc'"
  z-shell/z-a-patch-dl      "$_std compile'functions/.*patch-dl*~*.zwc'"
  z-shell/z-a-rust          "$_std compile'functions/.*rust*~*.zwc'"

  # @zsh-users
  zsh-users/zsh-syntax-highlighting   "$_std"
  zsh-users/zsh-autosuggestions       "$_std"
  zsh-users/zsh-completions           "$_std atpull'zi creinstall \$PWD' pick'/dev/null' atload'zicompinit; zicdreplay'"

  # @zsh-users+fast
  z-shell/F-Sy-H                      "$_std"

  # @console-style
  z-shell/zsh-eza                     "$_std"

  # @zsh-tools
  z-shell/zui                   "$_std blockf"
  z-shell/zbrowse               "$_std compile'functions/zbr*~*.zwc'"
  z-shell/zsh-cmd-architect     "$_std compile'functions/{h-*,zca*}*~*.zwc'"
  z-shell/zsh-editing-workbench "$_std compile'functions/zew*~*.zwc'"

  # @zunit: first-party test framework, including its bundled helper libraries.
  z-shell/zunit           "$_std as'program' pick'zunit' atclone'zsh -f ./build.zsh && cp zunit.zsh-completion _zunit' atpull'%atclone'"

  # @py-utils
  pyenv                   "$_std pack'default'"

  # @console-tools
  sharkdp/fd              "$_std as'program' from'gh-r' bpick'*$_target.tar.gz' pick'fd-*/fd' if'(( ! \$+commands[fd] ))'"
  sharkdp/bat             "$_std as'program' from'gh-r' bpick'*$_target.tar.gz' pick'bat-*/bat' atclone'cp bat-*/autocomplete/bat.zsh _bat' atpull'%atclone' run-atpull if'(( ! \$+commands[bat] ))'"
  # Eza binary and completions come from the same GitHub release.
  eza-community/eza       "$_std as'program' from'gh-r' bpick'eza_x86_64-unknown-linux-musl.tar.gz;completions-*.tar.gz' pick'eza' if'(( ! \$+commands[eza] ))'"
  BurntSushi/ripgrep      "$_std as'program' from'gh-r' bpick'*$_target.tar.gz' pick'ripgrep-*/rg' if'(( ! \$+commands[rg] ))'"

  # @fuzzy
  fzf                     "lucid pack'native+keys'"

  # @fuzzy-src: from sources
  fzf-go                  "lucid pack'default+keys' id-as'fzf-go' teleid'fzf' git"

  # @rust-utils: extensions use the existing toolchain and preserve its configured roots.
  cargo-extensions        "$_std as'program' cargo'cargo-expand;cargo-audit' pick'bin/cargo-expand' teleid'z-shell/0'"

  # @ext-git
  paulirish/git-open        "$_std as'program' pick'git-open'"
  wfxr/forgit               "$_std as'program' pick'bin/git-forgit' src'forgit.plugin.zsh' atinit'export FORGIT_NO_ALIASES=\${FORGIT_NO_ALIASES-1}'"

  # @node-utils
  tj/n                      "$_std as'program' atinit'export N_PREFIX=\${N_PREFIX:-\${XDG_DATA_HOME:-\$HOME/.local/share}/n}; (( \${path[(Ie)\$N_PREFIX/bin]} )) || path+=( \"\$N_PREFIX/bin\" )' pick'bin/n'"

  # @romkatv
  romkatv/powerlevel10k       "$_std depth=1 atload'[[ ! -f \"\${ZDOTDIR:-\$HOME}/.p10k.zsh\" ]] || source \"\${ZDOTDIR:-\$HOME}/.p10k.zsh\"' nocd"
)

# Snippets
_std+=" is-snippet"

_z_a_meta_plugins_config_map+=(
  # Prezto
  PZTM::archive       "$_std svn pick''"
  PZTM::directory     "$_std"
  PZTM::utility       "$_std svn pick'init.zsh'"

  # Oh-My-Zsh Library
  OMZL::async_prompt.zsh          "$_std"
  OMZL::git.zsh                   "$_std"
  OMZL::history.zsh               "$_std"
  OMZL::vcs_info.zsh              "$_std"
  OMZL::clipboard.zsh             "$_std"
  OMZL::completion.zsh            "$_std atinit'typeset -g ZSH_CACHE_DIR=\${ZSH_CACHE_DIR:-\${ZI[CACHE_DIR]}/omz}; mkdir -p \"\$ZSH_CACHE_DIR\"; zicompinit; zicdreplay'"
  OMZL::theme-and-appearance.zsh  "$_std"
  OMZL::prompt_info_functions.zsh "$_std"
  OMZL::termsupport.zsh           "$_std"
  OMZL::key-bindings.zsh          "$_std"
  OMZL::compfix.zsh               "$_std"
  OMZL::directories.zsh           "$_std"
  OMZL::functions.zsh             "$_std"
)

# https://wiki.zshell.dev/community/zsh_plugin_standard#unload-function
z-a-meta-plugins_plugin_unload() {
  emulate -L zsh

  # Remove functions directory from fpath
  if (( ${+_z_a_meta_plugins_state[repo-dir]} )); then
    fpath=( "${fpath[@]:#${_z_a_meta_plugins_state[repo-dir]}/functions}" )
  fi

  # Zi has no annex unregister API, so the hook stays in ZI_EXTS after unload.
  # Removing the handler would leave Zi calling a missing function on the next
  # plugin load (zi.zsh dispatches "${___arr[5]}" and folds a 127 into its
  # return value), so neutralize the handler in place instead.
  local unregister_annex='@zi-unregister-annex'
  if (( ${+functions[$unregister_annex]} )); then
    "$unregister_annex" "z-a-meta-plugins" hook:before-load-4 2>/dev/null
    unfunction _z_a_meta_plugins_before_load_handler _z_a_meta_plugins_null_handler 2>/dev/null
  else
    _z_a_meta_plugins_before_load_handler() { return 0; }
  fi

  # Unset state parameters
  unset _z_a_meta_plugins_state _z_a_meta_plugins_notices _z_a_meta_plugins_map _z_a_meta_plugins_config_map

  # Self-destruct
  unfunction z-a-meta-plugins_plugin_unload
}
} "${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
