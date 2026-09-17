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

# Prose is every line outside fenced code blocks with inline code spans
# removed, so a `#` comment in a code block or a `<version>` argument in a
# code span never counts as Markdown or as a template placeholder.
typeset -a prose
typeset line
integer in_fence=0
for line in "${lines[@]}"; do
  if [[ $line == '```'* ]]; then
    (( in_fence = !in_fence ))
    continue
  fi
  (( in_fence )) && continue
  prose+=( "${line//\`[^\`]#\`/}" )
done

(( ${prose[(I)\#[^#]*]} == 0 )) || fail 'README has no Markdown H1; the header is the centered HTML block'
(( ${prose[(I)*\<!--*]} == 0 )) || fail 'README carries no template comments'

# The template's placeholders are <Capitalized phrases>, <hyphenated-or_underscored
# words>, and HTML-encoded &lt;...&gt;. In prose the only legitimate angle
# brackets are the HTML tags the header, group notes, and footer use.
typeset -a html_tags=( a br code details div h1 img p summary )
typeset content=${(F)prose} inner tag
while [[ $content == (#b)[^\<]#\<([^\>]#)\>(*) ]]; do
  inner=$match[1] content=$match[2]
  tag=${${inner#/}%%[[:space:]]*}
  (( ${html_tags[(Ie)$tag]} )) || fail "README carries no <placeholder> from the template (found <$inner>)"
done
(( ${prose[(I)*&lt;*]} == 0 )) || fail 'README carries no &lt;placeholder&gt; from the template'

# The footer is the last content: its paragraph, then the closing </div>.
typeset -a tail_lines=( "${(@)lines:#}" )
[[ $tail_lines[-1] == '</div>' && $tail_lines[-2] == *Developed\ with*Z-Shell\ Community* ]] ||
  fail 'README ends with the organization footer'
typeset em_dash=$'\u2014'
(( ${lines[(I)*${em_dash}*]} == 0 )) || fail 'README uses no em dash'

builtin print -r -- 'ok - docs/README.md follows the organization README template'
