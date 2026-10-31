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

	/// Reads a join address with a scheme, "ws://host[:port][/path]" or "wss://...", into the
	/// host, port (`defaultPort` when the address names none, else the scheme's own), Secure and
	/// path. False when `address` has no ws:// or wss:// scheme (a bare host) or names no host.
	public bool ParseAddress(StringView address, uint16 defaultPort)
	{
		StringView rest;
		if ((address.Length >= 6) && address.Substring(0, 6).Equals("wss://", true))
		{
			Secure = true;
			rest = address.Substring(6);
		}
		else if ((address.Length >= 5) && address.Substring(0, 5).Equals("ws://", true))
		{
			Secure = false;
			rest = address.Substring(5);
		}
		else
			return false;
		var slash = rest.IndexOf('/');
		if (slash < 0)
			slash = rest.Length;
		let authority = rest.Substring(0, slash);
		Path.Set((slash < rest.Length) ? rest.Substring(slash) : "/");
		var colon = authority.LastIndexOf(':');
		if (colon < 0)
			colon = authority.Length;
		Host.Set(authority.Substring(0, colon));
		Port = defaultPort;
		if (colon < authority.Length)
		{
			uint32 value = 0;
			let digits = authority.Substring(colon + 1);
			for (let c in digits)
			{
				if ((c < '0') || (c > '9') || (value > 65535))
					return false;
				value = value * 10 + (uint32)((int)c - (int)'0');
			}
			if (digits.IsEmpty || (value == 0) || (value > 65535))
				return false;
			Port = (uint16)value;
		}
		else if (Port == 0)
			Port = Secure ? 443 : 80; // the scheme's own, as a browser would
		return !Host.IsEmpty;
	}
}
