# bcdec-Beef

Beef bindings for [bcdec](https://github.com/iOrange/bcdec), a single header BCn **decoder**.

- **License:** MIT or Unlicense, the caller's choice (`bcdec/LICENSE`)

## Why there is no wrapper

bcdec's declarations are already plain C. It is header only, so `bcdec-c/` is the one
translation unit that defines `BCDEC_IMPLEMENTATION`, and `src/Bcdec.bf` binds the header
as it stands.

## Why a second decoder

`bc7enc-Beef` already decodes BC1 through BC7, but it has no BC6H at all, in either
direction. bcdec does, and it is the independent reference the engine's own BC6H encoder is
measured against. That is worth more than a decoder written alongside the encoder: a shared
misreading of the format would pass a self check and then fail on a GPU.

## Building the native library

```
./build-native.sh make RELEASE
./build-native.sh build RELEASE
```

`build-native.ps1` is the Windows counterpart. Both drop one archive in `dist/`, which is what
`BeefProj.toml` points `LibPaths` at.
