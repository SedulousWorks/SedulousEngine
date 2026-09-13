# astcenc (vendored)

ARM's [astc-encoder](https://github.com/ARM-software/astc-encoder) - the reference ASTC
compressor/decompressor. Used cook-side (Pipeline::Texture.Compression) to produce ASTC textures for
the mobile-web target (asset-variants.md, Decision 4). Apache-2.0 (see `LICENSE.txt`).

Upstream: git commit `4316299` (2026-08-15 snapshot).

## What was vendored

Only the encoder/decoder CORE - the 22 `astcenc_*.cpp` compilation units plus their headers
(`astcenc.h` is the public API). Excluded: the whole `astcenccli_*` command-line front end, its
image load/store (stb/tinyexr), the test/benchmark/fuzz harnesses, docs, and build scripts.

## Build config (portable scalar path)

We force the scalar "none" ISA path (`ASTCENC_SSE/AVX/POPCNT/F16C/NEON/SVE = 0`) so the one static
lib builds identically on desktop x86, and compiles for wasm, without per-arch source selection. This
is a cook-time encoder - encode speed is not on any runtime hot path - so the scalar path is the right
trade for portability. If desktop cook throughput ever matters, add an SSE/AVX variant behind an
option; nothing in our code depends on the ISA choice.
