using System;

namespace Sedulous.Profiler;

/// RAII helper for automatic scope profiling.
/// Use with Beef's `using` statement for automatic Begin/End.
///
/// Example:
/// ```beef
/// void Update()
/// {
///     using (Profiler.Begin("Update"))
///     {
///         // Code to profile
///     }
/// }
/// ```
///
/// Alternative direct construction:
/// ```beef
/// using (ProfileScope("Update"))
/// {
///     // Code to profile
/// }
/// ```
struct ProfileScope : IDisposable
{
	private bool mActive;

	/// Create a profiling scope with the given name.
	[Inline]
	public this(StringView name)
	{
		mActive = Profiler.Enabled;
		if (mActive)
			Profiler.BeginScope(name);
	}

	/// End the profiling scope.
	[Inline]
	public void Dispose()
	{
		if (mActive)
			Profiler.EndScope();
	}
}
