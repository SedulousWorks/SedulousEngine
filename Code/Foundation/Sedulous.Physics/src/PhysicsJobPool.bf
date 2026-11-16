using System;
using System.Threading;
using Sedulous.Core;
using joltc_Beef;

namespace Sedulous.Physics;

/// One worker pool for every world. Each world made its own, a thread per core per world, so a
/// game with a few scenes ran several pools' worth of threads. Refcounted by the worlds: made
/// with the first and gone with the last.
static class PhysicsJobPool
{
	private static Monitor sLock = new .() ~ delete _;
	private static int sUsers = 0;
	private static JPH_JobSystem* sPool = null;

	/// How many worlds hold the pool.
	public static int Users
	{
		get
		{
			using (sLock.Enter())
				return sUsers;
		}
	}

	/// The shared pool, made if no world holds it. Paired with Release.
	public static JPH_JobSystem* Acquire()
	{
		using (sLock.Enter())
		{
			if (sUsers++ == 0)
			{
				var config = JobSystemThreadPoolConfig()
					{
						maxJobs = (uint32)JPH_MAX_PHYSICS_JOBS,
						maxBarriers = (uint32)JPH_MAX_PHYSICS_BARRIERS,
						// One less than the machine has, since the calling thread joins the step.
						numThreads = Math.Max(JobSystem.LogicalCoreCount() - 1, 1)
					};
				sPool = JPH_JobSystemThreadPool_Create(&config);
			}
			return sPool;
		}
	}

	public static void Release()
	{
		using (sLock.Enter())
		{
			if (--sUsers == 0)
			{
				if (sPool != null)
					JPH_JobSystem_Destroy(sPool);
				sPool = null;
			}
		}
	}
}
