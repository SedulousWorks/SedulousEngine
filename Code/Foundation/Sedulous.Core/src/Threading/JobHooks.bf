using System;
using System.Threading;

namespace Sedulous.Core;

/// Called around every job any JobSystem runs, on the thread running it: how a profiler shows a
/// worker's jobs without Core knowing the profiler, which sits above it. Begin answers whether
/// it opened anything, and End runs only when it did. Installed once by whoever wants them;
/// none installed calls nothing.
class JobHooks
{
	public function bool() Begin;
	public function void() End;

	public this(function bool() begin, function void() end)
	{
		Begin = begin;
		End = end;
	}

	private static JobHooks sCurrent;

	/// Installs `hooks` for every JobSystem, or none with null. BORROWED: they must outlive
	/// every JobSystem that may run a job while they are installed.
	public static void Set(JobHooks hooks)
	{
		Interlocked.Exchange(ref sCurrent, hooks);
	}

	public static JobHooks Current => Volatile.Read(ref sCurrent);
}
