using System;

namespace Sedulous.RHI.WebGPU;

/// Where a device lost callback finds its device.
///
/// The callback has to be registered in the device DESCRIPTOR, which is built before the
/// request completes, so the wrapper it should mark does not exist yet. The adapter hands
/// wgpu this record instead and fills the slot once the wrapper is built.
///
/// Owned by the device, which frees it in Destroy AFTER releasing the wgpu device and
/// flushing pending callbacks - the one point where the still registered callback
/// provably cannot fire again.
class WebGpuDeviceLostRoute
{
	public WebGpuDevice Device = null;
}
