using System;
using System.IO;

namespace Sedulous.Mcp;

/// The real pipe: standard input and standard output.
///
/// NOTHING but responses may reach standard output. A stray print corrupts the stream, so a
/// host has to send its logs to standard error.
class StdioTransport : ITransport
{
	public bool ReadLine(String outLine)
	{
		outLine.Clear();
		var sawAny = false;

		for (;;)
		{
			let c = Console.In.Read();
			if (c case .Err)
			{
				// A final line with no trailing newline is still a message.
				return sawAny;
			}

			let ch = c.Get();
			sawAny = true;
			if (ch == '\n')
				return true;
			// A carriage return is dropped, so a peer using CRLF does not leave one on the
			// end of every message.
			if (ch != '\r')
				outLine.Append(ch);
		}
	}

	public void WriteLine(StringView line)
	{
		Console.Out.Write(line);
		Console.Out.Write("\n");
		Console.Out.Flush();
	}
}
