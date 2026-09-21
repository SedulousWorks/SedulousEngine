using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// The pool, which is bookkeeping rather than a pool.
///
/// WebGPU has no pool object: encoders come straight from the device and are one shot.
/// So this OWNS the encoder wrappers it hands out and frees them at destruction, and
/// Reset does nothing, each wrapper already opening a fresh encoder after it finishes.
sealed class WebGpuCommandPool : ICommandPool
{
	private WGPUDevice mDevice;
	/// BORROWED: the device owns it and it outlives every pool.
	private WebGpuBlitHelper mBlitHelper;

	private List<WebGpuCommandEncoder> mEncoders = new .() ~ DeleteContainerAndItems!(_);
	private List<WebGpuRenderBundleEncoder> mBundleEncoders = new .() ~ DeleteContainerAndItems!(_);

	public void Initialize(WGPUDevice device, WebGpuBlitHelper blitHelper)
	{
		mDevice = device;
		mBlitHelper = blitHelper;
	}

	public Result<ICommandEncoder> CreateEncoder()
	{
		let encoder = new WebGpuCommandEncoder();
		encoder.Initialize(mDevice, mBlitHelper);
		mEncoders.Add(encoder);
		return .Ok(encoder);
	}

	public void DestroyEncoder(ref ICommandEncoder encoder)
	{
		if (encoder == null)
			return;

		if (let wrapped = encoder as WebGpuCommandEncoder)
		{
			let index = mEncoders.IndexOf(wrapped);
			if (index >= 0)
			{
				// Order carries nothing here, so the last one fills the hole.
				mEncoders[index] = mEncoders[mEncoders.Count - 1];
				mEncoders.PopBack();
			}

			delete wrapped;
		}

		encoder = null;
	}

	/// Nothing to recycle: a one shot encoder re-opens lazily.
	public void Reset()
	{
		// The ENCODERS are not freed here, matching the Vulkan pool: a caller may reset and
		// then destroy an encoder it still holds, and freeing them here would make that a
		// use after free. Each one already re-opens a fresh WGPUCommandEncoder after Finish,
		// so there is nothing to recycle for them.
		//
		// The BUNDLE ENCODERS are. The renderer's parallel emit mints one per worker pool
		// EVERY frame and relies on this reset to reclaim it - "the pool never holds an open
		// primary list and its per frame reset stays legal on every backend", as ForwardPass
		// puts it. A pool that reset nothing would accumulate those for its whole life,
		// holding a finished WGPURenderBundle each and, through it, every resource that
		// bundle referenced. Vulkan's pool has always reclaimed them here.
		ClearAndDeleteItems!(mBundleEncoders);
	}

	public IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc)
	{
		let encoder = new WebGpuRenderBundleEncoder();
		if (encoder.Initialize(mDevice, desc) case .Err)
		{
			delete encoder;
			return null;
		}

		mBundleEncoders.Add(encoder);
		return encoder;
	}
}
