# zlib - vendored

Source: https://github.com/madler/zlib (https://zlib.net)
Pinned release: **1.3.2** (release `v1.3.2`, the archive `zlib-1.3.2.tar.gz`, SHA-256
`bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16`, the same as zlib.net lists).
License: zlib (see `LICENSE`).

For deflate: `Sedulous.Zip` inflates a zip archive's entries with it (the sample downloads), and
it is there for content compression later. Vendored BY COPY (no submodule), from Raptor's
ThirdParty/zlib, which took it from the release archive. Only the library is taken: the deflate and
inflate sources and their headers, `gzguts.h` (which `zutil.c` includes), `LICENSE` and `README`.
Not vendored: the gzip file functions (`gz*.c`), the build files, `contrib/`, `examples/`, `test/`,
`doc/`, the platform folders (`amiga/`, `msdos/`, `os400/`, `qnx/`, `watcom/`, `win32/`) and the
man page.

## Configuration

Upstream's `zconf.h`, unedited. `zlib-c/CMakeLists.txt` defines `Z_PREFIX`, so the symbols are
`z_inflate` and so on (which `src/Zlib.bf` binds): a shared library loaded beside the engine (the
shader compiler, a browser's runtime) that carries a zlib of its own cannot be confused with this
one.

## Updating

Download the release archive, check its SHA-256 against zlib.net, and copy the files listed above
over these. Keep this note's version and hash current, and rebuild `dist/` (`build-native.sh`).
