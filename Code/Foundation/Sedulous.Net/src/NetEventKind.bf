namespace Sedulous.Net;

/// What a drained transport event is.
enum NetEventKind : uint8
{
	case Connected;
	case Disconnected;
	case Received;
}
