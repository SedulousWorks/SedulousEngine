using System;

namespace Sedulous.Core.Logging;

/// The process-wide logger.
///
/// The same exception the job system makes, for the same reason: threading a logger
/// through everything that might want to say something costs more than it buys, and
/// Raptor's global worked well.
///
/// Ownership still flows down. The application constructs whatever logger it wants,
/// composite or otherwise, and installs it here; owns says whether this should delete it
/// on shutdown. Core neither creates one nor decides its shape.
///
/// Code must tolerate its absence: a unit test or headless tool never installs one, so
/// HasGlobalLogger exists rather than the accessor asserting.
static
{
	private static ILogger sGlobalLogger;
	private static bool sOwnsGlobalLogger;

	/// Installs the global logger, replacing and, if owned, deleting any previous one.
	public static void InitGlobalLogger(ILogger logger, bool owns = false)
	{
		ShutdownGlobalLogger();
		sGlobalLogger = logger;
		sOwnsGlobalLogger = owns;
	}

	public static void ShutdownGlobalLogger()
	{
		if (sOwnsGlobalLogger && (sGlobalLogger != null))
			delete sGlobalLogger;
		sGlobalLogger = null;
		sOwnsGlobalLogger = false;
	}

	/// Detaches the global logger WITHOUT deleting it, handing its ownership to the caller:
	/// for a scope that wants to listen in, installs a composite of this and its own, and
	/// puts this one back afterwards with the ownership it took.
	public static ILogger DetachGlobalLogger(out bool owned)
	{
		let logger = sGlobalLogger;
		owned = sOwnsGlobalLogger;
		sGlobalLogger = null;
		sOwnsGlobalLogger = false;
		return logger;
	}

	public static bool HasGlobalLogger() => sGlobalLogger != null;

	public static ILogger GlobalLogger() => sGlobalLogger;

	/// Logs to the global logger if one is installed, and does nothing otherwise.
	///
	/// This is the safe frontend for code that cannot assume an application started. The
	/// arguments still reach it unformatted, so a filtered or absent logger does not pay
	/// to build the message.
	public static void GlobalLog(LogLevel level, StringView format, params Object[] args)
	{
		if (sGlobalLogger == null)
			return;
		sGlobalLogger.Log(level, format, params args);
	}
}
