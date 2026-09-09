namespace Sedulous.Net;

/// Where one remote stands in the handshake.
enum ConnectionState : uint8
{
	case Connecting;
	case Connected;
	case Disconnected;
}
