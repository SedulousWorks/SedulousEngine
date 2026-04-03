namespace Sedulous.Jobs;

/// The current state of a worker.
enum WorkerState
{
	/// Worker is idle and ready for jobs.
	Idle,
	/// Worker is processing a job.
	Busy,
	/// Worker is paused.
	Paused,
	/// Worker has stopped.
	Dead
}
