using System;
using Sedulous.Net.Tls;

namespace Sedulous.Net.WebSocket;

/// Where a WebSocketClientSocket connects, and how.
class WebSocketClientConfig
{
	/// A name or a dotted quad.
	public String Host = new .() ~ delete _;
	public uint16 Port = 0;
	/// wss:// (TLS); ws:// otherwise.
	public bool Secure = false;
	public String Path = new .("/") ~ delete _;
	/// Native wss only: the TLS backend (the application's, BORROWED, outliving the socket) and
	/// what the host's certificate is checked against (Roots: TrustedPem alone). A browser does
	/// its own TLS.
	public ITlsBackend Tls = null;
	public TlsTrust Trust = .System;
	public String TrustedPem = new .() ~ delete _;
	/// Native only: a host that has not upgraded the connection by then is given up on.
	public float UpgradeTimeoutSeconds = 10.0f;
}
