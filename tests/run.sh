#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
zp=$here/../zp

ZP_TEST_DIR=$(mktemp -d)
export ZP_TEST_DIR
trap 'rm -rf "$ZP_TEST_DIR"' EXIT

PATH=$here/bin:$PATH
export PATH
unset ZP_ROOT

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
ZMX_SESSION_PREFIX=d. run '' 'gamma' "$enter" >/dev/null || true
assert_log 'attaching a listed session never re-applies ZMX_SESSION_PREFIX' \
	'ATTACH:\[d.gamma] PWD:*'

reset_log
ZMX_SESSION_PREFIX=d. run '' 'zzz-pfx' "$enter" >/dev/null || true
assert_log 'sessions zp creates do get ZMX_SESSION_PREFIX applied' \
	'ATTACH:\[d.zzz-pfx] PWD:*'

next=$(ZMX_SESSION_PREFIX=d. /bin/bash -c '
	eval "$(awk "/^next_session\(\) \{/,/^\}/" "$1")"
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

out=$("$zp" --version)
if [[ $out == zp\ [0-9]*.[0-9]*.[0-9]* && $out == "$("$zp" -V)" ]]; then
	ok '--version and -V report the version'
else
	not_ok '--version and -V report the version' "$out"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
