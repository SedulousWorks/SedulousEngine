namespace Sedulous.RHI.Vulkan;

using Bulkan;

/// Vulkan implementation of ISurface.
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

	public void Destroy()
	{
		if (mSurface.Handle != 0)
		{
			VulkanNative.vkDestroySurfaceKHR(mInstance, mSurface, null);
			mSurface = .Null;
		}
	}
}
