namespace Sedulous.Net.WebSocket;

/// The frame kinds RFC 6455 defines.
enum WsOpcode : uint8
{
	case Continuation = 0x0;
	case Text = 0x1;
	case Binary = 0x2;
	case Close = 0x8;
	case Ping = 0x9;
	case Pong = 0xA;
}
