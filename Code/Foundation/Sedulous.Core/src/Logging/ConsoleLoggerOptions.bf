using System;

namespace Sedulous.Core.Logging;

/// Per-level console colours.
struct ConsoleLoggerOptions
{
	public ConsoleColor Trace = .White;
	public ConsoleColor Debug = .Gray;
	public ConsoleColor Information = .Blue;
	public ConsoleColor Warning = .Yellow;
	public ConsoleColor Error = .Red;
	public ConsoleColor Critical = .DarkRed;

	public this() { }

	public ConsoleColor GetColor(LogLevel logLevel, ConsoleColor defaultColor)
	{
		switch (logLevel)
		{
		case .Trace: return Trace;
		case .Debug: return Debug;
		case .Information: return Information;
		case .Warning: return Warning;
		case .Error: return Error;
		case .Critical: return Critical;
		default: return defaultColor;
		}
	}
}
