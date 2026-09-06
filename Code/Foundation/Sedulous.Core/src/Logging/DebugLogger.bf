using System;

namespace Sedulous.Core.Logging;

/// Writes to the platform debugger output.
class DebugLogger : BaseLogger
{
	public this(LogLevel minimumLogLevel, StringView name = Compiler.ProjectName,
		ILogFormatter formatter = null, bool ownsFormatter = false)
		: base(minimumLogLevel, name, formatter, ownsFormatter)
	{
	}

	protected override void LogMessage(LogLevel logLevel, StringView message)
	{
		System.Diagnostics.Debug.WriteLine(message);
	}
}
