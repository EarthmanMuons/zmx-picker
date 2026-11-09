#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
zp=$here/../zp

ZP_TEST_DIR=$(mktemp -d)
export ZP_TEST_DIR
trap 'rm -rf "$ZP_TEST_DIR"' EXIT

PATH=$here/bin:$PATH
export PATH
unset ZP_ROOT ZP_LABEL_MARKS

root=$ZP_TEST_DIR/root
mkdir -p "$root/plain/.jj" "$root/my.repo/.git"

pass=0
fail=0

ok() {
	printf 'ok   %s\n' "$1"
	pass=$((pass + 1))
}

not_ok() {
	printf 'FAIL %s (got: %s)\n' "$1" "$2"
	fail=$((fail + 1))
}

log() {
	cat "$ZP_TEST_DIR/calls.log" 2>/dev/null || true
}

reset_log() {
	rm -f "$ZP_TEST_DIR/calls.log"
}

# assert_log <description> <glob pattern matched against the call log>
assert_log() {
	# shellcheck disable=SC2053 # glob matching the pattern is the point
	if [[ $(log) == $2 ]]; then
		ok "$1"
	else
		not_ok "$1" "$(log)"
	fi
}

run() {
	expect "$here/harness.exp" "$zp" "$@"
}

esc=$'\x1b'
enter=$'\r'
tab=$'\t'
ctrl_n=$'\x0e'
ctrl_x=$'\x18'

reset_log
rc=0
run '' "$esc" || rc=$?
if [[ $rc -eq 0 && -z $(log) ]]; then
	ok 'esc cancels with exit 0 and no zmx calls'
else
	not_ok 'esc cancels with exit 0 and no zmx calls' "rc=$rc log=$(log)"
fi

reset_log
run '' 'beta' "$enter" >/dev/null || true
assert_log 'enter attaches the matched session' 'ATTACH:\[beta] PWD:*'

reset_log
run "$root" 'plain' "$enter" >/dev/null || true
assert_log 'selecting a repo starts a numbered session inside it' \
	'ATTACH:\[plain.1] PWD:*/root/plain'

reset_log
run "$root" 'my.repo' "$enter" >/dev/null || true
assert_log 'dots in repo names become underscores in session names' \
	'ATTACH:\[my_repo.1] PWD:*/root/my.repo'

reset_log
run '' 'bet' "$ctrl_n" >/dev/null || true
assert_log 'ctrl-n creates from the query even with a match highlighted' \
	'ATTACH:\[bet] PWD:*'

reset_log
rc=0
run '' "$tab" "$ctrl_n" >/dev/null || rc=$?
if [[ $rc -eq 1 && -z $(log) ]]; then
	ok 'ctrl-n with an empty query errors out, ignoring marks'
else
	not_ok 'ctrl-n with an empty query errors out, ignoring marks' \
		"rc=$rc log=$(log)"
fi

reset_log
run '' 'zzz-new' "$enter" >/dev/null || true
assert_log 'enter on an unmatched query creates a session' \
	'ATTACH:\[zzz-new] PWD:*'

reset_log
run '' "$tab" "$enter" >/dev/null || true
assert_log 'enter follows the cursor even with other rows marked' \
	'ATTACH:\[alpha.2] PWD:*'

reset_log
run '' "$tab$tab" "$ctrl_x" "$esc" >/dev/null || true
assert_log 'ctrl-x kills all marked sessions in one call' \
	'KILL:\[alpha.1 alpha.2] PWD:*'

reset_log
printf 'session\talpha.1\tx\nrepo\t/nope\tx\nsession\tbeta\tx\n' |
	"$zp" --kill
assert_log '--kill ignores repo rows and kills sessions together' \
	'KILL:\[alpha.1 beta] PWD:*'

reset_log
printf 'session\talpha.1\tx\nsession\talpha.2\tx\n' |
	ZMX_SESSION=alpha.1 "$zp" --kill
assert_log '--kill orders the current session last' \
	'KILL:\[alpha.2 alpha.1] PWD:*'

reset_log
out=$("$zp" --candidates "$root")
if [[ $out == *$'session\talpha.1\t'* && $out == *'(1 session)'* &&
	$out == *$'\t'"$root/my.repo"$'\t'* ]]; then
	ok 'candidates strips list markers and annotates session counts'
else
	not_ok 'candidates strips list markers and annotates session counts' "$out"
fi

reset_log
out=$("$zp" --candidates "$root")
beta_line=$(grep $'^session\tbeta\t' <<<"$out")
if [[ $beta_line == *'project=zp env=work'* ]]; then
	ok 'session labels are surfaced in the searchable display column'
else
	not_ok 'session labels are surfaced in the searchable display column' \
		"$beta_line"
fi

# ZP_LABEL_MARKS maps key=value labels to marks shown ahead of the
# name, in the map's order, then a tab: fzf expands it to the next
# tab stop, so names align however wide fzf measures the marks. The
# labels themselves stay, so they are still searchable; an entry
# with no mark is ignored.
out=$(ZMX_SESSION=alpha.1 ZP_LABEL_MARKS='env=work=W nomark project=zp=Z' "$zp" --candidates "$root")
display() { grep $'^session\t'"$1"$'\t' <<<"$out" | cut -f3-; }
if [[ $(display beta) == "  WZ${tab}beta  "*'project=zp env=work' ]]; then
	ok 'label marks show ahead of the name, labels kept'
else
	not_ok 'label marks show ahead of the name, labels kept' "$(display beta)"
fi
if [[ $(display alpha.2) == "  ${tab}alpha.2 "* ]]; then
	ok 'unmarked sessions get the tab so names stay aligned'
else
	not_ok 'unmarked sessions get the tab so names stay aligned' \
		"$(display alpha.2)"
fi
if [[ $(display alpha.1) == "→ ${tab}alpha.1 "* ]]; then
	ok 'label marks follow the current-session arrow'
else
	not_ok 'label marks follow the current-session arrow' "$(display alpha.1)"
fi
stale_display=$(grep $'^stale\told.3\t' <<<"$out" | cut -f3-)
if [[ $stale_display == "  ${tab}old.3 "* ]]; then
	ok 'stale sessions get the tab too'
else
	not_ok 'stale sessions get the tab too' "$stale_display"
fi

# Unset, or matching nothing, the rows keep their old shape.
out=$("$zp" --candidates "$root")
unmarked=$out
if [[ $(display alpha.2) == '  alpha.2 '* ]]; then
	ok 'no mark column when ZP_LABEL_MARKS is unset'
else
	not_ok 'no mark column when ZP_LABEL_MARKS is unset' "$(display alpha.2)"
fi
out=$(ZP_LABEL_MARKS='env=none=X' "$zp" --candidates "$root")
if [[ $out == "$unmarked" ]]; then
	ok 'a map matching no session leaves the rows unchanged'
else
	not_ok 'a map matching no session leaves the rows unchanged' "$out"
fi

reset_log
ZMX_SESSION_PREFIX=d. run '' 'gamma' "$enter" >/dev/null || true
assert_log 'attaching a listed session never re-applies ZMX_SESSION_PREFIX' \
	'ATTACH:\[d.gamma] PWD:*'

reset_log
ZMX_SESSION_PREFIX=d. run '' 'zzz-pfx' "$enter" >/dev/null || true
assert_log 'sessions zp creates do get ZMX_SESSION_PREFIX applied' \
	'ATTACH:\[d.zzz-pfx] PWD:*'

next=$(ZMX_SESSION_PREFIX=d. /bin/bash -c '
	eval "$(awk "/^(session_names|next_session)\(\) \{/,/^\}/" "$1")"
	next_session /x/omega' _ "$zp")
if [[ $next == omega.10 ]]; then
	ok 'numbering skips past prefixed sessions when creating'
else
	not_ok 'numbering skips past prefixed sessions when creating' "$next"
fi

reset_log
touch "$ZP_TEST_DIR/no-sessions"
rc=0
out=$("$zp" 2>&1) || rc=$?
rm -f "$ZP_TEST_DIR/no-sessions"
if [[ $rc -eq 1 && $out == *'no zmx sessions running'* ]]; then
	ok 'no sessions and no roots prints a hint and exits 1'
else
	not_ok 'no sessions and no roots prints a hint and exits 1' "rc=$rc out=$out"
fi

out=$(ZMX_SESSION=beta "$zp" --candidates "$root")
beta_line=$(grep $'^session\tbeta\t' <<<"$out")
alpha_line=$(grep $'^session\talpha.1\t' <<<"$out")
if [[ $beta_line == *$'\t→ beta'* && $alpha_line == *$'\t  alpha.1'* ]]; then
	ok 'the session zp runs inside gets the arrow marker'
else
	not_ok 'the session zp runs inside gets the arrow marker' "$beta_line"
fi

rm -f "$ZP_TEST_DIR/history.log"
run '' "$esc" >/dev/null || true
if [[ $(cat "$ZP_TEST_DIR/history.log" 2>/dev/null) == *'HISTORY:[alpha.1]'* ]]; then
	ok 'focusing a session previews its history'
else
	not_ok 'focusing a session previews its history' \
		"$(cat "$ZP_TEST_DIR/history.log" 2>/dev/null || true)"
fi

rm -f "$ZP_TEST_DIR/history.log"
ZMX_SESSION=alpha.1 run '' "$esc" >/dev/null || true
if [[ $(cat "$ZP_TEST_DIR/history.log" 2>/dev/null) != *'HISTORY:[alpha.1]'* ]]; then
	ok 'the current session skips the recursive history preview'
else
	not_ok 'the current session skips the recursive history preview' \
		"$(cat "$ZP_TEST_DIR/history.log" 2>/dev/null || true)"
fi

out=$(HOME=$ZP_TEST_DIR "$zp" --candidates "$root")
line=$(grep $'\t'"$root/plain"$'\t' <<<"$out")
display=${line##*$'\t'}
if [[ $display == *'~/root'* && $display != *"$ZP_TEST_DIR"* &&
	$line == *$'\t'"$root/plain"$'\t'* ]]; then
	ok 'display paths shorten the home dir to ~ while values stay absolute'
else
	not_ok 'display paths shorten the home dir to ~ while values stay absolute' "$line"
fi

out=$(HOME=/tmp "$zp" --candidates)
gamma_line=$(grep $'^session\td.gamma\t' <<<"$out")
omega_line=$(grep $'^session\td.omega.9\t' <<<"$out")
if [[ $gamma_line == *'file://elsewhere.example/tmp' &&
	$omega_line == *'  ~/a b' ]]; then
	ok 'local OSC 7 cwds show as decoded ~ paths, remote ones keep the URL'
else
	not_ok 'local OSC 7 cwds show as decoded ~ paths, remote ones keep the URL' \
		"$gamma_line | $omega_line"
fi

out=$(/bin/bash -c '
	eval "$(awk "/^(local_path|tilde)\(\) \{/,/^\}/" "$1")"
	local_path "file:///tmp/a%0Ab%09c"
	tilde "$localized"
	printf "%s|%s" "$localized" "$tilded"' _ "$zp")
if [[ $out == $'/tmp/a\nb\tc|/tmp/a?b?c' ]]; then
	ok 'decoded cwds keep control characters but display them as ?'
else
	not_ok 'decoded cwds keep control characters but display them as ?' "$out"
fi

out=$(/bin/bash -c '
	eval "$(awk "/^local_path\(\) \{/,/^\}/" "$1")"
	shopt -s nocasematch
	local_path "file://elsewhere.example/tmp"
	local_path "file:///tmp"
	shopt -q nocasematch && echo kept' _ "$zp")
if [[ $out == kept ]]; then
	ok 'local_path preserves the caller nocasematch setting'
else
	not_ok 'local_path preserves the caller nocasematch setting' "$out"
fi

out=$("$zp" --candidates)
stale_line=$(grep $'^stale\told.3\t' <<<"$out")
if [[ $stale_line == *'unreachable (err=Unexpected)'* &&
	$out != *$'session\told.3'* ]]; then
	ok 'unreachable sessions are listed as stale with the reason'
else
	not_ok 'unreachable sessions are listed as stale with the reason' "$out"
fi

reset_log
rc=0
run '' 'old.3' "$enter" >/dev/null || rc=$?
if [[ $rc -eq 1 && -z $(log) ]]; then
	ok 'selecting a stale session explains instead of attaching'
else
	not_ok 'selecting a stale session explains instead of attaching' \
		"rc=$rc log=$(log)"
fi

next=$(/bin/bash -c '
	eval "$(awk "/^(session_names|next_session)\(\) \{/,/^\}/" "$1")"
	next_session /x/old' _ "$zp")
if [[ $next == old.4 ]]; then
	ok 'numbering counts unreachable sessions as taken'
else
	not_ok 'numbering counts unreachable sessions as taken' "$next"
fi

# daemon_pid with stub zmx and lsof, run under the script's own
# strict mode. The stubs print a socket for "project branch" ahead
# of the one for "project", in the Linux form with a type suffix.
daemon_pid_with() {
	/bin/bash -c '
		set -euo pipefail
		eval "$(awk "/^daemon_pid\(\) \{/,/^\}/" "$1")"
		zmx() { printf "zmx\t\t1.0.1\nsocket_dir\t/s\n"; }
		stub=$2
		lsof() { eval "$stub"; }
		daemon_pid "$3"
		echo "rc=$?"' _ "$zp" "$1" "$2"
}

out=$(daemon_pid_with '
	printf "p111\nn/s/project branch type=STREAM\n"
	printf "p222\nn/s/project type=STREAM (LISTEN)\n"' project)
if [[ $out == $'222\nrc=0' ]]; then
	ok 'daemon lookup matches the exact socket, not a name prefix'
else
	not_ok 'daemon lookup matches the exact socket, not a name prefix' "$out"
fi

out=$(daemon_pid_with 'printf "p111\nn/s/project branch\n"' project)
if [[ $out == rc=0 ]]; then
	ok 'daemon lookup finds nothing when only a longer name matches'
else
	not_ok 'daemon lookup finds nothing when only a longer name matches' "$out"
fi

out=$(daemon_pid_with 'return 1' project)
if [[ $out == rc=0 ]]; then
	ok 'a failing lsof means no daemon found, not an aborted script'
else
	not_ok 'a failing lsof means no daemon found, not an aborted script' "$out"
fi

out=$(daemon_pid_with '
	printf "p333\nn/s/project\n"
	seq 1 200000 | sed "s/^/n\/x\//"' project)
if [[ $out == $'333\nrc=0' ]]; then
	ok 'large lsof output after a match does not die of SIGPIPE'
else
	not_ok 'large lsof output after a match does not die of SIGPIPE' "$out"
fi

# Nix builders and devshells export $out. A local of the same name
# would inherit the export and carry the whole capture into awk's
# environment, past the kernel's per-string limit.
out=$(export out=x && daemon_pid_with '
	printf "p333\nn/s/project\n"
	seq 1 200000 | sed "s/^/n\/x\//"' project)
if [[ $out == $'333\nrc=0' ]]; then
	ok 'large lsof output survives a caller that exports out'
else
	not_ok 'large lsof output survives a caller that exports out' "$out"
fi

# Without a stand-in daemon pid, the fake lsof finds nothing and
# exits 1, like a real lsof with no match.
out=$("$zp" --stale-info old.3)
if [[ $out == *'could not be found automatically'* ]]; then
	ok 'the stale preview falls back to manual guidance without a pid'
else
	not_ok 'the stale preview falls back to manual guidance without a pid' "$out"
fi

reset_log
printf 'stale\told.3\tx\nsession\tbeta\tx\n' | "$zp" --kill
assert_log 'a failed daemon lookup still kills the other marked sessions' \
	'KILL:\[beta] PWD:*'

# Start a stand-in for an old daemon and record its pid where the
# fake lsof finds it. It logs SIGTERM to the call log, so tests can
# check when it was signaled relative to zmx kill. The subshell
# reparents it away from this shell, so once killed it is reaped
# instead of lingering as a zombie.
start_stale_daemon() {
	(
		sh -c 'trap "echo STALE:TERM >>\"\$1\"; exit 0" TERM
			while :; do sleep 1 & wait; done' _ "$ZP_TEST_DIR/calls.log" \
			>/dev/null 2>&1 &
		echo $! >"$ZP_TEST_DIR/stale.pid"
	)
	stale_pid=$(cat "$ZP_TEST_DIR/stale.pid")
}

start_stale_daemon

out=$("$zp" --stale-info old.3)
if [[ $out == *"kill $stale_pid"* ]]; then
	ok 'the stale preview names the daemon pid found via lsof'
else
	not_ok 'the stale preview names the daemon pid found via lsof' "$out"
fi

reset_log
printf 'stale\told.3\tx\n' | "$zp" --kill
if ! kill -0 "$stale_pid" 2>/dev/null && [[ $(log) == STALE:TERM ]]; then
	ok '--kill signals a stale daemon directly instead of zmx kill'
else
	kill "$stale_pid" 2>/dev/null || true
	not_ok '--kill signals a stale daemon directly instead of zmx kill' \
		"log=$(log)"
fi

reset_log
start_stale_daemon
printf 'stale\told.3\tx\nsession\tbeta\tx\n' |
	ZMX_SESSION=old.3 "$zp" --kill
assert_log '--kill signals the current stale session after the others' \
	$'KILL:\\[beta] PWD:*\nSTALE:TERM'
kill "$stale_pid" 2>/dev/null || true
rm -f "$ZP_TEST_DIR/stale.pid"

out=$("$zp" --version)
if [[ $out == zp\ [0-9]*.[0-9]*.[0-9]* && $out == "$("$zp" -V)" ]]; then
	ok '--version and -V report the version'
else
	not_ok '--version and -V report the version' "$out"
fi

# Compare files to preserve NUL delimiters and catch any extra stdout.
# assert_print <description> <root> <query> <key> <directory> <session>
# An empty expected directory means cancellation should emit no bytes.
assert_print() {
	local description=$1 rc=0
	reset_log
	rm -f "$ZP_TEST_DIR/selection"
	: >"$ZP_TEST_DIR/expected"
	if [[ -n $5 ]]; then
		printf '%s\0%s\0' "$5" "$6" >"$ZP_TEST_DIR/expected"
	fi
	run --print "$2" "$3" "$4" || rc=$?
	if [[ $rc -eq 0 && -z $(log) ]] &&
		cmp -s "$ZP_TEST_DIR/expected" "$ZP_TEST_DIR/selection"; then
		ok "$description"
	else
		not_ok "$description" "rc=$rc log=$(log); output bytes: $(od -An -tx1 "$ZP_TEST_DIR/selection" 2>/dev/null)"
	fi
}

ZMX_SESSION_PREFIX='' assert_print '--print emits the caller directory and existing name without attaching' \
	'' 'beta' "$enter" "$PWD" beta
ZMX_SESSION_PREFIX=d. assert_print '--print never re-applies the prefix to an existing name' \
	'' 'gamma' "$enter" "$PWD" d.gamma
ZMX_SESSION_PREFIX='' assert_print '--print emits an unmatched query without attaching' \
	'' 'zzz-new' "$enter" "$PWD" zzz-new
ZMX_SESSION_PREFIX=d. assert_print '--print prefixes an unmatched query' \
	'' 'zzz-new' "$enter" "$PWD" d.zzz-new
ZMX_SESSION_PREFIX=d. assert_print '--print ctrl-n uses the query even with a match highlighted' \
	'' 'bet' "$ctrl_n" "$PWD" d.bet

print_root="$ZP_TEST_DIR/root with spaces"
mkdir -p "$print_root/omega/.git"
ZMX_SESSION_PREFIX=d. assert_print '--print preserves repo paths with spaces and numbers prefixed sessions' \
	"$print_root" '[repo] omega' "$enter" "$print_root/omega" d.omega.10
assert_print '--print cancellation exits successfully with no output or attach' \
	'' '' "$esc" '' ''

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
