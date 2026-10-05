using System;
using System.Threading;

namespace Sedulous.RHI.WebGPU;

/// What the WebGPU devices have reported, for code that has to know rather than read the
/// console: a test that a sequence of calls raises no validation error, say.
static class WebGpuDiagnostics
{
	private static int32 sUncapturedErrors = 0;

	/// Every uncaptured error any device has raised since the process started (each is also
	/// written to the console as it arrives). A test reads it before and after.
	public static int32 UncapturedErrorCount => Interlocked.Load(ref sUncapturedErrors);

	public static void RecordUncapturedError() => Interlocked.Increment(ref sUncapturedErrors);
}
