using System;
using Sedulous.Core;

namespace Sedulous.Resource;

/// One asynchronous load in flight.
///
/// Main-thread only.
class PendingLoad
{
	public ResourceHandle Handle;
	public Guid Id;
	/// The decode, ended once its result is queued: a reference of ours. A synchronous bind of
	/// this identity waits on it, which a pool of no workers runs there.
	public TaskHandle Task = null ~ _?.ReleaseRef();
	/// The product is set on the main thread; the record can be reaped once it is.
	public bool Finalized;
}
