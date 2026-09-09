namespace Sedulous.Http;

/// Where an incremental parse stands.
enum HttpParseState : uint8
{
	/// Feed more bytes.
	case NeedMore;
	/// A whole message is readable.
	case Complete;
	/// Malformed or over a limit. Close the connection; a server answers 400 first.
	case Failed;
}
