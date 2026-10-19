#!/usr/bin/env bash
# radare2 course grader.
#   ./check.sh doctor
#   ./check.sh score
#   ./check.sh <exercise-id> <answer>
set -uo pipefail
cd "$(dirname "$0")"

BUILD=build
PROGRESS=.progress
ANSWERS=answers.sha256
QEMU_SYSROOT=/opt/V1X00/sysroots/aarch64-poky-linux

RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; DIM=$'\033[2m'; OFF=$'\033[0m'
ok()   { echo "${GRN}PASS${OFF} $*"; }
bad()  { echo "${RED}FAIL${OFF} $*"; }
note() { echo "${DIM}$*${OFF}"; }

# ---------------------------------------------------------------- doctor ----
doctor() {
	local fail=0
	if command -v r2 >/dev/null; then
		ok "r2 $(r2 -v | head -1 | awk '{print $2}')  $(command -v r2)"
		local n; n=$(command -v -a r2 2>/dev/null | wc -l)
		[ "$n" -gt 1 ] && echo "${YEL}WARN${OFF} r2 found $n times on PATH - the first one wins:" && command -v -a r2
	else
		bad "r2 not installed - see README step 1"; fail=1
	fi
	[ -f .r2-commit ] && note "r2 source commit: $(cat .r2-commit)"
	for t in gcc g++ gdb make python3 jq; do
		command -v "$t" >/dev/null && ok "$t" || { bad "$t missing"; fail=1; }
	done
	command -v uv >/dev/null && ok "uv (for r2pipe in module 8)" || echo "${YEL}WARN${OFF} uv missing - module 8 needs it"
	command -v qemu-aarch64 >/dev/null && ok "qemu-aarch64" || { bad "qemu-aarch64 missing - module 10"; fail=1; }
	[ -d "$QEMU_SYSROOT" ] && ok "aarch64 sysroot $QEMU_SYSROOT" || { bad "aarch64 sysroot missing - module 10"; fail=1; }
	local ps; ps=$(cat /proc/sys/kernel/yama/ptrace_scope 2>/dev/null || echo "?")
	if [ "$ps" = "0" ]; then
		ok "ptrace_scope=0 (attach to running processes works)"
	else
		echo "${YEL}WARN${OFF} ptrace_scope=$ps - 'r2 -d ./prog' works, 'r2 -d <pid>' needs sudo"
	fi
	[ -d $BUILD ] && ok "$BUILD/ has $(ls -1 $BUILD | wc -l) files" || { echo "${YEL}WARN${OFF} run 'make' first"; }
	return $fail
}

# ------------------------------------------------------------ hash answers ---
normalize() { python3 -I -c '
import sys,re
s=sys.argv[1].strip().strip("\"\x27").lower()
s=re.sub(r"^(sym\.imp\.|sym\.|dbg\.|fcn\.|sub\.|method\.|loc\.)","",s)
if re.fullmatch(r"0x[0-9a-f]+",s): s=str(int(s,16))
elif re.fullmatch(r"[0-9]+",s):    s=str(int(s,10))
elif re.fullmatch(r"[0-9a-f]+",s): s=str(int(s,16))
else: s=re.sub(r"\s+"," ",s)
print(s)' "$1"; }

hashed() { python3 -I -c '
import sys,hashlib
print(hashlib.sha256(("%s|wave-r2|%s"%(sys.argv[1],sys.argv[2])).encode()).hexdigest())' "$1" "$2"; }

check_hash() {
	local id="$1" ans="$2"
	local want got
	want=$(awk -v k="$id" '$1==k{print $2}' "$ANSWERS")
	if [ -z "$want" ]; then bad "no such exercise: $id"; return 2; fi
	got=$(hashed "$id" "$(normalize "$ans")")
	if [ "$got" = "$want" ]; then record "$id"; ok "$id"; return 0; fi
	bad "$id - not the expected answer"; return 1
}

# ------------------------------------------------- behavioural (run) checks --
expect_run() { # expect_run <id> <wanted-stdout-substring> <cmd...>
	local id="$1" want="$2"; shift 2
	local out rc
	out=$("$@" 2>&1); rc=$?
	if [ $rc -eq 0 ] && [[ "$out" == *"$want"* ]]; then
		record "$id"; ok "$id - $out"; return 0
	fi
	bad "$id - exit=$rc output: ${out:-<none>}"; return 1
}

need_file() {
	[ -f "$1" ] && return 0
	bad "$2 - missing $1"
	note "   $3"
	return 1
}

check_behaviour() {
	local id="$1" ans="${2:-}"
	case "$id" in
	3)  need_file $BUILD/03_keycheck "$id" "run: make" || return 1
	    expect_run "$id" "KEY ACCEPTED" $BUILD/03_keycheck "$ans" ;;
	4)  need_file $BUILD/04_guard "$id" "run: make" || return 1
	    local out; out=$(printf '%s\n' "$ans" | $BUILD/04_guard 2>&1)
	    if [[ "$out" == *"GUARD PASSED"* ]]; then record "$id"; ok "$id"; else bad "$id - $out"; return 1; fi ;;
	5)  need_file $BUILD/05_xorbox "$id" "run: make" || return 1
	    expect_run "$id" "BOX OPENED" $BUILD/05_xorbox "$ans" ;;
	7)  need_file $BUILD/07_trial.patched "$id" \
	        "cp $BUILD/07_trial $BUILD/07_trial.patched, then patch the copy" || return 1
	    chmod +x $BUILD/07_trial.patched
	    cmp -s $BUILD/07_trial $BUILD/07_trial.patched && { bad "$id - the copy is unpatched"; return 1; }
	    expect_run "$id" "WAVE UNLOCKED" $BUILD/07_trial.patched ;;
	8)  check_inventory ;;
	9)  need_file $BUILD/09_stripped "$id" "run: make" || return 1
	    expect_run "$id" "STRIPPED CLEARED" $BUILD/09_stripped "$ans" ;;
	10) need_file $BUILD/10_arm "$id" "run: make" || return 1
	    expect_run "$id" "ARM CLEARED" qemu-aarch64 -L "$QEMU_SYSROOT" $BUILD/10_arm "$ans" ;;
	11) need_file $BUILD/capstone.patched "$id" \
	        "cp $BUILD/capstone $BUILD/capstone.patched, then patch the copy" || return 1
	    chmod +x $BUILD/capstone.patched
	    cmp -s $BUILD/capstone $BUILD/capstone.patched && { bad "$id - the copy is unpatched"; return 1; }
	    expect_run "$id" "WAVE CAPSTONE CLEARED" $BUILD/capstone.patched "$ans" ;;
	*)  return 9 ;;
	esac
}

check_inventory() {
	local script=scripts/inventory.py
	need_file "$script" 8 "write $script - see lessons/08-scripting.md" || return 1
	local json err rc
	err=$(mktemp)
	json=$(uv run --quiet --with r2pipe python3 "$script" $BUILD/08_many 2>"$err"); rc=$?
	if [ $rc -ne 0 ]; then bad "8 - script exited $rc"; tail -5 "$err"; rm -f "$err"; return 1; fi
	rm -f "$err"
	python3 -I -c '
import sys, json
try:
    d = json.loads(sys.stdin.read())
except Exception as e:
    print("not valid JSON: %s" % e); sys.exit(1)
if not isinstance(d, list): print("top level must be a JSON list"); sys.exit(1)
ops = [f for f in d if "op_" in f.get("name","")]
if len(ops) != 60:
    print("expected 60 op_* functions, got %d" % len(ops)); sys.exit(1)
for f in ops:
    if not all(k in f for k in ("name","addr","size")):
        print("each entry needs name, addr and size: %r" % f); sys.exit(1)
    if not isinstance(f["size"], int) or f["size"] <= 0:
        print("size must be a positive int: %r" % f); sys.exit(1)
need = {"op_io_init","op_spraying_clear","op_battery_selftest","op_driving_poll","op_plungers_arm"}
have = {n.split(".")[-1] for n in (f["name"] for f in ops)}
missing = need - have
if missing: print("missing: %s" % ", ".join(sorted(missing))); sys.exit(1)
print("60 functions, fields present, spot-checks found")
' <<<"$json"
	if [ $? -eq 0 ]; then record 8; ok "8"; return 0; fi
	bad "8"; return 1
}

# -------------------------------------------------------------- progress ----
record() {
	touch "$PROGRESS"
	grep -q "^$1	" "$PROGRESS" 2>/dev/null || printf '%s\t%s\n' "$1" "$(date -Is)" >> "$PROGRESS"
}

score() {
	local total=21 done_n=0
	[ -f "$PROGRESS" ] && done_n=$(wc -l < "$PROGRESS")
	echo "Progress: $done_n / $total exercises"
	echo
	local ids="0a 0b 0c 0d 1a 1b 1c 2a 2b 2c 3 4 5 6a 6b 6c 7 8 9 10 11"
	for id in $ids; do
		if grep -q "^$id	" "$PROGRESS" 2>/dev/null; then printf '  %s%-4s done%s\n' "$GRN" "$id" "$OFF"
		else printf '  %-4s -\n' "$id"; fi
	done
	echo
	for b in "3:static reverser" "9:ghost hunter" "11:WAVE capstone"; do
		grep -q "^${b%%:*}	" "$PROGRESS" 2>/dev/null && echo "  ${YEL}badge${OFF} ${b#*:}"
	done
}

# ------------------------------------------------------------------ main ----
case "${1:-help}" in
doctor) doctor ;;
score)  score ;;
help|"") echo "usage: ./check.sh doctor | score | <exercise-id> <answer>" ;;
*)
	id="$1"; ans="${2:-}"
	check_behaviour "$id" "$ans"; rc=$?
	if [ $rc -eq 9 ]; then
		[ -z "$ans" ] && { bad "$id needs an answer: make check N=$id A='...'"; exit 1; }
		check_hash "$id" "$ans"; rc=$?
	fi
	exit $rc ;;
esac
