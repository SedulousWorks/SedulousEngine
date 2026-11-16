# Building Sedulous

## Requirements

- A recent [Beef nightly](https://nightly.beeflang.org/index.html), for BeefBuild and the IDE.
  Upstream is sufficient; the `working` branch of [our fork](https://github.com/jayrulez/Beef)
  carries the compiler fixes we have contributed that are still in review, none of which the
  engine depends on.
- Linux x64 or Windows x64. Prebuilt native libraries for both are in the tree under
  `Dependencies/*/dist`, except SDL3 on Linux, which links the system's: install SDL 3.4
  (`libsdl3-dev` or your distribution's equivalent). The dependencies built from source carry a
  `build-native.sh` / `build-native.ps1` to rebuild them, and `Dependencies/build-all-native.sh` /
  `build-all-native.ps1` run every one: `status` says which committed archives are older than
  their sources, `build` rebuilds them (and `wasm`, from bash, the wasm32 ones).
- A Vulkan 1.3 or D3D12 capable GPU to run anything that draws.
- For web builds, [emsdk](https://emscripten.org/) on the path.
- For Android builds, a Linux host with the Android NDK r30 (`30.0.16248370`) named by
  `ANDROID_NDK_HOME`; to package an app, the Android SDK (`ANDROID_HOME`, with platform 36) and a
  JDK 17 (`JAVA_HOME`). The first Gradle build downloads Gradle and the Android plugin.

## Building

Everything is one Beef workspace under `Code/`:

```
cd Code
BeefBuild -project=Samples.HelloWindow          # the smallest sample
BeefBuild -project=Sedulous.Tools.Editor         # the editor
BeefBuild -project=Samples.Sandbox               # the engine sandbox
BeefBuild -test -project=Sedulous.Core.Tests     # one test project
```

Outputs land in `Code/build/<Config>_<Platform>/<Project>/`. Executables find the engine's data
by walking up to the `.dataroot` marker in `Data/`, so they run from the build directory, the
project directory or the repository root alike.

## Android

BeefBuild compiles the player for `aarch64-linux-android33`; the NDK's clang links it into the
app's `libmain.so` against the native libraries' `dist/Release-Android64` archives and Beef's
Android runtime (`Dependencies/BeefRT-Android`, committed; its `build-native.sh` rebuilds it from
a Beef checkout). Only the player and the RHI samples build for Android: the editor and the tools
run on the desktop.

```
Code/Tools/android-app.sh Sedulous.Engine.Player.Android --game Data/SampleProjects/SkyHopper --run
Code/Tools/android-tests.sh                       # the headless suites, on a phone over adb
CONFIG=ShippingRelease Code/Tools/android-app.sh Sedulous.Engine.Player.Android --template
```

The first builds a development app with a sample game in it, installs it on the phone attached
over adb and starts it. The second runs the suites on the phone: it builds each for Android,
pushes it with the engine's data and reads its results back. The third makes the Android export
template a game ships on (a Release build makes the profile one).

## Running the editor

```
Code/build/Debug_Linux64/Sedulous.Tools.Editor/Sedulous.Tools.Editor               # project manager
Code/build/Debug_Linux64/Sedulous.Tools.Editor/Sedulous.Tools.Editor <projectDir>  # open a project
```

Add `--mcp` to serve the project to an agent over MCP while you work in the editor.
`Sedulous.Tools.Mcp` serves MCP without the editor.

## The old editor and UI

The editor is on the GUI: its shell (the dock, menus, project manager, assets browser and
dialogs), the scene page, the Game tab, the asset pages and the Profiler page. The old editor on
Sedulous.UI is gone; it last builds at commit e293ee1f. The old UI framework and its UISandbox stay
under `Code/Deprecated/UI`, disabled in every build config.
