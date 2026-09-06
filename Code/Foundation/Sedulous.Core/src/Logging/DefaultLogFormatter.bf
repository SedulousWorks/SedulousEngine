using System;

namespace Sedulous.Core.Logging;

/// The default line shape: "[name] [level] message", driven by a template so a host can
/// change the arrangement without writing a formatter.
class DefaultLogFormatter : ILogFormatter
{
	public String Format { get; private set; } ~ delete _;

	public this(StringView template = "[[loggerName]] [[logLevel]] [message]")
	{
		Format = new String(template);
	}

	public void Format(ILogger logger, LogLevel logLevel, StringView message, String output)
	{
		output.Append(Format);
		output.Replace("[loggerName]", logger.Name);
		output.Replace("[logLevel]", logLevel.ToString(.. scope .()));
		output.Replace("[message]", scope String(message));
	}
}
