using Bulkan;
using System;
namespace VulkanTriangle;

extension VulkanTriangle
{
	private VkInstance instance;
	char8*[?] validationLayers = .("VK_LAYER_KHRONOS_validation");

	char8*[?] extensions = .
		(
		"VK_KHR_surface",
	#if BF_PLATFORM_WINDOWS 
		"VK_KHR_win32_surface",
#endif

#if BF_PLATFORM_LINUX 
		"VK_KHR_xlib_surface",
#endif
		"VK_EXT_debug_utils",
		VulkanNative.VK_EXT_DEBUG_REPORT_EXTENSION_NAME
		);

	private void CreateInstance()
	{
		VulkanNative.Initialize();
		VulkanNative.LoadPreInstanceFunctions();

		VkApplicationInfo appInfo = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_APPLICATION_INFO,
				pApplicationName = "Vulkan Triangle",
				applicationVersion = Helpers.Version(1, 0, 0),
				pEngineName = "No Engine",
				engineVersion = Helpers.Version(1, 0, 0),
				apiVersion = Helpers.Version(1, 2, 0)
			};

		VkInstanceCreateInfo createInfo = .();
		createInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
		createInfo.pApplicationInfo = &appInfo;

		// Extensions
		this.GetAllInstanceExtensionsAvailables();
		createInfo.enabledExtensionCount = (uint32)extensions.Count;
		createInfo.ppEnabledExtensionNames = &extensions;

		// Validation layers
#if DEBUG
		if (this.CheckValidationLayerSupport())
		{
			createInfo.enabledLayerCount = (uint32)validationLayers.Count;
			createInfo.ppEnabledLayerNames = &validationLayers;
		}
		else
		{
			createInfo.enabledLayerCount = 0;
			createInfo.pNext = null;
		}
#else
		createInfo.enabledLayerCount = 0;
		createInfo.pNext = null;
#endif


		Helpers.CheckErrors(VulkanNative.vkCreateInstance(&createInfo, null, &instance));
		InstanceFunctionFlags instanceFlags = .Agnostic;

#if BF_PLATFORM_WINDOWS 
		instanceFlags |= .Win32;
#endif

#if BF_PLATFORM_LINUX 
		instanceFlags |= .Xlib;
#endif

		VulkanNative.LoadInstanceFunctions(instance, instanceFlags, null, scope (func) =>
			{
				Console.WriteLine(scope $"Failed to load function '{func}'.");
			}).IgnoreError();

		VulkanNative.LoadPostInstanceFunctions();
	}

	private void GetAllInstanceExtensionsAvailables()
	{
		uint32 extensionCount = 0;
		Helpers.CheckErrors(VulkanNative.vkEnumerateInstanceExtensionProperties(null, &extensionCount, null));
		VkExtensionProperties[] availableExtensions = scope VkExtensionProperties[(int)extensionCount](?);
		Helpers.CheckErrors(VulkanNative.vkEnumerateInstanceExtensionProperties(null, &extensionCount, availableExtensions.Ptr));

		for (int i = 0; i < (int)extensionCount; i++)
		{
			Console.WriteLine($"Extension: {availableExtensions[i].extensionName} version: {availableExtensions[i].specVersion}");
		}

		// Return
		//Extension: VK_KHR_device_group_creation version: 1
		//Extension: VK_KHR_external_fence_capabilities version: 1
		//Extension: VK_KHR_external_memory_capabilities version: 1
		//Extension: VK_KHR_external_semaphore_capabilities version: 1
		//Extension: VK_KHR_get_physical_device_properties2 version: 2
		//Extension: VK_KHR_get_surface_capabilities2 version: 1
		//Extension: VK_KHR_surface version: 25
		//Extension: VK_KHR_surface_protected_capabilities version: 1
		//Extension: VK_KHR_win32_surface version: 6
		//Extension: VK_EXT_debug_report version: 9
		//Extension: VK_EXT_debug_utils version: 2
		//Extension: VK_EXT_swapchain_colorspace version: 4
		//Extension: VK_NV_external_memory_capabilities version: 1
	}
}