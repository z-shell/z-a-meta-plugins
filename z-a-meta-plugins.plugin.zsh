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
)

# The map in which the default sets of ices
# for the real plugins are being stored.
typeset -gA Zinit_Annex_Meta_Plugins_Config_Map
Zinit_Annex_Meta_Plugins_Config_Map=(
    sharkdp/fd            "null lucid from'gh-r' mv'fd* fd' sbin'**/fd'"
    sharkdp/bat           "null lucid from'gh-r' mv'bat* bat' sbin'**/bat'"
    sharkdp/hexyl         "null lucid from'gh-r' mv'hexyl* hexyl' sbin'**/hexyl'"
    sharkdp/hyperfine     "null lucid from'gh-r' mv'hyperfine* hyperfine' sbin'**/hyperfine'"
    sharkdp/vivid         "null lucid from'gh-r' mv'vivid* vivid' sbin'**/vivid'"
)


# vim:ft=zsh:tw=80:sw=4:sts=4:et:foldmarker=[[[,]]]
