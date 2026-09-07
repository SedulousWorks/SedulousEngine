using System;
using System.Collections;

namespace Sedulous.RHI.Validation;

/// Where the validation layer reports what it found.
///
/// A CALLBACK rather than a return value, because the layer sits transparently between a
/// caller and a backend: it must not change what a call returns, and the caller could not
/// act on the reason anyway. It is process global for the same reason the logger and the
/// profiler are: a diagnostic channel that every layer writes to and nobody threads.
///
/// The callback is also what makes the rules testable. A test installs one, drives the
/// misuse, and asserts on what was reported.
static class ValidationLog
{
	private static ValidationCallback sCallback;
	private static ValidationSeverity sMinimumSeverity = .Warning;

	/// Routes messages somewhere. The caller OWNS the delegate and must keep it alive for
	/// as long as it is installed; passing null goes back to the default.
	public static void SetCallback(ValidationCallback callback) => sCallback = callback;

	/// Below this, messages are dropped. Warning by default, so Info costs nothing until
	/// somebody asks for it.
	public static void SetMinimumSeverity(ValidationSeverity severity)
		=> sMinimumSeverity = severity;

	public static ValidationSeverity MinimumSeverity => sMinimumSeverity;

	public static void Error(StringView message) => Write(.Error, message);
	public static void Warn(StringView message) => Write(.Warning, message);
	public static void Info(StringView message) => Write(.Info, message);

	private static void Write(ValidationSeverity severity, StringView message)
	{
		if (severity < sMinimumSeverity)
			return;

		if (sCallback != null)
		{
			sCallback(severity, message);
			return;
		}

		let prefix = (severity == .Error) ? "[Sedulous.RHI ERROR] "
			: (severity == .Warning) ? "[Sedulous.RHI WARN] "
			: "[Sedulous.RHI INFO] ";
		Console.WriteLine(scope $"{prefix}{message}");
	}
}
