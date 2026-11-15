#!/usr/bin/env bash
# Builds the Android player's app for a game and, when asked, installs and runs it on a device.
#
#   Code/Tools/android-app.sh <export-dir> [--config Debug|Release|ShippingRelease] [--skip-build]
#                             [--install] [--run] [--args "<player flags>"]
#
# <export-dir> is a content-only Android export of the game (Sedulous.Tools.Export <project>
# --content-only --platform Android64 --out <dir>): its player.xml and Content.pak become the APK's
# assets/Game, its Data/ the APK's assets/Data.
#
# The steps: BeefBuild compiles Sedulous.Engine.Player.Android for aarch64-linux-android33 (each
# project a static archive); the NDK's clang links libmain.so from native/AndroidMain.c, the
# player's archive FIRST (every Beef archive carries a stub BeefMain, and the first one the linker
# meets is the one it takes), the rest of the Beef archives, the native libraries' Android
# archives (Dependencies/*/dist/Release-Android64; SDL linked whole, since its Java side finds its
# functions by name) and Beef's runtime; Gradle builds the app over SDL's vendored Java glue. Needs
# ANDROID_NDK_HOME, ANDROID_HOME (or ~/Android/Sdk) and a JDK 17 (JAVA_HOME).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
code="$here/.."
repo="$code/.."
deps="$repo/Dependencies"
platform="aarch64-linux-android33"
project="Sedulous.Engine.Player.Android"
app="$code/Engine/$project/app"

[ $# -ge 1 ] || { sed -n '2,9p' "$0"; exit 1; }
export_dir="$(cd "$1" && pwd)"; shift
config=Debug; build=1; install=0; run=0; launch_args=""
while [ $# -gt 0 ]; do
  case "$1" in
    --config) config="$2"; shift ;;
    --skip-build) build=0 ;;
    --install) install=1 ;;
    --run) install=1; run=1 ;;
    --args) launch_args="$2"; shift ;;
    *) echo "android-app: unknown option $1"; exit 1 ;;
  esac
  shift
done

ndk="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"
[ -f "$ndk/build/cmake/android.toolchain.cmake" ] || { echo "android-app: set ANDROID_NDK_HOME to the Android NDK"; exit 1; }
sdk="${ANDROID_HOME:-$HOME/Android/Sdk}"
tools="$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin"
[ -f "$export_dir/player.xml" ] || { echo "android-app: $export_dir holds no player.xml (a content-only Android export)"; exit 1; }

out="$code/build/${config}_${platform}"
staged="$code/build/android-app/$config"

if [ "$build" = 1 ]; then
  echo "android-app: building $project ($config, $platform)"
  (cd "$code" && BeefBuild -proddir=. -config="$config" -platform="$platform" -project="$project")
fi

echo "android-app: linking libmain.so"
mkdir -p "$staged/jniLibs/arm64-v8a"
"$tools/${platform}-clang" -c -fPIC -I"$deps/SDL3-Beef/SDL/include" \
  "$code/Engine/$project/native/AndroidMain.c" -o "$staged/AndroidMain.o"
start="$out/$project/$project.a"
beef_archives=$(find "$out" -name '*.a' ! -path "$start" | sort)
native_archives=$(find "$deps" -path '*/dist/Release-Android64/*.a' ! -path '*SDL3-Beef*' ! -path '*BeefRT-Android*' | sort)
"$tools/${platform}-clang++" -shared -o "$staged/jniLibs/arm64-v8a/libmain.so" "$staged/AndroidMain.o" \
  -Wl,--whole-archive "$deps/SDL3-Beef/dist/Release-Android64/libSDL3.a" -Wl,--no-whole-archive \
  "$start" -Wl,--start-group $beef_archives $native_archives \
  "$deps/BeefRT-Android/dist/Release-Android64/libBeefRT.a" -Wl,--end-group \
  -static-libstdc++ -landroid -llog -lm -ldl -lGLESv2 -lEGL -lOpenSLES -laaudio -pthread -Wl,--no-undefined

echo "android-app: staging the game from $export_dir"
rm -rf "$staged/assets"
mkdir -p "$staged/assets/Game"
cp "$export_dir/player.xml" "$staged/assets/Game/"
cp "$export_dir"/Content*.pak "$staged/assets/Game/"
[ -d "$export_dir/Data" ] && cp -r "$export_dir/Data" "$staged/assets/Data"

echo "android-app: building the app"
(cd "$app" && echo "sdk.dir=$sdk" > local.properties && ./gradlew --no-daemon -q assembleDebug \
  -PsedulousStaged="$staged" -PsdlJava="$deps/SDL3-Beef/SDL/android-project/app/src/main/java")
apk="$staged/gradle/app/outputs/apk/debug/app-debug.apk"
echo "android-app: $apk"

adb="$sdk/platform-tools/adb"
if [ "$install" = 1 ]; then
  "$adb" install -r "$apk"
fi
if [ "$run" = 1 ]; then
  "$adb" logcat -c
  "$adb" shell am start -n com.sedulous.player/.PlayerActivity ${launch_args:+--es args "\"$launch_args\""}
  echo "android-app: started; its log is 'adb logcat -s Sedulous SDL/APP'"
fi
