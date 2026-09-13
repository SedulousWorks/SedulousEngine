# astcenc-Beef

Beef bindings for [astc-encoder](https://github.com/ARM-software/astc-encoder), ARM's ASTC
texture encoder and decoder.

- **License:** Apache 2.0 (`astcenc/LICENSE.txt`)

## Why there is no wrapper

Unlike the other bindings here, astcenc already ships an `extern "C"` surface with plain
structs, so `src/Astcenc.bf` binds it directly. The struct layouts there mirror `astcenc.h`
field for field and in order; a version bump that reorders one has to be mirrored.

## Scope

**The `astcenc_*.cpp` core.** No command line front end, no test or benchmark harness.

The build is forced onto the scalar "none" ISA path (`ASTCENC_SSE=0` and friends), so ONE
archive serves every architecture with no per-arch source selection. That costs encode time
a cook can afford and is never on a frame time path.

## Building the native library

```
./build-native.sh make RELEASE
./build-native.sh build RELEASE
```

`build-native.ps1` is the Windows counterpart. Both drop one archive in `dist/`, which is what
`BeefProj.toml` points `LibPaths` at.
