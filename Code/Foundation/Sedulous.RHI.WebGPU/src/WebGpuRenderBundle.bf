#if !BF_PLATFORM_ANDROID
using System;
using wgpu_Beef;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A finished render bundle: pre-recorded commands a pass can replay.
///
/// Owned by the encoder that made it, which frees it at destruction.
sealed class WebGpuRenderBundle : IRenderBundle
{
	private WGPURenderBundle mHandle;
	/// What it recorded, counted each time it is executed.
	public RecordedCounts Counts;
	/// The aspects it leaves unwritten, and its label: a pass that executes it checks them
	/// (WebGPU refuses a bundle that may write an aspect the pass holds read-only).
	public bool DepthReadOnly = false;
	public bool StencilReadOnly = false;
	public String Label = new .() ~ delete _;

	public WGPURenderBundle Handle => mHandle;

	public ~this()
	{
		Release();
	}

	/// TAKES the handle.
	public void Adopt(WGPURenderBundle bundle)
	{
		Release();
		mHandle = bundle;
	}

	public void Release()
	{
		if (mHandle != null)
		{
			wgpuRenderBundleRelease(mHandle);
			mHandle = null;
		}
	}
}

#endif // !BF_PLATFORM_ANDROID
