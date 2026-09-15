#!/usr/bin/env zsh

builtin emulate -R zsh
setopt extended_glob

typeset repo_dir=${0:A:h:h}
typeset -gA ICE ZI ZI_EXTS ZI_EXTS2
typeset -ga zsh_loaded_plugins

fail() { print -u2 -r -- "not ok - $1"; exit 1; }
.zi-get-object-path() { return 0; }
.zi-two-paths() { :; }
.zi-any-colorify-as-uspl2() { REPLY=$1; }
+zi-message() { :; }

source "$repo_dir/z-a-meta-plugins.plugin.zsh" || fail 'source annex'

expand() {
  source "$repo_dir/functions/_z_a_meta_plugins_before_load_handler" \
    plugin "$1" "$1" "${2-}" '' before-load-4 load
}

expand annexes
(( $? == 2 )) || fail 'expand installer group without installed capabilities'
typeset initial=${ZI[annex-before-load:new-@]}
[[ $initial == *z-a-bin-gem-node*z-a-readurl*z-a-patch-dl*z-a-rust* ]] ||
  fail 'preserve provisioning members and order'

# Zi may have recorded the plugin before its source failed. Neither record
# establishes that the extension can actually interpret its installer ices.
zsh_loaded_plugins=( z-shell/z-a-bin-gem-node )
expand annexes
(( $? == 2 )) || fail 'retry failed provisioning'
[[ ${ZI[annex-before-load:new-@]} == "$initial" ]] || fail 'do not skip failed installers'

ZI_EXTS[ice-mods]="50-sbin|50-sbin''|10-dlink''|20-dl''|40-cargo''"
expand annexes
(( $? == 2 )) || fail 'skip registered provisioning capabilities without an error'
[[ -z ${ZI[annex-before-load:new-@]//[[:space:]]/} ]] || fail 'do not queue duplicates'

_z_a_meta_plugins_map[fixture]='example/tool'
typeset saved=${_z_a_meta_plugins_state[annex-loaded-plugins]}
typeset recipe
for recipe in "sbin'bin/tool'" "pack'bgn-binary'" "dl'https://example.invalid/file'" "cargo'example'" "rustup" "dlink'https://example.invalid/'"; do
  _z_a_meta_plugins_config_map[example/tool]=$recipe
  ZI_EXTS=()
  expand fixture '@following' 2>/dev/null
  (( $? == 3 )) || fail "reject missing capability: $recipe"
  [[ ${ZI[annex-before-load:new-@]} == '@following' ]] || fail 'preserve remaining request'
  [[ ${_z_a_meta_plugins_state[annex-loaded-plugins]} == "$saved" ]] || fail 'leave load bookkeeping untouched'
done

ICE[skip]=tool
expand fixture '@following'
(( $? == 2 )) || fail 'skipped recipe needs no installer'
[[ ${ZI[annex-before-load:new-@]} == *'@following' && ${ZI[annex-before-load:new-@]} != *example/tool* ]] || fail 'honor skip filter'
ICE=()
ZI_EXTS2[ice-mods]="cargo''"
_z_a_meta_plugins_config_map[example/tool]="cargo'example'"
expand fixture
(( $? == 2 )) || fail 'recognize an ice registered through Zi hook API'
[[ ${ZI[annex-before-load:new-@]} == *"cargo'example' @example/tool"* ]] || fail 'queue supported recipe'

# An incomplete installation can leave its directory behind. A queued ID from
# an older annex version is not evidence that Zi registered the plugin.
_z_a_meta_plugins_state[annex-loaded-plugins]='example/tool'
expand fixture
(( $? == 2 )) || fail 'retry an unregistered installation'
[[ ${ZI[annex-before-load:new-@]} == *'@example/tool'* ]] || fail 'ignore stale queue bookkeeping'
typeset -a ZI_TASKS=( '<no-data>' '1+0+1 p 1 light example/tool' ) ZI_RUN
expand fixture
(( $? == 2 )) || fail 'recognize an already queued plugin'
[[ ${ZI[annex-before-load:new-@]} != *'@example/tool'* ]] || fail 'avoid duplicate pending work'
ZI_RUN=( "$ZI_TASKS[2]" )
ZI_TASKS=()
expand fixture
[[ ${ZI[annex-before-load:new-@]} != *'@example/tool'* ]] || fail 'recognize active scheduler batch'
ZI_RUN=()
expand fixture
[[ ${ZI[annex-before-load:new-@]} == *'@example/tool'* ]] || fail 'retry after the failed task leaves the scheduler'

expand annexes+ 2>/dev/null
(( $? == 2 )) || fail 'consume deprecated annex bundle'
[[ ${ZI[annex-before-load:new-@]} == '@annexes '* ]] || fail 'retain provisioning migration target'
[[ ${ZI[annex-before-load:new-@]} != *z-a-* ]] || fail 'do not bulk-load optional extensions'

zsh_loaded_plugins=( z-shell/F-Sy-H )
expand zsh-users '@following' 2>/dev/null
(( $? == 3 )) || fail 'reject standard highlighter after F-Sy-H'
[[ ${ZI[annex-before-load:new-@]} == '@following' ]] || fail 'preserve requests after highlighter conflict'
zsh_loaded_plugins=( zsh-users/zsh-syntax-highlighting )
expand zsh-users+fast 2>/dev/null
(( $? == 3 )) || fail 'reject F-Sy-H after standard highlighter'
ICE[skip]=F-Sy-H
expand zsh-users+fast
(( $? == 2 )) || fail 'allow explicitly skipped alternative highlighter'

() {
  local OSTYPE=darwin CPUTYPE=arm64
  local -hA commands=()
  ICE=()
  source "$repo_dir/z-a-meta-plugins.plugin.zsh" || fail 'source macOS profile'
  [[ ${_z_a_meta_plugins_config_map[sharkdp/fd]} == *aarch64-apple-darwin.tar.gz* ]] || fail 'select native ARM64 macOS archive'
  expand console-tools '@following' 2>/dev/null
  (( $? == 3 )) || fail 'require system eza on macOS'
  [[ ${ZI[annex-before-load:new-@]} == '@following' ]] || fail 'preserve requests after missing system eza'
  commands[eza]=/fixture/eza
  expand console-tools
  (( $? == 2 )) || fail 'accept existing system eza without Rust'
  commands=()
  ICE[skip]=eza
  expand console-tools
  (( $? == 2 )) || fail 'permit explicit eza exclusion'
  ICE=()
  local TERM=xterm
  expand console-style 2>/dev/null
  (( $? == 3 )) || fail 'reject styling before eza is available'
  commands[eza]=/fixture/eza
  expand console-style
  (( $? == 2 )) || fail 'allow first-party styling with system eza'
  [[ ${ZI[annex-before-load:new-@]} == *'@z-shell/zsh-eza'* ]] || fail 'load maintained shell integration'
}

() {
  local OSTYPE=freebsd14.0 CPUTYPE=amd64
  local -hA commands=()
  ICE=()
  source "$repo_dir/z-a-meta-plugins.plugin.zsh" || fail 'source unsupported profile'
  [[ ${_z_a_meta_plugins_config_map[sharkdp/fd]} == *unsupported-platform.tar.gz* ]] || fail 'mark unsupported release target'
  expand console-tools '@following' 2>/dev/null
  (( $? == 3 )) || fail 'require system tools on an unsupported release target'
  [[ ${ZI[annex-before-load:new-@]} == '@following' ]] || fail 'preserve requests after unsupported release target'
  commands=( fd /fixture/fd bat /fixture/bat eza /fixture/eza rg /fixture/rg )
  expand console-tools
  (( $? == 2 )) || fail 'accept existing system tools on an unsupported release target'
}
source "$repo_dir/z-a-meta-plugins.plugin.zsh" || fail 'restore host profile'

print -r -- 'ok - provisioning capabilities, retries, skips and dependency failures'

# Native fzf packages must not accidentally retain provisioning requirements.
ZI_EXTS=()
ZI_EXTS2=()
zsh_loaded_plugins=()
ZI_TASKS=()
ZI_RUN=()
ICE=()
expand fuzzy
(( $? == 2 )) || fail 'native fuzzy group needs no installer annex'
[[ ${ZI[annex-before-load:new-@]} == *"pack'native+keys' @fzf"* ]] || fail 'use first-party native package'
[[ ${_z_a_meta_plugins_map[fuzzy]} == fzf ]] || fail 'select one finder'
zsh_loaded_plugins=( fzf )
expand fuzzy '@following'
(( $? == 2 )) || fail 'repeat fuzzy group succeeds'
[[ ${ZI[annex-before-load:new-@]} == '@following' ]] || fail 'repeat preserves following request'
print -r -- 'ok - native fuzzy profile requires no installer and repeats without duplicate work'

zsh_loaded_plugins=()
expand fuzzy-src
(( $? == 2 )) || fail 'source fuzzy profile needs no installer annex'
[[ ${_z_a_meta_plugins_map[fuzzy-src]} == fzf-go ]] || fail 'build one finder'
[[ ${ZI[annex-before-load:new-@]} == *"pack'default+keys' id-as'fzf-go' teleid'fzf' git @fzf-go"* ]] || fail 'select first-party source profile'
print -r -- 'ok - source fuzzy profile builds one backend through the first-party package'

zsh_loaded_plugins=( fzf )
expand fuzzy-src '@following' 2>/dev/null
(( $? == 3 )) || fail 'reject a source finder over a loaded release finder'
[[ ${ZI[annex-before-load:new-@]} == '@following' ]] || fail 'preserve following request on finder conflict'
zsh_loaded_plugins=( fzf-go )
expand fuzzy '@following' 2>/dev/null
(( $? == 3 )) || fail 'reject a release finder over a loaded source finder'
zsh_loaded_plugins=( fzf )
typeset -ga ZI_REGISTERED_PLUGINS=( fzf-go )
expand fuzzy-src '@following'
(( $? == 2 )) || fail 'repeat source finder succeeds'
[[ ${ZI[annex-before-load:new-@]} == '@following' ]] || fail 'repeat source finder avoids duplicate work'
print -r -- 'ok - finder variants are exclusive and repeated source loading is a no-op'

zsh_loaded_plugins=()
ZI_REGISTERED_PLUGINS=()
expand ext-git
(( $? == 2 )) || fail 'interactive Git group needs no installer annex'
[[ ${_z_a_meta_plugins_map[ext-git]} == 'fuzzy wfxr/forgit paulirish/git-open' ]] || fail 'supply finder before Git tools'
[[ ${ZI[annex-before-load:new-@]} == *"pick'bin/git-forgit' src'forgit.plugin.zsh'"* ]] || fail 'expose native forgit command and shell integration'
[[ ${_z_a_meta_plugins_config_map[git-quick-stats/git-quick-stats]} != '' ]] || fail 'use canonical quick-stats owner'
print -r -- 'ok - interactive Git group supplies one finder and native commands'

expand zsh-tools
(( $? == 2 )) || fail 'expand development tools'
[[ ${_z_a_meta_plugins_map[zsh-tools]} == 'z-shell/zui z-shell/zsh-cmd-architect z-shell/zsh-editing-workbench z-shell/zbrowse' ]] || fail 'canonical development IDs and ZUI dependency'
[[ ${_z_a_meta_plugins_config_map[z-shell/zbrowse]} == *"compile'functions/zbr*~*.zwc'"* ]] || fail 'exclude existing compiled outputs'
[[ ${_z_a_meta_plugins_config_map[z-shell/zsh-editing-workbench]} != *zew_word_style* ]] || fail 'leave word-style ownership to user and plugin'
print -r -- 'ok - development group uses canonical recipes and preserves word-style ownership'

expand zunit
(( $? == 2 )) || fail 'test framework needs no installer annex'
[[ ${_z_a_meta_plugins_map[zunit]} == z-shell/zunit ]] || fail 'select bundled first-party framework'
print -r -- 'ok - test framework group has no duplicate helper dependencies'

ZI_EXTS[ice-mods]='cargo|rustup'
expand rust-utils
(( $? == 2 )) || fail 'expand Rust tools with registered installer'
[[ ${_z_a_meta_plugins_map[rust-utils]} == cargo-extensions ]] || fail 'do not install a toolchain'
[[ ${ZI[annex-before-load:new-@]} == *"cargo'cargo-expand;cargo-audit' pick'bin/cargo-expand'"* ]] || fail 'install focused extensions without shims'
[[ ${ZI[annex-before-load:new-@]} != *CARGO_HOME* && ${ZI[annex-before-load:new-@]} != *RUSTUP_HOME* ]] || fail 'preserve Rust roots'
print -r -- 'ok - Rust group installs focused extensions with existing toolchain and native commands'

expand py-utils
(( $? == 2 )) || fail 'Python group requires no installer annex'
[[ ${ZI[annex-before-load:new-@]} == *"pack'default' @pyenv"* ]] || fail 'use native first-party Python profile'
print -r -- 'ok - Python group selects the native root-preserving package'

ZI_SNIPPETS=()
expand ohmyzsh-lib
(( $? == 2 )) || fail 'expand OMZ compatibility snippets'
[[ ${ZI[annex-before-load:new-@]} == *'@OMZL::async_prompt.zsh'*'@OMZL::git.zsh'* ]] || fail 'load async prerequisite before Git'
[[ ${ZI[annex-before-load:new-@]} != *'@OMZL::git '* ]] || fail 'use actual OMZ filenames'
print -r -- 'ok - OMZ compatibility uses complete filenames and ordered prerequisites'

expand z-shell 2>/dev/null
(( $? == 2 )) || fail 'consume legacy editor label'
[[ ${ZI[annex-before-load:new-@]} == '@zsh-users+fast '* ]] || fail 'delegate to one editor profile'
[[ ${_z_a_meta_plugins_config_map[z-shell/H-S-MW]} != *page-size* ]] || fail 'preserve history-search preferences'
[[ ${_z_a_meta_plugins_config_map[z-shell/zsh-diff-so-fancy]} == *"as'program'"* ]] || fail 'use native optional Git formatter'
print -r -- 'ok - legacy editor bundle delegates without history or pager side effects'

expand z-shell+ '@following' 2>/dev/null
(( $? == 2 )) || fail 'consume retired session bundle successfully'
[[ ${ZI[annex-before-load:new-@]} == '@following' ]] || fail 'retired bundle preserves subsequent requests'
expand z-shell+ 2>/dev/null
(( $? == 2 )) || fail 'repeat retired session bundle successfully'
[[ -z ${ZI[annex-before-load:new-@]} ]] || fail 'retired session bundle installs nothing'
print -r -- 'ok - retired session bundle is an idempotent no-op'

expand sharkdp '@following' 2>/dev/null
(( $? == 2 )) || fail 'consume retired author bundle'
[[ ${ZI[annex-before-load:new-@]} == '@following' ]] || fail 'retired author bundle installs nothing'
_z_a_meta_plugins_map[diagnostics]='sharkdp/hexyl sharkdp/hyperfine sharkdp/vivid'
ZI_EXTS=()
expand diagnostics
(( $? == 2 )) || fail 'optional diagnostics require no installer annex'
[[ ${ZI[annex-before-load:new-@]} != *sbin* ]] || fail 'avoid binary wrapper dependency'
print -r -- 'ok - author bundle retires while explicitly selected diagnostics use native executables'
