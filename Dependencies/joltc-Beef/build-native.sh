#!/usr/bin/env bash
# Linux counterpart of build-native.ps1. Builds libjoltc.so (Jolt statically
# linked in) and copies it into dist/ for [Configs.*.Linux64] + runtime.
set -euo pipefail
cd "$(dirname "$0")"
option="${1:-help}"; target="${2:-ALL}"
configure() { echo "Configuring $1..."; cmake -S . -B "$2" -G Ninja -DCMAKE_BUILD_TYPE="$1" -DINTERPROCEDURAL_OPTIMIZATION=OFF; }
build() {
  local cfg="$1" dir="$2" distdir="$3"
  [ -d "$dir" ] || { echo "$cfg build dir missing. Run 'make $cfg' first."; return; }
  echo "Building $cfg..."; cmake --build "$dir"
  mkdir -p "$distdir"
  cp -f "$(find "$dir" -name libjoltc.so | head -1)" "$distdir/libjoltc.so"
  echo "Copied libjoltc.so -> $distdir"
}

# ---- wasm32 (Emscripten) ----
#
# emcmake puts the emscripten toolchain in front of cmake; everything after is the same as a
# native build. Needs emcc on PATH: source the emsdk's emsdk_env.sh first. The result lands in
# dist/Release-wasm32, which is where the BeefProj's wasm32 LibPaths look.
wasm() {
  command -v emcmake >/dev/null || { echo "emcmake not on PATH. Source the emsdk's emsdk_env.sh."; exit 1; }
  echo "Configuring wasm32..."
  # STATIC, not shared: wasm has no shared libraries, so JPH_MASTER_PROJECT goes OFF and
  # joltc falls back to the archive it builds when it is not the top level project.
  emcmake cmake -S . -B build-wasm -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DINTERPROCEDURAL_OPTIMIZATION=OFF -DJPH_MASTER_PROJECT=OFF
  echo "Building wasm32..."
  cmake --build build-wasm
  mkdir -p dist/Release-wasm32
  # BOTH archives: the Linux .so bundles Jolt statically, but a static joltc.a only holds the
  # C wrapper and leaves JPH::Allocate and the rest to libJolt.a beside it.
  for l in libjoltc.a libJolt.a; do
    cp -f "$(find build-wasm -name "$l" | head -1)" "dist/Release-wasm32/$l"
    echo "Copied $l -> dist/Release-wasm32"
  done
}

case "$option" in
  make)  { [ "$target" = DEBUG ] || [ "$target" = ALL ]; } && configure Debug build-linux-debug
         { [ "$target" = RELEASE ] || [ "$target" = ALL ]; } && configure Release build-linux-release; ;;
  build) { [ "$target" = DEBUG ] || [ "$target" = ALL ]; } && build Debug build-linux-debug dist/Debug-Linux64
         { [ "$target" = RELEASE ] || [ "$target" = ALL ]; } && build Release build-linux-release dist/Release-Linux64; ;;
  wasm)  wasm; ;;
  clean) rm -rf build-linux-debug build-linux-release build-wasm; echo "Clean complete."; ;;
  *) echo "Usage: build-native.sh [make|build|wasm|clean] [DEBUG|RELEASE|ALL]"; ;;
esac
