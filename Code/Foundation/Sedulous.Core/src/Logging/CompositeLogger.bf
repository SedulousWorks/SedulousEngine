using System;
using System.Collections;

namespace Sedulous.Core.Logging;

/// Fans one log call out to several loggers.
///
/// Keeping it as an ILogger rather than as a sink list inside every logger means a caller
/// who wants console-and-file composes two loggers, and a caller who wants one pays for
/// nothing.
///
/// It implements ILogger directly rather than extending BaseLogger, so each child
/// applies its OWN level filter and formatter. Formatting here and passing the result
/// down would flatten every child's formatter into this one's.
///
/// Children are non-owning by default; Add takes an owns flag for callers that want the
/// composite to be the owner.
class CompositeLogger : ILogger
{
	private List<ILogger> mLoggers = new .() ~ delete _;
	private List<bool> mOwned = new .() ~ delete _;

	public LogLevel MinimumLogLevel { get; set; }
	public String Name { get; private set; } = new .() ~ delete _;

	public this(LogLevel minimumLogLevel = .Trace, StringView name = Compiler.ProjectName)
	{
		MinimumLogLevel = minimumLogLevel;
		Name.Set(name);
	}

	public ~this()
	{
		for (int i < mLoggers.Count)
		{
			if (mOwned[i])
				delete mLoggers[i];
		}
	}

	public int Count => mLoggers.Count;

	public void Add(ILogger logger, bool owned = false)
	{
		if (logger == null)
			return;
		mLoggers.Add(logger);
		mOwned.Add(owned);
	}

	/// Removes without deleting, even if the composite owned it: the caller taking it
	/// back is taking the lifetime back too.
	public bool Remove(ILogger logger)
	{
		for (int i < mLoggers.Count)
		{
			if (mLoggers[i] == logger)
			{
				mLoggers.RemoveAt(i);
				mOwned.RemoveAt(i);
				return true;
			}
		}
		return false;
	}

	/// The composite's own level gates the whole fan-out; each child then applies its
	/// own, so a child can be quieter than the composite but not louder.
	public void Log(LogLevel logLevel, StringView format, params Object[] args)
	{
		if ((logLevel < MinimumLogLevel) || (logLevel >= .None))
			return;
		for (let logger in mLoggers)
			logger.Log(logLevel, format, params args);
	}
}
