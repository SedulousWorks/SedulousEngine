using System;

namespace Sedulous.Core.Logging;

/// Writes to the console, colouring each line by level.
class ConsoleLogger : BaseLogger
{
	private ConsoleLoggerOptions mOptions;

	public this(LogLevel minimumLogLevel, StringView name = Compiler.ProjectName,
		ILogFormatter formatter = null, bool ownsFormatter = false,
		ConsoleLoggerOptions options = .())
		: base(minimumLogLevel, name, formatter, ownsFormatter)
	{
		mOptions = options;
	}

	protected override void LogMessage(LogLevel logLevel, StringView message)
	{
		let original = Console.ForegroundColor;
		Console.ForegroundColor = mOptions.GetColor(logLevel, original);
		Console.WriteLine(message);
		Console.ForegroundColor = original;
	}
}
