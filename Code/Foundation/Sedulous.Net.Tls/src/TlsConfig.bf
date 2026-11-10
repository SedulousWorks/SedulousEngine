using System;
using System.Collections;

namespace Sedulous.Net.Tls;

/// What a client checks the server's certificate against.
enum TlsTrust : uint8
{
	/// The system's roots (TlsSystemRoots), the default.
	System,
	/// The configuration's own roots alone (a game's own CA).
	Roots,
	/// No check at all: tests only, never the default.
	InsecureForTests,
}

enum TlsVersion : uint8
{
	Tls12,
	Tls13,
}

class TlsClientConfig
{
	/// The host the client asks for (SNI) and checks the certificate is for; required unless the
	/// trust is InsecureForTests.
	public String ServerName = new .() ~ delete _;
	public TlsTrust Trust = .System;
	/// What a Roots trust trusts.
	public TlsRoots Roots = new .() ~ delete _;
	/// Protocols offered, in preference order ("http/1.1").
	public List<String> Alpn = new .() ~ DeleteContainerAndItems!(_);
	public TlsVersion Minimum = .Tls12;
	public TlsVersion Maximum = .Tls13;

	/// Trusts the roots in `pem` alone.
	public void TrustPem(StringView pem)
	{
		Trust = .Roots;
		Roots.Pem.Set(pem);
	}
}

class TlsServerConfig
{
	/// The server's certificate first, then its issuers.
	public String CertificateChainPem = new .() ~ delete _;
	public String PrivateKeyPem = new .() ~ delete _;
	/// Protocols accepted, in preference order.
	public List<String> Alpn = new .() ~ DeleteContainerAndItems!(_);
	public TlsVersion Minimum = .Tls12;
	public TlsVersion Maximum = .Tls13;
}
