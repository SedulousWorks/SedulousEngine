using Bulkan;
using System;
namespace VulkanTriangle;

extension VulkanTriangle
{
	private VkSwapchainKHR swapChain;
	private VkImage[] swapChainImages;
	private VkFormat swapChainImageFormat;
	private VkExtent2D swapChainExtent;

	[CRepr]
	public struct SwapChainSupportDetails : IDisposable
	{
		public VkSurfaceCapabilitiesKHR capabilities;
		public VkSurfaceFormatKHR[] formats;
		public VkPresentModeKHR[] presentModes;

		public void Dispose()
		{
			if (formats != null)
				delete formats;

			if (presentModes != null)
				delete presentModes;
		}
	}

	private void QuerySwapChainSupport(VkPhysicalDevice physicalDevice, ref SwapChainSupportDetails details)
	{
		// Capabilities
		Helpers.CheckErrors(VulkanNative.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physicalDevice, surface, &details.capabilities));

		// Formats
		uint32 formatCount = 0;
		VkResult result = VulkanNative.vkGetPhysicalDeviceSurfaceFormatsKHR(physicalDevice, surface, &formatCount, null);
		Helpers.CheckErrors(result);

		if (formatCount != 0)
		{
			details.formats = new VkSurfaceFormatKHR[formatCount];
			Helpers.CheckErrors(VulkanNative.vkGetPhysicalDeviceSurfaceFormatsKHR(physicalDevice, surface, &formatCount, details.formats.Ptr));
		}

		// Present Modes
		uint32 presentModeCount = 0;
		Helpers.CheckErrors(VulkanNative.vkGetPhysicalDeviceSurfacePresentModesKHR(physicalDevice, surface, &presentModeCount, null));

		if (presentModeCount != 0)
		{
			details.presentModes = new VkPresentModeKHR[presentModeCount];
			Helpers.CheckErrors(VulkanNative.vkGetPhysicalDeviceSurfacePresentModesKHR(physicalDevice, surface, &presentModeCount, details.presentModes.Ptr));
		}

		//return details;
	}

	private VkSurfaceFormatKHR ChooseSwapSurfaceFormat(VkSurfaceFormatKHR[] availableFormats)
	{
		for (var availableFormat in availableFormats)
		{
			if (availableFormat.format == VkFormat.VK_FORMAT_B8G8R8A8_SRGB && availableFormat.colorSpace == VkColorSpaceKHR.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR)
			{
				return availableFormat;
			}
		}

		return availableFormats[0];
	}

	private VkPresentModeKHR ChooseSwapPresentMode(VkPresentModeKHR[] availablePresentModes)
	{
		for (var availablePresentMode in availablePresentModes)
		{
			if (availablePresentMode == VkPresentModeKHR.VK_PRESENT_MODE_MAILBOX_KHR)
			{
				return availablePresentMode;
			}
		}

		return VkPresentModeKHR.VK_PRESENT_MODE_FIFO_KHR;
	}

	VkExtent2D ChooseSwapExtent(VkSurfaceCapabilitiesKHR capabilities)
	{
		if (capabilities.currentExtent.width != uint32.MaxValue)
		{
			return capabilities.currentExtent;
		}
		else
		{
			VkExtent2D actualExtent = VkExtent2D(WIDTH, HEIGHT);

			actualExtent.width = Math.Max(capabilities.minImageExtent.width, Math.Min(capabilities.maxImageExtent.width, actualExtent.width));
			actualExtent.height = Math.Max(capabilities.minImageExtent.height, Math.Min(capabilities.maxImageExtent.height, actualExtent.height));

			return actualExtent;
		}
	}

	private void CreateSwapChain()
	{
		// Create SwapChain
		SwapChainSupportDetails swapChainSupport = .();
		defer swapChainSupport.Dispose();

		this.QuerySwapChainSupport(this.physicalDevice, ref swapChainSupport);

		VkSurfaceFormatKHR surfaceFormat = this.ChooseSwapSurfaceFormat(swapChainSupport.formats);
		VkPresentModeKHR presentMode = this.ChooseSwapPresentMode(swapChainSupport.presentModes);
		VkExtent2D extent = this.ChooseSwapExtent(swapChainSupport.capabilities);

		uint32 imageCount = swapChainSupport.capabilities.minImageCount + 1;
		if (swapChainSupport.capabilities.maxImageCount > 0 && imageCount > swapChainSupport.capabilities.maxImageCount)
		{
			imageCount = swapChainSupport.capabilities.maxImageCount;
		}

		VkSwapchainCreateInfoKHR createInfo = .();
		createInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
		createInfo.surface = surface;
		createInfo.minImageCount = imageCount;
		createInfo.imageFormat = surfaceFormat.format;
		createInfo.imageColorSpace = surfaceFormat.colorSpace;
		createInfo.imageExtent = extent;
		createInfo.imageArrayLayers = 1;
		createInfo.imageUsage = VkImageUsageFlags.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;

		QueueFamilyIndices indices = this.FindQueueFamilies(this.physicalDevice);
		uint32[?] queueFamilyIndices = .(indices.graphicsFamily.Value, indices.presentFamily.Value);

		if (indices.graphicsFamily != indices.presentFamily)
		{
			createInfo.imageSharingMode = VkSharingMode.VK_SHARING_MODE_CONCURRENT;
			createInfo.queueFamilyIndexCount = queueFamilyIndices.Count;
			createInfo.pQueueFamilyIndices = &queueFamilyIndices;
		}
		else
		{
			createInfo.imageSharingMode = VkSharingMode.VK_SHARING_MODE_EXCLUSIVE;
			createInfo.queueFamilyIndexCount = 0; //Optional
			createInfo.pQueueFamilyIndices = null; //Optional
		}
		createInfo.preTransform = swapChainSupport.capabilities.currentTransform;
		createInfo.compositeAlpha = VkCompositeAlphaFlagsKHR.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
		createInfo.presentMode = presentMode;
		createInfo.clipped = true;
		createInfo.oldSwapchain = 0;

		Helpers.CheckErrors(VulkanNative.vkCreateSwapchainKHR(device, &createInfo, null, &swapChain));

		// SwapChain Images
		VulkanNative.vkGetSwapchainImagesKHR(device, swapChain, &imageCount, null);
		this.swapChainImages = new VkImage[imageCount];
		VulkanNative.vkGetSwapchainImagesKHR(device, swapChain, &imageCount, this.swapChainImages.Ptr);

		this.swapChainImageFormat = surfaceFormat.format;
		this.swapChainExtent = extent;
	}
}