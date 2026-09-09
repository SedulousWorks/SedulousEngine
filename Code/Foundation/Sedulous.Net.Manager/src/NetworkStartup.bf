using System;
using Sedulous.Net;

namespace Sedulous.Net.Manager;

/// Declarative startup, preset by an application before it configures its subsystems.
///
/// IPv4 for now: ServerHost is a dotted quad or a DNS name. BORROWED, and only read during
/// the Start call it is passed to.
struct NetworkStartup
{
	public NetworkRole Role = .None;
	/// Server: the bind port. Client: nought lets the operating system choose.
	public uint16 ListenPort = 0;
	/// Client: the address to connect to.
	public StringView ServerHost = "127.0.0.1";
	/// Client: the server's port.
	public uint16 ServerPort = 0;
	/// Server: dedicated, with no local player, against a listen server.
	public bool Dedicated = false;
	/// Protocol tuning: keepalive, timeout, resend.
	public ReliableConfig Reliable = .();

	public this() {}
}
