using Bulkan;
using System;
using System.Collections;
namespace VulkanTriangle;

extension VulkanTriangle
{
	private VkPhysicalDevice physicalDevice;

	private void PickPhysicalDevice()
	{
		uint32 deviceCount = 0;
		Helpers.CheckErrors(VulkanNative.vkEnumeratePhysicalDevices(instance, &deviceCount, null));
		if (deviceCount == 0)
		{
			Runtime.FatalError("Failed to find GPUs with Vulkan support!");
		}

		VkPhysicalDevice* devices = scope VkPhysicalDevice[(int)deviceCount]*;
		Helpers.CheckErrors(VulkanNative.vkEnumeratePhysicalDevices(instance, &deviceCount, devices));

		for (int i = 0; i < (int)deviceCount; i++)
		{
			var device = devices[i];
			if (this.IsPhysicalDeviceSuitable(device))
			{
				this.physicalDevice = device;
				break;
			}
		}

		if (this.physicalDevice == default)
		{
			Runtime.FatalError("failed to find a suitable GPU!");
		}
	}

	private bool IsPhysicalDeviceSuitable(VkPhysicalDevice physicalDevice)
	{
		QueueFamilyIndices indices = this.FindQueueFamilies(physicalDevice);

		bool extensionsSupported = this.CheckPhysicalDeviceExtensionSupport(physicalDevice);

		bool swapChainAdequate = false;
		if (extensionsSupported)
		{
			using (var swapChainSupport = SwapChainSupportDetails())
			{
				this.QuerySwapChainSupport(physicalDevice, ref swapChainSupport);
				swapChainAdequate = (swapChainSupport.formats.Count != 0 && swapChainSupport.presentModes.Count != 0);
			}
		}

		return indices.IsComplete() && extensionsSupported && swapChainAdequate;
	}

	private bool CheckPhysicalDeviceExtensionSupport(VkPhysicalDevice physicalDevice)
	{
		uint32 extensionCount = 0;
		Helpers.CheckErrors(VulkanNative.vkEnumerateDeviceExtensionProperties(physicalDevice, null, &extensionCount, null));

		List<VkExtensionProperties> availableExtensions = scope .();
		availableExtensions.Count = (int)extensionCount;

		Helpers.CheckErrors(VulkanNative.vkEnumerateDeviceExtensionProperties(physicalDevice, null, &extensionCount, availableExtensions.Ptr));

		List<char8*> requiredExtensions = scope .();
		for (int i = 0; i < deviceExtensions.Count; i++)
		{
			requiredExtensions.Add(deviceExtensions[i]);
		}

		for (int i = 0; i < requiredExtensions.Count; i++)
		{
			bool found = false;
			for (int j = 0; j < availableExtensions.Count; j++)
			{
				char8* extensionName = &availableExtensions[j].extensionName;
				if (String.Equals(requiredExtensions[i], extensionName))
				{
					found = true;
					break;
				}
			}
			if (!found)
				return false;
		}
		return true;
		/*for (int i = 0; i < extensionCount; i++)
		{
			char8* extensionName = &availableExtensions[i].extensionName;
			if (requiredExtensions.Contains(extensionName))
				requiredExtensions.Remove(extensionName);
		}

		return requiredExtensions.Count == 0;*/
	}

	public struct QueueFamilyIndices
	{
		public uint32? graphicsFamily;
		public uint32? presentFamily;

		public bool IsComplete()
		{
			return graphicsFamily.HasValue && presentFamily.HasValue;
		}
	}

	private QueueFamilyIndices FindQueueFamilies(VkPhysicalDevice physicalDevice)
	{
		QueueFamilyIndices indices = default;

		uint32 queueFamilyCount = 0;
		VulkanNative.vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueFamilyCount, null);

		VkQueueFamilyProperties* queueFamilies = scope VkQueueFamilyProperties[(int)queueFamilyCount]*;
		VulkanNative.vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueFamilyCount, queueFamilies);

		for (uint32 i = 0; i < queueFamilyCount; i++)
		{
			var queueFamily = queueFamilies[i];
			if ((queueFamily.queueFlags & VkQueueFlags.VK_QUEUE_GRAPHICS_BIT) != 0)
			{
				indices.graphicsFamily = i;
			}

			VkBool32 presentSupport = false;
			Helpers.CheckErrors(VulkanNative.vkGetPhysicalDeviceSurfaceSupportKHR(physicalDevice, i, this.surface, &presentSupport));

			if (presentSupport)
			{
				indices.presentFamily = i;
			}

			if (indices.IsComplete())
			{
				break;
			}
		}

		return indices;
	}

	private bool IsDeviceSuitable(VkPhysicalDevice physicalDevice)
	{
		QueueFamilyIndices indices = this.FindQueueFamilies(physicalDevice);

		return indices.IsComplete();
	}
}