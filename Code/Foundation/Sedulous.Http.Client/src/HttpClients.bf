using System;
using Sedulous.Net.Tls;

namespace Sedulous.Http.Client;

static class HttpClients
{
	/// The platform's client, which the caller owns: the native one (`tls` BORROWED, null for http
	/// only; `trust` and `trustedPem` as there), or in a browser the browser's, which ignores them
	/// (the browser does TLS).
	public static IHttpClient Create(ITlsBackend tls, TlsTrust trust = .System, StringView trustedPem = default)
	{
#if BF_PLATFORM_WASM
		return new BrowserHttpClient();
#else
		return new NativeHttpClient(tls, trust, trustedPem);
#endif
	}
}
