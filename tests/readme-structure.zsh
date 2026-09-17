#!/usr/bin/env zsh
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
# docs/README.md keeps the sections the organization README template
# requires (z-shell/.github templates/readme/zsh-plugin.md, adapted for an
# annex) and carries none of the template's scaffolding.
builtin emulate -R zsh
setopt extended_glob

typeset repo_dir=${0:A:h:h}
typeset readme=$repo_dir/docs/README.md

fail() { builtin print -u2 -r -- "not ok - $1"; exit 1 }

[[ -r $readme ]] || fail 'docs/README.md exists'

typeset -a lines
lines=( "${(@f)$(<$readme)}" )

typeset section
for section in Features Requirements Installation Usage Configuration \
    'Lifecycle and side effects' 'Portable shell contract' Verification \
    'Documentation and support' 'Release model' 'Contributing and license'; do
  (( ${lines[(Ie)## $section]} )) || fail "README has a '## $section' section"
done

(( ${lines[(I)\#[^#]*]} == 0 )) || fail 'README has no Markdown H1; the header is the centered HTML block'
(( ${lines[(I)*\<!--*]} == 0 )) || fail 'README carries no template comments'
(( ${lines[(I)*\<[a-z-]#(name|slug|owner|repo|project|url|tagline)[a-z-]#\>*]} == 0 )) ||
  fail 'README carries no <placeholder> from the template'
(( ${lines[(I)*Developed with*Z-Shell Community*]} )) || fail 'README ends with the organization footer'
typeset em_dash=$'\u2014'
(( ${lines[(I)*${em_dash}*]} == 0 )) || fail 'README uses no em dash'

builtin print -r -- 'ok - docs/README.md follows the organization README template'
