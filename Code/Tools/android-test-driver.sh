#!/system/bin/sh
# Runs one Beef test executable on an Android phone, standing in for BeefBuild's test manager on the
# pipe the executable expects (as Code/Tools/asan-test.py does on the desktop). It runs in adb's
# shell, Android's mksh, which has no Python: android-tests.sh pushes it beside the suites.
#
#   sh android-test-driver.sh <Suite> [name-filter]      (from the suites' folder)
#
# The suite opens <name> in the temp folder to write and <name>__ to read, <name> being its
# argument. adb's shell may not make a fifo (SELinux), so both are plain files: the suite writes
# its lines into <name>, which this follows with tail -f, and reads what this appends to <name>__
# (a read at the end of a file finds nothing yet, and the suite reads again). The suite lists its
# tests between :TestInit and :TestBegin, one per line with the name first, then asks with
# :TestQuery for the index to run next until :TestFinish. A filter runs only the tests whose name
# contains it. Exits nonzero when a test failed or the suite died.

suite="$1"
filter="$2"
dir="${TMPDIR:-/data/local/tmp}"
name="bftest$$"
toManager="$dir/$name"
toSuite="$dir/${name}__"
tab="$(printf '\t')"
cr="$(printf '\r')"

rm -f "$toManager" "$toSuite"
: > "$toManager" || exit 2
: > "$toSuite" || exit 2

TMPDIR="$dir" "./$suite" "$name" &
pid=$!
# The suite's end said aloud: a crash leaves nothing more to read, so this does.
( while kill -0 "$pid" 2>/dev/null; do sleep 1; done; echo ":Exited" >> "$toManager" ) &
watcher=$!

# A coprocess, so the loop runs in this shell and tail is ended by its own pid.
tail -f -n +1 "$toManager" |&
tailPid=$!
set -A names
count=0
next=0
listing=0
failures=0
while IFS= read -p -r line; do
	line="${line%$cr}"
	command="${line%%$tab*}"
	case "$command" in
	:TestInit) listing=1 ;;
	:TestBegin) listing=0 ;;
	:TestQuery)
		while [ "$next" -lt "$count" ]; do
			case "${names[$next]}" in *"$filter"*) break ;; esac
			next=$((next + 1))
		done
		if [ "$next" -lt "$count" ]; then
			echo "RUN: ${names[$next]}"
			printf ':TestRun\t%d\n' "$next" >> "$toSuite"
			next=$((next + 1))
		else
			printf ':TestFinish\n' >> "$toSuite"
		fi
		;;
	:TestFail|:TestFatal)
		echo "FAIL: $line"
		failures=$((failures + 1))
		[ "$command" = ":TestFatal" ] && printf ':TestContinue\n' >> "$toSuite"
		;;
	:TestWrite) printf '%s\n' "${line#*$tab}" | tr '\r' '\n' ;;
	:Exited) break ;;
	*)
		if [ "$listing" = 1 ] && [ -n "$command" ]; then
			names[$count]="$command"
			count=$((count + 1))
		fi
		;;
	esac
done
kill "$tailPid" 2>/dev/null

wait "$pid"
code=$?
kill "$watcher" 2>/dev/null
rm -f "$toManager" "$toSuite"
echo "$suite: exit $code, $failures test failure(s) of $count"
[ "$code" = 0 ] && [ "$failures" = 0 ]
