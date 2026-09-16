using System;
using System.Collections;

namespace Sedulous.RHI.WebGPU;

/// The device's ledger of live shadow backed buffers.
///
/// The queue walks it before every submit and flushes any shadow whose mapping is still
/// open, which is what makes a held pointer behave like Vulkan's coherent one. See
/// WebGpuBuffer for the whole emulation.
///
/// BORROWS every buffer in it. Single threaded, by the same contract as the rest of the
/// backend.
sealed class WebGpuBufferRegistry
{
	private List<WebGpuBuffer> mBuffers = new .() ~ delete _;

	public void Add(WebGpuBuffer buffer)
	{
		mBuffers.Add(buffer);
	}

	public void Remove(WebGpuBuffer buffer)
	{
		let index = mBuffers.IndexOf(buffer);
		if (index >= 0)
		{
			// Order carries nothing here, so the last one fills the hole.
			mBuffers[index] = mBuffers[mBuffers.Count - 1];
			mBuffers.PopBack();
		}
	}

	public void FlushOutstanding()
	{
		for (let buffer in mBuffers)
			buffer.FlushShadowIfOutstanding();
	}
}
