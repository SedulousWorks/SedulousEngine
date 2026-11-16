#!/usr/bin/env bash
# Beef's runtime (BeefRT) for the Android player, arm64-v8a at API 33, from a Beef source
# checkout: BeefBuild compiles Beef code for Android but ships no runtime for it, and the
# player's link (libmain.so) needs one. The archive is committed in dist/Release-Android64, so
# exporting a game needs no Beef sources; this rebuilds it.
#
#   build-native.sh android   needs ANDROID_NDK_HOME (or ANDROID_NDK_ROOT) and BEEF_SOURCE, the
#                             Beef checkout (its BeefRT/, BeefySysLib/, ...); the runtime must
#                             build for Android there (bionic's struct sigaction, the core count)
#
# make, build and wasm do nothing: the desktop and web runtimes come with BeefBuild.
set -euo pipefail
cd "$(dirname "$0")"

android() {
  local ndk="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"
  [ -f "$ndk/build/cmake/android.toolchain.cmake" ] || { echo "Set ANDROID_NDK_HOME to the Android NDK."; exit 1; }
  [ -f "${BEEF_SOURCE:-}/BeefRT/CMakeLists.txt" ] || { echo "Set BEEF_SOURCE to a Beef checkout."; exit 1; }
  echo "Configuring Android64..."
  # Without libffi, which the Beef sources carry for desktop hosts only: what it serves (calling a
  # method through reflection with arguments built at run time) is not available on Android.
  cmake -DCMAKE_TOOLCHAIN_FILE="$ndk/build/cmake/android.toolchain.cmake" -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-33 -S "$BEEF_SOURCE/BeefRT" -B build-android -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DBF_DISABLE_FFI=1
  echo "Building Android64..."
  cmake --build build-android
  mkdir -p dist/Release-Android64
  cp -f "$(find build-android -name libBeefRT.a | head -1)" dist/Release-Android64/libBeefRT.a
  "$ndk"/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip --strip-debug dist/Release-Android64/libBeefRT.a
  echo "Copied libBeefRT.a -> dist/Release-Android64 (from $(git -C "$BEEF_SOURCE" rev-parse --short HEAD 2>/dev/null || echo "an unknown revision"))"
}

case "${1:-help}" in
  android) android ;;
  make|build|wasm|clean) echo "Nothing to do: only the Android runtime is built here." ;;
  *) echo "Usage: build-native.sh [android]" ;;
esac
