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
}
