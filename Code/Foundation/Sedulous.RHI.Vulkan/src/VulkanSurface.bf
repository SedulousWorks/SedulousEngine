using Bulkan;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A presentable surface over a native window.
class VulkanSurface : ISurface
{
	private VkSurfaceKHR mSurface;
	private VkInstance mInstance;

	public this(VkSurfaceKHR surface, VkInstance instance)
	{
		mSurface = surface;
		mInstance = instance;
	}

	public VkSurfaceKHR Handle => mSurface;
	public VkInstance Instance => mInstance;

	/// Destroys the surface. Owned by the BACKEND, which created it and outlives every
	/// swap chain built on it.
	public void Destroy()
	{
		if (mSurface != .Null)
		{
			VulkanNative.vkDestroySurfaceKHR(mInstance, mSurface, null);
			mSurface = .Null;
		}
	}
}
