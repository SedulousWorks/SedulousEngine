#!/usr/bin/env bash
# SDL3 for the Android player, from the vendored source in SDL/ (SDL/README.vendored.md): static,
# arm64-v8a at API 33, into dist/Release-Android64. Windows links the prebuilt SDL in
# dist/SDL3-3.4.0 and Linux the system's, so make, build and wasm have nothing to do here.
#
#   build-native.sh android   needs ANDROID_NDK_HOME (or ANDROID_NDK_ROOT)
set -euo pipefail
cd "$(dirname "$0")"

android() {
  local ndk="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"
  [ -f "$ndk/build/cmake/android.toolchain.cmake" ] || { echo "Set ANDROID_NDK_HOME to the Android NDK."; exit 1; }
  echo "Configuring Android64..."
  # Static and position independent: the player links it whole into its shared libmain.so.
  cmake -DCMAKE_TOOLCHAIN_FILE="$ndk/build/cmake/android.toolchain.cmake" -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-33 -S SDL -B build-android -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DSDL_SHARED=OFF -DSDL_STATIC=ON -DSDL_STATIC_PIC=ON -DSDL_TEST_LIBRARY=OFF -DSDL_TESTS=OFF \
    -DSDL_EXAMPLES=OFF -DSDL_INSTALL=OFF
  echo "Building Android64..."
  cmake --build build-android
  mkdir -p dist/Release-Android64
  cp -f build-android/libSDL3.a dist/Release-Android64/libSDL3.a
  # Without debug information: the NDK's toolchain file compiles with it even in Release.
  "$ndk"/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip --strip-debug dist/Release-Android64/libSDL3.a
  echo "Copied libSDL3.a -> dist/Release-Android64"
}

case "${1:-help}" in
  android) android ;;
  make|build|wasm|clean) echo "Nothing to do: Windows has the prebuilt SDL and Linux the system's." ;;
  *) echo "Usage: build-native.sh [android]" ;;
esac
