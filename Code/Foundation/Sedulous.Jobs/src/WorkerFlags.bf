namespace Sedulous.Jobs;

/// Flags controlling worker behavior.
enum WorkerFlags
{
	/// No special flags.
	None = 0,
	/// Worker should be recreated if it dies.
	Persistent = 1
}
