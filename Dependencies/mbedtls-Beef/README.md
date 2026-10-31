# mbedtls-Beef

Beef bindings for [Mbed TLS](https://github.com/Mbed-TLS/mbedtls) 4.2.0: TLS 1.2 and 1.3, X.509
certificates and the PSA crypto beneath them, for the engine's HTTP client and secure WebSockets.

- **License:** Apache-2.0 OR GPL-2.0-or-later, taken under Apache-2.0: see `mbedtls/LICENSE` and
  `mbedtls/tf-psa-crypto/LICENSE`. What is vendored, and how to update it, is
  `mbedtls/README.vendored.md`.

## Why there is a wrapper

Mbed TLS passes its contexts as structs whose layout follows its configuration (`mbedtls_config.h`,
`crypto_config.h`), which a hand-written Beef binding cannot track. `mbedtls-c/` keeps every Mbed
TLS type on the C side, behind plain arguments and opaque handles, and `src/MbedTls.bf` binds that.
The same arrangement as `bc7enc-Beef` and `msdfgen-Beef`. The surface grows with what the engine's
TLS backend needs.

`mbedtls-house/threading_alt.h` is this engine's, not upstream's: Mbed TLS's alternate threading
types on Windows, where there are no pthreads.

## Building the native library

```
./build-native.sh make RELEASE
./build-native.sh build RELEASE
./build-native.sh wasm
```

`build-native.ps1` is the Windows counterpart. Both drop one archive in `dist/`, which is what
`BeefProj.toml` points `LibPaths` at.

## Testing

`mbedtls-Beef-Test`, this folder's workspace startup project, starts the crypto, checks the version
and hashes FIPS 180-2's "abc" vector through PSA.
