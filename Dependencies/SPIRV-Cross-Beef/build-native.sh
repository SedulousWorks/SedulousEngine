#!/usr/bin/env bash
# Linux counterpart of the Windows build. Builds the SPIRV-Cross C API shared
# library from the vendored SPIRV-Cross/ source and copies it into dist/.
set -euo pipefail
cd "$(dirname "$0")"
SONAME="libspirv-cross-c-shared.so.0"
option="${1:-help}"; target="${2:-ALL}"
configure() {
  echo "Configuring $1..."
  cmake -S SPIRV-Cross -B "$2" -G Ninja -DCMAKE_BUILD_TYPE="$1" \
    -DSPIRV_CROSS_SHARED=ON -DSPIRV_CROSS_CLI=OFF -DSPIRV_CROSS_ENABLE_TESTS=OFF
}
build() {
  local cfg="$1" dir="$2" distdir="$3"
  [ -d "$dir" ] || { echo "$cfg build dir missing. Run 'make $cfg' first."; return; }
  echo "Building $cfg..."; cmake --build "$dir"
  mkdir -p "$distdir"
  cp -Lf "$dir/$SONAME" "$distdir/$SONAME"      # dereference versioned symlink to real file
  echo "Copied $SONAME -> $distdir"
}
case "$option" in
  make)  { [ "$target" = DEBUG ] || [ "$target" = ALL ]; } && configure Debug build-linux-debug
         { [ "$target" = RELEASE ] || [ "$target" = ALL ]; } && configure Release build-linux-release; ;;
  build) { [ "$target" = DEBUG ] || [ "$target" = ALL ]; } && build Debug build-linux-debug dist/Linux64/Debug
         { [ "$target" = RELEASE ] || [ "$target" = ALL ]; } && build Release build-linux-release dist/Linux64/Release; ;;
  clean) rm -rf build-linux-debug build-linux-release; echo "Clean complete."; ;;
  *) echo "Usage: build-native.sh [make|build|clean] [DEBUG|RELEASE|ALL]"; ;;
esac
