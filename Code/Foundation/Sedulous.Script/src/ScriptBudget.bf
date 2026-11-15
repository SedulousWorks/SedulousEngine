using System;

namespace Sedulous.Script;

/// What one call into script may run before it is stopped with an error, which fails that call
/// and not the game: a loop that never ends would otherwise hang it. Time a coroutine waits
/// between resumes, or a call spends stopped at a breakpoint, is not running.
struct ScriptBudget
{
	/// Seconds of running per call, from the outermost call into script: a call the script makes
	/// into the engine that calls script again runs on the outer call's clock.
	public double CallSeconds = 5.0;
	/// Bytes the script's memory may hold, past which an allocation fails the call that asked
	/// ("Out of memory"). A backend with one heap for the process (AngelScript) holds every
	/// runtime to the budget of the call running.
	public uint64 HeapBytes = 512 * 1024 * 1024;
}
