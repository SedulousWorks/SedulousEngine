using System;

namespace Sedulous.Core.Logging;

/// The level-named frontend, as an extension so it exists once for every ILogger rather
/// than being repeated per implementation or forced through a base class.
///
/// The arguments reach Log unformatted, so a disabled level costs the boxing of the
/// arguments but not the formatting.
extension ILogger
{
	public void LogTrace(StringView format, params Object[] args) =>
		Log(.Trace, format, params args);

	public void LogDebug(StringView format, params Object[] args) =>
		Log(.Debug, format, params args);

	public void LogInformation(StringView format, params Object[] args) =>
		Log(.Information, format, params args);

	public void LogWarning(StringView format, params Object[] args) =>
		Log(.Warning, format, params args);

	public void LogError(StringView format, params Object[] args) =>
		Log(.Error, format, params args);

	public void LogCritical(StringView format, params Object[] args) =>
		Log(.Critical, format, params args);
}
