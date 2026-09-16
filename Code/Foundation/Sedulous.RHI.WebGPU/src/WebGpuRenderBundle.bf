using System;
using wgpu_Beef;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A finished render bundle: pre-recorded commands a pass can replay.
///
/// Owned by the encoder that made it, which frees it at destruction.
class WebGpuRenderBundle : IRenderBundle
{
	private WGPURenderBundle mHandle;

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
