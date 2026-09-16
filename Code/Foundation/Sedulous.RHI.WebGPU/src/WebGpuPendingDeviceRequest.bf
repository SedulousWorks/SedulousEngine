using System;
using wgpu_Beef;

namespace Sedulous.RHI.WebGPU;

/// The in flight record for one RequestDevice.
///
/// A HEAP record rather than a stack one, for the same reason WebGpuPendingSignal is: the
/// callback stays registered after the pump gives up, and would otherwise write through a
/// dead frame. When the waiter gives up it sets Orphaned, and the callback frees this and
/// releases whatever device it was handed, nobody else being left to.
sealed class WebGpuPendingDeviceRequest
{
	public WGPUDevice Device = null;
	public bool Done = false;
	/// The waiter gave up; the callback owns deletion.
	public bool Orphaned = false;
}
