/* SPDX-License-Identifier: MIT
 * Copyright (c) 2026-Present Robert Campbell
 *
 * The C surface Beef binds over Mbed TLS (src/MbedTls.bf). Mbed TLS's own API passes its
 * contexts by value-sized structs whose layout follows its configuration, which a hand-written
 * Beef binding cannot track; this keeps every Mbed TLS type on the C side, behind plain
 * arguments and opaque handles, and grows with what the engine's TLS backend needs.
 */
#ifndef SEDULOUS_MBEDTLS_C_H
#define SEDULOUS_MBEDTLS_C_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Starts the crypto library once, thread-safely: on Windows Mbed TLS's alternate threading
 * functions first (Win32's slim lock and condition variable), as it requires before any other
 * call, then psa_crypto_init. Every later call answers the first's result. 1 when started. */
int mbedtlsc_start(void);

/* The library's version, "4.2.0". */
const char* mbedtlsc_version(void);

/* SHA-256 of `length` bytes into `out` (32 bytes) through PSA. 1 when hashed; 0 when the crypto
 * library did not start or the hash failed. */
int mbedtlsc_sha256(const uint8_t* data, size_t length, uint8_t* out);

#ifdef __cplusplus
}
#endif

#endif
