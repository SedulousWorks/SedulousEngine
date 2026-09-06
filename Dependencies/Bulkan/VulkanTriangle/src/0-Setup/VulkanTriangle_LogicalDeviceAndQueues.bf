using Bulkan;
using System.Collections;
namespace VulkanTriangle;

extension VulkanTriangle
{
	char8*[?] deviceExtensions = .("VK_KHR_swapchain");

	private VkDevice device;
	private VkQueue graphicsQueue;
	private VkQueue presentQueue;

	private void CreateLogicalDevice()
	{
		QueueFamilyIndices indices = this.FindQueueFamilies(physicalDevice);

		List<VkDeviceQueueCreateInfo> queueCreateInfos = scope .();
		HashSet<uint> uniqueQueueFamilies = scope .() { indices.graphicsFamily.Value, indices.presentFamily.Value };

		float queuePriority = 1.0f;
		for (uint32 queueFamily in uniqueQueueFamilies)
		{
			VkDeviceQueueCreateInfo queueCreateInfo = .()
				{
					sType = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
					queueFamilyIndex = queueFamily,
					queueCount = 1,
					pQueuePriorities = &queuePriority
				};
			queueCreateInfos.Add(queueCreateInfo);
		}

		VkPhysicalDeviceFeatures deviceFeatures = .();

		VkDeviceCreateInfo createInfo = .();
		createInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;

		VkDeviceQueueCreateInfo* queueCreateInfosArrayPtr = &queueCreateInfos[0];
		{
			createInfo.queueCreateInfoCount = (uint32)queueCreateInfos.Count;
			createInfo.pQueueCreateInfos = queueCreateInfosArrayPtr;
		}

		createInfo.pEnabledFeatures = &deviceFeatures;
		createInfo.enabledExtensionCount = (uint)deviceExtensions.Count;
		createInfo.ppEnabledExtensionNames = &deviceExtensions;

		Helpers.CheckErrors(VulkanNative.vkCreateDevice(physicalDevice, &createInfo, null, &device));
		VulkanNative.vkGetDeviceQueue(device, indices.graphicsFamily.Value, 0, &graphicsQueue);
		VulkanNative.vkGetDeviceQueue(device, indices.presentFamily.Value, 0, &presentQueue); // TODO queue index 0 ?¿?¿
	}
}
