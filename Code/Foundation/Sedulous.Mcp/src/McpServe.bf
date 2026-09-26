using System;

namespace Sedulous.Mcp;

/// The serve loop.
static class McpServe
{
	/// Reads, dispatches and writes until the input stream ends.
	///
	/// Single threaded on purpose: one message is handled at a time, so a tool sees a settled
	/// world rather than one another request is halfway through changing. A tool that is not
	/// finished is re-entered with the same line after a short sleep: stdio has no frame to
	/// pump, so this loop is the pump.
	public static void Serve(McpServer server, ITransport transport)
	{
		let line = scope String();
		let response = scope String();

		while (transport.ReadLine(line))
		{
			response.Clear();
			var state = server.HandleLine(line, response);
			while (state == .NotFinished)
			{
				System.Threading.Thread.Sleep(1);
				response.Clear();
				state = server.HandleLine(line, response);
			}
			// A notification produces no line at all.
			if (state == .Answered)
				transport.WriteLine(response);
		}
	}
}
