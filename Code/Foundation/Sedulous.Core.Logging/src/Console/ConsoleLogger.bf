using Sedulous.Core.Logging.Abstractions;
using System;

namespace Sedulous.Core.Logging.Console;

struct ConsoleLoggerOptions
{
	public ConsoleColor Trace = .White;
	public ConsoleColor Debug = .Gray;
	public ConsoleColor Information = .Blue;
	public ConsoleColor Warning = .Yellow;
	public ConsoleColor Error = .Red;
	public ConsoleColor Critical = .DarkRed;

	public ConsoleColor GetColor(LogLevel logLevel, ConsoleColor defaultColor)
	{
		switch (logLevel) {
		case .Trace:
			return Trace;

		case .Debug:
			return Debug;

		case .Information:
			return Information;

		case .Warning:
			return Warning;

		case .Error:
			return Error;

		case .Critical:
			return Critical;

		default:
			return defaultColor;
		}
	}
}

class ConsoleLogger : BaseLogger
{
	private ConsoleLoggerOptions mOptions;
	public this(LogLevel minimumLogLevel, String name = null, ILogFormatter formatter = null, ConsoleLoggerOptions options = .())
		: base(minimumLogLevel, name, formatter)
	{
		mOptions = options;
	}

	protected override void LogMessage(LogLevel logLevel, StringView message)
	{
		var original = Console.ForegroundColor;
		Console.ForegroundColor = mOptions.GetColor(logLevel, original);
		Console.WriteLine(message);
		Console.ForegroundColor = original;
	}
}