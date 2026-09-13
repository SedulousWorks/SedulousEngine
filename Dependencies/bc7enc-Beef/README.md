# bc7enc-Beef

Beef bindings for [bc7enc_rdo](https://github.com/richgel999/bc7enc_rdo), the fast BC1 to BC7
texture encoders.

- **License:** see `bc7enc/LICENSE`. Attribution is requested but not required.

## Why there is a wrapper

`bc7enc.h` declares C functions, but the parameters it takes are a struct with member
functions on it; `rgbcx` and `bc7decomp` are C++ namespaces whose entry points have defaulted
arguments. None of that crosses a C ABI. `bc7enc-c/` re-declares the surface a texture cook
needs with plain arguments and no defaults, and `src/Bc7Enc.bf` binds that. The same
arrangement as `msdfgen-Beef` and `recastnavigation-Beef`.

## Scope

**The encoder and decoder core only.** Vendored: `bc7enc.cpp` (BC7), `rgbcx.cpp` (BC1, BC3,
BC4, BC5, and the decoders), `bc7decomp.cpp` (BC7 decode, which is what a round trip quality
test measures against).

Not vendored: the ISPC encoder and its committed `ispc.exe`, the rate distortion optimisation
pass, the command line tool, lodepng, and the test corpus. Encoding runs at cook time and
never at frame time, so the scalar path is the whole story; the RDO pass trades quality for
LZ compressibility of the cooked bytes, which is a packaging decision this engine has not
made yet.

BC6H is NOT here. Upstream has no BC6H encoder, which is why the engine writes its own.

## Building the native library

```
./build-native.sh make RELEASE
./build-native.sh build RELEASE
```

`build-native.ps1` is the Windows counterpart. Both drop one archive in `dist/`, which is
what `BeefProj.toml` points `LibPaths` at.
