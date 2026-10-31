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

/* Mbed TLS's words for an error code ("SSL - ..."), NUL-terminated into `out`. */
void mbedtlsc_strerror(int code, char* out, size_t size);

/* ---- sessions: one connection's TLS over in-memory buffers (a memory BIO) -------------------
 *
 * A session never touches a socket: bytes from the peer go in (mbedtlsc_session_receive), bytes
 * for the peer come out (mbedtlsc_session_take_outgoing), and plaintext is read and written. A
 * negative return is Mbed TLS's error code (mbedtlsc_strerror says it). */
typedef struct mbedtlsc_session mbedtlsc_session;

/* What mbedtlsc_session_handshake answers besides an error code. */
#define MBEDTLSC_HANDSHAKE_DONE 0
#define MBEDTLSC_HANDSHAKE_WANTS 1   /* more bytes from the peer, or bytes to send first */
#define MBEDTLSC_HANDSHAKE_REFUSED 2 /* the peer's certificate failed its checks (verify_info says why) */

/* What mbedtlsc_session_read leaves in `outCode` when it reads nothing. */
#define MBEDTLSC_READ_NONE 0   /* nothing ready yet */
#define MBEDTLSC_READ_CLOSED 1 /* the peer closed (close_notify) */

/* A session's configuration: `server` 0 for a client, 1 for a server; versions 2 (TLS 1.2) or 3
 * (TLS 1.3); `alpn` the protocols offered or accepted, in preference order (the names are
 * copied). Null only when out of memory; a configuration that failed leaves `outCode` nonzero:
 * an error code, or MBEDTLSC_NOT_STARTED (positive, as no Mbed TLS error is) when the crypto did
 * not start. */
#define MBEDTLSC_NOT_STARTED 1
mbedtlsc_session* mbedtlsc_session_create(int server, int minimum, int maximum, const char* const* alpn, int alpnCount,
                                          int* outCode);
void mbedtlsc_session_destroy(mbedtlsc_session* session);

/* A client's trust. Roots from a PEM bundle (a certificate this build cannot read is skipped; the
 * rest count) and from DER; how many roots the session holds; then the check: `verify` 0 checks
 * nothing (tests only), 1 requires the chain to reach the roots. */
void mbedtlsc_session_add_roots_pem(mbedtlsc_session* session, const uint8_t* pem, size_t length);
void mbedtlsc_session_add_root_der(mbedtlsc_session* session, const uint8_t* der, size_t length);
int mbedtlsc_session_root_count(mbedtlsc_session* session);
void mbedtlsc_session_verify(mbedtlsc_session* session, int verify);

/* A server's certificate chain (its own first) and private key, both PEM. 0, or an error code
 * with `outStage` 0 (the chain), 1 (the key) or 2 (the pair refused). */
int mbedtlsc_session_own_certificate(mbedtlsc_session* session, const uint8_t* chainPem, size_t chainLength,
                                     const uint8_t* keyPem, size_t keyLength, int* outStage);

/* Ends the configuration and wires the buffers. 0 or an error code. */
int mbedtlsc_session_setup(mbedtlsc_session* session);
/* The name a client asks for (SNI) and checks the certificate is for. 0 or an error code. */
int mbedtlsc_session_set_hostname(mbedtlsc_session* session, const char* name);

void mbedtlsc_session_receive(mbedtlsc_session* session, const uint8_t* bytes, size_t length);
/* How many bytes wait for the peer, and up to `capacity` of them taken into `out`. */
size_t mbedtlsc_session_outgoing(mbedtlsc_session* session);
size_t mbedtlsc_session_take_outgoing(mbedtlsc_session* session, uint8_t* out, size_t capacity);

/* The handshake as far as the bytes so far take it: MBEDTLSC_HANDSHAKE_*, or an error code. */
int mbedtlsc_session_handshake(mbedtlsc_session* session);
/* Why the peer's certificate was refused, one reason a line, NUL-terminated into `out`. */
void mbedtlsc_session_verify_info(mbedtlsc_session* session, char* out, size_t size);

/* Up to `capacity` decrypted bytes (TLS 1.3's after-handshake tickets read past). 0 with
 * `outCode` MBEDTLSC_READ_* or an error code. */
int mbedtlsc_session_read(mbedtlsc_session* session, uint8_t* out, size_t capacity, int* outCode);
/* All of `length` bytes encrypted into the outgoing bytes. 0 or an error code. */
int mbedtlsc_session_write(mbedtlsc_session* session, const uint8_t* bytes, size_t length);
/* Tells the peer the connection ends. 0 or an error code. */
int mbedtlsc_session_close_notify(mbedtlsc_session* session);

/* The protocol ALPN agreed on, or null. */
const char* mbedtlsc_session_alpn(mbedtlsc_session* session);
/* The version agreed on: 3 for TLS 1.3, 2 for TLS 1.2. */
int mbedtlsc_session_version(mbedtlsc_session* session);

/* ---- certificates ------------------------------------------------------------------------- */

/* A self-signed certificate for `name` (its subject's CN and its one DNS name), valid from
 * `notBefore` to `notAfter` (UTC, "YYYYMMDDhhmmss"), with a new P-256 key (ECDSA, SHA-256): the
 * certificate and the key as PEM, NUL-terminated. 0, or nonzero (an error code, or
 * MBEDTLSC_NOT_STARTED) with `outStage` saying where: 0 the crypto did not start, 1 the key was
 * not made, 2 it was not copied, 3 the certificate was not written, 4 the key was not written. */
int mbedtlsc_self_signed_certificate(const char* name, const char* notBefore, const char* notAfter, char* certificatePem,
                                     size_t certificateSize, char* keyPem, size_t keySize, int* outStage);

#ifdef __cplusplus
}
#endif

#endif
