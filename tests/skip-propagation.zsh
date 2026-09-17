#!/usr/bin/env zsh
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
# skip'' reaches a nested label, and a token that matches nothing is reported.
builtin emulate -R zsh
setopt extended_glob

typeset repo_dir=${0:A:h:h}

fail() { builtin print -u2 -r -- "not ok - $1"; exit 1 }

typeset -gA ICE ZI ZI_EXTS ZI_EXTS2 ZI_SNIPPETS
typeset -ga zsh_loaded_plugins ZI_REGISTERED_PLUGINS ZI_TASKS ZI_RUN messages
.zi-get-object-path() { return 0 }
.zi-two-paths() { : }
.zi-any-colorify-as-uspl2() { REPLY=$1 }
+zi-message() { [[ $1 == -n ]] && shift; messages+=( "$*" ) }

builtin source "$repo_dir/z-a-meta-plugins.plugin.zsh" >/dev/null 2>&1 ||
  fail 'source the annex'

expand() {  # expand <label>; status in $?, queue in ZI[...]
  builtin source "$repo_dir/functions/_z_a_meta_plugins_before_load_handler" \
    plugin "$1" "$1" '' '' before-load-4 load
}

# Zi splits the replacement into words and unquotes each one before parsing
# ices, so read it back the same way.
queued() { reply=( "${(@Q)${(@z)ZI[annex-before-load:new-@]}}" ) }

typeset -a warnings
integer at

# A token naming a member of the nested label is forwarded to that label.
ICE=( skip fzf )
messages=()
expand ext-git
(( $? == 2 )) || fail 'expand @ext-git with a nested skip'
queued
at=${reply[(Ie)@fuzzy]}
(( at )) || fail "@ext-git no longer nests @fuzzy: ${(j: :)reply}"
(( at > 1 )) && [[ $reply[at-1] == skip* ]] ||
  fail "no skip ice precedes @fuzzy: ${(j: :)reply}"
[[ ${(j: :)reply} == *forgit* && ${(j: :)reply} == *git-open* ]] ||
  fail 'the forwarded skip must not remove the other members'
warnings=( ${(M)messages:#*no member*} )
(( ${#warnings} == 0 )) || fail "fzf is a nested member; unexpected: ${(F)warnings}"

# Replay the forwarded ice on the inner label the way Zi will.
ICE=( skip ${reply[at-1]#skip} )
messages=()
expand fuzzy
(( $? == 2 )) || fail 'the inner label must return 2 after the forwarded skip'
[[ -z ${ZI[annex-before-load:new-@]//[[:space:]]/} ]] ||
  fail "the inner label queued [${ZI[annex-before-load:new-@]}] against the forwarded skip"
warnings=( ${(M)messages:#*no member*} )
(( ${#warnings} == 0 )) || fail "the forwarded token matched; unexpected: ${(F)warnings}"

# Only tokens that match a nested member are forwarded.
ICE=( skip 'forgit fzf' )
messages=()
expand ext-git
queued
at=${reply[(Ie)@fuzzy]}
(( at > 1 )) && [[ $reply[at-1] == skip* && $reply[at-1] != *forgit* ]] ||
  fail "forward only tokens that match nested members: ${(j: :)reply}"
[[ ${(j: :)reply} != *forgit* ]] || fail 'forgit must be skipped at the outer level'
(( ${#${(M)messages:#*no member*}} == 0 )) ||
  fail 'every token matched somewhere; no warning expected'

# Naming the nested label itself removes it whole.
ICE=( skip fuzzy )
messages=()
expand ext-git
[[ ${ZI[annex-before-load:new-@]} != *@fuzzy* ]] || fail 'skip of the nested label removes it'
(( ${#${(M)messages:#*no member*}} == 0 )) || fail 'the label name is a match'

# Tokens that match nothing are reported once, with the group's members.
ICE=( skip 'exa hexil peco' )
messages=()
expand console-tools
(( $? == 2 )) || fail 'unmatched tokens must not fail the group'
queued
[[ ${(j: :)reply} == *sharkdp/fd*sharkdp/bat*eza-community/eza*BurntSushi/ripgrep* ]] ||
  fail "unmatched tokens must leave the group intact: ${(j: :)reply}"
warnings=( ${(M)messages:#*no member*} )
(( ${#warnings} == 1 )) || fail "expected one warning, got ${#warnings}: ${(F)messages}"
typeset token
for token in exa hexil peco; do
  [[ $warnings[1] == *$token* ]] || fail "the warning must name $token: $warnings[1]"
done
# Zi messages render the owner separator as U+2215, as the Loading cluster does.
[[ $warnings[1] == *console-tools* && $warnings[1] == *eza-community[/∕]eza* ]] ||
  fail "the warning must name the group and its current members: $warnings[1]"
[[ $warnings[1] == *"${_z_a_meta_plugins_state[migration-guide]}#migrate-console-tools"* ]] ||
  fail "the warning must link the @console-tools subsection of the guide: $warnings[1]"
ICE=()

# A group without its own subsection sends the user to the migration section.
ICE=( skip nothing-here )
messages=()
expand zsh-users
(( $? == 2 )) || fail 'unmatched tokens must not fail @zsh-users'
warnings=( ${(M)messages:#*no member*} )
(( ${#warnings} == 1 )) || fail "expected one warning, got ${#warnings}: ${(F)messages}"
[[ $warnings[1] == *"${_z_a_meta_plugins_state[migration-guide]}#${_z_a_meta_plugins_state[migration-section]}"* ]] ||
  fail "the warning must link the migration section of the guide: $warnings[1]"

# The report does not wait for validation: a group that cannot load on this
# shell still names the stale token, so the configuration gets fixed once.
ICE=( skip fzy )
zsh_loaded_plugins=( fzf-go )
messages=()
expand fuzzy
(( $? == 3 )) || fail "another fzf is loaded; @fuzzy must return 3, got $?"
warnings=( ${(M)messages:#*no member*} )
(( ${#warnings} == 1 )) ||
  fail "a group that fails validation must still report its stale token: ${(F)messages}"
[[ $warnings[1] == *fzy* && $warnings[1] == *fuzzy* ]] ||
  fail "the warning must name the token and the group: $warnings[1]"
zsh_loaded_plugins=()
ICE=()

builtin print -r -- 'ok - skip reaches nested labels and unmatched tokens are reported'
