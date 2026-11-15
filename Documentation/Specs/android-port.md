# Android: the player on phones and tablets

> Status: IN PROGRESS on the `android` branch, 2026-11-15. A1 and A2 are done: the RHI triangle
> drew on the Pixel 6, and Sky Hopper, exported content-only, plays from its APK (menu, touch
> controls, the level, music). The phases from A3 on are still the proposal.
> Scope: an Android build of the shipping PLAYER and an editor export that makes an APK. The
> editor, the cook and the tools stay desktop programs.

## Targets

- **arm64-v8a only**, Android 13 (API 33) and newer: API 33 is the first whose `libvulkan`
  exports the Vulkan 1.3 calls the RHI makes directly. No 32-bit ARM, no x86_64 emulator image.
- **Vulkan 1.3 required.** No GLES fallback; a device without it is refused by the manifest.
- **SDL3's Java activity** (`SDLActivity`) hosts the game, not `NativeActivity`: SDL brings the
  lifecycle, input, the surface and the Java glue, and the engine's shell is already SDL3.
- Tested on a Pixel 6 (Mali-G78, Android 16) over adb.

## What the spike proved (2026-11-15)

Working files outside the repos in `~/Dev/Beef/android-spike`.

1. **Beef's runtime builds for Android** with NDK r30 and CMake on Linux:
   `BeefRT/CMakeLists.txt` with the NDK's toolchain file, `ANDROID_ABI=arm64-v8a`,
   `ANDROID_PLATFORM=android-33`, Release. One fix was needed: the SIGPIPE handler in
   `BeefySysLib/platform/posix/PosixCommon.cpp` initialised `struct sigaction` positionally, and
   bionic orders its members differently from glibc (Beef fork branch `fix/android-posix`).
2. **BeefBuild compiles Beef for Android** with no project changes: `BeefBuild
   -platform=aarch64-linux-android33` (no vendor part: a "none" vendor made Beef read the platform
   as None, so `BF_PLATFORM_ANDROID` was not defined; Beef fork branch `fix/triple-none-vendor`) gives each project a static archive (`StaticLib`,
   PIC is forced), with `BeefMain`, `BeefStart` and `BeefStop` exported for a console
   application. BeefBuild cannot link an Android shared library itself; the NDK's clang does.
3. **A plain executable** (a C `main` calling `BeefMain`, linked with the Beef archives and
   `libBeefRT.a`) ran from `/data/local/tmp`: console output, four threads under a lock, file IO,
   collections and formatting all correct.
4. **An app**: `libmain.so` with SDL3 built static from source (3.4.10), a C `SDL_main` calling
   `BeefMain`, and a small Gradle project over SDL's Java glue. On the phone SDL's activity ran
   Beef's `Main`, which opened a 1080x2400 window and renderer through Sedulous's own SDL3
   bindings, wrote and read a file in the app's files folder, and received touches (31 in a 20 s
   run, injected ones at their exact positions). Paused for 14 minutes by the screen lock, it got
   its surface back on resume and exited cleanly.

   The link line that works (SDL whole, since its Java side finds its native functions by name):

   ```
   clang++ -shared -o libmain.so main.o
       -Wl,--whole-archive libSDL3.a -Wl,--no-whole-archive
       -Wl,--start-group <each Beef project's .a> corlib.a libBeefRT.a -Wl,--end-group
       -static-libstdc++ -landroid -llog -lm -ldl -lGLESv2 -lEGL -lOpenSLES -laaudio -pthread
       -Wl,--no-undefined
   ```

### Gaps the spike found in Beef's Android runtime

- `Runtime.FatalError` exits with code 1; its message, with the file and line, goes to logcat under
  the tag `Beef` (the Android runtime routes its error output there), followed by an unsymbolised
  backtrace.
- Beef's own crash catcher reports nothing on a SIGSEGV; Android's debuggerd writes the tombstone
  to logcat. The tombstone symbolises to Beef source lines with the NDK's `llvm-symbolizer
  --obj=<unstripped binary>` (`ndk-stack` found nothing for an executable outside an APK).
- `BfpSystem_GetNumLogicalCPUs` returns 1 on Android (a stub in `PosixCommon.cpp`): the job
  system would run on one worker.
- No backtrace support is configured for Android (`BFP_HAS_BACKTRACE` / `BFP_HAS_EXECINFO`), and
  the temp folder is fixed at `/data/local/tmp`.
- BeefBuild names the runtime libraries for Windows on an Android target
  (`IDE/src/BuildContext.bf`, `GetRtLibNames`); harmless while the link is ours, worth fixing
  upstream.

- An executable's devirtualisation thunks named struct types (a `Float2` return, say) that its
  vdata module had only declared; AArch64 returns such a two-float struct as itself, and LLVM
  refused the module ("Instruction returns a non-scalar type"). Every library built; the player
  did not. Fixed on the Beef fork branch `fix/devirt-thunk-struct-types`: building the player
  needs a BeefBuild with it until it is upstream.

Beef defines one platform macro per target: an Android build has `BF_PLATFORM_ANDROID` and NOT
`BF_PLATFORM_LINUX`, so every `#elif BF_PLATFORM_LINUX` branch misses Android while every
`#else` (the engine's usual Windows-or-not split) takes it.

## Already in Sedulous

Ports of the parts of Android support that are not Android-only:

- **Swapchain**: pre-rotation from the surface's `currentTransform`, recreated on a change
  (`Foundation/Sedulous.RHI.Vulkan/src/VulkanSwapChain.bf:131,266`), sRGB on RGBA-only surfaces.
- **Lifecycle**: background and foreground through an SDL event watch
  (`Foundation/Sedulous.Shell.SDL3/src/SDL3Shell.bf:45`), as Android needs (the spike's plain
  `SDL_PollEvent` loop never saw the background event); the window's safe area.
- **Data inside the APK**: `PlayerMounts` lets a host hand the player its Game, Content and Data
  file systems (`Engine/Sedulous.Engine.Player/src/PlayerMounts.bf`); `Sedulous.VFS.Zip` reads
  the APK in place, and `PakFileSystem` reads a pak stored in it through `FileRegionStream`
  (`Foundation/Sedulous.VFS.Pak/src/PakFileSystem.bf:85`).
- **Content**: the `android` cook target is ASTC
  (`Pipeline/Sedulous.Pipeline.Core/src/CookTarget.bf:48`), and the export treats a platform
  starting with "Android" as one ASTC pak (`Editor/Sedulous.Editor.Project/src/ExportDriver.bf:199`),
  with a content-only mode that stages the paks, `player.xml` and the shader pack without a
  player. Shaders ship as SPIR-V.
- **TLS**: the system's roots from Android's certificate folders
  (`Foundation/Sedulous.Net.Tls/src/TlsSystemRoots.bf`).

## What the port needs

### Engine code

- **Vulkan surface**: `VulkanBackend.bf` knows Win32 and Xlib/Wayland and otherwise logs that
  window surfaces are unsupported (`:83`, `:122`, `:228`). Add `VK_KHR_android_surface`
  (`vkCreateAndroidSurfaceKHR`, which Bulkan declares) and the `ANativeWindow` from SDL
  (`SDL_PROP_WINDOW_ANDROID_WINDOW_POINTER`) in `Shell.SDL3/src/SDL3Window.bf:156-180`.
- **Vulkan loader**: `Dependencies/Bulkan/src/VulkanNative.bf:182-189` names no library on
  Android and calls `Runtime.FatalError`; Android's is `libvulkan.so`. `NativeLibrary.bf:90`
  (dlopen) is `BF_PLATFORM_LINUX || BF_PLATFORM_MACOS` and needs Android too.
- **WebGPU out of the build**: `Sedulous.Graphics.Gpu` always takes `Sedulous.RHI.WebGPU`, and
  wgpu-native has no Android library; compile the backend out on Android as DX12 is off Windows.
- **Paths**: `SystemPaths.bf:82-95` falls back to `XDG_DATA_HOME` and `HOME`, which an app does
  not have: on Android the user data folder is the one the activity passes (`getFilesDir()`),
  as the spike did. The temp folder likewise (`getCacheDir()`).
- **Platform tag**: `PluginHost.bf:137` and `ApplicationHost.bf:219` fall through to "Linux64";
  Android needs its own tag ("Android64"), which `BuildLayout.bf:108` and plugin manifests then
  accept.
- **The host**: an `Sedulous.Engine.Player.Android` library beside DesktopMain: its `SDL_main`
  reads the activity's arguments (the APK path, the files and cache folders), mounts the game
  and the engine data from the APK through `PlayerMounts`, and runs the player.

### Native libraries

Every library the player links needs an arm64 Android archive: AngelScript (its arm64
trampoline), joltc, miniaudio (AAudio), HarfBuzz, SheenBidi, Mbed TLS, stb_image, stb_truetype,
bcdec, recastnavigation, cimgui, and SDL3 itself (static, from source, with its Java glue
vendored beside it). They build from source with CMake already; each `build-native.sh` gains an
`android` mode (the NDK's toolchain file, `ANDROID_ABI=arm64-v8a`, `ANDROID_PLATFORM=android-33`,
into `dist/Release-Android64`), and `Dependencies/build-all-native.sh android` builds them all.
Each BeefProj names its archive under a `[Configs.*.<android platform>]` section only where
that helps; the link is ours, so the host's link step can list them.

The cook-only libraries (astcenc, bc7enc, cgltf, ufbx, meshoptimizer, msdfgen, DXC) are not
needed on the device. zlib is: the player reads the APK through `Sedulous.VFS.Zip`.

### Beef runtime

- The SIGPIPE fix upstream, and the runtime's arm64 Android build in a script (the only one in
  the Beef repo is a Windows batch file for NDK 20).
- The CPU count from `sysconf(_SC_NPROCESSORS_ONLN)`.
- Crash reports: either Beef's crash catcher made to print on Android, or rely on the tombstone
  plus symbolising (the export keeps the unstripped `libmain.so` for that).

### Build and export

- **The link**: BeefBuild builds the Beef archives for `aarch64-linux-android33`; a script
  (later the export) links `libmain.so` with the NDK's clang as above.
- **The app**: a Gradle project like the spike's (SDL's Java glue, one activity, `minSdk 33`,
  `abiFilters 'arm64-v8a'`), the paks and `player.xml` in `assets/`, stored uncompressed
  (`noCompress`) so they are read in place.
- **Export**: an Android preset builds the player's archives, links `libmain.so`, stages the
  content-only export into the app's assets and runs Gradle, giving an APK (debug key) or a
  signed APK/AAB (a release keystore whose password is asked for or read from the environment,
  never stored). The editor's Preferences name the SDK and JDK folders, else `ANDROID_HOME` and
  `JAVA_HOME`.

## Phases

Each phase ends with something running on the phone.

- **A0 Toolchain**: the Beef fixes (SIGPIPE, CPU count) on the fork; the runtime's
  Android build scripted; `build-native.sh android` for the player's libraries; a test runner that
  pushes a few headless test suites (Core, Scene, Messaging) to the phone and runs them.
- **A1 A triangle** (done): the Vulkan Android surface and loader, WebGPU compiled out; a sample that
  clears and draws a triangle in the spike's app.
- **A2 The player** (done): `Sedulous.Engine.Player.Android`, the paths, the platform tag; Sky
  Hopper exported content-only and played from the APK. `Code/Tools/android-app.sh <export-dir>
  --run` builds, links, packages, installs and starts it. The device found one engine bug:
  Android tags heap addresses in their top byte, and streamed audio named a clip by its address
  read back as a signed number, so music never started.
- **A3 Lifecycle**: background and foreground with the surface released and made again, audio
  stopped and started, the save written on the way out, Back to the platform when nothing takes
  it.
- **A4 Export**: the editor's Android preset making an installable APK, signing, the SDK and JDK
  settings.
- **A5 Rotation and measurements**: pre-rotation checked on the device, frame times of the
  samples, the known differences (`Shipping/KnownIssues.md`).

## Open questions

- Whether games with their own native plugins can ship on Android at first, or are refused by the
  export until their packages build for it.
- How the tests run on the device beyond a handful of headless suites (no emulator; arm64 only).
- Whether the IBL and other startup work need the cheaper paths a phone's GPU wants, which only
  measurement on the device will tell.
