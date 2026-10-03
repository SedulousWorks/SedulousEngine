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
	/// Under a lock, not a bare counter: parallel cooks (the cook driver builds on job workers,
	/// with no world alive) each acquire, and a second caller must not use the backend before
	/// the first has finished bringing it up, nor a release tear it down under one acquiring.
	private static Monitor sLock = new .() ~ delete _;
	private static int sUsers = 0;

	/// Brings the backend up if nothing else has. Paired with Release.
	public static void Acquire()
	{
		using (sLock.Enter())
		{
			if (sUsers++ == 0)
				JPH_Init();
		}
	}

	public static void Release()
	{
		using (sLock.Enter())
		{
			if (--sUsers == 0)
				JPH_Shutdown();
		}
	}
}
