<h1 align="center">
  <a href="https://github.com/z-shell/zi">
    <img align="center" src="https://github.com/z-shell/zi/raw/main/docs/images/logo.svg" alt="Logo" width="60px" height="60px" />
  </a> ❮ Zi ❯ Annex - meta-plugins </h1>
  <h2 align="center">
  <p> An annex delivers the capability to install a group of plugins via a single, friendly label </p></h2>
    <p><img align="center" src="https://raw.githubusercontent.com/z-shell/z-a-meta-plugins/main/docs/images/fuzzy-mplg-ex.png" alt="zi annex meta-plugins" width="100%" height="auto" /></p><hr />

## 💡 Wiki: [meta-plugins](https://wiki.zshell.dev/ecosystem/annexes/meta-plugins) - [annexes](https://wiki.zshell.dev/ecosystem/category/-annexes)

# Install

Simply load like a regular plugin, i.e.:

```zsh
zi light z-shell/z-a-meta-plugins
```

After executing this command you can then install meta plugins provided by the annex.

## Provisioning capabilities

Load the installers required by your selected recipes before loading a group.
The explicit `@annexes` bundle provides all four:

```zsh
zi light @annexes
zi light @console-tools
```

| Annex                      | Recipe capability                                  |
| -------------------------- | -------------------------------------------------- |
| `z-shell/z-a-bin-gem-node` | `sbin`, `fbin`, and `pack'bgn...'` binary wrappers |
| `z-shell/z-a-readurl`      | `dlink` and `.readurl` URL discovery               |
| `z-shell/z-a-patch-dl`     | `dl` and `patch` downloads                         |
| `z-shell/z-a-rust`         | `cargo` and `rustup` installation                  |

You can load just the required annex instead of the whole bundle. Loading the
Rust annex registers its capabilities; requesting a `cargo` or `rustup` recipe
performs installation. These installers must be ready before a dependent group,
so do not defer their loading past that group.

A selected recipe with a missing installer fails before its group is queued and
names the annex to load. Skipped recipes do not require their installers.
Repeating `@annexes` retries providers whose capabilities were not registered,
even if a previous failed attempt left their directories on disk.

`@annexes+` is deprecated and expands to the same four installers, with a
notice. Replace it with `@annexes` and load optional extensions explicitly. The
[migration guide](https://wiki.zshell.dev/ecosystem/annexes/meta-plugins#migrate-annexes+)
lists them, with the retired labels `@z-shell`, `@z-shell+` and `@sharkdp`.

## Editor profile

`zi light @zsh-users` loads completion definitions, initializes completion,
then loads autosuggestions and syntax highlighting. Load this group at the end
of your widget/plugin setup, before the first prompt. Its completion recipe
owns one `zicompinit` call, so omit a separate initialization for this profile.
It respects `ZI[COMPINIT_OPTS]` and `ZI[ZCOMPDUMP_PATH]`; it does not force `-C`.
Skipping the completion provider leaves initialization to your configuration.

Autosuggestions uses its normal upstream first-prompt setup. The recipe no
longer forces early widget rebinding or compiles development source files
that are not sourced by its distributed entrypoint. Repeating the group in
the same session does not initialize completion again.

`@zsh-users+fast` is the alternative profile with F-Sy-H last. Choose one
profile; loading both is rejected before the second group is queued. The
historical label does not promise better performance. F-Sy-H uses its own
defaults and the current `fsh_theme` command for user-selected themes; this
recipe no longer calls the removed `fast-theme` command or forces a theme.

The alternative profile no longer loads fancy-completions automatically. If
you want its completion policy, load `z-shell/zsh-fancy-completions` explicitly
before the editor profile and test it with your other completion extensions.

## Console tools

`@console-tools` provides `fd`, `bat`, `eza`, and `rg`, without replacing `ls`
or other standard commands with aliases. Existing commands on `PATH` take
precedence. Newly installed executables use Zi's native program loading,
without requiring bin-gem-node shims. Hexyl and hyperfine are no longer part
of the everyday group.

The fd, bat, and ripgrep recipes select x86-64 or ARM64 Linux musl archives,
or matching macOS archives. Other targets require existing system commands.
The tested eza binary recipe is x86-64 Linux musl and fetches its completion
archive from the same release. On macOS and other targets, install system eza
first; the group does not install a Rust toolchain. Skipping eza explicitly
also permits loading the remaining tools.

For aliases and listing styles, use the maintained `z-shell/zsh-eza` shell
integration after eza is available. It uses `:zsh-eza:config` styles and leaves
automatic directory listing disabled by default. Its documented aliases are
an explicit shell-styling choice, separate from the executable group.

## Console styling

`@console-style` now loads `z-shell/zsh-eza`. It provides the `ls`, `l`, `ll`,
`llm`, `la`, `lx`, `lt`, and `tree` aliases using your configured eza styles.
Configure `:zsh-eza:config` before loading the group. Its unload function
restores aliases that the plugin still owns and preserves later user changes.

This group no longer installs dircolors-material or vivid. `LS_COLORS` and
completion color styles remain yours to configure; no new color cache or
generator runs at startup. If you explicitly want a different color policy,
review the first-party `ls_colors` or `dircolors-material` Zi package profiles
and choose one. They are not loaded alongside the default style group.

## Fuzzy finder

`@fuzzy` now selects fzf alone through the first-party `z-shell/fzf`
`native+keys` package profile. It uses a release binary and matching cached
shell integration, with no Go/Rust build or bin-gem-node/patch-dl requirement.
The package profile must be available before using this updated group.

The upstream bindings are Ctrl-R for history, Ctrl-T for files, and Alt-C for
changing directories. Set `FZF_CTRL_R_COMMAND`, `FZF_CTRL_T_COMMAND`, or
`FZF_ALT_C_COMMAND` to an empty string before loading to disable that binding.
Load this group before the editor profile so its widgets precede highlighting.
Completion integration is included; fzf-tab is a separate completion-policy
choice and is not installed by this group.

`@fuzzy-src` is the explicit fzf source-build alternative. It uses the corrected
first-party `default+keys` profile and requires an existing compatible Go
compiler, make, and Git. Go modules download during the build, but the profile
does not install a compiler. A compiler that cannot build the upstream source
causes installation to fail. Choose either `@fuzzy` or `@fuzzy-src`; the source
group is not an automatic fallback and does not build other finders.

Fzy, Skim and peco are no longer installed together with fzf. Choose another
finder explicitly if it fits your workflow. Use their upstream installation instructions; the unused legacy recipes are
removed rather than presenting obsolete installers as supported alternatives.

## Interactive Git

`@ext-git` provides the first-party fzf package through `@fuzzy`, forgit, and
`git open`. It exposes `git forgit` and the `forgit::` shell functions without
requiring installer annexes. Forgit requires fzf 0.60.0 or later; the supplied
package provides a current release. If you skip fzf, supply a compatible
executable yourself. To use the source finder, load `@fuzzy-src` first and
skip the nested `fuzzy` group when loading `@ext-git`.

Forgit's short aliases are disabled by default to preserve existing Git
aliases. Set `FORGIT_NO_ALIASES=''` before loading to explicitly enable its
upstream aliases, or define your own aliases for `forgit::add`, `forgit::log`,
and other functions. Export other `FORGIT_*` settings before loading.
`git open --print` prints a repository URL without launching a browser.

The group does not change global Git configuration or select a pager. Tig,
git-extras, git-recent and git-quick-stats remain separate choices; the
[migration guide](https://wiki.zshell.dev/ecosystem/annexes/meta-plugins#migrate-ext-git)
gives their commands. Git-my, git-now and the separate gitignore plugin are no
longer defaults because their roles overlap or are more specialized than this
workflow.

## Zsh development tools

`@zsh-tools` is an explicit development-workbench choice: ZUI, command
architect, editing workbench and ZBrowse. ZUI is required by ZBrowse and stays
first. All IDs use their canonical `z-shell/` prefix, so their recipes apply.
The workbench respects an existing `zew_word_style` instead of forcing
whitespace behavior.

These plugins deliberately change editing behavior. Command architect binds
Ctrl-T, ZBrowse binds Ctrl-B, and editing workbench owns several Alt bindings,
Ctrl-W, Ctrl-J and undo. Ctrl-T overlaps fzf file selection, and Ctrl-B replaces
backward-character in the default Emacs map. Choose which tool owns each key
and rebind after loading when combining groups. The plugins create their own
configuration files and ZBrowse tracks interactive parameter changes.

## ZUnit

`@zunit` builds the active first-party `z-shell/zunit` framework and installs
its completion. Its color and progress helpers are bundled into the executable;
separate `zdharma/color` and `zdharma/revolver` installations are no longer
needed. The command uses native Zi program loading without installer annexes.
Updating the plugin rebuilds the executable and refreshes the completion file.

## Node manager

`@node-utils` installs `n` without downloading or selecting a Node version.
It preserves `N_PREFIX`; when unset or empty, the prefix defaults to
`${XDG_DATA_HOME:-$HOME/.local/share}/n`, outside the plugin checkout. Its bin
directory is appended once, so an existing earlier Node command keeps priority.
Use `n <version>` explicitly to install a runtime. If another Node installation
has priority, choose your PATH ordering explicitly before switching to n.
No directory-change hook or second version manager is enabled.

---

> **Note**
>
> - This repository compatible with [Zi](https://github.com/z-shell/zi)

### Rust development tools (`@rust-utils`)

This opt-in group installs `cargo-expand` for inspecting macro expansion and
`cargo-audit` for checking dependency advisories through the first-party Rust
annex. An existing Cargo and Rust compiler are required. It preserves
`CARGO_HOME`, `RUSTUP_HOME` and the selected toolchain, and installs extension
binaries into Zi's plugin directory. It neither installs nor selects a toolchain.

The group no longer installs eight extensions or replaces the user's Rust
roots. Cargo already provides `cargo tree`; other extensions remain explicit
user choices. The former `rust-toolchain` recipe is removed. Manage toolchains
separately with your existing Rust installation method.

Run `cargo expand --help` and `cargo audit --help` for supported options.
Expansion may require a compatible compiler; this group does not download one.
An audit fetches advisory data when explicitly invoked, not on shell startup.
Updates use Cargo's own version checks without unconditional forced rebuilds.
Zi prepends the extension binary directory to PATH, so its installed extensions
take precedence. Only the two selected crates are installed on a fresh setup.
Old binaries and installer-generated shims are not deleted automatically; review
those separately when migrating an existing installation.

### Python versions (`@py-utils`)

This group keeps pyenv through its first-party native package profile. Set
`PYENV_ROOT` before loading to reuse installed interpreters; otherwise pyenv uses
`$HOME/.pyenv`. The group initializes Zsh and shims but installs no interpreter
and changes no global or project version selection. `pyenv shell` remains
available for an explicit session override.

Users of the former checkout-root profile must keep `PYENV_ROOT` pointing at
that existing installation until they intentionally migrate it. uv is a
separate project/tool workflow, not an automatic replacement in this group.

### Prezto compatibility (`@prezto`)

Use `zi light-mode for @prezto` for this snippet group. Zi's classic `light`
command forces plugin dispatch; the `for` form supports mixed snippet groups.
Archive and utility load complete module directories through Zi's Git sparse
backend. Utility's helper and spectrum dependencies use Zi's existing
`pmodload` compatibility. No full Prezto startup files are sourced.

This is an opt-in framework compatibility profile, not a neutral utility
bundle: directory and utility define aliases and change directory/navigation,
correction and other shell options. Spectrum supplies color state. Existing
Prezto zstyles control those behaviors; set them before loading. Do not combine
this profile with the Oh My Zsh library profile or assume it preserves aliases.

### Oh My Zsh compatibility (`@ohmyzsh-lib`)

Use `zi light-mode for @ohmyzsh-lib`. This explicitly loads OMZ library behavior,
including history, completion styles, aliases, keybindings, prompt defaults,
colors and terminal-title hooks. It is not a full Oh My Zsh installation;
framework management commands require a separately configured OMZ installation.
Do not combine it with `@prezto` or treat it as a neutral helper bundle.

The async prompt library loads before Git helpers, and general functions load
before terminal support. Zi initializes completion and replays captured
registrations before loading completion styles. An existing `ZSH_CACHE_DIR` is
preserved; otherwise the completion cache uses Zi's cache directory. Set OMZ
preferences before loading. No update checker or full framework startup script
is loaded. Repeating the group skips snippets already registered by Zi.

### Prompt choice (`@romkatv`)

This group loads only Powerlevel10k. It sources `${ZDOTDIR:-$HOME}/.p10k.zsh`
when present and leaves `POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD` under user
control. Existing users with a custom ZDOTDIR should move or explicitly source
their former HOME configuration. Configure before loading another prompt; do
not combine prompt engines. Repeat group loading preserves later user changes.

[Powerlevel10k](https://github.com/romkatv/powerlevel10k#readme) currently declares
very limited support. It remains an explicit choice; this is not a performance
assessment. Instant prompt requires placement near the beginning of your own
startup file, following upstream instructions. The annex does not rewrite it.
[Pure](https://github.com/sindresorhus/pure#install) is a separate minimal prompt
alternative; follow its normal setup instead of loading `@romkatv` too.

## Retired labels

`@z-shell`, `@z-shell+` and `@sharkdp` install nothing. Each prints one notice
per session that links its subsection of the
[migration guide](https://wiki.zshell.dev/ecosystem/annexes/meta-plugins#migration-from-earlier-catalogs),
which gives the replacement commands for every former member and the reasons
for the change. Remove the label from your startup file; existing
installations are not deleted. A `skip''` token that names no current member of
a group is reported on every load, with a link to the group's subsection when
the guide has one.

## Regression measurements

The [group benchmark guide](../benchmarks/README.md) covers reporting-only
comparisons for shared loading, editor profiles, fzf and pyenv, including an
optional pinned `z-shell/zd` runtime. Correctness failures invalidate timings.
