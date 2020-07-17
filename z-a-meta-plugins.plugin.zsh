# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-

# Copyright (c) 2020 Sebastian Gniazdowski

# According to the Zsh Plugin Standard:
# http://zdharma.org/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html#zero-handling

0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

typeset -gA Zinit_Annex_Meta_Plugins
Zinit_Annex_Meta_Plugins[0]="$0" Zinit_Annex_Meta_Plugins[repo-dir]="${0:h}"

# Standard hash for plugins:
# http://zdharma.org/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html#std-hash
typeset -gA Plugins
Plugins[META_PLUGINS_DIR]="${0:h}"

autoload -Uz ∧za-meta-plugins-before-load-handler \
    ∧za-meta-plugins-meta-cmd-help-handler \
    ∧za-meta-plugins-meta-cmd

# An empty stub to fill the help handler fields
∧za-meta-plugins-help-null-handler() { :; }

# The unscoping-support hook.
@zinit-register-annex "z-a-meta-plugins" \
    hook:before-load-4 \
    ∧za-meta-plugins-before-load-handler \
    ∧za-meta-plugins-help-null-handler

# The subcommand `meta'.
@zinit-register-annex "z-a-meta-plugins" \
    subcommand:meta \
    ∧za-meta-plugins-meta-cmd \
    ∧za-meta-plugins-meta-cmd-help-handler

# The map in which the definitions of
# the meta-plugins are being stored.
typeset -gA Zinit_Annex_Meta_Plugins_Map
Zinit_Annex_Meta_Plugins_Map=(
    sharkdp     "sharkdp/fd sharkdp/bat sharkdp/hexyl sharkdp/hyperfine sharkdp/vivid"
    file-utils  "ogham/exa sharkdp/fd sharkdp/bat"
    zsh-users   "zsh-users/zsh-syntax-highlighting zsh-users/zsh-autosuggestions zsh-users/zsh-completions"
    zsh-users+fast "zdharma/fast-syntax-highlighting zsh-users/zsh-autosuggestions zsh-users/zsh-completions"
    zdharma     "zdharma/fast-syntax-highlighting zdharma/history-search-multi-word zdharma/zsh-diff-so-fancy"
    zdharma2    "zdharma/zconvey zdharma/zui zdharma/zflai"

    developer   "github-issues github-issues-srv molovo/color molovo/revolver molovo/zunit"

    molovo      "molovo/color molovo/revolver molovo/zunit"

    console-tools "sharkdp ogham/exa"
)

# The map in which the default sets of ices
# for the real plugins are being stored.
typeset -gA Zinit_Annex_Meta_Plugins_Config_Map
typeset -g _std="lucid"
Zinit_Annex_Meta_Plugins_Config_Map=(
    # @zinit-zsh (all annexes + extensions, without Meta-Plugins, obviously)
    zinit-zsh/zinit-console     "$_std"
    zinit-zsh/z-a-as-monitor    "$_std"
    zinit-zsh/z-a-patch-dl      "$_std"
    zinit-zsh/z-a-unscope       "$_std"
    zinit-zsh/z-a-submods       "$_std"
    zinit-zsh/z-a-rust          "$_std"
    zinit-zsh/z-a-bin-gem-node  "$_std"
    zinit-zsh/z-a-man           "$_std"
    zinit-zsh/z-a-test          "$_std"

    # @sharkdp
    sharkdp/fd              "$_std null lucid from'gh-r' mv'fd* fd' sbin'**/fd'"
    sharkdp/bat             "$_std null lucid from'gh-r' mv'bat* bat' sbin'**/bat'"
    sharkdp/hexyl           "$_std null lucid from'gh-r' mv'hexyl* hexyl' sbin'**/hexyl'"
    sharkdp/hyperfine       "$_std null lucid from'gh-r' mv'hyperfine* hyperfine' sbin'**/hyperfine'"
    sharkdp/vivid           "$_std null lucid from'gh-r' mv'vivid* vivid' sbin'**/vivid'"
    # @zsh-users
    zsh-users/zsh-autosuggestions       "$_std atload'_zsh_autosuggest_start;'"
    zsh-users/zsh-syntax-highlighting   "$_std atinit'ZINIT[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay;'"
    zsh-users/zsh-completions           "$_std pick'/dev/null'"
    # @zdharma
    zdharma/fast-syntax-highlighting    "$_std atinit'ZINIT[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay;'"
    zdharma/history-search-multi-word   "$_std atinit'zstyle :history-search-multi-word page-size 7;'"
    zdharma/zsh-diff-so-fancy           "$_std null sbin'bin/git-dsf;bin/diff-so-fancy'"
    # @zdharma, less popular
    zdharma/zui             "$_std blockf"
    zdharma/zconvey         "$_std sbin'cmds/zc-bg-notify;cmds/plg-zsh-notify'"
    zdharma/zsh-unique-id   "$_std"
    zdharma/zflai           "$_std"
    github-issues           "$_std pack"
    github-issues-srv       "$_std pack atinit'GIT_PROJECTS=zdharma/zinit GIT_SLEEP_TIME=700;'"
    # @molovo
    molovo/zunit            "$_std null sbin atclone'./build.zsh;' atpull'%atclone'"
    molovo/color            "$_std null sbin'color.zsh -> color'"
    molovo/revolver         "$_std as'program' pick'revolver'"
    # @zpm-zsh
    dircolors-material      "$_std pack"
    # @pyenv
    pyenv                   "$_std pack'bgn'"
    # @ogham
    ogham/exa               "$_std mv'exa* -> exa' sbin"
    cargo-exa               "$_std null cargo='!exa' teleid'zdharma/null'"

    # A few utility plugins
    hlissner/zsh-autopair               "$_std"
    urbainvaes/fzf-marks                "$_std"
    psprint/zsh-navigation-tools        "$_std"
    voronkovich/gitignore.plugin.zsh    "$_std trigger-load'!gi;!gii' \
        dl'https://gist.githubusercontent.com/psprint/1f4d0a3cb89d68d3256615f247e2aac9/raw -> \
            templates/Zsh.gitignore"
    psprint/zsh-editing-workbench       "$_std atinit'local zew_word_style=whitespace;'"



    # @marzocchi, a notifier, configured to use zconvey
    marzocchi/zsh-notify      "$_std atinit'zstyle \":notify:*\" command-complete-timeout 3; \
                                            zstyle \":notify:*\" notifier plg-zsh-notify"

    # no username → a rust-annex usage to install Rust toolchain
    rust-toolchain            "$_std null sbin='bin/*' rustup teleid'zdharma/null' \
                                    atload='[[ ! -f \${ZINIT[COMPLETIONS_DIR]}/_cargo ]] && \
                                        zi creinstall rust; \
                                    export CARGO_HOME=\$PWD RUSTUP_HOME=\$PWD/rustup'"

    # Fuzzy searchers
    fzf     "$_std pack'bgn-binary'"
    fzy     "$_std pack'bgn' git"

    # Git extensions
    Fakerr/git-recall         "$_std null sbin"
    paulirish/git-open        "$_std null sbin"
    paulirish/git-recent      "$_std null sbin"
    davidosomething/git-my    "$_std null sbin"
    arzzen/git-quick-stats    "$_std null sbin atload'export _MENU_THEME=legacy;'"
    iwata/git-now             "$_std null sbin"
    tj/git-extras             "$_std null make'PREFIX=$ZPFX'"
    wfxr/forgit               "$_std atinit'forgit_ignore=fgi'"

    # @jonas
    jonas/tig                 "$_std null make'prefix=$ZPFX install'"

    # @sindresorhus
    sindresorhus/pure         "$_std pick'async.zsh' src'pure.zsh' atload'prompt_pure_precmd' nocd"

    # @agkozak
    agkozak/agkozak-zsh-theme "$_std atload'_agkozak_precmd' atinit'AGKOZAK_FORCE_ASYNC_METHOD=subst-async' nocd"

    # @woefe
    woefe/git-prompt.zsh      "$_std atload'_zsh_git_prompt_precmd_hook' nocd"
)

# Snippets
_std+=" is-snippet"

Zinit_Annex_Meta_Plugins_Config_Map+=(
    # Prezto
    PZTM::archive       "$_std"
    PZTM::directory     "$_std"
    PZTM::utility       "$_std"
)

unset _std


# vim:ft=zsh:tw=80:sw=4:sts=4:et:foldmarker=[[[,]]]
