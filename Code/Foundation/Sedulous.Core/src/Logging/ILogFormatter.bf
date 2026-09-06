using System;

namespace Sedulous.Core.Logging;

/// Turns a logger, a level and a message into the line that gets written.
interface ILogFormatter
{
	/// The template this formatter applies, for callers that want to show or edit it.
	String Format { get; }

	void Format(ILogger logger, LogLevel logLevel, StringView message, String output);
}
