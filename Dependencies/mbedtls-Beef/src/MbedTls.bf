using System;

namespace mbedtls_Beef;

/*
 * Mbed TLS - TLS 1.2 and 1.3, X.509 certificates, and the PSA crypto beneath them.
 *
 * Source: https://github.com/Mbed-TLS/mbedtls (release mbedtls-4.2.0)
 * License: Apache-2.0 OR GPL-2.0-or-later, taken under Apache-2.0 (see mbedtls/LICENSE and
 * mbedtls/tf-psa-crypto/LICENSE).
 *
 * Mbed TLS passes its contexts as structs whose layout follows its configuration, which a hand
 * written binding cannot track, so mbedtls-c/ keeps every Mbed TLS type on the C side behind
 * plain arguments and opaque handles, and this binds that. The same arrangement as bc7enc-Beef
 * and msdfgen-Beef. The surface grows with what the engine's TLS backend needs.
 */

static
{
	/// Starts the crypto library once, thread-safely (on Windows the alternate threading
	/// functions first, as Mbed TLS requires). Every later call answers the first's result.
	/// Nonzero when started.
	[CLink] public static extern int32 mbedtlsc_start();

	/// The library's version, "4.2.0". Static storage.
	[CLink] public static extern char8* mbedtlsc_version();

	/// SHA-256 of `length` bytes into `out` (32 bytes) through PSA. Nonzero when hashed.
	[CLink] public static extern int32 mbedtlsc_sha256(uint8* data, uint length, uint8* @out);

	/// Mbed TLS's words for an error code, NUL-terminated into `out`.
	[CLink] public static extern void mbedtlsc_strerror(int32 code, char8* @out, uint size);

	// ---- sessions: one connection's TLS over in-memory buffers ---------------------------------

	/// mbedtlsc_session_handshake's answers besides an error code (negative).
	public const int32 MBEDTLSC_HANDSHAKE_DONE = 0;
	public const int32 MBEDTLSC_HANDSHAKE_WANTS = 1;
	public const int32 MBEDTLSC_HANDSHAKE_REFUSED = 2;
	/// What mbedtlsc_session_read leaves in its code when it reads nothing.
	public const int32 MBEDTLSC_READ_NONE = 0;
	public const int32 MBEDTLSC_READ_CLOSED = 1;
	/// The crypto library did not start (positive, as no Mbed TLS error is).
	public const int32 MBEDTLSC_NOT_STARTED = 1;

	/// Server 0 for a client, 1 for a server; versions 2 (TLS 1.2) or 3 (TLS 1.3). Null only out of
	/// memory; a configuration that failed leaves `outCode` nonzero.
	[CLink] public static extern void* mbedtlsc_session_create(int32 server, int32 minimum, int32 maximum, char8** alpn,
		int32 alpnCount, int32* outCode);
	[CLink] public static extern void mbedtlsc_session_destroy(void* session);
	[CLink] public static extern void mbedtlsc_session_add_roots_pem(void* session, uint8* pem, uint length);
	[CLink] public static extern void mbedtlsc_session_add_root_der(void* session, uint8* der, uint length);
	[CLink] public static extern int32 mbedtlsc_session_root_count(void* session);
	/// Verify 0 checks nothing (tests only), 1 requires the chain to reach the roots.
	[CLink] public static extern void mbedtlsc_session_verify(void* session, int32 verify);
	/// 0, or an error code with `outStage` 0 (the chain), 1 (the key) or 2 (the pair refused).
	[CLink] public static extern int32 mbedtlsc_session_own_certificate(void* session, uint8* chainPem, uint chainLength,
		uint8* keyPem, uint keyLength, int32* outStage);
	[CLink] public static extern int32 mbedtlsc_session_setup(void* session);
	[CLink] public static extern int32 mbedtlsc_session_set_hostname(void* session, char8* name);
	[CLink] public static extern void mbedtlsc_session_receive(void* session, uint8* bytes, uint length);
	[CLink] public static extern uint mbedtlsc_session_outgoing(void* session);
	[CLink] public static extern uint mbedtlsc_session_take_outgoing(void* session, uint8* @out, uint capacity);
	[CLink] public static extern int32 mbedtlsc_session_handshake(void* session);
	[CLink] public static extern void mbedtlsc_session_verify_info(void* session, char8* @out, uint size);
	/// Bytes read, or 0 with `outCode` MBEDTLSC_READ_* or an error code.
	[CLink] public static extern int32 mbedtlsc_session_read(void* session, uint8* @out, uint capacity, int32* outCode);
	[CLink] public static extern int32 mbedtlsc_session_write(void* session, uint8* bytes, uint length);
	[CLink] public static extern int32 mbedtlsc_session_close_notify(void* session);
	/// Null when ALPN agreed on none.
	[CLink] public static extern char8* mbedtlsc_session_alpn(void* session);
	/// 3 for TLS 1.3, 2 for TLS 1.2.
	[CLink] public static extern int32 mbedtlsc_session_version(void* session);

	// ---- certificates -----------------------------------------------------------------------------

	/// A self-signed certificate for `name`, valid from `notBefore` to `notAfter` (UTC,
	/// "YYYYMMDDhhmmss"), with a new P-256 key: both PEM, NUL-terminated. 0, or nonzero with
	/// `outStage` saying where (0 start, 1 key made, 2 key copied, 3 certificate, 4 key written).
	[CLink] public static extern int32 mbedtlsc_self_signed_certificate(char8* name, char8* notBefore, char8* notAfter,
		char8* certificatePem, uint certificateSize, char8* keyPem, uint keySize, int32* outStage);
}
