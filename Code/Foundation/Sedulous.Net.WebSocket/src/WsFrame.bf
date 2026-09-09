using System;
using System.Collections;

namespace Sedulous.Net.WebSocket;

/// One decoded frame, unmasked.
class WsFrame
{
	public WsOpcode Opcode = .Binary;
	public List<uint8> Payload = new .() ~ delete _;

	public void Set(WsOpcode opcode, Span<uint8> payload)
	{
		Opcode = opcode;
		Payload.Clear();
		Payload.AddRange(payload);
	}
}
