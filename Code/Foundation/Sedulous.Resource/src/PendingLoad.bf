using System;
using Sedulous.Core;

namespace Sedulous.Resource;

/// One asynchronous load in flight.
///
/// Main-thread only, and heap allocated so the counter has a stable address for the job
/// system to signal.
class PendingLoad
{
	public ResourceHandle Handle;
	public Guid Id;
	/// One, until the decode job completes. A synchronous bind of this identity waits on
	/// it, which runs the decode inline if no worker has started it.
	public Counter Counter = new .(1) ~ delete _;
	/// The product is set on the main thread; the record can be reaped once it is.
	public bool Finalized;
}
