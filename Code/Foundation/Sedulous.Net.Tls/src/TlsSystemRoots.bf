using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Net.Tls;

/// The system's trusted roots: the distribution's bundle on Linux and SteamOS (the first of the
/// usual paths that exists), the ROOT store on Windows, the system's certificate folder on
/// Android; none where none is found (a web build, a box without a bundle).
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
#elif BF_PLATFORM_ANDROID
		// Android keeps its roots as a folder of certificates: since Android 14 in the module the
		// system updates for security, before that in the system image. Certificates a user added
		// are left out, as Android leaves them out for an app unless it asks for them.
		StringView[2] folders = .("/apex/com.android.conscrypt/cacerts", "/system/etc/security/cacerts");
		for (let folder in folders)
		{
			let count = ReadCertificateFolder(folder, outRoots.Pem..Clear());
			if (outRoots.Pem.IsEmpty)
				continue;
			outWhere?.Set(scope $"{folder} ({count} certificates)");
			return;
		}
		outWhere?.Set("no certificates in /apex/com.android.conscrypt/cacerts or /system/etc/security/cacerts");
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

	/// Appends the certificates in `folder`, a PEM file each (Android keeps its roots so), to
	/// `outBundle` as one bundle; text around a certificate is kept, as a PEM reader skips it.
	/// Nothing when the folder is missing or holds none. Returns the number of files read.
	public static int ReadCertificateFolder(StringView folder, String outBundle)
	{
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		ListDirectory(folder, scope [&] (name, isDirectory) =>
			{
				if (!isDirectory)
					names.Add(new String(name));
			});
		int read = 0;
		let bytes = scope List<uint8>();
		for (let name in names)
		{
			bytes.Clear();
			if ((ReadFile(PathJoin(folder, name, .. scope .()), bytes) case .Err) || bytes.IsEmpty)
				continue;
			outBundle.Append(StringView((char8*)bytes.Ptr, bytes.Count));
			outBundle.Append('\n');
			read++;
		}
		return read;
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
