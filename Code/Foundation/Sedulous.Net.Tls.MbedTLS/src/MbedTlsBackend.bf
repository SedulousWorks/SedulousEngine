using System;
using Sedulous.Core;
using mbedtls_Beef;

namespace Sedulous.Net.Tls.MbedTLS;

#if !BF_PLATFORM_WASM
/// The Mbed TLS backend of the TLS seam: TLS 1.2 and 1.3, the client checking the server's name
/// and chain against its trust, the server presenting its chain. The only project that links
/// mbedtls-Beef. Desktop and the Deck compose it; a web build has none (the browser does TLS).
class MbedTlsBackend : ITlsBackend
{
	public this()
	{
		mbedtlsc_start();
	}

	public StringView Name => "Mbed TLS";

	public ITlsSession CreateClient(TlsClientConfig config)
	{
		let session = new MbedTlsSession();
		session.SetUpClient(config);
		return session;
	}

	public ITlsSession CreateServer(TlsServerConfig config)
	{
		let session = new MbedTlsSession();
		session.SetUpServer(config);
		return session;
	}
}

/// A self-signed certificate (a P-256 key, ECDSA with SHA-256): what a test serves, and what a
/// host on a LAN can serve to clients that trust it explicitly. A certificate a browser accepts
/// without asking comes from a CA (Let's Encrypt), not from here.
static class TlsCertificates
{
	/// A certificate for `name` (its subject's CN and its one DNS name), valid from `notBefore` to
	/// `notAfter` (UTC, "YYYYMMDDhhmmss"), with a new key. False, `outError` saying why, when it
	/// could not be made.
	public static bool CreateSelfSigned(StringView name, StringView notBefore, StringView notAfter, String outCertificatePem,
		String outPrivateKeyPem, String outError)
	{
		let certificate = scope char8[4096];
		let key = scope char8[2048];
		int32 stage = 0;
		let code = mbedtlsc_self_signed_certificate(scope String(name).CStr(), scope String(notBefore).CStr(),
			scope String(notAfter).CStr(), certificate.Ptr, (uint)certificate.Count, key.Ptr, (uint)key.Count, &stage);
		if (code != 0)
		{
			switch (stage)
			{
			case 0: outError.Append("the crypto library did not start");
			case 1: outError.Append("the key could not be made");
			case 2:
				outError.Append("the key could not be copied: ");
				MbedTlsSession.ErrorText(code, outError);
			case 3:
				outError.Append("the certificate could not be written: ");
				MbedTlsSession.ErrorText(code, outError);
			default:
				outError.Append("the key could not be written: ");
				MbedTlsSession.ErrorText(code, outError);
			}
			return false;
		}
		outCertificatePem.Append(StringView(certificate.Ptr));
		outPrivateKeyPem.Append(StringView(key.Ptr));
		return true;
	}

	/// "YYYYMMDDhhmmss" for now plus `days` (negative: before now), UTC, for a certificate's
	/// validity: each field zero-padded to its width, as X.509's GeneralizedTime writes it.
	public static void Time(int32 days, String outTime)
	{
		let at = DateTime.UtcNow.AddDays(days);
		outTime.AppendF("{0:0000}{1:00}{2:00}{3:00}{4:00}{5:00}", at.Year, at.Month, at.Day, at.Hour, at.Minute, at.Second);
	}
}
#endif
