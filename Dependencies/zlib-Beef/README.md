# zlib-Beef

Beef bindings for [zlib](https://zlib.net) 1.3.2: deflate and inflate, for the engine's zip reader
(`Sedulous.Zip`) and content compression later.

- **License:** zlib: see `zlib/LICENSE`. What is vendored (release 1.3.2, the archive's SHA-256
  `bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16`), and how to update it, is
  `zlib/README.vendored.md`.

## No wrapper

zlib's interface is plain C, and its stream's layout is its ABI rather than a configuration, so
`src/Zlib.bf` binds it directly (unlike `mbedtls-Beef`). It is built with `Z_PREFIX`: every symbol
is `z_`-prefixed. The surface grows with what the engine needs.

## Building the native library

```
./build-native.sh make RELEASE
./build-native.sh build RELEASE
./build-native.sh wasm
```

Each drops `libzlib-c.a` in `dist/`, which is what `BeefProj.toml` points `LibPaths` at. The
Windows counterpart (`build-native.ps1`) and its libraries are owed.
