using System;
using Sedulous.Core.Logging;

namespace Sedulous.Tools.Mcp;

/// Every engine log line to standard error: standard output is the JSON-RPC wire, and a
/// stray line there corrupts the protocol stream.
class StderrLogger : BaseLogger
{
	public this(LogLevel minimumLogLevel) : base(minimumLogLevel, "Mcp")
	{
	}

	protected override void LogMessage(LogLevel logLevel, StringView message)
	{
		Console.Error.WriteLine(message);
		Console.Error.Flush();
	}
}
