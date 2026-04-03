using System;
namespace Sedulous.Core.Logging.Abstractions;

abstract class BaseLogger : ILogger
{
	public LogLevel MimimumLogLevel { get; set; }
	public String Name { get; private set; } = new .() ~ delete _;
	public ILogFormatter Formatter { get; private set; } ~ { if (mOwnsLogFormatter) delete _; }

	private bool mOwnsLogFormatter = false;

	public this(LogLevel mimimumLogLevel, StringView name = Compiler.ProjectName, ILogFormatter formatter = null)
	{
		MimimumLogLevel = mimimumLogLevel;
		Name.Set(name);
		Formatter = formatter;
		if (Formatter == null)
		{
			SetDefaultFormatter();
		}
	}

	private void SetDefaultFormatter()
	{
		if (mOwnsLogFormatter && Formatter != null)
		{
			delete Formatter;
			Formatter = null;
		}

		Formatter = new DefaultLogFormatter();
		mOwnsLogFormatter = true;
	}

	public void SetFormatter(ILogFormatter formatter, bool ownsFormatter = false)
	{
		if (mOwnsLogFormatter && Formatter != null)
		{
			delete Formatter;
			Formatter = null;
		}

		Formatter = formatter;
		mOwnsLogFormatter = ownsFormatter;

		if (Formatter == null)
		{
			SetDefaultFormatter();
		}
	}

	public void Log(LogLevel logLevel, StringView format, params Object[] args)
	{
		if (logLevel >= MimimumLogLevel && logLevel < .None)
		{
			String message = scope String();
			message.AppendF(format, params args);

			String formattedMessage = scope .();
			Formatter.Format(this, logLevel, message, formattedMessage);

			LogMessage(logLevel, formattedMessage);
		}
	}

	protected abstract void LogMessage(LogLevel logLevel, StringView message);
}