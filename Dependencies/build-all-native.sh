#!/usr/bin/env bash
# Every native dependency at once: each <name>-Beef/build-native.sh in this folder, in turn.
#
#   build-all-native.sh status [names...]  which committed archives are older than their sources
#   build-all-native.sh build  [names...]  configure and build each one's Debug and Release (Linux64)
#   build-all-native.sh wasm   [names...]  build each one's wasm32 archive (those that have one)
#
# Names are folder names (joltc-Beef, or just joltc); none means all of them. A build goes on past a
# failure and lists the failures at the end. Bulkan, Win32-Beef, SDL3-Beef, wgpu-Beef, Dxc-Beef and
# gpui have no build script: they are bindings over a system or prebuilt library.
#
# status reads git, not file times: a platform's archives are outdated when a commit touched the
# library's native sources (C, C++, headers, assembly, CMake) after the last commit that touched
# its dist/<Config>-<Platform> folder. That commit is named, since one that changed only a comment
# or another platform's flags needs no rebuild. It covers Win64 too, so this machine can say what Windows
# needs rebuilt (build-all-native.ps1 then builds it there).
set -uo pipefail
cd "$(dirname "$0")"

option="${1:-help}"
shift || true

# The dependencies with a bash build script, filtered by the names given.
selected() {
  local dir name
  for dir in */; do
    dir="${dir%/}"
    [ -f "$dir/build-native.sh" ] || continue
    if [ "$#" -gt 0 ]; then
      local want="" match=0
      for want in "$@"; do
        # Case does not matter: angelscript names AngelScript-Beef.
        name="${want,,}"; name="${name%-beef}"
        [ "${dir,,}" = "$name-beef" ] || [ "${dir,,}" = "$name" ] && match=1
      done
      [ "$match" = 1 ] || continue
    fi
    echo "$dir"
  done
}

# The last commit time (seconds) of the given pathspecs, or 0.
last_commit() { local t; t=$(git log -1 --format=%ct -- "$@" 2>/dev/null); echo "${t:-0}"; }

native_sources() {
  local d="$1" ext
  for ext in c cc cpp cxx h hh hpp hxx inl S s asm; do echo ":(glob)$d/**/*.$ext"; done
  echo ":(glob)$d/**/CMakeLists.txt"
  echo ":(glob)$d/**/*.cmake"
  echo ":(exclude)$d/dist"
}

status() {
  local d platform cfgs cfg folder sources archive oldest any
  printf "%-24s %-9s %s\n" "dependency" "platform" "archives"
  for d in $(selected "$@"); do
    mapfile -t specs < <(native_sources "$d")
    sources=$(last_commit "${specs[@]}")
    newest=$(git log -1 --format='%h %s' -- "${specs[@]}" 2>/dev/null | cut -c1-60)
    for platform in Win64 Linux64 wasm32; do
      oldest=0; any=0
      for cfg in Debug Release; do
        folder="$d/dist/$cfg-$platform"
        [ -d "$folder" ] || continue
        any=1
        archive=$(last_commit "$folder")
        if [ "$oldest" = 0 ] || [ "$archive" -lt "$oldest" ]; then oldest="$archive"; fi
      done
      if [ "$any" = 0 ]; then
        # Windows archives are expected wherever a PowerShell script builds them.
        [ "$platform" = Win64 ] && [ -f "$d/build-native.ps1" ] && printf "%-24s %-9s %s\n" "$d" "$platform" "MISSING"
        continue
      fi
      if [ "$oldest" = 0 ]; then
        printf "%-24s %-9s %s\n" "$d" "$platform" "not committed"
      elif [ "$oldest" -lt "$sources" ]; then
        printf "%-24s %-9s %s\n" "$d" "$platform" "OUTDATED (built $(date -d "@$oldest" +%F); sources $(date -d "@$sources" +%F): $newest)"
      else
        printf "%-24s %-9s %s\n" "$d" "$platform" "up to date ($(date -d "@$oldest" +%F))"
      fi
    done
  done
}

failed=()
run() {
  local d="$1"; shift
  echo "==== $d: $*"
  if ! (cd "$d" && ./build-native.sh "$@"); then failed+=("$d ($*)"); return 1; fi
}

case "$option" in
  status) status "$@" ;;
  build)
    for d in $(selected "$@"); do
      run "$d" make ALL && run "$d" build ALL
    done ;;
  wasm)
    command -v emcmake >/dev/null || { echo "emcmake not on PATH. Source the emsdk's emsdk_env.sh."; exit 1; }
    for d in $(selected "$@"); do
      grep -q '^ *wasm)' "$d/build-native.sh" || { echo "==== $d: no wasm32 build"; continue; }
      run "$d" wasm
    done ;;
  *)
    echo "Usage: build-all-native.sh [status|build|wasm] [names...]"
    exit 1 ;;
esac

if [ "${#failed[@]}" -gt 0 ]; then
  echo
  echo "FAILED:"
  printf '  %s\n' "${failed[@]}"
  exit 1
fi
