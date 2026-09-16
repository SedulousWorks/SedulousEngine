using System;
using wgpu_Beef;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A finished command buffer, waiting to be submitted.
///
/// Owns its handle until the queue TAKES it. A buffer that is never submitted releases
/// on the next adopt or at destruction, so a recorded-then-abandoned frame does not leak.
class WebGpuCommandBuffer : ICommandBuffer
{
	private WGPUCommandBuffer mHandle;

	public WGPUCommandBuffer Handle => mHandle;

	public ~this()
	{
		ReleaseHandle();
	}

	/// TAKES ownership of a finished command buffer, releasing whatever was held before.
	public void Adopt(WGPUCommandBuffer commandBuffer)
	{
		ReleaseHandle();
		mHandle = commandBuffer;
	}

	/// The queue takes the handle for submission and this wrapper forgets it, submission
	/// being what consumes a WebGPU command buffer.
	public WGPUCommandBuffer Take()
	{
		let taken = mHandle;
		mHandle = null;
		return taken;
	}

	public void ReleaseHandle()
	{
		if (mHandle != null)
		{
			wgpuCommandBufferRelease(mHandle);
			mHandle = null;
		}
	}
}
