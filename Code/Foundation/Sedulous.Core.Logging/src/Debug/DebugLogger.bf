using Sedulous.Core.Logging.Abstractions;
using System;

namespace Sedulous.Core.Logging.Debug;

class DebugLogger : BaseLogger
{
	public this(LogLevel minimumLogLevel, String name = null, ILogFormatter formatter = null)
		: base(minimumLogLevel, name, formatter)
	{
	}

	public ~this()
	{

	}

	protected override void LogMessage(LogLevel logLevel, StringView message)
	{
		Diagnostics.Debug.WriteLine(message);
	}
}