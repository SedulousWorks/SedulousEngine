using System;

namespace Sedulous.Mcp.Http;

/// How the host binds and what it accepts as proof of trust.
struct McpHttpConfig
{
	/// Nought lets the operating system choose; read BoundPort after Start.
	public uint16 Port = 0;
	/// REQUIRED. Start refuses an empty one, because localhost is the boundary and this is the
	/// lock: without it anything on the machine could drive the editor.
	///
	/// BORROWED. Start copies it, so it need only outlive that call.
	public StringView Token = default;

	public this() {}
}
