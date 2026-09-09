using System;

namespace Sedulous.Mcp;

/// The transport seam: newline delimited JSON-RPC, one message per line.
///
/// NO Content-Length headers. That framing is LSP's, not this protocol's, and mixing them up
/// produces a stream neither side can read.
interface ITransport
{
	/// Reads the next inbound line into outLine, with the newline stripped. False at end of
	/// stream.
	bool ReadLine(String outLine);

	/// Writes one outbound line. The transport appends the delimiter.
	void WriteLine(StringView line);
}
