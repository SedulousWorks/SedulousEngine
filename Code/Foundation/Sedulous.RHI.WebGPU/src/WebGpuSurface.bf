using System;
using wgpu_Beef;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A WebGPU surface: the window the swapchain will present to.
///
/// Owns the handle it is given. The backend makes these and keeps them, because a
/// surface outlives the swapchain built on it.
class WebGpuSurface : ISurface
{
	private WGPUSurface mHandle;

	public WGPUSurface Handle => mHandle;

	/// TAKES the handle. Releasing it is this object's job from here.
	public this(WGPUSurface handle)
	{
		mHandle = handle;
	}

	public ~this()
	{
		if (mHandle != null)
		{
			wgpuSurfaceRelease(mHandle);
			mHandle = null;
		}
	}
}
