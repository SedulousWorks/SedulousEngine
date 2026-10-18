# sheenbidi-Beef

Beef bindings for [SheenBidi](https://github.com/Tehreer/SheenBidi), the Unicode bidirectional
algorithm.

- **Version:** v3.0.0 (2026-01-24), the v3.0.0 tag archive,
  sha256 86c56014034739ba39a24c23eb00323b0bf6f737354f665786015fca842af786
- **License:** Apache-2.0 (`sheenbidi/LICENSE`). The project ships no NOTICE file.

SheenBidi is a C API, so `src/SheenBidi.bf` binds it directly with no wrapper in between. It is
used only behind the engine's own bidi interface; no SheenBidi type crosses it.

## Trimmed vendoring

`sheenbidi/` carries `Headers/` and `Source/` as released: the library and its Unicode data
tables, built as C from its own unity source (`Source/SheenBidi.c` with `SB_CONFIG_UNITY`). Left
out: the tests, the tools that generate the tables, and the build files (meson, make, CMake,
pkg-config).

The binding declares only what the engine's bidi resolver calls. Every function it declares is
defined in the archive; check again after adding one:

```
nm --defined-only -g dist/Release-Linux64/libsheenbidi.a | awk '$2=="T"{print $3}' | grep '^SB'
```

## Building the native library

```
./build-native.sh make RELEASE      # configure
./build-native.sh build RELEASE     # build + copy into dist/Release-Linux64
./build-native.sh wasm              # dist/Release-wasm32, with the emsdk's emsdk_env.sh sourced
```

Windows: `build-native.ps1 make` then `build-native.ps1 build ALL`, which fills
`dist/Debug-Win64` and `dist/Release-Win64`.

## Test

`sheenbidi-Beef-Test` resolves "abc" followed by three Arabic letters to a left-to-right
paragraph whose Arabic sits at level 1, and a paragraph of a digit, defaulting right to left, to
level 1.
