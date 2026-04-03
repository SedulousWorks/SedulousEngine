namespace Sedulous.Jobs;

/// The current state of a job.
enum JobState
{
	/// Job is waiting to be executed.
	Pending,
	/// Job is currently running.
	Running,
	/// Job completed successfully.
	Succeeded,
	/// Job was canceled.
	Canceled
}
