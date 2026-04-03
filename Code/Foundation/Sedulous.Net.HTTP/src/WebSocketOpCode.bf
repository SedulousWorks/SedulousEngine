namespace Sedulous.Net.HTTP;

using System;

/// WebSocket frame opcodes (RFC 6455 Section 5.2).
public enum WebSocketOpCode : uint8
{
	case Continuation = 0x0;
	case Text = 0x1;
	case Binary = 0x2;
	case Close = 0x8;
	case Ping = 0x9;
	case Pong = 0xA;

	public bool IsControl => (uint8)this >= 0x8;
}
