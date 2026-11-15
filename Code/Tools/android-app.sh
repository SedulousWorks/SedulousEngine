#!/usr/bin/env bash
# Builds an Android app around a program and, when asked, installs and runs it on the phone.
#
# The app is Code/Engine/Sedulous.Engine.Player.Android/app: SDL's activity running the program from
# libmain.so, which reads its data in place from the APK. The program is the player, with a game,
# or an RHI sample:
#   - Sedulous.Engine.Player.Android --game <project>: the game's content exported for Android (the
#     host's Sedulous.Tools.Export --content-only --platform Android64: Content.pak with ASTC
#     textures and player.xml as assets/Game, the SPIR-V shader pack and the rest of the engine's
#     data, its GUI fonts, as assets/Data).
#   - an RHI sample (Samples.RHI.Sample001_Triangle, say): the samples' shaders cooked from
#     Data/Samples/RHI (the host's Sedulous.Tools.ShaderPack --entries), since Android has no
#     shader compiler.
#
#   Usage:  Code/Tools/android-app.sh <Target> [--game <project>] [--install] [--run] [--args "<flags>"]
#           Code/Tools/android-app.sh Sedulous.Engine.Player.Android --template
#           e.g. Code/Tools/android-app.sh Sedulous.Engine.Player.Android --game Data/SampleProjects/SkyHopper --run
#                Code/Tools/android-app.sh Samples.RHI.Sample001_Triangle --run
#                CONFIG=ShippingRelease Code/Tools/android-app.sh Sedulous.Engine.Player.Android --template
#
# --template makes the player's export template instead of an app: the library, the app's Gradle
# project (SDL's Java glue in its sdl-java/) and the notices, staged in a player folder beside the
# Android build (build/<Config>_aarch64-linux-android33/AndroidPlayer) and installed from there by
# the host's Sedulous.Tools.Export --template create (a ShippingRelease build is the Release
# template a game ships, a Release build the Profile one).
#   Env:    CONFIG=Debug         the Android build's configuration (Debug, Release, ShippingRelease)
#           HOST_BIN=<dir>       the host build with the tools (default Code/build/Debug_Linux64)
#           SERIAL=<id>          the phone, when more than one is attached (adb -s)
#           NO_BUILD=1           package what is already built (skip BeefBuild)
#           VULKAN_LAYER=<.so>   a Vulkan layer to carry beside the program, as the Khronos
#                                validation layer's Android build: a debuggable app loads the
#                                layers in its own library folder, and the engine asks for
#                                validation in Debug
#
# The steps: BeefBuild compiles <Target> for aarch64-linux-android33 (each project a static
# archive); the NDK's clang links libmain.so from native/AndroidMain.c, the target's archive FIRST
# (every Beef archive carries a stub BeefMain, and the first one the linker meets is the one it
# takes), the rest of the Beef archives, the native libraries' Android archives
# (Dependencies/*/dist/Release-Android64; SDL linked whole, since its Java side finds its functions
# by name) and Beef's runtime; Gradle builds the app over SDL's vendored Java glue. The unstripped
# library stays in the staging folder for symbolising a crash; the app carries it stripped. Needs
# ANDROID_NDK_HOME, ANDROID_HOME (or ~/Android/Sdk) and a JDK 17 (JAVA_HOME).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
code="$(cd "$here/.." && pwd)"
repo="$(cd "$code/.." && pwd)"
deps="$repo/Dependencies"
platform="aarch64-linux-android33"
app="$code/Engine/Sedulous.Engine.Player.Android/app"

target="${1:-}"
if [[ -z "$target" || "$target" == -* ]]; then
  sed -n '2,32p' "$0" >&2
  exit 2
fi
shift
install=0; run=0; game=""; launch_args=""; template=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --install) install=1 ;;
    --run) install=1; run=1 ;;
    --game) game="$(cd "$2" && pwd)"; shift ;;
    --args) launch_args="$2"; shift ;;
    --template) template=1 ;;
    *) echo "android-app: unknown option $1" >&2; exit 2 ;;
  esac
  shift
done

config="${CONFIG:-Debug}"
host_bin="${HOST_BIN:-$code/build/Debug_Linux64}"
ndk="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"
[ -f "$ndk/build/cmake/android.toolchain.cmake" ] || { echo "android-app: set ANDROID_NDK_HOME to the Android NDK" >&2; exit 1; }
sdk="${ANDROID_HOME:-$HOME/Android/Sdk}"
tools="$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin"
adb=("$sdk/platform-tools/adb")
[ -n "${SERIAL:-}" ] && adb+=(-s "$SERIAL")

out="$code/build/${config}_${platform}"
staged="$code/build/android-app/$target/$config"

if [ "${NO_BUILD:-0}" != 1 ]; then
  echo "== building $target ($config, $platform)"
  (cd "$code" && BeefBuild -proddir=. -config="$config" -platform="$platform" -project="$target")
fi

echo "== linking libmain.so"
mkdir -p "$staged"
"$tools/${platform}-clang" -c -fPIC -I"$deps/SDL3-Beef/SDL/include" \
  "$code/Engine/Sedulous.Engine.Player.Android/native/AndroidMain.c" -o "$staged/AndroidMain.o"
start="$out/$target/$target.a"
[ -f "$start" ] || { echo "android-app: $start is not built" >&2; exit 1; }
beef_archives=$(find "$out" -name '*.a' ! -path "$start" | sort)
native_archives=$(find "$deps" -path '*/dist/Release-Android64/*.a' ! -path '*SDL3-Beef*' ! -path '*BeefRT-Android*' | sort)
"$tools/${platform}-clang++" -shared -o "$staged/libmain.so" "$staged/AndroidMain.o" \
  -Wl,--whole-archive "$deps/SDL3-Beef/dist/Release-Android64/libSDL3.a" -Wl,--no-whole-archive \
  "$start" -Wl,--start-group $beef_archives $native_archives \
  "$deps/BeefRT-Android/dist/Release-Android64/libBeefRT.a" -Wl,--end-group \
  -static-libstdc++ -landroid -llog -lm -ldl -lGLESv2 -lEGL -lOpenSLES -laaudio -pthread -Wl,--no-undefined

if [ "$template" = 1 ]; then
  player_dir="$out/AndroidPlayer"
  echo "== staging the export template's player folder in $player_dir"
  rm -rf "$player_dir"
  mkdir -p "$player_dir/android/sdl-java"
  "$tools/llvm-strip" --strip-debug -o "$player_dir/libmain.so" "$staged/libmain.so"
  # The Gradle project less Gradle's own state, and SDL's Java glue where its build.gradle looks first.
  (cd "$app" && find . -type f ! -path './.gradle/*' ! -path '*/build/*' ! -name local.properties \
    -exec cp --parents -p {} "$player_dir/android/" \;)
  cp -r "$deps/SDL3-Beef/SDL/android-project/app/src/main/java/." "$player_dir/android/sdl-java/"
  cp "$deps/THIRD-PARTY-NOTICES.txt" "$player_dir/"
  "$host_bin/Sedulous.Tools.Export/Sedulous.Tools.Export" --template create "$player_dir" --install
  exit 0
fi

echo "== staging $target into $staged"
rm -rf "$staged/jniLibs" "$staged/assets"
mkdir -p "$staged/jniLibs/arm64-v8a" "$staged/assets/Data"
# The debug information stays in the staging folder (llvm-symbolizer reads it there); the app
# carries the code.
"$tools/llvm-strip" --strip-debug -o "$staged/jniLibs/arm64-v8a/libmain.so" "$staged/libmain.so"
if [ -n "${VULKAN_LAYER:-}" ]; then
  cp "$VULKAN_LAYER" "$staged/jniLibs/arm64-v8a/"
fi
if [ -n "$game" ]; then
  export_dir="$staged/export"
  rm -rf "$export_dir"
  "$host_bin/Sedulous.Tools.Export/Sedulous.Tools.Export" "$game" --content-only --platform Android64 --out "$export_dir"
  dist="$(find "$export_dir" -mindepth 1 -maxdepth 1 -type d | head -1)"
  mkdir -p "$staged/assets/Game" "$staged/assets/Data/Engine/Shaders"
  cp "$dist/player.xml" "$dist"/Content*.pak "$staged/assets/Game/"
  cp "$dist/Data/Engine/Shaders/shaders.dpak" "$staged/assets/Data/Engine/Shaders/"
  # The rest of the engine's data (the GUI's built-in fonts), as a desktop player's dist carries
  # it; the shader sources stay behind, since the pack replaces them.
  for entry in "$repo"/Data/Engine/*; do
    [ "$(basename "$entry")" = Shaders ] || cp -r "$entry" "$staged/assets/Data/Engine/"
  done
else
  mkdir -p "$staged/assets/Data/Samples/RHI"
  "$host_bin/Sedulous.Tools.ShaderPack/Sedulous.Tools.ShaderPack" --entries "$repo/Data/Samples/RHI" \
    "$staged/assets/Data/Samples/RHI/shaders.dpak" spirv
fi

echo "== building the APK"
(cd "$app" && echo "sdk.dir=$sdk" > local.properties && ./gradlew --no-daemon -q assembleDebug \
  -PsedulousStaged="$staged" -PsdlJava="$deps/SDL3-Beef/SDL/android-project/app/src/main/java")
apk="$staged/gradle/app/outputs/apk/debug/app-debug.apk"
echo "== $apk"

if [ "$install" = 1 ]; then
  "${adb[@]}" install -r "$apk"
fi
if [ "$run" = 1 ]; then
  "${adb[@]}" logcat -c
  "${adb[@]}" shell am start -n com.sedulous.player/.PlayerActivity ${launch_args:+--es args "\"$launch_args\""}
  echo "== started; its log is 'adb logcat -s Sedulous SDL/APP'"
fi
