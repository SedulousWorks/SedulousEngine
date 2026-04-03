namespace Sedulous.Jobs;

/// Flags controlling job behavior.
enum JobFlags
{
	/// No special flags.
	None = 0,
	/// Job must run on the main thread.
	RunOnMainThread = 1,
	/// Job should be automatically released when completed.
	AutoRelease = 2
}
