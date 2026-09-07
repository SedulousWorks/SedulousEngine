# Tint (Dawn WGSL tooling) - vendored, VERSION PROVISIONAL

Tint is used as the **cook-time WGSL conformance validator** (Chrome/Dawn is the strict
frontend; see docs/design/shaders.md P3). naga-cli is the translator; tint is the oracle we
run over naga's WGSL output to fail the web cook on anything Chrome would reject.

## Current binaries (PROVISIONAL)

These were copied from a local FlaxEngine checkout to unblock the P3 spike. They are
**stripped and carry no version** (`tint --version` is unsupported on this build):

- `bin/linux-x86_64/tint`  - ELF x86-64, BuildID sha1 42477a9cbbe766cf2455a0ea238bee180b936bcb
- `bin/mac-arm64/tint`     - Mach-O arm64

Source: `FlaxEngine/Source/Platforms/Web/Binaries/Tools/{Linux/x64,Mac/ARM64}/tint`.

## Windows: built from Dawn via vcpkg

- `bin/win-x64/tint.exe` - built from the vcpkg `dawn` port, version `20260219.200501`:

```
vcpkg install "dawn[core,tint]:x64-windows-static"
# -> installed/x64-windows-static/tools/dawn/tint.exe
```

The `tint` feature maps to `TINT_BUILD_CMD_TOOLS`, and the port sets `TINT_BUILD_WGSL_READER=ON`
(which is the part that matters to us). `[core]` selects no graphics backends, so the build skips
DXC and the backend stack. The static triplet yields a standalone exe with no DLL dependencies -
suitable for checking in, like the Linux binary. Verified round-tripping valid WGSL and rejecting
invalid WGSL with a diagnostic and a non-zero exit.

**Any replacement binary must have the WGSL reader enabled.** We use tint as a *reader*,
parsing naga's WGSL output to validate it; a build configured only as a one-way WGSL *writer*
reports

```
Tint not built with the WGSL reader enabled
```

and fails every WGSL cook at the Validate stage instead of passing it. Check with
`tint --format wgsl <some.wgsl>` before trusting a new binary. The Linux/mac binaries above
predate this check and should be re-verified, ideally replaced by the same vcpkg build.

## TODO: replace with a pinned build

Build tint from Dawn at a known revision and record it here, so the conformance oracle has a
reproducible version invariant (as wgpu-native v29.0.1.1 / naga 29.0.x is for the translator).
Dawn ships a standalone CMake build; the `tint_cmd` target is the executable. No Google
prebuilt tint distribution exists - from source is the only authoritative path.

The uniformity rule tint enforces (the one that surfaced forward.ps / taa.ps in the spike) is
WGSL-spec-stable across tint versions, so even this provisional binary is a valid oracle for
that class of error; a pinned build is about reproducibility, not correctness of this finding.
