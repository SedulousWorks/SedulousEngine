using System;

namespace Sedulous.Core;

/// The process-wide JobSystem.
///
/// Threading a pool through every call site that might parallelise costs more than it
/// buys, so this is a deliberate exception to passing dependencies down. The application
/// brackets its lifetime: initialise before any subsystem starts, shut down after every
/// subsystem has torn down, so it outlives its users.
///
/// Code that parallelises must tolerate its absence and fall back to serial. A unit test
/// or headless tool that never starts an application never initialises it, which is why
/// HasGlobalJobSystem exists rather than the accessor simply asserting.
///
/// JobSystem itself stays ordinarily constructible; this is only a managed instance.
static
{
	private static JobSystem sGlobalJobs;

	/// Creates the global pool, or does nothing if it already exists. The worker count is
	/// JobSystem's: negative picks logical cores minus one, zero runs everything inline.
	public static void InitGlobalJobSystem(int32 workerCount = JobSystem.Auto)
	{
		if (sGlobalJobs == null)
			sGlobalJobs = new JobSystem(workerCount);
	}

	/// Destroys the global pool, joining its workers. Does nothing if absent.
	public static void ShutdownGlobalJobSystem()
	{
		if (sGlobalJobs != null)
		{
			delete sGlobalJobs;
			sGlobalJobs = null;
		}
	}

	public static bool HasGlobalJobSystem() => sGlobalJobs != null;

	/// The global pool. Only valid once initialised; check HasGlobalJobSystem first if
	/// the caller can run without an application.
	public static JobSystem GlobalJobs() => sGlobalJobs;
}
