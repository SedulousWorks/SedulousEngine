namespace Sedulous.Http;

/// How a server binds and what it will tolerate.
struct HttpServerConfig
{
	/// Nought lets the operating system choose; read BoundPort after Start.
	public uint16 Port = 0;
	public int MaxBodyBytes = 16 * 1024 * 1024;
	/// Accepted but unanswered connections beyond this are refused, so a peer opening sockets
	/// and never speaking cannot exhaust the server.
	public int MaxConnections = 32;

	public this() {}
}
