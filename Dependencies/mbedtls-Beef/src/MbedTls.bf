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
}
