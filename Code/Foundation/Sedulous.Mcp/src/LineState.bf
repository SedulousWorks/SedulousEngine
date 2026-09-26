namespace Sedulous.Mcp;

/// How McpServer.HandleLine dealt with one line.
enum LineState
{
	/// The response line was written out.
	case Answered;
	/// Nothing to write back, by protocol.
	case Notification;
	/// The tool asked to be re-entered: hand the SAME line in again on the next pump.
	case NotFinished;
}
