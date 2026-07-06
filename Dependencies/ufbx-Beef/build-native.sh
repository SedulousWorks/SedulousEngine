#!/usr/bin/env bash
# Linux counterpart of build-native.ps1. Builds the native ufbx static
# library and copies it into dist/ so [Configs.*.Linux64] LibPaths can find it.
set -euo pipefail
cd "$(dirname "$0")"

LIBS=("libufbx.a")   # static libs produced by this project

option="${1:-help}"; target="${2:-ALL}"
configure() { echo "Configuring $1..."; cmake -S . -B "$2" -G Ninja -DCMAKE_BUILD_TYPE="$1"; }
build() {
  local cfg="$1" dir="$2" distdir="$3"
  [ -d "$dir" ] || { echo "$cfg build dir missing. Run 'make $cfg' first."; return; }
  echo "Building $cfg..."; cmake --build "$dir"
  mkdir -p "$distdir"
  for l in "${LIBS[@]}"; do cp -f "$dir/$l" "$distdir/$l"; echo "Copied $l -> $distdir"; done
}
case "$option" in
  make)  { [ "$target" = DEBUG ] || [ "$target" = ALL ]; } && configure Debug build-linux-debug
         { [ "$target" = RELEASE ] || [ "$target" = ALL ]; } && configure Release build-linux-release; ;;
  build) { [ "$target" = DEBUG ] || [ "$target" = ALL ]; } && build Debug build-linux-debug dist/Debug-Linux64
         { [ "$target" = RELEASE ] || [ "$target" = ALL ]; } && build Release build-linux-release dist/Release-Linux64; ;;
  clean) rm -rf build-linux-debug build-linux-release; echo "Clean complete."; ;;
  *) echo "Usage: build-native.sh [make|build|clean] [DEBUG|RELEASE|ALL]"; ;;
esac
