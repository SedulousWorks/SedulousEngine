using System;

namespace Sedulous.Core.Logging;

/// The shared part of a logger: the level filter, the name, and the formatter.
///
/// The level is checked BEFORE the message is formatted, so a disabled level costs
/// nothing beyond the call. Subclasses implement LogMessage and receive a line that is
/// already formatted.
///
/// Formatter ownership is a parameter rather than a convention: SetFormatter takes an
/// owns flag, and a formatter the logger created for itself is deleted by the logger.
/// Core provides the facility; whoever constructs the logger decides the lifetimes.
abstract class BaseLogger : ILogger
{
	public LogLevel MinimumLogLevel { get; set; }
	public String Name { get; private set; } = new .() ~ delete _;
	public ILogFormatter Formatter { get; private set; } ~ { if (mOwnsFormatter) delete _; }

	private bool mOwnsFormatter = false;

	/// The name defaults to the project that constructed the logger, which is resolved
	/// at that call site rather than here.
	public this(LogLevel minimumLogLevel, StringView name = Compiler.ProjectName,
		ILogFormatter formatter = null, bool ownsFormatter = false)
	{
		MinimumLogLevel = minimumLogLevel;
		Name.Set(name);
		Formatter = formatter;
		mOwnsFormatter = ownsFormatter;
		if (Formatter == null)
			SetDefaultFormatter();
	}

	private void SetDefaultFormatter()
	{
		ReleaseFormatter();
		Formatter = new DefaultLogFormatter();
		mOwnsFormatter = true;
	}

	private void ReleaseFormatter()
	{
		if (mOwnsFormatter && (Formatter != null))
			delete Formatter;
		Formatter = null;
		mOwnsFormatter = false;
	}

	/// Passing null restores the default formatter, which the logger then owns.
	public void SetFormatter(ILogFormatter formatter, bool ownsFormatter = false)
	{
		ReleaseFormatter();
		Formatter = formatter;
		mOwnsFormatter = ownsFormatter;
		if (Formatter == null)
			SetDefaultFormatter();
	}

	public bool IsEnabled(LogLevel logLevel) =>
		(logLevel >= MinimumLogLevel) && (logLevel < .None);

	public void Log(LogLevel logLevel, StringView format, params Object[] args)
	{
		if (!IsEnabled(logLevel))
			return;

		let message = scope String();
		message.AppendF(format, params args);

		let formatted = scope String();
		Formatter.Format(this, logLevel, message, formatted);

		LogMessage(logLevel, formatted);
	}

	protected abstract void LogMessage(LogLevel logLevel, StringView message);
}
