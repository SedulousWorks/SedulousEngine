using System;

namespace Sedulous.Core.Logging;

/// Somewhere log messages go.
///
/// Log takes the format and its arguments rather than a finished string, so an
/// implementation can check the level before paying to format. The level-named
/// convenience methods are an extension on this interface, so every implementation gets
/// them without inheriting anything.
interface ILogger
{
	LogLevel MinimumLogLevel { get; set; }
	String Name { get; }

	void Log(LogLevel logLevel, StringView format, params Object[] args);

	/// A line with the references it carries (borrowed for the call). A logger that keeps none (a
	/// console, a file, the fixed size ring) writes the text alone, which is the default.
	void LogReferenced(LogLevel logLevel, Span<LogReference> references, StringView format, params Object[] args)
	{
		Log(logLevel, format, params args);
	}
}
