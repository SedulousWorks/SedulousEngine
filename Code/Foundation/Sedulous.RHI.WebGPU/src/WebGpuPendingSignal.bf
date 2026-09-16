using System;

namespace Sedulous.RHI.WebGPU;

/// One queued work-done signal, owned by the callback that frees it.
///
/// It can be delivered LONG after the fence already resolved by submission index, which
/// is Wait's fast path, and that includes during device teardown after the fence itself
/// is gone. So the record OUTLIVES the fence: the fence severs every record it still
/// holds when it is destroyed, and the callback only touches Fence while it is still
/// attached.
class WebGpuPendingSignal
{
	/// Null once the fence has been destroyed, which is the callback's signal to do
	/// nothing but free this.
	public WebGpuFence Fence;
	public uint64 Value;
}
