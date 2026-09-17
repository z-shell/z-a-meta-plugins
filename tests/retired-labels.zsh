#!/usr/bin/env zsh
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
# A retired label installs nothing, keeps the requests that follow it, and
# says so once per session through Zi messaging, with the migration guide.
builtin emulate -R zsh
setopt extended_glob

typeset repo_dir=${0:A:h:h}
typeset errfile=$(command mktemp "${TMPDIR:-/tmp}/meta-retired.XXXXXXXX") || exit 1
trap 'command rm -f -- "$errfile"' EXIT INT TERM

fail() { builtin print -u2 -r -- "not ok - $1"; exit 1 }

typeset -gA ICE ZI ZI_EXTS ZI_EXTS2 ZI_SNIPPETS
typeset -ga zsh_loaded_plugins ZI_REGISTERED_PLUGINS ZI_TASKS ZI_RUN messages
.zi-get-object-path() { return 0 }
.zi-two-paths() { : }
.zi-any-colorify-as-uspl2() { REPLY=$1 }
+zi-message() { [[ $1 == -n ]] && shift; messages+=( "$*" ) }

builtin source "$repo_dir/z-a-meta-plugins.plugin.zsh" >/dev/null 2>&1 ||
  fail 'source the annex'

expand() {  # expand <label> [<following args>]; status in $?, queue in ZI[...]
  builtin source "$repo_dir/functions/_z_a_meta_plugins_before_load_handler" \
    plugin "$1" "$1" "${2-}" '' before-load-4 load 2>>"$errfile"
}

typeset guide=${_z_a_meta_plugins_state[migration-guide]}
[[ $guide == https://* ]] || fail 'the annex records the migration guide URL'

typeset label
typeset -a hits
for label in z-shell z-shell+ sharkdp; do
  (( $+_z_a_meta_plugins_map[$label] )) && fail "@$label still expands to a group"
  (( $+_z_a_meta_plugins_notices[$label] )) || fail "@$label has no notice"
  messages=()
  expand $label '@following'
  (( $? == 2 )) || fail "@$label must return 2, the recognised-nothing-to-load status"
  [[ ${ZI[annex-before-load:new-@]} == '@following' ]] ||
    fail "@$label must queue nothing and keep the following request"
  hits=( ${(M)messages:#*$guide*} )
  (( ${#hits} == 1 )) ||
    fail "@$label must print one notice with the guide URL, got: ${(F)messages}"
  [[ $hits[1] == *"$guide#migrate-$label"* ]] ||
    fail "the notice must link the @$label subsection of the guide: $hits[1]"
  [[ ${(F)messages} == *"@$label"* ]] || fail "the notice must name @$label"
  messages=()
  expand $label
  (( $? == 2 )) || fail "a repeated @$label must return 2"
  [[ -z ${ZI[annex-before-load:new-@]//[[:space:]]/} ]] ||
    fail "a repeated @$label queued [${ZI[annex-before-load:new-@]}]"
  (( ${#messages} == 0 )) ||
    fail "@$label repeated its notice in the same session: ${(F)messages}"
done

# A deprecated label keeps expanding and gets the same once-per-session notice.
messages=()
expand annexes+
(( $? == 2 )) || fail '@annexes+ must still expand'
[[ ${ZI[annex-before-load:new-@]} == *z-a-bin-gem-node*z-a-readurl*z-a-patch-dl*z-a-rust* ]] ||
  fail '@annexes+ must queue the four installers'
hits=( ${(M)messages:#*$guide*} )
(( ${#hits} == 1 )) ||
  fail "@annexes+ must print one notice with the guide URL, got: ${(F)messages}"
[[ $hits[1] == *"$guide#migrate-annexes+"* ]] ||
  fail "the notice must link the @annexes+ subsection of the guide: $hits[1]"
messages=()
expand annexes+
hits=( ${(M)messages:#*$guide*} )
(( ${#hits} == 0 )) || fail '@annexes+ repeated its notice'

# The blank line that separates the cluster from an ordinary plugin's output
# depends on the previous ID, not on a notice printed earlier in the session.
separated() {  # separated <label>; stdout of the expansion, END-terminated
  ( expand $1 >/dev/null 2>&1; messages=(); expand $1 2>/dev/null; builtin print -n END )
}
ICE=( debug 1 )
ZI[annex-exposed-processed-IDs]='zsh-users/zsh-autosuggestions'
[[ $(separated annexes+) == $'\nEND' ]] ||
  fail 'a notified label loaded after an ordinary plugin lost the separator'
ZI[annex-exposed-processed-IDs]='zsh-users'
[[ $(separated annexes+) == END ]] ||
  fail 'a notified label loaded after a meta-plugin gained a separator'
ZI[annex-exposed-processed-IDs]=''
ICE=()

[[ ! -s $errfile ]] || fail "notices bypassed Zi messaging: $(<$errfile)"

builtin print -r -- 'ok - retired labels are once-notified no-ops that link their guide subsection'
