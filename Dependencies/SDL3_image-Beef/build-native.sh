#!/usr/bin/env bash
# Linux counterpart of the Windows build. Builds libSDL3_image.so from the
# vendored SDL_image/ source (system SDL3 + codecs) and copies it into dist/.
set -euo pipefail
cd "$(dirname "$0")"
SONAME="libSDL3_image.so.0"
DISTREL="dist/SDL3_image-3.2.4/lib/linux-x64"
option="${1:-help}"; target="${2:-ALL}"
configure() {
  echo "Configuring $1..."
  cmake -S SDL_image -B "$2" -G Ninja -DCMAKE_BUILD_TYPE="$1" \
    -DSDLIMAGE_VENDORED=OFF -DBUILD_SHARED_LIBS=ON -DSDLIMAGE_SAMPLES=OFF -DSDLIMAGE_TESTS=OFF
}
build() {
  local cfg="$1" dir="$2" distdir="$3"
  [ -d "$dir" ] || { echo "$cfg build dir missing. Run 'make $cfg' first."; return; }
  echo "Building $cfg..."; cmake --build "$dir"
  mkdir -p "$distdir"
  cp -Lf "$(find "$dir" -name "$SONAME" | head -1)" "$distdir/$SONAME"
  echo "Copied $SONAME -> $distdir"
}
case "$option" in
  make)  { [ "$target" = DEBUG ] || [ "$target" = ALL ]; } && configure Debug build-linux-debug
         { [ "$target" = RELEASE ] || [ "$target" = ALL ]; } && configure Release build-linux-release; ;;
  build) { [ "$target" = DEBUG ] || [ "$target" = ALL ]; } && build Debug build-linux-debug "$DISTREL"
         { [ "$target" = RELEASE ] || [ "$target" = ALL ]; } && build Release build-linux-release "$DISTREL"; ;;
  clean) rm -rf build-linux-debug build-linux-release; echo "Clean complete."; ;;
  *) echo "Usage: build-native.sh [make|build|clean] [DEBUG|RELEASE|ALL]"; ;;
esac
