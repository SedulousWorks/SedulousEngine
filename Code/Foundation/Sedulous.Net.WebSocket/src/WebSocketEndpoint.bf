using Sedulous.Net;

namespace Sedulous.Net.WebSocket;

/// Synthetic endpoints for browser clients.
///
/// A real UDP endpoint packs an address and a port into the low forty eight bits and never
/// touches the top, so setting BIT SIXTY THREE gives websocket clients their own space in the
/// same value. That is what lets one datagram socket carry both kinds without the session
/// above it knowing which is which.
static class WebSocketEndpoint
{
	public const uint64 Bit = 1UL << 63;

	public static DatagramEndpoint Make(uint32 client) => .(Bit | (uint64)client);

	public static bool IsWebSocket(DatagramEndpoint endpoint) => (endpoint.Value & Bit) != 0;

	public static uint32 Client(DatagramEndpoint endpoint) => (uint32)(endpoint.Value & 0xFFFFFFFF);
}
