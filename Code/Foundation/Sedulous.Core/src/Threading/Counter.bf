using System;
using System.Collections;
using System.Threading;

namespace Sedulous.Core;

/// A completion counter. Jobs signal it by decrementing on completion, and may depend on
/// it by running only once it reaches zero.
///
/// Caller-owned: keep it alive until it reaches zero AND every wait or continuation on it
/// has finished. A stack local in the frame loop is the usual shape.
///
/// Caller-SEEDED too. Submit does not add to it, so construct it with the number of jobs
/// about to be submitted against it. Seeding it below that count makes a wait return while
/// jobs are still running; above it, the wait never ends.
class Counter
{
	private volatile int32 mCount;
	private Monitor mLock = new .() ~ delete _;
	private List<JobItem> mContinuations = new .() ~ delete _;

	public this(int32 initial = 0)
	{
		mCount = initial;
	}

	public int32 Value => mCount;
}
