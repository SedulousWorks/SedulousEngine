# naga-cli - vendored cook-time WGSL translator

naga-cli translates SPIR-V -> WGSL in the **web cook** (see docs/design/shaders.md P3). It is
the version-matched translator for our runtime: we ship **wgpu-native v29.0.1.1**, which bundles
**naga 29.0.x** - the exact WGSL validator our native WebGPU backend links - so naga-cli pinned
to the 29.0 line emits WGSL guaranteed to round-trip through our own runtime.

## Why it is vendored (nobody installs Rust)

This is a **cook-time-only** tool, shelled out to when cooking for the web target - exactly like
DXC (`ThirdParty/DXC`), wgpu-native (`ThirdParty/WgpuNative`), and tint (`ThirdParty/Tint`).

- **Players never touch it.** Dists ship cooked WGSL; the translator does not.
- **Developers never install Rust.** We ship the prebuilt binary here. Rust was used ONCE to
  produce each binary and the result is checked in. The Linux binary is a STATIC musl build
  (static-pie, zero runtime library deps - it runs on any distro/glibc, incl. CI containers);
  the Windows binary links the system CRT normally.

## Current binaries

- `bin/linux-x86_64/naga` - naga-cli 29.0.4, stripped, ELF x86-64, static-pie (musl).
  `VERSION` = 29.0.4. Rebuild recipe:
  `rustup target add x86_64-unknown-linux-musl` then
  `cargo install naga-cli --version 29.0.4 --locked --target x86_64-unknown-linux-musl`
  (needs the musl toolchain, e.g. apt `musl-tools`).
- `bin/win-x64/naga.exe`  - naga-cli 29.0.4, PE x86-64. Built with
  `cargo install naga-cli --version 29.0.4 --locked` (needs rustc >= 1.82; the `bit-set`
  dependency enforces that floor). `naga.exe --version` prints `29.0.4`.

## TODO: other host platforms

`bin/mac-arm64/naga` is still missing - build it with the same
`cargo install naga-cli --version 29.0.4 --locked` on that host and drop the binary here.
Keep the pin at the 29.0 line to stay matched to wgpu-native v29's naga.
