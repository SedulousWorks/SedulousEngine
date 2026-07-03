using Bulkan;
namespace VulkanTriangle;

extension VulkanTriangle
{
	private VkSurfaceKHR surface;

	private void CreateSurface()
	{
#if BF_PLATFORM_WINDOWS 
		VkWin32SurfaceCreateInfoKHR createInfo = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR,
				hwnd = NativeWindow,
				hinstance = (void*)(int)System.Windows.GetModuleHandleA(null)
			};

		Helpers.CheckErrors(VulkanNative.vkCreateWin32SurfaceKHR(instance, &createInfo, null, &surface));
		#elif BF_PLATFORM_LINUX  
		VkXlibSurfaceCreateInfoKHR createInfo = .(){
			sType = .VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR,
			dpy = Display,
			window = NativeWindow
		};
		Helpers.CheckErrors(VulkanNative.vkCreateXlibSurfaceKHR(instance, &createInfo, null, &surface));
#else
		Runtime.FatalError("Unsupported platform.");
#endif
	}
}