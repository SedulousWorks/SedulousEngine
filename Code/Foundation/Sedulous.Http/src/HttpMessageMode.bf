namespace Sedulous.Http;

/// Which side of the exchange a parser is reading.
enum HttpMessageMode : uint8
{
	case Request;
	case Response;
}
