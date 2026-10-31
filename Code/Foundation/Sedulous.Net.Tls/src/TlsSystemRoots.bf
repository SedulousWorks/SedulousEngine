using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Net.Tls;

/// The system's trusted roots: the distribution's bundle on Linux and SteamOS (the first of the
/// usual paths that exists), the ROOT store on Windows; none where none is found (a web build, a
/// box without a bundle).
static class TlsSystemRoots
{
	/// Fills `outRoots`; `outWhere`, when given, says what was read or where it looked.
	public static void Load(TlsRoots outRoots, String outWhere = null)
	{
#if BF_PLATFORM_WINDOWS
		// The machine's trusted roots, as Windows' own TLS checks them. Every certificate the
		// store hands is taken: one that is not X.509 DER fails its parse and does not count.
		let store = CertOpenSystemStoreW(0, "ROOT".ToScopedNativeWChar!());
		if (store == null)
		{
			outWhere?.Set("the Windows ROOT store did not open");
			return;
		}
		for (var cert = CertEnumCertificatesInStore(store, null); cert != null; cert = CertEnumCertificatesInStore(store, cert))
		{
			let der = new List<uint8>();
			der.AddRange(Span<uint8>(cert.Encoded, (int)cert.EncodedLength));
			outRoots.Der.Add(der);
		}
		CertCloseStore(store, 0);
		outWhere?.Set(scope $"the Windows ROOT store ({outRoots.Der.Count} certificates)");
#elif BF_PLATFORM_WASM
		// A browser checks certificates itself; a web build has no TLS backend.
		outWhere?.Set("none: the browser does TLS");
#else
		// The bundle a distribution keeps (Debian/Ubuntu/SteamOS/Arch, Fedora/RHEL, openSUSE,
		// Alpine), the first that exists.
		StringView[5] bundles = .(
			"/etc/ssl/certs/ca-certificates.crt",
			"/etc/pki/tls/certs/ca-bundle.crt",
			"/etc/ssl/ca-bundle.pem",
			"/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem",
			"/etc/ssl/cert.pem");
		let bytes = scope List<uint8>();
		for (let path in bundles)
		{
			if ((ReadFile(path, bytes) case .Err) || bytes.IsEmpty)
				continue;
			outRoots.Pem.Set(StringView((char8*)bytes.Ptr, bytes.Count));
			outWhere?.Set(path);
			return;
		}
		outWhere?.Set("no bundle at /etc/ssl/certs/ca-certificates.crt or the other usual paths");
#endif
	}

#if BF_PLATFORM_WINDOWS
	[CRepr]
	private struct CertContext
	{
		public uint32 EncodingType;
		public uint8* Encoded;
		public uint32 EncodedLength;
		public void* Info;
		public void* Store;
	}

	[CLink, CallingConvention(.Stdcall)]
	private static extern void* CertOpenSystemStoreW(uint provider, char16* subsystem);
	[CLink, CallingConvention(.Stdcall)]
	private static extern CertContext* CertEnumCertificatesInStore(void* store, CertContext* previous);
	[CLink, CallingConvention(.Stdcall)]
	private static extern int32 CertCloseStore(void* store, uint32 flags);
#endif
}
