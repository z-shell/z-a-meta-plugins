# Meta-Plugins support for Zsh-Zinit

### **Install groups of plugins via a single, friendly label …**
### **… and also have the curated, optimal ice lists automatically applied !**

![screenshot](https://raw.githubusercontent.com/zinit-zsh/z-a-meta-plugins/master/images/fuzzy-mplg-ex.png)

## Rationale

It can be tiring to:
1. Constantly, over and over collect some new interesting plugins to install/load.
2. Over and over reconstruct the new findings on the new machines.
3. Constantly extend and tweak the ice list of each plugin, so that it's hard on
  eyes, especially for an outsider.

Meta-Plugins annex helps in those problems:

| Problem                   | Solution |
|:-------------------------:|----------|
| (1)<br/> *finding new plugins*                              | the annex contains a curated, broad list of plugins, e.g.: all the console tools like `fd`, `fzf`, `exa`, `ripgrep`, etc., |
| (2)<br/> *reconstructing the findings in new environments*     | it's easy to say and memorize e.g.: `zinit for console-tools` – one label pulls a group of plugins and also the curated, optimal, default ice lists for each of them, |
| (3)<br/> *constant increase of complexity of the commands*  | the provided, hopefully best/optimal ices for each plugin are handled transparently and automatically; care is given to each ice list so that the plugin loads without any glitches (e.g.: without "No files for compilation found." message and other, even such slight issues). |

Other unique benefits of the Meta-Plugins annex:

| Benefit                   | Description |
|:-------------------------:|-------------|
|plugin dependencies                                            | The meta-plugins implement a dependency mechanism (to some extent), so that e.g.: selecting a from-source built [ogham/exa](https://github.com/ogham/exa) will automatically pull-in also the Rust compiler (available under meta-plugin name: `rust-toolchain`). |
|flexible disabling of chosen sub-plugins in any meta-plugin    | A meta-plugin can contain many sub-plugins and it's possible to skip installing some of them by the **skip'plg-1 plg-2…'** ice, e.g.: `zinit skip'ripgrep fd' for console-tools`. This way despite that some of the meta-plugins are broad the user still has control over what's and how much is being installed.|
|common from-source meta-plugins                                | For the plugins that provide the binary programs it is often the case that a meta-plugin exists that'll build the program from source (e.g.: **fuzzy** meta-plugin and its **fuzzy-src** counterpart). This might be handy e.g.: if there's no binary for our machine. |

## The list of the meta-plugins

|Meta-Plugin ID     | Contained sub-plugins |
|:-----------------:|-----------------------|
|annexes            |zinit-zsh/z-a-unscope zinit-zsh/z-a-as-monitor zinit-zsh/z-a-patch-dl zinit-zsh/z-a-rust zinit-zsh/z-a-submods zinit-zsh/z-a-bin-gem-node                        | 
|annexes+con        |zinit-zsh/zinit-console annexes                                                                                                                                  |
|                   |                                                                                                                                                                 |
|zsh-users          |zsh-users/zsh-syntax-highlighting zsh-users/zsh-autosuggestions zsh-users/zsh-completions                                                                        |
|zsh-users+fast     |zdharma/fast-syntax-highlighting zsh-users/zsh-autosuggestions zsh-users/zsh-completions                                                                         |
|                   |                                                                                                                                                                 |
|zdharma            |zdharma/fast-syntax-highlighting zdharma/history-search-multi-word zdharma/zsh-diff-so-fancy                                                                     |
|zdharma2           |zdharma/zconvey zdharma/zui zdharma/zflai                                                                                                                        |
|                   |                                                                                                                                                                 |
|molovo             |molovo/color molovo/revolver molovo/zunit                                                                                                                        |
|                   |                                                                                                                                                                 |
|sharkdp            |sharkdp/fd sharkdp/bat sharkdp/hexyl sharkdp/hyperfine sharkdp/vivid                                                                                             |
|                   |                                                                                                                                                                 |
|developer          |github-issues github-issues-srv molovo/color molovo/revolver molovo/zunit voronkovich/gitignore.plugin.zsh jonas/tig                                             |
|                   |                                                                                                                                                                 |
|console-tools      |dircolors-material sharkdp ogham/exa BurntSushi/ripgrep jonas/tig                                                                                                |
|                   |                                                                                                                                                                 |
|fuzzy              |fzf fzy lotabout/skim peco/peco                                                                                                                                  |
|fuzzy-src          |fzf-go fzy skim-cargo peco-go                                                                                                                                    |
|                   |                                                                                                                                                                 |
|ext-git            |Fakerr/git-recall paulirish/git-open paulirish/git-recent davidosomething/git-my arzzen/git-quick-stats iwata/git-now tj/git-extras wfxr/forgit                  |
|                   |                                                                                                                                                                 |
|rust-utils         |rust-toolchain cargo-extensions                                                                                                                                  |
|                   |                                                                                                                                                                 |
|prezto             |PZTM::archive PZTM::directory PZTM::utility                                                                                                                      |
|                   |                                                                                                                                                                 |
<!-- vim:set ft=markdown tw=81 fo+=a1n autoindent: -->
