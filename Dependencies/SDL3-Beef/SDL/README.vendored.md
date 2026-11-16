# SDL3 - vendored source

- Upstream: https://github.com/libsdl-org/SDL
- Version: release-3.4.10 (see include/SDL3/SDL_version.h)
- License: zlib (LICENSE.txt, preserved verbatim, as the license requires)

Built from source for Android alone, where no SDL comes with the system: `../build-native.sh
android` builds it static (`libSDL3.a`, into `../dist/Release-Android64`), and the Android player
links it whole into its `libmain.so`, since SDL's Java side finds its native functions by name.
The Android app's Gradle project compiles the Java glue below beside its own activity.

Windows links the prebuilt SDL in `../dist/SDL3-3.4.0`, and Linux the system's SDL3; both are
3.4 releases, which keep one binary interface, so the bindings in `../src` serve every one.

## Prune set (what was removed from the upstream release)

Kept: `src/ include/ cmake/ build-scripts/ wayland-protocols/ CMakeLists.txt LICENSE.txt
INSTALL.md WhatsNew.txt`, and from `android-project/` only its Java glue,
`android-project/app/src/main/java/org/libsdl/app/*.java` (SDLActivity and the classes it uses).
Removed: tests, examples, docs, IDE project files (VisualC, Xcode), and the rest of
`android-project/` (its Gradle files, manifest and resources: the engine's Android app has its
own). A new version takes the same prune, so its diff stays reviewable.

## Local changes

- `src/core/android/SDL_android.c`, `onNativeSurfaceDestroyed`: clears the window's
  `SDL_PROP_WINDOW_ANDROID_WINDOW_POINTER` when it releases the native window. Upstream leaves the
  property naming the released window until the next surface arrives, so a Vulkan surface made in
  between (the window going fullscreen as it opens, or a return from the background) crashed in
  `vkCreateAndroidSurfaceKHR`. Each change is marked `Sedulous:` in the source; a new version
  takes them again.
