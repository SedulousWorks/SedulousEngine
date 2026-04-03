namespace Sedulous.Jobs;

/// Result of attempting to run a job.
enum JobRunResult
{
	/// Job ran successfully.
	Success,
	/// Job was not ready (dependencies not met).
	NotReady,
	/// Job was canceled.
	Cancelled
}
