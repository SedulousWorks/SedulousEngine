using System;
using System.Collections;
using Sedulous.Core.Logging;

namespace Sedulous.Core.Tests;

/// A logger that records what reached it, so tests can assert on delivery rather than on
/// console output.
class CapturingLogger : BaseLogger
{
	public List<String> Lines = new .() ~ DeleteContainerAndItems!(_);
	public List<LogLevel> Levels = new .() ~ delete _;

	public this(LogLevel minimumLogLevel, StringView name = "Test",
		ILogFormatter formatter = null, bool ownsFormatter = false)
		: base(minimumLogLevel, name, formatter, ownsFormatter)
	{
	}

	public int Count => Lines.Count;
	public StringView LastLine => Lines.IsEmpty ? default : Lines[Lines.Count - 1];
	public LogLevel LastLevel => Levels[Levels.Count - 1];

	public void Reset()
	{
		ClearAndDeleteItems!(Lines);
		Levels.Clear();
	}

	protected override void LogMessage(LogLevel logLevel, StringView message)
	{
		Lines.Add(new String(message));
		Levels.Add(logLevel);
	}
}
