namespace Sedulous.RHI.Validation;

using System;

/// Severity levels for validation messages.
enum ValidationSeverity
{
	Info,
	Warning,
	Error,
}

/// Callback delegate for validation messages.
typealias ValidationCallback = delegate void(ValidationSeverity severity, StringView message);

/// Central logging system for the validation layer.
/// Users can register a callback to route messages to their own logging system.
static class ValidationLogger
{
	private static ValidationCallback sCallback;
	private static ValidationSeverity sMinSeverity = .Warning;

	/// Sets the callback for validation messages.
	public static void SetCallback(ValidationCallback callback)
	{
		sCallback = callback;
	}

	/// Sets the minimum severity level to report.
	public static void SetMinSeverity(ValidationSeverity severity)
	{
		sMinSeverity = severity;
	}

	/// Logs a validation error.
	public static void Error(StringView message)
	{
		Log(.Error, message);
	}

	/// Logs a validation warning.
	public static void Warn(StringView message)
	{
		Log(.Warning, message);
	}

	/// Logs a validation info message.
	public static void Info(StringView message)
	{
		Log(.Info, message);
	}

	private static void Log(ValidationSeverity severity, StringView message)
	{
		if (severity < sMinSeverity) return;

		if (sCallback != null)
		{
			sCallback(severity, message);
		}
		else
		{
			// Default: print to debug output
			let prefix = (severity == .Error) ? "[Sedulous.RHI ERROR] " :
						 (severity == .Warning) ? "[Sedulous.RHI WARN] " :
						 "[Sedulous.RHI INFO] ";

			let msg = scope String();
			msg.Append(prefix);
			msg.Append(message);
			System.Diagnostics.Debug.WriteLine(msg);
		}
	}
}
