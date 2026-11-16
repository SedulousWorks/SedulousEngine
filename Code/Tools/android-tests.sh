#!/usr/bin/env bash
# Runs the engine's headless test suites on an Android phone over adb.
#
#   Code/Tools/android-tests.sh [Suite ...] [--filter <name part>] [--no-build]
#           (default: the suites Tools/android-workspace.py lists as TEST_TARGETS)
#   Env:    SERIAL=<id>     the phone, when more than one is attached (adb -s)
#           DATA=0          skip pushing Data/
#
# Each suite is built in the Test config for aarch64-linux-android33 as a test executable (its
# project's Android Test section, which Tools/android-workspace.py writes, says so); BeefBuild's own
# link of it fails, as no host linker takes Android objects, so the objects it records are linked
# with the NDK's clang instead. The executable is pushed to /data/local/tmp/sedulous-tests and run
# there under android-test-driver.sh, which stands in for BeefBuild's test manager on the suite's
# pipe. The engine's data a suite reads (Data/.dataroot, Engine, Tests, Samples, Editor; not the
# sample projects) goes beside the suites, where the data root's walk up from the executable finds
# it. Needs ANDROID_NDK_HOME, ANDROID_HOME (or ~/Android/Sdk) and Beef's Android runtime
# (Dependencies/BeefRT-Android) built with the pipe and CPU fixes.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
code="$(cd "$here/.." && pwd)"
repo="$(cd "$code/.." && pwd)"
deps="$repo/Dependencies"
platform="aarch64-linux-android33"
remote="/data/local/tmp/sedulous-tests"

suites=(); filter=""; build=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --filter) filter="$2"; shift ;;
    --no-build) build=0 ;;
    -*) echo "android-tests: unknown option $1" >&2; exit 2 ;;
    *) suites+=("$1") ;;
  esac
  shift
done
if [[ ${#suites[@]} -eq 0 ]]; then
  while IFS= read -r suite; do suites+=("$suite"); done < <(python3 - "$here/android-workspace.py" <<'E'
import re, sys
text = open(sys.argv[1]).read()
block = re.search(r"TEST_TARGETS = \[(.*?)\]", text, re.S).group(1)
print("\n".join(re.findall(r'"([^"]+)"', block)))
E
)
fi

ndk="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"
[ -f "$ndk/build/cmake/android.toolchain.cmake" ] || { echo "android-tests: set ANDROID_NDK_HOME to the Android NDK" >&2; exit 2; }
sdk="${ANDROID_HOME:-$HOME/Android/Sdk}"
tools="$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin"
adb=("$sdk/platform-tools/adb")
[ -n "${SERIAL:-}" ] && adb+=(-s "$SERIAL")
[[ "$("${adb[@]}" get-state 2>/dev/null || true)" == "device" ]] || { echo "android-tests: no phone attached (adb devices)" >&2; exit 2; }

out="$code/build/Test_$platform"
staged="$code/build/android-tests"
mkdir -p "$staged"
native_archives=$(find "$deps" -path '*/dist/Release-Android64/*.a' ! -path '*BeefRT-Android*' | sort)

"${adb[@]}" shell mkdir -p "$remote"
"${adb[@]}" push --sync "$here/android-test-driver.sh" "$remote/" > /dev/null
if [[ "${DATA:-1}" != "0" ]]; then
  "${adb[@]}" shell mkdir -p "$remote/Data"
  for part in .dataroot Engine Tests Samples Editor; do
    "${adb[@]}" push --sync "$repo/Data/$part" "$remote/Data/" > /dev/null
  done
fi

failed=()
for suite in "${suites[@]}"; do
  if [[ "$build" == 1 ]]; then
    echo "== building $suite"
    # BeefBuild's link fails here (no host linker takes Android objects): its objects are what is
    # wanted, checked below.
    (cd "$code" && BeefBuild -proddir=. -config=Test -platform="$platform" -test -project="$suite" > "$staged/$suite.build.log" 2>&1) || true
  fi
  # BeefBuild records the link it tried (its line 2: the output, then every object the program
  # takes, the suite's and its dependencies'); the same objects, linked by the NDK's clang.
  record="$out/$suite/$suite.build.txt"
  if [[ ! -f "$record" ]]; then
    echo "== $suite: not built (see $staged/$suite.build.log)" >&2
    failed+=("$suite")
    continue
  fi
  objects=$(sed -n 2p "$record" | tr ' ' '\n' | grep '\.o$')
  "$tools/${platform}-clang++" -pie -o "$staged/$suite" $objects \
    -Wl,--start-group $native_archives "$deps/BeefRT-Android/dist/Release-Android64/libBeefRT.a" -Wl,--end-group \
    -static-libstdc++ -landroid -llog -lm -ldl -lGLESv2 -lEGL -lOpenSLES -laaudio -pthread
  "$tools/llvm-strip" --strip-debug "$staged/$suite"
  "${adb[@]}" push --sync "$staged/$suite" "$remote/" > /dev/null
  echo "== $suite"
  if "${adb[@]}" shell "cd $remote && sh ./android-test-driver.sh $suite '$filter'"; then
    :
  else
    failed+=("$suite")
  fi
done

echo
if [[ ${#failed[@]} -eq 0 ]]; then
  echo "all ${#suites[@]} suite(s) passed"
else
  echo "${#failed[@]} of ${#suites[@]} suite(s) failed: ${failed[*]}"
  exit 1
fi
