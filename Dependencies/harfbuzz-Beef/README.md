# harfbuzz-Beef

Beef bindings for [HarfBuzz](https://github.com/harfbuzz/harfbuzz), the OpenType text shaper.

- **Version:** 14.5.1 (2026-09-30), harfbuzz-14.5.1.tar.xz,
  sha256 7e2fa4e8c7c98e8d8140671f5772542afaaa6acccfbd746506886b6d85f7f8d6
- **License:** the "Old MIT" license (`harfbuzz/COPYING`). The Universal Shaping Engine tables
  are generated in part from Microsoft data under the MIT license (`harfbuzz/src/ms-use/COPYING`).

HarfBuzz is a C API already, so `src/HarfBuzz.bf` binds it directly with no wrapper in between.
It is used only behind the engine's own `ITextShaper`; no HarfBuzz type crosses that interface.

## Trimmed vendoring

`harfbuzz/` carries the library's own amalgamation, `src/harfbuzz.cc`, the sources it includes,
every public and internal header, and `src/OT/`. Left out: the subsetter (`harfbuzz-subset.cc`,
`graph/`, `hb-subset*.cc`), the raster, vector, GPU, Cairo and world builds, the Rust and wasm
shapers, the generator scripts, the ragel inputs and the Unicode data text files (their
generated tables are kept), tests, fuzzers, docs and the util front ends.

It is built with no FreeType, glib, ICU, Graphite or platform shaper: its built-in Unicode data
and OpenType shaping.

The binding declares only what the engine's shaper calls. Every function it declares is defined
in the archive; check again after adding one:

```
nm --defined-only -g dist/Release-Linux64/libharfbuzz.a | awk '$2=="T"{print $3}' | grep '^hb_'
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

`harfbuzz-Beef-Test` shapes "office" in Roboto (five glyphs, the fi ligature one glyph over a
two-character cluster), closes the GSUB substitutions over f and i to reach that ligature, and
reads the direction of Arabic. Run it from its own folder, so it finds Roboto in the repository's
`Data/`.
