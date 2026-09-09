using System;

namespace Sedulous.Mcp;

/// The serve loop.
static class McpServe
{
	/// Reads, dispatches and writes until the input stream ends.
	///
	/// Single threaded on purpose: one message is handled at a time, so a tool sees a settled
	/// world rather than one another request is halfway through changing.
	public static void Serve(McpServer server, ITransport transport)
	{
		let line = scope String();
		let response = scope String();

		while (transport.ReadLine(line))
		{
			response.Clear();
			// A notification produces no line at all, which is what false means here.
			if (server.HandleLine(line, response))
				transport.WriteLine(response);
		}
	}
}
