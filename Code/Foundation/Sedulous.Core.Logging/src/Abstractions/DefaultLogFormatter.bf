using System;
namespace Sedulous.Core.Logging.Abstractions;

class DefaultLogFormatter : ILogFormatter
{
	public String Format { get; private set; } ~ delete _;

	public this()
	{
		Format = new String("[[loggerName]] [[logLevel]] [message]");
	}

	public void Format(ILogger logger, LogLevel logLevel, StringView message, String output)
	{
		output.Append(Format);
		output.Replace("[loggerName]", logger.Name);
		output.Replace("[logLevel]", logLevel.ToString(.. scope .()));

		output.Replace("[message]", scope String(message));
	}
}