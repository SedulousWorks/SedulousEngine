using System;
using System.Collections;

namespace Sedulous.Net.WebSocket;

/// One event from the gateway.
///
/// The caller SUPPLIES one and reuses it across the drain loop, the same shape the transport
/// seam uses.
class WsGatewayEvent
{
	public WsGatewayEventKind Kind = .Message;
	public uint32 Client = 0;
	/// Meaningful for Message only.
	public List<uint8> Payload = new .() ~ delete _;

	public void Set(WsGatewayEventKind kind, uint32 client, Span<uint8> payload)
	{
		Kind = kind;
		Client = client;
		Payload.Clear();
		Payload.AddRange(payload);
	}
}
