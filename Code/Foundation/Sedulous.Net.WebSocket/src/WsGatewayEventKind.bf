namespace Sedulous.Net.WebSocket;

/// What a drained gateway event is.
enum WsGatewayEventKind : uint8
{
	/// A client completed the upgrade.
	case Connected;
	/// A client closed or errored.
	case Disconnected;
	/// One binary frame arrived.
	case Message;
}
