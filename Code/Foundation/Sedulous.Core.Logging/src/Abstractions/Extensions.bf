using System;
namespace Sedulous.Core.Logging.Abstractions;

extension ILogger
{
	public void LogTrace(StringView format, params Object[] args)
	{
		Log(.Trace, format, params args);
	}

	public void LogDebug(StringView format, params Object[] args)
	{
		Log(.Debug, format, params args);
	}

	public void LogInformation(StringView format, params Object[] args)
	{
		Log(.Information, format, params args);
	}

	public void LogWarning(StringView mimimumLogLevel, params Object[] args)
	{
		Log(.Warning, mimimumLogLevel, params args);
	}

	public void LogError(StringView format, params Object[] args)
	{
		Log(.Error, format, params args);
	}

	public void LogCritical(StringView format, params Object[] args)
	{
		Log(.Critical, format, params args);
	}
}