namespace Sedulous.RHI;

using System;

/// A timeline fence for CPU/GPU synchronization.
/// The fence value increases monotonically - GPU operations signal specific values,
/// and the CPU can wait for them.
///
/// Vulkan: VkSemaphore (timeline). DX12: ID3D12Fence.
/// Destroyed via IDevice.DestroyFence().
///
/// Usage:
/// ```
/// var fence = device.CreateFence(0).Value;
/// defer device.DestroyFence(ref fence);
///
/// uint64 frameValue = 1;
/// queue.Submit(.(&cmdBuf, 1), fence, frameValue);
/// fence.Wait(frameValue); // block until GPU completes
/// frameValue++;
/// ```
interface IFence
{
	/// The most recently completed value (what the GPU has signaled so far).
	uint64 CompletedValue { get; }

	/// Blocks the CPU until the fence reaches at least `value`.
	/// Returns true if the value was reached, false if the timeout expired.
	bool Wait(uint64 value, uint64 timeoutNs = uint64.MaxValue);
}
