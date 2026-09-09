using System;
using System.Threading;
using joltc_Beef;

namespace Sedulous.Physics;

/// The backend's PROCESS WIDE bring up: its allocator, factory and type registry.
///
/// Refcounted, because it is one registry for the process and there is one per WORLD asking
/// for it. Bringing it up twice would replace the factory out from under the shapes already
/// built against it, and tearing it down while a world still holds bodies is worse.
///
/// Cooking a shape needs it too, and a cooker has no world, which is the other reason this
/// is not simply the world's constructor.
static class JoltRuntime
{
	private static int sUsers = 0;

	/// Brings the backend up if nothing else has. Paired with Release.
	public static void Acquire()
	{
		if (Interlocked.Increment(ref sUsers) == 1)
			JPH_Init();
	}

	public static void Release()
	{
		if (Interlocked.Decrement(ref sUsers) == 0)
			JPH_Shutdown();
	}
}
