#!/usr/bin/env bash
# Linux counterpart of build-native.ps1. Builds the bc7enc C wrapper, which carries the
# vendored encoder with it, and copies it into dist/ so [Configs.*.Linux64] LibPaths find it.
set -euo pipefail
cd "$(dirname "$0")"

SRC="."
LIBS=("libastcenc.a")

option="${1:-help}"; target="${2:-ALL}"
configure() { echo "Configuring $1..."; cmake -S "$SRC" -B "$2" -G Ninja -DCMAKE_BUILD_TYPE="$1"; }
build() {
  local cfg="$1" dir="$2" distdir="$3"
  [ -d "$dir" ] || { echo "$cfg build dir missing. Run 'make $cfg' first."; return; }
  echo "Building $cfg..."; cmake --build "$dir"
  mkdir -p "$distdir"
  for l in "${LIBS[@]}"; do cp -f "$(find "$dir" -name "$l" | head -1)" "$distdir/$l"; echo "Copied $l -> $distdir"; done
}

# ---- wasm32 (Emscripten) ----
#
# emcmake puts the emscripten toolchain in front of cmake; everything after is the same as a
# native build. Needs emcc on PATH: source the emsdk's emsdk_env.sh first. The result lands in
# dist/Release-wasm32, which is where the BeefProj's wasm32 LibPaths look.
wasm() {
  command -v emcmake >/dev/null || { echo "emcmake not on PATH. Source the emsdk's emsdk_env.sh."; exit 1; }
  echo "Configuring wasm32..."
  emcmake cmake -S "$SRC" -B build-wasm -G Ninja -DCMAKE_BUILD_TYPE=Release
  echo "Building wasm32..."
  cmake --build build-wasm
  mkdir -p dist/Release-wasm32
  for l in "${LIBS[@]}"; do cp -f "$(find build-wasm -name "$l" | head -1)" "dist/Release-wasm32/$l"; echo "Copied $l -> dist/Release-wasm32"; done
}

case "$option" in
  make)  { [ "$target" = DEBUG ] || [ "$target" = ALL ]; } && configure Debug build-linux-debug
         { [ "$target" = RELEASE ] || [ "$target" = ALL ]; } && configure Release build-linux-release; ;;
  build) { [ "$target" = DEBUG ] || [ "$target" = ALL ]; } && build Debug build-linux-debug dist/Debug-Linux64
         { [ "$target" = RELEASE ] || [ "$target" = ALL ]; } && build Release build-linux-release dist/Release-Linux64; ;;
  wasm)  wasm; ;;
  clean) rm -rf build-linux-debug build-linux-release; echo "Clean complete."; ;;
  *) echo "Usage: build-native.sh [make|build|clean] [DEBUG|RELEASE|ALL]"; ;;
esac
