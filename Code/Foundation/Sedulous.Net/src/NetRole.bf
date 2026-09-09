namespace Sedulous.Net;

/// What a session is in the topology.
enum NetRole : uint8
{
	case None;
	/// One server, which this is not.
	case Client;
	/// A server that is also a local player.
	case ListenServer;
	/// A headless server with no local player.
	case DedicatedServer;
}
