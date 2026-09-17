<div align="center">
  <a href="https://github.com/z-shell/z-a-meta-plugins">
    <img
      src="https://raw.githubusercontent.com/z-shell/zi/main/docs/images/logo.svg"
      alt="Z-Shell logo"
      width="72"
      height="72"
    />
  </a>

  <h1>meta-plugins</h1>
  <p>A Zi annex that installs a curated group of plugins through one friendly label.</p>
  <p>
    <a href="https://github.com/z-shell/z-a-meta-plugins/actions/workflows/zsh-n.yml">
      <img
        src="https://github.com/z-shell/z-a-meta-plugins/actions/workflows/zsh-n.yml/badge.svg?branch=main"
        alt="Zsh checks status"
      />
    </a>
    <a href="https://github.com/z-shell/z-a-meta-plugins/actions/workflows/zsh-lint.yml">
      <img
        src="https://github.com/z-shell/z-a-meta-plugins/actions/workflows/zsh-lint.yml/badge.svg?branch=main"
        alt="Zsh Lint status"
      />
    </a>
    <a href="../LICENSE">
      <img
        src="https://img.shields.io/github/license/z-shell/z-a-meta-plugins"
        alt="License"
      />
    </a>
  </p>
</div>

## Features

- One label, such as `@zsh-users` or `@console-tools`, queues a curated group of plugins with a tested ice list for every member.
- `skip''` drops members by full ID, repository name, or nested label, and forwards matching tokens to a nested group.
- A group whose recipes need an installer annex that is not loaded, a release binary the platform cannot receive, or a second highlighter or fzf build is refused before anything is queued, with a message that names what to load first. Build toolchains such as Go or make are not checked; `@fuzzy-src` fails during installation when they are missing.
- Members that Zi has already loaded or queued, and release binaries already on `PATH`, are not installed again.
- Deprecated and retired labels print one notice per session that links their subsection of the migration guide.
- Repository tests keep every label, recipe, notice, and migration anchor consistent, and check that each recipe parses natively.

## Requirements

- Zsh 5.9.2 or newer
- [Zi](https://github.com/z-shell/zi) with its annex hook API; the annex registers a `before-load` hook and the `skip''` ice

> [!NOTE]
> Some groups need one of the installer annexes before they load. `@annexes` loads all four; the [Usage](#usage) notes name the one each group needs.

## Installation

### Zi

```zsh
zi light z-shell/z-a-meta-plugins
```

Annexes extend Zi and depend on its hook API, so there is no other plugin-manager path. Load the annex before the first label; the labels below do nothing until the annex is loaded.

## Usage

Load a group like a plugin, with the `@` prefix:

```zsh
zi light @zsh-users
```

Drop members with `skip''`, which also reaches a nested label:

```zsh
zi light-mode for @annexes \
  skip'zsh-completions' @zsh-users \
  skip'eza ripgrep' @console-tools \
  skip'fzf' @ext-git
```

The [wiki catalog](https://wiki.zshell.dev/ecosystem/annexes/meta-plugins#available-meta-plugins) lists every member in loading order with what each group requires. The labels are:

| Label             | Installs                                                      | Before loading                               |
| :---------------- | :------------------------------------------------------------ | :------------------------------------------- |
| `@annexes`        | bin-gem-node, readurl, patch-dl, and rust installer annexes   | Nothing                                      |
| `@zsh-users`      | zsh-completions, zsh-autosuggestions, zsh-syntax-highlighting | Nothing; load it last                        |
| `@zsh-users+fast` | zsh-completions, zsh-autosuggestions, F-Sy-H                  | Nothing; not together with `@zsh-users`      |
| `@console-tools`  | fd, bat, eza, ripgrep release binaries                        | System eza outside Linux x86-64              |
| `@console-style`  | zsh-eza aliases                                               | `@console-tools` or a system eza             |
| `@fuzzy`          | fzf release binary with shell integration and key bindings    | Nothing                                      |
| `@fuzzy-src`      | fzf built from source                                         | Go, make, Git; not together with `@fuzzy`    |
| `@ext-git`        | `@fuzzy`, forgit, git-open                                    | Nothing                                      |
| `@zsh-tools`      | zui, zsh-cmd-architect, zsh-editing-workbench, zbrowse        | Nothing                                      |
| `@zunit`          | zunit with its completion                                     | Nothing                                      |
| `@node-utils`     | n                                                             | Nothing                                      |
| `@rust-utils`     | cargo-expand and cargo-audit                                  | `z-shell/z-a-rust` and a Rust toolchain      |
| `@py-utils`       | pyenv package profile                                         | Nothing                                      |
| `@prezto`         | Prezto archive, directory, and utility modules                | `zi light-mode for`; not with `@ohmyzsh-lib` |
| `@ohmyzsh-lib`    | Oh My Zsh library files in dependency order                   | `zi light-mode for`; not with `@prezto`      |
| `@romkatv`        | Powerlevel10k                                                 | Nothing; one prompt engine                   |

`@annexes+` is deprecated and expands to the same four installers as `@annexes`, with a notice. `@z-shell`, `@z-shell+`, and `@sharkdp` are retired: each installs nothing and prints one notice per session that links its subsection of the [migration guide](https://wiki.zshell.dev/ecosystem/annexes/meta-plugins#migration-from-earlier-catalogs), which gives the replacement commands for every former member. Remove the label from your startup file; existing installations are not deleted.

The notes below cover what each group changes in your shell and what it leaves to you.

<details>
<summary>Provisioning: <code>@annexes</code></summary>

Load the installers required by your selected recipes before loading a group. The explicit `@annexes` bundle provides all four:

```zsh
zi light @annexes
zi light @console-tools
```

| Annex                      | Recipe capability                                  |
| :------------------------- | :------------------------------------------------- |
| `z-shell/z-a-bin-gem-node` | `sbin`, `fbin`, and `pack'bgn...'` binary wrappers |
| `z-shell/z-a-readurl`      | `dlink` and `.readurl` URL discovery               |
| `z-shell/z-a-patch-dl`     | `dl` and `patch` downloads                         |
| `z-shell/z-a-rust`         | `cargo` and `rustup` installation                  |

You can load just the required annex instead of the whole bundle. Loading the Rust annex registers its capabilities; requesting a `cargo` or `rustup` recipe performs installation. These installers must be ready before a dependent group, so do not defer their loading past that group.

A selected recipe with a missing installer fails before its group is queued and names the annex to load. Skipped recipes do not require their installers. Repeating `@annexes` retries providers whose capabilities were not registered, even if a previous failed attempt left their directories on disk.

</details>

<details>
<summary>Editor profile: <code>@zsh-users</code> and <code>@zsh-users+fast</code></summary>

`zi light @zsh-users` loads completion definitions, initializes completion, then loads autosuggestions and syntax highlighting. Load this group at the end of your widget and plugin setup, before the first prompt. Its completion recipe owns one `zicompinit` call, so omit a separate initialization for this profile. It respects `ZI[COMPINIT_OPTS]` and `ZI[ZCOMPDUMP_PATH]`; it does not force `-C`. Skipping the completion provider leaves initialization to your configuration.

Autosuggestions uses its normal upstream first-prompt setup. The recipe does not force early widget rebinding or compile development source files that are not sourced by its distributed entrypoint. Repeating the group in the same session does not initialize completion again.

`@zsh-users+fast` is the alternative profile with F-Sy-H last. Choose one profile; loading a second highlighter is rejected before the second group is queued. The label does not promise better performance. F-Sy-H uses its own defaults and the current `fsh_theme` command for user-selected themes; this recipe does not call the removed `fast-theme` command or force a theme.

Neither profile loads fancy-completions. If you want its completion policy, load `z-shell/zsh-fancy-completions` explicitly before the editor profile and test it with your other completion extensions.

</details>

<details>
<summary>Console tools: <code>@console-tools</code></summary>

`@console-tools` provides `fd`, `bat`, `eza`, and `rg`, without replacing `ls` or other standard commands with aliases. Existing commands on `PATH` take precedence. Newly installed executables use Zi's native program loading, without requiring bin-gem-node shims. Hexyl and hyperfine are not part of the everyday group.

The fd, bat, and ripgrep recipes select x86-64 or ARM64 Linux musl archives, or matching macOS archives. Other targets require existing system commands. The tested eza binary recipe is x86-64 Linux musl and fetches its completion archive from the same release. On macOS and other targets, install system eza first; the group does not install a Rust toolchain. Skipping eza explicitly also permits loading the remaining tools.

For aliases and listing styles, use the maintained `z-shell/zsh-eza` shell integration after eza is available. It uses `:zsh-eza:config` styles and leaves automatic directory listing disabled by default. Its documented aliases are an explicit shell-styling choice, separate from the executable group.

</details>

<details>
<summary>Console styling: <code>@console-style</code></summary>

`@console-style` loads `z-shell/zsh-eza`. It provides the `ls`, `l`, `ll`, `llm`, `la`, `lx`, `lt`, and `tree` aliases using your configured eza styles. Configure `:zsh-eza:config` before loading the group. Its unload function restores aliases that the plugin still owns and preserves later user changes.

This group does not install dircolors-material or vivid. `LS_COLORS` and completion color styles remain yours to configure; no new color cache or generator runs at startup. If you explicitly want a different color policy, review the first-party `ls_colors` or `dircolors-material` Zi package profiles and choose one. They are not loaded alongside the default style group.

</details>

<details>
<summary>Fuzzy finder: <code>@fuzzy</code> and <code>@fuzzy-src</code></summary>

`@fuzzy` selects fzf alone through the first-party `z-shell/fzf` `native+keys` package profile. It uses a release binary and matching cached shell integration, with no Go or Rust build and no bin-gem-node or patch-dl requirement. The package profile must be available before using this group.

The upstream bindings are Ctrl-R for history, Ctrl-T for files, and Alt-C for changing directories. Set `FZF_CTRL_R_COMMAND`, `FZF_CTRL_T_COMMAND`, or `FZF_ALT_C_COMMAND` to an empty string before loading to disable that binding. Load this group before the editor profile so its widgets precede highlighting. Completion integration is included; fzf-tab is a separate completion-policy choice and is not installed by this group.

`@fuzzy-src` is the explicit fzf source-build alternative. It uses the first-party `default+keys` profile and requires an existing compatible Go compiler, make, and Git. Go modules download during the build, but the profile does not install a compiler. A compiler that cannot build the upstream source causes installation to fail. Choose either `@fuzzy` or `@fuzzy-src`; the source group is not an automatic fallback and does not build other finders.

Fzy, Skim, and peco are not installed together with fzf. Choose another finder explicitly if it fits your workflow and use its upstream installation instructions.

</details>

<details>
<summary>Interactive Git: <code>@ext-git</code></summary>

`@ext-git` provides the first-party fzf package through `@fuzzy`, forgit, and `git open`. It exposes `git forgit` and the `forgit::` shell functions without requiring installer annexes. Forgit requires fzf 0.60.0 or later; the supplied package provides a current release. If you skip fzf, supply a compatible executable yourself. To use the source finder, load `@fuzzy-src` first and skip the nested `fuzzy` group when loading `@ext-git`.

Forgit's short aliases are disabled by default to preserve existing Git aliases. Set `FORGIT_NO_ALIASES=''` before loading to explicitly enable its upstream aliases, or define your own aliases for `forgit::add`, `forgit::log`, and other functions. Export other `FORGIT_*` settings before loading. `git open --print` prints a repository URL without launching a browser.

The group does not change global Git configuration or select a pager. Tig, git-extras, git-recent, and git-quick-stats remain separate choices; the [ext-git migration section](https://wiki.zshell.dev/ecosystem/annexes/meta-plugins#migrate-ext-git) gives their commands.

</details>

<details>
<summary>Zsh development tools: <code>@zsh-tools</code></summary>

`@zsh-tools` is an explicit development-workbench choice: ZUI, command architect, editing workbench, and ZBrowse. ZUI is required by ZBrowse and stays first. All IDs use their canonical `z-shell/` prefix, so their recipes apply. The workbench respects an existing `zew_word_style` instead of forcing whitespace behavior.

These plugins deliberately change editing behavior. Command architect binds Ctrl-T, ZBrowse binds Ctrl-B, and editing workbench owns several Alt bindings, Ctrl-W, Ctrl-J, and undo. Ctrl-T overlaps fzf file selection, and Ctrl-B replaces backward-character in the default Emacs map. Choose which tool owns each key and rebind after loading when combining groups. The plugins create their own configuration files and ZBrowse tracks interactive parameter changes.

</details>

<details>
<summary>ZUnit: <code>@zunit</code></summary>

`@zunit` builds the first-party `z-shell/zunit` framework and installs its completion. Its color and progress helpers are bundled into the executable; separate `zdharma/color` and `zdharma/revolver` installations are not needed. The command uses native Zi program loading without installer annexes. Updating the plugin rebuilds the executable and refreshes the completion file.

</details>

<details>
<summary>Node manager: <code>@node-utils</code></summary>

`@node-utils` installs `n` without downloading or selecting a Node version. It preserves `N_PREFIX`; when unset or empty, the prefix defaults to `${XDG_DATA_HOME:-$HOME/.local/share}/n`, outside the plugin checkout. Its bin directory is appended once, so an existing earlier Node command keeps priority. Use `n <version>` explicitly to install a runtime. If another Node installation has priority, choose your PATH ordering explicitly before switching to n. No directory-change hook or second version manager is enabled.

</details>

<details>
<summary>Rust development tools: <code>@rust-utils</code></summary>

This opt-in group installs `cargo-expand` for inspecting macro expansion and `cargo-audit` for checking dependency advisories through the first-party Rust annex. An existing Cargo and Rust compiler are required. It preserves `CARGO_HOME`, `RUSTUP_HOME`, and the selected toolchain, and installs extension binaries into Zi's plugin directory. It neither installs nor selects a toolchain. Cargo already provides `cargo tree`; other extensions remain explicit user choices. Manage toolchains separately with your existing Rust installation method.

Run `cargo expand --help` and `cargo audit --help` for supported options. Expansion may require a compatible compiler; this group does not download one. An audit fetches advisory data when explicitly invoked, not on shell startup. Updates use Cargo's own version checks without unconditional forced rebuilds. Zi prepends the extension binary directory to PATH, so its installed extensions take precedence. Old binaries and installer-generated shims are not deleted automatically; review those separately when migrating an existing installation.

</details>

<details>
<summary>Python versions: <code>@py-utils</code></summary>

This group loads pyenv through its first-party native package profile. Set `PYENV_ROOT` before loading to reuse installed interpreters; otherwise pyenv uses `$HOME/.pyenv`. The group initializes Zsh and shims but installs no interpreter and changes no global or project version selection. `pyenv shell` remains available for an explicit session override.

Users of the former checkout-root profile must keep `PYENV_ROOT` pointing at that existing installation until they intentionally migrate it. uv is a separate project and tool workflow, not an automatic replacement in this group.

</details>

<details>
<summary>Prezto compatibility: <code>@prezto</code></summary>

Use `zi light-mode for @prezto` for this snippet group. Zi's classic `light` command forces plugin dispatch; the `for` form supports mixed snippet groups. Archive and utility load complete module directories through Zi's Git sparse backend. Utility's helper and spectrum dependencies use Zi's existing `pmodload` compatibility. No full Prezto startup files are sourced.

This is an opt-in framework compatibility profile, not a neutral utility bundle: directory and utility define aliases and change directory, navigation, correction, and other shell options. Spectrum supplies color state. Existing Prezto zstyles control those behaviors; set them before loading. Do not combine this profile with the Oh My Zsh library profile or assume it preserves aliases.

</details>

<details>
<summary>Oh My Zsh compatibility: <code>@ohmyzsh-lib</code></summary>

Use `zi light-mode for @ohmyzsh-lib`. This explicitly loads OMZ library behavior, including history, completion styles, aliases, keybindings, prompt defaults, colors, and terminal-title hooks. It is not a full Oh My Zsh installation; framework management commands require a separately configured OMZ installation. Do not combine it with `@prezto` or treat it as a neutral helper bundle.

The async prompt library loads before Git helpers, and general functions load before terminal support. Zi initializes completion and replays captured registrations before loading completion styles. An existing `ZSH_CACHE_DIR` is preserved; otherwise the completion cache uses Zi's cache directory. Set OMZ preferences before loading. No update checker or full framework startup script is loaded. Repeating the group skips snippets already registered by Zi.

</details>

<details>
<summary>Prompt choice: <code>@romkatv</code></summary>

This group loads only Powerlevel10k. It sources `${ZDOTDIR:-$HOME}/.p10k.zsh` when present and leaves `POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD` under user control. Existing users with a custom ZDOTDIR should move or explicitly source their former HOME configuration. Configure before loading another prompt; do not combine prompt engines. Repeat group loading preserves later user changes.

[Powerlevel10k](https://github.com/romkatv/powerlevel10k#readme) currently declares very limited support. It remains an explicit choice; this is not a performance assessment. Instant prompt requires placement near the beginning of your own startup file, following upstream instructions. The annex does not rewrite it. [Pure](https://github.com/sindresorhus/pure#install) is a separate minimal prompt alternative; follow its normal setup instead of loading `@romkatv` too.

</details>

## Configuration

The annex owns no `zstyle` context. It is configured per load through ices on the label, and the members are configured through their own settings before the label loads.

| Setting                                                         | Applies to            | Effect                                                                                     |
| :-------------------------------------------------------------- | :-------------------- | :----------------------------------------------------------------------------------------- |
| `skip'member ...'` ice                                          | Any label             | Drops the named members; a token that matches nothing is reported with the current members |
| `debug''` ice                                                   | Any label             | Prints which members are skipped because they are already loaded                           |
| `ZI[COMPINIT_OPTS]`, `ZI[ZCOMPDUMP_PATH]`                       | `@zsh-users` profiles | Passed to the one `zicompinit` call the completion recipe owns                             |
| `FZF_CTRL_R_COMMAND`, `FZF_CTRL_T_COMMAND`, `FZF_ALT_C_COMMAND` | `@fuzzy`, `@ext-git`  | An empty value disables that key binding                                                   |
| `FORGIT_NO_ALIASES` and other `FORGIT_*`                        | `@ext-git`            | Short aliases stay disabled unless `FORGIT_NO_ALIASES` is exported empty                   |
| `N_PREFIX`                                                      | `@node-utils`         | Preserved; defaults to `${XDG_DATA_HOME:-$HOME/.local/share}/n`                            |
| `PYENV_ROOT`                                                    | `@py-utils`           | Preserved; defaults to `$HOME/.pyenv`                                                      |
| `ZSH_CACHE_DIR`                                                 | `@ohmyzsh-lib`        | Preserved; defaults to Zi's cache directory                                                |
| `:zsh-eza:config` styles                                        | `@console-style`      | Read by zsh-eza when the group loads                                                       |

> [!IMPORTANT]
> `@annexes+`, `@z-shell`, `@z-shell+`, and `@sharkdp` changed meaning. Follow the [migration guide](https://wiki.zshell.dev/ecosystem/annexes/meta-plugins#migration-from-earlier-catalogs) for the replacement commands.

## Lifecycle and side effects

- Loading the annex appends its `functions/` directory to `fpath` when the manager does not handle that itself, defines the `_z_a_meta_plugins_*` state parameters, and registers the `before-load` hook with the `skip''` ice. Nothing is installed and no network activity happens until a label is loaded through Zi.
- Loading a label rewrites Zi's queue with the group's members and their ice lists. Members already loaded, already queued, or present on `PATH` for release-binary recipes are left out. A missing installer annex, an unsupported release-binary platform without the tool on `PATH`, or a conflicting highlighter or fzf build refuses the whole group before any member is queued; build toolchains are not checked.
- A deprecated or retired label prints its notice once per session, inside the numbered message cluster. An unmatched `skip''` token is reported on every load.
- `z-a-meta-plugins_plugin_unload` removes the `fpath` entry, unregisters the hook when Zi provides `@zi-unregister-annex` and otherwise neutralizes the handler in place, unsets every state parameter, and removes itself. Plugins installed through labels stay installed.

## Portable shell contract

| Item                         | Value                                                                                                           |
| :--------------------------- | :-------------------------------------------------------------------------------------------------------------- |
| Project identifier           | `z-a-meta-plugins`; persistent shell names use the `_z_a_meta_plugins_` prefix                                  |
| Authoritative entrypoint     | `z-a-meta-plugins.plugin.zsh`                                                                                   |
| Zi registration              | `@zi-register-annex "z-a-meta-plugins" hook:before-load-4`, registering the `skip''` ice                        |
| Public configuration context | None; see [Configuration](#configuration)                                                                       |
| Public functions             | None; `_z_a_meta_plugins_before_load_handler` is the autoloaded Zi hook                                         |
| State parameters             | `_z_a_meta_plugins_state`, `_z_a_meta_plugins_notices`, `_z_a_meta_plugins_map`, `_z_a_meta_plugins_config_map` |
| Unload function              | `z-a-meta-plugins_plugin_unload`                                                                                |
| Optional directories         | `functions/` for the autoloaded handler                                                                         |

## Verification

From the repository root, run the test suite the way CI does:

```bash
zsh -f -c 'setopt err_exit; for t in tests/*.zsh; do print -r -- "== $t"; zsh -f "$t"; done'
```

The tests need only Zsh; they stub the Zi API and touch no network. `tests/catalog-consistency.zsh` fails when a label, a recipe, a notice, or a migration anchor falls out of step with the rest of the catalog. `tests/readme-structure.zsh` fails when this file drops a section the organization README template requires.

The CI-pinned [zsh-lint](https://github.com/z-shell/zsh-lint) profile reads `zsh-lint.json`:

```bash
zsh-lint --config zsh-lint.json z-a-meta-plugins.plugin.zsh functions/*
```

The [group benchmark guide](../benchmarks/README.md) covers reporting-only timing comparisons for shared loading, editor profiles, fzf, and pyenv, including an optional pinned `z-shell/zd` runtime. Correctness failures invalidate timings.

## Documentation and support

- [meta-plugins on the Z-Shell wiki](https://wiki.zshell.dev/ecosystem/annexes/meta-plugins): the full catalog and the migration guide
- [Zi annexes](https://wiki.zshell.dev/ecosystem/category/-annexes)
- [Zsh Plugin Standard](https://wiki.zshell.dev/community/zsh_plugin_standard)
- [Zsh documentation](https://zsh.sourceforge.io/Doc/)
- [Zi plugin manager](https://github.com/z-shell/zi)
- [Report an issue](https://github.com/z-shell/z-a-meta-plugins/issues)

## Release model

The annex is consumed directly from Git. Contributions integrate on `main` through short-lived topic branches and pull requests; there is no versioned artifact and no persistent integration branch.

## Contributing and license

Contributions follow the [Z-Shell organization guidance](https://github.com/z-shell/.github). This project is distributed under the terms in [LICENSE](../LICENSE).

---

<div align="center">
  <p>Developed with ❤️ by the <a href="https://github.com/z-shell">Z-Shell Community</a>.</p>
</div>
