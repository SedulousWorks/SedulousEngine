using System;
using System.Collections;
using internal Bulkan;
namespace Bulkan;

public extension VulkanNative
{
	public typealias vkCreateInstanceFunction = function VkResult(VkInstanceCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkInstance* pInstance);
	private static vkCreateInstanceFunction vkCreateInstance_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateInstance(VkInstanceCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkInstance* pInstance)
		=> vkCreateInstance_ptr(pCreateInfo, pAllocator, pInstance);

	public typealias vkDestroyInstanceFunction = function void(VkInstance instance, VkAllocationCallbacks* pAllocator);
	private static vkDestroyInstanceFunction vkDestroyInstance_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyInstance(VkInstance instance, VkAllocationCallbacks* pAllocator)
		=> vkDestroyInstance_ptr(instance, pAllocator);

	public typealias vkEnumeratePhysicalDevicesFunction = function VkResult(VkInstance instance, uint32* pPhysicalDeviceCount, VkPhysicalDevice* pPhysicalDevices);
	private static vkEnumeratePhysicalDevicesFunction vkEnumeratePhysicalDevices_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkEnumeratePhysicalDevices(VkInstance instance, uint32* pPhysicalDeviceCount, VkPhysicalDevice* pPhysicalDevices)
		=> vkEnumeratePhysicalDevices_ptr(instance, pPhysicalDeviceCount, pPhysicalDevices);

	public typealias vkGetPhysicalDeviceFeaturesFunction = function void(VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures* pFeatures);
	private static vkGetPhysicalDeviceFeaturesFunction vkGetPhysicalDeviceFeatures_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceFeatures(VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures* pFeatures)
		=> vkGetPhysicalDeviceFeatures_ptr(physicalDevice, pFeatures);

	public typealias vkGetPhysicalDeviceFormatPropertiesFunction = function void(VkPhysicalDevice physicalDevice, VkFormat format, VkFormatProperties* pFormatProperties);
	private static vkGetPhysicalDeviceFormatPropertiesFunction vkGetPhysicalDeviceFormatProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceFormatProperties(VkPhysicalDevice physicalDevice, VkFormat format, VkFormatProperties* pFormatProperties)
		=> vkGetPhysicalDeviceFormatProperties_ptr(physicalDevice, format, pFormatProperties);

	public typealias vkGetPhysicalDeviceImageFormatPropertiesFunction = function VkResult(VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkImageTiling tiling, VkImageUsageFlags usage, VkImageCreateFlags flags, VkImageFormatProperties* pImageFormatProperties);
	private static vkGetPhysicalDeviceImageFormatPropertiesFunction vkGetPhysicalDeviceImageFormatProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceImageFormatProperties(VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkImageTiling tiling, VkImageUsageFlags usage, VkImageCreateFlags flags, VkImageFormatProperties* pImageFormatProperties)
		=> vkGetPhysicalDeviceImageFormatProperties_ptr(physicalDevice, format, type, tiling, usage, flags, pImageFormatProperties);

	public typealias vkGetPhysicalDevicePropertiesFunction = function void(VkPhysicalDevice physicalDevice, VkPhysicalDeviceProperties* pProperties);
	private static vkGetPhysicalDevicePropertiesFunction vkGetPhysicalDeviceProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceProperties(VkPhysicalDevice physicalDevice, VkPhysicalDeviceProperties* pProperties)
		=> vkGetPhysicalDeviceProperties_ptr(physicalDevice, pProperties);

	public typealias vkGetPhysicalDeviceQueueFamilyPropertiesFunction = function void(VkPhysicalDevice physicalDevice, uint32* pQueueFamilyPropertyCount, VkQueueFamilyProperties* pQueueFamilyProperties);
	private static vkGetPhysicalDeviceQueueFamilyPropertiesFunction vkGetPhysicalDeviceQueueFamilyProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceQueueFamilyProperties(VkPhysicalDevice physicalDevice, uint32* pQueueFamilyPropertyCount, VkQueueFamilyProperties* pQueueFamilyProperties)
		=> vkGetPhysicalDeviceQueueFamilyProperties_ptr(physicalDevice, pQueueFamilyPropertyCount, pQueueFamilyProperties);

	public typealias vkGetPhysicalDeviceMemoryPropertiesFunction = function void(VkPhysicalDevice physicalDevice, VkPhysicalDeviceMemoryProperties* pMemoryProperties);
	private static vkGetPhysicalDeviceMemoryPropertiesFunction vkGetPhysicalDeviceMemoryProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceMemoryProperties(VkPhysicalDevice physicalDevice, VkPhysicalDeviceMemoryProperties* pMemoryProperties)
		=> vkGetPhysicalDeviceMemoryProperties_ptr(physicalDevice, pMemoryProperties);

	public typealias vkGetInstanceProcAddrFunction = function void*(VkInstance instance, char8* pName);
	private static vkGetInstanceProcAddrFunction vkGetInstanceProcAddr_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void* vkGetInstanceProcAddr(VkInstance instance, char8* pName)
		=> vkGetInstanceProcAddr_ptr(instance, pName);

	public typealias vkGetDeviceProcAddrFunction = function void*(VkDevice device, char8* pName);
	private static vkGetDeviceProcAddrFunction vkGetDeviceProcAddr_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void* vkGetDeviceProcAddr(VkDevice device, char8* pName)
		=> vkGetDeviceProcAddr_ptr(device, pName);

	public typealias vkCreateDeviceFunction = function VkResult(VkPhysicalDevice physicalDevice, VkDeviceCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDevice* pDevice);
	private static vkCreateDeviceFunction vkCreateDevice_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateDevice(VkPhysicalDevice physicalDevice, VkDeviceCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDevice* pDevice)
		=> vkCreateDevice_ptr(physicalDevice, pCreateInfo, pAllocator, pDevice);

	public typealias vkDestroyDeviceFunction = function void(VkDevice device, VkAllocationCallbacks* pAllocator);
	private static vkDestroyDeviceFunction vkDestroyDevice_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyDevice(VkDevice device, VkAllocationCallbacks* pAllocator)
		=> vkDestroyDevice_ptr(device, pAllocator);

	public typealias vkEnumerateInstanceExtensionPropertiesFunction = function VkResult(char8* pLayerName, uint32* pPropertyCount, VkExtensionProperties* pProperties);
	private static vkEnumerateInstanceExtensionPropertiesFunction vkEnumerateInstanceExtensionProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkEnumerateInstanceExtensionProperties(char8* pLayerName, uint32* pPropertyCount, VkExtensionProperties* pProperties)
		=> vkEnumerateInstanceExtensionProperties_ptr(pLayerName, pPropertyCount, pProperties);

	public typealias vkEnumerateDeviceExtensionPropertiesFunction = function VkResult(VkPhysicalDevice physicalDevice, char8* pLayerName, uint32* pPropertyCount, VkExtensionProperties* pProperties);
	private static vkEnumerateDeviceExtensionPropertiesFunction vkEnumerateDeviceExtensionProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkEnumerateDeviceExtensionProperties(VkPhysicalDevice physicalDevice, char8* pLayerName, uint32* pPropertyCount, VkExtensionProperties* pProperties)
		=> vkEnumerateDeviceExtensionProperties_ptr(physicalDevice, pLayerName, pPropertyCount, pProperties);

	public typealias vkEnumerateInstanceLayerPropertiesFunction = function VkResult(uint32* pPropertyCount, VkLayerProperties* pProperties);
	private static vkEnumerateInstanceLayerPropertiesFunction vkEnumerateInstanceLayerProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkEnumerateInstanceLayerProperties(uint32* pPropertyCount, VkLayerProperties* pProperties)
		=> vkEnumerateInstanceLayerProperties_ptr(pPropertyCount, pProperties);

	public typealias vkEnumerateDeviceLayerPropertiesFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkLayerProperties* pProperties);
	private static vkEnumerateDeviceLayerPropertiesFunction vkEnumerateDeviceLayerProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkEnumerateDeviceLayerProperties(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkLayerProperties* pProperties)
		=> vkEnumerateDeviceLayerProperties_ptr(physicalDevice, pPropertyCount, pProperties);

	public typealias vkGetDeviceQueueFunction = function void(VkDevice device, uint32 queueFamilyIndex, uint32 queueIndex, VkQueue* pQueue);
	private static vkGetDeviceQueueFunction vkGetDeviceQueue_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDeviceQueue(VkDevice device, uint32 queueFamilyIndex, uint32 queueIndex, VkQueue* pQueue)
		=> vkGetDeviceQueue_ptr(device, queueFamilyIndex, queueIndex, pQueue);

	public typealias vkQueueSubmitFunction = function VkResult(VkQueue queue, uint32 submitCount, VkSubmitInfo* pSubmits, VkFence fence);
	private static vkQueueSubmitFunction vkQueueSubmit_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkQueueSubmit(VkQueue queue, uint32 submitCount, VkSubmitInfo* pSubmits, VkFence fence)
		=> vkQueueSubmit_ptr(queue, submitCount, pSubmits, fence);

	public typealias vkQueueWaitIdleFunction = function VkResult(VkQueue queue);
	private static vkQueueWaitIdleFunction vkQueueWaitIdle_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkQueueWaitIdle(VkQueue queue)
		=> vkQueueWaitIdle_ptr(queue);

	public typealias vkDeviceWaitIdleFunction = function VkResult(VkDevice device);
	private static vkDeviceWaitIdleFunction vkDeviceWaitIdle_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkDeviceWaitIdle(VkDevice device)
		=> vkDeviceWaitIdle_ptr(device);

	public typealias vkAllocateMemoryFunction = function VkResult(VkDevice device, VkMemoryAllocateInfo* pAllocateInfo, VkAllocationCallbacks* pAllocator, VkDeviceMemory* pMemory);
	private static vkAllocateMemoryFunction vkAllocateMemory_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkAllocateMemory(VkDevice device, VkMemoryAllocateInfo* pAllocateInfo, VkAllocationCallbacks* pAllocator, VkDeviceMemory* pMemory)
		=> vkAllocateMemory_ptr(device, pAllocateInfo, pAllocator, pMemory);

	public typealias vkFreeMemoryFunction = function void(VkDevice device, VkDeviceMemory memory, VkAllocationCallbacks* pAllocator);
	private static vkFreeMemoryFunction vkFreeMemory_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkFreeMemory(VkDevice device, VkDeviceMemory memory, VkAllocationCallbacks* pAllocator)
		=> vkFreeMemory_ptr(device, memory, pAllocator);

	public typealias vkMapMemoryFunction = function VkResult(VkDevice device, VkDeviceMemory memory, uint64 offset, uint64 size, VkMemoryMapFlags flags, void** ppData);
	private static vkMapMemoryFunction vkMapMemory_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkMapMemory(VkDevice device, VkDeviceMemory memory, uint64 offset, uint64 size, VkMemoryMapFlags flags, void** ppData)
		=> vkMapMemory_ptr(device, memory, offset, size, flags, ppData);

	public typealias vkUnmapMemoryFunction = function void(VkDevice device, VkDeviceMemory memory);
	private static vkUnmapMemoryFunction vkUnmapMemory_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkUnmapMemory(VkDevice device, VkDeviceMemory memory)
		=> vkUnmapMemory_ptr(device, memory);

	public typealias vkFlushMappedMemoryRangesFunction = function VkResult(VkDevice device, uint32 memoryRangeCount, VkMappedMemoryRange* pMemoryRanges);
	private static vkFlushMappedMemoryRangesFunction vkFlushMappedMemoryRanges_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkFlushMappedMemoryRanges(VkDevice device, uint32 memoryRangeCount, VkMappedMemoryRange* pMemoryRanges)
		=> vkFlushMappedMemoryRanges_ptr(device, memoryRangeCount, pMemoryRanges);

	public typealias vkInvalidateMappedMemoryRangesFunction = function VkResult(VkDevice device, uint32 memoryRangeCount, VkMappedMemoryRange* pMemoryRanges);
	private static vkInvalidateMappedMemoryRangesFunction vkInvalidateMappedMemoryRanges_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkInvalidateMappedMemoryRanges(VkDevice device, uint32 memoryRangeCount, VkMappedMemoryRange* pMemoryRanges)
		=> vkInvalidateMappedMemoryRanges_ptr(device, memoryRangeCount, pMemoryRanges);

	public typealias vkGetDeviceMemoryCommitmentFunction = function void(VkDevice device, VkDeviceMemory memory, uint64* pCommittedMemoryInBytes);
	private static vkGetDeviceMemoryCommitmentFunction vkGetDeviceMemoryCommitment_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDeviceMemoryCommitment(VkDevice device, VkDeviceMemory memory, uint64* pCommittedMemoryInBytes)
		=> vkGetDeviceMemoryCommitment_ptr(device, memory, pCommittedMemoryInBytes);

	public typealias vkBindBufferMemoryFunction = function VkResult(VkDevice device, VkBuffer buffer, VkDeviceMemory memory, uint64 memoryOffset);
	private static vkBindBufferMemoryFunction vkBindBufferMemory_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkBindBufferMemory(VkDevice device, VkBuffer buffer, VkDeviceMemory memory, uint64 memoryOffset)
		=> vkBindBufferMemory_ptr(device, buffer, memory, memoryOffset);

	public typealias vkBindImageMemoryFunction = function VkResult(VkDevice device, VkImage image, VkDeviceMemory memory, uint64 memoryOffset);
	private static vkBindImageMemoryFunction vkBindImageMemory_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkBindImageMemory(VkDevice device, VkImage image, VkDeviceMemory memory, uint64 memoryOffset)
		=> vkBindImageMemory_ptr(device, image, memory, memoryOffset);

	public typealias vkGetBufferMemoryRequirementsFunction = function void(VkDevice device, VkBuffer buffer, VkMemoryRequirements* pMemoryRequirements);
	private static vkGetBufferMemoryRequirementsFunction vkGetBufferMemoryRequirements_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetBufferMemoryRequirements(VkDevice device, VkBuffer buffer, VkMemoryRequirements* pMemoryRequirements)
		=> vkGetBufferMemoryRequirements_ptr(device, buffer, pMemoryRequirements);

	public typealias vkGetImageMemoryRequirementsFunction = function void(VkDevice device, VkImage image, VkMemoryRequirements* pMemoryRequirements);
	private static vkGetImageMemoryRequirementsFunction vkGetImageMemoryRequirements_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetImageMemoryRequirements(VkDevice device, VkImage image, VkMemoryRequirements* pMemoryRequirements)
		=> vkGetImageMemoryRequirements_ptr(device, image, pMemoryRequirements);

	public typealias vkGetImageSparseMemoryRequirementsFunction = function void(VkDevice device, VkImage image, uint32* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements* pSparseMemoryRequirements);
	private static vkGetImageSparseMemoryRequirementsFunction vkGetImageSparseMemoryRequirements_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetImageSparseMemoryRequirements(VkDevice device, VkImage image, uint32* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements* pSparseMemoryRequirements)
		=> vkGetImageSparseMemoryRequirements_ptr(device, image, pSparseMemoryRequirementCount, pSparseMemoryRequirements);

	public typealias vkGetPhysicalDeviceSparseImageFormatPropertiesFunction = function void(VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkSampleCountFlags samples, VkImageUsageFlags usage, VkImageTiling tiling, uint32* pPropertyCount, VkSparseImageFormatProperties* pProperties);
	private static vkGetPhysicalDeviceSparseImageFormatPropertiesFunction vkGetPhysicalDeviceSparseImageFormatProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceSparseImageFormatProperties(VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkSampleCountFlags samples, VkImageUsageFlags usage, VkImageTiling tiling, uint32* pPropertyCount, VkSparseImageFormatProperties* pProperties)
		=> vkGetPhysicalDeviceSparseImageFormatProperties_ptr(physicalDevice, format, type, samples, usage, tiling, pPropertyCount, pProperties);

	public typealias vkQueueBindSparseFunction = function VkResult(VkQueue queue, uint32 bindInfoCount, VkBindSparseInfo* pBindInfo, VkFence fence);
	private static vkQueueBindSparseFunction vkQueueBindSparse_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkQueueBindSparse(VkQueue queue, uint32 bindInfoCount, VkBindSparseInfo* pBindInfo, VkFence fence)
		=> vkQueueBindSparse_ptr(queue, bindInfoCount, pBindInfo, fence);

	public typealias vkCreateFenceFunction = function VkResult(VkDevice device, VkFenceCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkFence* pFence);
	private static vkCreateFenceFunction vkCreateFence_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateFence(VkDevice device, VkFenceCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkFence* pFence)
		=> vkCreateFence_ptr(device, pCreateInfo, pAllocator, pFence);

	public typealias vkDestroyFenceFunction = function void(VkDevice device, VkFence fence, VkAllocationCallbacks* pAllocator);
	private static vkDestroyFenceFunction vkDestroyFence_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyFence(VkDevice device, VkFence fence, VkAllocationCallbacks* pAllocator)
		=> vkDestroyFence_ptr(device, fence, pAllocator);

	public typealias vkResetFencesFunction = function VkResult(VkDevice device, uint32 fenceCount, VkFence* pFences);
	private static vkResetFencesFunction vkResetFences_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkResetFences(VkDevice device, uint32 fenceCount, VkFence* pFences)
		=> vkResetFences_ptr(device, fenceCount, pFences);

	public typealias vkGetFenceStatusFunction = function VkResult(VkDevice device, VkFence fence);
	private static vkGetFenceStatusFunction vkGetFenceStatus_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetFenceStatus(VkDevice device, VkFence fence)
		=> vkGetFenceStatus_ptr(device, fence);

	public typealias vkWaitForFencesFunction = function VkResult(VkDevice device, uint32 fenceCount, VkFence* pFences, VkBool32 waitAll, uint64 timeout);
	private static vkWaitForFencesFunction vkWaitForFences_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkWaitForFences(VkDevice device, uint32 fenceCount, VkFence* pFences, VkBool32 waitAll, uint64 timeout)
		=> vkWaitForFences_ptr(device, fenceCount, pFences, waitAll, timeout);

	public typealias vkCreateSemaphoreFunction = function VkResult(VkDevice device, VkSemaphoreCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSemaphore* pSemaphore);
	private static vkCreateSemaphoreFunction vkCreateSemaphore_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateSemaphore(VkDevice device, VkSemaphoreCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSemaphore* pSemaphore)
		=> vkCreateSemaphore_ptr(device, pCreateInfo, pAllocator, pSemaphore);

	public typealias vkDestroySemaphoreFunction = function void(VkDevice device, VkSemaphore semaphore, VkAllocationCallbacks* pAllocator);
	private static vkDestroySemaphoreFunction vkDestroySemaphore_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroySemaphore(VkDevice device, VkSemaphore semaphore, VkAllocationCallbacks* pAllocator)
		=> vkDestroySemaphore_ptr(device, semaphore, pAllocator);

	public typealias vkCreateQueryPoolFunction = function VkResult(VkDevice device, VkQueryPoolCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkQueryPool* pQueryPool);
	private static vkCreateQueryPoolFunction vkCreateQueryPool_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateQueryPool(VkDevice device, VkQueryPoolCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkQueryPool* pQueryPool)
		=> vkCreateQueryPool_ptr(device, pCreateInfo, pAllocator, pQueryPool);

	public typealias vkDestroyQueryPoolFunction = function void(VkDevice device, VkQueryPool queryPool, VkAllocationCallbacks* pAllocator);
	private static vkDestroyQueryPoolFunction vkDestroyQueryPool_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyQueryPool(VkDevice device, VkQueryPool queryPool, VkAllocationCallbacks* pAllocator)
		=> vkDestroyQueryPool_ptr(device, queryPool, pAllocator);

	public typealias vkGetQueryPoolResultsFunction = function VkResult(VkDevice device, VkQueryPool queryPool, uint32 firstQuery, uint32 queryCount, uint dataSize, void* pData, uint64 stride, VkQueryResultFlags flags);
	private static vkGetQueryPoolResultsFunction vkGetQueryPoolResults_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetQueryPoolResults(VkDevice device, VkQueryPool queryPool, uint32 firstQuery, uint32 queryCount, uint dataSize, void* pData, uint64 stride, VkQueryResultFlags flags)
		=> vkGetQueryPoolResults_ptr(device, queryPool, firstQuery, queryCount, dataSize, pData, stride, flags);

	public typealias vkCreateBufferFunction = function VkResult(VkDevice device, VkBufferCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkBuffer* pBuffer);
	private static vkCreateBufferFunction vkCreateBuffer_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateBuffer(VkDevice device, VkBufferCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkBuffer* pBuffer)
		=> vkCreateBuffer_ptr(device, pCreateInfo, pAllocator, pBuffer);

	public typealias vkDestroyBufferFunction = function void(VkDevice device, VkBuffer buffer, VkAllocationCallbacks* pAllocator);
	private static vkDestroyBufferFunction vkDestroyBuffer_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyBuffer(VkDevice device, VkBuffer buffer, VkAllocationCallbacks* pAllocator)
		=> vkDestroyBuffer_ptr(device, buffer, pAllocator);

	public typealias vkCreateImageFunction = function VkResult(VkDevice device, VkImageCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkImage* pImage);
	private static vkCreateImageFunction vkCreateImage_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateImage(VkDevice device, VkImageCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkImage* pImage)
		=> vkCreateImage_ptr(device, pCreateInfo, pAllocator, pImage);

	public typealias vkDestroyImageFunction = function void(VkDevice device, VkImage image, VkAllocationCallbacks* pAllocator);
	private static vkDestroyImageFunction vkDestroyImage_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyImage(VkDevice device, VkImage image, VkAllocationCallbacks* pAllocator)
		=> vkDestroyImage_ptr(device, image, pAllocator);

	public typealias vkGetImageSubresourceLayoutFunction = function void(VkDevice device, VkImage image, VkImageSubresource* pSubresource, VkSubresourceLayout* pLayout);
	private static vkGetImageSubresourceLayoutFunction vkGetImageSubresourceLayout_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetImageSubresourceLayout(VkDevice device, VkImage image, VkImageSubresource* pSubresource, VkSubresourceLayout* pLayout)
		=> vkGetImageSubresourceLayout_ptr(device, image, pSubresource, pLayout);

	public typealias vkCreateImageViewFunction = function VkResult(VkDevice device, VkImageViewCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkImageView* pView);
	private static vkCreateImageViewFunction vkCreateImageView_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateImageView(VkDevice device, VkImageViewCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkImageView* pView)
		=> vkCreateImageView_ptr(device, pCreateInfo, pAllocator, pView);

	public typealias vkDestroyImageViewFunction = function void(VkDevice device, VkImageView imageView, VkAllocationCallbacks* pAllocator);
	private static vkDestroyImageViewFunction vkDestroyImageView_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyImageView(VkDevice device, VkImageView imageView, VkAllocationCallbacks* pAllocator)
		=> vkDestroyImageView_ptr(device, imageView, pAllocator);

	public typealias vkCreateCommandPoolFunction = function VkResult(VkDevice device, VkCommandPoolCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCommandPool* pCommandPool);
	private static vkCreateCommandPoolFunction vkCreateCommandPool_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateCommandPool(VkDevice device, VkCommandPoolCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCommandPool* pCommandPool)
		=> vkCreateCommandPool_ptr(device, pCreateInfo, pAllocator, pCommandPool);

	public typealias vkDestroyCommandPoolFunction = function void(VkDevice device, VkCommandPool commandPool, VkAllocationCallbacks* pAllocator);
	private static vkDestroyCommandPoolFunction vkDestroyCommandPool_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyCommandPool(VkDevice device, VkCommandPool commandPool, VkAllocationCallbacks* pAllocator)
		=> vkDestroyCommandPool_ptr(device, commandPool, pAllocator);

	public typealias vkResetCommandPoolFunction = function VkResult(VkDevice device, VkCommandPool commandPool, VkCommandPoolResetFlags flags);
	private static vkResetCommandPoolFunction vkResetCommandPool_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkResetCommandPool(VkDevice device, VkCommandPool commandPool, VkCommandPoolResetFlags flags)
		=> vkResetCommandPool_ptr(device, commandPool, flags);

	public typealias vkAllocateCommandBuffersFunction = function VkResult(VkDevice device, VkCommandBufferAllocateInfo* pAllocateInfo, VkCommandBuffer* pCommandBuffers);
	private static vkAllocateCommandBuffersFunction vkAllocateCommandBuffers_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkAllocateCommandBuffers(VkDevice device, VkCommandBufferAllocateInfo* pAllocateInfo, VkCommandBuffer* pCommandBuffers)
		=> vkAllocateCommandBuffers_ptr(device, pAllocateInfo, pCommandBuffers);

	public typealias vkFreeCommandBuffersFunction = function void(VkDevice device, VkCommandPool commandPool, uint32 commandBufferCount, VkCommandBuffer* pCommandBuffers);
	private static vkFreeCommandBuffersFunction vkFreeCommandBuffers_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkFreeCommandBuffers(VkDevice device, VkCommandPool commandPool, uint32 commandBufferCount, VkCommandBuffer* pCommandBuffers)
		=> vkFreeCommandBuffers_ptr(device, commandPool, commandBufferCount, pCommandBuffers);

	public typealias vkBeginCommandBufferFunction = function VkResult(VkCommandBuffer commandBuffer, VkCommandBufferBeginInfo* pBeginInfo);
	private static vkBeginCommandBufferFunction vkBeginCommandBuffer_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkBeginCommandBuffer(VkCommandBuffer commandBuffer, VkCommandBufferBeginInfo* pBeginInfo)
		=> vkBeginCommandBuffer_ptr(commandBuffer, pBeginInfo);

	public typealias vkEndCommandBufferFunction = function VkResult(VkCommandBuffer commandBuffer);
	private static vkEndCommandBufferFunction vkEndCommandBuffer_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkEndCommandBuffer(VkCommandBuffer commandBuffer)
		=> vkEndCommandBuffer_ptr(commandBuffer);

	public typealias vkResetCommandBufferFunction = function VkResult(VkCommandBuffer commandBuffer, VkCommandBufferResetFlags flags);
	private static vkResetCommandBufferFunction vkResetCommandBuffer_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkResetCommandBuffer(VkCommandBuffer commandBuffer, VkCommandBufferResetFlags flags)
		=> vkResetCommandBuffer_ptr(commandBuffer, flags);

	public typealias vkCmdCopyBufferFunction = function void(VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkBuffer dstBuffer, uint32 regionCount, VkBufferCopy* pRegions);
	private static vkCmdCopyBufferFunction vkCmdCopyBuffer_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyBuffer(VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkBuffer dstBuffer, uint32 regionCount, VkBufferCopy* pRegions)
		=> vkCmdCopyBuffer_ptr(commandBuffer, srcBuffer, dstBuffer, regionCount, pRegions);

	public typealias vkCmdCopyImageFunction = function void(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32 regionCount, VkImageCopy* pRegions);
	private static vkCmdCopyImageFunction vkCmdCopyImage_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyImage(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32 regionCount, VkImageCopy* pRegions)
		=> vkCmdCopyImage_ptr(commandBuffer, srcImage, srcImageLayout, dstImage, dstImageLayout, regionCount, pRegions);

	public typealias vkCmdCopyBufferToImageFunction = function void(VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkImage dstImage, VkImageLayout dstImageLayout, uint32 regionCount, VkBufferImageCopy* pRegions);
	private static vkCmdCopyBufferToImageFunction vkCmdCopyBufferToImage_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyBufferToImage(VkCommandBuffer commandBuffer, VkBuffer srcBuffer, VkImage dstImage, VkImageLayout dstImageLayout, uint32 regionCount, VkBufferImageCopy* pRegions)
		=> vkCmdCopyBufferToImage_ptr(commandBuffer, srcBuffer, dstImage, dstImageLayout, regionCount, pRegions);

	public typealias vkCmdCopyImageToBufferFunction = function void(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkBuffer dstBuffer, uint32 regionCount, VkBufferImageCopy* pRegions);
	private static vkCmdCopyImageToBufferFunction vkCmdCopyImageToBuffer_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyImageToBuffer(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkBuffer dstBuffer, uint32 regionCount, VkBufferImageCopy* pRegions)
		=> vkCmdCopyImageToBuffer_ptr(commandBuffer, srcImage, srcImageLayout, dstBuffer, regionCount, pRegions);

	public typealias vkCmdUpdateBufferFunction = function void(VkCommandBuffer commandBuffer, VkBuffer dstBuffer, uint64 dstOffset, uint64 dataSize, void* pData);
	private static vkCmdUpdateBufferFunction vkCmdUpdateBuffer_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdUpdateBuffer(VkCommandBuffer commandBuffer, VkBuffer dstBuffer, uint64 dstOffset, uint64 dataSize, void* pData)
		=> vkCmdUpdateBuffer_ptr(commandBuffer, dstBuffer, dstOffset, dataSize, pData);

	public typealias vkCmdFillBufferFunction = function void(VkCommandBuffer commandBuffer, VkBuffer dstBuffer, uint64 dstOffset, uint64 size, uint32 data);
	private static vkCmdFillBufferFunction vkCmdFillBuffer_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdFillBuffer(VkCommandBuffer commandBuffer, VkBuffer dstBuffer, uint64 dstOffset, uint64 size, uint32 data)
		=> vkCmdFillBuffer_ptr(commandBuffer, dstBuffer, dstOffset, size, data);

	public typealias vkCmdPipelineBarrierFunction = function void(VkCommandBuffer commandBuffer, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, VkDependencyFlags dependencyFlags, uint32 memoryBarrierCount, VkMemoryBarrier* pMemoryBarriers, uint32 bufferMemoryBarrierCount, VkBufferMemoryBarrier* pBufferMemoryBarriers, uint32 imageMemoryBarrierCount, VkImageMemoryBarrier* pImageMemoryBarriers);
	private static vkCmdPipelineBarrierFunction vkCmdPipelineBarrier_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdPipelineBarrier(VkCommandBuffer commandBuffer, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, VkDependencyFlags dependencyFlags, uint32 memoryBarrierCount, VkMemoryBarrier* pMemoryBarriers, uint32 bufferMemoryBarrierCount, VkBufferMemoryBarrier* pBufferMemoryBarriers, uint32 imageMemoryBarrierCount, VkImageMemoryBarrier* pImageMemoryBarriers)
		=> vkCmdPipelineBarrier_ptr(commandBuffer, srcStageMask, dstStageMask, dependencyFlags, memoryBarrierCount, pMemoryBarriers, bufferMemoryBarrierCount, pBufferMemoryBarriers, imageMemoryBarrierCount, pImageMemoryBarriers);

	public typealias vkCmdBeginQueryFunction = function void(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32 query, VkQueryControlFlags flags);
	private static vkCmdBeginQueryFunction vkCmdBeginQuery_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBeginQuery(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32 query, VkQueryControlFlags flags)
		=> vkCmdBeginQuery_ptr(commandBuffer, queryPool, query, flags);

	public typealias vkCmdEndQueryFunction = function void(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32 query);
	private static vkCmdEndQueryFunction vkCmdEndQuery_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdEndQuery(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32 query)
		=> vkCmdEndQuery_ptr(commandBuffer, queryPool, query);

	public typealias vkCmdResetQueryPoolFunction = function void(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32 firstQuery, uint32 queryCount);
	private static vkCmdResetQueryPoolFunction vkCmdResetQueryPool_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdResetQueryPool(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32 firstQuery, uint32 queryCount)
		=> vkCmdResetQueryPool_ptr(commandBuffer, queryPool, firstQuery, queryCount);

	public typealias vkCmdWriteTimestampFunction = function void(VkCommandBuffer commandBuffer, VkPipelineStageFlags pipelineStage, VkQueryPool queryPool, uint32 query);
	private static vkCmdWriteTimestampFunction vkCmdWriteTimestamp_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdWriteTimestamp(VkCommandBuffer commandBuffer, VkPipelineStageFlags pipelineStage, VkQueryPool queryPool, uint32 query)
		=> vkCmdWriteTimestamp_ptr(commandBuffer, pipelineStage, queryPool, query);

	public typealias vkCmdCopyQueryPoolResultsFunction = function void(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32 firstQuery, uint32 queryCount, VkBuffer dstBuffer, uint64 dstOffset, uint64 stride, VkQueryResultFlags flags);
	private static vkCmdCopyQueryPoolResultsFunction vkCmdCopyQueryPoolResults_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyQueryPoolResults(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32 firstQuery, uint32 queryCount, VkBuffer dstBuffer, uint64 dstOffset, uint64 stride, VkQueryResultFlags flags)
		=> vkCmdCopyQueryPoolResults_ptr(commandBuffer, queryPool, firstQuery, queryCount, dstBuffer, dstOffset, stride, flags);

	public typealias vkCmdExecuteCommandsFunction = function void(VkCommandBuffer commandBuffer, uint32 commandBufferCount, VkCommandBuffer* pCommandBuffers);
	private static vkCmdExecuteCommandsFunction vkCmdExecuteCommands_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdExecuteCommands(VkCommandBuffer commandBuffer, uint32 commandBufferCount, VkCommandBuffer* pCommandBuffers)
		=> vkCmdExecuteCommands_ptr(commandBuffer, commandBufferCount, pCommandBuffers);

	public typealias vkCreateEventFunction = function VkResult(VkDevice device, VkEventCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkEvent* pEvent);
	private static vkCreateEventFunction vkCreateEvent_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateEvent(VkDevice device, VkEventCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkEvent* pEvent)
		=> vkCreateEvent_ptr(device, pCreateInfo, pAllocator, pEvent);

	public typealias vkDestroyEventFunction = function void(VkDevice device, VkEvent event, VkAllocationCallbacks* pAllocator);
	private static vkDestroyEventFunction vkDestroyEvent_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyEvent(VkDevice device, VkEvent event, VkAllocationCallbacks* pAllocator)
		=> vkDestroyEvent_ptr(device, event, pAllocator);

	public typealias vkGetEventStatusFunction = function VkResult(VkDevice device, VkEvent event);
	private static vkGetEventStatusFunction vkGetEventStatus_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetEventStatus(VkDevice device, VkEvent event)
		=> vkGetEventStatus_ptr(device, event);

	public typealias vkSetEventFunction = function VkResult(VkDevice device, VkEvent event);
	private static vkSetEventFunction vkSetEvent_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkSetEvent(VkDevice device, VkEvent event)
		=> vkSetEvent_ptr(device, event);

	public typealias vkResetEventFunction = function VkResult(VkDevice device, VkEvent event);
	private static vkResetEventFunction vkResetEvent_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkResetEvent(VkDevice device, VkEvent event)
		=> vkResetEvent_ptr(device, event);

	public typealias vkCreateBufferViewFunction = function VkResult(VkDevice device, VkBufferViewCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkBufferView* pView);
	private static vkCreateBufferViewFunction vkCreateBufferView_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateBufferView(VkDevice device, VkBufferViewCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkBufferView* pView)
		=> vkCreateBufferView_ptr(device, pCreateInfo, pAllocator, pView);

	public typealias vkDestroyBufferViewFunction = function void(VkDevice device, VkBufferView bufferView, VkAllocationCallbacks* pAllocator);
	private static vkDestroyBufferViewFunction vkDestroyBufferView_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyBufferView(VkDevice device, VkBufferView bufferView, VkAllocationCallbacks* pAllocator)
		=> vkDestroyBufferView_ptr(device, bufferView, pAllocator);

	public typealias vkCreateShaderModuleFunction = function VkResult(VkDevice device, VkShaderModuleCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkShaderModule* pShaderModule);
	private static vkCreateShaderModuleFunction vkCreateShaderModule_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateShaderModule(VkDevice device, VkShaderModuleCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkShaderModule* pShaderModule)
		=> vkCreateShaderModule_ptr(device, pCreateInfo, pAllocator, pShaderModule);

	public typealias vkDestroyShaderModuleFunction = function void(VkDevice device, VkShaderModule shaderModule, VkAllocationCallbacks* pAllocator);
	private static vkDestroyShaderModuleFunction vkDestroyShaderModule_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyShaderModule(VkDevice device, VkShaderModule shaderModule, VkAllocationCallbacks* pAllocator)
		=> vkDestroyShaderModule_ptr(device, shaderModule, pAllocator);

	public typealias vkCreatePipelineCacheFunction = function VkResult(VkDevice device, VkPipelineCacheCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkPipelineCache* pPipelineCache);
	private static vkCreatePipelineCacheFunction vkCreatePipelineCache_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreatePipelineCache(VkDevice device, VkPipelineCacheCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkPipelineCache* pPipelineCache)
		=> vkCreatePipelineCache_ptr(device, pCreateInfo, pAllocator, pPipelineCache);

	public typealias vkDestroyPipelineCacheFunction = function void(VkDevice device, VkPipelineCache pipelineCache, VkAllocationCallbacks* pAllocator);
	private static vkDestroyPipelineCacheFunction vkDestroyPipelineCache_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyPipelineCache(VkDevice device, VkPipelineCache pipelineCache, VkAllocationCallbacks* pAllocator)
		=> vkDestroyPipelineCache_ptr(device, pipelineCache, pAllocator);

	public typealias vkGetPipelineCacheDataFunction = function VkResult(VkDevice device, VkPipelineCache pipelineCache, uint* pDataSize, void* pData);
	private static vkGetPipelineCacheDataFunction vkGetPipelineCacheData_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPipelineCacheData(VkDevice device, VkPipelineCache pipelineCache, uint* pDataSize, void* pData)
		=> vkGetPipelineCacheData_ptr(device, pipelineCache, pDataSize, pData);

	public typealias vkMergePipelineCachesFunction = function VkResult(VkDevice device, VkPipelineCache dstCache, uint32 srcCacheCount, VkPipelineCache* pSrcCaches);
	private static vkMergePipelineCachesFunction vkMergePipelineCaches_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkMergePipelineCaches(VkDevice device, VkPipelineCache dstCache, uint32 srcCacheCount, VkPipelineCache* pSrcCaches)
		=> vkMergePipelineCaches_ptr(device, dstCache, srcCacheCount, pSrcCaches);

	public typealias vkCreateComputePipelinesFunction = function VkResult(VkDevice device, VkPipelineCache pipelineCache, uint32 createInfoCount, VkComputePipelineCreateInfo* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines);
	private static vkCreateComputePipelinesFunction vkCreateComputePipelines_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateComputePipelines(VkDevice device, VkPipelineCache pipelineCache, uint32 createInfoCount, VkComputePipelineCreateInfo* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines)
		=> vkCreateComputePipelines_ptr(device, pipelineCache, createInfoCount, pCreateInfos, pAllocator, pPipelines);

	public typealias vkDestroyPipelineFunction = function void(VkDevice device, VkPipeline pipeline, VkAllocationCallbacks* pAllocator);
	private static vkDestroyPipelineFunction vkDestroyPipeline_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyPipeline(VkDevice device, VkPipeline pipeline, VkAllocationCallbacks* pAllocator)
		=> vkDestroyPipeline_ptr(device, pipeline, pAllocator);

	public typealias vkCreatePipelineLayoutFunction = function VkResult(VkDevice device, VkPipelineLayoutCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkPipelineLayout* pPipelineLayout);
	private static vkCreatePipelineLayoutFunction vkCreatePipelineLayout_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreatePipelineLayout(VkDevice device, VkPipelineLayoutCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkPipelineLayout* pPipelineLayout)
		=> vkCreatePipelineLayout_ptr(device, pCreateInfo, pAllocator, pPipelineLayout);

	public typealias vkDestroyPipelineLayoutFunction = function void(VkDevice device, VkPipelineLayout pipelineLayout, VkAllocationCallbacks* pAllocator);
	private static vkDestroyPipelineLayoutFunction vkDestroyPipelineLayout_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyPipelineLayout(VkDevice device, VkPipelineLayout pipelineLayout, VkAllocationCallbacks* pAllocator)
		=> vkDestroyPipelineLayout_ptr(device, pipelineLayout, pAllocator);

	public typealias vkCreateSamplerFunction = function VkResult(VkDevice device, VkSamplerCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSampler* pSampler);
	private static vkCreateSamplerFunction vkCreateSampler_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateSampler(VkDevice device, VkSamplerCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSampler* pSampler)
		=> vkCreateSampler_ptr(device, pCreateInfo, pAllocator, pSampler);

	public typealias vkDestroySamplerFunction = function void(VkDevice device, VkSampler sampler, VkAllocationCallbacks* pAllocator);
	private static vkDestroySamplerFunction vkDestroySampler_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroySampler(VkDevice device, VkSampler sampler, VkAllocationCallbacks* pAllocator)
		=> vkDestroySampler_ptr(device, sampler, pAllocator);

	public typealias vkCreateDescriptorSetLayoutFunction = function VkResult(VkDevice device, VkDescriptorSetLayoutCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDescriptorSetLayout* pSetLayout);
	private static vkCreateDescriptorSetLayoutFunction vkCreateDescriptorSetLayout_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateDescriptorSetLayout(VkDevice device, VkDescriptorSetLayoutCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDescriptorSetLayout* pSetLayout)
		=> vkCreateDescriptorSetLayout_ptr(device, pCreateInfo, pAllocator, pSetLayout);

	public typealias vkDestroyDescriptorSetLayoutFunction = function void(VkDevice device, VkDescriptorSetLayout descriptorSetLayout, VkAllocationCallbacks* pAllocator);
	private static vkDestroyDescriptorSetLayoutFunction vkDestroyDescriptorSetLayout_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyDescriptorSetLayout(VkDevice device, VkDescriptorSetLayout descriptorSetLayout, VkAllocationCallbacks* pAllocator)
		=> vkDestroyDescriptorSetLayout_ptr(device, descriptorSetLayout, pAllocator);

	public typealias vkCreateDescriptorPoolFunction = function VkResult(VkDevice device, VkDescriptorPoolCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDescriptorPool* pDescriptorPool);
	private static vkCreateDescriptorPoolFunction vkCreateDescriptorPool_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateDescriptorPool(VkDevice device, VkDescriptorPoolCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDescriptorPool* pDescriptorPool)
		=> vkCreateDescriptorPool_ptr(device, pCreateInfo, pAllocator, pDescriptorPool);

	public typealias vkDestroyDescriptorPoolFunction = function void(VkDevice device, VkDescriptorPool descriptorPool, VkAllocationCallbacks* pAllocator);
	private static vkDestroyDescriptorPoolFunction vkDestroyDescriptorPool_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyDescriptorPool(VkDevice device, VkDescriptorPool descriptorPool, VkAllocationCallbacks* pAllocator)
		=> vkDestroyDescriptorPool_ptr(device, descriptorPool, pAllocator);

	public typealias vkResetDescriptorPoolFunction = function VkResult(VkDevice device, VkDescriptorPool descriptorPool, uint32 flags);
	private static vkResetDescriptorPoolFunction vkResetDescriptorPool_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkResetDescriptorPool(VkDevice device, VkDescriptorPool descriptorPool, uint32 flags)
		=> vkResetDescriptorPool_ptr(device, descriptorPool, flags);

	public typealias vkAllocateDescriptorSetsFunction = function VkResult(VkDevice device, VkDescriptorSetAllocateInfo* pAllocateInfo, VkDescriptorSet* pDescriptorSets);
	private static vkAllocateDescriptorSetsFunction vkAllocateDescriptorSets_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkAllocateDescriptorSets(VkDevice device, VkDescriptorSetAllocateInfo* pAllocateInfo, VkDescriptorSet* pDescriptorSets)
		=> vkAllocateDescriptorSets_ptr(device, pAllocateInfo, pDescriptorSets);

	public typealias vkFreeDescriptorSetsFunction = function VkResult(VkDevice device, VkDescriptorPool descriptorPool, uint32 descriptorSetCount, VkDescriptorSet* pDescriptorSets);
	private static vkFreeDescriptorSetsFunction vkFreeDescriptorSets_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkFreeDescriptorSets(VkDevice device, VkDescriptorPool descriptorPool, uint32 descriptorSetCount, VkDescriptorSet* pDescriptorSets)
		=> vkFreeDescriptorSets_ptr(device, descriptorPool, descriptorSetCount, pDescriptorSets);

	public typealias vkUpdateDescriptorSetsFunction = function void(VkDevice device, uint32 descriptorWriteCount, VkWriteDescriptorSet* pDescriptorWrites, uint32 descriptorCopyCount, VkCopyDescriptorSet* pDescriptorCopies);
	private static vkUpdateDescriptorSetsFunction vkUpdateDescriptorSets_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkUpdateDescriptorSets(VkDevice device, uint32 descriptorWriteCount, VkWriteDescriptorSet* pDescriptorWrites, uint32 descriptorCopyCount, VkCopyDescriptorSet* pDescriptorCopies)
		=> vkUpdateDescriptorSets_ptr(device, descriptorWriteCount, pDescriptorWrites, descriptorCopyCount, pDescriptorCopies);

	public typealias vkCmdBindPipelineFunction = function void(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline);
	private static vkCmdBindPipelineFunction vkCmdBindPipeline_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindPipeline(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline)
		=> vkCmdBindPipeline_ptr(commandBuffer, pipelineBindPoint, pipeline);

	public typealias vkCmdBindDescriptorSetsFunction = function void(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32 firstSet, uint32 descriptorSetCount, VkDescriptorSet* pDescriptorSets, uint32 dynamicOffsetCount, uint32* pDynamicOffsets);
	private static vkCmdBindDescriptorSetsFunction vkCmdBindDescriptorSets_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindDescriptorSets(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32 firstSet, uint32 descriptorSetCount, VkDescriptorSet* pDescriptorSets, uint32 dynamicOffsetCount, uint32* pDynamicOffsets)
		=> vkCmdBindDescriptorSets_ptr(commandBuffer, pipelineBindPoint, layout, firstSet, descriptorSetCount, pDescriptorSets, dynamicOffsetCount, pDynamicOffsets);

	public typealias vkCmdClearColorImageFunction = function void(VkCommandBuffer commandBuffer, VkImage image, VkImageLayout imageLayout, VkClearColorValue* pColor, uint32 rangeCount, VkImageSubresourceRange* pRanges);
	private static vkCmdClearColorImageFunction vkCmdClearColorImage_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdClearColorImage(VkCommandBuffer commandBuffer, VkImage image, VkImageLayout imageLayout, VkClearColorValue* pColor, uint32 rangeCount, VkImageSubresourceRange* pRanges)
		=> vkCmdClearColorImage_ptr(commandBuffer, image, imageLayout, pColor, rangeCount, pRanges);

	public typealias vkCmdDispatchFunction = function void(VkCommandBuffer commandBuffer, uint32 groupCountX, uint32 groupCountY, uint32 groupCountZ);
	private static vkCmdDispatchFunction vkCmdDispatch_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDispatch(VkCommandBuffer commandBuffer, uint32 groupCountX, uint32 groupCountY, uint32 groupCountZ)
		=> vkCmdDispatch_ptr(commandBuffer, groupCountX, groupCountY, groupCountZ);

	public typealias vkCmdDispatchIndirectFunction = function void(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset);
	private static vkCmdDispatchIndirectFunction vkCmdDispatchIndirect_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDispatchIndirect(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset)
		=> vkCmdDispatchIndirect_ptr(commandBuffer, buffer, offset);

	public typealias vkCmdSetEventFunction = function void(VkCommandBuffer commandBuffer, VkEvent event, VkPipelineStageFlags stageMask);
	private static vkCmdSetEventFunction vkCmdSetEvent_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetEvent(VkCommandBuffer commandBuffer, VkEvent event, VkPipelineStageFlags stageMask)
		=> vkCmdSetEvent_ptr(commandBuffer, event, stageMask);

	public typealias vkCmdResetEventFunction = function void(VkCommandBuffer commandBuffer, VkEvent event, VkPipelineStageFlags stageMask);
	private static vkCmdResetEventFunction vkCmdResetEvent_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdResetEvent(VkCommandBuffer commandBuffer, VkEvent event, VkPipelineStageFlags stageMask)
		=> vkCmdResetEvent_ptr(commandBuffer, event, stageMask);

	public typealias vkCmdWaitEventsFunction = function void(VkCommandBuffer commandBuffer, uint32 eventCount, VkEvent* pEvents, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, uint32 memoryBarrierCount, VkMemoryBarrier* pMemoryBarriers, uint32 bufferMemoryBarrierCount, VkBufferMemoryBarrier* pBufferMemoryBarriers, uint32 imageMemoryBarrierCount, VkImageMemoryBarrier* pImageMemoryBarriers);
	private static vkCmdWaitEventsFunction vkCmdWaitEvents_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdWaitEvents(VkCommandBuffer commandBuffer, uint32 eventCount, VkEvent* pEvents, VkPipelineStageFlags srcStageMask, VkPipelineStageFlags dstStageMask, uint32 memoryBarrierCount, VkMemoryBarrier* pMemoryBarriers, uint32 bufferMemoryBarrierCount, VkBufferMemoryBarrier* pBufferMemoryBarriers, uint32 imageMemoryBarrierCount, VkImageMemoryBarrier* pImageMemoryBarriers)
		=> vkCmdWaitEvents_ptr(commandBuffer, eventCount, pEvents, srcStageMask, dstStageMask, memoryBarrierCount, pMemoryBarriers, bufferMemoryBarrierCount, pBufferMemoryBarriers, imageMemoryBarrierCount, pImageMemoryBarriers);

	public typealias vkCmdPushConstantsFunction = function void(VkCommandBuffer commandBuffer, VkPipelineLayout layout, VkShaderStageFlags stageFlags, uint32 offset, uint32 size, void* pValues);
	private static vkCmdPushConstantsFunction vkCmdPushConstants_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdPushConstants(VkCommandBuffer commandBuffer, VkPipelineLayout layout, VkShaderStageFlags stageFlags, uint32 offset, uint32 size, void* pValues)
		=> vkCmdPushConstants_ptr(commandBuffer, layout, stageFlags, offset, size, pValues);

	public typealias vkCreateGraphicsPipelinesFunction = function VkResult(VkDevice device, VkPipelineCache pipelineCache, uint32 createInfoCount, VkGraphicsPipelineCreateInfo* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines);
	private static vkCreateGraphicsPipelinesFunction vkCreateGraphicsPipelines_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateGraphicsPipelines(VkDevice device, VkPipelineCache pipelineCache, uint32 createInfoCount, VkGraphicsPipelineCreateInfo* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines)
		=> vkCreateGraphicsPipelines_ptr(device, pipelineCache, createInfoCount, pCreateInfos, pAllocator, pPipelines);

	public typealias vkCreateFramebufferFunction = function VkResult(VkDevice device, VkFramebufferCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkFramebuffer* pFramebuffer);
	private static vkCreateFramebufferFunction vkCreateFramebuffer_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateFramebuffer(VkDevice device, VkFramebufferCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkFramebuffer* pFramebuffer)
		=> vkCreateFramebuffer_ptr(device, pCreateInfo, pAllocator, pFramebuffer);

	public typealias vkDestroyFramebufferFunction = function void(VkDevice device, VkFramebuffer framebuffer, VkAllocationCallbacks* pAllocator);
	private static vkDestroyFramebufferFunction vkDestroyFramebuffer_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyFramebuffer(VkDevice device, VkFramebuffer framebuffer, VkAllocationCallbacks* pAllocator)
		=> vkDestroyFramebuffer_ptr(device, framebuffer, pAllocator);

	public typealias vkCreateRenderPassFunction = function VkResult(VkDevice device, VkRenderPassCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkRenderPass* pRenderPass);
	private static vkCreateRenderPassFunction vkCreateRenderPass_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateRenderPass(VkDevice device, VkRenderPassCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkRenderPass* pRenderPass)
		=> vkCreateRenderPass_ptr(device, pCreateInfo, pAllocator, pRenderPass);

	public typealias vkDestroyRenderPassFunction = function void(VkDevice device, VkRenderPass renderPass, VkAllocationCallbacks* pAllocator);
	private static vkDestroyRenderPassFunction vkDestroyRenderPass_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyRenderPass(VkDevice device, VkRenderPass renderPass, VkAllocationCallbacks* pAllocator)
		=> vkDestroyRenderPass_ptr(device, renderPass, pAllocator);

	public typealias vkGetRenderAreaGranularityFunction = function void(VkDevice device, VkRenderPass renderPass, VkExtent2D* pGranularity);
	private static vkGetRenderAreaGranularityFunction vkGetRenderAreaGranularity_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetRenderAreaGranularity(VkDevice device, VkRenderPass renderPass, VkExtent2D* pGranularity)
		=> vkGetRenderAreaGranularity_ptr(device, renderPass, pGranularity);

	public typealias vkCmdSetViewportFunction = function void(VkCommandBuffer commandBuffer, uint32 firstViewport, uint32 viewportCount, VkViewport* pViewports);
	private static vkCmdSetViewportFunction vkCmdSetViewport_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetViewport(VkCommandBuffer commandBuffer, uint32 firstViewport, uint32 viewportCount, VkViewport* pViewports)
		=> vkCmdSetViewport_ptr(commandBuffer, firstViewport, viewportCount, pViewports);

	public typealias vkCmdSetScissorFunction = function void(VkCommandBuffer commandBuffer, uint32 firstScissor, uint32 scissorCount, VkRect2D* pScissors);
	private static vkCmdSetScissorFunction vkCmdSetScissor_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetScissor(VkCommandBuffer commandBuffer, uint32 firstScissor, uint32 scissorCount, VkRect2D* pScissors)
		=> vkCmdSetScissor_ptr(commandBuffer, firstScissor, scissorCount, pScissors);

	public typealias vkCmdSetLineWidthFunction = function void(VkCommandBuffer commandBuffer, float lineWidth);
	private static vkCmdSetLineWidthFunction vkCmdSetLineWidth_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetLineWidth(VkCommandBuffer commandBuffer, float lineWidth)
		=> vkCmdSetLineWidth_ptr(commandBuffer, lineWidth);

	public typealias vkCmdSetDepthBiasFunction = function void(VkCommandBuffer commandBuffer, float depthBiasConstantFactor, float depthBiasClamp, float depthBiasSlopeFactor);
	private static vkCmdSetDepthBiasFunction vkCmdSetDepthBias_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDepthBias(VkCommandBuffer commandBuffer, float depthBiasConstantFactor, float depthBiasClamp, float depthBiasSlopeFactor)
		=> vkCmdSetDepthBias_ptr(commandBuffer, depthBiasConstantFactor, depthBiasClamp, depthBiasSlopeFactor);

	public typealias vkCmdSetBlendConstantsFunction = function void(VkCommandBuffer commandBuffer, float[4] blendConstants);
	private static vkCmdSetBlendConstantsFunction vkCmdSetBlendConstants_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetBlendConstants(VkCommandBuffer commandBuffer, float[4] blendConstants)
		=> vkCmdSetBlendConstants_ptr(commandBuffer, blendConstants);

	public typealias vkCmdSetDepthBoundsFunction = function void(VkCommandBuffer commandBuffer, float minDepthBounds, float maxDepthBounds);
	private static vkCmdSetDepthBoundsFunction vkCmdSetDepthBounds_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDepthBounds(VkCommandBuffer commandBuffer, float minDepthBounds, float maxDepthBounds)
		=> vkCmdSetDepthBounds_ptr(commandBuffer, minDepthBounds, maxDepthBounds);

	public typealias vkCmdSetStencilCompareMaskFunction = function void(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32 compareMask);
	private static vkCmdSetStencilCompareMaskFunction vkCmdSetStencilCompareMask_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetStencilCompareMask(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32 compareMask)
		=> vkCmdSetStencilCompareMask_ptr(commandBuffer, faceMask, compareMask);

	public typealias vkCmdSetStencilWriteMaskFunction = function void(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32 writeMask);
	private static vkCmdSetStencilWriteMaskFunction vkCmdSetStencilWriteMask_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetStencilWriteMask(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32 writeMask)
		=> vkCmdSetStencilWriteMask_ptr(commandBuffer, faceMask, writeMask);

	public typealias vkCmdSetStencilReferenceFunction = function void(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32 reference);
	private static vkCmdSetStencilReferenceFunction vkCmdSetStencilReference_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetStencilReference(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, uint32 reference)
		=> vkCmdSetStencilReference_ptr(commandBuffer, faceMask, reference);

	public typealias vkCmdBindIndexBufferFunction = function void(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, VkIndexType indexType);
	private static vkCmdBindIndexBufferFunction vkCmdBindIndexBuffer_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindIndexBuffer(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, VkIndexType indexType)
		=> vkCmdBindIndexBuffer_ptr(commandBuffer, buffer, offset, indexType);

	public typealias vkCmdBindVertexBuffersFunction = function void(VkCommandBuffer commandBuffer, uint32 firstBinding, uint32 bindingCount, VkBuffer* pBuffers, uint64* pOffsets);
	private static vkCmdBindVertexBuffersFunction vkCmdBindVertexBuffers_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindVertexBuffers(VkCommandBuffer commandBuffer, uint32 firstBinding, uint32 bindingCount, VkBuffer* pBuffers, uint64* pOffsets)
		=> vkCmdBindVertexBuffers_ptr(commandBuffer, firstBinding, bindingCount, pBuffers, pOffsets);

	public typealias vkCmdDrawFunction = function void(VkCommandBuffer commandBuffer, uint32 vertexCount, uint32 instanceCount, uint32 firstVertex, uint32 firstInstance);
	private static vkCmdDrawFunction vkCmdDraw_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDraw(VkCommandBuffer commandBuffer, uint32 vertexCount, uint32 instanceCount, uint32 firstVertex, uint32 firstInstance)
		=> vkCmdDraw_ptr(commandBuffer, vertexCount, instanceCount, firstVertex, firstInstance);

	public typealias vkCmdDrawIndexedFunction = function void(VkCommandBuffer commandBuffer, uint32 indexCount, uint32 instanceCount, uint32 firstIndex, int32 vertexOffset, uint32 firstInstance);
	private static vkCmdDrawIndexedFunction vkCmdDrawIndexed_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawIndexed(VkCommandBuffer commandBuffer, uint32 indexCount, uint32 instanceCount, uint32 firstIndex, int32 vertexOffset, uint32 firstInstance)
		=> vkCmdDrawIndexed_ptr(commandBuffer, indexCount, instanceCount, firstIndex, vertexOffset, firstInstance);

	public typealias vkCmdDrawIndirectFunction = function void(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride);
	private static vkCmdDrawIndirectFunction vkCmdDrawIndirect_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawIndirect(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
		=> vkCmdDrawIndirect_ptr(commandBuffer, buffer, offset, drawCount, stride);

	public typealias vkCmdDrawIndexedIndirectFunction = function void(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride);
	private static vkCmdDrawIndexedIndirectFunction vkCmdDrawIndexedIndirect_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawIndexedIndirect(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
		=> vkCmdDrawIndexedIndirect_ptr(commandBuffer, buffer, offset, drawCount, stride);

	public typealias vkCmdBlitImageFunction = function void(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32 regionCount, VkImageBlit* pRegions, VkFilter filter);
	private static vkCmdBlitImageFunction vkCmdBlitImage_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBlitImage(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32 regionCount, VkImageBlit* pRegions, VkFilter filter)
		=> vkCmdBlitImage_ptr(commandBuffer, srcImage, srcImageLayout, dstImage, dstImageLayout, regionCount, pRegions, filter);

	public typealias vkCmdClearDepthStencilImageFunction = function void(VkCommandBuffer commandBuffer, VkImage image, VkImageLayout imageLayout, VkClearDepthStencilValue* pDepthStencil, uint32 rangeCount, VkImageSubresourceRange* pRanges);
	private static vkCmdClearDepthStencilImageFunction vkCmdClearDepthStencilImage_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdClearDepthStencilImage(VkCommandBuffer commandBuffer, VkImage image, VkImageLayout imageLayout, VkClearDepthStencilValue* pDepthStencil, uint32 rangeCount, VkImageSubresourceRange* pRanges)
		=> vkCmdClearDepthStencilImage_ptr(commandBuffer, image, imageLayout, pDepthStencil, rangeCount, pRanges);

	public typealias vkCmdClearAttachmentsFunction = function void(VkCommandBuffer commandBuffer, uint32 attachmentCount, VkClearAttachment* pAttachments, uint32 rectCount, VkClearRect* pRects);
	private static vkCmdClearAttachmentsFunction vkCmdClearAttachments_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdClearAttachments(VkCommandBuffer commandBuffer, uint32 attachmentCount, VkClearAttachment* pAttachments, uint32 rectCount, VkClearRect* pRects)
		=> vkCmdClearAttachments_ptr(commandBuffer, attachmentCount, pAttachments, rectCount, pRects);

	public typealias vkCmdResolveImageFunction = function void(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32 regionCount, VkImageResolve* pRegions);
	private static vkCmdResolveImageFunction vkCmdResolveImage_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdResolveImage(VkCommandBuffer commandBuffer, VkImage srcImage, VkImageLayout srcImageLayout, VkImage dstImage, VkImageLayout dstImageLayout, uint32 regionCount, VkImageResolve* pRegions)
		=> vkCmdResolveImage_ptr(commandBuffer, srcImage, srcImageLayout, dstImage, dstImageLayout, regionCount, pRegions);

	public typealias vkCmdBeginRenderPassFunction = function void(VkCommandBuffer commandBuffer, VkRenderPassBeginInfo* pRenderPassBegin, VkSubpassContents contents);
	private static vkCmdBeginRenderPassFunction vkCmdBeginRenderPass_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBeginRenderPass(VkCommandBuffer commandBuffer, VkRenderPassBeginInfo* pRenderPassBegin, VkSubpassContents contents)
		=> vkCmdBeginRenderPass_ptr(commandBuffer, pRenderPassBegin, contents);

	public typealias vkCmdNextSubpassFunction = function void(VkCommandBuffer commandBuffer, VkSubpassContents contents);
	private static vkCmdNextSubpassFunction vkCmdNextSubpass_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdNextSubpass(VkCommandBuffer commandBuffer, VkSubpassContents contents)
		=> vkCmdNextSubpass_ptr(commandBuffer, contents);

	public typealias vkCmdEndRenderPassFunction = function void(VkCommandBuffer commandBuffer);
	private static vkCmdEndRenderPassFunction vkCmdEndRenderPass_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdEndRenderPass(VkCommandBuffer commandBuffer)
		=> vkCmdEndRenderPass_ptr(commandBuffer);

	public typealias vkEnumerateInstanceVersionFunction = function VkResult(uint32* pApiVersion);
	private static vkEnumerateInstanceVersionFunction vkEnumerateInstanceVersion_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkEnumerateInstanceVersion(uint32* pApiVersion)
		=> vkEnumerateInstanceVersion_ptr(pApiVersion);

	public typealias vkBindBufferMemory2Function = function VkResult(VkDevice device, uint32 bindInfoCount, VkBindBufferMemoryInfo* pBindInfos);
	private static vkBindBufferMemory2Function vkBindBufferMemory2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkBindBufferMemory2(VkDevice device, uint32 bindInfoCount, VkBindBufferMemoryInfo* pBindInfos)
		=> vkBindBufferMemory2_ptr(device, bindInfoCount, pBindInfos);

	public typealias vkBindImageMemory2Function = function VkResult(VkDevice device, uint32 bindInfoCount, VkBindImageMemoryInfo* pBindInfos);
	private static vkBindImageMemory2Function vkBindImageMemory2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkBindImageMemory2(VkDevice device, uint32 bindInfoCount, VkBindImageMemoryInfo* pBindInfos)
		=> vkBindImageMemory2_ptr(device, bindInfoCount, pBindInfos);

	public typealias vkGetDeviceGroupPeerMemoryFeaturesFunction = function void(VkDevice device, uint32 heapIndex, uint32 localDeviceIndex, uint32 remoteDeviceIndex, VkPeerMemoryFeatureFlags* pPeerMemoryFeatures);
	private static vkGetDeviceGroupPeerMemoryFeaturesFunction vkGetDeviceGroupPeerMemoryFeatures_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDeviceGroupPeerMemoryFeatures(VkDevice device, uint32 heapIndex, uint32 localDeviceIndex, uint32 remoteDeviceIndex, VkPeerMemoryFeatureFlags* pPeerMemoryFeatures)
		=> vkGetDeviceGroupPeerMemoryFeatures_ptr(device, heapIndex, localDeviceIndex, remoteDeviceIndex, pPeerMemoryFeatures);

	public typealias vkCmdSetDeviceMaskFunction = function void(VkCommandBuffer commandBuffer, uint32 deviceMask);
	private static vkCmdSetDeviceMaskFunction vkCmdSetDeviceMask_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDeviceMask(VkCommandBuffer commandBuffer, uint32 deviceMask)
		=> vkCmdSetDeviceMask_ptr(commandBuffer, deviceMask);

	public typealias vkEnumeratePhysicalDeviceGroupsFunction = function VkResult(VkInstance instance, uint32* pPhysicalDeviceGroupCount, VkPhysicalDeviceGroupProperties* pPhysicalDeviceGroupProperties);
	private static vkEnumeratePhysicalDeviceGroupsFunction vkEnumeratePhysicalDeviceGroups_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkEnumeratePhysicalDeviceGroups(VkInstance instance, uint32* pPhysicalDeviceGroupCount, VkPhysicalDeviceGroupProperties* pPhysicalDeviceGroupProperties)
		=> vkEnumeratePhysicalDeviceGroups_ptr(instance, pPhysicalDeviceGroupCount, pPhysicalDeviceGroupProperties);

	public typealias vkGetImageMemoryRequirements2Function = function void(VkDevice device, VkImageMemoryRequirementsInfo2* pInfo, VkMemoryRequirements2* pMemoryRequirements);
	private static vkGetImageMemoryRequirements2Function vkGetImageMemoryRequirements2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetImageMemoryRequirements2(VkDevice device, VkImageMemoryRequirementsInfo2* pInfo, VkMemoryRequirements2* pMemoryRequirements)
		=> vkGetImageMemoryRequirements2_ptr(device, pInfo, pMemoryRequirements);

	public typealias vkGetBufferMemoryRequirements2Function = function void(VkDevice device, VkBufferMemoryRequirementsInfo2* pInfo, VkMemoryRequirements2* pMemoryRequirements);
	private static vkGetBufferMemoryRequirements2Function vkGetBufferMemoryRequirements2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetBufferMemoryRequirements2(VkDevice device, VkBufferMemoryRequirementsInfo2* pInfo, VkMemoryRequirements2* pMemoryRequirements)
		=> vkGetBufferMemoryRequirements2_ptr(device, pInfo, pMemoryRequirements);

	public typealias vkGetImageSparseMemoryRequirements2Function = function void(VkDevice device, VkImageSparseMemoryRequirementsInfo2* pInfo, uint32* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements2* pSparseMemoryRequirements);
	private static vkGetImageSparseMemoryRequirements2Function vkGetImageSparseMemoryRequirements2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetImageSparseMemoryRequirements2(VkDevice device, VkImageSparseMemoryRequirementsInfo2* pInfo, uint32* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements2* pSparseMemoryRequirements)
		=> vkGetImageSparseMemoryRequirements2_ptr(device, pInfo, pSparseMemoryRequirementCount, pSparseMemoryRequirements);

	public typealias vkGetPhysicalDeviceFeatures2Function = function void(VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures2* pFeatures);
	private static vkGetPhysicalDeviceFeatures2Function vkGetPhysicalDeviceFeatures2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceFeatures2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceFeatures2* pFeatures)
		=> vkGetPhysicalDeviceFeatures2_ptr(physicalDevice, pFeatures);

	public typealias vkGetPhysicalDeviceProperties2Function = function void(VkPhysicalDevice physicalDevice, VkPhysicalDeviceProperties2* pProperties);
	private static vkGetPhysicalDeviceProperties2Function vkGetPhysicalDeviceProperties2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceProperties2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceProperties2* pProperties)
		=> vkGetPhysicalDeviceProperties2_ptr(physicalDevice, pProperties);

	public typealias vkGetPhysicalDeviceFormatProperties2Function = function void(VkPhysicalDevice physicalDevice, VkFormat format, VkFormatProperties2* pFormatProperties);
	private static vkGetPhysicalDeviceFormatProperties2Function vkGetPhysicalDeviceFormatProperties2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceFormatProperties2(VkPhysicalDevice physicalDevice, VkFormat format, VkFormatProperties2* pFormatProperties)
		=> vkGetPhysicalDeviceFormatProperties2_ptr(physicalDevice, format, pFormatProperties);

	public typealias vkGetPhysicalDeviceImageFormatProperties2Function = function VkResult(VkPhysicalDevice physicalDevice, VkPhysicalDeviceImageFormatInfo2* pImageFormatInfo, VkImageFormatProperties2* pImageFormatProperties);
	private static vkGetPhysicalDeviceImageFormatProperties2Function vkGetPhysicalDeviceImageFormatProperties2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceImageFormatProperties2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceImageFormatInfo2* pImageFormatInfo, VkImageFormatProperties2* pImageFormatProperties)
		=> vkGetPhysicalDeviceImageFormatProperties2_ptr(physicalDevice, pImageFormatInfo, pImageFormatProperties);

	public typealias vkGetPhysicalDeviceQueueFamilyProperties2Function = function void(VkPhysicalDevice physicalDevice, uint32* pQueueFamilyPropertyCount, VkQueueFamilyProperties2* pQueueFamilyProperties);
	private static vkGetPhysicalDeviceQueueFamilyProperties2Function vkGetPhysicalDeviceQueueFamilyProperties2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceQueueFamilyProperties2(VkPhysicalDevice physicalDevice, uint32* pQueueFamilyPropertyCount, VkQueueFamilyProperties2* pQueueFamilyProperties)
		=> vkGetPhysicalDeviceQueueFamilyProperties2_ptr(physicalDevice, pQueueFamilyPropertyCount, pQueueFamilyProperties);

	public typealias vkGetPhysicalDeviceMemoryProperties2Function = function void(VkPhysicalDevice physicalDevice, VkPhysicalDeviceMemoryProperties2* pMemoryProperties);
	private static vkGetPhysicalDeviceMemoryProperties2Function vkGetPhysicalDeviceMemoryProperties2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceMemoryProperties2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceMemoryProperties2* pMemoryProperties)
		=> vkGetPhysicalDeviceMemoryProperties2_ptr(physicalDevice, pMemoryProperties);

	public typealias vkGetPhysicalDeviceSparseImageFormatProperties2Function = function void(VkPhysicalDevice physicalDevice, VkPhysicalDeviceSparseImageFormatInfo2* pFormatInfo, uint32* pPropertyCount, VkSparseImageFormatProperties2* pProperties);
	private static vkGetPhysicalDeviceSparseImageFormatProperties2Function vkGetPhysicalDeviceSparseImageFormatProperties2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceSparseImageFormatProperties2(VkPhysicalDevice physicalDevice, VkPhysicalDeviceSparseImageFormatInfo2* pFormatInfo, uint32* pPropertyCount, VkSparseImageFormatProperties2* pProperties)
		=> vkGetPhysicalDeviceSparseImageFormatProperties2_ptr(physicalDevice, pFormatInfo, pPropertyCount, pProperties);

	public typealias vkTrimCommandPoolFunction = function void(VkDevice device, VkCommandPool commandPool, uint32 flags);
	private static vkTrimCommandPoolFunction vkTrimCommandPool_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkTrimCommandPool(VkDevice device, VkCommandPool commandPool, uint32 flags)
		=> vkTrimCommandPool_ptr(device, commandPool, flags);

	public typealias vkGetDeviceQueue2Function = function void(VkDevice device, VkDeviceQueueInfo2* pQueueInfo, VkQueue* pQueue);
	private static vkGetDeviceQueue2Function vkGetDeviceQueue2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDeviceQueue2(VkDevice device, VkDeviceQueueInfo2* pQueueInfo, VkQueue* pQueue)
		=> vkGetDeviceQueue2_ptr(device, pQueueInfo, pQueue);

	public typealias vkGetPhysicalDeviceExternalBufferPropertiesFunction = function void(VkPhysicalDevice physicalDevice, VkPhysicalDeviceExternalBufferInfo* pExternalBufferInfo, VkExternalBufferProperties* pExternalBufferProperties);
	private static vkGetPhysicalDeviceExternalBufferPropertiesFunction vkGetPhysicalDeviceExternalBufferProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceExternalBufferProperties(VkPhysicalDevice physicalDevice, VkPhysicalDeviceExternalBufferInfo* pExternalBufferInfo, VkExternalBufferProperties* pExternalBufferProperties)
		=> vkGetPhysicalDeviceExternalBufferProperties_ptr(physicalDevice, pExternalBufferInfo, pExternalBufferProperties);

	public typealias vkGetPhysicalDeviceExternalFencePropertiesFunction = function void(VkPhysicalDevice physicalDevice, VkPhysicalDeviceExternalFenceInfo* pExternalFenceInfo, VkExternalFenceProperties* pExternalFenceProperties);
	private static vkGetPhysicalDeviceExternalFencePropertiesFunction vkGetPhysicalDeviceExternalFenceProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceExternalFenceProperties(VkPhysicalDevice physicalDevice, VkPhysicalDeviceExternalFenceInfo* pExternalFenceInfo, VkExternalFenceProperties* pExternalFenceProperties)
		=> vkGetPhysicalDeviceExternalFenceProperties_ptr(physicalDevice, pExternalFenceInfo, pExternalFenceProperties);

	public typealias vkGetPhysicalDeviceExternalSemaphorePropertiesFunction = function void(VkPhysicalDevice physicalDevice, VkPhysicalDeviceExternalSemaphoreInfo* pExternalSemaphoreInfo, VkExternalSemaphoreProperties* pExternalSemaphoreProperties);
	private static vkGetPhysicalDeviceExternalSemaphorePropertiesFunction vkGetPhysicalDeviceExternalSemaphoreProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceExternalSemaphoreProperties(VkPhysicalDevice physicalDevice, VkPhysicalDeviceExternalSemaphoreInfo* pExternalSemaphoreInfo, VkExternalSemaphoreProperties* pExternalSemaphoreProperties)
		=> vkGetPhysicalDeviceExternalSemaphoreProperties_ptr(physicalDevice, pExternalSemaphoreInfo, pExternalSemaphoreProperties);

	public typealias vkCmdDispatchBaseFunction = function void(VkCommandBuffer commandBuffer, uint32 baseGroupX, uint32 baseGroupY, uint32 baseGroupZ, uint32 groupCountX, uint32 groupCountY, uint32 groupCountZ);
	private static vkCmdDispatchBaseFunction vkCmdDispatchBase_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDispatchBase(VkCommandBuffer commandBuffer, uint32 baseGroupX, uint32 baseGroupY, uint32 baseGroupZ, uint32 groupCountX, uint32 groupCountY, uint32 groupCountZ)
		=> vkCmdDispatchBase_ptr(commandBuffer, baseGroupX, baseGroupY, baseGroupZ, groupCountX, groupCountY, groupCountZ);

	public typealias vkCreateDescriptorUpdateTemplateFunction = function VkResult(VkDevice device, VkDescriptorUpdateTemplateCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDescriptorUpdateTemplate* pDescriptorUpdateTemplate);
	private static vkCreateDescriptorUpdateTemplateFunction vkCreateDescriptorUpdateTemplate_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateDescriptorUpdateTemplate(VkDevice device, VkDescriptorUpdateTemplateCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDescriptorUpdateTemplate* pDescriptorUpdateTemplate)
		=> vkCreateDescriptorUpdateTemplate_ptr(device, pCreateInfo, pAllocator, pDescriptorUpdateTemplate);

	public typealias vkDestroyDescriptorUpdateTemplateFunction = function void(VkDevice device, VkDescriptorUpdateTemplate descriptorUpdateTemplate, VkAllocationCallbacks* pAllocator);
	private static vkDestroyDescriptorUpdateTemplateFunction vkDestroyDescriptorUpdateTemplate_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyDescriptorUpdateTemplate(VkDevice device, VkDescriptorUpdateTemplate descriptorUpdateTemplate, VkAllocationCallbacks* pAllocator)
		=> vkDestroyDescriptorUpdateTemplate_ptr(device, descriptorUpdateTemplate, pAllocator);

	public typealias vkUpdateDescriptorSetWithTemplateFunction = function void(VkDevice device, VkDescriptorSet descriptorSet, VkDescriptorUpdateTemplate descriptorUpdateTemplate, void* pData);
	private static vkUpdateDescriptorSetWithTemplateFunction vkUpdateDescriptorSetWithTemplate_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkUpdateDescriptorSetWithTemplate(VkDevice device, VkDescriptorSet descriptorSet, VkDescriptorUpdateTemplate descriptorUpdateTemplate, void* pData)
		=> vkUpdateDescriptorSetWithTemplate_ptr(device, descriptorSet, descriptorUpdateTemplate, pData);

	public typealias vkGetDescriptorSetLayoutSupportFunction = function void(VkDevice device, VkDescriptorSetLayoutCreateInfo* pCreateInfo, VkDescriptorSetLayoutSupport* pSupport);
	private static vkGetDescriptorSetLayoutSupportFunction vkGetDescriptorSetLayoutSupport_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDescriptorSetLayoutSupport(VkDevice device, VkDescriptorSetLayoutCreateInfo* pCreateInfo, VkDescriptorSetLayoutSupport* pSupport)
		=> vkGetDescriptorSetLayoutSupport_ptr(device, pCreateInfo, pSupport);

	public typealias vkCreateSamplerYcbcrConversionFunction = function VkResult(VkDevice device, VkSamplerYcbcrConversionCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSamplerYcbcrConversion* pYcbcrConversion);
	private static vkCreateSamplerYcbcrConversionFunction vkCreateSamplerYcbcrConversion_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateSamplerYcbcrConversion(VkDevice device, VkSamplerYcbcrConversionCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSamplerYcbcrConversion* pYcbcrConversion)
		=> vkCreateSamplerYcbcrConversion_ptr(device, pCreateInfo, pAllocator, pYcbcrConversion);

	public typealias vkDestroySamplerYcbcrConversionFunction = function void(VkDevice device, VkSamplerYcbcrConversion ycbcrConversion, VkAllocationCallbacks* pAllocator);
	private static vkDestroySamplerYcbcrConversionFunction vkDestroySamplerYcbcrConversion_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroySamplerYcbcrConversion(VkDevice device, VkSamplerYcbcrConversion ycbcrConversion, VkAllocationCallbacks* pAllocator)
		=> vkDestroySamplerYcbcrConversion_ptr(device, ycbcrConversion, pAllocator);

	public typealias vkResetQueryPoolFunction = function void(VkDevice device, VkQueryPool queryPool, uint32 firstQuery, uint32 queryCount);
	private static vkResetQueryPoolFunction vkResetQueryPool_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkResetQueryPool(VkDevice device, VkQueryPool queryPool, uint32 firstQuery, uint32 queryCount)
		=> vkResetQueryPool_ptr(device, queryPool, firstQuery, queryCount);

	public typealias vkGetSemaphoreCounterValueFunction = function VkResult(VkDevice device, VkSemaphore semaphore, uint64* pValue);
	private static vkGetSemaphoreCounterValueFunction vkGetSemaphoreCounterValue_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetSemaphoreCounterValue(VkDevice device, VkSemaphore semaphore, uint64* pValue)
		=> vkGetSemaphoreCounterValue_ptr(device, semaphore, pValue);

	public typealias vkWaitSemaphoresFunction = function VkResult(VkDevice device, VkSemaphoreWaitInfo* pWaitInfo, uint64 timeout);
	private static vkWaitSemaphoresFunction vkWaitSemaphores_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkWaitSemaphores(VkDevice device, VkSemaphoreWaitInfo* pWaitInfo, uint64 timeout)
		=> vkWaitSemaphores_ptr(device, pWaitInfo, timeout);

	public typealias vkSignalSemaphoreFunction = function VkResult(VkDevice device, VkSemaphoreSignalInfo* pSignalInfo);
	private static vkSignalSemaphoreFunction vkSignalSemaphore_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkSignalSemaphore(VkDevice device, VkSemaphoreSignalInfo* pSignalInfo)
		=> vkSignalSemaphore_ptr(device, pSignalInfo);

	public typealias vkGetBufferDeviceAddressFunction = function uint64(VkDevice device, VkBufferDeviceAddressInfo* pInfo);
	private static vkGetBufferDeviceAddressFunction vkGetBufferDeviceAddress_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static uint64 vkGetBufferDeviceAddress(VkDevice device, VkBufferDeviceAddressInfo* pInfo)
		=> vkGetBufferDeviceAddress_ptr(device, pInfo);

	public typealias vkGetBufferOpaqueCaptureAddressFunction = function uint64(VkDevice device, VkBufferDeviceAddressInfo* pInfo);
	private static vkGetBufferOpaqueCaptureAddressFunction vkGetBufferOpaqueCaptureAddress_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static uint64 vkGetBufferOpaqueCaptureAddress(VkDevice device, VkBufferDeviceAddressInfo* pInfo)
		=> vkGetBufferOpaqueCaptureAddress_ptr(device, pInfo);

	public typealias vkGetDeviceMemoryOpaqueCaptureAddressFunction = function uint64(VkDevice device, VkDeviceMemoryOpaqueCaptureAddressInfo* pInfo);
	private static vkGetDeviceMemoryOpaqueCaptureAddressFunction vkGetDeviceMemoryOpaqueCaptureAddress_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static uint64 vkGetDeviceMemoryOpaqueCaptureAddress(VkDevice device, VkDeviceMemoryOpaqueCaptureAddressInfo* pInfo)
		=> vkGetDeviceMemoryOpaqueCaptureAddress_ptr(device, pInfo);

	public typealias vkCmdDrawIndirectCountFunction = function void(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, VkBuffer countBuffer, uint64 countBufferOffset, uint32 maxDrawCount, uint32 stride);
	private static vkCmdDrawIndirectCountFunction vkCmdDrawIndirectCount_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawIndirectCount(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, VkBuffer countBuffer, uint64 countBufferOffset, uint32 maxDrawCount, uint32 stride)
		=> vkCmdDrawIndirectCount_ptr(commandBuffer, buffer, offset, countBuffer, countBufferOffset, maxDrawCount, stride);

	public typealias vkCmdDrawIndexedIndirectCountFunction = function void(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, VkBuffer countBuffer, uint64 countBufferOffset, uint32 maxDrawCount, uint32 stride);
	private static vkCmdDrawIndexedIndirectCountFunction vkCmdDrawIndexedIndirectCount_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawIndexedIndirectCount(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, VkBuffer countBuffer, uint64 countBufferOffset, uint32 maxDrawCount, uint32 stride)
		=> vkCmdDrawIndexedIndirectCount_ptr(commandBuffer, buffer, offset, countBuffer, countBufferOffset, maxDrawCount, stride);

	public typealias vkCreateRenderPass2Function = function VkResult(VkDevice device, VkRenderPassCreateInfo2* pCreateInfo, VkAllocationCallbacks* pAllocator, VkRenderPass* pRenderPass);
	private static vkCreateRenderPass2Function vkCreateRenderPass2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateRenderPass2(VkDevice device, VkRenderPassCreateInfo2* pCreateInfo, VkAllocationCallbacks* pAllocator, VkRenderPass* pRenderPass)
		=> vkCreateRenderPass2_ptr(device, pCreateInfo, pAllocator, pRenderPass);

	public typealias vkCmdBeginRenderPass2Function = function void(VkCommandBuffer commandBuffer, VkRenderPassBeginInfo* pRenderPassBegin, VkSubpassBeginInfo* pSubpassBeginInfo);
	private static vkCmdBeginRenderPass2Function vkCmdBeginRenderPass2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBeginRenderPass2(VkCommandBuffer commandBuffer, VkRenderPassBeginInfo* pRenderPassBegin, VkSubpassBeginInfo* pSubpassBeginInfo)
		=> vkCmdBeginRenderPass2_ptr(commandBuffer, pRenderPassBegin, pSubpassBeginInfo);

	public typealias vkCmdNextSubpass2Function = function void(VkCommandBuffer commandBuffer, VkSubpassBeginInfo* pSubpassBeginInfo, VkSubpassEndInfo* pSubpassEndInfo);
	private static vkCmdNextSubpass2Function vkCmdNextSubpass2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdNextSubpass2(VkCommandBuffer commandBuffer, VkSubpassBeginInfo* pSubpassBeginInfo, VkSubpassEndInfo* pSubpassEndInfo)
		=> vkCmdNextSubpass2_ptr(commandBuffer, pSubpassBeginInfo, pSubpassEndInfo);

	public typealias vkCmdEndRenderPass2Function = function void(VkCommandBuffer commandBuffer, VkSubpassEndInfo* pSubpassEndInfo);
	private static vkCmdEndRenderPass2Function vkCmdEndRenderPass2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdEndRenderPass2(VkCommandBuffer commandBuffer, VkSubpassEndInfo* pSubpassEndInfo)
		=> vkCmdEndRenderPass2_ptr(commandBuffer, pSubpassEndInfo);

	public typealias vkGetPhysicalDeviceToolPropertiesFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pToolCount, VkPhysicalDeviceToolProperties* pToolProperties);
	private static vkGetPhysicalDeviceToolPropertiesFunction vkGetPhysicalDeviceToolProperties_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceToolProperties(VkPhysicalDevice physicalDevice, uint32* pToolCount, VkPhysicalDeviceToolProperties* pToolProperties)
		=> vkGetPhysicalDeviceToolProperties_ptr(physicalDevice, pToolCount, pToolProperties);

	public typealias vkCreatePrivateDataSlotFunction = function VkResult(VkDevice device, VkPrivateDataSlotCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkPrivateDataSlot* pPrivateDataSlot);
	private static vkCreatePrivateDataSlotFunction vkCreatePrivateDataSlot_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreatePrivateDataSlot(VkDevice device, VkPrivateDataSlotCreateInfo* pCreateInfo, VkAllocationCallbacks* pAllocator, VkPrivateDataSlot* pPrivateDataSlot)
		=> vkCreatePrivateDataSlot_ptr(device, pCreateInfo, pAllocator, pPrivateDataSlot);

	public typealias vkDestroyPrivateDataSlotFunction = function void(VkDevice device, VkPrivateDataSlot privateDataSlot, VkAllocationCallbacks* pAllocator);
	private static vkDestroyPrivateDataSlotFunction vkDestroyPrivateDataSlot_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyPrivateDataSlot(VkDevice device, VkPrivateDataSlot privateDataSlot, VkAllocationCallbacks* pAllocator)
		=> vkDestroyPrivateDataSlot_ptr(device, privateDataSlot, pAllocator);

	public typealias vkSetPrivateDataFunction = function VkResult(VkDevice device, VkObjectType objectType, uint64 objectHandle, VkPrivateDataSlot privateDataSlot, uint64 data);
	private static vkSetPrivateDataFunction vkSetPrivateData_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkSetPrivateData(VkDevice device, VkObjectType objectType, uint64 objectHandle, VkPrivateDataSlot privateDataSlot, uint64 data)
		=> vkSetPrivateData_ptr(device, objectType, objectHandle, privateDataSlot, data);

	public typealias vkGetPrivateDataFunction = function void(VkDevice device, VkObjectType objectType, uint64 objectHandle, VkPrivateDataSlot privateDataSlot, uint64* pData);
	private static vkGetPrivateDataFunction vkGetPrivateData_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPrivateData(VkDevice device, VkObjectType objectType, uint64 objectHandle, VkPrivateDataSlot privateDataSlot, uint64* pData)
		=> vkGetPrivateData_ptr(device, objectType, objectHandle, privateDataSlot, pData);

	public typealias vkCmdPipelineBarrier2Function = function void(VkCommandBuffer commandBuffer, VkDependencyInfo* pDependencyInfo);
	private static vkCmdPipelineBarrier2Function vkCmdPipelineBarrier2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdPipelineBarrier2(VkCommandBuffer commandBuffer, VkDependencyInfo* pDependencyInfo)
		=> vkCmdPipelineBarrier2_ptr(commandBuffer, pDependencyInfo);

	public typealias vkCmdWriteTimestamp2Function = function void(VkCommandBuffer commandBuffer, uint64 stage, VkQueryPool queryPool, uint32 query);
	private static vkCmdWriteTimestamp2Function vkCmdWriteTimestamp2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdWriteTimestamp2(VkCommandBuffer commandBuffer, uint64 stage, VkQueryPool queryPool, uint32 query)
		=> vkCmdWriteTimestamp2_ptr(commandBuffer, stage, queryPool, query);

	public typealias vkQueueSubmit2Function = function VkResult(VkQueue queue, uint32 submitCount, VkSubmitInfo2* pSubmits, VkFence fence);
	private static vkQueueSubmit2Function vkQueueSubmit2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkQueueSubmit2(VkQueue queue, uint32 submitCount, VkSubmitInfo2* pSubmits, VkFence fence)
		=> vkQueueSubmit2_ptr(queue, submitCount, pSubmits, fence);

	public typealias vkCmdCopyBuffer2Function = function void(VkCommandBuffer commandBuffer, VkCopyBufferInfo2* pCopyBufferInfo);
	private static vkCmdCopyBuffer2Function vkCmdCopyBuffer2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyBuffer2(VkCommandBuffer commandBuffer, VkCopyBufferInfo2* pCopyBufferInfo)
		=> vkCmdCopyBuffer2_ptr(commandBuffer, pCopyBufferInfo);

	public typealias vkCmdCopyImage2Function = function void(VkCommandBuffer commandBuffer, VkCopyImageInfo2* pCopyImageInfo);
	private static vkCmdCopyImage2Function vkCmdCopyImage2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyImage2(VkCommandBuffer commandBuffer, VkCopyImageInfo2* pCopyImageInfo)
		=> vkCmdCopyImage2_ptr(commandBuffer, pCopyImageInfo);

	public typealias vkCmdCopyBufferToImage2Function = function void(VkCommandBuffer commandBuffer, VkCopyBufferToImageInfo2* pCopyBufferToImageInfo);
	private static vkCmdCopyBufferToImage2Function vkCmdCopyBufferToImage2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyBufferToImage2(VkCommandBuffer commandBuffer, VkCopyBufferToImageInfo2* pCopyBufferToImageInfo)
		=> vkCmdCopyBufferToImage2_ptr(commandBuffer, pCopyBufferToImageInfo);

	public typealias vkCmdCopyImageToBuffer2Function = function void(VkCommandBuffer commandBuffer, VkCopyImageToBufferInfo2* pCopyImageToBufferInfo);
	private static vkCmdCopyImageToBuffer2Function vkCmdCopyImageToBuffer2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyImageToBuffer2(VkCommandBuffer commandBuffer, VkCopyImageToBufferInfo2* pCopyImageToBufferInfo)
		=> vkCmdCopyImageToBuffer2_ptr(commandBuffer, pCopyImageToBufferInfo);

	public typealias vkGetDeviceBufferMemoryRequirementsFunction = function void(VkDevice device, VkDeviceBufferMemoryRequirements* pInfo, VkMemoryRequirements2* pMemoryRequirements);
	private static vkGetDeviceBufferMemoryRequirementsFunction vkGetDeviceBufferMemoryRequirements_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDeviceBufferMemoryRequirements(VkDevice device, VkDeviceBufferMemoryRequirements* pInfo, VkMemoryRequirements2* pMemoryRequirements)
		=> vkGetDeviceBufferMemoryRequirements_ptr(device, pInfo, pMemoryRequirements);

	public typealias vkGetDeviceImageMemoryRequirementsFunction = function void(VkDevice device, VkDeviceImageMemoryRequirements* pInfo, VkMemoryRequirements2* pMemoryRequirements);
	private static vkGetDeviceImageMemoryRequirementsFunction vkGetDeviceImageMemoryRequirements_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDeviceImageMemoryRequirements(VkDevice device, VkDeviceImageMemoryRequirements* pInfo, VkMemoryRequirements2* pMemoryRequirements)
		=> vkGetDeviceImageMemoryRequirements_ptr(device, pInfo, pMemoryRequirements);

	public typealias vkGetDeviceImageSparseMemoryRequirementsFunction = function void(VkDevice device, VkDeviceImageMemoryRequirements* pInfo, uint32* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements2* pSparseMemoryRequirements);
	private static vkGetDeviceImageSparseMemoryRequirementsFunction vkGetDeviceImageSparseMemoryRequirements_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDeviceImageSparseMemoryRequirements(VkDevice device, VkDeviceImageMemoryRequirements* pInfo, uint32* pSparseMemoryRequirementCount, VkSparseImageMemoryRequirements2* pSparseMemoryRequirements)
		=> vkGetDeviceImageSparseMemoryRequirements_ptr(device, pInfo, pSparseMemoryRequirementCount, pSparseMemoryRequirements);

	public typealias vkCmdSetEvent2Function = function void(VkCommandBuffer commandBuffer, VkEvent event, VkDependencyInfo* pDependencyInfo);
	private static vkCmdSetEvent2Function vkCmdSetEvent2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetEvent2(VkCommandBuffer commandBuffer, VkEvent event, VkDependencyInfo* pDependencyInfo)
		=> vkCmdSetEvent2_ptr(commandBuffer, event, pDependencyInfo);

	public typealias vkCmdResetEvent2Function = function void(VkCommandBuffer commandBuffer, VkEvent event, uint64 stageMask);
	private static vkCmdResetEvent2Function vkCmdResetEvent2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdResetEvent2(VkCommandBuffer commandBuffer, VkEvent event, uint64 stageMask)
		=> vkCmdResetEvent2_ptr(commandBuffer, event, stageMask);

	public typealias vkCmdWaitEvents2Function = function void(VkCommandBuffer commandBuffer, uint32 eventCount, VkEvent* pEvents, VkDependencyInfo* pDependencyInfos);
	private static vkCmdWaitEvents2Function vkCmdWaitEvents2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdWaitEvents2(VkCommandBuffer commandBuffer, uint32 eventCount, VkEvent* pEvents, VkDependencyInfo* pDependencyInfos)
		=> vkCmdWaitEvents2_ptr(commandBuffer, eventCount, pEvents, pDependencyInfos);

	public typealias vkCmdBlitImage2Function = function void(VkCommandBuffer commandBuffer, VkBlitImageInfo2* pBlitImageInfo);
	private static vkCmdBlitImage2Function vkCmdBlitImage2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBlitImage2(VkCommandBuffer commandBuffer, VkBlitImageInfo2* pBlitImageInfo)
		=> vkCmdBlitImage2_ptr(commandBuffer, pBlitImageInfo);

	public typealias vkCmdResolveImage2Function = function void(VkCommandBuffer commandBuffer, VkResolveImageInfo2* pResolveImageInfo);
	private static vkCmdResolveImage2Function vkCmdResolveImage2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdResolveImage2(VkCommandBuffer commandBuffer, VkResolveImageInfo2* pResolveImageInfo)
		=> vkCmdResolveImage2_ptr(commandBuffer, pResolveImageInfo);

	public typealias vkCmdBeginRenderingFunction = function void(VkCommandBuffer commandBuffer, VkRenderingInfo* pRenderingInfo);
	private static vkCmdBeginRenderingFunction vkCmdBeginRendering_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBeginRendering(VkCommandBuffer commandBuffer, VkRenderingInfo* pRenderingInfo)
		=> vkCmdBeginRendering_ptr(commandBuffer, pRenderingInfo);

	public typealias vkCmdEndRenderingFunction = function void(VkCommandBuffer commandBuffer);
	private static vkCmdEndRenderingFunction vkCmdEndRendering_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdEndRendering(VkCommandBuffer commandBuffer)
		=> vkCmdEndRendering_ptr(commandBuffer);

	public typealias vkCmdSetCullModeFunction = function void(VkCommandBuffer commandBuffer, VkCullModeFlags cullMode);
	private static vkCmdSetCullModeFunction vkCmdSetCullMode_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetCullMode(VkCommandBuffer commandBuffer, VkCullModeFlags cullMode)
		=> vkCmdSetCullMode_ptr(commandBuffer, cullMode);

	public typealias vkCmdSetFrontFaceFunction = function void(VkCommandBuffer commandBuffer, VkFrontFace frontFace);
	private static vkCmdSetFrontFaceFunction vkCmdSetFrontFace_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetFrontFace(VkCommandBuffer commandBuffer, VkFrontFace frontFace)
		=> vkCmdSetFrontFace_ptr(commandBuffer, frontFace);

	public typealias vkCmdSetPrimitiveTopologyFunction = function void(VkCommandBuffer commandBuffer, VkPrimitiveTopology primitiveTopology);
	private static vkCmdSetPrimitiveTopologyFunction vkCmdSetPrimitiveTopology_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetPrimitiveTopology(VkCommandBuffer commandBuffer, VkPrimitiveTopology primitiveTopology)
		=> vkCmdSetPrimitiveTopology_ptr(commandBuffer, primitiveTopology);

	public typealias vkCmdSetViewportWithCountFunction = function void(VkCommandBuffer commandBuffer, uint32 viewportCount, VkViewport* pViewports);
	private static vkCmdSetViewportWithCountFunction vkCmdSetViewportWithCount_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetViewportWithCount(VkCommandBuffer commandBuffer, uint32 viewportCount, VkViewport* pViewports)
		=> vkCmdSetViewportWithCount_ptr(commandBuffer, viewportCount, pViewports);

	public typealias vkCmdSetScissorWithCountFunction = function void(VkCommandBuffer commandBuffer, uint32 scissorCount, VkRect2D* pScissors);
	private static vkCmdSetScissorWithCountFunction vkCmdSetScissorWithCount_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetScissorWithCount(VkCommandBuffer commandBuffer, uint32 scissorCount, VkRect2D* pScissors)
		=> vkCmdSetScissorWithCount_ptr(commandBuffer, scissorCount, pScissors);

	public typealias vkCmdBindVertexBuffers2Function = function void(VkCommandBuffer commandBuffer, uint32 firstBinding, uint32 bindingCount, VkBuffer* pBuffers, uint64* pOffsets, uint64* pSizes, uint64* pStrides);
	private static vkCmdBindVertexBuffers2Function vkCmdBindVertexBuffers2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindVertexBuffers2(VkCommandBuffer commandBuffer, uint32 firstBinding, uint32 bindingCount, VkBuffer* pBuffers, uint64* pOffsets, uint64* pSizes, uint64* pStrides)
		=> vkCmdBindVertexBuffers2_ptr(commandBuffer, firstBinding, bindingCount, pBuffers, pOffsets, pSizes, pStrides);

	public typealias vkCmdSetDepthTestEnableFunction = function void(VkCommandBuffer commandBuffer, VkBool32 depthTestEnable);
	private static vkCmdSetDepthTestEnableFunction vkCmdSetDepthTestEnable_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDepthTestEnable(VkCommandBuffer commandBuffer, VkBool32 depthTestEnable)
		=> vkCmdSetDepthTestEnable_ptr(commandBuffer, depthTestEnable);

	public typealias vkCmdSetDepthWriteEnableFunction = function void(VkCommandBuffer commandBuffer, VkBool32 depthWriteEnable);
	private static vkCmdSetDepthWriteEnableFunction vkCmdSetDepthWriteEnable_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDepthWriteEnable(VkCommandBuffer commandBuffer, VkBool32 depthWriteEnable)
		=> vkCmdSetDepthWriteEnable_ptr(commandBuffer, depthWriteEnable);

	public typealias vkCmdSetDepthCompareOpFunction = function void(VkCommandBuffer commandBuffer, VkCompareOp depthCompareOp);
	private static vkCmdSetDepthCompareOpFunction vkCmdSetDepthCompareOp_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDepthCompareOp(VkCommandBuffer commandBuffer, VkCompareOp depthCompareOp)
		=> vkCmdSetDepthCompareOp_ptr(commandBuffer, depthCompareOp);

	public typealias vkCmdSetDepthBoundsTestEnableFunction = function void(VkCommandBuffer commandBuffer, VkBool32 depthBoundsTestEnable);
	private static vkCmdSetDepthBoundsTestEnableFunction vkCmdSetDepthBoundsTestEnable_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDepthBoundsTestEnable(VkCommandBuffer commandBuffer, VkBool32 depthBoundsTestEnable)
		=> vkCmdSetDepthBoundsTestEnable_ptr(commandBuffer, depthBoundsTestEnable);

	public typealias vkCmdSetStencilTestEnableFunction = function void(VkCommandBuffer commandBuffer, VkBool32 stencilTestEnable);
	private static vkCmdSetStencilTestEnableFunction vkCmdSetStencilTestEnable_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetStencilTestEnable(VkCommandBuffer commandBuffer, VkBool32 stencilTestEnable)
		=> vkCmdSetStencilTestEnable_ptr(commandBuffer, stencilTestEnable);

	public typealias vkCmdSetStencilOpFunction = function void(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, VkStencilOp failOp, VkStencilOp passOp, VkStencilOp depthFailOp, VkCompareOp compareOp);
	private static vkCmdSetStencilOpFunction vkCmdSetStencilOp_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetStencilOp(VkCommandBuffer commandBuffer, VkStencilFaceFlags faceMask, VkStencilOp failOp, VkStencilOp passOp, VkStencilOp depthFailOp, VkCompareOp compareOp)
		=> vkCmdSetStencilOp_ptr(commandBuffer, faceMask, failOp, passOp, depthFailOp, compareOp);

	public typealias vkCmdSetRasterizerDiscardEnableFunction = function void(VkCommandBuffer commandBuffer, VkBool32 rasterizerDiscardEnable);
	private static vkCmdSetRasterizerDiscardEnableFunction vkCmdSetRasterizerDiscardEnable_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetRasterizerDiscardEnable(VkCommandBuffer commandBuffer, VkBool32 rasterizerDiscardEnable)
		=> vkCmdSetRasterizerDiscardEnable_ptr(commandBuffer, rasterizerDiscardEnable);

	public typealias vkCmdSetDepthBiasEnableFunction = function void(VkCommandBuffer commandBuffer, VkBool32 depthBiasEnable);
	private static vkCmdSetDepthBiasEnableFunction vkCmdSetDepthBiasEnable_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDepthBiasEnable(VkCommandBuffer commandBuffer, VkBool32 depthBiasEnable)
		=> vkCmdSetDepthBiasEnable_ptr(commandBuffer, depthBiasEnable);

	public typealias vkCmdSetPrimitiveRestartEnableFunction = function void(VkCommandBuffer commandBuffer, VkBool32 primitiveRestartEnable);
	private static vkCmdSetPrimitiveRestartEnableFunction vkCmdSetPrimitiveRestartEnable_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetPrimitiveRestartEnable(VkCommandBuffer commandBuffer, VkBool32 primitiveRestartEnable)
		=> vkCmdSetPrimitiveRestartEnable_ptr(commandBuffer, primitiveRestartEnable);

	public typealias vkMapMemory2Function = function VkResult(VkDevice device, VkMemoryMapInfo* pMemoryMapInfo, void** ppData);
	private static vkMapMemory2Function vkMapMemory2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkMapMemory2(VkDevice device, VkMemoryMapInfo* pMemoryMapInfo, void** ppData)
		=> vkMapMemory2_ptr(device, pMemoryMapInfo, ppData);

	public typealias vkUnmapMemory2Function = function VkResult(VkDevice device, VkMemoryUnmapInfo* pMemoryUnmapInfo);
	private static vkUnmapMemory2Function vkUnmapMemory2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkUnmapMemory2(VkDevice device, VkMemoryUnmapInfo* pMemoryUnmapInfo)
		=> vkUnmapMemory2_ptr(device, pMemoryUnmapInfo);

	public typealias vkGetDeviceImageSubresourceLayoutFunction = function void(VkDevice device, VkDeviceImageSubresourceInfo* pInfo, VkSubresourceLayout2* pLayout);
	private static vkGetDeviceImageSubresourceLayoutFunction vkGetDeviceImageSubresourceLayout_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDeviceImageSubresourceLayout(VkDevice device, VkDeviceImageSubresourceInfo* pInfo, VkSubresourceLayout2* pLayout)
		=> vkGetDeviceImageSubresourceLayout_ptr(device, pInfo, pLayout);

	public typealias vkGetImageSubresourceLayout2Function = function void(VkDevice device, VkImage image, VkImageSubresource2* pSubresource, VkSubresourceLayout2* pLayout);
	private static vkGetImageSubresourceLayout2Function vkGetImageSubresourceLayout2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetImageSubresourceLayout2(VkDevice device, VkImage image, VkImageSubresource2* pSubresource, VkSubresourceLayout2* pLayout)
		=> vkGetImageSubresourceLayout2_ptr(device, image, pSubresource, pLayout);

	public typealias vkCopyMemoryToImageFunction = function VkResult(VkDevice device, VkCopyMemoryToImageInfo* pCopyMemoryToImageInfo);
	private static vkCopyMemoryToImageFunction vkCopyMemoryToImage_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCopyMemoryToImage(VkDevice device, VkCopyMemoryToImageInfo* pCopyMemoryToImageInfo)
		=> vkCopyMemoryToImage_ptr(device, pCopyMemoryToImageInfo);

	public typealias vkCopyImageToMemoryFunction = function VkResult(VkDevice device, VkCopyImageToMemoryInfo* pCopyImageToMemoryInfo);
	private static vkCopyImageToMemoryFunction vkCopyImageToMemory_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCopyImageToMemory(VkDevice device, VkCopyImageToMemoryInfo* pCopyImageToMemoryInfo)
		=> vkCopyImageToMemory_ptr(device, pCopyImageToMemoryInfo);

	public typealias vkCopyImageToImageFunction = function VkResult(VkDevice device, VkCopyImageToImageInfo* pCopyImageToImageInfo);
	private static vkCopyImageToImageFunction vkCopyImageToImage_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCopyImageToImage(VkDevice device, VkCopyImageToImageInfo* pCopyImageToImageInfo)
		=> vkCopyImageToImage_ptr(device, pCopyImageToImageInfo);

	public typealias vkTransitionImageLayoutFunction = function VkResult(VkDevice device, uint32 transitionCount, VkHostImageLayoutTransitionInfo* pTransitions);
	private static vkTransitionImageLayoutFunction vkTransitionImageLayout_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkTransitionImageLayout(VkDevice device, uint32 transitionCount, VkHostImageLayoutTransitionInfo* pTransitions)
		=> vkTransitionImageLayout_ptr(device, transitionCount, pTransitions);

	public typealias vkCmdPushDescriptorSetFunction = function void(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32 set, uint32 descriptorWriteCount, VkWriteDescriptorSet* pDescriptorWrites);
	private static vkCmdPushDescriptorSetFunction vkCmdPushDescriptorSet_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdPushDescriptorSet(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32 set, uint32 descriptorWriteCount, VkWriteDescriptorSet* pDescriptorWrites)
		=> vkCmdPushDescriptorSet_ptr(commandBuffer, pipelineBindPoint, layout, set, descriptorWriteCount, pDescriptorWrites);

	public typealias vkCmdPushDescriptorSetWithTemplateFunction = function void(VkCommandBuffer commandBuffer, VkDescriptorUpdateTemplate descriptorUpdateTemplate, VkPipelineLayout layout, uint32 set, void* pData);
	private static vkCmdPushDescriptorSetWithTemplateFunction vkCmdPushDescriptorSetWithTemplate_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdPushDescriptorSetWithTemplate(VkCommandBuffer commandBuffer, VkDescriptorUpdateTemplate descriptorUpdateTemplate, VkPipelineLayout layout, uint32 set, void* pData)
		=> vkCmdPushDescriptorSetWithTemplate_ptr(commandBuffer, descriptorUpdateTemplate, layout, set, pData);

	public typealias vkCmdBindDescriptorSets2Function = function void(VkCommandBuffer commandBuffer, VkBindDescriptorSetsInfo* pBindDescriptorSetsInfo);
	private static vkCmdBindDescriptorSets2Function vkCmdBindDescriptorSets2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindDescriptorSets2(VkCommandBuffer commandBuffer, VkBindDescriptorSetsInfo* pBindDescriptorSetsInfo)
		=> vkCmdBindDescriptorSets2_ptr(commandBuffer, pBindDescriptorSetsInfo);

	public typealias vkCmdPushConstants2Function = function void(VkCommandBuffer commandBuffer, VkPushConstantsInfo* pPushConstantsInfo);
	private static vkCmdPushConstants2Function vkCmdPushConstants2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdPushConstants2(VkCommandBuffer commandBuffer, VkPushConstantsInfo* pPushConstantsInfo)
		=> vkCmdPushConstants2_ptr(commandBuffer, pPushConstantsInfo);

	public typealias vkCmdPushDescriptorSet2Function = function void(VkCommandBuffer commandBuffer, VkPushDescriptorSetInfo* pPushDescriptorSetInfo);
	private static vkCmdPushDescriptorSet2Function vkCmdPushDescriptorSet2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdPushDescriptorSet2(VkCommandBuffer commandBuffer, VkPushDescriptorSetInfo* pPushDescriptorSetInfo)
		=> vkCmdPushDescriptorSet2_ptr(commandBuffer, pPushDescriptorSetInfo);

	public typealias vkCmdPushDescriptorSetWithTemplate2Function = function void(VkCommandBuffer commandBuffer, VkPushDescriptorSetWithTemplateInfo* pPushDescriptorSetWithTemplateInfo);
	private static vkCmdPushDescriptorSetWithTemplate2Function vkCmdPushDescriptorSetWithTemplate2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdPushDescriptorSetWithTemplate2(VkCommandBuffer commandBuffer, VkPushDescriptorSetWithTemplateInfo* pPushDescriptorSetWithTemplateInfo)
		=> vkCmdPushDescriptorSetWithTemplate2_ptr(commandBuffer, pPushDescriptorSetWithTemplateInfo);

	public typealias vkCmdSetLineStippleFunction = function void(VkCommandBuffer commandBuffer, uint32 lineStippleFactor, uint16 lineStipplePattern);
	private static vkCmdSetLineStippleFunction vkCmdSetLineStipple_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetLineStipple(VkCommandBuffer commandBuffer, uint32 lineStippleFactor, uint16 lineStipplePattern)
		=> vkCmdSetLineStipple_ptr(commandBuffer, lineStippleFactor, lineStipplePattern);

	public typealias vkCmdBindIndexBuffer2Function = function void(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, uint64 size, VkIndexType indexType);
	private static vkCmdBindIndexBuffer2Function vkCmdBindIndexBuffer2_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindIndexBuffer2(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, uint64 size, VkIndexType indexType)
		=> vkCmdBindIndexBuffer2_ptr(commandBuffer, buffer, offset, size, indexType);

	public typealias vkGetRenderingAreaGranularityFunction = function void(VkDevice device, VkRenderingAreaInfo* pRenderingAreaInfo, VkExtent2D* pGranularity);
	private static vkGetRenderingAreaGranularityFunction vkGetRenderingAreaGranularity_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetRenderingAreaGranularity(VkDevice device, VkRenderingAreaInfo* pRenderingAreaInfo, VkExtent2D* pGranularity)
		=> vkGetRenderingAreaGranularity_ptr(device, pRenderingAreaInfo, pGranularity);

	public typealias vkCmdSetRenderingAttachmentLocationsFunction = function void(VkCommandBuffer commandBuffer, VkRenderingAttachmentLocationInfo* pLocationInfo);
	private static vkCmdSetRenderingAttachmentLocationsFunction vkCmdSetRenderingAttachmentLocations_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetRenderingAttachmentLocations(VkCommandBuffer commandBuffer, VkRenderingAttachmentLocationInfo* pLocationInfo)
		=> vkCmdSetRenderingAttachmentLocations_ptr(commandBuffer, pLocationInfo);

	public typealias vkCmdSetRenderingInputAttachmentIndicesFunction = function void(VkCommandBuffer commandBuffer, VkRenderingInputAttachmentIndexInfo* pInputAttachmentIndexInfo);
	private static vkCmdSetRenderingInputAttachmentIndicesFunction vkCmdSetRenderingInputAttachmentIndices_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetRenderingInputAttachmentIndices(VkCommandBuffer commandBuffer, VkRenderingInputAttachmentIndexInfo* pInputAttachmentIndexInfo)
		=> vkCmdSetRenderingInputAttachmentIndices_ptr(commandBuffer, pInputAttachmentIndexInfo);

	public typealias vkGetCommandPoolMemoryConsumptionFunction = function void(VkDevice device, VkCommandPool commandPool, VkCommandBuffer commandBuffer, VkCommandPoolMemoryConsumption* pConsumption);
	private static vkGetCommandPoolMemoryConsumptionFunction vkGetCommandPoolMemoryConsumption_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetCommandPoolMemoryConsumption(VkDevice device, VkCommandPool commandPool, VkCommandBuffer commandBuffer, VkCommandPoolMemoryConsumption* pConsumption)
		=> vkGetCommandPoolMemoryConsumption_ptr(device, commandPool, commandBuffer, pConsumption);

	public typealias vkGetFaultDataFunction = function VkResult(VkDevice device, VkFaultQueryBehavior faultQueryBehavior, VkBool32* pUnrecordedFaults, uint32* pFaultCount, VkFaultData* pFaults);
	private static vkGetFaultDataFunction vkGetFaultData_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetFaultData(VkDevice device, VkFaultQueryBehavior faultQueryBehavior, VkBool32* pUnrecordedFaults, uint32* pFaultCount, VkFaultData* pFaults)
		=> vkGetFaultData_ptr(device, faultQueryBehavior, pUnrecordedFaults, pFaultCount, pFaults);

	public typealias vkDestroySurfaceKHRFunction = function void(VkInstance instance, VkSurfaceKHR surface, VkAllocationCallbacks* pAllocator);
	private static vkDestroySurfaceKHRFunction vkDestroySurfaceKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroySurfaceKHR(VkInstance instance, VkSurfaceKHR surface, VkAllocationCallbacks* pAllocator)
		=> vkDestroySurfaceKHR_ptr(instance, surface, pAllocator);

	public typealias vkGetPhysicalDeviceSurfaceSupportKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, VkSurfaceKHR surface, VkBool32* pSupported);
	private static vkGetPhysicalDeviceSurfaceSupportKHRFunction vkGetPhysicalDeviceSurfaceSupportKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceSurfaceSupportKHR(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, VkSurfaceKHR surface, VkBool32* pSupported)
		=> vkGetPhysicalDeviceSurfaceSupportKHR_ptr(physicalDevice, queueFamilyIndex, surface, pSupported);

	public typealias vkGetPhysicalDeviceSurfaceCapabilitiesKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, VkSurfaceCapabilitiesKHR* pSurfaceCapabilities);
	private static vkGetPhysicalDeviceSurfaceCapabilitiesKHRFunction vkGetPhysicalDeviceSurfaceCapabilitiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceSurfaceCapabilitiesKHR(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, VkSurfaceCapabilitiesKHR* pSurfaceCapabilities)
		=> vkGetPhysicalDeviceSurfaceCapabilitiesKHR_ptr(physicalDevice, surface, pSurfaceCapabilities);

	public typealias vkGetPhysicalDeviceSurfaceFormatsKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32* pSurfaceFormatCount, VkSurfaceFormatKHR* pSurfaceFormats);
	private static vkGetPhysicalDeviceSurfaceFormatsKHRFunction vkGetPhysicalDeviceSurfaceFormatsKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceSurfaceFormatsKHR(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32* pSurfaceFormatCount, VkSurfaceFormatKHR* pSurfaceFormats)
		=> vkGetPhysicalDeviceSurfaceFormatsKHR_ptr(physicalDevice, surface, pSurfaceFormatCount, pSurfaceFormats);

	public typealias vkGetPhysicalDeviceSurfacePresentModesKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32* pPresentModeCount, VkPresentModeKHR* pPresentModes);
	private static vkGetPhysicalDeviceSurfacePresentModesKHRFunction vkGetPhysicalDeviceSurfacePresentModesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceSurfacePresentModesKHR(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32* pPresentModeCount, VkPresentModeKHR* pPresentModes)
		=> vkGetPhysicalDeviceSurfacePresentModesKHR_ptr(physicalDevice, surface, pPresentModeCount, pPresentModes);

	public typealias vkCreateSwapchainKHRFunction = function VkResult(VkDevice device, VkSwapchainCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSwapchainKHR* pSwapchain);
	private static vkCreateSwapchainKHRFunction vkCreateSwapchainKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateSwapchainKHR(VkDevice device, VkSwapchainCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSwapchainKHR* pSwapchain)
		=> vkCreateSwapchainKHR_ptr(device, pCreateInfo, pAllocator, pSwapchain);

	public typealias vkDestroySwapchainKHRFunction = function void(VkDevice device, VkSwapchainKHR swapchain, VkAllocationCallbacks* pAllocator);
	private static vkDestroySwapchainKHRFunction vkDestroySwapchainKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroySwapchainKHR(VkDevice device, VkSwapchainKHR swapchain, VkAllocationCallbacks* pAllocator)
		=> vkDestroySwapchainKHR_ptr(device, swapchain, pAllocator);

	public typealias vkGetSwapchainImagesKHRFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain, uint32* pSwapchainImageCount, VkImage* pSwapchainImages);
	private static vkGetSwapchainImagesKHRFunction vkGetSwapchainImagesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetSwapchainImagesKHR(VkDevice device, VkSwapchainKHR swapchain, uint32* pSwapchainImageCount, VkImage* pSwapchainImages)
		=> vkGetSwapchainImagesKHR_ptr(device, swapchain, pSwapchainImageCount, pSwapchainImages);

	public typealias vkAcquireNextImageKHRFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain, uint64 timeout, VkSemaphore semaphore, VkFence fence, uint32* pImageIndex);
	private static vkAcquireNextImageKHRFunction vkAcquireNextImageKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkAcquireNextImageKHR(VkDevice device, VkSwapchainKHR swapchain, uint64 timeout, VkSemaphore semaphore, VkFence fence, uint32* pImageIndex)
		=> vkAcquireNextImageKHR_ptr(device, swapchain, timeout, semaphore, fence, pImageIndex);

	public typealias vkQueuePresentKHRFunction = function VkResult(VkQueue queue, VkPresentInfoKHR* pPresentInfo);
	private static vkQueuePresentKHRFunction vkQueuePresentKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkQueuePresentKHR(VkQueue queue, VkPresentInfoKHR* pPresentInfo)
		=> vkQueuePresentKHR_ptr(queue, pPresentInfo);

	public typealias vkGetDeviceGroupPresentCapabilitiesKHRFunction = function VkResult(VkDevice device, VkDeviceGroupPresentCapabilitiesKHR* pDeviceGroupPresentCapabilities);
	private static vkGetDeviceGroupPresentCapabilitiesKHRFunction vkGetDeviceGroupPresentCapabilitiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDeviceGroupPresentCapabilitiesKHR(VkDevice device, VkDeviceGroupPresentCapabilitiesKHR* pDeviceGroupPresentCapabilities)
		=> vkGetDeviceGroupPresentCapabilitiesKHR_ptr(device, pDeviceGroupPresentCapabilities);

	public typealias vkGetDeviceGroupSurfacePresentModesKHRFunction = function VkResult(VkDevice device, VkSurfaceKHR surface, VkDeviceGroupPresentModeFlagsKHR* pModes);
	private static vkGetDeviceGroupSurfacePresentModesKHRFunction vkGetDeviceGroupSurfacePresentModesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDeviceGroupSurfacePresentModesKHR(VkDevice device, VkSurfaceKHR surface, VkDeviceGroupPresentModeFlagsKHR* pModes)
		=> vkGetDeviceGroupSurfacePresentModesKHR_ptr(device, surface, pModes);

	public typealias vkGetPhysicalDevicePresentRectanglesKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32* pRectCount, VkRect2D* pRects);
	private static vkGetPhysicalDevicePresentRectanglesKHRFunction vkGetPhysicalDevicePresentRectanglesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDevicePresentRectanglesKHR(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, uint32* pRectCount, VkRect2D* pRects)
		=> vkGetPhysicalDevicePresentRectanglesKHR_ptr(physicalDevice, surface, pRectCount, pRects);

	public typealias vkAcquireNextImage2KHRFunction = function VkResult(VkDevice device, VkAcquireNextImageInfoKHR* pAcquireInfo, uint32* pImageIndex);
	private static vkAcquireNextImage2KHRFunction vkAcquireNextImage2KHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkAcquireNextImage2KHR(VkDevice device, VkAcquireNextImageInfoKHR* pAcquireInfo, uint32* pImageIndex)
		=> vkAcquireNextImage2KHR_ptr(device, pAcquireInfo, pImageIndex);

	public typealias vkGetPhysicalDeviceDisplayPropertiesKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkDisplayPropertiesKHR* pProperties);
	private static vkGetPhysicalDeviceDisplayPropertiesKHRFunction vkGetPhysicalDeviceDisplayPropertiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceDisplayPropertiesKHR(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkDisplayPropertiesKHR* pProperties)
		=> vkGetPhysicalDeviceDisplayPropertiesKHR_ptr(physicalDevice, pPropertyCount, pProperties);

	public typealias vkGetPhysicalDeviceDisplayPlanePropertiesKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkDisplayPlanePropertiesKHR* pProperties);
	private static vkGetPhysicalDeviceDisplayPlanePropertiesKHRFunction vkGetPhysicalDeviceDisplayPlanePropertiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceDisplayPlanePropertiesKHR(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkDisplayPlanePropertiesKHR* pProperties)
		=> vkGetPhysicalDeviceDisplayPlanePropertiesKHR_ptr(physicalDevice, pPropertyCount, pProperties);

	public typealias vkGetDisplayPlaneSupportedDisplaysKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32 planeIndex, uint32* pDisplayCount, VkDisplayKHR* pDisplays);
	private static vkGetDisplayPlaneSupportedDisplaysKHRFunction vkGetDisplayPlaneSupportedDisplaysKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDisplayPlaneSupportedDisplaysKHR(VkPhysicalDevice physicalDevice, uint32 planeIndex, uint32* pDisplayCount, VkDisplayKHR* pDisplays)
		=> vkGetDisplayPlaneSupportedDisplaysKHR_ptr(physicalDevice, planeIndex, pDisplayCount, pDisplays);

	public typealias vkGetDisplayModePropertiesKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkDisplayKHR display, uint32* pPropertyCount, VkDisplayModePropertiesKHR* pProperties);
	private static vkGetDisplayModePropertiesKHRFunction vkGetDisplayModePropertiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDisplayModePropertiesKHR(VkPhysicalDevice physicalDevice, VkDisplayKHR display, uint32* pPropertyCount, VkDisplayModePropertiesKHR* pProperties)
		=> vkGetDisplayModePropertiesKHR_ptr(physicalDevice, display, pPropertyCount, pProperties);

	public typealias vkCreateDisplayModeKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkDisplayKHR display, VkDisplayModeCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDisplayModeKHR* pMode);
	private static vkCreateDisplayModeKHRFunction vkCreateDisplayModeKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateDisplayModeKHR(VkPhysicalDevice physicalDevice, VkDisplayKHR display, VkDisplayModeCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDisplayModeKHR* pMode)
		=> vkCreateDisplayModeKHR_ptr(physicalDevice, display, pCreateInfo, pAllocator, pMode);

	public typealias vkGetDisplayPlaneCapabilitiesKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkDisplayModeKHR mode, uint32 planeIndex, VkDisplayPlaneCapabilitiesKHR* pCapabilities);
	private static vkGetDisplayPlaneCapabilitiesKHRFunction vkGetDisplayPlaneCapabilitiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDisplayPlaneCapabilitiesKHR(VkPhysicalDevice physicalDevice, VkDisplayModeKHR mode, uint32 planeIndex, VkDisplayPlaneCapabilitiesKHR* pCapabilities)
		=> vkGetDisplayPlaneCapabilitiesKHR_ptr(physicalDevice, mode, planeIndex, pCapabilities);

	public typealias vkCreateDisplayPlaneSurfaceKHRFunction = function VkResult(VkInstance instance, VkDisplaySurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateDisplayPlaneSurfaceKHRFunction vkCreateDisplayPlaneSurfaceKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateDisplayPlaneSurfaceKHR(VkInstance instance, VkDisplaySurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateDisplayPlaneSurfaceKHR_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkCreateSharedSwapchainsKHRFunction = function VkResult(VkDevice device, uint32 swapchainCount, VkSwapchainCreateInfoKHR* pCreateInfos, VkAllocationCallbacks* pAllocator, VkSwapchainKHR* pSwapchains);
	private static vkCreateSharedSwapchainsKHRFunction vkCreateSharedSwapchainsKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateSharedSwapchainsKHR(VkDevice device, uint32 swapchainCount, VkSwapchainCreateInfoKHR* pCreateInfos, VkAllocationCallbacks* pAllocator, VkSwapchainKHR* pSwapchains)
		=> vkCreateSharedSwapchainsKHR_ptr(device, swapchainCount, pCreateInfos, pAllocator, pSwapchains);

	public typealias vkCreateXlibSurfaceKHRFunction = function VkResult(VkInstance instance, VkXlibSurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateXlibSurfaceKHRFunction vkCreateXlibSurfaceKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateXlibSurfaceKHR(VkInstance instance, VkXlibSurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateXlibSurfaceKHR_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkGetPhysicalDeviceXlibPresentationSupportKHRFunction = function VkBool32(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, void* dpy, void* visualID);
	private static vkGetPhysicalDeviceXlibPresentationSupportKHRFunction vkGetPhysicalDeviceXlibPresentationSupportKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkBool32 vkGetPhysicalDeviceXlibPresentationSupportKHR(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, void* dpy, void* visualID)
		=> vkGetPhysicalDeviceXlibPresentationSupportKHR_ptr(physicalDevice, queueFamilyIndex, dpy, visualID);

	public typealias vkCreateXcbSurfaceKHRFunction = function VkResult(VkInstance instance, VkXcbSurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateXcbSurfaceKHRFunction vkCreateXcbSurfaceKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateXcbSurfaceKHR(VkInstance instance, VkXcbSurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateXcbSurfaceKHR_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkGetPhysicalDeviceXcbPresentationSupportKHRFunction = function VkBool32(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, void* connection, void* visual_id);
	private static vkGetPhysicalDeviceXcbPresentationSupportKHRFunction vkGetPhysicalDeviceXcbPresentationSupportKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkBool32 vkGetPhysicalDeviceXcbPresentationSupportKHR(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, void* connection, void* visual_id)
		=> vkGetPhysicalDeviceXcbPresentationSupportKHR_ptr(physicalDevice, queueFamilyIndex, connection, visual_id);

	public typealias vkCreateWaylandSurfaceKHRFunction = function VkResult(VkInstance instance, VkWaylandSurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateWaylandSurfaceKHRFunction vkCreateWaylandSurfaceKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateWaylandSurfaceKHR(VkInstance instance, VkWaylandSurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateWaylandSurfaceKHR_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkGetPhysicalDeviceWaylandPresentationSupportKHRFunction = function VkBool32(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, void* display);
	private static vkGetPhysicalDeviceWaylandPresentationSupportKHRFunction vkGetPhysicalDeviceWaylandPresentationSupportKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkBool32 vkGetPhysicalDeviceWaylandPresentationSupportKHR(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, void* display)
		=> vkGetPhysicalDeviceWaylandPresentationSupportKHR_ptr(physicalDevice, queueFamilyIndex, display);

	public typealias vkCreateAndroidSurfaceKHRFunction = function VkResult(VkInstance instance, VkAndroidSurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateAndroidSurfaceKHRFunction vkCreateAndroidSurfaceKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateAndroidSurfaceKHR(VkInstance instance, VkAndroidSurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateAndroidSurfaceKHR_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkCreateWin32SurfaceKHRFunction = function VkResult(VkInstance instance, VkWin32SurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateWin32SurfaceKHRFunction vkCreateWin32SurfaceKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateWin32SurfaceKHR(VkInstance instance, VkWin32SurfaceCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateWin32SurfaceKHR_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkGetPhysicalDeviceWin32PresentationSupportKHRFunction = function VkBool32(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex);
	private static vkGetPhysicalDeviceWin32PresentationSupportKHRFunction vkGetPhysicalDeviceWin32PresentationSupportKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkBool32 vkGetPhysicalDeviceWin32PresentationSupportKHR(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex)
		=> vkGetPhysicalDeviceWin32PresentationSupportKHR_ptr(physicalDevice, queueFamilyIndex);

	public typealias vkCreateDebugReportCallbackEXTFunction = function VkResult(VkInstance instance, VkDebugReportCallbackCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDebugReportCallbackEXT* pCallback);
	private static vkCreateDebugReportCallbackEXTFunction vkCreateDebugReportCallbackEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateDebugReportCallbackEXT(VkInstance instance, VkDebugReportCallbackCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDebugReportCallbackEXT* pCallback)
		=> vkCreateDebugReportCallbackEXT_ptr(instance, pCreateInfo, pAllocator, pCallback);

	public typealias vkDestroyDebugReportCallbackEXTFunction = function void(VkInstance instance, VkDebugReportCallbackEXT callback, VkAllocationCallbacks* pAllocator);
	private static vkDestroyDebugReportCallbackEXTFunction vkDestroyDebugReportCallbackEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyDebugReportCallbackEXT(VkInstance instance, VkDebugReportCallbackEXT callback, VkAllocationCallbacks* pAllocator)
		=> vkDestroyDebugReportCallbackEXT_ptr(instance, callback, pAllocator);

	public typealias vkDebugReportMessageEXTFunction = function void(VkInstance instance, VkDebugReportFlagsEXT flags, VkDebugReportObjectTypeEXT objectType, uint64 object, uint location, int32 messageCode, char8* pLayerPrefix, char8* pMessage);
	private static vkDebugReportMessageEXTFunction vkDebugReportMessageEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDebugReportMessageEXT(VkInstance instance, VkDebugReportFlagsEXT flags, VkDebugReportObjectTypeEXT objectType, uint64 object, uint location, int32 messageCode, char8* pLayerPrefix, char8* pMessage)
		=> vkDebugReportMessageEXT_ptr(instance, flags, objectType, object, location, messageCode, pLayerPrefix, pMessage);

	public typealias vkDebugMarkerSetObjectTagEXTFunction = function VkResult(VkDevice device, VkDebugMarkerObjectTagInfoEXT* pTagInfo);
	private static vkDebugMarkerSetObjectTagEXTFunction vkDebugMarkerSetObjectTagEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkDebugMarkerSetObjectTagEXT(VkDevice device, VkDebugMarkerObjectTagInfoEXT* pTagInfo)
		=> vkDebugMarkerSetObjectTagEXT_ptr(device, pTagInfo);

	public typealias vkDebugMarkerSetObjectNameEXTFunction = function VkResult(VkDevice device, VkDebugMarkerObjectNameInfoEXT* pNameInfo);
	private static vkDebugMarkerSetObjectNameEXTFunction vkDebugMarkerSetObjectNameEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkDebugMarkerSetObjectNameEXT(VkDevice device, VkDebugMarkerObjectNameInfoEXT* pNameInfo)
		=> vkDebugMarkerSetObjectNameEXT_ptr(device, pNameInfo);

	public typealias vkCmdDebugMarkerBeginEXTFunction = function void(VkCommandBuffer commandBuffer, VkDebugMarkerMarkerInfoEXT* pMarkerInfo);
	private static vkCmdDebugMarkerBeginEXTFunction vkCmdDebugMarkerBeginEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDebugMarkerBeginEXT(VkCommandBuffer commandBuffer, VkDebugMarkerMarkerInfoEXT* pMarkerInfo)
		=> vkCmdDebugMarkerBeginEXT_ptr(commandBuffer, pMarkerInfo);

	public typealias vkCmdDebugMarkerEndEXTFunction = function void(VkCommandBuffer commandBuffer);
	private static vkCmdDebugMarkerEndEXTFunction vkCmdDebugMarkerEndEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDebugMarkerEndEXT(VkCommandBuffer commandBuffer)
		=> vkCmdDebugMarkerEndEXT_ptr(commandBuffer);

	public typealias vkCmdDebugMarkerInsertEXTFunction = function void(VkCommandBuffer commandBuffer, VkDebugMarkerMarkerInfoEXT* pMarkerInfo);
	private static vkCmdDebugMarkerInsertEXTFunction vkCmdDebugMarkerInsertEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDebugMarkerInsertEXT(VkCommandBuffer commandBuffer, VkDebugMarkerMarkerInfoEXT* pMarkerInfo)
		=> vkCmdDebugMarkerInsertEXT_ptr(commandBuffer, pMarkerInfo);

	public typealias vkGetPhysicalDeviceVideoCapabilitiesKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkVideoProfileInfoKHR* pVideoProfile, VkVideoCapabilitiesKHR* pCapabilities);
	private static vkGetPhysicalDeviceVideoCapabilitiesKHRFunction vkGetPhysicalDeviceVideoCapabilitiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceVideoCapabilitiesKHR(VkPhysicalDevice physicalDevice, VkVideoProfileInfoKHR* pVideoProfile, VkVideoCapabilitiesKHR* pCapabilities)
		=> vkGetPhysicalDeviceVideoCapabilitiesKHR_ptr(physicalDevice, pVideoProfile, pCapabilities);

	public typealias vkGetPhysicalDeviceVideoFormatPropertiesKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkPhysicalDeviceVideoFormatInfoKHR* pVideoFormatInfo, uint32* pVideoFormatPropertyCount, VkVideoFormatPropertiesKHR* pVideoFormatProperties);
	private static vkGetPhysicalDeviceVideoFormatPropertiesKHRFunction vkGetPhysicalDeviceVideoFormatPropertiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceVideoFormatPropertiesKHR(VkPhysicalDevice physicalDevice, VkPhysicalDeviceVideoFormatInfoKHR* pVideoFormatInfo, uint32* pVideoFormatPropertyCount, VkVideoFormatPropertiesKHR* pVideoFormatProperties)
		=> vkGetPhysicalDeviceVideoFormatPropertiesKHR_ptr(physicalDevice, pVideoFormatInfo, pVideoFormatPropertyCount, pVideoFormatProperties);

	public typealias vkCreateVideoSessionKHRFunction = function VkResult(VkDevice device, VkVideoSessionCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkVideoSessionKHR* pVideoSession);
	private static vkCreateVideoSessionKHRFunction vkCreateVideoSessionKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateVideoSessionKHR(VkDevice device, VkVideoSessionCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkVideoSessionKHR* pVideoSession)
		=> vkCreateVideoSessionKHR_ptr(device, pCreateInfo, pAllocator, pVideoSession);

	public typealias vkDestroyVideoSessionKHRFunction = function void(VkDevice device, VkVideoSessionKHR videoSession, VkAllocationCallbacks* pAllocator);
	private static vkDestroyVideoSessionKHRFunction vkDestroyVideoSessionKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyVideoSessionKHR(VkDevice device, VkVideoSessionKHR videoSession, VkAllocationCallbacks* pAllocator)
		=> vkDestroyVideoSessionKHR_ptr(device, videoSession, pAllocator);

	public typealias vkGetVideoSessionMemoryRequirementsKHRFunction = function VkResult(VkDevice device, VkVideoSessionKHR videoSession, uint32* pMemoryRequirementsCount, VkVideoSessionMemoryRequirementsKHR* pMemoryRequirements);
	private static vkGetVideoSessionMemoryRequirementsKHRFunction vkGetVideoSessionMemoryRequirementsKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetVideoSessionMemoryRequirementsKHR(VkDevice device, VkVideoSessionKHR videoSession, uint32* pMemoryRequirementsCount, VkVideoSessionMemoryRequirementsKHR* pMemoryRequirements)
		=> vkGetVideoSessionMemoryRequirementsKHR_ptr(device, videoSession, pMemoryRequirementsCount, pMemoryRequirements);

	public typealias vkBindVideoSessionMemoryKHRFunction = function VkResult(VkDevice device, VkVideoSessionKHR videoSession, uint32 bindSessionMemoryInfoCount, VkBindVideoSessionMemoryInfoKHR* pBindSessionMemoryInfos);
	private static vkBindVideoSessionMemoryKHRFunction vkBindVideoSessionMemoryKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkBindVideoSessionMemoryKHR(VkDevice device, VkVideoSessionKHR videoSession, uint32 bindSessionMemoryInfoCount, VkBindVideoSessionMemoryInfoKHR* pBindSessionMemoryInfos)
		=> vkBindVideoSessionMemoryKHR_ptr(device, videoSession, bindSessionMemoryInfoCount, pBindSessionMemoryInfos);

	public typealias vkCreateVideoSessionParametersKHRFunction = function VkResult(VkDevice device, VkVideoSessionParametersCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkVideoSessionParametersKHR* pVideoSessionParameters);
	private static vkCreateVideoSessionParametersKHRFunction vkCreateVideoSessionParametersKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateVideoSessionParametersKHR(VkDevice device, VkVideoSessionParametersCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkVideoSessionParametersKHR* pVideoSessionParameters)
		=> vkCreateVideoSessionParametersKHR_ptr(device, pCreateInfo, pAllocator, pVideoSessionParameters);

	public typealias vkUpdateVideoSessionParametersKHRFunction = function VkResult(VkDevice device, VkVideoSessionParametersKHR videoSessionParameters, VkVideoSessionParametersUpdateInfoKHR* pUpdateInfo);
	private static vkUpdateVideoSessionParametersKHRFunction vkUpdateVideoSessionParametersKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkUpdateVideoSessionParametersKHR(VkDevice device, VkVideoSessionParametersKHR videoSessionParameters, VkVideoSessionParametersUpdateInfoKHR* pUpdateInfo)
		=> vkUpdateVideoSessionParametersKHR_ptr(device, videoSessionParameters, pUpdateInfo);

	public typealias vkDestroyVideoSessionParametersKHRFunction = function void(VkDevice device, VkVideoSessionParametersKHR videoSessionParameters, VkAllocationCallbacks* pAllocator);
	private static vkDestroyVideoSessionParametersKHRFunction vkDestroyVideoSessionParametersKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyVideoSessionParametersKHR(VkDevice device, VkVideoSessionParametersKHR videoSessionParameters, VkAllocationCallbacks* pAllocator)
		=> vkDestroyVideoSessionParametersKHR_ptr(device, videoSessionParameters, pAllocator);

	public typealias vkCmdBeginVideoCodingKHRFunction = function void(VkCommandBuffer commandBuffer, VkVideoBeginCodingInfoKHR* pBeginInfo);
	private static vkCmdBeginVideoCodingKHRFunction vkCmdBeginVideoCodingKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBeginVideoCodingKHR(VkCommandBuffer commandBuffer, VkVideoBeginCodingInfoKHR* pBeginInfo)
		=> vkCmdBeginVideoCodingKHR_ptr(commandBuffer, pBeginInfo);

	public typealias vkCmdEndVideoCodingKHRFunction = function void(VkCommandBuffer commandBuffer, VkVideoEndCodingInfoKHR* pEndCodingInfo);
	private static vkCmdEndVideoCodingKHRFunction vkCmdEndVideoCodingKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdEndVideoCodingKHR(VkCommandBuffer commandBuffer, VkVideoEndCodingInfoKHR* pEndCodingInfo)
		=> vkCmdEndVideoCodingKHR_ptr(commandBuffer, pEndCodingInfo);

	public typealias vkCmdControlVideoCodingKHRFunction = function void(VkCommandBuffer commandBuffer, VkVideoCodingControlInfoKHR* pCodingControlInfo);
	private static vkCmdControlVideoCodingKHRFunction vkCmdControlVideoCodingKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdControlVideoCodingKHR(VkCommandBuffer commandBuffer, VkVideoCodingControlInfoKHR* pCodingControlInfo)
		=> vkCmdControlVideoCodingKHR_ptr(commandBuffer, pCodingControlInfo);

	public typealias vkCmdDecodeVideoKHRFunction = function void(VkCommandBuffer commandBuffer, VkVideoDecodeInfoKHR* pDecodeInfo);
	private static vkCmdDecodeVideoKHRFunction vkCmdDecodeVideoKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDecodeVideoKHR(VkCommandBuffer commandBuffer, VkVideoDecodeInfoKHR* pDecodeInfo)
		=> vkCmdDecodeVideoKHR_ptr(commandBuffer, pDecodeInfo);

	public typealias vkCmdBindTransformFeedbackBuffersEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 firstBinding, uint32 bindingCount, VkBuffer* pBuffers, uint64* pOffsets, uint64* pSizes);
	private static vkCmdBindTransformFeedbackBuffersEXTFunction vkCmdBindTransformFeedbackBuffersEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindTransformFeedbackBuffersEXT(VkCommandBuffer commandBuffer, uint32 firstBinding, uint32 bindingCount, VkBuffer* pBuffers, uint64* pOffsets, uint64* pSizes)
		=> vkCmdBindTransformFeedbackBuffersEXT_ptr(commandBuffer, firstBinding, bindingCount, pBuffers, pOffsets, pSizes);

	public typealias vkCmdBeginTransformFeedbackEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 firstCounterBuffer, uint32 counterBufferCount, VkBuffer* pCounterBuffers, uint64* pCounterBufferOffsets);
	private static vkCmdBeginTransformFeedbackEXTFunction vkCmdBeginTransformFeedbackEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBeginTransformFeedbackEXT(VkCommandBuffer commandBuffer, uint32 firstCounterBuffer, uint32 counterBufferCount, VkBuffer* pCounterBuffers, uint64* pCounterBufferOffsets)
		=> vkCmdBeginTransformFeedbackEXT_ptr(commandBuffer, firstCounterBuffer, counterBufferCount, pCounterBuffers, pCounterBufferOffsets);

	public typealias vkCmdEndTransformFeedbackEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 firstCounterBuffer, uint32 counterBufferCount, VkBuffer* pCounterBuffers, uint64* pCounterBufferOffsets);
	private static vkCmdEndTransformFeedbackEXTFunction vkCmdEndTransformFeedbackEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdEndTransformFeedbackEXT(VkCommandBuffer commandBuffer, uint32 firstCounterBuffer, uint32 counterBufferCount, VkBuffer* pCounterBuffers, uint64* pCounterBufferOffsets)
		=> vkCmdEndTransformFeedbackEXT_ptr(commandBuffer, firstCounterBuffer, counterBufferCount, pCounterBuffers, pCounterBufferOffsets);

	public typealias vkCmdBeginQueryIndexedEXTFunction = function void(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32 query, VkQueryControlFlags flags, uint32 index);
	private static vkCmdBeginQueryIndexedEXTFunction vkCmdBeginQueryIndexedEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBeginQueryIndexedEXT(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32 query, VkQueryControlFlags flags, uint32 index)
		=> vkCmdBeginQueryIndexedEXT_ptr(commandBuffer, queryPool, query, flags, index);

	public typealias vkCmdEndQueryIndexedEXTFunction = function void(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32 query, uint32 index);
	private static vkCmdEndQueryIndexedEXTFunction vkCmdEndQueryIndexedEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdEndQueryIndexedEXT(VkCommandBuffer commandBuffer, VkQueryPool queryPool, uint32 query, uint32 index)
		=> vkCmdEndQueryIndexedEXT_ptr(commandBuffer, queryPool, query, index);

	public typealias vkCmdDrawIndirectByteCountEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 instanceCount, uint32 firstInstance, VkBuffer counterBuffer, uint64 counterBufferOffset, uint32 counterOffset, uint32 vertexStride);
	private static vkCmdDrawIndirectByteCountEXTFunction vkCmdDrawIndirectByteCountEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawIndirectByteCountEXT(VkCommandBuffer commandBuffer, uint32 instanceCount, uint32 firstInstance, VkBuffer counterBuffer, uint64 counterBufferOffset, uint32 counterOffset, uint32 vertexStride)
		=> vkCmdDrawIndirectByteCountEXT_ptr(commandBuffer, instanceCount, firstInstance, counterBuffer, counterBufferOffset, counterOffset, vertexStride);

	public typealias vkCreateCuModuleNVXFunction = function VkResult(VkDevice device, VkCuModuleCreateInfoNVX* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCuModuleNVX* pModule);
	private static vkCreateCuModuleNVXFunction vkCreateCuModuleNVX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateCuModuleNVX(VkDevice device, VkCuModuleCreateInfoNVX* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCuModuleNVX* pModule)
		=> vkCreateCuModuleNVX_ptr(device, pCreateInfo, pAllocator, pModule);

	public typealias vkCreateCuFunctionNVXFunction = function VkResult(VkDevice device, VkCuFunctionCreateInfoNVX* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCuFunctionNVX* pFunction);
	private static vkCreateCuFunctionNVXFunction vkCreateCuFunctionNVX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateCuFunctionNVX(VkDevice device, VkCuFunctionCreateInfoNVX* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCuFunctionNVX* pFunction)
		=> vkCreateCuFunctionNVX_ptr(device, pCreateInfo, pAllocator, pFunction);

	public typealias vkDestroyCuModuleNVXFunction = function void(VkDevice device, VkCuModuleNVX module, VkAllocationCallbacks* pAllocator);
	private static vkDestroyCuModuleNVXFunction vkDestroyCuModuleNVX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyCuModuleNVX(VkDevice device, VkCuModuleNVX module, VkAllocationCallbacks* pAllocator)
		=> vkDestroyCuModuleNVX_ptr(device, module, pAllocator);

	public typealias vkDestroyCuFunctionNVXFunction = function void(VkDevice device, VkCuFunctionNVX vkfunction, VkAllocationCallbacks* pAllocator);
	private static vkDestroyCuFunctionNVXFunction vkDestroyCuFunctionNVX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyCuFunctionNVX(VkDevice device, VkCuFunctionNVX vkfunction, VkAllocationCallbacks* pAllocator)
		=> vkDestroyCuFunctionNVX_ptr(device, vkfunction, pAllocator);

	public typealias vkCmdCuLaunchKernelNVXFunction = function void(VkCommandBuffer commandBuffer, VkCuLaunchInfoNVX* pLaunchInfo);
	private static vkCmdCuLaunchKernelNVXFunction vkCmdCuLaunchKernelNVX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCuLaunchKernelNVX(VkCommandBuffer commandBuffer, VkCuLaunchInfoNVX* pLaunchInfo)
		=> vkCmdCuLaunchKernelNVX_ptr(commandBuffer, pLaunchInfo);

	public typealias vkGetImageViewHandleNVXFunction = function uint32(VkDevice device, VkImageViewHandleInfoNVX* pInfo);
	private static vkGetImageViewHandleNVXFunction vkGetImageViewHandleNVX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static uint32 vkGetImageViewHandleNVX(VkDevice device, VkImageViewHandleInfoNVX* pInfo)
		=> vkGetImageViewHandleNVX_ptr(device, pInfo);

	public typealias vkGetImageViewHandle64NVXFunction = function uint64(VkDevice device, VkImageViewHandleInfoNVX* pInfo);
	private static vkGetImageViewHandle64NVXFunction vkGetImageViewHandle64NVX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static uint64 vkGetImageViewHandle64NVX(VkDevice device, VkImageViewHandleInfoNVX* pInfo)
		=> vkGetImageViewHandle64NVX_ptr(device, pInfo);

	public typealias vkGetImageViewAddressNVXFunction = function VkResult(VkDevice device, VkImageView imageView, VkImageViewAddressPropertiesNVX* pProperties);
	private static vkGetImageViewAddressNVXFunction vkGetImageViewAddressNVX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetImageViewAddressNVX(VkDevice device, VkImageView imageView, VkImageViewAddressPropertiesNVX* pProperties)
		=> vkGetImageViewAddressNVX_ptr(device, imageView, pProperties);

	public typealias vkGetDeviceCombinedImageSamplerIndexNVXFunction = function uint64(VkDevice device, uint64 imageViewIndex, uint64 samplerIndex);
	private static vkGetDeviceCombinedImageSamplerIndexNVXFunction vkGetDeviceCombinedImageSamplerIndexNVX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static uint64 vkGetDeviceCombinedImageSamplerIndexNVX(VkDevice device, uint64 imageViewIndex, uint64 samplerIndex)
		=> vkGetDeviceCombinedImageSamplerIndexNVX_ptr(device, imageViewIndex, samplerIndex);

	public typealias vkGetShaderInfoAMDFunction = function VkResult(VkDevice device, VkPipeline pipeline, VkShaderStageFlags shaderStage, VkShaderInfoTypeAMD infoType, uint* pInfoSize, void* pInfo);
	private static vkGetShaderInfoAMDFunction vkGetShaderInfoAMD_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetShaderInfoAMD(VkDevice device, VkPipeline pipeline, VkShaderStageFlags shaderStage, VkShaderInfoTypeAMD infoType, uint* pInfoSize, void* pInfo)
		=> vkGetShaderInfoAMD_ptr(device, pipeline, shaderStage, infoType, pInfoSize, pInfo);

	public typealias vkCreateStreamDescriptorSurfaceGGPFunction = function VkResult(VkInstance instance, VkStreamDescriptorSurfaceCreateInfoGGP* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateStreamDescriptorSurfaceGGPFunction vkCreateStreamDescriptorSurfaceGGP_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateStreamDescriptorSurfaceGGP(VkInstance instance, VkStreamDescriptorSurfaceCreateInfoGGP* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateStreamDescriptorSurfaceGGP_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkGetPhysicalDeviceExternalImageFormatPropertiesNVFunction = function VkResult(VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkImageTiling tiling, VkImageUsageFlags usage, VkImageCreateFlags flags, VkExternalMemoryHandleTypeFlagsNV externalHandleType, VkExternalImageFormatPropertiesNV* pExternalImageFormatProperties);
	private static vkGetPhysicalDeviceExternalImageFormatPropertiesNVFunction vkGetPhysicalDeviceExternalImageFormatPropertiesNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceExternalImageFormatPropertiesNV(VkPhysicalDevice physicalDevice, VkFormat format, VkImageType type, VkImageTiling tiling, VkImageUsageFlags usage, VkImageCreateFlags flags, VkExternalMemoryHandleTypeFlagsNV externalHandleType, VkExternalImageFormatPropertiesNV* pExternalImageFormatProperties)
		=> vkGetPhysicalDeviceExternalImageFormatPropertiesNV_ptr(physicalDevice, format, type, tiling, usage, flags, externalHandleType, pExternalImageFormatProperties);

	public typealias vkGetMemoryWin32HandleNVFunction = function VkResult(VkDevice device, VkDeviceMemory memory, VkExternalMemoryHandleTypeFlagsNV handleType, void* pHandle);
	private static vkGetMemoryWin32HandleNVFunction vkGetMemoryWin32HandleNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemoryWin32HandleNV(VkDevice device, VkDeviceMemory memory, VkExternalMemoryHandleTypeFlagsNV handleType, void* pHandle)
		=> vkGetMemoryWin32HandleNV_ptr(device, memory, handleType, pHandle);

	public typealias vkCreateViSurfaceNNFunction = function VkResult(VkInstance instance, VkViSurfaceCreateInfoNN* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateViSurfaceNNFunction vkCreateViSurfaceNN_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateViSurfaceNN(VkInstance instance, VkViSurfaceCreateInfoNN* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateViSurfaceNN_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkGetMemoryWin32HandleKHRFunction = function VkResult(VkDevice device, VkMemoryGetWin32HandleInfoKHR* pGetWin32HandleInfo, void* pHandle);
	private static vkGetMemoryWin32HandleKHRFunction vkGetMemoryWin32HandleKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemoryWin32HandleKHR(VkDevice device, VkMemoryGetWin32HandleInfoKHR* pGetWin32HandleInfo, void* pHandle)
		=> vkGetMemoryWin32HandleKHR_ptr(device, pGetWin32HandleInfo, pHandle);

	public typealias vkGetMemoryWin32HandlePropertiesKHRFunction = function VkResult(VkDevice device, VkExternalMemoryHandleTypeFlags handleType, void* handle, VkMemoryWin32HandlePropertiesKHR* pMemoryWin32HandleProperties);
	private static vkGetMemoryWin32HandlePropertiesKHRFunction vkGetMemoryWin32HandlePropertiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemoryWin32HandlePropertiesKHR(VkDevice device, VkExternalMemoryHandleTypeFlags handleType, void* handle, VkMemoryWin32HandlePropertiesKHR* pMemoryWin32HandleProperties)
		=> vkGetMemoryWin32HandlePropertiesKHR_ptr(device, handleType, handle, pMemoryWin32HandleProperties);

	public typealias vkGetMemoryFdKHRFunction = function VkResult(VkDevice device, VkMemoryGetFdInfoKHR* pGetFdInfo, int* pFd);
	private static vkGetMemoryFdKHRFunction vkGetMemoryFdKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemoryFdKHR(VkDevice device, VkMemoryGetFdInfoKHR* pGetFdInfo, int* pFd)
		=> vkGetMemoryFdKHR_ptr(device, pGetFdInfo, pFd);

	public typealias vkGetMemoryFdPropertiesKHRFunction = function VkResult(VkDevice device, VkExternalMemoryHandleTypeFlags handleType, int fd, VkMemoryFdPropertiesKHR* pMemoryFdProperties);
	private static vkGetMemoryFdPropertiesKHRFunction vkGetMemoryFdPropertiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemoryFdPropertiesKHR(VkDevice device, VkExternalMemoryHandleTypeFlags handleType, int fd, VkMemoryFdPropertiesKHR* pMemoryFdProperties)
		=> vkGetMemoryFdPropertiesKHR_ptr(device, handleType, fd, pMemoryFdProperties);

	public typealias vkImportSemaphoreWin32HandleKHRFunction = function VkResult(VkDevice device, VkImportSemaphoreWin32HandleInfoKHR* pImportSemaphoreWin32HandleInfo);
	private static vkImportSemaphoreWin32HandleKHRFunction vkImportSemaphoreWin32HandleKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkImportSemaphoreWin32HandleKHR(VkDevice device, VkImportSemaphoreWin32HandleInfoKHR* pImportSemaphoreWin32HandleInfo)
		=> vkImportSemaphoreWin32HandleKHR_ptr(device, pImportSemaphoreWin32HandleInfo);

	public typealias vkGetSemaphoreWin32HandleKHRFunction = function VkResult(VkDevice device, VkSemaphoreGetWin32HandleInfoKHR* pGetWin32HandleInfo, void* pHandle);
	private static vkGetSemaphoreWin32HandleKHRFunction vkGetSemaphoreWin32HandleKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetSemaphoreWin32HandleKHR(VkDevice device, VkSemaphoreGetWin32HandleInfoKHR* pGetWin32HandleInfo, void* pHandle)
		=> vkGetSemaphoreWin32HandleKHR_ptr(device, pGetWin32HandleInfo, pHandle);

	public typealias vkImportSemaphoreFdKHRFunction = function VkResult(VkDevice device, VkImportSemaphoreFdInfoKHR* pImportSemaphoreFdInfo);
	private static vkImportSemaphoreFdKHRFunction vkImportSemaphoreFdKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkImportSemaphoreFdKHR(VkDevice device, VkImportSemaphoreFdInfoKHR* pImportSemaphoreFdInfo)
		=> vkImportSemaphoreFdKHR_ptr(device, pImportSemaphoreFdInfo);

	public typealias vkGetSemaphoreFdKHRFunction = function VkResult(VkDevice device, VkSemaphoreGetFdInfoKHR* pGetFdInfo, int* pFd);
	private static vkGetSemaphoreFdKHRFunction vkGetSemaphoreFdKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetSemaphoreFdKHR(VkDevice device, VkSemaphoreGetFdInfoKHR* pGetFdInfo, int* pFd)
		=> vkGetSemaphoreFdKHR_ptr(device, pGetFdInfo, pFd);

	public typealias vkCmdBeginConditionalRenderingEXTFunction = function void(VkCommandBuffer commandBuffer, VkConditionalRenderingBeginInfoEXT* pConditionalRenderingBegin);
	private static vkCmdBeginConditionalRenderingEXTFunction vkCmdBeginConditionalRenderingEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBeginConditionalRenderingEXT(VkCommandBuffer commandBuffer, VkConditionalRenderingBeginInfoEXT* pConditionalRenderingBegin)
		=> vkCmdBeginConditionalRenderingEXT_ptr(commandBuffer, pConditionalRenderingBegin);

	public typealias vkCmdEndConditionalRenderingEXTFunction = function void(VkCommandBuffer commandBuffer);
	private static vkCmdEndConditionalRenderingEXTFunction vkCmdEndConditionalRenderingEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdEndConditionalRenderingEXT(VkCommandBuffer commandBuffer)
		=> vkCmdEndConditionalRenderingEXT_ptr(commandBuffer);

	public typealias vkCmdSetViewportWScalingNVFunction = function void(VkCommandBuffer commandBuffer, uint32 firstViewport, uint32 viewportCount, VkViewportWScalingNV* pViewportWScalings);
	private static vkCmdSetViewportWScalingNVFunction vkCmdSetViewportWScalingNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetViewportWScalingNV(VkCommandBuffer commandBuffer, uint32 firstViewport, uint32 viewportCount, VkViewportWScalingNV* pViewportWScalings)
		=> vkCmdSetViewportWScalingNV_ptr(commandBuffer, firstViewport, viewportCount, pViewportWScalings);

	public typealias vkReleaseDisplayEXTFunction = function VkResult(VkPhysicalDevice physicalDevice, VkDisplayKHR display);
	private static vkReleaseDisplayEXTFunction vkReleaseDisplayEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkReleaseDisplayEXT(VkPhysicalDevice physicalDevice, VkDisplayKHR display)
		=> vkReleaseDisplayEXT_ptr(physicalDevice, display);

	public typealias vkAcquireXlibDisplayEXTFunction = function VkResult(VkPhysicalDevice physicalDevice, void* dpy, VkDisplayKHR display);
	private static vkAcquireXlibDisplayEXTFunction vkAcquireXlibDisplayEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkAcquireXlibDisplayEXT(VkPhysicalDevice physicalDevice, void* dpy, VkDisplayKHR display)
		=> vkAcquireXlibDisplayEXT_ptr(physicalDevice, dpy, display);

	public typealias vkGetRandROutputDisplayEXTFunction = function VkResult(VkPhysicalDevice physicalDevice, void* dpy, void* rrOutput, VkDisplayKHR* pDisplay);
	private static vkGetRandROutputDisplayEXTFunction vkGetRandROutputDisplayEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetRandROutputDisplayEXT(VkPhysicalDevice physicalDevice, void* dpy, void* rrOutput, VkDisplayKHR* pDisplay)
		=> vkGetRandROutputDisplayEXT_ptr(physicalDevice, dpy, rrOutput, pDisplay);

	public typealias vkGetPhysicalDeviceSurfaceCapabilities2EXTFunction = function VkResult(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, VkSurfaceCapabilities2EXT* pSurfaceCapabilities);
	private static vkGetPhysicalDeviceSurfaceCapabilities2EXTFunction vkGetPhysicalDeviceSurfaceCapabilities2EXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceSurfaceCapabilities2EXT(VkPhysicalDevice physicalDevice, VkSurfaceKHR surface, VkSurfaceCapabilities2EXT* pSurfaceCapabilities)
		=> vkGetPhysicalDeviceSurfaceCapabilities2EXT_ptr(physicalDevice, surface, pSurfaceCapabilities);

	public typealias vkDisplayPowerControlEXTFunction = function VkResult(VkDevice device, VkDisplayKHR display, VkDisplayPowerInfoEXT* pDisplayPowerInfo);
	private static vkDisplayPowerControlEXTFunction vkDisplayPowerControlEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkDisplayPowerControlEXT(VkDevice device, VkDisplayKHR display, VkDisplayPowerInfoEXT* pDisplayPowerInfo)
		=> vkDisplayPowerControlEXT_ptr(device, display, pDisplayPowerInfo);

	public typealias vkRegisterDeviceEventEXTFunction = function VkResult(VkDevice device, VkDeviceEventInfoEXT* pDeviceEventInfo, VkAllocationCallbacks* pAllocator, VkFence* pFence);
	private static vkRegisterDeviceEventEXTFunction vkRegisterDeviceEventEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkRegisterDeviceEventEXT(VkDevice device, VkDeviceEventInfoEXT* pDeviceEventInfo, VkAllocationCallbacks* pAllocator, VkFence* pFence)
		=> vkRegisterDeviceEventEXT_ptr(device, pDeviceEventInfo, pAllocator, pFence);

	public typealias vkRegisterDisplayEventEXTFunction = function VkResult(VkDevice device, VkDisplayKHR display, VkDisplayEventInfoEXT* pDisplayEventInfo, VkAllocationCallbacks* pAllocator, VkFence* pFence);
	private static vkRegisterDisplayEventEXTFunction vkRegisterDisplayEventEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkRegisterDisplayEventEXT(VkDevice device, VkDisplayKHR display, VkDisplayEventInfoEXT* pDisplayEventInfo, VkAllocationCallbacks* pAllocator, VkFence* pFence)
		=> vkRegisterDisplayEventEXT_ptr(device, display, pDisplayEventInfo, pAllocator, pFence);

	public typealias vkGetSwapchainCounterEXTFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain, VkSurfaceCounterFlagsEXT counter, uint64* pCounterValue);
	private static vkGetSwapchainCounterEXTFunction vkGetSwapchainCounterEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetSwapchainCounterEXT(VkDevice device, VkSwapchainKHR swapchain, VkSurfaceCounterFlagsEXT counter, uint64* pCounterValue)
		=> vkGetSwapchainCounterEXT_ptr(device, swapchain, counter, pCounterValue);

	public typealias vkGetRefreshCycleDurationGOOGLEFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain, VkRefreshCycleDurationGOOGLE* pDisplayTimingProperties);
	private static vkGetRefreshCycleDurationGOOGLEFunction vkGetRefreshCycleDurationGOOGLE_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetRefreshCycleDurationGOOGLE(VkDevice device, VkSwapchainKHR swapchain, VkRefreshCycleDurationGOOGLE* pDisplayTimingProperties)
		=> vkGetRefreshCycleDurationGOOGLE_ptr(device, swapchain, pDisplayTimingProperties);

	public typealias vkGetPastPresentationTimingGOOGLEFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain, uint32* pPresentationTimingCount, VkPastPresentationTimingGOOGLE* pPresentationTimings);
	private static vkGetPastPresentationTimingGOOGLEFunction vkGetPastPresentationTimingGOOGLE_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPastPresentationTimingGOOGLE(VkDevice device, VkSwapchainKHR swapchain, uint32* pPresentationTimingCount, VkPastPresentationTimingGOOGLE* pPresentationTimings)
		=> vkGetPastPresentationTimingGOOGLE_ptr(device, swapchain, pPresentationTimingCount, pPresentationTimings);

	public typealias vkCmdSetDiscardRectangleEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 firstDiscardRectangle, uint32 discardRectangleCount, VkRect2D* pDiscardRectangles);
	private static vkCmdSetDiscardRectangleEXTFunction vkCmdSetDiscardRectangleEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDiscardRectangleEXT(VkCommandBuffer commandBuffer, uint32 firstDiscardRectangle, uint32 discardRectangleCount, VkRect2D* pDiscardRectangles)
		=> vkCmdSetDiscardRectangleEXT_ptr(commandBuffer, firstDiscardRectangle, discardRectangleCount, pDiscardRectangles);

	public typealias vkCmdSetDiscardRectangleEnableEXTFunction = function void(VkCommandBuffer commandBuffer, VkBool32 discardRectangleEnable);
	private static vkCmdSetDiscardRectangleEnableEXTFunction vkCmdSetDiscardRectangleEnableEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDiscardRectangleEnableEXT(VkCommandBuffer commandBuffer, VkBool32 discardRectangleEnable)
		=> vkCmdSetDiscardRectangleEnableEXT_ptr(commandBuffer, discardRectangleEnable);

	public typealias vkCmdSetDiscardRectangleModeEXTFunction = function void(VkCommandBuffer commandBuffer, VkDiscardRectangleModeEXT discardRectangleMode);
	private static vkCmdSetDiscardRectangleModeEXTFunction vkCmdSetDiscardRectangleModeEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDiscardRectangleModeEXT(VkCommandBuffer commandBuffer, VkDiscardRectangleModeEXT discardRectangleMode)
		=> vkCmdSetDiscardRectangleModeEXT_ptr(commandBuffer, discardRectangleMode);

	public typealias vkSetHdrMetadataEXTFunction = function void(VkDevice device, uint32 swapchainCount, VkSwapchainKHR* pSwapchains, VkHdrMetadataEXT* pMetadata);
	private static vkSetHdrMetadataEXTFunction vkSetHdrMetadataEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkSetHdrMetadataEXT(VkDevice device, uint32 swapchainCount, VkSwapchainKHR* pSwapchains, VkHdrMetadataEXT* pMetadata)
		=> vkSetHdrMetadataEXT_ptr(device, swapchainCount, pSwapchains, pMetadata);

	public typealias vkGetSwapchainStatusKHRFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain);
	private static vkGetSwapchainStatusKHRFunction vkGetSwapchainStatusKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetSwapchainStatusKHR(VkDevice device, VkSwapchainKHR swapchain)
		=> vkGetSwapchainStatusKHR_ptr(device, swapchain);

	public typealias vkImportFenceWin32HandleKHRFunction = function VkResult(VkDevice device, VkImportFenceWin32HandleInfoKHR* pImportFenceWin32HandleInfo);
	private static vkImportFenceWin32HandleKHRFunction vkImportFenceWin32HandleKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkImportFenceWin32HandleKHR(VkDevice device, VkImportFenceWin32HandleInfoKHR* pImportFenceWin32HandleInfo)
		=> vkImportFenceWin32HandleKHR_ptr(device, pImportFenceWin32HandleInfo);

	public typealias vkGetFenceWin32HandleKHRFunction = function VkResult(VkDevice device, VkFenceGetWin32HandleInfoKHR* pGetWin32HandleInfo, void* pHandle);
	private static vkGetFenceWin32HandleKHRFunction vkGetFenceWin32HandleKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetFenceWin32HandleKHR(VkDevice device, VkFenceGetWin32HandleInfoKHR* pGetWin32HandleInfo, void* pHandle)
		=> vkGetFenceWin32HandleKHR_ptr(device, pGetWin32HandleInfo, pHandle);

	public typealias vkImportFenceFdKHRFunction = function VkResult(VkDevice device, VkImportFenceFdInfoKHR* pImportFenceFdInfo);
	private static vkImportFenceFdKHRFunction vkImportFenceFdKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkImportFenceFdKHR(VkDevice device, VkImportFenceFdInfoKHR* pImportFenceFdInfo)
		=> vkImportFenceFdKHR_ptr(device, pImportFenceFdInfo);

	public typealias vkGetFenceFdKHRFunction = function VkResult(VkDevice device, VkFenceGetFdInfoKHR* pGetFdInfo, int* pFd);
	private static vkGetFenceFdKHRFunction vkGetFenceFdKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetFenceFdKHR(VkDevice device, VkFenceGetFdInfoKHR* pGetFdInfo, int* pFd)
		=> vkGetFenceFdKHR_ptr(device, pGetFdInfo, pFd);

	public typealias vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, uint32* pCounterCount, VkPerformanceCounterKHR* pCounters, VkPerformanceCounterDescriptionKHR* pCounterDescriptions);
	private static vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHRFunction vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, uint32* pCounterCount, VkPerformanceCounterKHR* pCounters, VkPerformanceCounterDescriptionKHR* pCounterDescriptions)
		=> vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR_ptr(physicalDevice, queueFamilyIndex, pCounterCount, pCounters, pCounterDescriptions);

	public typealias vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHRFunction = function void(VkPhysicalDevice physicalDevice, VkQueryPoolPerformanceCreateInfoKHR* pPerformanceQueryCreateInfo, uint32* pNumPasses);
	private static vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHRFunction vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR(VkPhysicalDevice physicalDevice, VkQueryPoolPerformanceCreateInfoKHR* pPerformanceQueryCreateInfo, uint32* pNumPasses)
		=> vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR_ptr(physicalDevice, pPerformanceQueryCreateInfo, pNumPasses);

	public typealias vkAcquireProfilingLockKHRFunction = function VkResult(VkDevice device, VkAcquireProfilingLockInfoKHR* pInfo);
	private static vkAcquireProfilingLockKHRFunction vkAcquireProfilingLockKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkAcquireProfilingLockKHR(VkDevice device, VkAcquireProfilingLockInfoKHR* pInfo)
		=> vkAcquireProfilingLockKHR_ptr(device, pInfo);

	public typealias vkReleaseProfilingLockKHRFunction = function void(VkDevice device);
	private static vkReleaseProfilingLockKHRFunction vkReleaseProfilingLockKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkReleaseProfilingLockKHR(VkDevice device)
		=> vkReleaseProfilingLockKHR_ptr(device);

	public typealias vkGetPhysicalDeviceSurfaceCapabilities2KHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkPhysicalDeviceSurfaceInfo2KHR* pSurfaceInfo, VkSurfaceCapabilities2KHR* pSurfaceCapabilities);
	private static vkGetPhysicalDeviceSurfaceCapabilities2KHRFunction vkGetPhysicalDeviceSurfaceCapabilities2KHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceSurfaceCapabilities2KHR(VkPhysicalDevice physicalDevice, VkPhysicalDeviceSurfaceInfo2KHR* pSurfaceInfo, VkSurfaceCapabilities2KHR* pSurfaceCapabilities)
		=> vkGetPhysicalDeviceSurfaceCapabilities2KHR_ptr(physicalDevice, pSurfaceInfo, pSurfaceCapabilities);

	public typealias vkGetPhysicalDeviceSurfaceFormats2KHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkPhysicalDeviceSurfaceInfo2KHR* pSurfaceInfo, uint32* pSurfaceFormatCount, VkSurfaceFormat2KHR* pSurfaceFormats);
	private static vkGetPhysicalDeviceSurfaceFormats2KHRFunction vkGetPhysicalDeviceSurfaceFormats2KHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceSurfaceFormats2KHR(VkPhysicalDevice physicalDevice, VkPhysicalDeviceSurfaceInfo2KHR* pSurfaceInfo, uint32* pSurfaceFormatCount, VkSurfaceFormat2KHR* pSurfaceFormats)
		=> vkGetPhysicalDeviceSurfaceFormats2KHR_ptr(physicalDevice, pSurfaceInfo, pSurfaceFormatCount, pSurfaceFormats);

	public typealias vkGetPhysicalDeviceDisplayProperties2KHRFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkDisplayProperties2KHR* pProperties);
	private static vkGetPhysicalDeviceDisplayProperties2KHRFunction vkGetPhysicalDeviceDisplayProperties2KHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceDisplayProperties2KHR(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkDisplayProperties2KHR* pProperties)
		=> vkGetPhysicalDeviceDisplayProperties2KHR_ptr(physicalDevice, pPropertyCount, pProperties);

	public typealias vkGetPhysicalDeviceDisplayPlaneProperties2KHRFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkDisplayPlaneProperties2KHR* pProperties);
	private static vkGetPhysicalDeviceDisplayPlaneProperties2KHRFunction vkGetPhysicalDeviceDisplayPlaneProperties2KHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceDisplayPlaneProperties2KHR(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkDisplayPlaneProperties2KHR* pProperties)
		=> vkGetPhysicalDeviceDisplayPlaneProperties2KHR_ptr(physicalDevice, pPropertyCount, pProperties);

	public typealias vkGetDisplayModeProperties2KHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkDisplayKHR display, uint32* pPropertyCount, VkDisplayModeProperties2KHR* pProperties);
	private static vkGetDisplayModeProperties2KHRFunction vkGetDisplayModeProperties2KHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDisplayModeProperties2KHR(VkPhysicalDevice physicalDevice, VkDisplayKHR display, uint32* pPropertyCount, VkDisplayModeProperties2KHR* pProperties)
		=> vkGetDisplayModeProperties2KHR_ptr(physicalDevice, display, pPropertyCount, pProperties);

	public typealias vkGetDisplayPlaneCapabilities2KHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkDisplayPlaneInfo2KHR* pDisplayPlaneInfo, VkDisplayPlaneCapabilities2KHR* pCapabilities);
	private static vkGetDisplayPlaneCapabilities2KHRFunction vkGetDisplayPlaneCapabilities2KHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDisplayPlaneCapabilities2KHR(VkPhysicalDevice physicalDevice, VkDisplayPlaneInfo2KHR* pDisplayPlaneInfo, VkDisplayPlaneCapabilities2KHR* pCapabilities)
		=> vkGetDisplayPlaneCapabilities2KHR_ptr(physicalDevice, pDisplayPlaneInfo, pCapabilities);

	public typealias vkCreateIOSSurfaceMVKFunction = function VkResult(VkInstance instance, VkIOSSurfaceCreateInfoMVK* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateIOSSurfaceMVKFunction vkCreateIOSSurfaceMVK_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateIOSSurfaceMVK(VkInstance instance, VkIOSSurfaceCreateInfoMVK* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateIOSSurfaceMVK_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkCreateMacOSSurfaceMVKFunction = function VkResult(VkInstance instance, VkMacOSSurfaceCreateInfoMVK* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateMacOSSurfaceMVKFunction vkCreateMacOSSurfaceMVK_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateMacOSSurfaceMVK(VkInstance instance, VkMacOSSurfaceCreateInfoMVK* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateMacOSSurfaceMVK_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkSetDebugUtilsObjectNameEXTFunction = function VkResult(VkDevice device, VkDebugUtilsObjectNameInfoEXT* pNameInfo);
	private static vkSetDebugUtilsObjectNameEXTFunction vkSetDebugUtilsObjectNameEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkSetDebugUtilsObjectNameEXT(VkDevice device, VkDebugUtilsObjectNameInfoEXT* pNameInfo)
		=> vkSetDebugUtilsObjectNameEXT_ptr(device, pNameInfo);

	public typealias vkSetDebugUtilsObjectTagEXTFunction = function VkResult(VkDevice device, VkDebugUtilsObjectTagInfoEXT* pTagInfo);
	private static vkSetDebugUtilsObjectTagEXTFunction vkSetDebugUtilsObjectTagEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkSetDebugUtilsObjectTagEXT(VkDevice device, VkDebugUtilsObjectTagInfoEXT* pTagInfo)
		=> vkSetDebugUtilsObjectTagEXT_ptr(device, pTagInfo);

	public typealias vkQueueBeginDebugUtilsLabelEXTFunction = function void(VkQueue queue, VkDebugUtilsLabelEXT* pLabelInfo);
	private static vkQueueBeginDebugUtilsLabelEXTFunction vkQueueBeginDebugUtilsLabelEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkQueueBeginDebugUtilsLabelEXT(VkQueue queue, VkDebugUtilsLabelEXT* pLabelInfo)
		=> vkQueueBeginDebugUtilsLabelEXT_ptr(queue, pLabelInfo);

	public typealias vkQueueEndDebugUtilsLabelEXTFunction = function void(VkQueue queue);
	private static vkQueueEndDebugUtilsLabelEXTFunction vkQueueEndDebugUtilsLabelEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkQueueEndDebugUtilsLabelEXT(VkQueue queue)
		=> vkQueueEndDebugUtilsLabelEXT_ptr(queue);

	public typealias vkQueueInsertDebugUtilsLabelEXTFunction = function void(VkQueue queue, VkDebugUtilsLabelEXT* pLabelInfo);
	private static vkQueueInsertDebugUtilsLabelEXTFunction vkQueueInsertDebugUtilsLabelEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkQueueInsertDebugUtilsLabelEXT(VkQueue queue, VkDebugUtilsLabelEXT* pLabelInfo)
		=> vkQueueInsertDebugUtilsLabelEXT_ptr(queue, pLabelInfo);

	public typealias vkCmdBeginDebugUtilsLabelEXTFunction = function void(VkCommandBuffer commandBuffer, VkDebugUtilsLabelEXT* pLabelInfo);
	private static vkCmdBeginDebugUtilsLabelEXTFunction vkCmdBeginDebugUtilsLabelEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBeginDebugUtilsLabelEXT(VkCommandBuffer commandBuffer, VkDebugUtilsLabelEXT* pLabelInfo)
		=> vkCmdBeginDebugUtilsLabelEXT_ptr(commandBuffer, pLabelInfo);

	public typealias vkCmdEndDebugUtilsLabelEXTFunction = function void(VkCommandBuffer commandBuffer);
	private static vkCmdEndDebugUtilsLabelEXTFunction vkCmdEndDebugUtilsLabelEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdEndDebugUtilsLabelEXT(VkCommandBuffer commandBuffer)
		=> vkCmdEndDebugUtilsLabelEXT_ptr(commandBuffer);

	public typealias vkCmdInsertDebugUtilsLabelEXTFunction = function void(VkCommandBuffer commandBuffer, VkDebugUtilsLabelEXT* pLabelInfo);
	private static vkCmdInsertDebugUtilsLabelEXTFunction vkCmdInsertDebugUtilsLabelEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdInsertDebugUtilsLabelEXT(VkCommandBuffer commandBuffer, VkDebugUtilsLabelEXT* pLabelInfo)
		=> vkCmdInsertDebugUtilsLabelEXT_ptr(commandBuffer, pLabelInfo);

	public typealias vkCreateDebugUtilsMessengerEXTFunction = function VkResult(VkInstance instance, VkDebugUtilsMessengerCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDebugUtilsMessengerEXT* pMessenger);
	private static vkCreateDebugUtilsMessengerEXTFunction vkCreateDebugUtilsMessengerEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateDebugUtilsMessengerEXT(VkInstance instance, VkDebugUtilsMessengerCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDebugUtilsMessengerEXT* pMessenger)
		=> vkCreateDebugUtilsMessengerEXT_ptr(instance, pCreateInfo, pAllocator, pMessenger);

	public typealias vkDestroyDebugUtilsMessengerEXTFunction = function void(VkInstance instance, VkDebugUtilsMessengerEXT messenger, VkAllocationCallbacks* pAllocator);
	private static vkDestroyDebugUtilsMessengerEXTFunction vkDestroyDebugUtilsMessengerEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyDebugUtilsMessengerEXT(VkInstance instance, VkDebugUtilsMessengerEXT messenger, VkAllocationCallbacks* pAllocator)
		=> vkDestroyDebugUtilsMessengerEXT_ptr(instance, messenger, pAllocator);

	public typealias vkSubmitDebugUtilsMessageEXTFunction = function void(VkInstance instance, VkDebugUtilsMessageSeverityFlagsEXT messageSeverity, VkDebugUtilsMessageTypeFlagsEXT messageTypes, VkDebugUtilsMessengerCallbackDataEXT* pCallbackData);
	private static vkSubmitDebugUtilsMessageEXTFunction vkSubmitDebugUtilsMessageEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkSubmitDebugUtilsMessageEXT(VkInstance instance, VkDebugUtilsMessageSeverityFlagsEXT messageSeverity, VkDebugUtilsMessageTypeFlagsEXT messageTypes, VkDebugUtilsMessengerCallbackDataEXT* pCallbackData)
		=> vkSubmitDebugUtilsMessageEXT_ptr(instance, messageSeverity, messageTypes, pCallbackData);

	public typealias vkGetAndroidHardwareBufferPropertiesANDROIDFunction = function VkResult(VkDevice device, void* buffer, VkAndroidHardwareBufferPropertiesANDROID* pProperties);
	private static vkGetAndroidHardwareBufferPropertiesANDROIDFunction vkGetAndroidHardwareBufferPropertiesANDROID_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetAndroidHardwareBufferPropertiesANDROID(VkDevice device, void* buffer, VkAndroidHardwareBufferPropertiesANDROID* pProperties)
		=> vkGetAndroidHardwareBufferPropertiesANDROID_ptr(device, buffer, pProperties);

	public typealias vkGetMemoryAndroidHardwareBufferANDROIDFunction = function VkResult(VkDevice device, VkMemoryGetAndroidHardwareBufferInfoANDROID* pInfo, void* pBuffer);
	private static vkGetMemoryAndroidHardwareBufferANDROIDFunction vkGetMemoryAndroidHardwareBufferANDROID_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemoryAndroidHardwareBufferANDROID(VkDevice device, VkMemoryGetAndroidHardwareBufferInfoANDROID* pInfo, void* pBuffer)
		=> vkGetMemoryAndroidHardwareBufferANDROID_ptr(device, pInfo, pBuffer);

	public typealias vkCreateExecutionGraphPipelinesAMDXFunction = function VkResult(VkDevice device, VkPipelineCache pipelineCache, uint32 createInfoCount, VkExecutionGraphPipelineCreateInfoAMDX* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines);
	private static vkCreateExecutionGraphPipelinesAMDXFunction vkCreateExecutionGraphPipelinesAMDX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateExecutionGraphPipelinesAMDX(VkDevice device, VkPipelineCache pipelineCache, uint32 createInfoCount, VkExecutionGraphPipelineCreateInfoAMDX* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines)
		=> vkCreateExecutionGraphPipelinesAMDX_ptr(device, pipelineCache, createInfoCount, pCreateInfos, pAllocator, pPipelines);

	public typealias vkGetExecutionGraphPipelineScratchSizeAMDXFunction = function VkResult(VkDevice device, VkPipeline executionGraph, VkExecutionGraphPipelineScratchSizeAMDX* pSizeInfo);
	private static vkGetExecutionGraphPipelineScratchSizeAMDXFunction vkGetExecutionGraphPipelineScratchSizeAMDX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetExecutionGraphPipelineScratchSizeAMDX(VkDevice device, VkPipeline executionGraph, VkExecutionGraphPipelineScratchSizeAMDX* pSizeInfo)
		=> vkGetExecutionGraphPipelineScratchSizeAMDX_ptr(device, executionGraph, pSizeInfo);

	public typealias vkGetExecutionGraphPipelineNodeIndexAMDXFunction = function VkResult(VkDevice device, VkPipeline executionGraph, VkPipelineShaderStageNodeCreateInfoAMDX* pNodeInfo, uint32* pNodeIndex);
	private static vkGetExecutionGraphPipelineNodeIndexAMDXFunction vkGetExecutionGraphPipelineNodeIndexAMDX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetExecutionGraphPipelineNodeIndexAMDX(VkDevice device, VkPipeline executionGraph, VkPipelineShaderStageNodeCreateInfoAMDX* pNodeInfo, uint32* pNodeIndex)
		=> vkGetExecutionGraphPipelineNodeIndexAMDX_ptr(device, executionGraph, pNodeInfo, pNodeIndex);

	public typealias vkCmdInitializeGraphScratchMemoryAMDXFunction = function void(VkCommandBuffer commandBuffer, VkPipeline executionGraph, uint64 scratch, uint64 scratchSize);
	private static vkCmdInitializeGraphScratchMemoryAMDXFunction vkCmdInitializeGraphScratchMemoryAMDX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdInitializeGraphScratchMemoryAMDX(VkCommandBuffer commandBuffer, VkPipeline executionGraph, uint64 scratch, uint64 scratchSize)
		=> vkCmdInitializeGraphScratchMemoryAMDX_ptr(commandBuffer, executionGraph, scratch, scratchSize);

	public typealias vkCmdDispatchGraphAMDXFunction = function void(VkCommandBuffer commandBuffer, uint64 scratch, uint64 scratchSize, VkDispatchGraphCountInfoAMDX* pCountInfo);
	private static vkCmdDispatchGraphAMDXFunction vkCmdDispatchGraphAMDX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDispatchGraphAMDX(VkCommandBuffer commandBuffer, uint64 scratch, uint64 scratchSize, VkDispatchGraphCountInfoAMDX* pCountInfo)
		=> vkCmdDispatchGraphAMDX_ptr(commandBuffer, scratch, scratchSize, pCountInfo);

	public typealias vkCmdDispatchGraphIndirectAMDXFunction = function void(VkCommandBuffer commandBuffer, uint64 scratch, uint64 scratchSize, VkDispatchGraphCountInfoAMDX* pCountInfo);
	private static vkCmdDispatchGraphIndirectAMDXFunction vkCmdDispatchGraphIndirectAMDX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDispatchGraphIndirectAMDX(VkCommandBuffer commandBuffer, uint64 scratch, uint64 scratchSize, VkDispatchGraphCountInfoAMDX* pCountInfo)
		=> vkCmdDispatchGraphIndirectAMDX_ptr(commandBuffer, scratch, scratchSize, pCountInfo);

	public typealias vkCmdDispatchGraphIndirectCountAMDXFunction = function void(VkCommandBuffer commandBuffer, uint64 scratch, uint64 scratchSize, uint64 countInfo);
	private static vkCmdDispatchGraphIndirectCountAMDXFunction vkCmdDispatchGraphIndirectCountAMDX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDispatchGraphIndirectCountAMDX(VkCommandBuffer commandBuffer, uint64 scratch, uint64 scratchSize, uint64 countInfo)
		=> vkCmdDispatchGraphIndirectCountAMDX_ptr(commandBuffer, scratch, scratchSize, countInfo);

	public typealias vkWriteSamplerDescriptorsEXTFunction = function VkResult(VkDevice device, uint32 samplerCount, VkSamplerCreateInfo* pSamplers, VkHostAddressRangeEXT* pDescriptors);
	private static vkWriteSamplerDescriptorsEXTFunction vkWriteSamplerDescriptorsEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkWriteSamplerDescriptorsEXT(VkDevice device, uint32 samplerCount, VkSamplerCreateInfo* pSamplers, VkHostAddressRangeEXT* pDescriptors)
		=> vkWriteSamplerDescriptorsEXT_ptr(device, samplerCount, pSamplers, pDescriptors);

	public typealias vkWriteResourceDescriptorsEXTFunction = function VkResult(VkDevice device, uint32 resourceCount, VkResourceDescriptorInfoEXT* pResources, VkHostAddressRangeEXT* pDescriptors);
	private static vkWriteResourceDescriptorsEXTFunction vkWriteResourceDescriptorsEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkWriteResourceDescriptorsEXT(VkDevice device, uint32 resourceCount, VkResourceDescriptorInfoEXT* pResources, VkHostAddressRangeEXT* pDescriptors)
		=> vkWriteResourceDescriptorsEXT_ptr(device, resourceCount, pResources, pDescriptors);

	public typealias vkCmdBindSamplerHeapEXTFunction = function void(VkCommandBuffer commandBuffer, VkBindHeapInfoEXT* pBindInfo);
	private static vkCmdBindSamplerHeapEXTFunction vkCmdBindSamplerHeapEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindSamplerHeapEXT(VkCommandBuffer commandBuffer, VkBindHeapInfoEXT* pBindInfo)
		=> vkCmdBindSamplerHeapEXT_ptr(commandBuffer, pBindInfo);

	public typealias vkCmdBindResourceHeapEXTFunction = function void(VkCommandBuffer commandBuffer, VkBindHeapInfoEXT* pBindInfo);
	private static vkCmdBindResourceHeapEXTFunction vkCmdBindResourceHeapEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindResourceHeapEXT(VkCommandBuffer commandBuffer, VkBindHeapInfoEXT* pBindInfo)
		=> vkCmdBindResourceHeapEXT_ptr(commandBuffer, pBindInfo);

	public typealias vkCmdPushDataEXTFunction = function void(VkCommandBuffer commandBuffer, VkPushDataInfoEXT* pPushDataInfo);
	private static vkCmdPushDataEXTFunction vkCmdPushDataEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdPushDataEXT(VkCommandBuffer commandBuffer, VkPushDataInfoEXT* pPushDataInfo)
		=> vkCmdPushDataEXT_ptr(commandBuffer, pPushDataInfo);

	public typealias vkGetImageOpaqueCaptureDataEXTFunction = function VkResult(VkDevice device, uint32 imageCount, VkImage* pImages, VkHostAddressRangeEXT* pDatas);
	private static vkGetImageOpaqueCaptureDataEXTFunction vkGetImageOpaqueCaptureDataEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetImageOpaqueCaptureDataEXT(VkDevice device, uint32 imageCount, VkImage* pImages, VkHostAddressRangeEXT* pDatas)
		=> vkGetImageOpaqueCaptureDataEXT_ptr(device, imageCount, pImages, pDatas);

	public typealias vkGetPhysicalDeviceDescriptorSizeEXTFunction = function uint64(VkPhysicalDevice physicalDevice, VkDescriptorType descriptorType);
	private static vkGetPhysicalDeviceDescriptorSizeEXTFunction vkGetPhysicalDeviceDescriptorSizeEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static uint64 vkGetPhysicalDeviceDescriptorSizeEXT(VkPhysicalDevice physicalDevice, VkDescriptorType descriptorType)
		=> vkGetPhysicalDeviceDescriptorSizeEXT_ptr(physicalDevice, descriptorType);

	public typealias vkRegisterCustomBorderColorEXTFunction = function VkResult(VkDevice device, VkSamplerCustomBorderColorCreateInfoEXT* pBorderColor, VkBool32 requestIndex, uint32* pIndex);
	private static vkRegisterCustomBorderColorEXTFunction vkRegisterCustomBorderColorEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkRegisterCustomBorderColorEXT(VkDevice device, VkSamplerCustomBorderColorCreateInfoEXT* pBorderColor, VkBool32 requestIndex, uint32* pIndex)
		=> vkRegisterCustomBorderColorEXT_ptr(device, pBorderColor, requestIndex, pIndex);

	public typealias vkUnregisterCustomBorderColorEXTFunction = function void(VkDevice device, uint32 index);
	private static vkUnregisterCustomBorderColorEXTFunction vkUnregisterCustomBorderColorEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkUnregisterCustomBorderColorEXT(VkDevice device, uint32 index)
		=> vkUnregisterCustomBorderColorEXT_ptr(device, index);

	public typealias vkGetTensorOpaqueCaptureDataARMFunction = function VkResult(VkDevice device, uint32 tensorCount, VkTensorARM* pTensors, VkHostAddressRangeEXT* pDatas);
	private static vkGetTensorOpaqueCaptureDataARMFunction vkGetTensorOpaqueCaptureDataARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetTensorOpaqueCaptureDataARM(VkDevice device, uint32 tensorCount, VkTensorARM* pTensors, VkHostAddressRangeEXT* pDatas)
		=> vkGetTensorOpaqueCaptureDataARM_ptr(device, tensorCount, pTensors, pDatas);

	public typealias vkCmdSetSampleLocationsEXTFunction = function void(VkCommandBuffer commandBuffer, VkSampleLocationsInfoEXT* pSampleLocationsInfo);
	private static vkCmdSetSampleLocationsEXTFunction vkCmdSetSampleLocationsEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetSampleLocationsEXT(VkCommandBuffer commandBuffer, VkSampleLocationsInfoEXT* pSampleLocationsInfo)
		=> vkCmdSetSampleLocationsEXT_ptr(commandBuffer, pSampleLocationsInfo);

	public typealias vkGetPhysicalDeviceMultisamplePropertiesEXTFunction = function void(VkPhysicalDevice physicalDevice, VkSampleCountFlags samples, VkMultisamplePropertiesEXT* pMultisampleProperties);
	private static vkGetPhysicalDeviceMultisamplePropertiesEXTFunction vkGetPhysicalDeviceMultisamplePropertiesEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceMultisamplePropertiesEXT(VkPhysicalDevice physicalDevice, VkSampleCountFlags samples, VkMultisamplePropertiesEXT* pMultisampleProperties)
		=> vkGetPhysicalDeviceMultisamplePropertiesEXT_ptr(physicalDevice, samples, pMultisampleProperties);

	public typealias vkCreateAccelerationStructureKHRFunction = function VkResult(VkDevice device, VkAccelerationStructureCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkAccelerationStructureKHR* pAccelerationStructure);
	private static vkCreateAccelerationStructureKHRFunction vkCreateAccelerationStructureKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateAccelerationStructureKHR(VkDevice device, VkAccelerationStructureCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkAccelerationStructureKHR* pAccelerationStructure)
		=> vkCreateAccelerationStructureKHR_ptr(device, pCreateInfo, pAllocator, pAccelerationStructure);

	public typealias vkDestroyAccelerationStructureKHRFunction = function void(VkDevice device, VkAccelerationStructureKHR accelerationStructure, VkAllocationCallbacks* pAllocator);
	private static vkDestroyAccelerationStructureKHRFunction vkDestroyAccelerationStructureKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyAccelerationStructureKHR(VkDevice device, VkAccelerationStructureKHR accelerationStructure, VkAllocationCallbacks* pAllocator)
		=> vkDestroyAccelerationStructureKHR_ptr(device, accelerationStructure, pAllocator);

	public typealias vkCmdBuildAccelerationStructuresKHRFunction = function void(VkCommandBuffer commandBuffer, uint32 infoCount, VkAccelerationStructureBuildGeometryInfoKHR* pInfos, VkAccelerationStructureBuildRangeInfoKHR** ppBuildRangeInfos);
	private static vkCmdBuildAccelerationStructuresKHRFunction vkCmdBuildAccelerationStructuresKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBuildAccelerationStructuresKHR(VkCommandBuffer commandBuffer, uint32 infoCount, VkAccelerationStructureBuildGeometryInfoKHR* pInfos, VkAccelerationStructureBuildRangeInfoKHR** ppBuildRangeInfos)
		=> vkCmdBuildAccelerationStructuresKHR_ptr(commandBuffer, infoCount, pInfos, ppBuildRangeInfos);

	public typealias vkCmdBuildAccelerationStructuresIndirectKHRFunction = function void(VkCommandBuffer commandBuffer, uint32 infoCount, VkAccelerationStructureBuildGeometryInfoKHR* pInfos, uint64* pIndirectDeviceAddresses, uint32* pIndirectStrides, uint32** ppMaxPrimitiveCounts);
	private static vkCmdBuildAccelerationStructuresIndirectKHRFunction vkCmdBuildAccelerationStructuresIndirectKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBuildAccelerationStructuresIndirectKHR(VkCommandBuffer commandBuffer, uint32 infoCount, VkAccelerationStructureBuildGeometryInfoKHR* pInfos, uint64* pIndirectDeviceAddresses, uint32* pIndirectStrides, uint32** ppMaxPrimitiveCounts)
		=> vkCmdBuildAccelerationStructuresIndirectKHR_ptr(commandBuffer, infoCount, pInfos, pIndirectDeviceAddresses, pIndirectStrides, ppMaxPrimitiveCounts);

	public typealias vkBuildAccelerationStructuresKHRFunction = function VkResult(VkDevice device, VkDeferredOperationKHR deferredOperation, uint32 infoCount, VkAccelerationStructureBuildGeometryInfoKHR* pInfos, VkAccelerationStructureBuildRangeInfoKHR** ppBuildRangeInfos);
	private static vkBuildAccelerationStructuresKHRFunction vkBuildAccelerationStructuresKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkBuildAccelerationStructuresKHR(VkDevice device, VkDeferredOperationKHR deferredOperation, uint32 infoCount, VkAccelerationStructureBuildGeometryInfoKHR* pInfos, VkAccelerationStructureBuildRangeInfoKHR** ppBuildRangeInfos)
		=> vkBuildAccelerationStructuresKHR_ptr(device, deferredOperation, infoCount, pInfos, ppBuildRangeInfos);

	public typealias vkCopyAccelerationStructureKHRFunction = function VkResult(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyAccelerationStructureInfoKHR* pInfo);
	private static vkCopyAccelerationStructureKHRFunction vkCopyAccelerationStructureKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCopyAccelerationStructureKHR(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyAccelerationStructureInfoKHR* pInfo)
		=> vkCopyAccelerationStructureKHR_ptr(device, deferredOperation, pInfo);

	public typealias vkCopyAccelerationStructureToMemoryKHRFunction = function VkResult(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyAccelerationStructureToMemoryInfoKHR* pInfo);
	private static vkCopyAccelerationStructureToMemoryKHRFunction vkCopyAccelerationStructureToMemoryKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCopyAccelerationStructureToMemoryKHR(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyAccelerationStructureToMemoryInfoKHR* pInfo)
		=> vkCopyAccelerationStructureToMemoryKHR_ptr(device, deferredOperation, pInfo);

	public typealias vkCopyMemoryToAccelerationStructureKHRFunction = function VkResult(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyMemoryToAccelerationStructureInfoKHR* pInfo);
	private static vkCopyMemoryToAccelerationStructureKHRFunction vkCopyMemoryToAccelerationStructureKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCopyMemoryToAccelerationStructureKHR(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyMemoryToAccelerationStructureInfoKHR* pInfo)
		=> vkCopyMemoryToAccelerationStructureKHR_ptr(device, deferredOperation, pInfo);

	public typealias vkWriteAccelerationStructuresPropertiesKHRFunction = function VkResult(VkDevice device, uint32 accelerationStructureCount, VkAccelerationStructureKHR* pAccelerationStructures, VkQueryType queryType, uint dataSize, void* pData, uint stride);
	private static vkWriteAccelerationStructuresPropertiesKHRFunction vkWriteAccelerationStructuresPropertiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkWriteAccelerationStructuresPropertiesKHR(VkDevice device, uint32 accelerationStructureCount, VkAccelerationStructureKHR* pAccelerationStructures, VkQueryType queryType, uint dataSize, void* pData, uint stride)
		=> vkWriteAccelerationStructuresPropertiesKHR_ptr(device, accelerationStructureCount, pAccelerationStructures, queryType, dataSize, pData, stride);

	public typealias vkCmdCopyAccelerationStructureKHRFunction = function void(VkCommandBuffer commandBuffer, VkCopyAccelerationStructureInfoKHR* pInfo);
	private static vkCmdCopyAccelerationStructureKHRFunction vkCmdCopyAccelerationStructureKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyAccelerationStructureKHR(VkCommandBuffer commandBuffer, VkCopyAccelerationStructureInfoKHR* pInfo)
		=> vkCmdCopyAccelerationStructureKHR_ptr(commandBuffer, pInfo);

	public typealias vkCmdCopyAccelerationStructureToMemoryKHRFunction = function void(VkCommandBuffer commandBuffer, VkCopyAccelerationStructureToMemoryInfoKHR* pInfo);
	private static vkCmdCopyAccelerationStructureToMemoryKHRFunction vkCmdCopyAccelerationStructureToMemoryKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyAccelerationStructureToMemoryKHR(VkCommandBuffer commandBuffer, VkCopyAccelerationStructureToMemoryInfoKHR* pInfo)
		=> vkCmdCopyAccelerationStructureToMemoryKHR_ptr(commandBuffer, pInfo);

	public typealias vkCmdCopyMemoryToAccelerationStructureKHRFunction = function void(VkCommandBuffer commandBuffer, VkCopyMemoryToAccelerationStructureInfoKHR* pInfo);
	private static vkCmdCopyMemoryToAccelerationStructureKHRFunction vkCmdCopyMemoryToAccelerationStructureKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyMemoryToAccelerationStructureKHR(VkCommandBuffer commandBuffer, VkCopyMemoryToAccelerationStructureInfoKHR* pInfo)
		=> vkCmdCopyMemoryToAccelerationStructureKHR_ptr(commandBuffer, pInfo);

	public typealias vkGetAccelerationStructureDeviceAddressKHRFunction = function uint64(VkDevice device, VkAccelerationStructureDeviceAddressInfoKHR* pInfo);
	private static vkGetAccelerationStructureDeviceAddressKHRFunction vkGetAccelerationStructureDeviceAddressKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static uint64 vkGetAccelerationStructureDeviceAddressKHR(VkDevice device, VkAccelerationStructureDeviceAddressInfoKHR* pInfo)
		=> vkGetAccelerationStructureDeviceAddressKHR_ptr(device, pInfo);

	public typealias vkCmdWriteAccelerationStructuresPropertiesKHRFunction = function void(VkCommandBuffer commandBuffer, uint32 accelerationStructureCount, VkAccelerationStructureKHR* pAccelerationStructures, VkQueryType queryType, VkQueryPool queryPool, uint32 firstQuery);
	private static vkCmdWriteAccelerationStructuresPropertiesKHRFunction vkCmdWriteAccelerationStructuresPropertiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdWriteAccelerationStructuresPropertiesKHR(VkCommandBuffer commandBuffer, uint32 accelerationStructureCount, VkAccelerationStructureKHR* pAccelerationStructures, VkQueryType queryType, VkQueryPool queryPool, uint32 firstQuery)
		=> vkCmdWriteAccelerationStructuresPropertiesKHR_ptr(commandBuffer, accelerationStructureCount, pAccelerationStructures, queryType, queryPool, firstQuery);

	public typealias vkGetDeviceAccelerationStructureCompatibilityKHRFunction = function void(VkDevice device, VkAccelerationStructureVersionInfoKHR* pVersionInfo, VkAccelerationStructureCompatibilityKHR* pCompatibility);
	private static vkGetDeviceAccelerationStructureCompatibilityKHRFunction vkGetDeviceAccelerationStructureCompatibilityKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDeviceAccelerationStructureCompatibilityKHR(VkDevice device, VkAccelerationStructureVersionInfoKHR* pVersionInfo, VkAccelerationStructureCompatibilityKHR* pCompatibility)
		=> vkGetDeviceAccelerationStructureCompatibilityKHR_ptr(device, pVersionInfo, pCompatibility);

	public typealias vkGetAccelerationStructureBuildSizesKHRFunction = function void(VkDevice device, VkAccelerationStructureBuildTypeKHR buildType, VkAccelerationStructureBuildGeometryInfoKHR* pBuildInfo, uint32* pMaxPrimitiveCounts, VkAccelerationStructureBuildSizesInfoKHR* pSizeInfo);
	private static vkGetAccelerationStructureBuildSizesKHRFunction vkGetAccelerationStructureBuildSizesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetAccelerationStructureBuildSizesKHR(VkDevice device, VkAccelerationStructureBuildTypeKHR buildType, VkAccelerationStructureBuildGeometryInfoKHR* pBuildInfo, uint32* pMaxPrimitiveCounts, VkAccelerationStructureBuildSizesInfoKHR* pSizeInfo)
		=> vkGetAccelerationStructureBuildSizesKHR_ptr(device, buildType, pBuildInfo, pMaxPrimitiveCounts, pSizeInfo);

	public typealias vkCmdTraceRaysKHRFunction = function void(VkCommandBuffer commandBuffer, VkStridedDeviceAddressRegionKHR* pRaygenShaderBindingTable, VkStridedDeviceAddressRegionKHR* pMissShaderBindingTable, VkStridedDeviceAddressRegionKHR* pHitShaderBindingTable, VkStridedDeviceAddressRegionKHR* pCallableShaderBindingTable, uint32 width, uint32 height, uint32 depth);
	private static vkCmdTraceRaysKHRFunction vkCmdTraceRaysKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdTraceRaysKHR(VkCommandBuffer commandBuffer, VkStridedDeviceAddressRegionKHR* pRaygenShaderBindingTable, VkStridedDeviceAddressRegionKHR* pMissShaderBindingTable, VkStridedDeviceAddressRegionKHR* pHitShaderBindingTable, VkStridedDeviceAddressRegionKHR* pCallableShaderBindingTable, uint32 width, uint32 height, uint32 depth)
		=> vkCmdTraceRaysKHR_ptr(commandBuffer, pRaygenShaderBindingTable, pMissShaderBindingTable, pHitShaderBindingTable, pCallableShaderBindingTable, width, height, depth);

	public typealias vkCreateRayTracingPipelinesKHRFunction = function VkResult(VkDevice device, VkDeferredOperationKHR deferredOperation, VkPipelineCache pipelineCache, uint32 createInfoCount, VkRayTracingPipelineCreateInfoKHR* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines);
	private static vkCreateRayTracingPipelinesKHRFunction vkCreateRayTracingPipelinesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateRayTracingPipelinesKHR(VkDevice device, VkDeferredOperationKHR deferredOperation, VkPipelineCache pipelineCache, uint32 createInfoCount, VkRayTracingPipelineCreateInfoKHR* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines)
		=> vkCreateRayTracingPipelinesKHR_ptr(device, deferredOperation, pipelineCache, createInfoCount, pCreateInfos, pAllocator, pPipelines);

	public typealias vkGetRayTracingShaderGroupHandlesKHRFunction = function VkResult(VkDevice device, VkPipeline pipeline, uint32 firstGroup, uint32 groupCount, uint dataSize, void* pData);
	private static vkGetRayTracingShaderGroupHandlesKHRFunction vkGetRayTracingShaderGroupHandlesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetRayTracingShaderGroupHandlesKHR(VkDevice device, VkPipeline pipeline, uint32 firstGroup, uint32 groupCount, uint dataSize, void* pData)
		=> vkGetRayTracingShaderGroupHandlesKHR_ptr(device, pipeline, firstGroup, groupCount, dataSize, pData);

	public typealias vkGetRayTracingCaptureReplayShaderGroupHandlesKHRFunction = function VkResult(VkDevice device, VkPipeline pipeline, uint32 firstGroup, uint32 groupCount, uint dataSize, void* pData);
	private static vkGetRayTracingCaptureReplayShaderGroupHandlesKHRFunction vkGetRayTracingCaptureReplayShaderGroupHandlesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetRayTracingCaptureReplayShaderGroupHandlesKHR(VkDevice device, VkPipeline pipeline, uint32 firstGroup, uint32 groupCount, uint dataSize, void* pData)
		=> vkGetRayTracingCaptureReplayShaderGroupHandlesKHR_ptr(device, pipeline, firstGroup, groupCount, dataSize, pData);

	public typealias vkCmdTraceRaysIndirectKHRFunction = function void(VkCommandBuffer commandBuffer, VkStridedDeviceAddressRegionKHR* pRaygenShaderBindingTable, VkStridedDeviceAddressRegionKHR* pMissShaderBindingTable, VkStridedDeviceAddressRegionKHR* pHitShaderBindingTable, VkStridedDeviceAddressRegionKHR* pCallableShaderBindingTable, uint64 indirectDeviceAddress);
	private static vkCmdTraceRaysIndirectKHRFunction vkCmdTraceRaysIndirectKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdTraceRaysIndirectKHR(VkCommandBuffer commandBuffer, VkStridedDeviceAddressRegionKHR* pRaygenShaderBindingTable, VkStridedDeviceAddressRegionKHR* pMissShaderBindingTable, VkStridedDeviceAddressRegionKHR* pHitShaderBindingTable, VkStridedDeviceAddressRegionKHR* pCallableShaderBindingTable, uint64 indirectDeviceAddress)
		=> vkCmdTraceRaysIndirectKHR_ptr(commandBuffer, pRaygenShaderBindingTable, pMissShaderBindingTable, pHitShaderBindingTable, pCallableShaderBindingTable, indirectDeviceAddress);

	public typealias vkGetRayTracingShaderGroupStackSizeKHRFunction = function uint64(VkDevice device, VkPipeline pipeline, uint32 group, VkShaderGroupShaderKHR groupShader);
	private static vkGetRayTracingShaderGroupStackSizeKHRFunction vkGetRayTracingShaderGroupStackSizeKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static uint64 vkGetRayTracingShaderGroupStackSizeKHR(VkDevice device, VkPipeline pipeline, uint32 group, VkShaderGroupShaderKHR groupShader)
		=> vkGetRayTracingShaderGroupStackSizeKHR_ptr(device, pipeline, group, groupShader);

	public typealias vkCmdSetRayTracingPipelineStackSizeKHRFunction = function void(VkCommandBuffer commandBuffer, uint32 pipelineStackSize);
	private static vkCmdSetRayTracingPipelineStackSizeKHRFunction vkCmdSetRayTracingPipelineStackSizeKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetRayTracingPipelineStackSizeKHR(VkCommandBuffer commandBuffer, uint32 pipelineStackSize)
		=> vkCmdSetRayTracingPipelineStackSizeKHR_ptr(commandBuffer, pipelineStackSize);

	public typealias vkGetImageDrmFormatModifierPropertiesEXTFunction = function VkResult(VkDevice device, VkImage image, VkImageDrmFormatModifierPropertiesEXT* pProperties);
	private static vkGetImageDrmFormatModifierPropertiesEXTFunction vkGetImageDrmFormatModifierPropertiesEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetImageDrmFormatModifierPropertiesEXT(VkDevice device, VkImage image, VkImageDrmFormatModifierPropertiesEXT* pProperties)
		=> vkGetImageDrmFormatModifierPropertiesEXT_ptr(device, image, pProperties);

	public typealias vkCreateValidationCacheEXTFunction = function VkResult(VkDevice device, VkValidationCacheCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkValidationCacheEXT* pValidationCache);
	private static vkCreateValidationCacheEXTFunction vkCreateValidationCacheEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateValidationCacheEXT(VkDevice device, VkValidationCacheCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkValidationCacheEXT* pValidationCache)
		=> vkCreateValidationCacheEXT_ptr(device, pCreateInfo, pAllocator, pValidationCache);

	public typealias vkDestroyValidationCacheEXTFunction = function void(VkDevice device, VkValidationCacheEXT validationCache, VkAllocationCallbacks* pAllocator);
	private static vkDestroyValidationCacheEXTFunction vkDestroyValidationCacheEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyValidationCacheEXT(VkDevice device, VkValidationCacheEXT validationCache, VkAllocationCallbacks* pAllocator)
		=> vkDestroyValidationCacheEXT_ptr(device, validationCache, pAllocator);

	public typealias vkMergeValidationCachesEXTFunction = function VkResult(VkDevice device, VkValidationCacheEXT dstCache, uint32 srcCacheCount, VkValidationCacheEXT* pSrcCaches);
	private static vkMergeValidationCachesEXTFunction vkMergeValidationCachesEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkMergeValidationCachesEXT(VkDevice device, VkValidationCacheEXT dstCache, uint32 srcCacheCount, VkValidationCacheEXT* pSrcCaches)
		=> vkMergeValidationCachesEXT_ptr(device, dstCache, srcCacheCount, pSrcCaches);

	public typealias vkGetValidationCacheDataEXTFunction = function VkResult(VkDevice device, VkValidationCacheEXT validationCache, uint* pDataSize, void* pData);
	private static vkGetValidationCacheDataEXTFunction vkGetValidationCacheDataEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetValidationCacheDataEXT(VkDevice device, VkValidationCacheEXT validationCache, uint* pDataSize, void* pData)
		=> vkGetValidationCacheDataEXT_ptr(device, validationCache, pDataSize, pData);

	public typealias vkCmdBindShadingRateImageNVFunction = function void(VkCommandBuffer commandBuffer, VkImageView imageView, VkImageLayout imageLayout);
	private static vkCmdBindShadingRateImageNVFunction vkCmdBindShadingRateImageNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindShadingRateImageNV(VkCommandBuffer commandBuffer, VkImageView imageView, VkImageLayout imageLayout)
		=> vkCmdBindShadingRateImageNV_ptr(commandBuffer, imageView, imageLayout);

	public typealias vkCmdSetViewportShadingRatePaletteNVFunction = function void(VkCommandBuffer commandBuffer, uint32 firstViewport, uint32 viewportCount, VkShadingRatePaletteNV* pShadingRatePalettes);
	private static vkCmdSetViewportShadingRatePaletteNVFunction vkCmdSetViewportShadingRatePaletteNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetViewportShadingRatePaletteNV(VkCommandBuffer commandBuffer, uint32 firstViewport, uint32 viewportCount, VkShadingRatePaletteNV* pShadingRatePalettes)
		=> vkCmdSetViewportShadingRatePaletteNV_ptr(commandBuffer, firstViewport, viewportCount, pShadingRatePalettes);

	public typealias vkCmdSetCoarseSampleOrderNVFunction = function void(VkCommandBuffer commandBuffer, VkCoarseSampleOrderTypeNV sampleOrderType, uint32 customSampleOrderCount, VkCoarseSampleOrderCustomNV* pCustomSampleOrders);
	private static vkCmdSetCoarseSampleOrderNVFunction vkCmdSetCoarseSampleOrderNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetCoarseSampleOrderNV(VkCommandBuffer commandBuffer, VkCoarseSampleOrderTypeNV sampleOrderType, uint32 customSampleOrderCount, VkCoarseSampleOrderCustomNV* pCustomSampleOrders)
		=> vkCmdSetCoarseSampleOrderNV_ptr(commandBuffer, sampleOrderType, customSampleOrderCount, pCustomSampleOrders);

	public typealias vkCreateAccelerationStructureNVFunction = function VkResult(VkDevice device, VkAccelerationStructureCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkAccelerationStructureNV* pAccelerationStructure);
	private static vkCreateAccelerationStructureNVFunction vkCreateAccelerationStructureNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateAccelerationStructureNV(VkDevice device, VkAccelerationStructureCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkAccelerationStructureNV* pAccelerationStructure)
		=> vkCreateAccelerationStructureNV_ptr(device, pCreateInfo, pAllocator, pAccelerationStructure);

	public typealias vkDestroyAccelerationStructureNVFunction = function void(VkDevice device, VkAccelerationStructureNV accelerationStructure, VkAllocationCallbacks* pAllocator);
	private static vkDestroyAccelerationStructureNVFunction vkDestroyAccelerationStructureNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyAccelerationStructureNV(VkDevice device, VkAccelerationStructureNV accelerationStructure, VkAllocationCallbacks* pAllocator)
		=> vkDestroyAccelerationStructureNV_ptr(device, accelerationStructure, pAllocator);

	public typealias vkGetAccelerationStructureMemoryRequirementsNVFunction = function void(VkDevice device, VkAccelerationStructureMemoryRequirementsInfoNV* pInfo, VkMemoryRequirements2* pMemoryRequirements);
	private static vkGetAccelerationStructureMemoryRequirementsNVFunction vkGetAccelerationStructureMemoryRequirementsNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetAccelerationStructureMemoryRequirementsNV(VkDevice device, VkAccelerationStructureMemoryRequirementsInfoNV* pInfo, VkMemoryRequirements2* pMemoryRequirements)
		=> vkGetAccelerationStructureMemoryRequirementsNV_ptr(device, pInfo, pMemoryRequirements);

	public typealias vkBindAccelerationStructureMemoryNVFunction = function VkResult(VkDevice device, uint32 bindInfoCount, VkBindAccelerationStructureMemoryInfoNV* pBindInfos);
	private static vkBindAccelerationStructureMemoryNVFunction vkBindAccelerationStructureMemoryNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkBindAccelerationStructureMemoryNV(VkDevice device, uint32 bindInfoCount, VkBindAccelerationStructureMemoryInfoNV* pBindInfos)
		=> vkBindAccelerationStructureMemoryNV_ptr(device, bindInfoCount, pBindInfos);

	public typealias vkCmdBuildAccelerationStructureNVFunction = function void(VkCommandBuffer commandBuffer, VkAccelerationStructureInfoNV* pInfo, VkBuffer instanceData, uint64 instanceOffset, VkBool32 update, VkAccelerationStructureNV dst, VkAccelerationStructureNV src, VkBuffer scratch, uint64 scratchOffset);
	private static vkCmdBuildAccelerationStructureNVFunction vkCmdBuildAccelerationStructureNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBuildAccelerationStructureNV(VkCommandBuffer commandBuffer, VkAccelerationStructureInfoNV* pInfo, VkBuffer instanceData, uint64 instanceOffset, VkBool32 update, VkAccelerationStructureNV dst, VkAccelerationStructureNV src, VkBuffer scratch, uint64 scratchOffset)
		=> vkCmdBuildAccelerationStructureNV_ptr(commandBuffer, pInfo, instanceData, instanceOffset, update, dst, src, scratch, scratchOffset);

	public typealias vkCmdCopyAccelerationStructureNVFunction = function void(VkCommandBuffer commandBuffer, VkAccelerationStructureNV dst, VkAccelerationStructureNV src, VkCopyAccelerationStructureModeKHR mode);
	private static vkCmdCopyAccelerationStructureNVFunction vkCmdCopyAccelerationStructureNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyAccelerationStructureNV(VkCommandBuffer commandBuffer, VkAccelerationStructureNV dst, VkAccelerationStructureNV src, VkCopyAccelerationStructureModeKHR mode)
		=> vkCmdCopyAccelerationStructureNV_ptr(commandBuffer, dst, src, mode);

	public typealias vkCmdTraceRaysNVFunction = function void(VkCommandBuffer commandBuffer, VkBuffer raygenShaderBindingTableBuffer, uint64 raygenShaderBindingOffset, VkBuffer missShaderBindingTableBuffer, uint64 missShaderBindingOffset, uint64 missShaderBindingStride, VkBuffer hitShaderBindingTableBuffer, uint64 hitShaderBindingOffset, uint64 hitShaderBindingStride, VkBuffer callableShaderBindingTableBuffer, uint64 callableShaderBindingOffset, uint64 callableShaderBindingStride, uint32 width, uint32 height, uint32 depth);
	private static vkCmdTraceRaysNVFunction vkCmdTraceRaysNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdTraceRaysNV(VkCommandBuffer commandBuffer, VkBuffer raygenShaderBindingTableBuffer, uint64 raygenShaderBindingOffset, VkBuffer missShaderBindingTableBuffer, uint64 missShaderBindingOffset, uint64 missShaderBindingStride, VkBuffer hitShaderBindingTableBuffer, uint64 hitShaderBindingOffset, uint64 hitShaderBindingStride, VkBuffer callableShaderBindingTableBuffer, uint64 callableShaderBindingOffset, uint64 callableShaderBindingStride, uint32 width, uint32 height, uint32 depth)
		=> vkCmdTraceRaysNV_ptr(commandBuffer, raygenShaderBindingTableBuffer, raygenShaderBindingOffset, missShaderBindingTableBuffer, missShaderBindingOffset, missShaderBindingStride, hitShaderBindingTableBuffer, hitShaderBindingOffset, hitShaderBindingStride, callableShaderBindingTableBuffer, callableShaderBindingOffset, callableShaderBindingStride, width, height, depth);

	public typealias vkCreateRayTracingPipelinesNVFunction = function VkResult(VkDevice device, VkPipelineCache pipelineCache, uint32 createInfoCount, VkRayTracingPipelineCreateInfoNV* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines);
	private static vkCreateRayTracingPipelinesNVFunction vkCreateRayTracingPipelinesNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateRayTracingPipelinesNV(VkDevice device, VkPipelineCache pipelineCache, uint32 createInfoCount, VkRayTracingPipelineCreateInfoNV* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines)
		=> vkCreateRayTracingPipelinesNV_ptr(device, pipelineCache, createInfoCount, pCreateInfos, pAllocator, pPipelines);

	public typealias vkGetAccelerationStructureHandleNVFunction = function VkResult(VkDevice device, VkAccelerationStructureNV accelerationStructure, uint dataSize, void* pData);
	private static vkGetAccelerationStructureHandleNVFunction vkGetAccelerationStructureHandleNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetAccelerationStructureHandleNV(VkDevice device, VkAccelerationStructureNV accelerationStructure, uint dataSize, void* pData)
		=> vkGetAccelerationStructureHandleNV_ptr(device, accelerationStructure, dataSize, pData);

	public typealias vkCmdWriteAccelerationStructuresPropertiesNVFunction = function void(VkCommandBuffer commandBuffer, uint32 accelerationStructureCount, VkAccelerationStructureNV* pAccelerationStructures, VkQueryType queryType, VkQueryPool queryPool, uint32 firstQuery);
	private static vkCmdWriteAccelerationStructuresPropertiesNVFunction vkCmdWriteAccelerationStructuresPropertiesNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdWriteAccelerationStructuresPropertiesNV(VkCommandBuffer commandBuffer, uint32 accelerationStructureCount, VkAccelerationStructureNV* pAccelerationStructures, VkQueryType queryType, VkQueryPool queryPool, uint32 firstQuery)
		=> vkCmdWriteAccelerationStructuresPropertiesNV_ptr(commandBuffer, accelerationStructureCount, pAccelerationStructures, queryType, queryPool, firstQuery);

	public typealias vkCompileDeferredNVFunction = function VkResult(VkDevice device, VkPipeline pipeline, uint32 shader);
	private static vkCompileDeferredNVFunction vkCompileDeferredNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCompileDeferredNV(VkDevice device, VkPipeline pipeline, uint32 shader)
		=> vkCompileDeferredNV_ptr(device, pipeline, shader);

	public typealias vkGetMemoryHostPointerPropertiesEXTFunction = function VkResult(VkDevice device, VkExternalMemoryHandleTypeFlags handleType, void* pHostPointer, VkMemoryHostPointerPropertiesEXT* pMemoryHostPointerProperties);
	private static vkGetMemoryHostPointerPropertiesEXTFunction vkGetMemoryHostPointerPropertiesEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemoryHostPointerPropertiesEXT(VkDevice device, VkExternalMemoryHandleTypeFlags handleType, void* pHostPointer, VkMemoryHostPointerPropertiesEXT* pMemoryHostPointerProperties)
		=> vkGetMemoryHostPointerPropertiesEXT_ptr(device, handleType, pHostPointer, pMemoryHostPointerProperties);

	public typealias vkCmdWriteBufferMarkerAMDFunction = function void(VkCommandBuffer commandBuffer, VkPipelineStageFlags pipelineStage, VkBuffer dstBuffer, uint64 dstOffset, uint32 marker);
	private static vkCmdWriteBufferMarkerAMDFunction vkCmdWriteBufferMarkerAMD_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdWriteBufferMarkerAMD(VkCommandBuffer commandBuffer, VkPipelineStageFlags pipelineStage, VkBuffer dstBuffer, uint64 dstOffset, uint32 marker)
		=> vkCmdWriteBufferMarkerAMD_ptr(commandBuffer, pipelineStage, dstBuffer, dstOffset, marker);

	public typealias vkCmdWriteBufferMarker2AMDFunction = function void(VkCommandBuffer commandBuffer, uint64 stage, VkBuffer dstBuffer, uint64 dstOffset, uint32 marker);
	private static vkCmdWriteBufferMarker2AMDFunction vkCmdWriteBufferMarker2AMD_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdWriteBufferMarker2AMD(VkCommandBuffer commandBuffer, uint64 stage, VkBuffer dstBuffer, uint64 dstOffset, uint32 marker)
		=> vkCmdWriteBufferMarker2AMD_ptr(commandBuffer, stage, dstBuffer, dstOffset, marker);

	public typealias vkGetPhysicalDeviceCalibrateableTimeDomainsKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pTimeDomainCount, VkTimeDomainKHR* pTimeDomains);
	private static vkGetPhysicalDeviceCalibrateableTimeDomainsKHRFunction vkGetPhysicalDeviceCalibrateableTimeDomainsKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceCalibrateableTimeDomainsKHR(VkPhysicalDevice physicalDevice, uint32* pTimeDomainCount, VkTimeDomainKHR* pTimeDomains)
		=> vkGetPhysicalDeviceCalibrateableTimeDomainsKHR_ptr(physicalDevice, pTimeDomainCount, pTimeDomains);

	public typealias vkGetCalibratedTimestampsKHRFunction = function VkResult(VkDevice device, uint32 timestampCount, VkCalibratedTimestampInfoKHR* pTimestampInfos, uint64* pTimestamps, uint64* pMaxDeviation);
	private static vkGetCalibratedTimestampsKHRFunction vkGetCalibratedTimestampsKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetCalibratedTimestampsKHR(VkDevice device, uint32 timestampCount, VkCalibratedTimestampInfoKHR* pTimestampInfos, uint64* pTimestamps, uint64* pMaxDeviation)
		=> vkGetCalibratedTimestampsKHR_ptr(device, timestampCount, pTimestampInfos, pTimestamps, pMaxDeviation);

	public typealias vkCmdDrawMeshTasksNVFunction = function void(VkCommandBuffer commandBuffer, uint32 taskCount, uint32 firstTask);
	private static vkCmdDrawMeshTasksNVFunction vkCmdDrawMeshTasksNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawMeshTasksNV(VkCommandBuffer commandBuffer, uint32 taskCount, uint32 firstTask)
		=> vkCmdDrawMeshTasksNV_ptr(commandBuffer, taskCount, firstTask);

	public typealias vkCmdDrawMeshTasksIndirectNVFunction = function void(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride);
	private static vkCmdDrawMeshTasksIndirectNVFunction vkCmdDrawMeshTasksIndirectNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawMeshTasksIndirectNV(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
		=> vkCmdDrawMeshTasksIndirectNV_ptr(commandBuffer, buffer, offset, drawCount, stride);

	public typealias vkCmdDrawMeshTasksIndirectCountNVFunction = function void(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, VkBuffer countBuffer, uint64 countBufferOffset, uint32 maxDrawCount, uint32 stride);
	private static vkCmdDrawMeshTasksIndirectCountNVFunction vkCmdDrawMeshTasksIndirectCountNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawMeshTasksIndirectCountNV(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, VkBuffer countBuffer, uint64 countBufferOffset, uint32 maxDrawCount, uint32 stride)
		=> vkCmdDrawMeshTasksIndirectCountNV_ptr(commandBuffer, buffer, offset, countBuffer, countBufferOffset, maxDrawCount, stride);

	public typealias vkCmdSetExclusiveScissorEnableNVFunction = function void(VkCommandBuffer commandBuffer, uint32 firstExclusiveScissor, uint32 exclusiveScissorCount, VkBool32* pExclusiveScissorEnables);
	private static vkCmdSetExclusiveScissorEnableNVFunction vkCmdSetExclusiveScissorEnableNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetExclusiveScissorEnableNV(VkCommandBuffer commandBuffer, uint32 firstExclusiveScissor, uint32 exclusiveScissorCount, VkBool32* pExclusiveScissorEnables)
		=> vkCmdSetExclusiveScissorEnableNV_ptr(commandBuffer, firstExclusiveScissor, exclusiveScissorCount, pExclusiveScissorEnables);

	public typealias vkCmdSetExclusiveScissorNVFunction = function void(VkCommandBuffer commandBuffer, uint32 firstExclusiveScissor, uint32 exclusiveScissorCount, VkRect2D* pExclusiveScissors);
	private static vkCmdSetExclusiveScissorNVFunction vkCmdSetExclusiveScissorNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetExclusiveScissorNV(VkCommandBuffer commandBuffer, uint32 firstExclusiveScissor, uint32 exclusiveScissorCount, VkRect2D* pExclusiveScissors)
		=> vkCmdSetExclusiveScissorNV_ptr(commandBuffer, firstExclusiveScissor, exclusiveScissorCount, pExclusiveScissors);

	public typealias vkCmdSetCheckpointNVFunction = function void(VkCommandBuffer commandBuffer, void* pCheckpointMarker);
	private static vkCmdSetCheckpointNVFunction vkCmdSetCheckpointNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetCheckpointNV(VkCommandBuffer commandBuffer, void* pCheckpointMarker)
		=> vkCmdSetCheckpointNV_ptr(commandBuffer, pCheckpointMarker);

	public typealias vkGetQueueCheckpointDataNVFunction = function void(VkQueue queue, uint32* pCheckpointDataCount, VkCheckpointDataNV* pCheckpointData);
	private static vkGetQueueCheckpointDataNVFunction vkGetQueueCheckpointDataNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetQueueCheckpointDataNV(VkQueue queue, uint32* pCheckpointDataCount, VkCheckpointDataNV* pCheckpointData)
		=> vkGetQueueCheckpointDataNV_ptr(queue, pCheckpointDataCount, pCheckpointData);

	public typealias vkGetQueueCheckpointData2NVFunction = function void(VkQueue queue, uint32* pCheckpointDataCount, VkCheckpointData2NV* pCheckpointData);
	private static vkGetQueueCheckpointData2NVFunction vkGetQueueCheckpointData2NV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetQueueCheckpointData2NV(VkQueue queue, uint32* pCheckpointDataCount, VkCheckpointData2NV* pCheckpointData)
		=> vkGetQueueCheckpointData2NV_ptr(queue, pCheckpointDataCount, pCheckpointData);

	public typealias vkSetSwapchainPresentTimingQueueSizeEXTFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain, uint32 size);
	private static vkSetSwapchainPresentTimingQueueSizeEXTFunction vkSetSwapchainPresentTimingQueueSizeEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkSetSwapchainPresentTimingQueueSizeEXT(VkDevice device, VkSwapchainKHR swapchain, uint32 size)
		=> vkSetSwapchainPresentTimingQueueSizeEXT_ptr(device, swapchain, size);

	public typealias vkGetSwapchainTimingPropertiesEXTFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain, VkSwapchainTimingPropertiesEXT* pSwapchainTimingProperties, uint64* pSwapchainTimingPropertiesCounter);
	private static vkGetSwapchainTimingPropertiesEXTFunction vkGetSwapchainTimingPropertiesEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetSwapchainTimingPropertiesEXT(VkDevice device, VkSwapchainKHR swapchain, VkSwapchainTimingPropertiesEXT* pSwapchainTimingProperties, uint64* pSwapchainTimingPropertiesCounter)
		=> vkGetSwapchainTimingPropertiesEXT_ptr(device, swapchain, pSwapchainTimingProperties, pSwapchainTimingPropertiesCounter);

	public typealias vkGetSwapchainTimeDomainPropertiesEXTFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain, VkSwapchainTimeDomainPropertiesEXT* pSwapchainTimeDomainProperties, uint64* pTimeDomainsCounter);
	private static vkGetSwapchainTimeDomainPropertiesEXTFunction vkGetSwapchainTimeDomainPropertiesEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetSwapchainTimeDomainPropertiesEXT(VkDevice device, VkSwapchainKHR swapchain, VkSwapchainTimeDomainPropertiesEXT* pSwapchainTimeDomainProperties, uint64* pTimeDomainsCounter)
		=> vkGetSwapchainTimeDomainPropertiesEXT_ptr(device, swapchain, pSwapchainTimeDomainProperties, pTimeDomainsCounter);

	public typealias vkGetPastPresentationTimingEXTFunction = function VkResult(VkDevice device, VkPastPresentationTimingInfoEXT* pPastPresentationTimingInfo, VkPastPresentationTimingPropertiesEXT* pPastPresentationTimingProperties);
	private static vkGetPastPresentationTimingEXTFunction vkGetPastPresentationTimingEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPastPresentationTimingEXT(VkDevice device, VkPastPresentationTimingInfoEXT* pPastPresentationTimingInfo, VkPastPresentationTimingPropertiesEXT* pPastPresentationTimingProperties)
		=> vkGetPastPresentationTimingEXT_ptr(device, pPastPresentationTimingInfo, pPastPresentationTimingProperties);

	public typealias vkInitializePerformanceApiINTELFunction = function VkResult(VkDevice device, VkInitializePerformanceApiInfoINTEL* pInitializeInfo);
	private static vkInitializePerformanceApiINTELFunction vkInitializePerformanceApiINTEL_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkInitializePerformanceApiINTEL(VkDevice device, VkInitializePerformanceApiInfoINTEL* pInitializeInfo)
		=> vkInitializePerformanceApiINTEL_ptr(device, pInitializeInfo);

	public typealias vkUninitializePerformanceApiINTELFunction = function void(VkDevice device);
	private static vkUninitializePerformanceApiINTELFunction vkUninitializePerformanceApiINTEL_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkUninitializePerformanceApiINTEL(VkDevice device)
		=> vkUninitializePerformanceApiINTEL_ptr(device);

	public typealias vkCmdSetPerformanceMarkerINTELFunction = function VkResult(VkCommandBuffer commandBuffer, VkPerformanceMarkerInfoINTEL* pMarkerInfo);
	private static vkCmdSetPerformanceMarkerINTELFunction vkCmdSetPerformanceMarkerINTEL_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCmdSetPerformanceMarkerINTEL(VkCommandBuffer commandBuffer, VkPerformanceMarkerInfoINTEL* pMarkerInfo)
		=> vkCmdSetPerformanceMarkerINTEL_ptr(commandBuffer, pMarkerInfo);

	public typealias vkCmdSetPerformanceStreamMarkerINTELFunction = function VkResult(VkCommandBuffer commandBuffer, VkPerformanceStreamMarkerInfoINTEL* pMarkerInfo);
	private static vkCmdSetPerformanceStreamMarkerINTELFunction vkCmdSetPerformanceStreamMarkerINTEL_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCmdSetPerformanceStreamMarkerINTEL(VkCommandBuffer commandBuffer, VkPerformanceStreamMarkerInfoINTEL* pMarkerInfo)
		=> vkCmdSetPerformanceStreamMarkerINTEL_ptr(commandBuffer, pMarkerInfo);

	public typealias vkCmdSetPerformanceOverrideINTELFunction = function VkResult(VkCommandBuffer commandBuffer, VkPerformanceOverrideInfoINTEL* pOverrideInfo);
	private static vkCmdSetPerformanceOverrideINTELFunction vkCmdSetPerformanceOverrideINTEL_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCmdSetPerformanceOverrideINTEL(VkCommandBuffer commandBuffer, VkPerformanceOverrideInfoINTEL* pOverrideInfo)
		=> vkCmdSetPerformanceOverrideINTEL_ptr(commandBuffer, pOverrideInfo);

	public typealias vkAcquirePerformanceConfigurationINTELFunction = function VkResult(VkDevice device, VkPerformanceConfigurationAcquireInfoINTEL* pAcquireInfo, VkPerformanceConfigurationINTEL* pConfiguration);
	private static vkAcquirePerformanceConfigurationINTELFunction vkAcquirePerformanceConfigurationINTEL_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkAcquirePerformanceConfigurationINTEL(VkDevice device, VkPerformanceConfigurationAcquireInfoINTEL* pAcquireInfo, VkPerformanceConfigurationINTEL* pConfiguration)
		=> vkAcquirePerformanceConfigurationINTEL_ptr(device, pAcquireInfo, pConfiguration);

	public typealias vkReleasePerformanceConfigurationINTELFunction = function VkResult(VkDevice device, VkPerformanceConfigurationINTEL configuration);
	private static vkReleasePerformanceConfigurationINTELFunction vkReleasePerformanceConfigurationINTEL_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkReleasePerformanceConfigurationINTEL(VkDevice device, VkPerformanceConfigurationINTEL configuration)
		=> vkReleasePerformanceConfigurationINTEL_ptr(device, configuration);

	public typealias vkQueueSetPerformanceConfigurationINTELFunction = function VkResult(VkQueue queue, VkPerformanceConfigurationINTEL configuration);
	private static vkQueueSetPerformanceConfigurationINTELFunction vkQueueSetPerformanceConfigurationINTEL_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkQueueSetPerformanceConfigurationINTEL(VkQueue queue, VkPerformanceConfigurationINTEL configuration)
		=> vkQueueSetPerformanceConfigurationINTEL_ptr(queue, configuration);

	public typealias vkGetPerformanceParameterINTELFunction = function VkResult(VkDevice device, VkPerformanceParameterTypeINTEL parameter, VkPerformanceValueINTEL* pValue);
	private static vkGetPerformanceParameterINTELFunction vkGetPerformanceParameterINTEL_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPerformanceParameterINTEL(VkDevice device, VkPerformanceParameterTypeINTEL parameter, VkPerformanceValueINTEL* pValue)
		=> vkGetPerformanceParameterINTEL_ptr(device, parameter, pValue);

	public typealias vkSetLocalDimmingAMDFunction = function void(VkDevice device, VkSwapchainKHR swapChain, VkBool32 localDimmingEnable);
	private static vkSetLocalDimmingAMDFunction vkSetLocalDimmingAMD_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkSetLocalDimmingAMD(VkDevice device, VkSwapchainKHR swapChain, VkBool32 localDimmingEnable)
		=> vkSetLocalDimmingAMD_ptr(device, swapChain, localDimmingEnable);

	public typealias vkCreateImagePipeSurfaceFUCHSIAFunction = function VkResult(VkInstance instance, VkImagePipeSurfaceCreateInfoFUCHSIA* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateImagePipeSurfaceFUCHSIAFunction vkCreateImagePipeSurfaceFUCHSIA_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateImagePipeSurfaceFUCHSIA(VkInstance instance, VkImagePipeSurfaceCreateInfoFUCHSIA* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateImagePipeSurfaceFUCHSIA_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkCreateMetalSurfaceEXTFunction = function VkResult(VkInstance instance, VkMetalSurfaceCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateMetalSurfaceEXTFunction vkCreateMetalSurfaceEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateMetalSurfaceEXT(VkInstance instance, VkMetalSurfaceCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateMetalSurfaceEXT_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkGetPhysicalDeviceFragmentShadingRatesKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pFragmentShadingRateCount, VkPhysicalDeviceFragmentShadingRateKHR* pFragmentShadingRates);
	private static vkGetPhysicalDeviceFragmentShadingRatesKHRFunction vkGetPhysicalDeviceFragmentShadingRatesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceFragmentShadingRatesKHR(VkPhysicalDevice physicalDevice, uint32* pFragmentShadingRateCount, VkPhysicalDeviceFragmentShadingRateKHR* pFragmentShadingRates)
		=> vkGetPhysicalDeviceFragmentShadingRatesKHR_ptr(physicalDevice, pFragmentShadingRateCount, pFragmentShadingRates);

	public typealias vkCmdSetFragmentShadingRateKHRFunction = function void(VkCommandBuffer commandBuffer, VkExtent2D* pFragmentSize, VkFragmentShadingRateCombinerOpKHR[2] combinerOps);
	private static vkCmdSetFragmentShadingRateKHRFunction vkCmdSetFragmentShadingRateKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetFragmentShadingRateKHR(VkCommandBuffer commandBuffer, VkExtent2D* pFragmentSize, VkFragmentShadingRateCombinerOpKHR[2] combinerOps)
		=> vkCmdSetFragmentShadingRateKHR_ptr(commandBuffer, pFragmentSize, combinerOps);

	public typealias vkWaitForPresentKHRFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain, uint64 presentId, uint64 timeout);
	private static vkWaitForPresentKHRFunction vkWaitForPresentKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkWaitForPresentKHR(VkDevice device, VkSwapchainKHR swapchain, uint64 presentId, uint64 timeout)
		=> vkWaitForPresentKHR_ptr(device, swapchain, presentId, timeout);

	public typealias vkGetPhysicalDeviceCooperativeMatrixPropertiesNVFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkCooperativeMatrixPropertiesNV* pProperties);
	private static vkGetPhysicalDeviceCooperativeMatrixPropertiesNVFunction vkGetPhysicalDeviceCooperativeMatrixPropertiesNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceCooperativeMatrixPropertiesNV(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkCooperativeMatrixPropertiesNV* pProperties)
		=> vkGetPhysicalDeviceCooperativeMatrixPropertiesNV_ptr(physicalDevice, pPropertyCount, pProperties);

	public typealias vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNVFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pCombinationCount, VkFramebufferMixedSamplesCombinationNV* pCombinations);
	private static vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNVFunction vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV(VkPhysicalDevice physicalDevice, uint32* pCombinationCount, VkFramebufferMixedSamplesCombinationNV* pCombinations)
		=> vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV_ptr(physicalDevice, pCombinationCount, pCombinations);

	public typealias vkGetPhysicalDeviceSurfacePresentModes2EXTFunction = function VkResult(VkPhysicalDevice physicalDevice, VkPhysicalDeviceSurfaceInfo2KHR* pSurfaceInfo, uint32* pPresentModeCount, VkPresentModeKHR* pPresentModes);
	private static vkGetPhysicalDeviceSurfacePresentModes2EXTFunction vkGetPhysicalDeviceSurfacePresentModes2EXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceSurfacePresentModes2EXT(VkPhysicalDevice physicalDevice, VkPhysicalDeviceSurfaceInfo2KHR* pSurfaceInfo, uint32* pPresentModeCount, VkPresentModeKHR* pPresentModes)
		=> vkGetPhysicalDeviceSurfacePresentModes2EXT_ptr(physicalDevice, pSurfaceInfo, pPresentModeCount, pPresentModes);

	public typealias vkAcquireFullScreenExclusiveModeEXTFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain);
	private static vkAcquireFullScreenExclusiveModeEXTFunction vkAcquireFullScreenExclusiveModeEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkAcquireFullScreenExclusiveModeEXT(VkDevice device, VkSwapchainKHR swapchain)
		=> vkAcquireFullScreenExclusiveModeEXT_ptr(device, swapchain);

	public typealias vkReleaseFullScreenExclusiveModeEXTFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain);
	private static vkReleaseFullScreenExclusiveModeEXTFunction vkReleaseFullScreenExclusiveModeEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkReleaseFullScreenExclusiveModeEXT(VkDevice device, VkSwapchainKHR swapchain)
		=> vkReleaseFullScreenExclusiveModeEXT_ptr(device, swapchain);

	public typealias vkGetDeviceGroupSurfacePresentModes2EXTFunction = function VkResult(VkDevice device, VkPhysicalDeviceSurfaceInfo2KHR* pSurfaceInfo, VkDeviceGroupPresentModeFlagsKHR* pModes);
	private static vkGetDeviceGroupSurfacePresentModes2EXTFunction vkGetDeviceGroupSurfacePresentModes2EXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDeviceGroupSurfacePresentModes2EXT(VkDevice device, VkPhysicalDeviceSurfaceInfo2KHR* pSurfaceInfo, VkDeviceGroupPresentModeFlagsKHR* pModes)
		=> vkGetDeviceGroupSurfacePresentModes2EXT_ptr(device, pSurfaceInfo, pModes);

	public typealias vkCreateHeadlessSurfaceEXTFunction = function VkResult(VkInstance instance, VkHeadlessSurfaceCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateHeadlessSurfaceEXTFunction vkCreateHeadlessSurfaceEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateHeadlessSurfaceEXT(VkInstance instance, VkHeadlessSurfaceCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateHeadlessSurfaceEXT_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkCreateDeferredOperationKHRFunction = function VkResult(VkDevice device, VkAllocationCallbacks* pAllocator, VkDeferredOperationKHR* pDeferredOperation);
	private static vkCreateDeferredOperationKHRFunction vkCreateDeferredOperationKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateDeferredOperationKHR(VkDevice device, VkAllocationCallbacks* pAllocator, VkDeferredOperationKHR* pDeferredOperation)
		=> vkCreateDeferredOperationKHR_ptr(device, pAllocator, pDeferredOperation);

	public typealias vkDestroyDeferredOperationKHRFunction = function void(VkDevice device, VkDeferredOperationKHR operation, VkAllocationCallbacks* pAllocator);
	private static vkDestroyDeferredOperationKHRFunction vkDestroyDeferredOperationKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyDeferredOperationKHR(VkDevice device, VkDeferredOperationKHR operation, VkAllocationCallbacks* pAllocator)
		=> vkDestroyDeferredOperationKHR_ptr(device, operation, pAllocator);

	public typealias vkGetDeferredOperationMaxConcurrencyKHRFunction = function uint32(VkDevice device, VkDeferredOperationKHR operation);
	private static vkGetDeferredOperationMaxConcurrencyKHRFunction vkGetDeferredOperationMaxConcurrencyKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static uint32 vkGetDeferredOperationMaxConcurrencyKHR(VkDevice device, VkDeferredOperationKHR operation)
		=> vkGetDeferredOperationMaxConcurrencyKHR_ptr(device, operation);

	public typealias vkGetDeferredOperationResultKHRFunction = function VkResult(VkDevice device, VkDeferredOperationKHR operation);
	private static vkGetDeferredOperationResultKHRFunction vkGetDeferredOperationResultKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDeferredOperationResultKHR(VkDevice device, VkDeferredOperationKHR operation)
		=> vkGetDeferredOperationResultKHR_ptr(device, operation);

	public typealias vkDeferredOperationJoinKHRFunction = function VkResult(VkDevice device, VkDeferredOperationKHR operation);
	private static vkDeferredOperationJoinKHRFunction vkDeferredOperationJoinKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkDeferredOperationJoinKHR(VkDevice device, VkDeferredOperationKHR operation)
		=> vkDeferredOperationJoinKHR_ptr(device, operation);

	public typealias vkGetPipelineExecutablePropertiesKHRFunction = function VkResult(VkDevice device, VkPipelineInfoKHR* pPipelineInfo, uint32* pExecutableCount, VkPipelineExecutablePropertiesKHR* pProperties);
	private static vkGetPipelineExecutablePropertiesKHRFunction vkGetPipelineExecutablePropertiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPipelineExecutablePropertiesKHR(VkDevice device, VkPipelineInfoKHR* pPipelineInfo, uint32* pExecutableCount, VkPipelineExecutablePropertiesKHR* pProperties)
		=> vkGetPipelineExecutablePropertiesKHR_ptr(device, pPipelineInfo, pExecutableCount, pProperties);

	public typealias vkGetPipelineExecutableStatisticsKHRFunction = function VkResult(VkDevice device, VkPipelineExecutableInfoKHR* pExecutableInfo, uint32* pStatisticCount, VkPipelineExecutableStatisticKHR* pStatistics);
	private static vkGetPipelineExecutableStatisticsKHRFunction vkGetPipelineExecutableStatisticsKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPipelineExecutableStatisticsKHR(VkDevice device, VkPipelineExecutableInfoKHR* pExecutableInfo, uint32* pStatisticCount, VkPipelineExecutableStatisticKHR* pStatistics)
		=> vkGetPipelineExecutableStatisticsKHR_ptr(device, pExecutableInfo, pStatisticCount, pStatistics);

	public typealias vkGetPipelineExecutableInternalRepresentationsKHRFunction = function VkResult(VkDevice device, VkPipelineExecutableInfoKHR* pExecutableInfo, uint32* pInternalRepresentationCount, VkPipelineExecutableInternalRepresentationKHR* pInternalRepresentations);
	private static vkGetPipelineExecutableInternalRepresentationsKHRFunction vkGetPipelineExecutableInternalRepresentationsKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPipelineExecutableInternalRepresentationsKHR(VkDevice device, VkPipelineExecutableInfoKHR* pExecutableInfo, uint32* pInternalRepresentationCount, VkPipelineExecutableInternalRepresentationKHR* pInternalRepresentations)
		=> vkGetPipelineExecutableInternalRepresentationsKHR_ptr(device, pExecutableInfo, pInternalRepresentationCount, pInternalRepresentations);

	public typealias vkReleaseSwapchainImagesKHRFunction = function VkResult(VkDevice device, VkReleaseSwapchainImagesInfoKHR* pReleaseInfo);
	private static vkReleaseSwapchainImagesKHRFunction vkReleaseSwapchainImagesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkReleaseSwapchainImagesKHR(VkDevice device, VkReleaseSwapchainImagesInfoKHR* pReleaseInfo)
		=> vkReleaseSwapchainImagesKHR_ptr(device, pReleaseInfo);

	public typealias vkGetGeneratedCommandsMemoryRequirementsNVFunction = function void(VkDevice device, VkGeneratedCommandsMemoryRequirementsInfoNV* pInfo, VkMemoryRequirements2* pMemoryRequirements);
	private static vkGetGeneratedCommandsMemoryRequirementsNVFunction vkGetGeneratedCommandsMemoryRequirementsNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetGeneratedCommandsMemoryRequirementsNV(VkDevice device, VkGeneratedCommandsMemoryRequirementsInfoNV* pInfo, VkMemoryRequirements2* pMemoryRequirements)
		=> vkGetGeneratedCommandsMemoryRequirementsNV_ptr(device, pInfo, pMemoryRequirements);

	public typealias vkCmdPreprocessGeneratedCommandsNVFunction = function void(VkCommandBuffer commandBuffer, VkGeneratedCommandsInfoNV* pGeneratedCommandsInfo);
	private static vkCmdPreprocessGeneratedCommandsNVFunction vkCmdPreprocessGeneratedCommandsNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdPreprocessGeneratedCommandsNV(VkCommandBuffer commandBuffer, VkGeneratedCommandsInfoNV* pGeneratedCommandsInfo)
		=> vkCmdPreprocessGeneratedCommandsNV_ptr(commandBuffer, pGeneratedCommandsInfo);

	public typealias vkCmdExecuteGeneratedCommandsNVFunction = function void(VkCommandBuffer commandBuffer, VkBool32 isPreprocessed, VkGeneratedCommandsInfoNV* pGeneratedCommandsInfo);
	private static vkCmdExecuteGeneratedCommandsNVFunction vkCmdExecuteGeneratedCommandsNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdExecuteGeneratedCommandsNV(VkCommandBuffer commandBuffer, VkBool32 isPreprocessed, VkGeneratedCommandsInfoNV* pGeneratedCommandsInfo)
		=> vkCmdExecuteGeneratedCommandsNV_ptr(commandBuffer, isPreprocessed, pGeneratedCommandsInfo);

	public typealias vkCmdBindPipelineShaderGroupNVFunction = function void(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline, uint32 groupIndex);
	private static vkCmdBindPipelineShaderGroupNVFunction vkCmdBindPipelineShaderGroupNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindPipelineShaderGroupNV(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline, uint32 groupIndex)
		=> vkCmdBindPipelineShaderGroupNV_ptr(commandBuffer, pipelineBindPoint, pipeline, groupIndex);

	public typealias vkCreateIndirectCommandsLayoutNVFunction = function VkResult(VkDevice device, VkIndirectCommandsLayoutCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkIndirectCommandsLayoutNV* pIndirectCommandsLayout);
	private static vkCreateIndirectCommandsLayoutNVFunction vkCreateIndirectCommandsLayoutNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateIndirectCommandsLayoutNV(VkDevice device, VkIndirectCommandsLayoutCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkIndirectCommandsLayoutNV* pIndirectCommandsLayout)
		=> vkCreateIndirectCommandsLayoutNV_ptr(device, pCreateInfo, pAllocator, pIndirectCommandsLayout);

	public typealias vkDestroyIndirectCommandsLayoutNVFunction = function void(VkDevice device, VkIndirectCommandsLayoutNV indirectCommandsLayout, VkAllocationCallbacks* pAllocator);
	private static vkDestroyIndirectCommandsLayoutNVFunction vkDestroyIndirectCommandsLayoutNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyIndirectCommandsLayoutNV(VkDevice device, VkIndirectCommandsLayoutNV indirectCommandsLayout, VkAllocationCallbacks* pAllocator)
		=> vkDestroyIndirectCommandsLayoutNV_ptr(device, indirectCommandsLayout, pAllocator);

	public typealias vkCmdSetDepthBias2EXTFunction = function void(VkCommandBuffer commandBuffer, VkDepthBiasInfoEXT* pDepthBiasInfo);
	private static vkCmdSetDepthBias2EXTFunction vkCmdSetDepthBias2EXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDepthBias2EXT(VkCommandBuffer commandBuffer, VkDepthBiasInfoEXT* pDepthBiasInfo)
		=> vkCmdSetDepthBias2EXT_ptr(commandBuffer, pDepthBiasInfo);

	public typealias vkAcquireDrmDisplayEXTFunction = function VkResult(VkPhysicalDevice physicalDevice, int32 drmFd, VkDisplayKHR display);
	private static vkAcquireDrmDisplayEXTFunction vkAcquireDrmDisplayEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkAcquireDrmDisplayEXT(VkPhysicalDevice physicalDevice, int32 drmFd, VkDisplayKHR display)
		=> vkAcquireDrmDisplayEXT_ptr(physicalDevice, drmFd, display);

	public typealias vkGetDrmDisplayEXTFunction = function VkResult(VkPhysicalDevice physicalDevice, int32 drmFd, uint32 connectorId, VkDisplayKHR* display);
	private static vkGetDrmDisplayEXTFunction vkGetDrmDisplayEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDrmDisplayEXT(VkPhysicalDevice physicalDevice, int32 drmFd, uint32 connectorId, VkDisplayKHR* display)
		=> vkGetDrmDisplayEXT_ptr(physicalDevice, drmFd, connectorId, display);

	public typealias vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, VkPhysicalDeviceVideoEncodeQualityLevelInfoKHR* pQualityLevelInfo, VkVideoEncodeQualityLevelPropertiesKHR* pQualityLevelProperties);
	private static vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHRFunction vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR(VkPhysicalDevice physicalDevice, VkPhysicalDeviceVideoEncodeQualityLevelInfoKHR* pQualityLevelInfo, VkVideoEncodeQualityLevelPropertiesKHR* pQualityLevelProperties)
		=> vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR_ptr(physicalDevice, pQualityLevelInfo, pQualityLevelProperties);

	public typealias vkGetEncodedVideoSessionParametersKHRFunction = function VkResult(VkDevice device, VkVideoEncodeSessionParametersGetInfoKHR* pVideoSessionParametersInfo, VkVideoEncodeSessionParametersFeedbackInfoKHR* pFeedbackInfo, uint* pDataSize, void* pData);
	private static vkGetEncodedVideoSessionParametersKHRFunction vkGetEncodedVideoSessionParametersKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetEncodedVideoSessionParametersKHR(VkDevice device, VkVideoEncodeSessionParametersGetInfoKHR* pVideoSessionParametersInfo, VkVideoEncodeSessionParametersFeedbackInfoKHR* pFeedbackInfo, uint* pDataSize, void* pData)
		=> vkGetEncodedVideoSessionParametersKHR_ptr(device, pVideoSessionParametersInfo, pFeedbackInfo, pDataSize, pData);

	public typealias vkCmdEncodeVideoKHRFunction = function void(VkCommandBuffer commandBuffer, VkVideoEncodeInfoKHR* pEncodeInfo);
	private static vkCmdEncodeVideoKHRFunction vkCmdEncodeVideoKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdEncodeVideoKHR(VkCommandBuffer commandBuffer, VkVideoEncodeInfoKHR* pEncodeInfo)
		=> vkCmdEncodeVideoKHR_ptr(commandBuffer, pEncodeInfo);

	public typealias vkCreateCudaModuleNVFunction = function VkResult(VkDevice device, VkCudaModuleCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCudaModuleNV* pModule);
	private static vkCreateCudaModuleNVFunction vkCreateCudaModuleNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateCudaModuleNV(VkDevice device, VkCudaModuleCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCudaModuleNV* pModule)
		=> vkCreateCudaModuleNV_ptr(device, pCreateInfo, pAllocator, pModule);

	public typealias vkGetCudaModuleCacheNVFunction = function VkResult(VkDevice device, VkCudaModuleNV module, uint* pCacheSize, void* pCacheData);
	private static vkGetCudaModuleCacheNVFunction vkGetCudaModuleCacheNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetCudaModuleCacheNV(VkDevice device, VkCudaModuleNV module, uint* pCacheSize, void* pCacheData)
		=> vkGetCudaModuleCacheNV_ptr(device, module, pCacheSize, pCacheData);

	public typealias vkCreateCudaFunctionNVFunction = function VkResult(VkDevice device, VkCudaFunctionCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCudaFunctionNV* pFunction);
	private static vkCreateCudaFunctionNVFunction vkCreateCudaFunctionNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateCudaFunctionNV(VkDevice device, VkCudaFunctionCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkCudaFunctionNV* pFunction)
		=> vkCreateCudaFunctionNV_ptr(device, pCreateInfo, pAllocator, pFunction);

	public typealias vkDestroyCudaModuleNVFunction = function void(VkDevice device, VkCudaModuleNV module, VkAllocationCallbacks* pAllocator);
	private static vkDestroyCudaModuleNVFunction vkDestroyCudaModuleNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyCudaModuleNV(VkDevice device, VkCudaModuleNV module, VkAllocationCallbacks* pAllocator)
		=> vkDestroyCudaModuleNV_ptr(device, module, pAllocator);

	public typealias vkDestroyCudaFunctionNVFunction = function void(VkDevice device, VkCudaFunctionNV vkfunction, VkAllocationCallbacks* pAllocator);
	private static vkDestroyCudaFunctionNVFunction vkDestroyCudaFunctionNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyCudaFunctionNV(VkDevice device, VkCudaFunctionNV vkfunction, VkAllocationCallbacks* pAllocator)
		=> vkDestroyCudaFunctionNV_ptr(device, vkfunction, pAllocator);

	public typealias vkCmdCudaLaunchKernelNVFunction = function void(VkCommandBuffer commandBuffer, VkCudaLaunchInfoNV* pLaunchInfo);
	private static vkCmdCudaLaunchKernelNVFunction vkCmdCudaLaunchKernelNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCudaLaunchKernelNV(VkCommandBuffer commandBuffer, VkCudaLaunchInfoNV* pLaunchInfo)
		=> vkCmdCudaLaunchKernelNV_ptr(commandBuffer, pLaunchInfo);

	public typealias vkCmdRefreshObjectsKHRFunction = function void(VkCommandBuffer commandBuffer, VkRefreshObjectListKHR* pRefreshObjects);
	private static vkCmdRefreshObjectsKHRFunction vkCmdRefreshObjectsKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdRefreshObjectsKHR(VkCommandBuffer commandBuffer, VkRefreshObjectListKHR* pRefreshObjects)
		=> vkCmdRefreshObjectsKHR_ptr(commandBuffer, pRefreshObjects);

	public typealias vkGetPhysicalDeviceRefreshableObjectTypesKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pRefreshableObjectTypeCount, VkObjectType* pRefreshableObjectTypes);
	private static vkGetPhysicalDeviceRefreshableObjectTypesKHRFunction vkGetPhysicalDeviceRefreshableObjectTypesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceRefreshableObjectTypesKHR(VkPhysicalDevice physicalDevice, uint32* pRefreshableObjectTypeCount, VkObjectType* pRefreshableObjectTypes)
		=> vkGetPhysicalDeviceRefreshableObjectTypesKHR_ptr(physicalDevice, pRefreshableObjectTypeCount, pRefreshableObjectTypes);

	public typealias vkCmdDispatchTileQCOMFunction = function void(VkCommandBuffer commandBuffer, VkDispatchTileInfoQCOM* pDispatchTileInfo);
	private static vkCmdDispatchTileQCOMFunction vkCmdDispatchTileQCOM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDispatchTileQCOM(VkCommandBuffer commandBuffer, VkDispatchTileInfoQCOM* pDispatchTileInfo)
		=> vkCmdDispatchTileQCOM_ptr(commandBuffer, pDispatchTileInfo);

	public typealias vkCmdBeginPerTileExecutionQCOMFunction = function void(VkCommandBuffer commandBuffer, VkPerTileBeginInfoQCOM* pPerTileBeginInfo);
	private static vkCmdBeginPerTileExecutionQCOMFunction vkCmdBeginPerTileExecutionQCOM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBeginPerTileExecutionQCOM(VkCommandBuffer commandBuffer, VkPerTileBeginInfoQCOM* pPerTileBeginInfo)
		=> vkCmdBeginPerTileExecutionQCOM_ptr(commandBuffer, pPerTileBeginInfo);

	public typealias vkCmdEndPerTileExecutionQCOMFunction = function void(VkCommandBuffer commandBuffer, VkPerTileEndInfoQCOM* pPerTileEndInfo);
	private static vkCmdEndPerTileExecutionQCOMFunction vkCmdEndPerTileExecutionQCOM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdEndPerTileExecutionQCOM(VkCommandBuffer commandBuffer, VkPerTileEndInfoQCOM* pPerTileEndInfo)
		=> vkCmdEndPerTileExecutionQCOM_ptr(commandBuffer, pPerTileEndInfo);

	public typealias vkExportMetalObjectsEXTFunction = function void(VkDevice device, VkExportMetalObjectsInfoEXT* pMetalObjectsInfo);
	private static vkExportMetalObjectsEXTFunction vkExportMetalObjectsEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkExportMetalObjectsEXT(VkDevice device, VkExportMetalObjectsInfoEXT* pMetalObjectsInfo)
		=> vkExportMetalObjectsEXT_ptr(device, pMetalObjectsInfo);

	public typealias vkGetDescriptorSetLayoutSizeEXTFunction = function void(VkDevice device, VkDescriptorSetLayout layout, uint64* pLayoutSizeInBytes);
	private static vkGetDescriptorSetLayoutSizeEXTFunction vkGetDescriptorSetLayoutSizeEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDescriptorSetLayoutSizeEXT(VkDevice device, VkDescriptorSetLayout layout, uint64* pLayoutSizeInBytes)
		=> vkGetDescriptorSetLayoutSizeEXT_ptr(device, layout, pLayoutSizeInBytes);

	public typealias vkGetDescriptorSetLayoutBindingOffsetEXTFunction = function void(VkDevice device, VkDescriptorSetLayout layout, uint32 binding, uint64* pOffset);
	private static vkGetDescriptorSetLayoutBindingOffsetEXTFunction vkGetDescriptorSetLayoutBindingOffsetEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDescriptorSetLayoutBindingOffsetEXT(VkDevice device, VkDescriptorSetLayout layout, uint32 binding, uint64* pOffset)
		=> vkGetDescriptorSetLayoutBindingOffsetEXT_ptr(device, layout, binding, pOffset);

	public typealias vkGetDescriptorEXTFunction = function void(VkDevice device, VkDescriptorGetInfoEXT* pDescriptorInfo, uint dataSize, void* pDescriptor);
	private static vkGetDescriptorEXTFunction vkGetDescriptorEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDescriptorEXT(VkDevice device, VkDescriptorGetInfoEXT* pDescriptorInfo, uint dataSize, void* pDescriptor)
		=> vkGetDescriptorEXT_ptr(device, pDescriptorInfo, dataSize, pDescriptor);

	public typealias vkCmdBindDescriptorBuffersEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 bufferCount, VkDescriptorBufferBindingInfoEXT* pBindingInfos);
	private static vkCmdBindDescriptorBuffersEXTFunction vkCmdBindDescriptorBuffersEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindDescriptorBuffersEXT(VkCommandBuffer commandBuffer, uint32 bufferCount, VkDescriptorBufferBindingInfoEXT* pBindingInfos)
		=> vkCmdBindDescriptorBuffersEXT_ptr(commandBuffer, bufferCount, pBindingInfos);

	public typealias vkCmdSetDescriptorBufferOffsetsEXTFunction = function void(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32 firstSet, uint32 setCount, uint32* pBufferIndices, uint64* pOffsets);
	private static vkCmdSetDescriptorBufferOffsetsEXTFunction vkCmdSetDescriptorBufferOffsetsEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDescriptorBufferOffsetsEXT(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32 firstSet, uint32 setCount, uint32* pBufferIndices, uint64* pOffsets)
		=> vkCmdSetDescriptorBufferOffsetsEXT_ptr(commandBuffer, pipelineBindPoint, layout, firstSet, setCount, pBufferIndices, pOffsets);

	public typealias vkCmdBindDescriptorBufferEmbeddedSamplersEXTFunction = function void(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32 set);
	private static vkCmdBindDescriptorBufferEmbeddedSamplersEXTFunction vkCmdBindDescriptorBufferEmbeddedSamplersEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindDescriptorBufferEmbeddedSamplersEXT(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipelineLayout layout, uint32 set)
		=> vkCmdBindDescriptorBufferEmbeddedSamplersEXT_ptr(commandBuffer, pipelineBindPoint, layout, set);

	public typealias vkGetBufferOpaqueCaptureDescriptorDataEXTFunction = function VkResult(VkDevice device, VkBufferCaptureDescriptorDataInfoEXT* pInfo, void* pData);
	private static vkGetBufferOpaqueCaptureDescriptorDataEXTFunction vkGetBufferOpaqueCaptureDescriptorDataEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetBufferOpaqueCaptureDescriptorDataEXT(VkDevice device, VkBufferCaptureDescriptorDataInfoEXT* pInfo, void* pData)
		=> vkGetBufferOpaqueCaptureDescriptorDataEXT_ptr(device, pInfo, pData);

	public typealias vkGetImageOpaqueCaptureDescriptorDataEXTFunction = function VkResult(VkDevice device, VkImageCaptureDescriptorDataInfoEXT* pInfo, void* pData);
	private static vkGetImageOpaqueCaptureDescriptorDataEXTFunction vkGetImageOpaqueCaptureDescriptorDataEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetImageOpaqueCaptureDescriptorDataEXT(VkDevice device, VkImageCaptureDescriptorDataInfoEXT* pInfo, void* pData)
		=> vkGetImageOpaqueCaptureDescriptorDataEXT_ptr(device, pInfo, pData);

	public typealias vkGetImageViewOpaqueCaptureDescriptorDataEXTFunction = function VkResult(VkDevice device, VkImageViewCaptureDescriptorDataInfoEXT* pInfo, void* pData);
	private static vkGetImageViewOpaqueCaptureDescriptorDataEXTFunction vkGetImageViewOpaqueCaptureDescriptorDataEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetImageViewOpaqueCaptureDescriptorDataEXT(VkDevice device, VkImageViewCaptureDescriptorDataInfoEXT* pInfo, void* pData)
		=> vkGetImageViewOpaqueCaptureDescriptorDataEXT_ptr(device, pInfo, pData);

	public typealias vkGetSamplerOpaqueCaptureDescriptorDataEXTFunction = function VkResult(VkDevice device, VkSamplerCaptureDescriptorDataInfoEXT* pInfo, void* pData);
	private static vkGetSamplerOpaqueCaptureDescriptorDataEXTFunction vkGetSamplerOpaqueCaptureDescriptorDataEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetSamplerOpaqueCaptureDescriptorDataEXT(VkDevice device, VkSamplerCaptureDescriptorDataInfoEXT* pInfo, void* pData)
		=> vkGetSamplerOpaqueCaptureDescriptorDataEXT_ptr(device, pInfo, pData);

	public typealias vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXTFunction = function VkResult(VkDevice device, VkAccelerationStructureCaptureDescriptorDataInfoEXT* pInfo, void* pData);
	private static vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXTFunction vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT(VkDevice device, VkAccelerationStructureCaptureDescriptorDataInfoEXT* pInfo, void* pData)
		=> vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT_ptr(device, pInfo, pData);

	public typealias vkCmdSetFragmentShadingRateEnumNVFunction = function void(VkCommandBuffer commandBuffer, VkFragmentShadingRateNV shadingRate, VkFragmentShadingRateCombinerOpKHR[2] combinerOps);
	private static vkCmdSetFragmentShadingRateEnumNVFunction vkCmdSetFragmentShadingRateEnumNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetFragmentShadingRateEnumNV(VkCommandBuffer commandBuffer, VkFragmentShadingRateNV shadingRate, VkFragmentShadingRateCombinerOpKHR[2] combinerOps)
		=> vkCmdSetFragmentShadingRateEnumNV_ptr(commandBuffer, shadingRate, combinerOps);

	public typealias vkCmdDrawMeshTasksEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 groupCountX, uint32 groupCountY, uint32 groupCountZ);
	private static vkCmdDrawMeshTasksEXTFunction vkCmdDrawMeshTasksEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawMeshTasksEXT(VkCommandBuffer commandBuffer, uint32 groupCountX, uint32 groupCountY, uint32 groupCountZ)
		=> vkCmdDrawMeshTasksEXT_ptr(commandBuffer, groupCountX, groupCountY, groupCountZ);

	public typealias vkCmdDrawMeshTasksIndirectEXTFunction = function void(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride);
	private static vkCmdDrawMeshTasksIndirectEXTFunction vkCmdDrawMeshTasksIndirectEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawMeshTasksIndirectEXT(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
		=> vkCmdDrawMeshTasksIndirectEXT_ptr(commandBuffer, buffer, offset, drawCount, stride);

	public typealias vkCmdDrawMeshTasksIndirectCountEXTFunction = function void(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, VkBuffer countBuffer, uint64 countBufferOffset, uint32 maxDrawCount, uint32 stride);
	private static vkCmdDrawMeshTasksIndirectCountEXTFunction vkCmdDrawMeshTasksIndirectCountEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawMeshTasksIndirectCountEXT(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset, VkBuffer countBuffer, uint64 countBufferOffset, uint32 maxDrawCount, uint32 stride)
		=> vkCmdDrawMeshTasksIndirectCountEXT_ptr(commandBuffer, buffer, offset, countBuffer, countBufferOffset, maxDrawCount, stride);

	public typealias vkGetDeviceFaultInfoEXTFunction = function VkResult(VkDevice device, VkDeviceFaultCountsEXT* pFaultCounts, VkDeviceFaultInfoEXT* pFaultInfo);
	private static vkGetDeviceFaultInfoEXTFunction vkGetDeviceFaultInfoEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDeviceFaultInfoEXT(VkDevice device, VkDeviceFaultCountsEXT* pFaultCounts, VkDeviceFaultInfoEXT* pFaultInfo)
		=> vkGetDeviceFaultInfoEXT_ptr(device, pFaultCounts, pFaultInfo);

	public typealias vkAcquireWinrtDisplayNVFunction = function VkResult(VkPhysicalDevice physicalDevice, VkDisplayKHR display);
	private static vkAcquireWinrtDisplayNVFunction vkAcquireWinrtDisplayNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkAcquireWinrtDisplayNV(VkPhysicalDevice physicalDevice, VkDisplayKHR display)
		=> vkAcquireWinrtDisplayNV_ptr(physicalDevice, display);

	public typealias vkGetWinrtDisplayNVFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32 deviceRelativeId, VkDisplayKHR* pDisplay);
	private static vkGetWinrtDisplayNVFunction vkGetWinrtDisplayNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetWinrtDisplayNV(VkPhysicalDevice physicalDevice, uint32 deviceRelativeId, VkDisplayKHR* pDisplay)
		=> vkGetWinrtDisplayNV_ptr(physicalDevice, deviceRelativeId, pDisplay);

	public typealias vkCreateDirectFBSurfaceEXTFunction = function VkResult(VkInstance instance, VkDirectFBSurfaceCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateDirectFBSurfaceEXTFunction vkCreateDirectFBSurfaceEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateDirectFBSurfaceEXT(VkInstance instance, VkDirectFBSurfaceCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateDirectFBSurfaceEXT_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkGetPhysicalDeviceDirectFBPresentationSupportEXTFunction = function VkBool32(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, void* dfb);
	private static vkGetPhysicalDeviceDirectFBPresentationSupportEXTFunction vkGetPhysicalDeviceDirectFBPresentationSupportEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkBool32 vkGetPhysicalDeviceDirectFBPresentationSupportEXT(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, void* dfb)
		=> vkGetPhysicalDeviceDirectFBPresentationSupportEXT_ptr(physicalDevice, queueFamilyIndex, dfb);

	public typealias vkCmdSetVertexInputEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 vertexBindingDescriptionCount, VkVertexInputBindingDescription2EXT* pVertexBindingDescriptions, uint32 vertexAttributeDescriptionCount, VkVertexInputAttributeDescription2EXT* pVertexAttributeDescriptions);
	private static vkCmdSetVertexInputEXTFunction vkCmdSetVertexInputEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetVertexInputEXT(VkCommandBuffer commandBuffer, uint32 vertexBindingDescriptionCount, VkVertexInputBindingDescription2EXT* pVertexBindingDescriptions, uint32 vertexAttributeDescriptionCount, VkVertexInputAttributeDescription2EXT* pVertexAttributeDescriptions)
		=> vkCmdSetVertexInputEXT_ptr(commandBuffer, vertexBindingDescriptionCount, pVertexBindingDescriptions, vertexAttributeDescriptionCount, pVertexAttributeDescriptions);

	public typealias vkGetMemoryZirconHandleFUCHSIAFunction = function VkResult(VkDevice device, VkMemoryGetZirconHandleInfoFUCHSIA* pGetZirconHandleInfo, void* pZirconHandle);
	private static vkGetMemoryZirconHandleFUCHSIAFunction vkGetMemoryZirconHandleFUCHSIA_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemoryZirconHandleFUCHSIA(VkDevice device, VkMemoryGetZirconHandleInfoFUCHSIA* pGetZirconHandleInfo, void* pZirconHandle)
		=> vkGetMemoryZirconHandleFUCHSIA_ptr(device, pGetZirconHandleInfo, pZirconHandle);

	public typealias vkGetMemoryZirconHandlePropertiesFUCHSIAFunction = function VkResult(VkDevice device, VkExternalMemoryHandleTypeFlags handleType, void* zirconHandle, VkMemoryZirconHandlePropertiesFUCHSIA* pMemoryZirconHandleProperties);
	private static vkGetMemoryZirconHandlePropertiesFUCHSIAFunction vkGetMemoryZirconHandlePropertiesFUCHSIA_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemoryZirconHandlePropertiesFUCHSIA(VkDevice device, VkExternalMemoryHandleTypeFlags handleType, void* zirconHandle, VkMemoryZirconHandlePropertiesFUCHSIA* pMemoryZirconHandleProperties)
		=> vkGetMemoryZirconHandlePropertiesFUCHSIA_ptr(device, handleType, zirconHandle, pMemoryZirconHandleProperties);

	public typealias vkImportSemaphoreZirconHandleFUCHSIAFunction = function VkResult(VkDevice device, VkImportSemaphoreZirconHandleInfoFUCHSIA* pImportSemaphoreZirconHandleInfo);
	private static vkImportSemaphoreZirconHandleFUCHSIAFunction vkImportSemaphoreZirconHandleFUCHSIA_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkImportSemaphoreZirconHandleFUCHSIA(VkDevice device, VkImportSemaphoreZirconHandleInfoFUCHSIA* pImportSemaphoreZirconHandleInfo)
		=> vkImportSemaphoreZirconHandleFUCHSIA_ptr(device, pImportSemaphoreZirconHandleInfo);

	public typealias vkGetSemaphoreZirconHandleFUCHSIAFunction = function VkResult(VkDevice device, VkSemaphoreGetZirconHandleInfoFUCHSIA* pGetZirconHandleInfo, void* pZirconHandle);
	private static vkGetSemaphoreZirconHandleFUCHSIAFunction vkGetSemaphoreZirconHandleFUCHSIA_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetSemaphoreZirconHandleFUCHSIA(VkDevice device, VkSemaphoreGetZirconHandleInfoFUCHSIA* pGetZirconHandleInfo, void* pZirconHandle)
		=> vkGetSemaphoreZirconHandleFUCHSIA_ptr(device, pGetZirconHandleInfo, pZirconHandle);

	public typealias vkCreateBufferCollectionFUCHSIAFunction = function VkResult(VkDevice device, VkBufferCollectionCreateInfoFUCHSIA* pCreateInfo, VkAllocationCallbacks* pAllocator, VkBufferCollectionFUCHSIA* pCollection);
	private static vkCreateBufferCollectionFUCHSIAFunction vkCreateBufferCollectionFUCHSIA_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateBufferCollectionFUCHSIA(VkDevice device, VkBufferCollectionCreateInfoFUCHSIA* pCreateInfo, VkAllocationCallbacks* pAllocator, VkBufferCollectionFUCHSIA* pCollection)
		=> vkCreateBufferCollectionFUCHSIA_ptr(device, pCreateInfo, pAllocator, pCollection);

	public typealias vkSetBufferCollectionImageConstraintsFUCHSIAFunction = function VkResult(VkDevice device, VkBufferCollectionFUCHSIA collection, VkImageConstraintsInfoFUCHSIA* pImageConstraintsInfo);
	private static vkSetBufferCollectionImageConstraintsFUCHSIAFunction vkSetBufferCollectionImageConstraintsFUCHSIA_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkSetBufferCollectionImageConstraintsFUCHSIA(VkDevice device, VkBufferCollectionFUCHSIA collection, VkImageConstraintsInfoFUCHSIA* pImageConstraintsInfo)
		=> vkSetBufferCollectionImageConstraintsFUCHSIA_ptr(device, collection, pImageConstraintsInfo);

	public typealias vkSetBufferCollectionBufferConstraintsFUCHSIAFunction = function VkResult(VkDevice device, VkBufferCollectionFUCHSIA collection, VkBufferConstraintsInfoFUCHSIA* pBufferConstraintsInfo);
	private static vkSetBufferCollectionBufferConstraintsFUCHSIAFunction vkSetBufferCollectionBufferConstraintsFUCHSIA_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkSetBufferCollectionBufferConstraintsFUCHSIA(VkDevice device, VkBufferCollectionFUCHSIA collection, VkBufferConstraintsInfoFUCHSIA* pBufferConstraintsInfo)
		=> vkSetBufferCollectionBufferConstraintsFUCHSIA_ptr(device, collection, pBufferConstraintsInfo);

	public typealias vkDestroyBufferCollectionFUCHSIAFunction = function void(VkDevice device, VkBufferCollectionFUCHSIA collection, VkAllocationCallbacks* pAllocator);
	private static vkDestroyBufferCollectionFUCHSIAFunction vkDestroyBufferCollectionFUCHSIA_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyBufferCollectionFUCHSIA(VkDevice device, VkBufferCollectionFUCHSIA collection, VkAllocationCallbacks* pAllocator)
		=> vkDestroyBufferCollectionFUCHSIA_ptr(device, collection, pAllocator);

	public typealias vkGetBufferCollectionPropertiesFUCHSIAFunction = function VkResult(VkDevice device, VkBufferCollectionFUCHSIA collection, VkBufferCollectionPropertiesFUCHSIA* pProperties);
	private static vkGetBufferCollectionPropertiesFUCHSIAFunction vkGetBufferCollectionPropertiesFUCHSIA_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetBufferCollectionPropertiesFUCHSIA(VkDevice device, VkBufferCollectionFUCHSIA collection, VkBufferCollectionPropertiesFUCHSIA* pProperties)
		=> vkGetBufferCollectionPropertiesFUCHSIA_ptr(device, collection, pProperties);

	public typealias vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEIFunction = function VkResult(VkDevice device, VkRenderPass renderpass, VkExtent2D* pMaxWorkgroupSize);
	private static vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEIFunction vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI(VkDevice device, VkRenderPass renderpass, VkExtent2D* pMaxWorkgroupSize)
		=> vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI_ptr(device, renderpass, pMaxWorkgroupSize);

	public typealias vkCmdSubpassShadingHUAWEIFunction = function void(VkCommandBuffer commandBuffer);
	private static vkCmdSubpassShadingHUAWEIFunction vkCmdSubpassShadingHUAWEI_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSubpassShadingHUAWEI(VkCommandBuffer commandBuffer)
		=> vkCmdSubpassShadingHUAWEI_ptr(commandBuffer);

	public typealias vkCmdBindInvocationMaskHUAWEIFunction = function void(VkCommandBuffer commandBuffer, VkImageView imageView, VkImageLayout imageLayout);
	private static vkCmdBindInvocationMaskHUAWEIFunction vkCmdBindInvocationMaskHUAWEI_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindInvocationMaskHUAWEI(VkCommandBuffer commandBuffer, VkImageView imageView, VkImageLayout imageLayout)
		=> vkCmdBindInvocationMaskHUAWEI_ptr(commandBuffer, imageView, imageLayout);

	public typealias vkGetMemoryRemoteAddressNVFunction = function VkResult(VkDevice device, VkMemoryGetRemoteAddressInfoNV* pMemoryGetRemoteAddressInfo, void* pAddress);
	private static vkGetMemoryRemoteAddressNVFunction vkGetMemoryRemoteAddressNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemoryRemoteAddressNV(VkDevice device, VkMemoryGetRemoteAddressInfoNV* pMemoryGetRemoteAddressInfo, void* pAddress)
		=> vkGetMemoryRemoteAddressNV_ptr(device, pMemoryGetRemoteAddressInfo, pAddress);

	public typealias vkGetPipelinePropertiesEXTFunction = function VkResult(VkDevice device, VkPipelineInfoKHR* pPipelineInfo, VkBaseOutStructure* pPipelineProperties);
	private static vkGetPipelinePropertiesEXTFunction vkGetPipelinePropertiesEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPipelinePropertiesEXT(VkDevice device, VkPipelineInfoKHR* pPipelineInfo, VkBaseOutStructure* pPipelineProperties)
		=> vkGetPipelinePropertiesEXT_ptr(device, pPipelineInfo, pPipelineProperties);

	public typealias vkGetFenceSciSyncFenceNVFunction = function VkResult(VkDevice device, VkFenceGetSciSyncInfoNV* pGetSciSyncHandleInfo, void* pHandle);
	private static vkGetFenceSciSyncFenceNVFunction vkGetFenceSciSyncFenceNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetFenceSciSyncFenceNV(VkDevice device, VkFenceGetSciSyncInfoNV* pGetSciSyncHandleInfo, void* pHandle)
		=> vkGetFenceSciSyncFenceNV_ptr(device, pGetSciSyncHandleInfo, pHandle);

	public typealias vkGetFenceSciSyncObjNVFunction = function VkResult(VkDevice device, VkFenceGetSciSyncInfoNV* pGetSciSyncHandleInfo, void* pHandle);
	private static vkGetFenceSciSyncObjNVFunction vkGetFenceSciSyncObjNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetFenceSciSyncObjNV(VkDevice device, VkFenceGetSciSyncInfoNV* pGetSciSyncHandleInfo, void* pHandle)
		=> vkGetFenceSciSyncObjNV_ptr(device, pGetSciSyncHandleInfo, pHandle);

	public typealias vkImportFenceSciSyncFenceNVFunction = function VkResult(VkDevice device, VkImportFenceSciSyncInfoNV* pImportFenceSciSyncInfo);
	private static vkImportFenceSciSyncFenceNVFunction vkImportFenceSciSyncFenceNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkImportFenceSciSyncFenceNV(VkDevice device, VkImportFenceSciSyncInfoNV* pImportFenceSciSyncInfo)
		=> vkImportFenceSciSyncFenceNV_ptr(device, pImportFenceSciSyncInfo);

	public typealias vkImportFenceSciSyncObjNVFunction = function VkResult(VkDevice device, VkImportFenceSciSyncInfoNV* pImportFenceSciSyncInfo);
	private static vkImportFenceSciSyncObjNVFunction vkImportFenceSciSyncObjNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkImportFenceSciSyncObjNV(VkDevice device, VkImportFenceSciSyncInfoNV* pImportFenceSciSyncInfo)
		=> vkImportFenceSciSyncObjNV_ptr(device, pImportFenceSciSyncInfo);

	public typealias vkGetPhysicalDeviceSciSyncAttributesNVFunction = function VkResult(VkPhysicalDevice physicalDevice, VkSciSyncAttributesInfoNV* pSciSyncAttributesInfo, void* pAttributes);
	private static vkGetPhysicalDeviceSciSyncAttributesNVFunction vkGetPhysicalDeviceSciSyncAttributesNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceSciSyncAttributesNV(VkPhysicalDevice physicalDevice, VkSciSyncAttributesInfoNV* pSciSyncAttributesInfo, void* pAttributes)
		=> vkGetPhysicalDeviceSciSyncAttributesNV_ptr(physicalDevice, pSciSyncAttributesInfo, pAttributes);

	public typealias vkGetSemaphoreSciSyncObjNVFunction = function VkResult(VkDevice device, VkSemaphoreGetSciSyncInfoNV* pGetSciSyncInfo, void* pHandle);
	private static vkGetSemaphoreSciSyncObjNVFunction vkGetSemaphoreSciSyncObjNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetSemaphoreSciSyncObjNV(VkDevice device, VkSemaphoreGetSciSyncInfoNV* pGetSciSyncInfo, void* pHandle)
		=> vkGetSemaphoreSciSyncObjNV_ptr(device, pGetSciSyncInfo, pHandle);

	public typealias vkImportSemaphoreSciSyncObjNVFunction = function VkResult(VkDevice device, VkImportSemaphoreSciSyncInfoNV* pImportSemaphoreSciSyncInfo);
	private static vkImportSemaphoreSciSyncObjNVFunction vkImportSemaphoreSciSyncObjNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkImportSemaphoreSciSyncObjNV(VkDevice device, VkImportSemaphoreSciSyncInfoNV* pImportSemaphoreSciSyncInfo)
		=> vkImportSemaphoreSciSyncObjNV_ptr(device, pImportSemaphoreSciSyncInfo);

	public typealias vkGetMemorySciBufNVFunction = function VkResult(VkDevice device, VkMemoryGetSciBufInfoNV* pGetSciBufInfo, void* pHandle);
	private static vkGetMemorySciBufNVFunction vkGetMemorySciBufNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemorySciBufNV(VkDevice device, VkMemoryGetSciBufInfoNV* pGetSciBufInfo, void* pHandle)
		=> vkGetMemorySciBufNV_ptr(device, pGetSciBufInfo, pHandle);

	public typealias vkGetPhysicalDeviceExternalMemorySciBufPropertiesNVFunction = function VkResult(VkPhysicalDevice physicalDevice, VkExternalMemoryHandleTypeFlags handleType, void* handle, VkMemorySciBufPropertiesNV* pMemorySciBufProperties);
	private static vkGetPhysicalDeviceExternalMemorySciBufPropertiesNVFunction vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV(VkPhysicalDevice physicalDevice, VkExternalMemoryHandleTypeFlags handleType, void* handle, VkMemorySciBufPropertiesNV* pMemorySciBufProperties)
		=> vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV_ptr(physicalDevice, handleType, handle, pMemorySciBufProperties);

	public typealias vkGetPhysicalDeviceSciBufAttributesNVFunction = function VkResult(VkPhysicalDevice physicalDevice, void* pAttributes);
	private static vkGetPhysicalDeviceSciBufAttributesNVFunction vkGetPhysicalDeviceSciBufAttributesNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceSciBufAttributesNV(VkPhysicalDevice physicalDevice, void* pAttributes)
		=> vkGetPhysicalDeviceSciBufAttributesNV_ptr(physicalDevice, pAttributes);

	public typealias vkCmdSetPatchControlPointsEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 patchControlPoints);
	private static vkCmdSetPatchControlPointsEXTFunction vkCmdSetPatchControlPointsEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetPatchControlPointsEXT(VkCommandBuffer commandBuffer, uint32 patchControlPoints)
		=> vkCmdSetPatchControlPointsEXT_ptr(commandBuffer, patchControlPoints);

	public typealias vkCmdSetLogicOpEXTFunction = function void(VkCommandBuffer commandBuffer, VkLogicOp logicOp);
	private static vkCmdSetLogicOpEXTFunction vkCmdSetLogicOpEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetLogicOpEXT(VkCommandBuffer commandBuffer, VkLogicOp logicOp)
		=> vkCmdSetLogicOpEXT_ptr(commandBuffer, logicOp);

	public typealias vkCreateScreenSurfaceQNXFunction = function VkResult(VkInstance instance, VkScreenSurfaceCreateInfoQNX* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateScreenSurfaceQNXFunction vkCreateScreenSurfaceQNX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateScreenSurfaceQNX(VkInstance instance, VkScreenSurfaceCreateInfoQNX* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateScreenSurfaceQNX_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkGetPhysicalDeviceScreenPresentationSupportQNXFunction = function VkBool32(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, void* window);
	private static vkGetPhysicalDeviceScreenPresentationSupportQNXFunction vkGetPhysicalDeviceScreenPresentationSupportQNX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkBool32 vkGetPhysicalDeviceScreenPresentationSupportQNX(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, void* window)
		=> vkGetPhysicalDeviceScreenPresentationSupportQNX_ptr(physicalDevice, queueFamilyIndex, window);

	public typealias vkCmdSetColorWriteEnableEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 attachmentCount, VkBool32* pColorWriteEnables);
	private static vkCmdSetColorWriteEnableEXTFunction vkCmdSetColorWriteEnableEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetColorWriteEnableEXT(VkCommandBuffer commandBuffer, uint32 attachmentCount, VkBool32* pColorWriteEnables)
		=> vkCmdSetColorWriteEnableEXT_ptr(commandBuffer, attachmentCount, pColorWriteEnables);

	public typealias vkCmdTraceRaysIndirect2KHRFunction = function void(VkCommandBuffer commandBuffer, uint64 indirectDeviceAddress);
	private static vkCmdTraceRaysIndirect2KHRFunction vkCmdTraceRaysIndirect2KHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdTraceRaysIndirect2KHR(VkCommandBuffer commandBuffer, uint64 indirectDeviceAddress)
		=> vkCmdTraceRaysIndirect2KHR_ptr(commandBuffer, indirectDeviceAddress);

	public typealias vkCmdDrawMultiEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 drawCount, VkMultiDrawInfoEXT* pVertexInfo, uint32 instanceCount, uint32 firstInstance, uint32 stride);
	private static vkCmdDrawMultiEXTFunction vkCmdDrawMultiEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawMultiEXT(VkCommandBuffer commandBuffer, uint32 drawCount, VkMultiDrawInfoEXT* pVertexInfo, uint32 instanceCount, uint32 firstInstance, uint32 stride)
		=> vkCmdDrawMultiEXT_ptr(commandBuffer, drawCount, pVertexInfo, instanceCount, firstInstance, stride);

	public typealias vkCmdDrawMultiIndexedEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 drawCount, VkMultiDrawIndexedInfoEXT* pIndexInfo, uint32 instanceCount, uint32 firstInstance, uint32 stride, int32* pVertexOffset);
	private static vkCmdDrawMultiIndexedEXTFunction vkCmdDrawMultiIndexedEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawMultiIndexedEXT(VkCommandBuffer commandBuffer, uint32 drawCount, VkMultiDrawIndexedInfoEXT* pIndexInfo, uint32 instanceCount, uint32 firstInstance, uint32 stride, int32* pVertexOffset)
		=> vkCmdDrawMultiIndexedEXT_ptr(commandBuffer, drawCount, pIndexInfo, instanceCount, firstInstance, stride, pVertexOffset);

	public typealias vkCreateMicromapEXTFunction = function VkResult(VkDevice device, VkMicromapCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkMicromapEXT* pMicromap);
	private static vkCreateMicromapEXTFunction vkCreateMicromapEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateMicromapEXT(VkDevice device, VkMicromapCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkMicromapEXT* pMicromap)
		=> vkCreateMicromapEXT_ptr(device, pCreateInfo, pAllocator, pMicromap);

	public typealias vkDestroyMicromapEXTFunction = function void(VkDevice device, VkMicromapEXT micromap, VkAllocationCallbacks* pAllocator);
	private static vkDestroyMicromapEXTFunction vkDestroyMicromapEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyMicromapEXT(VkDevice device, VkMicromapEXT micromap, VkAllocationCallbacks* pAllocator)
		=> vkDestroyMicromapEXT_ptr(device, micromap, pAllocator);

	public typealias vkCmdBuildMicromapsEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 infoCount, VkMicromapBuildInfoEXT* pInfos);
	private static vkCmdBuildMicromapsEXTFunction vkCmdBuildMicromapsEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBuildMicromapsEXT(VkCommandBuffer commandBuffer, uint32 infoCount, VkMicromapBuildInfoEXT* pInfos)
		=> vkCmdBuildMicromapsEXT_ptr(commandBuffer, infoCount, pInfos);

	public typealias vkBuildMicromapsEXTFunction = function VkResult(VkDevice device, VkDeferredOperationKHR deferredOperation, uint32 infoCount, VkMicromapBuildInfoEXT* pInfos);
	private static vkBuildMicromapsEXTFunction vkBuildMicromapsEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkBuildMicromapsEXT(VkDevice device, VkDeferredOperationKHR deferredOperation, uint32 infoCount, VkMicromapBuildInfoEXT* pInfos)
		=> vkBuildMicromapsEXT_ptr(device, deferredOperation, infoCount, pInfos);

	public typealias vkCopyMicromapEXTFunction = function VkResult(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyMicromapInfoEXT* pInfo);
	private static vkCopyMicromapEXTFunction vkCopyMicromapEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCopyMicromapEXT(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyMicromapInfoEXT* pInfo)
		=> vkCopyMicromapEXT_ptr(device, deferredOperation, pInfo);

	public typealias vkCopyMicromapToMemoryEXTFunction = function VkResult(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyMicromapToMemoryInfoEXT* pInfo);
	private static vkCopyMicromapToMemoryEXTFunction vkCopyMicromapToMemoryEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCopyMicromapToMemoryEXT(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyMicromapToMemoryInfoEXT* pInfo)
		=> vkCopyMicromapToMemoryEXT_ptr(device, deferredOperation, pInfo);

	public typealias vkCopyMemoryToMicromapEXTFunction = function VkResult(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyMemoryToMicromapInfoEXT* pInfo);
	private static vkCopyMemoryToMicromapEXTFunction vkCopyMemoryToMicromapEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCopyMemoryToMicromapEXT(VkDevice device, VkDeferredOperationKHR deferredOperation, VkCopyMemoryToMicromapInfoEXT* pInfo)
		=> vkCopyMemoryToMicromapEXT_ptr(device, deferredOperation, pInfo);

	public typealias vkWriteMicromapsPropertiesEXTFunction = function VkResult(VkDevice device, uint32 micromapCount, VkMicromapEXT* pMicromaps, VkQueryType queryType, uint dataSize, void* pData, uint stride);
	private static vkWriteMicromapsPropertiesEXTFunction vkWriteMicromapsPropertiesEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkWriteMicromapsPropertiesEXT(VkDevice device, uint32 micromapCount, VkMicromapEXT* pMicromaps, VkQueryType queryType, uint dataSize, void* pData, uint stride)
		=> vkWriteMicromapsPropertiesEXT_ptr(device, micromapCount, pMicromaps, queryType, dataSize, pData, stride);

	public typealias vkCmdCopyMicromapEXTFunction = function void(VkCommandBuffer commandBuffer, VkCopyMicromapInfoEXT* pInfo);
	private static vkCmdCopyMicromapEXTFunction vkCmdCopyMicromapEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyMicromapEXT(VkCommandBuffer commandBuffer, VkCopyMicromapInfoEXT* pInfo)
		=> vkCmdCopyMicromapEXT_ptr(commandBuffer, pInfo);

	public typealias vkCmdCopyMicromapToMemoryEXTFunction = function void(VkCommandBuffer commandBuffer, VkCopyMicromapToMemoryInfoEXT* pInfo);
	private static vkCmdCopyMicromapToMemoryEXTFunction vkCmdCopyMicromapToMemoryEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyMicromapToMemoryEXT(VkCommandBuffer commandBuffer, VkCopyMicromapToMemoryInfoEXT* pInfo)
		=> vkCmdCopyMicromapToMemoryEXT_ptr(commandBuffer, pInfo);

	public typealias vkCmdCopyMemoryToMicromapEXTFunction = function void(VkCommandBuffer commandBuffer, VkCopyMemoryToMicromapInfoEXT* pInfo);
	private static vkCmdCopyMemoryToMicromapEXTFunction vkCmdCopyMemoryToMicromapEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyMemoryToMicromapEXT(VkCommandBuffer commandBuffer, VkCopyMemoryToMicromapInfoEXT* pInfo)
		=> vkCmdCopyMemoryToMicromapEXT_ptr(commandBuffer, pInfo);

	public typealias vkCmdWriteMicromapsPropertiesEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 micromapCount, VkMicromapEXT* pMicromaps, VkQueryType queryType, VkQueryPool queryPool, uint32 firstQuery);
	private static vkCmdWriteMicromapsPropertiesEXTFunction vkCmdWriteMicromapsPropertiesEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdWriteMicromapsPropertiesEXT(VkCommandBuffer commandBuffer, uint32 micromapCount, VkMicromapEXT* pMicromaps, VkQueryType queryType, VkQueryPool queryPool, uint32 firstQuery)
		=> vkCmdWriteMicromapsPropertiesEXT_ptr(commandBuffer, micromapCount, pMicromaps, queryType, queryPool, firstQuery);

	public typealias vkGetDeviceMicromapCompatibilityEXTFunction = function void(VkDevice device, VkMicromapVersionInfoEXT* pVersionInfo, VkAccelerationStructureCompatibilityKHR* pCompatibility);
	private static vkGetDeviceMicromapCompatibilityEXTFunction vkGetDeviceMicromapCompatibilityEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDeviceMicromapCompatibilityEXT(VkDevice device, VkMicromapVersionInfoEXT* pVersionInfo, VkAccelerationStructureCompatibilityKHR* pCompatibility)
		=> vkGetDeviceMicromapCompatibilityEXT_ptr(device, pVersionInfo, pCompatibility);

	public typealias vkGetMicromapBuildSizesEXTFunction = function void(VkDevice device, VkAccelerationStructureBuildTypeKHR buildType, VkMicromapBuildInfoEXT* pBuildInfo, VkMicromapBuildSizesInfoEXT* pSizeInfo);
	private static vkGetMicromapBuildSizesEXTFunction vkGetMicromapBuildSizesEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetMicromapBuildSizesEXT(VkDevice device, VkAccelerationStructureBuildTypeKHR buildType, VkMicromapBuildInfoEXT* pBuildInfo, VkMicromapBuildSizesInfoEXT* pSizeInfo)
		=> vkGetMicromapBuildSizesEXT_ptr(device, buildType, pBuildInfo, pSizeInfo);

	public typealias vkCmdDrawClusterHUAWEIFunction = function void(VkCommandBuffer commandBuffer, uint32 groupCountX, uint32 groupCountY, uint32 groupCountZ);
	private static vkCmdDrawClusterHUAWEIFunction vkCmdDrawClusterHUAWEI_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawClusterHUAWEI(VkCommandBuffer commandBuffer, uint32 groupCountX, uint32 groupCountY, uint32 groupCountZ)
		=> vkCmdDrawClusterHUAWEI_ptr(commandBuffer, groupCountX, groupCountY, groupCountZ);

	public typealias vkCmdDrawClusterIndirectHUAWEIFunction = function void(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset);
	private static vkCmdDrawClusterIndirectHUAWEIFunction vkCmdDrawClusterIndirectHUAWEI_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDrawClusterIndirectHUAWEI(VkCommandBuffer commandBuffer, VkBuffer buffer, uint64 offset)
		=> vkCmdDrawClusterIndirectHUAWEI_ptr(commandBuffer, buffer, offset);

	public typealias vkSetDeviceMemoryPriorityEXTFunction = function void(VkDevice device, VkDeviceMemory memory, float priority);
	private static vkSetDeviceMemoryPriorityEXTFunction vkSetDeviceMemoryPriorityEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkSetDeviceMemoryPriorityEXT(VkDevice device, VkDeviceMemory memory, float priority)
		=> vkSetDeviceMemoryPriorityEXT_ptr(device, memory, priority);

	public typealias vkGetDescriptorSetLayoutHostMappingInfoVALVEFunction = function void(VkDevice device, VkDescriptorSetBindingReferenceVALVE* pBindingReference, VkDescriptorSetLayoutHostMappingInfoVALVE* pHostMapping);
	private static vkGetDescriptorSetLayoutHostMappingInfoVALVEFunction vkGetDescriptorSetLayoutHostMappingInfoVALVE_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDescriptorSetLayoutHostMappingInfoVALVE(VkDevice device, VkDescriptorSetBindingReferenceVALVE* pBindingReference, VkDescriptorSetLayoutHostMappingInfoVALVE* pHostMapping)
		=> vkGetDescriptorSetLayoutHostMappingInfoVALVE_ptr(device, pBindingReference, pHostMapping);

	public typealias vkGetDescriptorSetHostMappingVALVEFunction = function void(VkDevice device, VkDescriptorSet descriptorSet, void** ppData);
	private static vkGetDescriptorSetHostMappingVALVEFunction vkGetDescriptorSetHostMappingVALVE_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDescriptorSetHostMappingVALVE(VkDevice device, VkDescriptorSet descriptorSet, void** ppData)
		=> vkGetDescriptorSetHostMappingVALVE_ptr(device, descriptorSet, ppData);

	public typealias vkCmdCopyMemoryIndirectNVFunction = function void(VkCommandBuffer commandBuffer, uint64 copyBufferAddress, uint32 copyCount, uint32 stride);
	private static vkCmdCopyMemoryIndirectNVFunction vkCmdCopyMemoryIndirectNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyMemoryIndirectNV(VkCommandBuffer commandBuffer, uint64 copyBufferAddress, uint32 copyCount, uint32 stride)
		=> vkCmdCopyMemoryIndirectNV_ptr(commandBuffer, copyBufferAddress, copyCount, stride);

	public typealias vkCmdCopyMemoryToImageIndirectNVFunction = function void(VkCommandBuffer commandBuffer, uint64 copyBufferAddress, uint32 copyCount, uint32 stride, VkImage dstImage, VkImageLayout dstImageLayout, VkImageSubresourceLayers* pImageSubresources);
	private static vkCmdCopyMemoryToImageIndirectNVFunction vkCmdCopyMemoryToImageIndirectNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyMemoryToImageIndirectNV(VkCommandBuffer commandBuffer, uint64 copyBufferAddress, uint32 copyCount, uint32 stride, VkImage dstImage, VkImageLayout dstImageLayout, VkImageSubresourceLayers* pImageSubresources)
		=> vkCmdCopyMemoryToImageIndirectNV_ptr(commandBuffer, copyBufferAddress, copyCount, stride, dstImage, dstImageLayout, pImageSubresources);

	public typealias vkCmdDecompressMemoryNVFunction = function void(VkCommandBuffer commandBuffer, uint32 decompressRegionCount, VkDecompressMemoryRegionNV* pDecompressMemoryRegions);
	private static vkCmdDecompressMemoryNVFunction vkCmdDecompressMemoryNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDecompressMemoryNV(VkCommandBuffer commandBuffer, uint32 decompressRegionCount, VkDecompressMemoryRegionNV* pDecompressMemoryRegions)
		=> vkCmdDecompressMemoryNV_ptr(commandBuffer, decompressRegionCount, pDecompressMemoryRegions);

	public typealias vkCmdDecompressMemoryIndirectCountNVFunction = function void(VkCommandBuffer commandBuffer, uint64 indirectCommandsAddress, uint64 indirectCommandsCountAddress, uint32 stride);
	private static vkCmdDecompressMemoryIndirectCountNVFunction vkCmdDecompressMemoryIndirectCountNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDecompressMemoryIndirectCountNV(VkCommandBuffer commandBuffer, uint64 indirectCommandsAddress, uint64 indirectCommandsCountAddress, uint32 stride)
		=> vkCmdDecompressMemoryIndirectCountNV_ptr(commandBuffer, indirectCommandsAddress, indirectCommandsCountAddress, stride);

	public typealias vkGetPipelineIndirectMemoryRequirementsNVFunction = function void(VkDevice device, VkComputePipelineCreateInfo* pCreateInfo, VkMemoryRequirements2* pMemoryRequirements);
	private static vkGetPipelineIndirectMemoryRequirementsNVFunction vkGetPipelineIndirectMemoryRequirementsNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPipelineIndirectMemoryRequirementsNV(VkDevice device, VkComputePipelineCreateInfo* pCreateInfo, VkMemoryRequirements2* pMemoryRequirements)
		=> vkGetPipelineIndirectMemoryRequirementsNV_ptr(device, pCreateInfo, pMemoryRequirements);

	public typealias vkCmdUpdatePipelineIndirectBufferNVFunction = function void(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline);
	private static vkCmdUpdatePipelineIndirectBufferNVFunction vkCmdUpdatePipelineIndirectBufferNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdUpdatePipelineIndirectBufferNV(VkCommandBuffer commandBuffer, VkPipelineBindPoint pipelineBindPoint, VkPipeline pipeline)
		=> vkCmdUpdatePipelineIndirectBufferNV_ptr(commandBuffer, pipelineBindPoint, pipeline);

	public typealias vkGetPipelineIndirectDeviceAddressNVFunction = function uint64(VkDevice device, VkPipelineIndirectDeviceAddressInfoNV* pInfo);
	private static vkGetPipelineIndirectDeviceAddressNVFunction vkGetPipelineIndirectDeviceAddressNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static uint64 vkGetPipelineIndirectDeviceAddressNV(VkDevice device, VkPipelineIndirectDeviceAddressInfoNV* pInfo)
		=> vkGetPipelineIndirectDeviceAddressNV_ptr(device, pInfo);

	public typealias vkGetNativeBufferPropertiesOHOSFunction = function VkResult(VkDevice device, void* buffer, VkNativeBufferPropertiesOHOS* pProperties);
	private static vkGetNativeBufferPropertiesOHOSFunction vkGetNativeBufferPropertiesOHOS_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetNativeBufferPropertiesOHOS(VkDevice device, void* buffer, VkNativeBufferPropertiesOHOS* pProperties)
		=> vkGetNativeBufferPropertiesOHOS_ptr(device, buffer, pProperties);

	public typealias vkGetMemoryNativeBufferOHOSFunction = function VkResult(VkDevice device, VkMemoryGetNativeBufferInfoOHOS* pInfo, void* pBuffer);
	private static vkGetMemoryNativeBufferOHOSFunction vkGetMemoryNativeBufferOHOS_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemoryNativeBufferOHOS(VkDevice device, VkMemoryGetNativeBufferInfoOHOS* pInfo, void* pBuffer)
		=> vkGetMemoryNativeBufferOHOS_ptr(device, pInfo, pBuffer);

	public typealias vkCmdSetDepthClampEnableEXTFunction = function void(VkCommandBuffer commandBuffer, VkBool32 depthClampEnable);
	private static vkCmdSetDepthClampEnableEXTFunction vkCmdSetDepthClampEnableEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDepthClampEnableEXT(VkCommandBuffer commandBuffer, VkBool32 depthClampEnable)
		=> vkCmdSetDepthClampEnableEXT_ptr(commandBuffer, depthClampEnable);

	public typealias vkCmdSetPolygonModeEXTFunction = function void(VkCommandBuffer commandBuffer, VkPolygonMode polygonMode);
	private static vkCmdSetPolygonModeEXTFunction vkCmdSetPolygonModeEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetPolygonModeEXT(VkCommandBuffer commandBuffer, VkPolygonMode polygonMode)
		=> vkCmdSetPolygonModeEXT_ptr(commandBuffer, polygonMode);

	public typealias vkCmdSetRasterizationSamplesEXTFunction = function void(VkCommandBuffer commandBuffer, VkSampleCountFlags rasterizationSamples);
	private static vkCmdSetRasterizationSamplesEXTFunction vkCmdSetRasterizationSamplesEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetRasterizationSamplesEXT(VkCommandBuffer commandBuffer, VkSampleCountFlags rasterizationSamples)
		=> vkCmdSetRasterizationSamplesEXT_ptr(commandBuffer, rasterizationSamples);

	public typealias vkCmdSetSampleMaskEXTFunction = function void(VkCommandBuffer commandBuffer, VkSampleCountFlags samples, uint32* pSampleMask);
	private static vkCmdSetSampleMaskEXTFunction vkCmdSetSampleMaskEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetSampleMaskEXT(VkCommandBuffer commandBuffer, VkSampleCountFlags samples, uint32* pSampleMask)
		=> vkCmdSetSampleMaskEXT_ptr(commandBuffer, samples, pSampleMask);

	public typealias vkCmdSetAlphaToCoverageEnableEXTFunction = function void(VkCommandBuffer commandBuffer, VkBool32 alphaToCoverageEnable);
	private static vkCmdSetAlphaToCoverageEnableEXTFunction vkCmdSetAlphaToCoverageEnableEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetAlphaToCoverageEnableEXT(VkCommandBuffer commandBuffer, VkBool32 alphaToCoverageEnable)
		=> vkCmdSetAlphaToCoverageEnableEXT_ptr(commandBuffer, alphaToCoverageEnable);

	public typealias vkCmdSetAlphaToOneEnableEXTFunction = function void(VkCommandBuffer commandBuffer, VkBool32 alphaToOneEnable);
	private static vkCmdSetAlphaToOneEnableEXTFunction vkCmdSetAlphaToOneEnableEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetAlphaToOneEnableEXT(VkCommandBuffer commandBuffer, VkBool32 alphaToOneEnable)
		=> vkCmdSetAlphaToOneEnableEXT_ptr(commandBuffer, alphaToOneEnable);

	public typealias vkCmdSetLogicOpEnableEXTFunction = function void(VkCommandBuffer commandBuffer, VkBool32 logicOpEnable);
	private static vkCmdSetLogicOpEnableEXTFunction vkCmdSetLogicOpEnableEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetLogicOpEnableEXT(VkCommandBuffer commandBuffer, VkBool32 logicOpEnable)
		=> vkCmdSetLogicOpEnableEXT_ptr(commandBuffer, logicOpEnable);

	public typealias vkCmdSetColorBlendEnableEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 firstAttachment, uint32 attachmentCount, VkBool32* pColorBlendEnables);
	private static vkCmdSetColorBlendEnableEXTFunction vkCmdSetColorBlendEnableEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetColorBlendEnableEXT(VkCommandBuffer commandBuffer, uint32 firstAttachment, uint32 attachmentCount, VkBool32* pColorBlendEnables)
		=> vkCmdSetColorBlendEnableEXT_ptr(commandBuffer, firstAttachment, attachmentCount, pColorBlendEnables);

	public typealias vkCmdSetColorBlendEquationEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 firstAttachment, uint32 attachmentCount, VkColorBlendEquationEXT* pColorBlendEquations);
	private static vkCmdSetColorBlendEquationEXTFunction vkCmdSetColorBlendEquationEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetColorBlendEquationEXT(VkCommandBuffer commandBuffer, uint32 firstAttachment, uint32 attachmentCount, VkColorBlendEquationEXT* pColorBlendEquations)
		=> vkCmdSetColorBlendEquationEXT_ptr(commandBuffer, firstAttachment, attachmentCount, pColorBlendEquations);

	public typealias vkCmdSetColorWriteMaskEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 firstAttachment, uint32 attachmentCount, VkColorComponentFlags* pColorWriteMasks);
	private static vkCmdSetColorWriteMaskEXTFunction vkCmdSetColorWriteMaskEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetColorWriteMaskEXT(VkCommandBuffer commandBuffer, uint32 firstAttachment, uint32 attachmentCount, VkColorComponentFlags* pColorWriteMasks)
		=> vkCmdSetColorWriteMaskEXT_ptr(commandBuffer, firstAttachment, attachmentCount, pColorWriteMasks);

	public typealias vkCmdSetTessellationDomainOriginEXTFunction = function void(VkCommandBuffer commandBuffer, VkTessellationDomainOrigin domainOrigin);
	private static vkCmdSetTessellationDomainOriginEXTFunction vkCmdSetTessellationDomainOriginEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetTessellationDomainOriginEXT(VkCommandBuffer commandBuffer, VkTessellationDomainOrigin domainOrigin)
		=> vkCmdSetTessellationDomainOriginEXT_ptr(commandBuffer, domainOrigin);

	public typealias vkCmdSetRasterizationStreamEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 rasterizationStream);
	private static vkCmdSetRasterizationStreamEXTFunction vkCmdSetRasterizationStreamEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetRasterizationStreamEXT(VkCommandBuffer commandBuffer, uint32 rasterizationStream)
		=> vkCmdSetRasterizationStreamEXT_ptr(commandBuffer, rasterizationStream);

	public typealias vkCmdSetConservativeRasterizationModeEXTFunction = function void(VkCommandBuffer commandBuffer, VkConservativeRasterizationModeEXT conservativeRasterizationMode);
	private static vkCmdSetConservativeRasterizationModeEXTFunction vkCmdSetConservativeRasterizationModeEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetConservativeRasterizationModeEXT(VkCommandBuffer commandBuffer, VkConservativeRasterizationModeEXT conservativeRasterizationMode)
		=> vkCmdSetConservativeRasterizationModeEXT_ptr(commandBuffer, conservativeRasterizationMode);

	public typealias vkCmdSetExtraPrimitiveOverestimationSizeEXTFunction = function void(VkCommandBuffer commandBuffer, float extraPrimitiveOverestimationSize);
	private static vkCmdSetExtraPrimitiveOverestimationSizeEXTFunction vkCmdSetExtraPrimitiveOverestimationSizeEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetExtraPrimitiveOverestimationSizeEXT(VkCommandBuffer commandBuffer, float extraPrimitiveOverestimationSize)
		=> vkCmdSetExtraPrimitiveOverestimationSizeEXT_ptr(commandBuffer, extraPrimitiveOverestimationSize);

	public typealias vkCmdSetDepthClipEnableEXTFunction = function void(VkCommandBuffer commandBuffer, VkBool32 depthClipEnable);
	private static vkCmdSetDepthClipEnableEXTFunction vkCmdSetDepthClipEnableEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDepthClipEnableEXT(VkCommandBuffer commandBuffer, VkBool32 depthClipEnable)
		=> vkCmdSetDepthClipEnableEXT_ptr(commandBuffer, depthClipEnable);

	public typealias vkCmdSetSampleLocationsEnableEXTFunction = function void(VkCommandBuffer commandBuffer, VkBool32 sampleLocationsEnable);
	private static vkCmdSetSampleLocationsEnableEXTFunction vkCmdSetSampleLocationsEnableEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetSampleLocationsEnableEXT(VkCommandBuffer commandBuffer, VkBool32 sampleLocationsEnable)
		=> vkCmdSetSampleLocationsEnableEXT_ptr(commandBuffer, sampleLocationsEnable);

	public typealias vkCmdSetColorBlendAdvancedEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 firstAttachment, uint32 attachmentCount, VkColorBlendAdvancedEXT* pColorBlendAdvanced);
	private static vkCmdSetColorBlendAdvancedEXTFunction vkCmdSetColorBlendAdvancedEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetColorBlendAdvancedEXT(VkCommandBuffer commandBuffer, uint32 firstAttachment, uint32 attachmentCount, VkColorBlendAdvancedEXT* pColorBlendAdvanced)
		=> vkCmdSetColorBlendAdvancedEXT_ptr(commandBuffer, firstAttachment, attachmentCount, pColorBlendAdvanced);

	public typealias vkCmdSetProvokingVertexModeEXTFunction = function void(VkCommandBuffer commandBuffer, VkProvokingVertexModeEXT provokingVertexMode);
	private static vkCmdSetProvokingVertexModeEXTFunction vkCmdSetProvokingVertexModeEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetProvokingVertexModeEXT(VkCommandBuffer commandBuffer, VkProvokingVertexModeEXT provokingVertexMode)
		=> vkCmdSetProvokingVertexModeEXT_ptr(commandBuffer, provokingVertexMode);

	public typealias vkCmdSetLineRasterizationModeEXTFunction = function void(VkCommandBuffer commandBuffer, VkLineRasterizationMode lineRasterizationMode);
	private static vkCmdSetLineRasterizationModeEXTFunction vkCmdSetLineRasterizationModeEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetLineRasterizationModeEXT(VkCommandBuffer commandBuffer, VkLineRasterizationMode lineRasterizationMode)
		=> vkCmdSetLineRasterizationModeEXT_ptr(commandBuffer, lineRasterizationMode);

	public typealias vkCmdSetLineStippleEnableEXTFunction = function void(VkCommandBuffer commandBuffer, VkBool32 stippledLineEnable);
	private static vkCmdSetLineStippleEnableEXTFunction vkCmdSetLineStippleEnableEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetLineStippleEnableEXT(VkCommandBuffer commandBuffer, VkBool32 stippledLineEnable)
		=> vkCmdSetLineStippleEnableEXT_ptr(commandBuffer, stippledLineEnable);

	public typealias vkCmdSetDepthClipNegativeOneToOneEXTFunction = function void(VkCommandBuffer commandBuffer, VkBool32 negativeOneToOne);
	private static vkCmdSetDepthClipNegativeOneToOneEXTFunction vkCmdSetDepthClipNegativeOneToOneEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDepthClipNegativeOneToOneEXT(VkCommandBuffer commandBuffer, VkBool32 negativeOneToOne)
		=> vkCmdSetDepthClipNegativeOneToOneEXT_ptr(commandBuffer, negativeOneToOne);

	public typealias vkCmdSetViewportWScalingEnableNVFunction = function void(VkCommandBuffer commandBuffer, VkBool32 viewportWScalingEnable);
	private static vkCmdSetViewportWScalingEnableNVFunction vkCmdSetViewportWScalingEnableNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetViewportWScalingEnableNV(VkCommandBuffer commandBuffer, VkBool32 viewportWScalingEnable)
		=> vkCmdSetViewportWScalingEnableNV_ptr(commandBuffer, viewportWScalingEnable);

	public typealias vkCmdSetViewportSwizzleNVFunction = function void(VkCommandBuffer commandBuffer, uint32 firstViewport, uint32 viewportCount, VkViewportSwizzleNV* pViewportSwizzles);
	private static vkCmdSetViewportSwizzleNVFunction vkCmdSetViewportSwizzleNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetViewportSwizzleNV(VkCommandBuffer commandBuffer, uint32 firstViewport, uint32 viewportCount, VkViewportSwizzleNV* pViewportSwizzles)
		=> vkCmdSetViewportSwizzleNV_ptr(commandBuffer, firstViewport, viewportCount, pViewportSwizzles);

	public typealias vkCmdSetCoverageToColorEnableNVFunction = function void(VkCommandBuffer commandBuffer, VkBool32 coverageToColorEnable);
	private static vkCmdSetCoverageToColorEnableNVFunction vkCmdSetCoverageToColorEnableNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetCoverageToColorEnableNV(VkCommandBuffer commandBuffer, VkBool32 coverageToColorEnable)
		=> vkCmdSetCoverageToColorEnableNV_ptr(commandBuffer, coverageToColorEnable);

	public typealias vkCmdSetCoverageToColorLocationNVFunction = function void(VkCommandBuffer commandBuffer, uint32 coverageToColorLocation);
	private static vkCmdSetCoverageToColorLocationNVFunction vkCmdSetCoverageToColorLocationNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetCoverageToColorLocationNV(VkCommandBuffer commandBuffer, uint32 coverageToColorLocation)
		=> vkCmdSetCoverageToColorLocationNV_ptr(commandBuffer, coverageToColorLocation);

	public typealias vkCmdSetCoverageModulationModeNVFunction = function void(VkCommandBuffer commandBuffer, VkCoverageModulationModeNV coverageModulationMode);
	private static vkCmdSetCoverageModulationModeNVFunction vkCmdSetCoverageModulationModeNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetCoverageModulationModeNV(VkCommandBuffer commandBuffer, VkCoverageModulationModeNV coverageModulationMode)
		=> vkCmdSetCoverageModulationModeNV_ptr(commandBuffer, coverageModulationMode);

	public typealias vkCmdSetCoverageModulationTableEnableNVFunction = function void(VkCommandBuffer commandBuffer, VkBool32 coverageModulationTableEnable);
	private static vkCmdSetCoverageModulationTableEnableNVFunction vkCmdSetCoverageModulationTableEnableNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetCoverageModulationTableEnableNV(VkCommandBuffer commandBuffer, VkBool32 coverageModulationTableEnable)
		=> vkCmdSetCoverageModulationTableEnableNV_ptr(commandBuffer, coverageModulationTableEnable);

	public typealias vkCmdSetCoverageModulationTableNVFunction = function void(VkCommandBuffer commandBuffer, uint32 coverageModulationTableCount, float* pCoverageModulationTable);
	private static vkCmdSetCoverageModulationTableNVFunction vkCmdSetCoverageModulationTableNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetCoverageModulationTableNV(VkCommandBuffer commandBuffer, uint32 coverageModulationTableCount, float* pCoverageModulationTable)
		=> vkCmdSetCoverageModulationTableNV_ptr(commandBuffer, coverageModulationTableCount, pCoverageModulationTable);

	public typealias vkCmdSetShadingRateImageEnableNVFunction = function void(VkCommandBuffer commandBuffer, VkBool32 shadingRateImageEnable);
	private static vkCmdSetShadingRateImageEnableNVFunction vkCmdSetShadingRateImageEnableNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetShadingRateImageEnableNV(VkCommandBuffer commandBuffer, VkBool32 shadingRateImageEnable)
		=> vkCmdSetShadingRateImageEnableNV_ptr(commandBuffer, shadingRateImageEnable);

	public typealias vkCmdSetRepresentativeFragmentTestEnableNVFunction = function void(VkCommandBuffer commandBuffer, VkBool32 representativeFragmentTestEnable);
	private static vkCmdSetRepresentativeFragmentTestEnableNVFunction vkCmdSetRepresentativeFragmentTestEnableNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetRepresentativeFragmentTestEnableNV(VkCommandBuffer commandBuffer, VkBool32 representativeFragmentTestEnable)
		=> vkCmdSetRepresentativeFragmentTestEnableNV_ptr(commandBuffer, representativeFragmentTestEnable);

	public typealias vkCmdSetCoverageReductionModeNVFunction = function void(VkCommandBuffer commandBuffer, VkCoverageReductionModeNV coverageReductionMode);
	private static vkCmdSetCoverageReductionModeNVFunction vkCmdSetCoverageReductionModeNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetCoverageReductionModeNV(VkCommandBuffer commandBuffer, VkCoverageReductionModeNV coverageReductionMode)
		=> vkCmdSetCoverageReductionModeNV_ptr(commandBuffer, coverageReductionMode);

	public typealias vkCreateTensorARMFunction = function VkResult(VkDevice device, VkTensorCreateInfoARM* pCreateInfo, VkAllocationCallbacks* pAllocator, VkTensorARM* pTensor);
	private static vkCreateTensorARMFunction vkCreateTensorARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateTensorARM(VkDevice device, VkTensorCreateInfoARM* pCreateInfo, VkAllocationCallbacks* pAllocator, VkTensorARM* pTensor)
		=> vkCreateTensorARM_ptr(device, pCreateInfo, pAllocator, pTensor);

	public typealias vkDestroyTensorARMFunction = function void(VkDevice device, VkTensorARM tensor, VkAllocationCallbacks* pAllocator);
	private static vkDestroyTensorARMFunction vkDestroyTensorARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyTensorARM(VkDevice device, VkTensorARM tensor, VkAllocationCallbacks* pAllocator)
		=> vkDestroyTensorARM_ptr(device, tensor, pAllocator);

	public typealias vkCreateTensorViewARMFunction = function VkResult(VkDevice device, VkTensorViewCreateInfoARM* pCreateInfo, VkAllocationCallbacks* pAllocator, VkTensorViewARM* pView);
	private static vkCreateTensorViewARMFunction vkCreateTensorViewARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateTensorViewARM(VkDevice device, VkTensorViewCreateInfoARM* pCreateInfo, VkAllocationCallbacks* pAllocator, VkTensorViewARM* pView)
		=> vkCreateTensorViewARM_ptr(device, pCreateInfo, pAllocator, pView);

	public typealias vkDestroyTensorViewARMFunction = function void(VkDevice device, VkTensorViewARM tensorView, VkAllocationCallbacks* pAllocator);
	private static vkDestroyTensorViewARMFunction vkDestroyTensorViewARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyTensorViewARM(VkDevice device, VkTensorViewARM tensorView, VkAllocationCallbacks* pAllocator)
		=> vkDestroyTensorViewARM_ptr(device, tensorView, pAllocator);

	public typealias vkGetTensorMemoryRequirementsARMFunction = function void(VkDevice device, VkTensorMemoryRequirementsInfoARM* pInfo, VkMemoryRequirements2* pMemoryRequirements);
	private static vkGetTensorMemoryRequirementsARMFunction vkGetTensorMemoryRequirementsARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetTensorMemoryRequirementsARM(VkDevice device, VkTensorMemoryRequirementsInfoARM* pInfo, VkMemoryRequirements2* pMemoryRequirements)
		=> vkGetTensorMemoryRequirementsARM_ptr(device, pInfo, pMemoryRequirements);

	public typealias vkBindTensorMemoryARMFunction = function VkResult(VkDevice device, uint32 bindInfoCount, VkBindTensorMemoryInfoARM* pBindInfos);
	private static vkBindTensorMemoryARMFunction vkBindTensorMemoryARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkBindTensorMemoryARM(VkDevice device, uint32 bindInfoCount, VkBindTensorMemoryInfoARM* pBindInfos)
		=> vkBindTensorMemoryARM_ptr(device, bindInfoCount, pBindInfos);

	public typealias vkGetDeviceTensorMemoryRequirementsARMFunction = function void(VkDevice device, VkDeviceTensorMemoryRequirementsARM* pInfo, VkMemoryRequirements2* pMemoryRequirements);
	private static vkGetDeviceTensorMemoryRequirementsARMFunction vkGetDeviceTensorMemoryRequirementsARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDeviceTensorMemoryRequirementsARM(VkDevice device, VkDeviceTensorMemoryRequirementsARM* pInfo, VkMemoryRequirements2* pMemoryRequirements)
		=> vkGetDeviceTensorMemoryRequirementsARM_ptr(device, pInfo, pMemoryRequirements);

	public typealias vkCmdCopyTensorARMFunction = function void(VkCommandBuffer commandBuffer, VkCopyTensorInfoARM* pCopyTensorInfo);
	private static vkCmdCopyTensorARMFunction vkCmdCopyTensorARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyTensorARM(VkCommandBuffer commandBuffer, VkCopyTensorInfoARM* pCopyTensorInfo)
		=> vkCmdCopyTensorARM_ptr(commandBuffer, pCopyTensorInfo);

	public typealias vkGetPhysicalDeviceExternalTensorPropertiesARMFunction = function void(VkPhysicalDevice physicalDevice, VkPhysicalDeviceExternalTensorInfoARM* pExternalTensorInfo, VkExternalTensorPropertiesARM* pExternalTensorProperties);
	private static vkGetPhysicalDeviceExternalTensorPropertiesARMFunction vkGetPhysicalDeviceExternalTensorPropertiesARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceExternalTensorPropertiesARM(VkPhysicalDevice physicalDevice, VkPhysicalDeviceExternalTensorInfoARM* pExternalTensorInfo, VkExternalTensorPropertiesARM* pExternalTensorProperties)
		=> vkGetPhysicalDeviceExternalTensorPropertiesARM_ptr(physicalDevice, pExternalTensorInfo, pExternalTensorProperties);

	public typealias vkGetTensorOpaqueCaptureDescriptorDataARMFunction = function VkResult(VkDevice device, VkTensorCaptureDescriptorDataInfoARM* pInfo, void* pData);
	private static vkGetTensorOpaqueCaptureDescriptorDataARMFunction vkGetTensorOpaqueCaptureDescriptorDataARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetTensorOpaqueCaptureDescriptorDataARM(VkDevice device, VkTensorCaptureDescriptorDataInfoARM* pInfo, void* pData)
		=> vkGetTensorOpaqueCaptureDescriptorDataARM_ptr(device, pInfo, pData);

	public typealias vkGetTensorViewOpaqueCaptureDescriptorDataARMFunction = function VkResult(VkDevice device, VkTensorViewCaptureDescriptorDataInfoARM* pInfo, void* pData);
	private static vkGetTensorViewOpaqueCaptureDescriptorDataARMFunction vkGetTensorViewOpaqueCaptureDescriptorDataARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetTensorViewOpaqueCaptureDescriptorDataARM(VkDevice device, VkTensorViewCaptureDescriptorDataInfoARM* pInfo, void* pData)
		=> vkGetTensorViewOpaqueCaptureDescriptorDataARM_ptr(device, pInfo, pData);

	public typealias vkGetShaderModuleIdentifierEXTFunction = function void(VkDevice device, VkShaderModule shaderModule, VkShaderModuleIdentifierEXT* pIdentifier);
	private static vkGetShaderModuleIdentifierEXTFunction vkGetShaderModuleIdentifierEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetShaderModuleIdentifierEXT(VkDevice device, VkShaderModule shaderModule, VkShaderModuleIdentifierEXT* pIdentifier)
		=> vkGetShaderModuleIdentifierEXT_ptr(device, shaderModule, pIdentifier);

	public typealias vkGetShaderModuleCreateInfoIdentifierEXTFunction = function void(VkDevice device, VkShaderModuleCreateInfo* pCreateInfo, VkShaderModuleIdentifierEXT* pIdentifier);
	private static vkGetShaderModuleCreateInfoIdentifierEXTFunction vkGetShaderModuleCreateInfoIdentifierEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetShaderModuleCreateInfoIdentifierEXT(VkDevice device, VkShaderModuleCreateInfo* pCreateInfo, VkShaderModuleIdentifierEXT* pIdentifier)
		=> vkGetShaderModuleCreateInfoIdentifierEXT_ptr(device, pCreateInfo, pIdentifier);

	public typealias vkGetPhysicalDeviceOpticalFlowImageFormatsNVFunction = function VkResult(VkPhysicalDevice physicalDevice, VkOpticalFlowImageFormatInfoNV* pOpticalFlowImageFormatInfo, uint32* pFormatCount, VkOpticalFlowImageFormatPropertiesNV* pImageFormatProperties);
	private static vkGetPhysicalDeviceOpticalFlowImageFormatsNVFunction vkGetPhysicalDeviceOpticalFlowImageFormatsNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceOpticalFlowImageFormatsNV(VkPhysicalDevice physicalDevice, VkOpticalFlowImageFormatInfoNV* pOpticalFlowImageFormatInfo, uint32* pFormatCount, VkOpticalFlowImageFormatPropertiesNV* pImageFormatProperties)
		=> vkGetPhysicalDeviceOpticalFlowImageFormatsNV_ptr(physicalDevice, pOpticalFlowImageFormatInfo, pFormatCount, pImageFormatProperties);

	public typealias vkCreateOpticalFlowSessionNVFunction = function VkResult(VkDevice device, VkOpticalFlowSessionCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkOpticalFlowSessionNV* pSession);
	private static vkCreateOpticalFlowSessionNVFunction vkCreateOpticalFlowSessionNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateOpticalFlowSessionNV(VkDevice device, VkOpticalFlowSessionCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkOpticalFlowSessionNV* pSession)
		=> vkCreateOpticalFlowSessionNV_ptr(device, pCreateInfo, pAllocator, pSession);

	public typealias vkDestroyOpticalFlowSessionNVFunction = function void(VkDevice device, VkOpticalFlowSessionNV session, VkAllocationCallbacks* pAllocator);
	private static vkDestroyOpticalFlowSessionNVFunction vkDestroyOpticalFlowSessionNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyOpticalFlowSessionNV(VkDevice device, VkOpticalFlowSessionNV session, VkAllocationCallbacks* pAllocator)
		=> vkDestroyOpticalFlowSessionNV_ptr(device, session, pAllocator);

	public typealias vkBindOpticalFlowSessionImageNVFunction = function VkResult(VkDevice device, VkOpticalFlowSessionNV session, VkOpticalFlowSessionBindingPointNV bindingPoint, VkImageView view, VkImageLayout layout);
	private static vkBindOpticalFlowSessionImageNVFunction vkBindOpticalFlowSessionImageNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkBindOpticalFlowSessionImageNV(VkDevice device, VkOpticalFlowSessionNV session, VkOpticalFlowSessionBindingPointNV bindingPoint, VkImageView view, VkImageLayout layout)
		=> vkBindOpticalFlowSessionImageNV_ptr(device, session, bindingPoint, view, layout);

	public typealias vkCmdOpticalFlowExecuteNVFunction = function void(VkCommandBuffer commandBuffer, VkOpticalFlowSessionNV session, VkOpticalFlowExecuteInfoNV* pExecuteInfo);
	private static vkCmdOpticalFlowExecuteNVFunction vkCmdOpticalFlowExecuteNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdOpticalFlowExecuteNV(VkCommandBuffer commandBuffer, VkOpticalFlowSessionNV session, VkOpticalFlowExecuteInfoNV* pExecuteInfo)
		=> vkCmdOpticalFlowExecuteNV_ptr(commandBuffer, session, pExecuteInfo);

	public typealias vkAntiLagUpdateAMDFunction = function void(VkDevice device, VkAntiLagDataAMD* pData);
	private static vkAntiLagUpdateAMDFunction vkAntiLagUpdateAMD_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkAntiLagUpdateAMD(VkDevice device, VkAntiLagDataAMD* pData)
		=> vkAntiLagUpdateAMD_ptr(device, pData);

	public typealias vkWaitForPresent2KHRFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain, VkPresentWait2InfoKHR* pPresentWait2Info);
	private static vkWaitForPresent2KHRFunction vkWaitForPresent2KHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkWaitForPresent2KHR(VkDevice device, VkSwapchainKHR swapchain, VkPresentWait2InfoKHR* pPresentWait2Info)
		=> vkWaitForPresent2KHR_ptr(device, swapchain, pPresentWait2Info);

	public typealias vkCreateShadersEXTFunction = function VkResult(VkDevice device, uint32 createInfoCount, VkShaderCreateInfoEXT* pCreateInfos, VkAllocationCallbacks* pAllocator, VkShaderEXT* pShaders);
	private static vkCreateShadersEXTFunction vkCreateShadersEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateShadersEXT(VkDevice device, uint32 createInfoCount, VkShaderCreateInfoEXT* pCreateInfos, VkAllocationCallbacks* pAllocator, VkShaderEXT* pShaders)
		=> vkCreateShadersEXT_ptr(device, createInfoCount, pCreateInfos, pAllocator, pShaders);

	public typealias vkDestroyShaderEXTFunction = function void(VkDevice device, VkShaderEXT shader, VkAllocationCallbacks* pAllocator);
	private static vkDestroyShaderEXTFunction vkDestroyShaderEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyShaderEXT(VkDevice device, VkShaderEXT shader, VkAllocationCallbacks* pAllocator)
		=> vkDestroyShaderEXT_ptr(device, shader, pAllocator);

	public typealias vkGetShaderBinaryDataEXTFunction = function VkResult(VkDevice device, VkShaderEXT shader, uint* pDataSize, void* pData);
	private static vkGetShaderBinaryDataEXTFunction vkGetShaderBinaryDataEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetShaderBinaryDataEXT(VkDevice device, VkShaderEXT shader, uint* pDataSize, void* pData)
		=> vkGetShaderBinaryDataEXT_ptr(device, shader, pDataSize, pData);

	public typealias vkCmdBindShadersEXTFunction = function void(VkCommandBuffer commandBuffer, uint32 stageCount, VkShaderStageFlags* pStages, VkShaderEXT* pShaders);
	private static vkCmdBindShadersEXTFunction vkCmdBindShadersEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindShadersEXT(VkCommandBuffer commandBuffer, uint32 stageCount, VkShaderStageFlags* pStages, VkShaderEXT* pShaders)
		=> vkCmdBindShadersEXT_ptr(commandBuffer, stageCount, pStages, pShaders);

	public typealias vkCmdSetDepthClampRangeEXTFunction = function void(VkCommandBuffer commandBuffer, VkDepthClampModeEXT depthClampMode, VkDepthClampRangeEXT* pDepthClampRange);
	private static vkCmdSetDepthClampRangeEXTFunction vkCmdSetDepthClampRangeEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDepthClampRangeEXT(VkCommandBuffer commandBuffer, VkDepthClampModeEXT depthClampMode, VkDepthClampRangeEXT* pDepthClampRange)
		=> vkCmdSetDepthClampRangeEXT_ptr(commandBuffer, depthClampMode, pDepthClampRange);

	public typealias vkCreatePipelineBinariesKHRFunction = function VkResult(VkDevice device, VkPipelineBinaryCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkPipelineBinaryHandlesInfoKHR* pBinaries);
	private static vkCreatePipelineBinariesKHRFunction vkCreatePipelineBinariesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreatePipelineBinariesKHR(VkDevice device, VkPipelineBinaryCreateInfoKHR* pCreateInfo, VkAllocationCallbacks* pAllocator, VkPipelineBinaryHandlesInfoKHR* pBinaries)
		=> vkCreatePipelineBinariesKHR_ptr(device, pCreateInfo, pAllocator, pBinaries);

	public typealias vkDestroyPipelineBinaryKHRFunction = function void(VkDevice device, VkPipelineBinaryKHR pipelineBinary, VkAllocationCallbacks* pAllocator);
	private static vkDestroyPipelineBinaryKHRFunction vkDestroyPipelineBinaryKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyPipelineBinaryKHR(VkDevice device, VkPipelineBinaryKHR pipelineBinary, VkAllocationCallbacks* pAllocator)
		=> vkDestroyPipelineBinaryKHR_ptr(device, pipelineBinary, pAllocator);

	public typealias vkGetPipelineKeyKHRFunction = function VkResult(VkDevice device, VkPipelineCreateInfoKHR* pPipelineCreateInfo, VkPipelineBinaryKeyKHR* pPipelineKey);
	private static vkGetPipelineKeyKHRFunction vkGetPipelineKeyKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPipelineKeyKHR(VkDevice device, VkPipelineCreateInfoKHR* pPipelineCreateInfo, VkPipelineBinaryKeyKHR* pPipelineKey)
		=> vkGetPipelineKeyKHR_ptr(device, pPipelineCreateInfo, pPipelineKey);

	public typealias vkGetPipelineBinaryDataKHRFunction = function VkResult(VkDevice device, VkPipelineBinaryDataInfoKHR* pInfo, VkPipelineBinaryKeyKHR* pPipelineBinaryKey, uint* pPipelineBinaryDataSize, void* pPipelineBinaryData);
	private static vkGetPipelineBinaryDataKHRFunction vkGetPipelineBinaryDataKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPipelineBinaryDataKHR(VkDevice device, VkPipelineBinaryDataInfoKHR* pInfo, VkPipelineBinaryKeyKHR* pPipelineBinaryKey, uint* pPipelineBinaryDataSize, void* pPipelineBinaryData)
		=> vkGetPipelineBinaryDataKHR_ptr(device, pInfo, pPipelineBinaryKey, pPipelineBinaryDataSize, pPipelineBinaryData);

	public typealias vkReleaseCapturedPipelineDataKHRFunction = function VkResult(VkDevice device, VkReleaseCapturedPipelineDataInfoKHR* pInfo, VkAllocationCallbacks* pAllocator);
	private static vkReleaseCapturedPipelineDataKHRFunction vkReleaseCapturedPipelineDataKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkReleaseCapturedPipelineDataKHR(VkDevice device, VkReleaseCapturedPipelineDataInfoKHR* pInfo, VkAllocationCallbacks* pAllocator)
		=> vkReleaseCapturedPipelineDataKHR_ptr(device, pInfo, pAllocator);

	public typealias vkGetFramebufferTilePropertiesQCOMFunction = function VkResult(VkDevice device, VkFramebuffer framebuffer, uint32* pPropertiesCount, VkTilePropertiesQCOM* pProperties);
	private static vkGetFramebufferTilePropertiesQCOMFunction vkGetFramebufferTilePropertiesQCOM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetFramebufferTilePropertiesQCOM(VkDevice device, VkFramebuffer framebuffer, uint32* pPropertiesCount, VkTilePropertiesQCOM* pProperties)
		=> vkGetFramebufferTilePropertiesQCOM_ptr(device, framebuffer, pPropertiesCount, pProperties);

	public typealias vkGetDynamicRenderingTilePropertiesQCOMFunction = function VkResult(VkDevice device, VkRenderingInfo* pRenderingInfo, VkTilePropertiesQCOM* pProperties);
	private static vkGetDynamicRenderingTilePropertiesQCOMFunction vkGetDynamicRenderingTilePropertiesQCOM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDynamicRenderingTilePropertiesQCOM(VkDevice device, VkRenderingInfo* pRenderingInfo, VkTilePropertiesQCOM* pProperties)
		=> vkGetDynamicRenderingTilePropertiesQCOM_ptr(device, pRenderingInfo, pProperties);

	public typealias vkCreateSemaphoreSciSyncPoolNVFunction = function VkResult(VkDevice device, VkSemaphoreSciSyncPoolCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSemaphoreSciSyncPoolNV* pSemaphorePool);
	private static vkCreateSemaphoreSciSyncPoolNVFunction vkCreateSemaphoreSciSyncPoolNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateSemaphoreSciSyncPoolNV(VkDevice device, VkSemaphoreSciSyncPoolCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSemaphoreSciSyncPoolNV* pSemaphorePool)
		=> vkCreateSemaphoreSciSyncPoolNV_ptr(device, pCreateInfo, pAllocator, pSemaphorePool);

	public typealias vkDestroySemaphoreSciSyncPoolNVFunction = function void(VkDevice device, VkSemaphoreSciSyncPoolNV semaphorePool, VkAllocationCallbacks* pAllocator);
	private static vkDestroySemaphoreSciSyncPoolNVFunction vkDestroySemaphoreSciSyncPoolNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroySemaphoreSciSyncPoolNV(VkDevice device, VkSemaphoreSciSyncPoolNV semaphorePool, VkAllocationCallbacks* pAllocator)
		=> vkDestroySemaphoreSciSyncPoolNV_ptr(device, semaphorePool, pAllocator);

	public typealias vkGetPhysicalDeviceCooperativeVectorPropertiesNVFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkCooperativeVectorPropertiesNV* pProperties);
	private static vkGetPhysicalDeviceCooperativeVectorPropertiesNVFunction vkGetPhysicalDeviceCooperativeVectorPropertiesNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceCooperativeVectorPropertiesNV(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkCooperativeVectorPropertiesNV* pProperties)
		=> vkGetPhysicalDeviceCooperativeVectorPropertiesNV_ptr(physicalDevice, pPropertyCount, pProperties);

	public typealias vkConvertCooperativeVectorMatrixNVFunction = function VkResult(VkDevice device, VkConvertCooperativeVectorMatrixInfoNV* pInfo);
	private static vkConvertCooperativeVectorMatrixNVFunction vkConvertCooperativeVectorMatrixNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkConvertCooperativeVectorMatrixNV(VkDevice device, VkConvertCooperativeVectorMatrixInfoNV* pInfo)
		=> vkConvertCooperativeVectorMatrixNV_ptr(device, pInfo);

	public typealias vkCmdConvertCooperativeVectorMatrixNVFunction = function void(VkCommandBuffer commandBuffer, uint32 infoCount, VkConvertCooperativeVectorMatrixInfoNV* pInfos);
	private static vkCmdConvertCooperativeVectorMatrixNVFunction vkCmdConvertCooperativeVectorMatrixNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdConvertCooperativeVectorMatrixNV(VkCommandBuffer commandBuffer, uint32 infoCount, VkConvertCooperativeVectorMatrixInfoNV* pInfos)
		=> vkCmdConvertCooperativeVectorMatrixNV_ptr(commandBuffer, infoCount, pInfos);

	public typealias vkSetLatencySleepModeNVFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain, VkLatencySleepModeInfoNV* pSleepModeInfo);
	private static vkSetLatencySleepModeNVFunction vkSetLatencySleepModeNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkSetLatencySleepModeNV(VkDevice device, VkSwapchainKHR swapchain, VkLatencySleepModeInfoNV* pSleepModeInfo)
		=> vkSetLatencySleepModeNV_ptr(device, swapchain, pSleepModeInfo);

	public typealias vkLatencySleepNVFunction = function VkResult(VkDevice device, VkSwapchainKHR swapchain, VkLatencySleepInfoNV* pSleepInfo);
	private static vkLatencySleepNVFunction vkLatencySleepNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkLatencySleepNV(VkDevice device, VkSwapchainKHR swapchain, VkLatencySleepInfoNV* pSleepInfo)
		=> vkLatencySleepNV_ptr(device, swapchain, pSleepInfo);

	public typealias vkSetLatencyMarkerNVFunction = function void(VkDevice device, VkSwapchainKHR swapchain, VkSetLatencyMarkerInfoNV* pLatencyMarkerInfo);
	private static vkSetLatencyMarkerNVFunction vkSetLatencyMarkerNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkSetLatencyMarkerNV(VkDevice device, VkSwapchainKHR swapchain, VkSetLatencyMarkerInfoNV* pLatencyMarkerInfo)
		=> vkSetLatencyMarkerNV_ptr(device, swapchain, pLatencyMarkerInfo);

	public typealias vkGetLatencyTimingsNVFunction = function void(VkDevice device, VkSwapchainKHR swapchain, VkGetLatencyMarkerInfoNV* pLatencyMarkerInfo);
	private static vkGetLatencyTimingsNVFunction vkGetLatencyTimingsNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetLatencyTimingsNV(VkDevice device, VkSwapchainKHR swapchain, VkGetLatencyMarkerInfoNV* pLatencyMarkerInfo)
		=> vkGetLatencyTimingsNV_ptr(device, swapchain, pLatencyMarkerInfo);

	public typealias vkQueueNotifyOutOfBandNVFunction = function void(VkQueue queue, VkOutOfBandQueueTypeInfoNV* pQueueTypeInfo);
	private static vkQueueNotifyOutOfBandNVFunction vkQueueNotifyOutOfBandNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkQueueNotifyOutOfBandNV(VkQueue queue, VkOutOfBandQueueTypeInfoNV* pQueueTypeInfo)
		=> vkQueueNotifyOutOfBandNV_ptr(queue, pQueueTypeInfo);

	public typealias vkGetPhysicalDeviceCooperativeMatrixPropertiesKHRFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkCooperativeMatrixPropertiesKHR* pProperties);
	private static vkGetPhysicalDeviceCooperativeMatrixPropertiesKHRFunction vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkCooperativeMatrixPropertiesKHR* pProperties)
		=> vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR_ptr(physicalDevice, pPropertyCount, pProperties);

	public typealias vkCreateDataGraphPipelinesARMFunction = function VkResult(VkDevice device, VkDeferredOperationKHR deferredOperation, VkPipelineCache pipelineCache, uint32 createInfoCount, VkDataGraphPipelineCreateInfoARM* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines);
	private static vkCreateDataGraphPipelinesARMFunction vkCreateDataGraphPipelinesARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateDataGraphPipelinesARM(VkDevice device, VkDeferredOperationKHR deferredOperation, VkPipelineCache pipelineCache, uint32 createInfoCount, VkDataGraphPipelineCreateInfoARM* pCreateInfos, VkAllocationCallbacks* pAllocator, VkPipeline* pPipelines)
		=> vkCreateDataGraphPipelinesARM_ptr(device, deferredOperation, pipelineCache, createInfoCount, pCreateInfos, pAllocator, pPipelines);

	public typealias vkCreateDataGraphPipelineSessionARMFunction = function VkResult(VkDevice device, VkDataGraphPipelineSessionCreateInfoARM* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDataGraphPipelineSessionARM* pSession);
	private static vkCreateDataGraphPipelineSessionARMFunction vkCreateDataGraphPipelineSessionARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateDataGraphPipelineSessionARM(VkDevice device, VkDataGraphPipelineSessionCreateInfoARM* pCreateInfo, VkAllocationCallbacks* pAllocator, VkDataGraphPipelineSessionARM* pSession)
		=> vkCreateDataGraphPipelineSessionARM_ptr(device, pCreateInfo, pAllocator, pSession);

	public typealias vkGetDataGraphPipelineSessionBindPointRequirementsARMFunction = function VkResult(VkDevice device, VkDataGraphPipelineSessionBindPointRequirementsInfoARM* pInfo, uint32* pBindPointRequirementCount, VkDataGraphPipelineSessionBindPointRequirementARM* pBindPointRequirements);
	private static vkGetDataGraphPipelineSessionBindPointRequirementsARMFunction vkGetDataGraphPipelineSessionBindPointRequirementsARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDataGraphPipelineSessionBindPointRequirementsARM(VkDevice device, VkDataGraphPipelineSessionBindPointRequirementsInfoARM* pInfo, uint32* pBindPointRequirementCount, VkDataGraphPipelineSessionBindPointRequirementARM* pBindPointRequirements)
		=> vkGetDataGraphPipelineSessionBindPointRequirementsARM_ptr(device, pInfo, pBindPointRequirementCount, pBindPointRequirements);

	public typealias vkGetDataGraphPipelineSessionMemoryRequirementsARMFunction = function void(VkDevice device, VkDataGraphPipelineSessionMemoryRequirementsInfoARM* pInfo, VkMemoryRequirements2* pMemoryRequirements);
	private static vkGetDataGraphPipelineSessionMemoryRequirementsARMFunction vkGetDataGraphPipelineSessionMemoryRequirementsARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetDataGraphPipelineSessionMemoryRequirementsARM(VkDevice device, VkDataGraphPipelineSessionMemoryRequirementsInfoARM* pInfo, VkMemoryRequirements2* pMemoryRequirements)
		=> vkGetDataGraphPipelineSessionMemoryRequirementsARM_ptr(device, pInfo, pMemoryRequirements);

	public typealias vkBindDataGraphPipelineSessionMemoryARMFunction = function VkResult(VkDevice device, uint32 bindInfoCount, VkBindDataGraphPipelineSessionMemoryInfoARM* pBindInfos);
	private static vkBindDataGraphPipelineSessionMemoryARMFunction vkBindDataGraphPipelineSessionMemoryARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkBindDataGraphPipelineSessionMemoryARM(VkDevice device, uint32 bindInfoCount, VkBindDataGraphPipelineSessionMemoryInfoARM* pBindInfos)
		=> vkBindDataGraphPipelineSessionMemoryARM_ptr(device, bindInfoCount, pBindInfos);

	public typealias vkDestroyDataGraphPipelineSessionARMFunction = function void(VkDevice device, VkDataGraphPipelineSessionARM session, VkAllocationCallbacks* pAllocator);
	private static vkDestroyDataGraphPipelineSessionARMFunction vkDestroyDataGraphPipelineSessionARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyDataGraphPipelineSessionARM(VkDevice device, VkDataGraphPipelineSessionARM session, VkAllocationCallbacks* pAllocator)
		=> vkDestroyDataGraphPipelineSessionARM_ptr(device, session, pAllocator);

	public typealias vkCmdDispatchDataGraphARMFunction = function void(VkCommandBuffer commandBuffer, VkDataGraphPipelineSessionARM session, VkDataGraphPipelineDispatchInfoARM* pInfo);
	private static vkCmdDispatchDataGraphARMFunction vkCmdDispatchDataGraphARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDispatchDataGraphARM(VkCommandBuffer commandBuffer, VkDataGraphPipelineSessionARM session, VkDataGraphPipelineDispatchInfoARM* pInfo)
		=> vkCmdDispatchDataGraphARM_ptr(commandBuffer, session, pInfo);

	public typealias vkGetDataGraphPipelineAvailablePropertiesARMFunction = function VkResult(VkDevice device, VkDataGraphPipelineInfoARM* pPipelineInfo, uint32* pPropertiesCount, VkDataGraphPipelinePropertyARM* pProperties);
	private static vkGetDataGraphPipelineAvailablePropertiesARMFunction vkGetDataGraphPipelineAvailablePropertiesARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDataGraphPipelineAvailablePropertiesARM(VkDevice device, VkDataGraphPipelineInfoARM* pPipelineInfo, uint32* pPropertiesCount, VkDataGraphPipelinePropertyARM* pProperties)
		=> vkGetDataGraphPipelineAvailablePropertiesARM_ptr(device, pPipelineInfo, pPropertiesCount, pProperties);

	public typealias vkGetDataGraphPipelinePropertiesARMFunction = function VkResult(VkDevice device, VkDataGraphPipelineInfoARM* pPipelineInfo, uint32 propertiesCount, VkDataGraphPipelinePropertyQueryResultARM* pProperties);
	private static vkGetDataGraphPipelinePropertiesARMFunction vkGetDataGraphPipelinePropertiesARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetDataGraphPipelinePropertiesARM(VkDevice device, VkDataGraphPipelineInfoARM* pPipelineInfo, uint32 propertiesCount, VkDataGraphPipelinePropertyQueryResultARM* pProperties)
		=> vkGetDataGraphPipelinePropertiesARM_ptr(device, pPipelineInfo, propertiesCount, pProperties);

	public typealias vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARMFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, uint32* pQueueFamilyDataGraphPropertyCount, VkQueueFamilyDataGraphPropertiesARM* pQueueFamilyDataGraphProperties);
	private static vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARMFunction vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, uint32* pQueueFamilyDataGraphPropertyCount, VkQueueFamilyDataGraphPropertiesARM* pQueueFamilyDataGraphProperties)
		=> vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM_ptr(physicalDevice, queueFamilyIndex, pQueueFamilyDataGraphPropertyCount, pQueueFamilyDataGraphProperties);

	public typealias vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARMFunction = function void(VkPhysicalDevice physicalDevice, VkPhysicalDeviceQueueFamilyDataGraphProcessingEngineInfoARM* pQueueFamilyDataGraphProcessingEngineInfo, VkQueueFamilyDataGraphProcessingEnginePropertiesARM* pQueueFamilyDataGraphProcessingEngineProperties);
	private static vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARMFunction vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM(VkPhysicalDevice physicalDevice, VkPhysicalDeviceQueueFamilyDataGraphProcessingEngineInfoARM* pQueueFamilyDataGraphProcessingEngineInfo, VkQueueFamilyDataGraphProcessingEnginePropertiesARM* pQueueFamilyDataGraphProcessingEngineProperties)
		=> vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM_ptr(physicalDevice, pQueueFamilyDataGraphProcessingEngineInfo, pQueueFamilyDataGraphProcessingEngineProperties);

	public typealias vkCmdSetAttachmentFeedbackLoopEnableEXTFunction = function void(VkCommandBuffer commandBuffer, VkImageAspectFlags aspectMask);
	private static vkCmdSetAttachmentFeedbackLoopEnableEXTFunction vkCmdSetAttachmentFeedbackLoopEnableEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetAttachmentFeedbackLoopEnableEXT(VkCommandBuffer commandBuffer, VkImageAspectFlags aspectMask)
		=> vkCmdSetAttachmentFeedbackLoopEnableEXT_ptr(commandBuffer, aspectMask);

	public typealias vkGetScreenBufferPropertiesQNXFunction = function VkResult(VkDevice device, void* buffer, VkScreenBufferPropertiesQNX* pProperties);
	private static vkGetScreenBufferPropertiesQNXFunction vkGetScreenBufferPropertiesQNX_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetScreenBufferPropertiesQNX(VkDevice device, void* buffer, VkScreenBufferPropertiesQNX* pProperties)
		=> vkGetScreenBufferPropertiesQNX_ptr(device, buffer, pProperties);

	public typealias vkCmdSetDescriptorBufferOffsets2EXTFunction = function void(VkCommandBuffer commandBuffer, VkSetDescriptorBufferOffsetsInfoEXT* pSetDescriptorBufferOffsetsInfo);
	private static vkCmdSetDescriptorBufferOffsets2EXTFunction vkCmdSetDescriptorBufferOffsets2EXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetDescriptorBufferOffsets2EXT(VkCommandBuffer commandBuffer, VkSetDescriptorBufferOffsetsInfoEXT* pSetDescriptorBufferOffsetsInfo)
		=> vkCmdSetDescriptorBufferOffsets2EXT_ptr(commandBuffer, pSetDescriptorBufferOffsetsInfo);

	public typealias vkCmdBindDescriptorBufferEmbeddedSamplers2EXTFunction = function void(VkCommandBuffer commandBuffer, VkBindDescriptorBufferEmbeddedSamplersInfoEXT* pBindDescriptorBufferEmbeddedSamplersInfo);
	private static vkCmdBindDescriptorBufferEmbeddedSamplers2EXTFunction vkCmdBindDescriptorBufferEmbeddedSamplers2EXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindDescriptorBufferEmbeddedSamplers2EXT(VkCommandBuffer commandBuffer, VkBindDescriptorBufferEmbeddedSamplersInfoEXT* pBindDescriptorBufferEmbeddedSamplersInfo)
		=> vkCmdBindDescriptorBufferEmbeddedSamplers2EXT_ptr(commandBuffer, pBindDescriptorBufferEmbeddedSamplersInfo);

	public typealias vkCmdBindTileMemoryQCOMFunction = function void(VkCommandBuffer commandBuffer, VkTileMemoryBindInfoQCOM* pTileMemoryBindInfo);
	private static vkCmdBindTileMemoryQCOMFunction vkCmdBindTileMemoryQCOM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBindTileMemoryQCOM(VkCommandBuffer commandBuffer, VkTileMemoryBindInfoQCOM* pTileMemoryBindInfo)
		=> vkCmdBindTileMemoryQCOM_ptr(commandBuffer, pTileMemoryBindInfo);

	public typealias vkCmdCopyMemoryIndirectKHRFunction = function void(VkCommandBuffer commandBuffer, VkCopyMemoryIndirectInfoKHR* pCopyMemoryIndirectInfo);
	private static vkCmdCopyMemoryIndirectKHRFunction vkCmdCopyMemoryIndirectKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyMemoryIndirectKHR(VkCommandBuffer commandBuffer, VkCopyMemoryIndirectInfoKHR* pCopyMemoryIndirectInfo)
		=> vkCmdCopyMemoryIndirectKHR_ptr(commandBuffer, pCopyMemoryIndirectInfo);

	public typealias vkCmdCopyMemoryToImageIndirectKHRFunction = function void(VkCommandBuffer commandBuffer, VkCopyMemoryToImageIndirectInfoKHR* pCopyMemoryToImageIndirectInfo);
	private static vkCmdCopyMemoryToImageIndirectKHRFunction vkCmdCopyMemoryToImageIndirectKHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdCopyMemoryToImageIndirectKHR(VkCommandBuffer commandBuffer, VkCopyMemoryToImageIndirectInfoKHR* pCopyMemoryToImageIndirectInfo)
		=> vkCmdCopyMemoryToImageIndirectKHR_ptr(commandBuffer, pCopyMemoryToImageIndirectInfo);

	public typealias vkCmdDecompressMemoryEXTFunction = function void(VkCommandBuffer commandBuffer, VkDecompressMemoryInfoEXT* pDecompressMemoryInfoEXT);
	private static vkCmdDecompressMemoryEXTFunction vkCmdDecompressMemoryEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDecompressMemoryEXT(VkCommandBuffer commandBuffer, VkDecompressMemoryInfoEXT* pDecompressMemoryInfoEXT)
		=> vkCmdDecompressMemoryEXT_ptr(commandBuffer, pDecompressMemoryInfoEXT);

	public typealias vkCmdDecompressMemoryIndirectCountEXTFunction = function void(VkCommandBuffer commandBuffer, uint64 decompressionMethod, uint64 indirectCommandsAddress, uint64 indirectCommandsCountAddress, uint32 maxDecompressionCount, uint32 stride);
	private static vkCmdDecompressMemoryIndirectCountEXTFunction vkCmdDecompressMemoryIndirectCountEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdDecompressMemoryIndirectCountEXT(VkCommandBuffer commandBuffer, uint64 decompressionMethod, uint64 indirectCommandsAddress, uint64 indirectCommandsCountAddress, uint32 maxDecompressionCount, uint32 stride)
		=> vkCmdDecompressMemoryIndirectCountEXT_ptr(commandBuffer, decompressionMethod, indirectCommandsAddress, indirectCommandsCountAddress, maxDecompressionCount, stride);

	public typealias vkCreateExternalComputeQueueNVFunction = function VkResult(VkDevice device, VkExternalComputeQueueCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkExternalComputeQueueNV* pExternalQueue);
	private static vkCreateExternalComputeQueueNVFunction vkCreateExternalComputeQueueNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateExternalComputeQueueNV(VkDevice device, VkExternalComputeQueueCreateInfoNV* pCreateInfo, VkAllocationCallbacks* pAllocator, VkExternalComputeQueueNV* pExternalQueue)
		=> vkCreateExternalComputeQueueNV_ptr(device, pCreateInfo, pAllocator, pExternalQueue);

	public typealias vkDestroyExternalComputeQueueNVFunction = function void(VkDevice device, VkExternalComputeQueueNV externalQueue, VkAllocationCallbacks* pAllocator);
	private static vkDestroyExternalComputeQueueNVFunction vkDestroyExternalComputeQueueNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyExternalComputeQueueNV(VkDevice device, VkExternalComputeQueueNV externalQueue, VkAllocationCallbacks* pAllocator)
		=> vkDestroyExternalComputeQueueNV_ptr(device, externalQueue, pAllocator);

	public typealias vkGetExternalComputeQueueDataNVFunction = function void(VkExternalComputeQueueNV externalQueue, VkExternalComputeQueueDataParamsNV* vkParams, void* pData);
	private static vkGetExternalComputeQueueDataNVFunction vkGetExternalComputeQueueDataNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetExternalComputeQueueDataNV(VkExternalComputeQueueNV externalQueue, VkExternalComputeQueueDataParamsNV* vkParams, void* pData)
		=> vkGetExternalComputeQueueDataNV_ptr(externalQueue, vkParams, pData);

	public typealias vkGetClusterAccelerationStructureBuildSizesNVFunction = function void(VkDevice device, VkClusterAccelerationStructureInputInfoNV* pInfo, VkAccelerationStructureBuildSizesInfoKHR* pSizeInfo);
	private static vkGetClusterAccelerationStructureBuildSizesNVFunction vkGetClusterAccelerationStructureBuildSizesNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetClusterAccelerationStructureBuildSizesNV(VkDevice device, VkClusterAccelerationStructureInputInfoNV* pInfo, VkAccelerationStructureBuildSizesInfoKHR* pSizeInfo)
		=> vkGetClusterAccelerationStructureBuildSizesNV_ptr(device, pInfo, pSizeInfo);

	public typealias vkCmdBuildClusterAccelerationStructureIndirectNVFunction = function void(VkCommandBuffer commandBuffer, VkClusterAccelerationStructureCommandsInfoNV* pCommandInfos);
	private static vkCmdBuildClusterAccelerationStructureIndirectNVFunction vkCmdBuildClusterAccelerationStructureIndirectNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBuildClusterAccelerationStructureIndirectNV(VkCommandBuffer commandBuffer, VkClusterAccelerationStructureCommandsInfoNV* pCommandInfos)
		=> vkCmdBuildClusterAccelerationStructureIndirectNV_ptr(commandBuffer, pCommandInfos);

	public typealias vkGetPartitionedAccelerationStructuresBuildSizesNVFunction = function void(VkDevice device, VkPartitionedAccelerationStructureInstancesInputNV* pInfo, VkAccelerationStructureBuildSizesInfoKHR* pSizeInfo);
	private static vkGetPartitionedAccelerationStructuresBuildSizesNVFunction vkGetPartitionedAccelerationStructuresBuildSizesNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetPartitionedAccelerationStructuresBuildSizesNV(VkDevice device, VkPartitionedAccelerationStructureInstancesInputNV* pInfo, VkAccelerationStructureBuildSizesInfoKHR* pSizeInfo)
		=> vkGetPartitionedAccelerationStructuresBuildSizesNV_ptr(device, pInfo, pSizeInfo);

	public typealias vkCmdBuildPartitionedAccelerationStructuresNVFunction = function void(VkCommandBuffer commandBuffer, VkBuildPartitionedAccelerationStructureInfoNV* pBuildInfo);
	private static vkCmdBuildPartitionedAccelerationStructuresNVFunction vkCmdBuildPartitionedAccelerationStructuresNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBuildPartitionedAccelerationStructuresNV(VkCommandBuffer commandBuffer, VkBuildPartitionedAccelerationStructureInfoNV* pBuildInfo)
		=> vkCmdBuildPartitionedAccelerationStructuresNV_ptr(commandBuffer, pBuildInfo);

	public typealias vkGetGeneratedCommandsMemoryRequirementsEXTFunction = function void(VkDevice device, VkGeneratedCommandsMemoryRequirementsInfoEXT* pInfo, VkMemoryRequirements2* pMemoryRequirements);
	private static vkGetGeneratedCommandsMemoryRequirementsEXTFunction vkGetGeneratedCommandsMemoryRequirementsEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkGetGeneratedCommandsMemoryRequirementsEXT(VkDevice device, VkGeneratedCommandsMemoryRequirementsInfoEXT* pInfo, VkMemoryRequirements2* pMemoryRequirements)
		=> vkGetGeneratedCommandsMemoryRequirementsEXT_ptr(device, pInfo, pMemoryRequirements);

	public typealias vkCmdPreprocessGeneratedCommandsEXTFunction = function void(VkCommandBuffer commandBuffer, VkGeneratedCommandsInfoEXT* pGeneratedCommandsInfo, VkCommandBuffer stateCommandBuffer);
	private static vkCmdPreprocessGeneratedCommandsEXTFunction vkCmdPreprocessGeneratedCommandsEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdPreprocessGeneratedCommandsEXT(VkCommandBuffer commandBuffer, VkGeneratedCommandsInfoEXT* pGeneratedCommandsInfo, VkCommandBuffer stateCommandBuffer)
		=> vkCmdPreprocessGeneratedCommandsEXT_ptr(commandBuffer, pGeneratedCommandsInfo, stateCommandBuffer);

	public typealias vkCmdExecuteGeneratedCommandsEXTFunction = function void(VkCommandBuffer commandBuffer, VkBool32 isPreprocessed, VkGeneratedCommandsInfoEXT* pGeneratedCommandsInfo);
	private static vkCmdExecuteGeneratedCommandsEXTFunction vkCmdExecuteGeneratedCommandsEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdExecuteGeneratedCommandsEXT(VkCommandBuffer commandBuffer, VkBool32 isPreprocessed, VkGeneratedCommandsInfoEXT* pGeneratedCommandsInfo)
		=> vkCmdExecuteGeneratedCommandsEXT_ptr(commandBuffer, isPreprocessed, pGeneratedCommandsInfo);

	public typealias vkCreateIndirectCommandsLayoutEXTFunction = function VkResult(VkDevice device, VkIndirectCommandsLayoutCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkIndirectCommandsLayoutEXT* pIndirectCommandsLayout);
	private static vkCreateIndirectCommandsLayoutEXTFunction vkCreateIndirectCommandsLayoutEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateIndirectCommandsLayoutEXT(VkDevice device, VkIndirectCommandsLayoutCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkIndirectCommandsLayoutEXT* pIndirectCommandsLayout)
		=> vkCreateIndirectCommandsLayoutEXT_ptr(device, pCreateInfo, pAllocator, pIndirectCommandsLayout);

	public typealias vkDestroyIndirectCommandsLayoutEXTFunction = function void(VkDevice device, VkIndirectCommandsLayoutEXT indirectCommandsLayout, VkAllocationCallbacks* pAllocator);
	private static vkDestroyIndirectCommandsLayoutEXTFunction vkDestroyIndirectCommandsLayoutEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyIndirectCommandsLayoutEXT(VkDevice device, VkIndirectCommandsLayoutEXT indirectCommandsLayout, VkAllocationCallbacks* pAllocator)
		=> vkDestroyIndirectCommandsLayoutEXT_ptr(device, indirectCommandsLayout, pAllocator);

	public typealias vkCreateIndirectExecutionSetEXTFunction = function VkResult(VkDevice device, VkIndirectExecutionSetCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkIndirectExecutionSetEXT* pIndirectExecutionSet);
	private static vkCreateIndirectExecutionSetEXTFunction vkCreateIndirectExecutionSetEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateIndirectExecutionSetEXT(VkDevice device, VkIndirectExecutionSetCreateInfoEXT* pCreateInfo, VkAllocationCallbacks* pAllocator, VkIndirectExecutionSetEXT* pIndirectExecutionSet)
		=> vkCreateIndirectExecutionSetEXT_ptr(device, pCreateInfo, pAllocator, pIndirectExecutionSet);

	public typealias vkDestroyIndirectExecutionSetEXTFunction = function void(VkDevice device, VkIndirectExecutionSetEXT indirectExecutionSet, VkAllocationCallbacks* pAllocator);
	private static vkDestroyIndirectExecutionSetEXTFunction vkDestroyIndirectExecutionSetEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyIndirectExecutionSetEXT(VkDevice device, VkIndirectExecutionSetEXT indirectExecutionSet, VkAllocationCallbacks* pAllocator)
		=> vkDestroyIndirectExecutionSetEXT_ptr(device, indirectExecutionSet, pAllocator);

	public typealias vkUpdateIndirectExecutionSetPipelineEXTFunction = function void(VkDevice device, VkIndirectExecutionSetEXT indirectExecutionSet, uint32 executionSetWriteCount, VkWriteIndirectExecutionSetPipelineEXT* pExecutionSetWrites);
	private static vkUpdateIndirectExecutionSetPipelineEXTFunction vkUpdateIndirectExecutionSetPipelineEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkUpdateIndirectExecutionSetPipelineEXT(VkDevice device, VkIndirectExecutionSetEXT indirectExecutionSet, uint32 executionSetWriteCount, VkWriteIndirectExecutionSetPipelineEXT* pExecutionSetWrites)
		=> vkUpdateIndirectExecutionSetPipelineEXT_ptr(device, indirectExecutionSet, executionSetWriteCount, pExecutionSetWrites);

	public typealias vkUpdateIndirectExecutionSetShaderEXTFunction = function void(VkDevice device, VkIndirectExecutionSetEXT indirectExecutionSet, uint32 executionSetWriteCount, VkWriteIndirectExecutionSetShaderEXT* pExecutionSetWrites);
	private static vkUpdateIndirectExecutionSetShaderEXTFunction vkUpdateIndirectExecutionSetShaderEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkUpdateIndirectExecutionSetShaderEXT(VkDevice device, VkIndirectExecutionSetEXT indirectExecutionSet, uint32 executionSetWriteCount, VkWriteIndirectExecutionSetShaderEXT* pExecutionSetWrites)
		=> vkUpdateIndirectExecutionSetShaderEXT_ptr(device, indirectExecutionSet, executionSetWriteCount, pExecutionSetWrites);

	public typealias vkCreateSurfaceOHOSFunction = function VkResult(VkInstance instance, VkSurfaceCreateInfoOHOS* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateSurfaceOHOSFunction vkCreateSurfaceOHOS_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateSurfaceOHOS(VkInstance instance, VkSurfaceCreateInfoOHOS* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateSurfaceOHOS_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNVFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkCooperativeMatrixFlexibleDimensionsPropertiesNV* pProperties);
	private static vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNVFunction vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV(VkPhysicalDevice physicalDevice, uint32* pPropertyCount, VkCooperativeMatrixFlexibleDimensionsPropertiesNV* pProperties)
		=> vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV_ptr(physicalDevice, pPropertyCount, pProperties);

	public typealias vkGetMemoryMetalHandleEXTFunction = function VkResult(VkDevice device, VkMemoryGetMetalHandleInfoEXT* pGetMetalHandleInfo, void** pHandle);
	private static vkGetMemoryMetalHandleEXTFunction vkGetMemoryMetalHandleEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemoryMetalHandleEXT(VkDevice device, VkMemoryGetMetalHandleInfoEXT* pGetMetalHandleInfo, void** pHandle)
		=> vkGetMemoryMetalHandleEXT_ptr(device, pGetMetalHandleInfo, pHandle);

	public typealias vkGetMemoryMetalHandlePropertiesEXTFunction = function VkResult(VkDevice device, VkExternalMemoryHandleTypeFlags handleType, void* pHandle, VkMemoryMetalHandlePropertiesEXT* pMemoryMetalHandleProperties);
	private static vkGetMemoryMetalHandlePropertiesEXTFunction vkGetMemoryMetalHandlePropertiesEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetMemoryMetalHandlePropertiesEXT(VkDevice device, VkExternalMemoryHandleTypeFlags handleType, void* pHandle, VkMemoryMetalHandlePropertiesEXT* pMemoryMetalHandleProperties)
		=> vkGetMemoryMetalHandlePropertiesEXT_ptr(device, handleType, pHandle, pMemoryMetalHandleProperties);

	public typealias vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARMFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, uint32* pCounterCount, VkPerformanceCounterARM* pCounters, VkPerformanceCounterDescriptionARM* pCounterDescriptions);
	private static vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARMFunction vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, uint32* pCounterCount, VkPerformanceCounterARM* pCounters, VkPerformanceCounterDescriptionARM* pCounterDescriptions)
		=> vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM_ptr(physicalDevice, queueFamilyIndex, pCounterCount, pCounters, pCounterDescriptions);

	public typealias vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARMFunction = function VkResult(VkPhysicalDevice physicalDevice, uint32* pDescriptionCount, VkShaderInstrumentationMetricDescriptionARM* pDescriptions);
	private static vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARMFunction vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM(VkPhysicalDevice physicalDevice, uint32* pDescriptionCount, VkShaderInstrumentationMetricDescriptionARM* pDescriptions)
		=> vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM_ptr(physicalDevice, pDescriptionCount, pDescriptions);

	public typealias vkCreateShaderInstrumentationARMFunction = function VkResult(VkDevice device, VkShaderInstrumentationCreateInfoARM* pCreateInfo, VkAllocationCallbacks* pAllocator, VkShaderInstrumentationARM* pInstrumentation);
	private static vkCreateShaderInstrumentationARMFunction vkCreateShaderInstrumentationARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateShaderInstrumentationARM(VkDevice device, VkShaderInstrumentationCreateInfoARM* pCreateInfo, VkAllocationCallbacks* pAllocator, VkShaderInstrumentationARM* pInstrumentation)
		=> vkCreateShaderInstrumentationARM_ptr(device, pCreateInfo, pAllocator, pInstrumentation);

	public typealias vkDestroyShaderInstrumentationARMFunction = function void(VkDevice device, VkShaderInstrumentationARM instrumentation, VkAllocationCallbacks* pAllocator);
	private static vkDestroyShaderInstrumentationARMFunction vkDestroyShaderInstrumentationARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkDestroyShaderInstrumentationARM(VkDevice device, VkShaderInstrumentationARM instrumentation, VkAllocationCallbacks* pAllocator)
		=> vkDestroyShaderInstrumentationARM_ptr(device, instrumentation, pAllocator);

	public typealias vkCmdBeginShaderInstrumentationARMFunction = function void(VkCommandBuffer commandBuffer, VkShaderInstrumentationARM instrumentation);
	private static vkCmdBeginShaderInstrumentationARMFunction vkCmdBeginShaderInstrumentationARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBeginShaderInstrumentationARM(VkCommandBuffer commandBuffer, VkShaderInstrumentationARM instrumentation)
		=> vkCmdBeginShaderInstrumentationARM_ptr(commandBuffer, instrumentation);

	public typealias vkCmdEndShaderInstrumentationARMFunction = function void(VkCommandBuffer commandBuffer);
	private static vkCmdEndShaderInstrumentationARMFunction vkCmdEndShaderInstrumentationARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdEndShaderInstrumentationARM(VkCommandBuffer commandBuffer)
		=> vkCmdEndShaderInstrumentationARM_ptr(commandBuffer);

	public typealias vkGetShaderInstrumentationValuesARMFunction = function VkResult(VkDevice device, VkShaderInstrumentationARM instrumentation, uint32* pMetricBlockCount, void* pMetricValues, uint32 flags);
	private static vkGetShaderInstrumentationValuesARMFunction vkGetShaderInstrumentationValuesARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkGetShaderInstrumentationValuesARM(VkDevice device, VkShaderInstrumentationARM instrumentation, uint32* pMetricBlockCount, void* pMetricValues, uint32 flags)
		=> vkGetShaderInstrumentationValuesARM_ptr(device, instrumentation, pMetricBlockCount, pMetricValues, flags);

	public typealias vkClearShaderInstrumentationMetricsARMFunction = function void(VkDevice device, VkShaderInstrumentationARM instrumentation);
	private static vkClearShaderInstrumentationMetricsARMFunction vkClearShaderInstrumentationMetricsARM_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkClearShaderInstrumentationMetricsARM(VkDevice device, VkShaderInstrumentationARM instrumentation)
		=> vkClearShaderInstrumentationMetricsARM_ptr(device, instrumentation);

	public typealias vkCmdEndRendering2KHRFunction = function void(VkCommandBuffer commandBuffer, VkRenderingEndInfoKHR* pRenderingEndInfo);
	private static vkCmdEndRendering2KHRFunction vkCmdEndRendering2KHR_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdEndRendering2KHR(VkCommandBuffer commandBuffer, VkRenderingEndInfoKHR* pRenderingEndInfo)
		=> vkCmdEndRendering2KHR_ptr(commandBuffer, pRenderingEndInfo);

	public typealias vkCmdBeginCustomResolveEXTFunction = function void(VkCommandBuffer commandBuffer, VkBeginCustomResolveInfoEXT* pBeginCustomResolveInfo);
	private static vkCmdBeginCustomResolveEXTFunction vkCmdBeginCustomResolveEXT_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdBeginCustomResolveEXT(VkCommandBuffer commandBuffer, VkBeginCustomResolveInfoEXT* pBeginCustomResolveInfo)
		=> vkCmdBeginCustomResolveEXT_ptr(commandBuffer, pBeginCustomResolveInfo);

	public typealias vkCmdSetComputeOccupancyPriorityNVFunction = function void(VkCommandBuffer commandBuffer, VkComputeOccupancyPriorityParametersNV* pParameters);
	private static vkCmdSetComputeOccupancyPriorityNVFunction vkCmdSetComputeOccupancyPriorityNV_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static void vkCmdSetComputeOccupancyPriorityNV(VkCommandBuffer commandBuffer, VkComputeOccupancyPriorityParametersNV* pParameters)
		=> vkCmdSetComputeOccupancyPriorityNV_ptr(commandBuffer, pParameters);

	public typealias vkCreateUbmSurfaceSECFunction = function VkResult(VkInstance instance, VkUbmSurfaceCreateInfoSEC* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface);
	private static vkCreateUbmSurfaceSECFunction vkCreateUbmSurfaceSEC_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkResult vkCreateUbmSurfaceSEC(VkInstance instance, VkUbmSurfaceCreateInfoSEC* pCreateInfo, VkAllocationCallbacks* pAllocator, VkSurfaceKHR* pSurface)
		=> vkCreateUbmSurfaceSEC_ptr(instance, pCreateInfo, pAllocator, pSurface);

	public typealias vkGetPhysicalDeviceUbmPresentationSupportSECFunction = function VkBool32(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, void* device);
	private static vkGetPhysicalDeviceUbmPresentationSupportSECFunction vkGetPhysicalDeviceUbmPresentationSupportSEC_ptr;
	[CallingConvention(VulkanNative.CallConv)]
	public static VkBool32 vkGetPhysicalDeviceUbmPresentationSupportSEC(VkPhysicalDevice physicalDevice, uint32 queueFamilyIndex, void* device)
		=> vkGetPhysicalDeviceUbmPresentationSupportSEC_ptr(physicalDevice, queueFamilyIndex, device);


	private static List<(InstanceFunctionFlags Flags, String Name)> sKnownInstanceCommands = new .()
	{
		(.Agnostic, "vkDestroyInstance"),
		(.Agnostic, "vkEnumeratePhysicalDevices"),
		(.Agnostic, "vkGetInstanceProcAddr"),
		(.Agnostic, "vkEnumeratePhysicalDeviceGroups"),
		(.Agnostic, "vkDestroySurfaceKHR"),
		(.Agnostic, "vkCreateDisplayPlaneSurfaceKHR"),
		(.Agnostic, "vkCreateDebugReportCallbackEXT"),
		(.Agnostic, "vkDestroyDebugReportCallbackEXT"),
		(.Agnostic, "vkDebugReportMessageEXT"),
		(.Agnostic, "vkCreateDebugUtilsMessengerEXT"),
		(.Agnostic, "vkDestroyDebugUtilsMessengerEXT"),
		(.Agnostic, "vkSubmitDebugUtilsMessageEXT"),
		(.Agnostic, "vkCreateUbmSurfaceSEC"),
		(.Xlib, "vkCreateXlibSurfaceKHR"),
		(.Xcb, "vkCreateXcbSurfaceKHR"),
		(.Wayland, "vkCreateWaylandSurfaceKHR"),
		(.Android, "vkCreateAndroidSurfaceKHR"),
		(.Win32, "vkCreateWin32SurfaceKHR"),
		(.GGP, "vkCreateStreamDescriptorSurfaceGGP"),
		(.NN, "vkCreateViSurfaceNN"),
		(.MVK, "vkCreateIOSSurfaceMVK"),
		(.MVK, "vkCreateMacOSSurfaceMVK"),
		(.FUCHSIA, "vkCreateImagePipeSurfaceFUCHSIA"),
		(.Metal, "vkCreateMetalSurfaceEXT"),
		(.Headless, "vkCreateHeadlessSurfaceEXT"),
		(.DirectFB, "vkCreateDirectFBSurfaceEXT"),
		(.QNX, "vkCreateScreenSurfaceQNX"),
		(.OHOS, "vkCreateSurfaceOHOS"),
	} ~ delete _;

	public static Result<void> LoadFunction(StringView name, VkInstance? instance = null, bool invokeErrorCallback = true)
	{
		if(mLoadedFunctions.Contains(scope .(name)))
		{
			return .Ok;
		}

		switch (name) {
		case "vkCreateInstance":
			LoadFunction("vkCreateInstance", out vkCreateInstance_ptr, instance, invokeErrorCallback);
			if(vkCreateInstance_ptr == null)
				return .Err;
			break;

		case "vkDestroyInstance":
			LoadFunction("vkDestroyInstance", out vkDestroyInstance_ptr, instance, invokeErrorCallback);
			if(vkDestroyInstance_ptr == null)
				return .Err;
			break;

		case "vkEnumeratePhysicalDevices":
			LoadFunction("vkEnumeratePhysicalDevices", out vkEnumeratePhysicalDevices_ptr, instance, invokeErrorCallback);
			if(vkEnumeratePhysicalDevices_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceFeatures":
			LoadFunction("vkGetPhysicalDeviceFeatures", out vkGetPhysicalDeviceFeatures_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceFeatures_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceFormatProperties":
			LoadFunction("vkGetPhysicalDeviceFormatProperties", out vkGetPhysicalDeviceFormatProperties_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceFormatProperties_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceImageFormatProperties":
			LoadFunction("vkGetPhysicalDeviceImageFormatProperties", out vkGetPhysicalDeviceImageFormatProperties_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceImageFormatProperties_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceProperties":
			LoadFunction("vkGetPhysicalDeviceProperties", out vkGetPhysicalDeviceProperties_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceProperties_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceQueueFamilyProperties":
			LoadFunction("vkGetPhysicalDeviceQueueFamilyProperties", out vkGetPhysicalDeviceQueueFamilyProperties_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceQueueFamilyProperties_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceMemoryProperties":
			LoadFunction("vkGetPhysicalDeviceMemoryProperties", out vkGetPhysicalDeviceMemoryProperties_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceMemoryProperties_ptr == null)
				return .Err;
			break;

		case "vkGetInstanceProcAddr":
			LoadFunction("vkGetInstanceProcAddr", out vkGetInstanceProcAddr_ptr, instance, invokeErrorCallback);
			if(vkGetInstanceProcAddr_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceProcAddr":
			LoadFunction("vkGetDeviceProcAddr", out vkGetDeviceProcAddr_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceProcAddr_ptr == null)
				return .Err;
			break;

		case "vkCreateDevice":
			LoadFunction("vkCreateDevice", out vkCreateDevice_ptr, instance, invokeErrorCallback);
			if(vkCreateDevice_ptr == null)
				return .Err;
			break;

		case "vkDestroyDevice":
			LoadFunction("vkDestroyDevice", out vkDestroyDevice_ptr, instance, invokeErrorCallback);
			if(vkDestroyDevice_ptr == null)
				return .Err;
			break;

		case "vkEnumerateInstanceExtensionProperties":
			LoadFunction("vkEnumerateInstanceExtensionProperties", out vkEnumerateInstanceExtensionProperties_ptr, instance, invokeErrorCallback);
			if(vkEnumerateInstanceExtensionProperties_ptr == null)
				return .Err;
			break;

		case "vkEnumerateDeviceExtensionProperties":
			LoadFunction("vkEnumerateDeviceExtensionProperties", out vkEnumerateDeviceExtensionProperties_ptr, instance, invokeErrorCallback);
			if(vkEnumerateDeviceExtensionProperties_ptr == null)
				return .Err;
			break;

		case "vkEnumerateInstanceLayerProperties":
			LoadFunction("vkEnumerateInstanceLayerProperties", out vkEnumerateInstanceLayerProperties_ptr, instance, invokeErrorCallback);
			if(vkEnumerateInstanceLayerProperties_ptr == null)
				return .Err;
			break;

		case "vkEnumerateDeviceLayerProperties":
			LoadFunction("vkEnumerateDeviceLayerProperties", out vkEnumerateDeviceLayerProperties_ptr, instance, invokeErrorCallback);
			if(vkEnumerateDeviceLayerProperties_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceQueue":
			LoadFunction("vkGetDeviceQueue", out vkGetDeviceQueue_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceQueue_ptr == null)
				return .Err;
			break;

		case "vkQueueSubmit":
			LoadFunction("vkQueueSubmit", out vkQueueSubmit_ptr, instance, invokeErrorCallback);
			if(vkQueueSubmit_ptr == null)
				return .Err;
			break;

		case "vkQueueWaitIdle":
			LoadFunction("vkQueueWaitIdle", out vkQueueWaitIdle_ptr, instance, invokeErrorCallback);
			if(vkQueueWaitIdle_ptr == null)
				return .Err;
			break;

		case "vkDeviceWaitIdle":
			LoadFunction("vkDeviceWaitIdle", out vkDeviceWaitIdle_ptr, instance, invokeErrorCallback);
			if(vkDeviceWaitIdle_ptr == null)
				return .Err;
			break;

		case "vkAllocateMemory":
			LoadFunction("vkAllocateMemory", out vkAllocateMemory_ptr, instance, invokeErrorCallback);
			if(vkAllocateMemory_ptr == null)
				return .Err;
			break;

		case "vkFreeMemory":
			LoadFunction("vkFreeMemory", out vkFreeMemory_ptr, instance, invokeErrorCallback);
			if(vkFreeMemory_ptr == null)
				return .Err;
			break;

		case "vkMapMemory":
			LoadFunction("vkMapMemory", out vkMapMemory_ptr, instance, invokeErrorCallback);
			if(vkMapMemory_ptr == null)
				return .Err;
			break;

		case "vkUnmapMemory":
			LoadFunction("vkUnmapMemory", out vkUnmapMemory_ptr, instance, invokeErrorCallback);
			if(vkUnmapMemory_ptr == null)
				return .Err;
			break;

		case "vkFlushMappedMemoryRanges":
			LoadFunction("vkFlushMappedMemoryRanges", out vkFlushMappedMemoryRanges_ptr, instance, invokeErrorCallback);
			if(vkFlushMappedMemoryRanges_ptr == null)
				return .Err;
			break;

		case "vkInvalidateMappedMemoryRanges":
			LoadFunction("vkInvalidateMappedMemoryRanges", out vkInvalidateMappedMemoryRanges_ptr, instance, invokeErrorCallback);
			if(vkInvalidateMappedMemoryRanges_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceMemoryCommitment":
			LoadFunction("vkGetDeviceMemoryCommitment", out vkGetDeviceMemoryCommitment_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceMemoryCommitment_ptr == null)
				return .Err;
			break;

		case "vkBindBufferMemory":
			LoadFunction("vkBindBufferMemory", out vkBindBufferMemory_ptr, instance, invokeErrorCallback);
			if(vkBindBufferMemory_ptr == null)
				return .Err;
			break;

		case "vkBindImageMemory":
			LoadFunction("vkBindImageMemory", out vkBindImageMemory_ptr, instance, invokeErrorCallback);
			if(vkBindImageMemory_ptr == null)
				return .Err;
			break;

		case "vkGetBufferMemoryRequirements":
			LoadFunction("vkGetBufferMemoryRequirements", out vkGetBufferMemoryRequirements_ptr, instance, invokeErrorCallback);
			if(vkGetBufferMemoryRequirements_ptr == null)
				return .Err;
			break;

		case "vkGetImageMemoryRequirements":
			LoadFunction("vkGetImageMemoryRequirements", out vkGetImageMemoryRequirements_ptr, instance, invokeErrorCallback);
			if(vkGetImageMemoryRequirements_ptr == null)
				return .Err;
			break;

		case "vkGetImageSparseMemoryRequirements":
			LoadFunction("vkGetImageSparseMemoryRequirements", out vkGetImageSparseMemoryRequirements_ptr, instance, invokeErrorCallback);
			if(vkGetImageSparseMemoryRequirements_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceSparseImageFormatProperties":
			LoadFunction("vkGetPhysicalDeviceSparseImageFormatProperties", out vkGetPhysicalDeviceSparseImageFormatProperties_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceSparseImageFormatProperties_ptr == null)
				return .Err;
			break;

		case "vkQueueBindSparse":
			LoadFunction("vkQueueBindSparse", out vkQueueBindSparse_ptr, instance, invokeErrorCallback);
			if(vkQueueBindSparse_ptr == null)
				return .Err;
			break;

		case "vkCreateFence":
			LoadFunction("vkCreateFence", out vkCreateFence_ptr, instance, invokeErrorCallback);
			if(vkCreateFence_ptr == null)
				return .Err;
			break;

		case "vkDestroyFence":
			LoadFunction("vkDestroyFence", out vkDestroyFence_ptr, instance, invokeErrorCallback);
			if(vkDestroyFence_ptr == null)
				return .Err;
			break;

		case "vkResetFences":
			LoadFunction("vkResetFences", out vkResetFences_ptr, instance, invokeErrorCallback);
			if(vkResetFences_ptr == null)
				return .Err;
			break;

		case "vkGetFenceStatus":
			LoadFunction("vkGetFenceStatus", out vkGetFenceStatus_ptr, instance, invokeErrorCallback);
			if(vkGetFenceStatus_ptr == null)
				return .Err;
			break;

		case "vkWaitForFences":
			LoadFunction("vkWaitForFences", out vkWaitForFences_ptr, instance, invokeErrorCallback);
			if(vkWaitForFences_ptr == null)
				return .Err;
			break;

		case "vkCreateSemaphore":
			LoadFunction("vkCreateSemaphore", out vkCreateSemaphore_ptr, instance, invokeErrorCallback);
			if(vkCreateSemaphore_ptr == null)
				return .Err;
			break;

		case "vkDestroySemaphore":
			LoadFunction("vkDestroySemaphore", out vkDestroySemaphore_ptr, instance, invokeErrorCallback);
			if(vkDestroySemaphore_ptr == null)
				return .Err;
			break;

		case "vkCreateQueryPool":
			LoadFunction("vkCreateQueryPool", out vkCreateQueryPool_ptr, instance, invokeErrorCallback);
			if(vkCreateQueryPool_ptr == null)
				return .Err;
			break;

		case "vkDestroyQueryPool":
			LoadFunction("vkDestroyQueryPool", out vkDestroyQueryPool_ptr, instance, invokeErrorCallback);
			if(vkDestroyQueryPool_ptr == null)
				return .Err;
			break;

		case "vkGetQueryPoolResults":
			LoadFunction("vkGetQueryPoolResults", out vkGetQueryPoolResults_ptr, instance, invokeErrorCallback);
			if(vkGetQueryPoolResults_ptr == null)
				return .Err;
			break;

		case "vkCreateBuffer":
			LoadFunction("vkCreateBuffer", out vkCreateBuffer_ptr, instance, invokeErrorCallback);
			if(vkCreateBuffer_ptr == null)
				return .Err;
			break;

		case "vkDestroyBuffer":
			LoadFunction("vkDestroyBuffer", out vkDestroyBuffer_ptr, instance, invokeErrorCallback);
			if(vkDestroyBuffer_ptr == null)
				return .Err;
			break;

		case "vkCreateImage":
			LoadFunction("vkCreateImage", out vkCreateImage_ptr, instance, invokeErrorCallback);
			if(vkCreateImage_ptr == null)
				return .Err;
			break;

		case "vkDestroyImage":
			LoadFunction("vkDestroyImage", out vkDestroyImage_ptr, instance, invokeErrorCallback);
			if(vkDestroyImage_ptr == null)
				return .Err;
			break;

		case "vkGetImageSubresourceLayout":
			LoadFunction("vkGetImageSubresourceLayout", out vkGetImageSubresourceLayout_ptr, instance, invokeErrorCallback);
			if(vkGetImageSubresourceLayout_ptr == null)
				return .Err;
			break;

		case "vkCreateImageView":
			LoadFunction("vkCreateImageView", out vkCreateImageView_ptr, instance, invokeErrorCallback);
			if(vkCreateImageView_ptr == null)
				return .Err;
			break;

		case "vkDestroyImageView":
			LoadFunction("vkDestroyImageView", out vkDestroyImageView_ptr, instance, invokeErrorCallback);
			if(vkDestroyImageView_ptr == null)
				return .Err;
			break;

		case "vkCreateCommandPool":
			LoadFunction("vkCreateCommandPool", out vkCreateCommandPool_ptr, instance, invokeErrorCallback);
			if(vkCreateCommandPool_ptr == null)
				return .Err;
			break;

		case "vkDestroyCommandPool":
			LoadFunction("vkDestroyCommandPool", out vkDestroyCommandPool_ptr, instance, invokeErrorCallback);
			if(vkDestroyCommandPool_ptr == null)
				return .Err;
			break;

		case "vkResetCommandPool":
			LoadFunction("vkResetCommandPool", out vkResetCommandPool_ptr, instance, invokeErrorCallback);
			if(vkResetCommandPool_ptr == null)
				return .Err;
			break;

		case "vkAllocateCommandBuffers":
			LoadFunction("vkAllocateCommandBuffers", out vkAllocateCommandBuffers_ptr, instance, invokeErrorCallback);
			if(vkAllocateCommandBuffers_ptr == null)
				return .Err;
			break;

		case "vkFreeCommandBuffers":
			LoadFunction("vkFreeCommandBuffers", out vkFreeCommandBuffers_ptr, instance, invokeErrorCallback);
			if(vkFreeCommandBuffers_ptr == null)
				return .Err;
			break;

		case "vkBeginCommandBuffer":
			LoadFunction("vkBeginCommandBuffer", out vkBeginCommandBuffer_ptr, instance, invokeErrorCallback);
			if(vkBeginCommandBuffer_ptr == null)
				return .Err;
			break;

		case "vkEndCommandBuffer":
			LoadFunction("vkEndCommandBuffer", out vkEndCommandBuffer_ptr, instance, invokeErrorCallback);
			if(vkEndCommandBuffer_ptr == null)
				return .Err;
			break;

		case "vkResetCommandBuffer":
			LoadFunction("vkResetCommandBuffer", out vkResetCommandBuffer_ptr, instance, invokeErrorCallback);
			if(vkResetCommandBuffer_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyBuffer":
			LoadFunction("vkCmdCopyBuffer", out vkCmdCopyBuffer_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyBuffer_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyImage":
			LoadFunction("vkCmdCopyImage", out vkCmdCopyImage_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyImage_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyBufferToImage":
			LoadFunction("vkCmdCopyBufferToImage", out vkCmdCopyBufferToImage_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyBufferToImage_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyImageToBuffer":
			LoadFunction("vkCmdCopyImageToBuffer", out vkCmdCopyImageToBuffer_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyImageToBuffer_ptr == null)
				return .Err;
			break;

		case "vkCmdUpdateBuffer":
			LoadFunction("vkCmdUpdateBuffer", out vkCmdUpdateBuffer_ptr, instance, invokeErrorCallback);
			if(vkCmdUpdateBuffer_ptr == null)
				return .Err;
			break;

		case "vkCmdFillBuffer":
			LoadFunction("vkCmdFillBuffer", out vkCmdFillBuffer_ptr, instance, invokeErrorCallback);
			if(vkCmdFillBuffer_ptr == null)
				return .Err;
			break;

		case "vkCmdPipelineBarrier":
			LoadFunction("vkCmdPipelineBarrier", out vkCmdPipelineBarrier_ptr, instance, invokeErrorCallback);
			if(vkCmdPipelineBarrier_ptr == null)
				return .Err;
			break;

		case "vkCmdBeginQuery":
			LoadFunction("vkCmdBeginQuery", out vkCmdBeginQuery_ptr, instance, invokeErrorCallback);
			if(vkCmdBeginQuery_ptr == null)
				return .Err;
			break;

		case "vkCmdEndQuery":
			LoadFunction("vkCmdEndQuery", out vkCmdEndQuery_ptr, instance, invokeErrorCallback);
			if(vkCmdEndQuery_ptr == null)
				return .Err;
			break;

		case "vkCmdResetQueryPool":
			LoadFunction("vkCmdResetQueryPool", out vkCmdResetQueryPool_ptr, instance, invokeErrorCallback);
			if(vkCmdResetQueryPool_ptr == null)
				return .Err;
			break;

		case "vkCmdWriteTimestamp":
			LoadFunction("vkCmdWriteTimestamp", out vkCmdWriteTimestamp_ptr, instance, invokeErrorCallback);
			if(vkCmdWriteTimestamp_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyQueryPoolResults":
			LoadFunction("vkCmdCopyQueryPoolResults", out vkCmdCopyQueryPoolResults_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyQueryPoolResults_ptr == null)
				return .Err;
			break;

		case "vkCmdExecuteCommands":
			LoadFunction("vkCmdExecuteCommands", out vkCmdExecuteCommands_ptr, instance, invokeErrorCallback);
			if(vkCmdExecuteCommands_ptr == null)
				return .Err;
			break;

		case "vkCreateEvent":
			LoadFunction("vkCreateEvent", out vkCreateEvent_ptr, instance, invokeErrorCallback);
			if(vkCreateEvent_ptr == null)
				return .Err;
			break;

		case "vkDestroyEvent":
			LoadFunction("vkDestroyEvent", out vkDestroyEvent_ptr, instance, invokeErrorCallback);
			if(vkDestroyEvent_ptr == null)
				return .Err;
			break;

		case "vkGetEventStatus":
			LoadFunction("vkGetEventStatus", out vkGetEventStatus_ptr, instance, invokeErrorCallback);
			if(vkGetEventStatus_ptr == null)
				return .Err;
			break;

		case "vkSetEvent":
			LoadFunction("vkSetEvent", out vkSetEvent_ptr, instance, invokeErrorCallback);
			if(vkSetEvent_ptr == null)
				return .Err;
			break;

		case "vkResetEvent":
			LoadFunction("vkResetEvent", out vkResetEvent_ptr, instance, invokeErrorCallback);
			if(vkResetEvent_ptr == null)
				return .Err;
			break;

		case "vkCreateBufferView":
			LoadFunction("vkCreateBufferView", out vkCreateBufferView_ptr, instance, invokeErrorCallback);
			if(vkCreateBufferView_ptr == null)
				return .Err;
			break;

		case "vkDestroyBufferView":
			LoadFunction("vkDestroyBufferView", out vkDestroyBufferView_ptr, instance, invokeErrorCallback);
			if(vkDestroyBufferView_ptr == null)
				return .Err;
			break;

		case "vkCreateShaderModule":
			LoadFunction("vkCreateShaderModule", out vkCreateShaderModule_ptr, instance, invokeErrorCallback);
			if(vkCreateShaderModule_ptr == null)
				return .Err;
			break;

		case "vkDestroyShaderModule":
			LoadFunction("vkDestroyShaderModule", out vkDestroyShaderModule_ptr, instance, invokeErrorCallback);
			if(vkDestroyShaderModule_ptr == null)
				return .Err;
			break;

		case "vkCreatePipelineCache":
			LoadFunction("vkCreatePipelineCache", out vkCreatePipelineCache_ptr, instance, invokeErrorCallback);
			if(vkCreatePipelineCache_ptr == null)
				return .Err;
			break;

		case "vkDestroyPipelineCache":
			LoadFunction("vkDestroyPipelineCache", out vkDestroyPipelineCache_ptr, instance, invokeErrorCallback);
			if(vkDestroyPipelineCache_ptr == null)
				return .Err;
			break;

		case "vkGetPipelineCacheData":
			LoadFunction("vkGetPipelineCacheData", out vkGetPipelineCacheData_ptr, instance, invokeErrorCallback);
			if(vkGetPipelineCacheData_ptr == null)
				return .Err;
			break;

		case "vkMergePipelineCaches":
			LoadFunction("vkMergePipelineCaches", out vkMergePipelineCaches_ptr, instance, invokeErrorCallback);
			if(vkMergePipelineCaches_ptr == null)
				return .Err;
			break;

		case "vkCreateComputePipelines":
			LoadFunction("vkCreateComputePipelines", out vkCreateComputePipelines_ptr, instance, invokeErrorCallback);
			if(vkCreateComputePipelines_ptr == null)
				return .Err;
			break;

		case "vkDestroyPipeline":
			LoadFunction("vkDestroyPipeline", out vkDestroyPipeline_ptr, instance, invokeErrorCallback);
			if(vkDestroyPipeline_ptr == null)
				return .Err;
			break;

		case "vkCreatePipelineLayout":
			LoadFunction("vkCreatePipelineLayout", out vkCreatePipelineLayout_ptr, instance, invokeErrorCallback);
			if(vkCreatePipelineLayout_ptr == null)
				return .Err;
			break;

		case "vkDestroyPipelineLayout":
			LoadFunction("vkDestroyPipelineLayout", out vkDestroyPipelineLayout_ptr, instance, invokeErrorCallback);
			if(vkDestroyPipelineLayout_ptr == null)
				return .Err;
			break;

		case "vkCreateSampler":
			LoadFunction("vkCreateSampler", out vkCreateSampler_ptr, instance, invokeErrorCallback);
			if(vkCreateSampler_ptr == null)
				return .Err;
			break;

		case "vkDestroySampler":
			LoadFunction("vkDestroySampler", out vkDestroySampler_ptr, instance, invokeErrorCallback);
			if(vkDestroySampler_ptr == null)
				return .Err;
			break;

		case "vkCreateDescriptorSetLayout":
			LoadFunction("vkCreateDescriptorSetLayout", out vkCreateDescriptorSetLayout_ptr, instance, invokeErrorCallback);
			if(vkCreateDescriptorSetLayout_ptr == null)
				return .Err;
			break;

		case "vkDestroyDescriptorSetLayout":
			LoadFunction("vkDestroyDescriptorSetLayout", out vkDestroyDescriptorSetLayout_ptr, instance, invokeErrorCallback);
			if(vkDestroyDescriptorSetLayout_ptr == null)
				return .Err;
			break;

		case "vkCreateDescriptorPool":
			LoadFunction("vkCreateDescriptorPool", out vkCreateDescriptorPool_ptr, instance, invokeErrorCallback);
			if(vkCreateDescriptorPool_ptr == null)
				return .Err;
			break;

		case "vkDestroyDescriptorPool":
			LoadFunction("vkDestroyDescriptorPool", out vkDestroyDescriptorPool_ptr, instance, invokeErrorCallback);
			if(vkDestroyDescriptorPool_ptr == null)
				return .Err;
			break;

		case "vkResetDescriptorPool":
			LoadFunction("vkResetDescriptorPool", out vkResetDescriptorPool_ptr, instance, invokeErrorCallback);
			if(vkResetDescriptorPool_ptr == null)
				return .Err;
			break;

		case "vkAllocateDescriptorSets":
			LoadFunction("vkAllocateDescriptorSets", out vkAllocateDescriptorSets_ptr, instance, invokeErrorCallback);
			if(vkAllocateDescriptorSets_ptr == null)
				return .Err;
			break;

		case "vkFreeDescriptorSets":
			LoadFunction("vkFreeDescriptorSets", out vkFreeDescriptorSets_ptr, instance, invokeErrorCallback);
			if(vkFreeDescriptorSets_ptr == null)
				return .Err;
			break;

		case "vkUpdateDescriptorSets":
			LoadFunction("vkUpdateDescriptorSets", out vkUpdateDescriptorSets_ptr, instance, invokeErrorCallback);
			if(vkUpdateDescriptorSets_ptr == null)
				return .Err;
			break;

		case "vkCmdBindPipeline":
			LoadFunction("vkCmdBindPipeline", out vkCmdBindPipeline_ptr, instance, invokeErrorCallback);
			if(vkCmdBindPipeline_ptr == null)
				return .Err;
			break;

		case "vkCmdBindDescriptorSets":
			LoadFunction("vkCmdBindDescriptorSets", out vkCmdBindDescriptorSets_ptr, instance, invokeErrorCallback);
			if(vkCmdBindDescriptorSets_ptr == null)
				return .Err;
			break;

		case "vkCmdClearColorImage":
			LoadFunction("vkCmdClearColorImage", out vkCmdClearColorImage_ptr, instance, invokeErrorCallback);
			if(vkCmdClearColorImage_ptr == null)
				return .Err;
			break;

		case "vkCmdDispatch":
			LoadFunction("vkCmdDispatch", out vkCmdDispatch_ptr, instance, invokeErrorCallback);
			if(vkCmdDispatch_ptr == null)
				return .Err;
			break;

		case "vkCmdDispatchIndirect":
			LoadFunction("vkCmdDispatchIndirect", out vkCmdDispatchIndirect_ptr, instance, invokeErrorCallback);
			if(vkCmdDispatchIndirect_ptr == null)
				return .Err;
			break;

		case "vkCmdSetEvent":
			LoadFunction("vkCmdSetEvent", out vkCmdSetEvent_ptr, instance, invokeErrorCallback);
			if(vkCmdSetEvent_ptr == null)
				return .Err;
			break;

		case "vkCmdResetEvent":
			LoadFunction("vkCmdResetEvent", out vkCmdResetEvent_ptr, instance, invokeErrorCallback);
			if(vkCmdResetEvent_ptr == null)
				return .Err;
			break;

		case "vkCmdWaitEvents":
			LoadFunction("vkCmdWaitEvents", out vkCmdWaitEvents_ptr, instance, invokeErrorCallback);
			if(vkCmdWaitEvents_ptr == null)
				return .Err;
			break;

		case "vkCmdPushConstants":
			LoadFunction("vkCmdPushConstants", out vkCmdPushConstants_ptr, instance, invokeErrorCallback);
			if(vkCmdPushConstants_ptr == null)
				return .Err;
			break;

		case "vkCreateGraphicsPipelines":
			LoadFunction("vkCreateGraphicsPipelines", out vkCreateGraphicsPipelines_ptr, instance, invokeErrorCallback);
			if(vkCreateGraphicsPipelines_ptr == null)
				return .Err;
			break;

		case "vkCreateFramebuffer":
			LoadFunction("vkCreateFramebuffer", out vkCreateFramebuffer_ptr, instance, invokeErrorCallback);
			if(vkCreateFramebuffer_ptr == null)
				return .Err;
			break;

		case "vkDestroyFramebuffer":
			LoadFunction("vkDestroyFramebuffer", out vkDestroyFramebuffer_ptr, instance, invokeErrorCallback);
			if(vkDestroyFramebuffer_ptr == null)
				return .Err;
			break;

		case "vkCreateRenderPass":
			LoadFunction("vkCreateRenderPass", out vkCreateRenderPass_ptr, instance, invokeErrorCallback);
			if(vkCreateRenderPass_ptr == null)
				return .Err;
			break;

		case "vkDestroyRenderPass":
			LoadFunction("vkDestroyRenderPass", out vkDestroyRenderPass_ptr, instance, invokeErrorCallback);
			if(vkDestroyRenderPass_ptr == null)
				return .Err;
			break;

		case "vkGetRenderAreaGranularity":
			LoadFunction("vkGetRenderAreaGranularity", out vkGetRenderAreaGranularity_ptr, instance, invokeErrorCallback);
			if(vkGetRenderAreaGranularity_ptr == null)
				return .Err;
			break;

		case "vkCmdSetViewport":
			LoadFunction("vkCmdSetViewport", out vkCmdSetViewport_ptr, instance, invokeErrorCallback);
			if(vkCmdSetViewport_ptr == null)
				return .Err;
			break;

		case "vkCmdSetScissor":
			LoadFunction("vkCmdSetScissor", out vkCmdSetScissor_ptr, instance, invokeErrorCallback);
			if(vkCmdSetScissor_ptr == null)
				return .Err;
			break;

		case "vkCmdSetLineWidth":
			LoadFunction("vkCmdSetLineWidth", out vkCmdSetLineWidth_ptr, instance, invokeErrorCallback);
			if(vkCmdSetLineWidth_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDepthBias":
			LoadFunction("vkCmdSetDepthBias", out vkCmdSetDepthBias_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDepthBias_ptr == null)
				return .Err;
			break;

		case "vkCmdSetBlendConstants":
			LoadFunction("vkCmdSetBlendConstants", out vkCmdSetBlendConstants_ptr, instance, invokeErrorCallback);
			if(vkCmdSetBlendConstants_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDepthBounds":
			LoadFunction("vkCmdSetDepthBounds", out vkCmdSetDepthBounds_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDepthBounds_ptr == null)
				return .Err;
			break;

		case "vkCmdSetStencilCompareMask":
			LoadFunction("vkCmdSetStencilCompareMask", out vkCmdSetStencilCompareMask_ptr, instance, invokeErrorCallback);
			if(vkCmdSetStencilCompareMask_ptr == null)
				return .Err;
			break;

		case "vkCmdSetStencilWriteMask":
			LoadFunction("vkCmdSetStencilWriteMask", out vkCmdSetStencilWriteMask_ptr, instance, invokeErrorCallback);
			if(vkCmdSetStencilWriteMask_ptr == null)
				return .Err;
			break;

		case "vkCmdSetStencilReference":
			LoadFunction("vkCmdSetStencilReference", out vkCmdSetStencilReference_ptr, instance, invokeErrorCallback);
			if(vkCmdSetStencilReference_ptr == null)
				return .Err;
			break;

		case "vkCmdBindIndexBuffer":
			LoadFunction("vkCmdBindIndexBuffer", out vkCmdBindIndexBuffer_ptr, instance, invokeErrorCallback);
			if(vkCmdBindIndexBuffer_ptr == null)
				return .Err;
			break;

		case "vkCmdBindVertexBuffers":
			LoadFunction("vkCmdBindVertexBuffers", out vkCmdBindVertexBuffers_ptr, instance, invokeErrorCallback);
			if(vkCmdBindVertexBuffers_ptr == null)
				return .Err;
			break;

		case "vkCmdDraw":
			LoadFunction("vkCmdDraw", out vkCmdDraw_ptr, instance, invokeErrorCallback);
			if(vkCmdDraw_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawIndexed":
			LoadFunction("vkCmdDrawIndexed", out vkCmdDrawIndexed_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawIndexed_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawIndirect":
			LoadFunction("vkCmdDrawIndirect", out vkCmdDrawIndirect_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawIndirect_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawIndexedIndirect":
			LoadFunction("vkCmdDrawIndexedIndirect", out vkCmdDrawIndexedIndirect_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawIndexedIndirect_ptr == null)
				return .Err;
			break;

		case "vkCmdBlitImage":
			LoadFunction("vkCmdBlitImage", out vkCmdBlitImage_ptr, instance, invokeErrorCallback);
			if(vkCmdBlitImage_ptr == null)
				return .Err;
			break;

		case "vkCmdClearDepthStencilImage":
			LoadFunction("vkCmdClearDepthStencilImage", out vkCmdClearDepthStencilImage_ptr, instance, invokeErrorCallback);
			if(vkCmdClearDepthStencilImage_ptr == null)
				return .Err;
			break;

		case "vkCmdClearAttachments":
			LoadFunction("vkCmdClearAttachments", out vkCmdClearAttachments_ptr, instance, invokeErrorCallback);
			if(vkCmdClearAttachments_ptr == null)
				return .Err;
			break;

		case "vkCmdResolveImage":
			LoadFunction("vkCmdResolveImage", out vkCmdResolveImage_ptr, instance, invokeErrorCallback);
			if(vkCmdResolveImage_ptr == null)
				return .Err;
			break;

		case "vkCmdBeginRenderPass":
			LoadFunction("vkCmdBeginRenderPass", out vkCmdBeginRenderPass_ptr, instance, invokeErrorCallback);
			if(vkCmdBeginRenderPass_ptr == null)
				return .Err;
			break;

		case "vkCmdNextSubpass":
			LoadFunction("vkCmdNextSubpass", out vkCmdNextSubpass_ptr, instance, invokeErrorCallback);
			if(vkCmdNextSubpass_ptr == null)
				return .Err;
			break;

		case "vkCmdEndRenderPass":
			LoadFunction("vkCmdEndRenderPass", out vkCmdEndRenderPass_ptr, instance, invokeErrorCallback);
			if(vkCmdEndRenderPass_ptr == null)
				return .Err;
			break;

		case "vkEnumerateInstanceVersion":
			LoadFunction("vkEnumerateInstanceVersion", out vkEnumerateInstanceVersion_ptr, instance, invokeErrorCallback);
			if(vkEnumerateInstanceVersion_ptr == null)
				return .Err;
			break;

		case "vkBindBufferMemory2":
			LoadFunction("vkBindBufferMemory2", out vkBindBufferMemory2_ptr, instance, invokeErrorCallback);
			if(vkBindBufferMemory2_ptr == null)
				return .Err;
			break;

		case "vkBindImageMemory2":
			LoadFunction("vkBindImageMemory2", out vkBindImageMemory2_ptr, instance, invokeErrorCallback);
			if(vkBindImageMemory2_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceGroupPeerMemoryFeatures":
			LoadFunction("vkGetDeviceGroupPeerMemoryFeatures", out vkGetDeviceGroupPeerMemoryFeatures_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceGroupPeerMemoryFeatures_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDeviceMask":
			LoadFunction("vkCmdSetDeviceMask", out vkCmdSetDeviceMask_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDeviceMask_ptr == null)
				return .Err;
			break;

		case "vkEnumeratePhysicalDeviceGroups":
			LoadFunction("vkEnumeratePhysicalDeviceGroups", out vkEnumeratePhysicalDeviceGroups_ptr, instance, invokeErrorCallback);
			if(vkEnumeratePhysicalDeviceGroups_ptr == null)
				return .Err;
			break;

		case "vkGetImageMemoryRequirements2":
			LoadFunction("vkGetImageMemoryRequirements2", out vkGetImageMemoryRequirements2_ptr, instance, invokeErrorCallback);
			if(vkGetImageMemoryRequirements2_ptr == null)
				return .Err;
			break;

		case "vkGetBufferMemoryRequirements2":
			LoadFunction("vkGetBufferMemoryRequirements2", out vkGetBufferMemoryRequirements2_ptr, instance, invokeErrorCallback);
			if(vkGetBufferMemoryRequirements2_ptr == null)
				return .Err;
			break;

		case "vkGetImageSparseMemoryRequirements2":
			LoadFunction("vkGetImageSparseMemoryRequirements2", out vkGetImageSparseMemoryRequirements2_ptr, instance, invokeErrorCallback);
			if(vkGetImageSparseMemoryRequirements2_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceFeatures2":
			LoadFunction("vkGetPhysicalDeviceFeatures2", out vkGetPhysicalDeviceFeatures2_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceFeatures2_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceProperties2":
			LoadFunction("vkGetPhysicalDeviceProperties2", out vkGetPhysicalDeviceProperties2_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceProperties2_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceFormatProperties2":
			LoadFunction("vkGetPhysicalDeviceFormatProperties2", out vkGetPhysicalDeviceFormatProperties2_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceFormatProperties2_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceImageFormatProperties2":
			LoadFunction("vkGetPhysicalDeviceImageFormatProperties2", out vkGetPhysicalDeviceImageFormatProperties2_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceImageFormatProperties2_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceQueueFamilyProperties2":
			LoadFunction("vkGetPhysicalDeviceQueueFamilyProperties2", out vkGetPhysicalDeviceQueueFamilyProperties2_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceQueueFamilyProperties2_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceMemoryProperties2":
			LoadFunction("vkGetPhysicalDeviceMemoryProperties2", out vkGetPhysicalDeviceMemoryProperties2_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceMemoryProperties2_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceSparseImageFormatProperties2":
			LoadFunction("vkGetPhysicalDeviceSparseImageFormatProperties2", out vkGetPhysicalDeviceSparseImageFormatProperties2_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceSparseImageFormatProperties2_ptr == null)
				return .Err;
			break;

		case "vkTrimCommandPool":
			LoadFunction("vkTrimCommandPool", out vkTrimCommandPool_ptr, instance, invokeErrorCallback);
			if(vkTrimCommandPool_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceQueue2":
			LoadFunction("vkGetDeviceQueue2", out vkGetDeviceQueue2_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceQueue2_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceExternalBufferProperties":
			LoadFunction("vkGetPhysicalDeviceExternalBufferProperties", out vkGetPhysicalDeviceExternalBufferProperties_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceExternalBufferProperties_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceExternalFenceProperties":
			LoadFunction("vkGetPhysicalDeviceExternalFenceProperties", out vkGetPhysicalDeviceExternalFenceProperties_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceExternalFenceProperties_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceExternalSemaphoreProperties":
			LoadFunction("vkGetPhysicalDeviceExternalSemaphoreProperties", out vkGetPhysicalDeviceExternalSemaphoreProperties_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceExternalSemaphoreProperties_ptr == null)
				return .Err;
			break;

		case "vkCmdDispatchBase":
			LoadFunction("vkCmdDispatchBase", out vkCmdDispatchBase_ptr, instance, invokeErrorCallback);
			if(vkCmdDispatchBase_ptr == null)
				return .Err;
			break;

		case "vkCreateDescriptorUpdateTemplate":
			LoadFunction("vkCreateDescriptorUpdateTemplate", out vkCreateDescriptorUpdateTemplate_ptr, instance, invokeErrorCallback);
			if(vkCreateDescriptorUpdateTemplate_ptr == null)
				return .Err;
			break;

		case "vkDestroyDescriptorUpdateTemplate":
			LoadFunction("vkDestroyDescriptorUpdateTemplate", out vkDestroyDescriptorUpdateTemplate_ptr, instance, invokeErrorCallback);
			if(vkDestroyDescriptorUpdateTemplate_ptr == null)
				return .Err;
			break;

		case "vkUpdateDescriptorSetWithTemplate":
			LoadFunction("vkUpdateDescriptorSetWithTemplate", out vkUpdateDescriptorSetWithTemplate_ptr, instance, invokeErrorCallback);
			if(vkUpdateDescriptorSetWithTemplate_ptr == null)
				return .Err;
			break;

		case "vkGetDescriptorSetLayoutSupport":
			LoadFunction("vkGetDescriptorSetLayoutSupport", out vkGetDescriptorSetLayoutSupport_ptr, instance, invokeErrorCallback);
			if(vkGetDescriptorSetLayoutSupport_ptr == null)
				return .Err;
			break;

		case "vkCreateSamplerYcbcrConversion":
			LoadFunction("vkCreateSamplerYcbcrConversion", out vkCreateSamplerYcbcrConversion_ptr, instance, invokeErrorCallback);
			if(vkCreateSamplerYcbcrConversion_ptr == null)
				return .Err;
			break;

		case "vkDestroySamplerYcbcrConversion":
			LoadFunction("vkDestroySamplerYcbcrConversion", out vkDestroySamplerYcbcrConversion_ptr, instance, invokeErrorCallback);
			if(vkDestroySamplerYcbcrConversion_ptr == null)
				return .Err;
			break;

		case "vkResetQueryPool":
			LoadFunction("vkResetQueryPool", out vkResetQueryPool_ptr, instance, invokeErrorCallback);
			if(vkResetQueryPool_ptr == null)
				return .Err;
			break;

		case "vkGetSemaphoreCounterValue":
			LoadFunction("vkGetSemaphoreCounterValue", out vkGetSemaphoreCounterValue_ptr, instance, invokeErrorCallback);
			if(vkGetSemaphoreCounterValue_ptr == null)
				return .Err;
			break;

		case "vkWaitSemaphores":
			LoadFunction("vkWaitSemaphores", out vkWaitSemaphores_ptr, instance, invokeErrorCallback);
			if(vkWaitSemaphores_ptr == null)
				return .Err;
			break;

		case "vkSignalSemaphore":
			LoadFunction("vkSignalSemaphore", out vkSignalSemaphore_ptr, instance, invokeErrorCallback);
			if(vkSignalSemaphore_ptr == null)
				return .Err;
			break;

		case "vkGetBufferDeviceAddress":
			LoadFunction("vkGetBufferDeviceAddress", out vkGetBufferDeviceAddress_ptr, instance, invokeErrorCallback);
			if(vkGetBufferDeviceAddress_ptr == null)
				return .Err;
			break;

		case "vkGetBufferOpaqueCaptureAddress":
			LoadFunction("vkGetBufferOpaqueCaptureAddress", out vkGetBufferOpaqueCaptureAddress_ptr, instance, invokeErrorCallback);
			if(vkGetBufferOpaqueCaptureAddress_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceMemoryOpaqueCaptureAddress":
			LoadFunction("vkGetDeviceMemoryOpaqueCaptureAddress", out vkGetDeviceMemoryOpaqueCaptureAddress_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceMemoryOpaqueCaptureAddress_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawIndirectCount":
			LoadFunction("vkCmdDrawIndirectCount", out vkCmdDrawIndirectCount_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawIndirectCount_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawIndexedIndirectCount":
			LoadFunction("vkCmdDrawIndexedIndirectCount", out vkCmdDrawIndexedIndirectCount_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawIndexedIndirectCount_ptr == null)
				return .Err;
			break;

		case "vkCreateRenderPass2":
			LoadFunction("vkCreateRenderPass2", out vkCreateRenderPass2_ptr, instance, invokeErrorCallback);
			if(vkCreateRenderPass2_ptr == null)
				return .Err;
			break;

		case "vkCmdBeginRenderPass2":
			LoadFunction("vkCmdBeginRenderPass2", out vkCmdBeginRenderPass2_ptr, instance, invokeErrorCallback);
			if(vkCmdBeginRenderPass2_ptr == null)
				return .Err;
			break;

		case "vkCmdNextSubpass2":
			LoadFunction("vkCmdNextSubpass2", out vkCmdNextSubpass2_ptr, instance, invokeErrorCallback);
			if(vkCmdNextSubpass2_ptr == null)
				return .Err;
			break;

		case "vkCmdEndRenderPass2":
			LoadFunction("vkCmdEndRenderPass2", out vkCmdEndRenderPass2_ptr, instance, invokeErrorCallback);
			if(vkCmdEndRenderPass2_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceToolProperties":
			LoadFunction("vkGetPhysicalDeviceToolProperties", out vkGetPhysicalDeviceToolProperties_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceToolProperties_ptr == null)
				return .Err;
			break;

		case "vkCreatePrivateDataSlot":
			LoadFunction("vkCreatePrivateDataSlot", out vkCreatePrivateDataSlot_ptr, instance, invokeErrorCallback);
			if(vkCreatePrivateDataSlot_ptr == null)
				return .Err;
			break;

		case "vkDestroyPrivateDataSlot":
			LoadFunction("vkDestroyPrivateDataSlot", out vkDestroyPrivateDataSlot_ptr, instance, invokeErrorCallback);
			if(vkDestroyPrivateDataSlot_ptr == null)
				return .Err;
			break;

		case "vkSetPrivateData":
			LoadFunction("vkSetPrivateData", out vkSetPrivateData_ptr, instance, invokeErrorCallback);
			if(vkSetPrivateData_ptr == null)
				return .Err;
			break;

		case "vkGetPrivateData":
			LoadFunction("vkGetPrivateData", out vkGetPrivateData_ptr, instance, invokeErrorCallback);
			if(vkGetPrivateData_ptr == null)
				return .Err;
			break;

		case "vkCmdPipelineBarrier2":
			LoadFunction("vkCmdPipelineBarrier2", out vkCmdPipelineBarrier2_ptr, instance, invokeErrorCallback);
			if(vkCmdPipelineBarrier2_ptr == null)
				return .Err;
			break;

		case "vkCmdWriteTimestamp2":
			LoadFunction("vkCmdWriteTimestamp2", out vkCmdWriteTimestamp2_ptr, instance, invokeErrorCallback);
			if(vkCmdWriteTimestamp2_ptr == null)
				return .Err;
			break;

		case "vkQueueSubmit2":
			LoadFunction("vkQueueSubmit2", out vkQueueSubmit2_ptr, instance, invokeErrorCallback);
			if(vkQueueSubmit2_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyBuffer2":
			LoadFunction("vkCmdCopyBuffer2", out vkCmdCopyBuffer2_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyBuffer2_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyImage2":
			LoadFunction("vkCmdCopyImage2", out vkCmdCopyImage2_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyImage2_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyBufferToImage2":
			LoadFunction("vkCmdCopyBufferToImage2", out vkCmdCopyBufferToImage2_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyBufferToImage2_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyImageToBuffer2":
			LoadFunction("vkCmdCopyImageToBuffer2", out vkCmdCopyImageToBuffer2_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyImageToBuffer2_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceBufferMemoryRequirements":
			LoadFunction("vkGetDeviceBufferMemoryRequirements", out vkGetDeviceBufferMemoryRequirements_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceBufferMemoryRequirements_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceImageMemoryRequirements":
			LoadFunction("vkGetDeviceImageMemoryRequirements", out vkGetDeviceImageMemoryRequirements_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceImageMemoryRequirements_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceImageSparseMemoryRequirements":
			LoadFunction("vkGetDeviceImageSparseMemoryRequirements", out vkGetDeviceImageSparseMemoryRequirements_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceImageSparseMemoryRequirements_ptr == null)
				return .Err;
			break;

		case "vkCmdSetEvent2":
			LoadFunction("vkCmdSetEvent2", out vkCmdSetEvent2_ptr, instance, invokeErrorCallback);
			if(vkCmdSetEvent2_ptr == null)
				return .Err;
			break;

		case "vkCmdResetEvent2":
			LoadFunction("vkCmdResetEvent2", out vkCmdResetEvent2_ptr, instance, invokeErrorCallback);
			if(vkCmdResetEvent2_ptr == null)
				return .Err;
			break;

		case "vkCmdWaitEvents2":
			LoadFunction("vkCmdWaitEvents2", out vkCmdWaitEvents2_ptr, instance, invokeErrorCallback);
			if(vkCmdWaitEvents2_ptr == null)
				return .Err;
			break;

		case "vkCmdBlitImage2":
			LoadFunction("vkCmdBlitImage2", out vkCmdBlitImage2_ptr, instance, invokeErrorCallback);
			if(vkCmdBlitImage2_ptr == null)
				return .Err;
			break;

		case "vkCmdResolveImage2":
			LoadFunction("vkCmdResolveImage2", out vkCmdResolveImage2_ptr, instance, invokeErrorCallback);
			if(vkCmdResolveImage2_ptr == null)
				return .Err;
			break;

		case "vkCmdBeginRendering":
			LoadFunction("vkCmdBeginRendering", out vkCmdBeginRendering_ptr, instance, invokeErrorCallback);
			if(vkCmdBeginRendering_ptr == null)
				return .Err;
			break;

		case "vkCmdEndRendering":
			LoadFunction("vkCmdEndRendering", out vkCmdEndRendering_ptr, instance, invokeErrorCallback);
			if(vkCmdEndRendering_ptr == null)
				return .Err;
			break;

		case "vkCmdSetCullMode":
			LoadFunction("vkCmdSetCullMode", out vkCmdSetCullMode_ptr, instance, invokeErrorCallback);
			if(vkCmdSetCullMode_ptr == null)
				return .Err;
			break;

		case "vkCmdSetFrontFace":
			LoadFunction("vkCmdSetFrontFace", out vkCmdSetFrontFace_ptr, instance, invokeErrorCallback);
			if(vkCmdSetFrontFace_ptr == null)
				return .Err;
			break;

		case "vkCmdSetPrimitiveTopology":
			LoadFunction("vkCmdSetPrimitiveTopology", out vkCmdSetPrimitiveTopology_ptr, instance, invokeErrorCallback);
			if(vkCmdSetPrimitiveTopology_ptr == null)
				return .Err;
			break;

		case "vkCmdSetViewportWithCount":
			LoadFunction("vkCmdSetViewportWithCount", out vkCmdSetViewportWithCount_ptr, instance, invokeErrorCallback);
			if(vkCmdSetViewportWithCount_ptr == null)
				return .Err;
			break;

		case "vkCmdSetScissorWithCount":
			LoadFunction("vkCmdSetScissorWithCount", out vkCmdSetScissorWithCount_ptr, instance, invokeErrorCallback);
			if(vkCmdSetScissorWithCount_ptr == null)
				return .Err;
			break;

		case "vkCmdBindVertexBuffers2":
			LoadFunction("vkCmdBindVertexBuffers2", out vkCmdBindVertexBuffers2_ptr, instance, invokeErrorCallback);
			if(vkCmdBindVertexBuffers2_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDepthTestEnable":
			LoadFunction("vkCmdSetDepthTestEnable", out vkCmdSetDepthTestEnable_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDepthTestEnable_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDepthWriteEnable":
			LoadFunction("vkCmdSetDepthWriteEnable", out vkCmdSetDepthWriteEnable_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDepthWriteEnable_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDepthCompareOp":
			LoadFunction("vkCmdSetDepthCompareOp", out vkCmdSetDepthCompareOp_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDepthCompareOp_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDepthBoundsTestEnable":
			LoadFunction("vkCmdSetDepthBoundsTestEnable", out vkCmdSetDepthBoundsTestEnable_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDepthBoundsTestEnable_ptr == null)
				return .Err;
			break;

		case "vkCmdSetStencilTestEnable":
			LoadFunction("vkCmdSetStencilTestEnable", out vkCmdSetStencilTestEnable_ptr, instance, invokeErrorCallback);
			if(vkCmdSetStencilTestEnable_ptr == null)
				return .Err;
			break;

		case "vkCmdSetStencilOp":
			LoadFunction("vkCmdSetStencilOp", out vkCmdSetStencilOp_ptr, instance, invokeErrorCallback);
			if(vkCmdSetStencilOp_ptr == null)
				return .Err;
			break;

		case "vkCmdSetRasterizerDiscardEnable":
			LoadFunction("vkCmdSetRasterizerDiscardEnable", out vkCmdSetRasterizerDiscardEnable_ptr, instance, invokeErrorCallback);
			if(vkCmdSetRasterizerDiscardEnable_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDepthBiasEnable":
			LoadFunction("vkCmdSetDepthBiasEnable", out vkCmdSetDepthBiasEnable_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDepthBiasEnable_ptr == null)
				return .Err;
			break;

		case "vkCmdSetPrimitiveRestartEnable":
			LoadFunction("vkCmdSetPrimitiveRestartEnable", out vkCmdSetPrimitiveRestartEnable_ptr, instance, invokeErrorCallback);
			if(vkCmdSetPrimitiveRestartEnable_ptr == null)
				return .Err;
			break;

		case "vkMapMemory2":
			LoadFunction("vkMapMemory2", out vkMapMemory2_ptr, instance, invokeErrorCallback);
			if(vkMapMemory2_ptr == null)
				return .Err;
			break;

		case "vkUnmapMemory2":
			LoadFunction("vkUnmapMemory2", out vkUnmapMemory2_ptr, instance, invokeErrorCallback);
			if(vkUnmapMemory2_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceImageSubresourceLayout":
			LoadFunction("vkGetDeviceImageSubresourceLayout", out vkGetDeviceImageSubresourceLayout_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceImageSubresourceLayout_ptr == null)
				return .Err;
			break;

		case "vkGetImageSubresourceLayout2":
			LoadFunction("vkGetImageSubresourceLayout2", out vkGetImageSubresourceLayout2_ptr, instance, invokeErrorCallback);
			if(vkGetImageSubresourceLayout2_ptr == null)
				return .Err;
			break;

		case "vkCopyMemoryToImage":
			LoadFunction("vkCopyMemoryToImage", out vkCopyMemoryToImage_ptr, instance, invokeErrorCallback);
			if(vkCopyMemoryToImage_ptr == null)
				return .Err;
			break;

		case "vkCopyImageToMemory":
			LoadFunction("vkCopyImageToMemory", out vkCopyImageToMemory_ptr, instance, invokeErrorCallback);
			if(vkCopyImageToMemory_ptr == null)
				return .Err;
			break;

		case "vkCopyImageToImage":
			LoadFunction("vkCopyImageToImage", out vkCopyImageToImage_ptr, instance, invokeErrorCallback);
			if(vkCopyImageToImage_ptr == null)
				return .Err;
			break;

		case "vkTransitionImageLayout":
			LoadFunction("vkTransitionImageLayout", out vkTransitionImageLayout_ptr, instance, invokeErrorCallback);
			if(vkTransitionImageLayout_ptr == null)
				return .Err;
			break;

		case "vkCmdPushDescriptorSet":
			LoadFunction("vkCmdPushDescriptorSet", out vkCmdPushDescriptorSet_ptr, instance, invokeErrorCallback);
			if(vkCmdPushDescriptorSet_ptr == null)
				return .Err;
			break;

		case "vkCmdPushDescriptorSetWithTemplate":
			LoadFunction("vkCmdPushDescriptorSetWithTemplate", out vkCmdPushDescriptorSetWithTemplate_ptr, instance, invokeErrorCallback);
			if(vkCmdPushDescriptorSetWithTemplate_ptr == null)
				return .Err;
			break;

		case "vkCmdBindDescriptorSets2":
			LoadFunction("vkCmdBindDescriptorSets2", out vkCmdBindDescriptorSets2_ptr, instance, invokeErrorCallback);
			if(vkCmdBindDescriptorSets2_ptr == null)
				return .Err;
			break;

		case "vkCmdPushConstants2":
			LoadFunction("vkCmdPushConstants2", out vkCmdPushConstants2_ptr, instance, invokeErrorCallback);
			if(vkCmdPushConstants2_ptr == null)
				return .Err;
			break;

		case "vkCmdPushDescriptorSet2":
			LoadFunction("vkCmdPushDescriptorSet2", out vkCmdPushDescriptorSet2_ptr, instance, invokeErrorCallback);
			if(vkCmdPushDescriptorSet2_ptr == null)
				return .Err;
			break;

		case "vkCmdPushDescriptorSetWithTemplate2":
			LoadFunction("vkCmdPushDescriptorSetWithTemplate2", out vkCmdPushDescriptorSetWithTemplate2_ptr, instance, invokeErrorCallback);
			if(vkCmdPushDescriptorSetWithTemplate2_ptr == null)
				return .Err;
			break;

		case "vkCmdSetLineStipple":
			LoadFunction("vkCmdSetLineStipple", out vkCmdSetLineStipple_ptr, instance, invokeErrorCallback);
			if(vkCmdSetLineStipple_ptr == null)
				return .Err;
			break;

		case "vkCmdBindIndexBuffer2":
			LoadFunction("vkCmdBindIndexBuffer2", out vkCmdBindIndexBuffer2_ptr, instance, invokeErrorCallback);
			if(vkCmdBindIndexBuffer2_ptr == null)
				return .Err;
			break;

		case "vkGetRenderingAreaGranularity":
			LoadFunction("vkGetRenderingAreaGranularity", out vkGetRenderingAreaGranularity_ptr, instance, invokeErrorCallback);
			if(vkGetRenderingAreaGranularity_ptr == null)
				return .Err;
			break;

		case "vkCmdSetRenderingAttachmentLocations":
			LoadFunction("vkCmdSetRenderingAttachmentLocations", out vkCmdSetRenderingAttachmentLocations_ptr, instance, invokeErrorCallback);
			if(vkCmdSetRenderingAttachmentLocations_ptr == null)
				return .Err;
			break;

		case "vkCmdSetRenderingInputAttachmentIndices":
			LoadFunction("vkCmdSetRenderingInputAttachmentIndices", out vkCmdSetRenderingInputAttachmentIndices_ptr, instance, invokeErrorCallback);
			if(vkCmdSetRenderingInputAttachmentIndices_ptr == null)
				return .Err;
			break;

		case "vkGetCommandPoolMemoryConsumption":
			LoadFunction("vkGetCommandPoolMemoryConsumption", out vkGetCommandPoolMemoryConsumption_ptr, instance, invokeErrorCallback);
			if(vkGetCommandPoolMemoryConsumption_ptr == null)
				return .Err;
			break;

		case "vkGetFaultData":
			LoadFunction("vkGetFaultData", out vkGetFaultData_ptr, instance, invokeErrorCallback);
			if(vkGetFaultData_ptr == null)
				return .Err;
			break;

		case "vkDestroySurfaceKHR":
			LoadFunction("vkDestroySurfaceKHR", out vkDestroySurfaceKHR_ptr, instance, invokeErrorCallback);
			if(vkDestroySurfaceKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceSurfaceSupportKHR":
			LoadFunction("vkGetPhysicalDeviceSurfaceSupportKHR", out vkGetPhysicalDeviceSurfaceSupportKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceSurfaceSupportKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceSurfaceCapabilitiesKHR":
			LoadFunction("vkGetPhysicalDeviceSurfaceCapabilitiesKHR", out vkGetPhysicalDeviceSurfaceCapabilitiesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceSurfaceCapabilitiesKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceSurfaceFormatsKHR":
			LoadFunction("vkGetPhysicalDeviceSurfaceFormatsKHR", out vkGetPhysicalDeviceSurfaceFormatsKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceSurfaceFormatsKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceSurfacePresentModesKHR":
			LoadFunction("vkGetPhysicalDeviceSurfacePresentModesKHR", out vkGetPhysicalDeviceSurfacePresentModesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceSurfacePresentModesKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateSwapchainKHR":
			LoadFunction("vkCreateSwapchainKHR", out vkCreateSwapchainKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateSwapchainKHR_ptr == null)
				return .Err;
			break;

		case "vkDestroySwapchainKHR":
			LoadFunction("vkDestroySwapchainKHR", out vkDestroySwapchainKHR_ptr, instance, invokeErrorCallback);
			if(vkDestroySwapchainKHR_ptr == null)
				return .Err;
			break;

		case "vkGetSwapchainImagesKHR":
			LoadFunction("vkGetSwapchainImagesKHR", out vkGetSwapchainImagesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetSwapchainImagesKHR_ptr == null)
				return .Err;
			break;

		case "vkAcquireNextImageKHR":
			LoadFunction("vkAcquireNextImageKHR", out vkAcquireNextImageKHR_ptr, instance, invokeErrorCallback);
			if(vkAcquireNextImageKHR_ptr == null)
				return .Err;
			break;

		case "vkQueuePresentKHR":
			LoadFunction("vkQueuePresentKHR", out vkQueuePresentKHR_ptr, instance, invokeErrorCallback);
			if(vkQueuePresentKHR_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceGroupPresentCapabilitiesKHR":
			LoadFunction("vkGetDeviceGroupPresentCapabilitiesKHR", out vkGetDeviceGroupPresentCapabilitiesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceGroupPresentCapabilitiesKHR_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceGroupSurfacePresentModesKHR":
			LoadFunction("vkGetDeviceGroupSurfacePresentModesKHR", out vkGetDeviceGroupSurfacePresentModesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceGroupSurfacePresentModesKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDevicePresentRectanglesKHR":
			LoadFunction("vkGetPhysicalDevicePresentRectanglesKHR", out vkGetPhysicalDevicePresentRectanglesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDevicePresentRectanglesKHR_ptr == null)
				return .Err;
			break;

		case "vkAcquireNextImage2KHR":
			LoadFunction("vkAcquireNextImage2KHR", out vkAcquireNextImage2KHR_ptr, instance, invokeErrorCallback);
			if(vkAcquireNextImage2KHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceDisplayPropertiesKHR":
			LoadFunction("vkGetPhysicalDeviceDisplayPropertiesKHR", out vkGetPhysicalDeviceDisplayPropertiesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceDisplayPropertiesKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceDisplayPlanePropertiesKHR":
			LoadFunction("vkGetPhysicalDeviceDisplayPlanePropertiesKHR", out vkGetPhysicalDeviceDisplayPlanePropertiesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceDisplayPlanePropertiesKHR_ptr == null)
				return .Err;
			break;

		case "vkGetDisplayPlaneSupportedDisplaysKHR":
			LoadFunction("vkGetDisplayPlaneSupportedDisplaysKHR", out vkGetDisplayPlaneSupportedDisplaysKHR_ptr, instance, invokeErrorCallback);
			if(vkGetDisplayPlaneSupportedDisplaysKHR_ptr == null)
				return .Err;
			break;

		case "vkGetDisplayModePropertiesKHR":
			LoadFunction("vkGetDisplayModePropertiesKHR", out vkGetDisplayModePropertiesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetDisplayModePropertiesKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateDisplayModeKHR":
			LoadFunction("vkCreateDisplayModeKHR", out vkCreateDisplayModeKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateDisplayModeKHR_ptr == null)
				return .Err;
			break;

		case "vkGetDisplayPlaneCapabilitiesKHR":
			LoadFunction("vkGetDisplayPlaneCapabilitiesKHR", out vkGetDisplayPlaneCapabilitiesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetDisplayPlaneCapabilitiesKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateDisplayPlaneSurfaceKHR":
			LoadFunction("vkCreateDisplayPlaneSurfaceKHR", out vkCreateDisplayPlaneSurfaceKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateDisplayPlaneSurfaceKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateSharedSwapchainsKHR":
			LoadFunction("vkCreateSharedSwapchainsKHR", out vkCreateSharedSwapchainsKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateSharedSwapchainsKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateXlibSurfaceKHR":
			LoadFunction("vkCreateXlibSurfaceKHR", out vkCreateXlibSurfaceKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateXlibSurfaceKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceXlibPresentationSupportKHR":
			LoadFunction("vkGetPhysicalDeviceXlibPresentationSupportKHR", out vkGetPhysicalDeviceXlibPresentationSupportKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceXlibPresentationSupportKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateXcbSurfaceKHR":
			LoadFunction("vkCreateXcbSurfaceKHR", out vkCreateXcbSurfaceKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateXcbSurfaceKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceXcbPresentationSupportKHR":
			LoadFunction("vkGetPhysicalDeviceXcbPresentationSupportKHR", out vkGetPhysicalDeviceXcbPresentationSupportKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceXcbPresentationSupportKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateWaylandSurfaceKHR":
			LoadFunction("vkCreateWaylandSurfaceKHR", out vkCreateWaylandSurfaceKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateWaylandSurfaceKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceWaylandPresentationSupportKHR":
			LoadFunction("vkGetPhysicalDeviceWaylandPresentationSupportKHR", out vkGetPhysicalDeviceWaylandPresentationSupportKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceWaylandPresentationSupportKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateAndroidSurfaceKHR":
			LoadFunction("vkCreateAndroidSurfaceKHR", out vkCreateAndroidSurfaceKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateAndroidSurfaceKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateWin32SurfaceKHR":
			LoadFunction("vkCreateWin32SurfaceKHR", out vkCreateWin32SurfaceKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateWin32SurfaceKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceWin32PresentationSupportKHR":
			LoadFunction("vkGetPhysicalDeviceWin32PresentationSupportKHR", out vkGetPhysicalDeviceWin32PresentationSupportKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceWin32PresentationSupportKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateDebugReportCallbackEXT":
			LoadFunction("vkCreateDebugReportCallbackEXT", out vkCreateDebugReportCallbackEXT_ptr, instance, invokeErrorCallback);
			if(vkCreateDebugReportCallbackEXT_ptr == null)
				return .Err;
			break;

		case "vkDestroyDebugReportCallbackEXT":
			LoadFunction("vkDestroyDebugReportCallbackEXT", out vkDestroyDebugReportCallbackEXT_ptr, instance, invokeErrorCallback);
			if(vkDestroyDebugReportCallbackEXT_ptr == null)
				return .Err;
			break;

		case "vkDebugReportMessageEXT":
			LoadFunction("vkDebugReportMessageEXT", out vkDebugReportMessageEXT_ptr, instance, invokeErrorCallback);
			if(vkDebugReportMessageEXT_ptr == null)
				return .Err;
			break;

		case "vkDebugMarkerSetObjectTagEXT":
			LoadFunction("vkDebugMarkerSetObjectTagEXT", out vkDebugMarkerSetObjectTagEXT_ptr, instance, invokeErrorCallback);
			if(vkDebugMarkerSetObjectTagEXT_ptr == null)
				return .Err;
			break;

		case "vkDebugMarkerSetObjectNameEXT":
			LoadFunction("vkDebugMarkerSetObjectNameEXT", out vkDebugMarkerSetObjectNameEXT_ptr, instance, invokeErrorCallback);
			if(vkDebugMarkerSetObjectNameEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdDebugMarkerBeginEXT":
			LoadFunction("vkCmdDebugMarkerBeginEXT", out vkCmdDebugMarkerBeginEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdDebugMarkerBeginEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdDebugMarkerEndEXT":
			LoadFunction("vkCmdDebugMarkerEndEXT", out vkCmdDebugMarkerEndEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdDebugMarkerEndEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdDebugMarkerInsertEXT":
			LoadFunction("vkCmdDebugMarkerInsertEXT", out vkCmdDebugMarkerInsertEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdDebugMarkerInsertEXT_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceVideoCapabilitiesKHR":
			LoadFunction("vkGetPhysicalDeviceVideoCapabilitiesKHR", out vkGetPhysicalDeviceVideoCapabilitiesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceVideoCapabilitiesKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceVideoFormatPropertiesKHR":
			LoadFunction("vkGetPhysicalDeviceVideoFormatPropertiesKHR", out vkGetPhysicalDeviceVideoFormatPropertiesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceVideoFormatPropertiesKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateVideoSessionKHR":
			LoadFunction("vkCreateVideoSessionKHR", out vkCreateVideoSessionKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateVideoSessionKHR_ptr == null)
				return .Err;
			break;

		case "vkDestroyVideoSessionKHR":
			LoadFunction("vkDestroyVideoSessionKHR", out vkDestroyVideoSessionKHR_ptr, instance, invokeErrorCallback);
			if(vkDestroyVideoSessionKHR_ptr == null)
				return .Err;
			break;

		case "vkGetVideoSessionMemoryRequirementsKHR":
			LoadFunction("vkGetVideoSessionMemoryRequirementsKHR", out vkGetVideoSessionMemoryRequirementsKHR_ptr, instance, invokeErrorCallback);
			if(vkGetVideoSessionMemoryRequirementsKHR_ptr == null)
				return .Err;
			break;

		case "vkBindVideoSessionMemoryKHR":
			LoadFunction("vkBindVideoSessionMemoryKHR", out vkBindVideoSessionMemoryKHR_ptr, instance, invokeErrorCallback);
			if(vkBindVideoSessionMemoryKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateVideoSessionParametersKHR":
			LoadFunction("vkCreateVideoSessionParametersKHR", out vkCreateVideoSessionParametersKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateVideoSessionParametersKHR_ptr == null)
				return .Err;
			break;

		case "vkUpdateVideoSessionParametersKHR":
			LoadFunction("vkUpdateVideoSessionParametersKHR", out vkUpdateVideoSessionParametersKHR_ptr, instance, invokeErrorCallback);
			if(vkUpdateVideoSessionParametersKHR_ptr == null)
				return .Err;
			break;

		case "vkDestroyVideoSessionParametersKHR":
			LoadFunction("vkDestroyVideoSessionParametersKHR", out vkDestroyVideoSessionParametersKHR_ptr, instance, invokeErrorCallback);
			if(vkDestroyVideoSessionParametersKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdBeginVideoCodingKHR":
			LoadFunction("vkCmdBeginVideoCodingKHR", out vkCmdBeginVideoCodingKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdBeginVideoCodingKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdEndVideoCodingKHR":
			LoadFunction("vkCmdEndVideoCodingKHR", out vkCmdEndVideoCodingKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdEndVideoCodingKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdControlVideoCodingKHR":
			LoadFunction("vkCmdControlVideoCodingKHR", out vkCmdControlVideoCodingKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdControlVideoCodingKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdDecodeVideoKHR":
			LoadFunction("vkCmdDecodeVideoKHR", out vkCmdDecodeVideoKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdDecodeVideoKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdBindTransformFeedbackBuffersEXT":
			LoadFunction("vkCmdBindTransformFeedbackBuffersEXT", out vkCmdBindTransformFeedbackBuffersEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdBindTransformFeedbackBuffersEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdBeginTransformFeedbackEXT":
			LoadFunction("vkCmdBeginTransformFeedbackEXT", out vkCmdBeginTransformFeedbackEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdBeginTransformFeedbackEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdEndTransformFeedbackEXT":
			LoadFunction("vkCmdEndTransformFeedbackEXT", out vkCmdEndTransformFeedbackEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdEndTransformFeedbackEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdBeginQueryIndexedEXT":
			LoadFunction("vkCmdBeginQueryIndexedEXT", out vkCmdBeginQueryIndexedEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdBeginQueryIndexedEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdEndQueryIndexedEXT":
			LoadFunction("vkCmdEndQueryIndexedEXT", out vkCmdEndQueryIndexedEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdEndQueryIndexedEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawIndirectByteCountEXT":
			LoadFunction("vkCmdDrawIndirectByteCountEXT", out vkCmdDrawIndirectByteCountEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawIndirectByteCountEXT_ptr == null)
				return .Err;
			break;

		case "vkCreateCuModuleNVX":
			LoadFunction("vkCreateCuModuleNVX", out vkCreateCuModuleNVX_ptr, instance, invokeErrorCallback);
			if(vkCreateCuModuleNVX_ptr == null)
				return .Err;
			break;

		case "vkCreateCuFunctionNVX":
			LoadFunction("vkCreateCuFunctionNVX", out vkCreateCuFunctionNVX_ptr, instance, invokeErrorCallback);
			if(vkCreateCuFunctionNVX_ptr == null)
				return .Err;
			break;

		case "vkDestroyCuModuleNVX":
			LoadFunction("vkDestroyCuModuleNVX", out vkDestroyCuModuleNVX_ptr, instance, invokeErrorCallback);
			if(vkDestroyCuModuleNVX_ptr == null)
				return .Err;
			break;

		case "vkDestroyCuFunctionNVX":
			LoadFunction("vkDestroyCuFunctionNVX", out vkDestroyCuFunctionNVX_ptr, instance, invokeErrorCallback);
			if(vkDestroyCuFunctionNVX_ptr == null)
				return .Err;
			break;

		case "vkCmdCuLaunchKernelNVX":
			LoadFunction("vkCmdCuLaunchKernelNVX", out vkCmdCuLaunchKernelNVX_ptr, instance, invokeErrorCallback);
			if(vkCmdCuLaunchKernelNVX_ptr == null)
				return .Err;
			break;

		case "vkGetImageViewHandleNVX":
			LoadFunction("vkGetImageViewHandleNVX", out vkGetImageViewHandleNVX_ptr, instance, invokeErrorCallback);
			if(vkGetImageViewHandleNVX_ptr == null)
				return .Err;
			break;

		case "vkGetImageViewHandle64NVX":
			LoadFunction("vkGetImageViewHandle64NVX", out vkGetImageViewHandle64NVX_ptr, instance, invokeErrorCallback);
			if(vkGetImageViewHandle64NVX_ptr == null)
				return .Err;
			break;

		case "vkGetImageViewAddressNVX":
			LoadFunction("vkGetImageViewAddressNVX", out vkGetImageViewAddressNVX_ptr, instance, invokeErrorCallback);
			if(vkGetImageViewAddressNVX_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceCombinedImageSamplerIndexNVX":
			LoadFunction("vkGetDeviceCombinedImageSamplerIndexNVX", out vkGetDeviceCombinedImageSamplerIndexNVX_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceCombinedImageSamplerIndexNVX_ptr == null)
				return .Err;
			break;

		case "vkGetShaderInfoAMD":
			LoadFunction("vkGetShaderInfoAMD", out vkGetShaderInfoAMD_ptr, instance, invokeErrorCallback);
			if(vkGetShaderInfoAMD_ptr == null)
				return .Err;
			break;

		case "vkCreateStreamDescriptorSurfaceGGP":
			LoadFunction("vkCreateStreamDescriptorSurfaceGGP", out vkCreateStreamDescriptorSurfaceGGP_ptr, instance, invokeErrorCallback);
			if(vkCreateStreamDescriptorSurfaceGGP_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceExternalImageFormatPropertiesNV":
			LoadFunction("vkGetPhysicalDeviceExternalImageFormatPropertiesNV", out vkGetPhysicalDeviceExternalImageFormatPropertiesNV_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceExternalImageFormatPropertiesNV_ptr == null)
				return .Err;
			break;

		case "vkGetMemoryWin32HandleNV":
			LoadFunction("vkGetMemoryWin32HandleNV", out vkGetMemoryWin32HandleNV_ptr, instance, invokeErrorCallback);
			if(vkGetMemoryWin32HandleNV_ptr == null)
				return .Err;
			break;

		case "vkCreateViSurfaceNN":
			LoadFunction("vkCreateViSurfaceNN", out vkCreateViSurfaceNN_ptr, instance, invokeErrorCallback);
			if(vkCreateViSurfaceNN_ptr == null)
				return .Err;
			break;

		case "vkGetMemoryWin32HandleKHR":
			LoadFunction("vkGetMemoryWin32HandleKHR", out vkGetMemoryWin32HandleKHR_ptr, instance, invokeErrorCallback);
			if(vkGetMemoryWin32HandleKHR_ptr == null)
				return .Err;
			break;

		case "vkGetMemoryWin32HandlePropertiesKHR":
			LoadFunction("vkGetMemoryWin32HandlePropertiesKHR", out vkGetMemoryWin32HandlePropertiesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetMemoryWin32HandlePropertiesKHR_ptr == null)
				return .Err;
			break;

		case "vkGetMemoryFdKHR":
			LoadFunction("vkGetMemoryFdKHR", out vkGetMemoryFdKHR_ptr, instance, invokeErrorCallback);
			if(vkGetMemoryFdKHR_ptr == null)
				return .Err;
			break;

		case "vkGetMemoryFdPropertiesKHR":
			LoadFunction("vkGetMemoryFdPropertiesKHR", out vkGetMemoryFdPropertiesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetMemoryFdPropertiesKHR_ptr == null)
				return .Err;
			break;

		case "vkImportSemaphoreWin32HandleKHR":
			LoadFunction("vkImportSemaphoreWin32HandleKHR", out vkImportSemaphoreWin32HandleKHR_ptr, instance, invokeErrorCallback);
			if(vkImportSemaphoreWin32HandleKHR_ptr == null)
				return .Err;
			break;

		case "vkGetSemaphoreWin32HandleKHR":
			LoadFunction("vkGetSemaphoreWin32HandleKHR", out vkGetSemaphoreWin32HandleKHR_ptr, instance, invokeErrorCallback);
			if(vkGetSemaphoreWin32HandleKHR_ptr == null)
				return .Err;
			break;

		case "vkImportSemaphoreFdKHR":
			LoadFunction("vkImportSemaphoreFdKHR", out vkImportSemaphoreFdKHR_ptr, instance, invokeErrorCallback);
			if(vkImportSemaphoreFdKHR_ptr == null)
				return .Err;
			break;

		case "vkGetSemaphoreFdKHR":
			LoadFunction("vkGetSemaphoreFdKHR", out vkGetSemaphoreFdKHR_ptr, instance, invokeErrorCallback);
			if(vkGetSemaphoreFdKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdBeginConditionalRenderingEXT":
			LoadFunction("vkCmdBeginConditionalRenderingEXT", out vkCmdBeginConditionalRenderingEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdBeginConditionalRenderingEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdEndConditionalRenderingEXT":
			LoadFunction("vkCmdEndConditionalRenderingEXT", out vkCmdEndConditionalRenderingEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdEndConditionalRenderingEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetViewportWScalingNV":
			LoadFunction("vkCmdSetViewportWScalingNV", out vkCmdSetViewportWScalingNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetViewportWScalingNV_ptr == null)
				return .Err;
			break;

		case "vkReleaseDisplayEXT":
			LoadFunction("vkReleaseDisplayEXT", out vkReleaseDisplayEXT_ptr, instance, invokeErrorCallback);
			if(vkReleaseDisplayEXT_ptr == null)
				return .Err;
			break;

		case "vkAcquireXlibDisplayEXT":
			LoadFunction("vkAcquireXlibDisplayEXT", out vkAcquireXlibDisplayEXT_ptr, instance, invokeErrorCallback);
			if(vkAcquireXlibDisplayEXT_ptr == null)
				return .Err;
			break;

		case "vkGetRandROutputDisplayEXT":
			LoadFunction("vkGetRandROutputDisplayEXT", out vkGetRandROutputDisplayEXT_ptr, instance, invokeErrorCallback);
			if(vkGetRandROutputDisplayEXT_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceSurfaceCapabilities2EXT":
			LoadFunction("vkGetPhysicalDeviceSurfaceCapabilities2EXT", out vkGetPhysicalDeviceSurfaceCapabilities2EXT_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceSurfaceCapabilities2EXT_ptr == null)
				return .Err;
			break;

		case "vkDisplayPowerControlEXT":
			LoadFunction("vkDisplayPowerControlEXT", out vkDisplayPowerControlEXT_ptr, instance, invokeErrorCallback);
			if(vkDisplayPowerControlEXT_ptr == null)
				return .Err;
			break;

		case "vkRegisterDeviceEventEXT":
			LoadFunction("vkRegisterDeviceEventEXT", out vkRegisterDeviceEventEXT_ptr, instance, invokeErrorCallback);
			if(vkRegisterDeviceEventEXT_ptr == null)
				return .Err;
			break;

		case "vkRegisterDisplayEventEXT":
			LoadFunction("vkRegisterDisplayEventEXT", out vkRegisterDisplayEventEXT_ptr, instance, invokeErrorCallback);
			if(vkRegisterDisplayEventEXT_ptr == null)
				return .Err;
			break;

		case "vkGetSwapchainCounterEXT":
			LoadFunction("vkGetSwapchainCounterEXT", out vkGetSwapchainCounterEXT_ptr, instance, invokeErrorCallback);
			if(vkGetSwapchainCounterEXT_ptr == null)
				return .Err;
			break;

		case "vkGetRefreshCycleDurationGOOGLE":
			LoadFunction("vkGetRefreshCycleDurationGOOGLE", out vkGetRefreshCycleDurationGOOGLE_ptr, instance, invokeErrorCallback);
			if(vkGetRefreshCycleDurationGOOGLE_ptr == null)
				return .Err;
			break;

		case "vkGetPastPresentationTimingGOOGLE":
			LoadFunction("vkGetPastPresentationTimingGOOGLE", out vkGetPastPresentationTimingGOOGLE_ptr, instance, invokeErrorCallback);
			if(vkGetPastPresentationTimingGOOGLE_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDiscardRectangleEXT":
			LoadFunction("vkCmdSetDiscardRectangleEXT", out vkCmdSetDiscardRectangleEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDiscardRectangleEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDiscardRectangleEnableEXT":
			LoadFunction("vkCmdSetDiscardRectangleEnableEXT", out vkCmdSetDiscardRectangleEnableEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDiscardRectangleEnableEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDiscardRectangleModeEXT":
			LoadFunction("vkCmdSetDiscardRectangleModeEXT", out vkCmdSetDiscardRectangleModeEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDiscardRectangleModeEXT_ptr == null)
				return .Err;
			break;

		case "vkSetHdrMetadataEXT":
			LoadFunction("vkSetHdrMetadataEXT", out vkSetHdrMetadataEXT_ptr, instance, invokeErrorCallback);
			if(vkSetHdrMetadataEXT_ptr == null)
				return .Err;
			break;

		case "vkGetSwapchainStatusKHR":
			LoadFunction("vkGetSwapchainStatusKHR", out vkGetSwapchainStatusKHR_ptr, instance, invokeErrorCallback);
			if(vkGetSwapchainStatusKHR_ptr == null)
				return .Err;
			break;

		case "vkImportFenceWin32HandleKHR":
			LoadFunction("vkImportFenceWin32HandleKHR", out vkImportFenceWin32HandleKHR_ptr, instance, invokeErrorCallback);
			if(vkImportFenceWin32HandleKHR_ptr == null)
				return .Err;
			break;

		case "vkGetFenceWin32HandleKHR":
			LoadFunction("vkGetFenceWin32HandleKHR", out vkGetFenceWin32HandleKHR_ptr, instance, invokeErrorCallback);
			if(vkGetFenceWin32HandleKHR_ptr == null)
				return .Err;
			break;

		case "vkImportFenceFdKHR":
			LoadFunction("vkImportFenceFdKHR", out vkImportFenceFdKHR_ptr, instance, invokeErrorCallback);
			if(vkImportFenceFdKHR_ptr == null)
				return .Err;
			break;

		case "vkGetFenceFdKHR":
			LoadFunction("vkGetFenceFdKHR", out vkGetFenceFdKHR_ptr, instance, invokeErrorCallback);
			if(vkGetFenceFdKHR_ptr == null)
				return .Err;
			break;

		case "vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR":
			LoadFunction("vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR", out vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR_ptr, instance, invokeErrorCallback);
			if(vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR":
			LoadFunction("vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR", out vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR_ptr == null)
				return .Err;
			break;

		case "vkAcquireProfilingLockKHR":
			LoadFunction("vkAcquireProfilingLockKHR", out vkAcquireProfilingLockKHR_ptr, instance, invokeErrorCallback);
			if(vkAcquireProfilingLockKHR_ptr == null)
				return .Err;
			break;

		case "vkReleaseProfilingLockKHR":
			LoadFunction("vkReleaseProfilingLockKHR", out vkReleaseProfilingLockKHR_ptr, instance, invokeErrorCallback);
			if(vkReleaseProfilingLockKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceSurfaceCapabilities2KHR":
			LoadFunction("vkGetPhysicalDeviceSurfaceCapabilities2KHR", out vkGetPhysicalDeviceSurfaceCapabilities2KHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceSurfaceCapabilities2KHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceSurfaceFormats2KHR":
			LoadFunction("vkGetPhysicalDeviceSurfaceFormats2KHR", out vkGetPhysicalDeviceSurfaceFormats2KHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceSurfaceFormats2KHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceDisplayProperties2KHR":
			LoadFunction("vkGetPhysicalDeviceDisplayProperties2KHR", out vkGetPhysicalDeviceDisplayProperties2KHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceDisplayProperties2KHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceDisplayPlaneProperties2KHR":
			LoadFunction("vkGetPhysicalDeviceDisplayPlaneProperties2KHR", out vkGetPhysicalDeviceDisplayPlaneProperties2KHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceDisplayPlaneProperties2KHR_ptr == null)
				return .Err;
			break;

		case "vkGetDisplayModeProperties2KHR":
			LoadFunction("vkGetDisplayModeProperties2KHR", out vkGetDisplayModeProperties2KHR_ptr, instance, invokeErrorCallback);
			if(vkGetDisplayModeProperties2KHR_ptr == null)
				return .Err;
			break;

		case "vkGetDisplayPlaneCapabilities2KHR":
			LoadFunction("vkGetDisplayPlaneCapabilities2KHR", out vkGetDisplayPlaneCapabilities2KHR_ptr, instance, invokeErrorCallback);
			if(vkGetDisplayPlaneCapabilities2KHR_ptr == null)
				return .Err;
			break;

		case "vkCreateIOSSurfaceMVK":
			LoadFunction("vkCreateIOSSurfaceMVK", out vkCreateIOSSurfaceMVK_ptr, instance, invokeErrorCallback);
			if(vkCreateIOSSurfaceMVK_ptr == null)
				return .Err;
			break;

		case "vkCreateMacOSSurfaceMVK":
			LoadFunction("vkCreateMacOSSurfaceMVK", out vkCreateMacOSSurfaceMVK_ptr, instance, invokeErrorCallback);
			if(vkCreateMacOSSurfaceMVK_ptr == null)
				return .Err;
			break;

		case "vkSetDebugUtilsObjectNameEXT":
			LoadFunction("vkSetDebugUtilsObjectNameEXT", out vkSetDebugUtilsObjectNameEXT_ptr, instance, invokeErrorCallback);
			if(vkSetDebugUtilsObjectNameEXT_ptr == null)
				return .Err;
			break;

		case "vkSetDebugUtilsObjectTagEXT":
			LoadFunction("vkSetDebugUtilsObjectTagEXT", out vkSetDebugUtilsObjectTagEXT_ptr, instance, invokeErrorCallback);
			if(vkSetDebugUtilsObjectTagEXT_ptr == null)
				return .Err;
			break;

		case "vkQueueBeginDebugUtilsLabelEXT":
			LoadFunction("vkQueueBeginDebugUtilsLabelEXT", out vkQueueBeginDebugUtilsLabelEXT_ptr, instance, invokeErrorCallback);
			if(vkQueueBeginDebugUtilsLabelEXT_ptr == null)
				return .Err;
			break;

		case "vkQueueEndDebugUtilsLabelEXT":
			LoadFunction("vkQueueEndDebugUtilsLabelEXT", out vkQueueEndDebugUtilsLabelEXT_ptr, instance, invokeErrorCallback);
			if(vkQueueEndDebugUtilsLabelEXT_ptr == null)
				return .Err;
			break;

		case "vkQueueInsertDebugUtilsLabelEXT":
			LoadFunction("vkQueueInsertDebugUtilsLabelEXT", out vkQueueInsertDebugUtilsLabelEXT_ptr, instance, invokeErrorCallback);
			if(vkQueueInsertDebugUtilsLabelEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdBeginDebugUtilsLabelEXT":
			LoadFunction("vkCmdBeginDebugUtilsLabelEXT", out vkCmdBeginDebugUtilsLabelEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdBeginDebugUtilsLabelEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdEndDebugUtilsLabelEXT":
			LoadFunction("vkCmdEndDebugUtilsLabelEXT", out vkCmdEndDebugUtilsLabelEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdEndDebugUtilsLabelEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdInsertDebugUtilsLabelEXT":
			LoadFunction("vkCmdInsertDebugUtilsLabelEXT", out vkCmdInsertDebugUtilsLabelEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdInsertDebugUtilsLabelEXT_ptr == null)
				return .Err;
			break;

		case "vkCreateDebugUtilsMessengerEXT":
			LoadFunction("vkCreateDebugUtilsMessengerEXT", out vkCreateDebugUtilsMessengerEXT_ptr, instance, invokeErrorCallback);
			if(vkCreateDebugUtilsMessengerEXT_ptr == null)
				return .Err;
			break;

		case "vkDestroyDebugUtilsMessengerEXT":
			LoadFunction("vkDestroyDebugUtilsMessengerEXT", out vkDestroyDebugUtilsMessengerEXT_ptr, instance, invokeErrorCallback);
			if(vkDestroyDebugUtilsMessengerEXT_ptr == null)
				return .Err;
			break;

		case "vkSubmitDebugUtilsMessageEXT":
			LoadFunction("vkSubmitDebugUtilsMessageEXT", out vkSubmitDebugUtilsMessageEXT_ptr, instance, invokeErrorCallback);
			if(vkSubmitDebugUtilsMessageEXT_ptr == null)
				return .Err;
			break;

		case "vkGetAndroidHardwareBufferPropertiesANDROID":
			LoadFunction("vkGetAndroidHardwareBufferPropertiesANDROID", out vkGetAndroidHardwareBufferPropertiesANDROID_ptr, instance, invokeErrorCallback);
			if(vkGetAndroidHardwareBufferPropertiesANDROID_ptr == null)
				return .Err;
			break;

		case "vkGetMemoryAndroidHardwareBufferANDROID":
			LoadFunction("vkGetMemoryAndroidHardwareBufferANDROID", out vkGetMemoryAndroidHardwareBufferANDROID_ptr, instance, invokeErrorCallback);
			if(vkGetMemoryAndroidHardwareBufferANDROID_ptr == null)
				return .Err;
			break;

		case "vkCreateExecutionGraphPipelinesAMDX":
			LoadFunction("vkCreateExecutionGraphPipelinesAMDX", out vkCreateExecutionGraphPipelinesAMDX_ptr, instance, invokeErrorCallback);
			if(vkCreateExecutionGraphPipelinesAMDX_ptr == null)
				return .Err;
			break;

		case "vkGetExecutionGraphPipelineScratchSizeAMDX":
			LoadFunction("vkGetExecutionGraphPipelineScratchSizeAMDX", out vkGetExecutionGraphPipelineScratchSizeAMDX_ptr, instance, invokeErrorCallback);
			if(vkGetExecutionGraphPipelineScratchSizeAMDX_ptr == null)
				return .Err;
			break;

		case "vkGetExecutionGraphPipelineNodeIndexAMDX":
			LoadFunction("vkGetExecutionGraphPipelineNodeIndexAMDX", out vkGetExecutionGraphPipelineNodeIndexAMDX_ptr, instance, invokeErrorCallback);
			if(vkGetExecutionGraphPipelineNodeIndexAMDX_ptr == null)
				return .Err;
			break;

		case "vkCmdInitializeGraphScratchMemoryAMDX":
			LoadFunction("vkCmdInitializeGraphScratchMemoryAMDX", out vkCmdInitializeGraphScratchMemoryAMDX_ptr, instance, invokeErrorCallback);
			if(vkCmdInitializeGraphScratchMemoryAMDX_ptr == null)
				return .Err;
			break;

		case "vkCmdDispatchGraphAMDX":
			LoadFunction("vkCmdDispatchGraphAMDX", out vkCmdDispatchGraphAMDX_ptr, instance, invokeErrorCallback);
			if(vkCmdDispatchGraphAMDX_ptr == null)
				return .Err;
			break;

		case "vkCmdDispatchGraphIndirectAMDX":
			LoadFunction("vkCmdDispatchGraphIndirectAMDX", out vkCmdDispatchGraphIndirectAMDX_ptr, instance, invokeErrorCallback);
			if(vkCmdDispatchGraphIndirectAMDX_ptr == null)
				return .Err;
			break;

		case "vkCmdDispatchGraphIndirectCountAMDX":
			LoadFunction("vkCmdDispatchGraphIndirectCountAMDX", out vkCmdDispatchGraphIndirectCountAMDX_ptr, instance, invokeErrorCallback);
			if(vkCmdDispatchGraphIndirectCountAMDX_ptr == null)
				return .Err;
			break;

		case "vkWriteSamplerDescriptorsEXT":
			LoadFunction("vkWriteSamplerDescriptorsEXT", out vkWriteSamplerDescriptorsEXT_ptr, instance, invokeErrorCallback);
			if(vkWriteSamplerDescriptorsEXT_ptr == null)
				return .Err;
			break;

		case "vkWriteResourceDescriptorsEXT":
			LoadFunction("vkWriteResourceDescriptorsEXT", out vkWriteResourceDescriptorsEXT_ptr, instance, invokeErrorCallback);
			if(vkWriteResourceDescriptorsEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdBindSamplerHeapEXT":
			LoadFunction("vkCmdBindSamplerHeapEXT", out vkCmdBindSamplerHeapEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdBindSamplerHeapEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdBindResourceHeapEXT":
			LoadFunction("vkCmdBindResourceHeapEXT", out vkCmdBindResourceHeapEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdBindResourceHeapEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdPushDataEXT":
			LoadFunction("vkCmdPushDataEXT", out vkCmdPushDataEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdPushDataEXT_ptr == null)
				return .Err;
			break;

		case "vkGetImageOpaqueCaptureDataEXT":
			LoadFunction("vkGetImageOpaqueCaptureDataEXT", out vkGetImageOpaqueCaptureDataEXT_ptr, instance, invokeErrorCallback);
			if(vkGetImageOpaqueCaptureDataEXT_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceDescriptorSizeEXT":
			LoadFunction("vkGetPhysicalDeviceDescriptorSizeEXT", out vkGetPhysicalDeviceDescriptorSizeEXT_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceDescriptorSizeEXT_ptr == null)
				return .Err;
			break;

		case "vkRegisterCustomBorderColorEXT":
			LoadFunction("vkRegisterCustomBorderColorEXT", out vkRegisterCustomBorderColorEXT_ptr, instance, invokeErrorCallback);
			if(vkRegisterCustomBorderColorEXT_ptr == null)
				return .Err;
			break;

		case "vkUnregisterCustomBorderColorEXT":
			LoadFunction("vkUnregisterCustomBorderColorEXT", out vkUnregisterCustomBorderColorEXT_ptr, instance, invokeErrorCallback);
			if(vkUnregisterCustomBorderColorEXT_ptr == null)
				return .Err;
			break;

		case "vkGetTensorOpaqueCaptureDataARM":
			LoadFunction("vkGetTensorOpaqueCaptureDataARM", out vkGetTensorOpaqueCaptureDataARM_ptr, instance, invokeErrorCallback);
			if(vkGetTensorOpaqueCaptureDataARM_ptr == null)
				return .Err;
			break;

		case "vkCmdSetSampleLocationsEXT":
			LoadFunction("vkCmdSetSampleLocationsEXT", out vkCmdSetSampleLocationsEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetSampleLocationsEXT_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceMultisamplePropertiesEXT":
			LoadFunction("vkGetPhysicalDeviceMultisamplePropertiesEXT", out vkGetPhysicalDeviceMultisamplePropertiesEXT_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceMultisamplePropertiesEXT_ptr == null)
				return .Err;
			break;

		case "vkCreateAccelerationStructureKHR":
			LoadFunction("vkCreateAccelerationStructureKHR", out vkCreateAccelerationStructureKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateAccelerationStructureKHR_ptr == null)
				return .Err;
			break;

		case "vkDestroyAccelerationStructureKHR":
			LoadFunction("vkDestroyAccelerationStructureKHR", out vkDestroyAccelerationStructureKHR_ptr, instance, invokeErrorCallback);
			if(vkDestroyAccelerationStructureKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdBuildAccelerationStructuresKHR":
			LoadFunction("vkCmdBuildAccelerationStructuresKHR", out vkCmdBuildAccelerationStructuresKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdBuildAccelerationStructuresKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdBuildAccelerationStructuresIndirectKHR":
			LoadFunction("vkCmdBuildAccelerationStructuresIndirectKHR", out vkCmdBuildAccelerationStructuresIndirectKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdBuildAccelerationStructuresIndirectKHR_ptr == null)
				return .Err;
			break;

		case "vkBuildAccelerationStructuresKHR":
			LoadFunction("vkBuildAccelerationStructuresKHR", out vkBuildAccelerationStructuresKHR_ptr, instance, invokeErrorCallback);
			if(vkBuildAccelerationStructuresKHR_ptr == null)
				return .Err;
			break;

		case "vkCopyAccelerationStructureKHR":
			LoadFunction("vkCopyAccelerationStructureKHR", out vkCopyAccelerationStructureKHR_ptr, instance, invokeErrorCallback);
			if(vkCopyAccelerationStructureKHR_ptr == null)
				return .Err;
			break;

		case "vkCopyAccelerationStructureToMemoryKHR":
			LoadFunction("vkCopyAccelerationStructureToMemoryKHR", out vkCopyAccelerationStructureToMemoryKHR_ptr, instance, invokeErrorCallback);
			if(vkCopyAccelerationStructureToMemoryKHR_ptr == null)
				return .Err;
			break;

		case "vkCopyMemoryToAccelerationStructureKHR":
			LoadFunction("vkCopyMemoryToAccelerationStructureKHR", out vkCopyMemoryToAccelerationStructureKHR_ptr, instance, invokeErrorCallback);
			if(vkCopyMemoryToAccelerationStructureKHR_ptr == null)
				return .Err;
			break;

		case "vkWriteAccelerationStructuresPropertiesKHR":
			LoadFunction("vkWriteAccelerationStructuresPropertiesKHR", out vkWriteAccelerationStructuresPropertiesKHR_ptr, instance, invokeErrorCallback);
			if(vkWriteAccelerationStructuresPropertiesKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyAccelerationStructureKHR":
			LoadFunction("vkCmdCopyAccelerationStructureKHR", out vkCmdCopyAccelerationStructureKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyAccelerationStructureKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyAccelerationStructureToMemoryKHR":
			LoadFunction("vkCmdCopyAccelerationStructureToMemoryKHR", out vkCmdCopyAccelerationStructureToMemoryKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyAccelerationStructureToMemoryKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyMemoryToAccelerationStructureKHR":
			LoadFunction("vkCmdCopyMemoryToAccelerationStructureKHR", out vkCmdCopyMemoryToAccelerationStructureKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyMemoryToAccelerationStructureKHR_ptr == null)
				return .Err;
			break;

		case "vkGetAccelerationStructureDeviceAddressKHR":
			LoadFunction("vkGetAccelerationStructureDeviceAddressKHR", out vkGetAccelerationStructureDeviceAddressKHR_ptr, instance, invokeErrorCallback);
			if(vkGetAccelerationStructureDeviceAddressKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdWriteAccelerationStructuresPropertiesKHR":
			LoadFunction("vkCmdWriteAccelerationStructuresPropertiesKHR", out vkCmdWriteAccelerationStructuresPropertiesKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdWriteAccelerationStructuresPropertiesKHR_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceAccelerationStructureCompatibilityKHR":
			LoadFunction("vkGetDeviceAccelerationStructureCompatibilityKHR", out vkGetDeviceAccelerationStructureCompatibilityKHR_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceAccelerationStructureCompatibilityKHR_ptr == null)
				return .Err;
			break;

		case "vkGetAccelerationStructureBuildSizesKHR":
			LoadFunction("vkGetAccelerationStructureBuildSizesKHR", out vkGetAccelerationStructureBuildSizesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetAccelerationStructureBuildSizesKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdTraceRaysKHR":
			LoadFunction("vkCmdTraceRaysKHR", out vkCmdTraceRaysKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdTraceRaysKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateRayTracingPipelinesKHR":
			LoadFunction("vkCreateRayTracingPipelinesKHR", out vkCreateRayTracingPipelinesKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateRayTracingPipelinesKHR_ptr == null)
				return .Err;
			break;

		case "vkGetRayTracingShaderGroupHandlesKHR":
			LoadFunction("vkGetRayTracingShaderGroupHandlesKHR", out vkGetRayTracingShaderGroupHandlesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetRayTracingShaderGroupHandlesKHR_ptr == null)
				return .Err;
			break;

		case "vkGetRayTracingCaptureReplayShaderGroupHandlesKHR":
			LoadFunction("vkGetRayTracingCaptureReplayShaderGroupHandlesKHR", out vkGetRayTracingCaptureReplayShaderGroupHandlesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetRayTracingCaptureReplayShaderGroupHandlesKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdTraceRaysIndirectKHR":
			LoadFunction("vkCmdTraceRaysIndirectKHR", out vkCmdTraceRaysIndirectKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdTraceRaysIndirectKHR_ptr == null)
				return .Err;
			break;

		case "vkGetRayTracingShaderGroupStackSizeKHR":
			LoadFunction("vkGetRayTracingShaderGroupStackSizeKHR", out vkGetRayTracingShaderGroupStackSizeKHR_ptr, instance, invokeErrorCallback);
			if(vkGetRayTracingShaderGroupStackSizeKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdSetRayTracingPipelineStackSizeKHR":
			LoadFunction("vkCmdSetRayTracingPipelineStackSizeKHR", out vkCmdSetRayTracingPipelineStackSizeKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdSetRayTracingPipelineStackSizeKHR_ptr == null)
				return .Err;
			break;

		case "vkGetImageDrmFormatModifierPropertiesEXT":
			LoadFunction("vkGetImageDrmFormatModifierPropertiesEXT", out vkGetImageDrmFormatModifierPropertiesEXT_ptr, instance, invokeErrorCallback);
			if(vkGetImageDrmFormatModifierPropertiesEXT_ptr == null)
				return .Err;
			break;

		case "vkCreateValidationCacheEXT":
			LoadFunction("vkCreateValidationCacheEXT", out vkCreateValidationCacheEXT_ptr, instance, invokeErrorCallback);
			if(vkCreateValidationCacheEXT_ptr == null)
				return .Err;
			break;

		case "vkDestroyValidationCacheEXT":
			LoadFunction("vkDestroyValidationCacheEXT", out vkDestroyValidationCacheEXT_ptr, instance, invokeErrorCallback);
			if(vkDestroyValidationCacheEXT_ptr == null)
				return .Err;
			break;

		case "vkMergeValidationCachesEXT":
			LoadFunction("vkMergeValidationCachesEXT", out vkMergeValidationCachesEXT_ptr, instance, invokeErrorCallback);
			if(vkMergeValidationCachesEXT_ptr == null)
				return .Err;
			break;

		case "vkGetValidationCacheDataEXT":
			LoadFunction("vkGetValidationCacheDataEXT", out vkGetValidationCacheDataEXT_ptr, instance, invokeErrorCallback);
			if(vkGetValidationCacheDataEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdBindShadingRateImageNV":
			LoadFunction("vkCmdBindShadingRateImageNV", out vkCmdBindShadingRateImageNV_ptr, instance, invokeErrorCallback);
			if(vkCmdBindShadingRateImageNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetViewportShadingRatePaletteNV":
			LoadFunction("vkCmdSetViewportShadingRatePaletteNV", out vkCmdSetViewportShadingRatePaletteNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetViewportShadingRatePaletteNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetCoarseSampleOrderNV":
			LoadFunction("vkCmdSetCoarseSampleOrderNV", out vkCmdSetCoarseSampleOrderNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetCoarseSampleOrderNV_ptr == null)
				return .Err;
			break;

		case "vkCreateAccelerationStructureNV":
			LoadFunction("vkCreateAccelerationStructureNV", out vkCreateAccelerationStructureNV_ptr, instance, invokeErrorCallback);
			if(vkCreateAccelerationStructureNV_ptr == null)
				return .Err;
			break;

		case "vkDestroyAccelerationStructureNV":
			LoadFunction("vkDestroyAccelerationStructureNV", out vkDestroyAccelerationStructureNV_ptr, instance, invokeErrorCallback);
			if(vkDestroyAccelerationStructureNV_ptr == null)
				return .Err;
			break;

		case "vkGetAccelerationStructureMemoryRequirementsNV":
			LoadFunction("vkGetAccelerationStructureMemoryRequirementsNV", out vkGetAccelerationStructureMemoryRequirementsNV_ptr, instance, invokeErrorCallback);
			if(vkGetAccelerationStructureMemoryRequirementsNV_ptr == null)
				return .Err;
			break;

		case "vkBindAccelerationStructureMemoryNV":
			LoadFunction("vkBindAccelerationStructureMemoryNV", out vkBindAccelerationStructureMemoryNV_ptr, instance, invokeErrorCallback);
			if(vkBindAccelerationStructureMemoryNV_ptr == null)
				return .Err;
			break;

		case "vkCmdBuildAccelerationStructureNV":
			LoadFunction("vkCmdBuildAccelerationStructureNV", out vkCmdBuildAccelerationStructureNV_ptr, instance, invokeErrorCallback);
			if(vkCmdBuildAccelerationStructureNV_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyAccelerationStructureNV":
			LoadFunction("vkCmdCopyAccelerationStructureNV", out vkCmdCopyAccelerationStructureNV_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyAccelerationStructureNV_ptr == null)
				return .Err;
			break;

		case "vkCmdTraceRaysNV":
			LoadFunction("vkCmdTraceRaysNV", out vkCmdTraceRaysNV_ptr, instance, invokeErrorCallback);
			if(vkCmdTraceRaysNV_ptr == null)
				return .Err;
			break;

		case "vkCreateRayTracingPipelinesNV":
			LoadFunction("vkCreateRayTracingPipelinesNV", out vkCreateRayTracingPipelinesNV_ptr, instance, invokeErrorCallback);
			if(vkCreateRayTracingPipelinesNV_ptr == null)
				return .Err;
			break;

		case "vkGetAccelerationStructureHandleNV":
			LoadFunction("vkGetAccelerationStructureHandleNV", out vkGetAccelerationStructureHandleNV_ptr, instance, invokeErrorCallback);
			if(vkGetAccelerationStructureHandleNV_ptr == null)
				return .Err;
			break;

		case "vkCmdWriteAccelerationStructuresPropertiesNV":
			LoadFunction("vkCmdWriteAccelerationStructuresPropertiesNV", out vkCmdWriteAccelerationStructuresPropertiesNV_ptr, instance, invokeErrorCallback);
			if(vkCmdWriteAccelerationStructuresPropertiesNV_ptr == null)
				return .Err;
			break;

		case "vkCompileDeferredNV":
			LoadFunction("vkCompileDeferredNV", out vkCompileDeferredNV_ptr, instance, invokeErrorCallback);
			if(vkCompileDeferredNV_ptr == null)
				return .Err;
			break;

		case "vkGetMemoryHostPointerPropertiesEXT":
			LoadFunction("vkGetMemoryHostPointerPropertiesEXT", out vkGetMemoryHostPointerPropertiesEXT_ptr, instance, invokeErrorCallback);
			if(vkGetMemoryHostPointerPropertiesEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdWriteBufferMarkerAMD":
			LoadFunction("vkCmdWriteBufferMarkerAMD", out vkCmdWriteBufferMarkerAMD_ptr, instance, invokeErrorCallback);
			if(vkCmdWriteBufferMarkerAMD_ptr == null)
				return .Err;
			break;

		case "vkCmdWriteBufferMarker2AMD":
			LoadFunction("vkCmdWriteBufferMarker2AMD", out vkCmdWriteBufferMarker2AMD_ptr, instance, invokeErrorCallback);
			if(vkCmdWriteBufferMarker2AMD_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceCalibrateableTimeDomainsKHR":
			LoadFunction("vkGetPhysicalDeviceCalibrateableTimeDomainsKHR", out vkGetPhysicalDeviceCalibrateableTimeDomainsKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceCalibrateableTimeDomainsKHR_ptr == null)
				return .Err;
			break;

		case "vkGetCalibratedTimestampsKHR":
			LoadFunction("vkGetCalibratedTimestampsKHR", out vkGetCalibratedTimestampsKHR_ptr, instance, invokeErrorCallback);
			if(vkGetCalibratedTimestampsKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawMeshTasksNV":
			LoadFunction("vkCmdDrawMeshTasksNV", out vkCmdDrawMeshTasksNV_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawMeshTasksNV_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawMeshTasksIndirectNV":
			LoadFunction("vkCmdDrawMeshTasksIndirectNV", out vkCmdDrawMeshTasksIndirectNV_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawMeshTasksIndirectNV_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawMeshTasksIndirectCountNV":
			LoadFunction("vkCmdDrawMeshTasksIndirectCountNV", out vkCmdDrawMeshTasksIndirectCountNV_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawMeshTasksIndirectCountNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetExclusiveScissorEnableNV":
			LoadFunction("vkCmdSetExclusiveScissorEnableNV", out vkCmdSetExclusiveScissorEnableNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetExclusiveScissorEnableNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetExclusiveScissorNV":
			LoadFunction("vkCmdSetExclusiveScissorNV", out vkCmdSetExclusiveScissorNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetExclusiveScissorNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetCheckpointNV":
			LoadFunction("vkCmdSetCheckpointNV", out vkCmdSetCheckpointNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetCheckpointNV_ptr == null)
				return .Err;
			break;

		case "vkGetQueueCheckpointDataNV":
			LoadFunction("vkGetQueueCheckpointDataNV", out vkGetQueueCheckpointDataNV_ptr, instance, invokeErrorCallback);
			if(vkGetQueueCheckpointDataNV_ptr == null)
				return .Err;
			break;

		case "vkGetQueueCheckpointData2NV":
			LoadFunction("vkGetQueueCheckpointData2NV", out vkGetQueueCheckpointData2NV_ptr, instance, invokeErrorCallback);
			if(vkGetQueueCheckpointData2NV_ptr == null)
				return .Err;
			break;

		case "vkSetSwapchainPresentTimingQueueSizeEXT":
			LoadFunction("vkSetSwapchainPresentTimingQueueSizeEXT", out vkSetSwapchainPresentTimingQueueSizeEXT_ptr, instance, invokeErrorCallback);
			if(vkSetSwapchainPresentTimingQueueSizeEXT_ptr == null)
				return .Err;
			break;

		case "vkGetSwapchainTimingPropertiesEXT":
			LoadFunction("vkGetSwapchainTimingPropertiesEXT", out vkGetSwapchainTimingPropertiesEXT_ptr, instance, invokeErrorCallback);
			if(vkGetSwapchainTimingPropertiesEXT_ptr == null)
				return .Err;
			break;

		case "vkGetSwapchainTimeDomainPropertiesEXT":
			LoadFunction("vkGetSwapchainTimeDomainPropertiesEXT", out vkGetSwapchainTimeDomainPropertiesEXT_ptr, instance, invokeErrorCallback);
			if(vkGetSwapchainTimeDomainPropertiesEXT_ptr == null)
				return .Err;
			break;

		case "vkGetPastPresentationTimingEXT":
			LoadFunction("vkGetPastPresentationTimingEXT", out vkGetPastPresentationTimingEXT_ptr, instance, invokeErrorCallback);
			if(vkGetPastPresentationTimingEXT_ptr == null)
				return .Err;
			break;

		case "vkInitializePerformanceApiINTEL":
			LoadFunction("vkInitializePerformanceApiINTEL", out vkInitializePerformanceApiINTEL_ptr, instance, invokeErrorCallback);
			if(vkInitializePerformanceApiINTEL_ptr == null)
				return .Err;
			break;

		case "vkUninitializePerformanceApiINTEL":
			LoadFunction("vkUninitializePerformanceApiINTEL", out vkUninitializePerformanceApiINTEL_ptr, instance, invokeErrorCallback);
			if(vkUninitializePerformanceApiINTEL_ptr == null)
				return .Err;
			break;

		case "vkCmdSetPerformanceMarkerINTEL":
			LoadFunction("vkCmdSetPerformanceMarkerINTEL", out vkCmdSetPerformanceMarkerINTEL_ptr, instance, invokeErrorCallback);
			if(vkCmdSetPerformanceMarkerINTEL_ptr == null)
				return .Err;
			break;

		case "vkCmdSetPerformanceStreamMarkerINTEL":
			LoadFunction("vkCmdSetPerformanceStreamMarkerINTEL", out vkCmdSetPerformanceStreamMarkerINTEL_ptr, instance, invokeErrorCallback);
			if(vkCmdSetPerformanceStreamMarkerINTEL_ptr == null)
				return .Err;
			break;

		case "vkCmdSetPerformanceOverrideINTEL":
			LoadFunction("vkCmdSetPerformanceOverrideINTEL", out vkCmdSetPerformanceOverrideINTEL_ptr, instance, invokeErrorCallback);
			if(vkCmdSetPerformanceOverrideINTEL_ptr == null)
				return .Err;
			break;

		case "vkAcquirePerformanceConfigurationINTEL":
			LoadFunction("vkAcquirePerformanceConfigurationINTEL", out vkAcquirePerformanceConfigurationINTEL_ptr, instance, invokeErrorCallback);
			if(vkAcquirePerformanceConfigurationINTEL_ptr == null)
				return .Err;
			break;

		case "vkReleasePerformanceConfigurationINTEL":
			LoadFunction("vkReleasePerformanceConfigurationINTEL", out vkReleasePerformanceConfigurationINTEL_ptr, instance, invokeErrorCallback);
			if(vkReleasePerformanceConfigurationINTEL_ptr == null)
				return .Err;
			break;

		case "vkQueueSetPerformanceConfigurationINTEL":
			LoadFunction("vkQueueSetPerformanceConfigurationINTEL", out vkQueueSetPerformanceConfigurationINTEL_ptr, instance, invokeErrorCallback);
			if(vkQueueSetPerformanceConfigurationINTEL_ptr == null)
				return .Err;
			break;

		case "vkGetPerformanceParameterINTEL":
			LoadFunction("vkGetPerformanceParameterINTEL", out vkGetPerformanceParameterINTEL_ptr, instance, invokeErrorCallback);
			if(vkGetPerformanceParameterINTEL_ptr == null)
				return .Err;
			break;

		case "vkSetLocalDimmingAMD":
			LoadFunction("vkSetLocalDimmingAMD", out vkSetLocalDimmingAMD_ptr, instance, invokeErrorCallback);
			if(vkSetLocalDimmingAMD_ptr == null)
				return .Err;
			break;

		case "vkCreateImagePipeSurfaceFUCHSIA":
			LoadFunction("vkCreateImagePipeSurfaceFUCHSIA", out vkCreateImagePipeSurfaceFUCHSIA_ptr, instance, invokeErrorCallback);
			if(vkCreateImagePipeSurfaceFUCHSIA_ptr == null)
				return .Err;
			break;

		case "vkCreateMetalSurfaceEXT":
			LoadFunction("vkCreateMetalSurfaceEXT", out vkCreateMetalSurfaceEXT_ptr, instance, invokeErrorCallback);
			if(vkCreateMetalSurfaceEXT_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceFragmentShadingRatesKHR":
			LoadFunction("vkGetPhysicalDeviceFragmentShadingRatesKHR", out vkGetPhysicalDeviceFragmentShadingRatesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceFragmentShadingRatesKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdSetFragmentShadingRateKHR":
			LoadFunction("vkCmdSetFragmentShadingRateKHR", out vkCmdSetFragmentShadingRateKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdSetFragmentShadingRateKHR_ptr == null)
				return .Err;
			break;

		case "vkWaitForPresentKHR":
			LoadFunction("vkWaitForPresentKHR", out vkWaitForPresentKHR_ptr, instance, invokeErrorCallback);
			if(vkWaitForPresentKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceCooperativeMatrixPropertiesNV":
			LoadFunction("vkGetPhysicalDeviceCooperativeMatrixPropertiesNV", out vkGetPhysicalDeviceCooperativeMatrixPropertiesNV_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceCooperativeMatrixPropertiesNV_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV":
			LoadFunction("vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV", out vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceSurfacePresentModes2EXT":
			LoadFunction("vkGetPhysicalDeviceSurfacePresentModes2EXT", out vkGetPhysicalDeviceSurfacePresentModes2EXT_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceSurfacePresentModes2EXT_ptr == null)
				return .Err;
			break;

		case "vkAcquireFullScreenExclusiveModeEXT":
			LoadFunction("vkAcquireFullScreenExclusiveModeEXT", out vkAcquireFullScreenExclusiveModeEXT_ptr, instance, invokeErrorCallback);
			if(vkAcquireFullScreenExclusiveModeEXT_ptr == null)
				return .Err;
			break;

		case "vkReleaseFullScreenExclusiveModeEXT":
			LoadFunction("vkReleaseFullScreenExclusiveModeEXT", out vkReleaseFullScreenExclusiveModeEXT_ptr, instance, invokeErrorCallback);
			if(vkReleaseFullScreenExclusiveModeEXT_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceGroupSurfacePresentModes2EXT":
			LoadFunction("vkGetDeviceGroupSurfacePresentModes2EXT", out vkGetDeviceGroupSurfacePresentModes2EXT_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceGroupSurfacePresentModes2EXT_ptr == null)
				return .Err;
			break;

		case "vkCreateHeadlessSurfaceEXT":
			LoadFunction("vkCreateHeadlessSurfaceEXT", out vkCreateHeadlessSurfaceEXT_ptr, instance, invokeErrorCallback);
			if(vkCreateHeadlessSurfaceEXT_ptr == null)
				return .Err;
			break;

		case "vkCreateDeferredOperationKHR":
			LoadFunction("vkCreateDeferredOperationKHR", out vkCreateDeferredOperationKHR_ptr, instance, invokeErrorCallback);
			if(vkCreateDeferredOperationKHR_ptr == null)
				return .Err;
			break;

		case "vkDestroyDeferredOperationKHR":
			LoadFunction("vkDestroyDeferredOperationKHR", out vkDestroyDeferredOperationKHR_ptr, instance, invokeErrorCallback);
			if(vkDestroyDeferredOperationKHR_ptr == null)
				return .Err;
			break;

		case "vkGetDeferredOperationMaxConcurrencyKHR":
			LoadFunction("vkGetDeferredOperationMaxConcurrencyKHR", out vkGetDeferredOperationMaxConcurrencyKHR_ptr, instance, invokeErrorCallback);
			if(vkGetDeferredOperationMaxConcurrencyKHR_ptr == null)
				return .Err;
			break;

		case "vkGetDeferredOperationResultKHR":
			LoadFunction("vkGetDeferredOperationResultKHR", out vkGetDeferredOperationResultKHR_ptr, instance, invokeErrorCallback);
			if(vkGetDeferredOperationResultKHR_ptr == null)
				return .Err;
			break;

		case "vkDeferredOperationJoinKHR":
			LoadFunction("vkDeferredOperationJoinKHR", out vkDeferredOperationJoinKHR_ptr, instance, invokeErrorCallback);
			if(vkDeferredOperationJoinKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPipelineExecutablePropertiesKHR":
			LoadFunction("vkGetPipelineExecutablePropertiesKHR", out vkGetPipelineExecutablePropertiesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPipelineExecutablePropertiesKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPipelineExecutableStatisticsKHR":
			LoadFunction("vkGetPipelineExecutableStatisticsKHR", out vkGetPipelineExecutableStatisticsKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPipelineExecutableStatisticsKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPipelineExecutableInternalRepresentationsKHR":
			LoadFunction("vkGetPipelineExecutableInternalRepresentationsKHR", out vkGetPipelineExecutableInternalRepresentationsKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPipelineExecutableInternalRepresentationsKHR_ptr == null)
				return .Err;
			break;

		case "vkReleaseSwapchainImagesKHR":
			LoadFunction("vkReleaseSwapchainImagesKHR", out vkReleaseSwapchainImagesKHR_ptr, instance, invokeErrorCallback);
			if(vkReleaseSwapchainImagesKHR_ptr == null)
				return .Err;
			break;

		case "vkGetGeneratedCommandsMemoryRequirementsNV":
			LoadFunction("vkGetGeneratedCommandsMemoryRequirementsNV", out vkGetGeneratedCommandsMemoryRequirementsNV_ptr, instance, invokeErrorCallback);
			if(vkGetGeneratedCommandsMemoryRequirementsNV_ptr == null)
				return .Err;
			break;

		case "vkCmdPreprocessGeneratedCommandsNV":
			LoadFunction("vkCmdPreprocessGeneratedCommandsNV", out vkCmdPreprocessGeneratedCommandsNV_ptr, instance, invokeErrorCallback);
			if(vkCmdPreprocessGeneratedCommandsNV_ptr == null)
				return .Err;
			break;

		case "vkCmdExecuteGeneratedCommandsNV":
			LoadFunction("vkCmdExecuteGeneratedCommandsNV", out vkCmdExecuteGeneratedCommandsNV_ptr, instance, invokeErrorCallback);
			if(vkCmdExecuteGeneratedCommandsNV_ptr == null)
				return .Err;
			break;

		case "vkCmdBindPipelineShaderGroupNV":
			LoadFunction("vkCmdBindPipelineShaderGroupNV", out vkCmdBindPipelineShaderGroupNV_ptr, instance, invokeErrorCallback);
			if(vkCmdBindPipelineShaderGroupNV_ptr == null)
				return .Err;
			break;

		case "vkCreateIndirectCommandsLayoutNV":
			LoadFunction("vkCreateIndirectCommandsLayoutNV", out vkCreateIndirectCommandsLayoutNV_ptr, instance, invokeErrorCallback);
			if(vkCreateIndirectCommandsLayoutNV_ptr == null)
				return .Err;
			break;

		case "vkDestroyIndirectCommandsLayoutNV":
			LoadFunction("vkDestroyIndirectCommandsLayoutNV", out vkDestroyIndirectCommandsLayoutNV_ptr, instance, invokeErrorCallback);
			if(vkDestroyIndirectCommandsLayoutNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDepthBias2EXT":
			LoadFunction("vkCmdSetDepthBias2EXT", out vkCmdSetDepthBias2EXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDepthBias2EXT_ptr == null)
				return .Err;
			break;

		case "vkAcquireDrmDisplayEXT":
			LoadFunction("vkAcquireDrmDisplayEXT", out vkAcquireDrmDisplayEXT_ptr, instance, invokeErrorCallback);
			if(vkAcquireDrmDisplayEXT_ptr == null)
				return .Err;
			break;

		case "vkGetDrmDisplayEXT":
			LoadFunction("vkGetDrmDisplayEXT", out vkGetDrmDisplayEXT_ptr, instance, invokeErrorCallback);
			if(vkGetDrmDisplayEXT_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR":
			LoadFunction("vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR", out vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR_ptr == null)
				return .Err;
			break;

		case "vkGetEncodedVideoSessionParametersKHR":
			LoadFunction("vkGetEncodedVideoSessionParametersKHR", out vkGetEncodedVideoSessionParametersKHR_ptr, instance, invokeErrorCallback);
			if(vkGetEncodedVideoSessionParametersKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdEncodeVideoKHR":
			LoadFunction("vkCmdEncodeVideoKHR", out vkCmdEncodeVideoKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdEncodeVideoKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateCudaModuleNV":
			LoadFunction("vkCreateCudaModuleNV", out vkCreateCudaModuleNV_ptr, instance, invokeErrorCallback);
			if(vkCreateCudaModuleNV_ptr == null)
				return .Err;
			break;

		case "vkGetCudaModuleCacheNV":
			LoadFunction("vkGetCudaModuleCacheNV", out vkGetCudaModuleCacheNV_ptr, instance, invokeErrorCallback);
			if(vkGetCudaModuleCacheNV_ptr == null)
				return .Err;
			break;

		case "vkCreateCudaFunctionNV":
			LoadFunction("vkCreateCudaFunctionNV", out vkCreateCudaFunctionNV_ptr, instance, invokeErrorCallback);
			if(vkCreateCudaFunctionNV_ptr == null)
				return .Err;
			break;

		case "vkDestroyCudaModuleNV":
			LoadFunction("vkDestroyCudaModuleNV", out vkDestroyCudaModuleNV_ptr, instance, invokeErrorCallback);
			if(vkDestroyCudaModuleNV_ptr == null)
				return .Err;
			break;

		case "vkDestroyCudaFunctionNV":
			LoadFunction("vkDestroyCudaFunctionNV", out vkDestroyCudaFunctionNV_ptr, instance, invokeErrorCallback);
			if(vkDestroyCudaFunctionNV_ptr == null)
				return .Err;
			break;

		case "vkCmdCudaLaunchKernelNV":
			LoadFunction("vkCmdCudaLaunchKernelNV", out vkCmdCudaLaunchKernelNV_ptr, instance, invokeErrorCallback);
			if(vkCmdCudaLaunchKernelNV_ptr == null)
				return .Err;
			break;

		case "vkCmdRefreshObjectsKHR":
			LoadFunction("vkCmdRefreshObjectsKHR", out vkCmdRefreshObjectsKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdRefreshObjectsKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceRefreshableObjectTypesKHR":
			LoadFunction("vkGetPhysicalDeviceRefreshableObjectTypesKHR", out vkGetPhysicalDeviceRefreshableObjectTypesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceRefreshableObjectTypesKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdDispatchTileQCOM":
			LoadFunction("vkCmdDispatchTileQCOM", out vkCmdDispatchTileQCOM_ptr, instance, invokeErrorCallback);
			if(vkCmdDispatchTileQCOM_ptr == null)
				return .Err;
			break;

		case "vkCmdBeginPerTileExecutionQCOM":
			LoadFunction("vkCmdBeginPerTileExecutionQCOM", out vkCmdBeginPerTileExecutionQCOM_ptr, instance, invokeErrorCallback);
			if(vkCmdBeginPerTileExecutionQCOM_ptr == null)
				return .Err;
			break;

		case "vkCmdEndPerTileExecutionQCOM":
			LoadFunction("vkCmdEndPerTileExecutionQCOM", out vkCmdEndPerTileExecutionQCOM_ptr, instance, invokeErrorCallback);
			if(vkCmdEndPerTileExecutionQCOM_ptr == null)
				return .Err;
			break;

		case "vkExportMetalObjectsEXT":
			LoadFunction("vkExportMetalObjectsEXT", out vkExportMetalObjectsEXT_ptr, instance, invokeErrorCallback);
			if(vkExportMetalObjectsEXT_ptr == null)
				return .Err;
			break;

		case "vkGetDescriptorSetLayoutSizeEXT":
			LoadFunction("vkGetDescriptorSetLayoutSizeEXT", out vkGetDescriptorSetLayoutSizeEXT_ptr, instance, invokeErrorCallback);
			if(vkGetDescriptorSetLayoutSizeEXT_ptr == null)
				return .Err;
			break;

		case "vkGetDescriptorSetLayoutBindingOffsetEXT":
			LoadFunction("vkGetDescriptorSetLayoutBindingOffsetEXT", out vkGetDescriptorSetLayoutBindingOffsetEXT_ptr, instance, invokeErrorCallback);
			if(vkGetDescriptorSetLayoutBindingOffsetEXT_ptr == null)
				return .Err;
			break;

		case "vkGetDescriptorEXT":
			LoadFunction("vkGetDescriptorEXT", out vkGetDescriptorEXT_ptr, instance, invokeErrorCallback);
			if(vkGetDescriptorEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdBindDescriptorBuffersEXT":
			LoadFunction("vkCmdBindDescriptorBuffersEXT", out vkCmdBindDescriptorBuffersEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdBindDescriptorBuffersEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDescriptorBufferOffsetsEXT":
			LoadFunction("vkCmdSetDescriptorBufferOffsetsEXT", out vkCmdSetDescriptorBufferOffsetsEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDescriptorBufferOffsetsEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdBindDescriptorBufferEmbeddedSamplersEXT":
			LoadFunction("vkCmdBindDescriptorBufferEmbeddedSamplersEXT", out vkCmdBindDescriptorBufferEmbeddedSamplersEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdBindDescriptorBufferEmbeddedSamplersEXT_ptr == null)
				return .Err;
			break;

		case "vkGetBufferOpaqueCaptureDescriptorDataEXT":
			LoadFunction("vkGetBufferOpaqueCaptureDescriptorDataEXT", out vkGetBufferOpaqueCaptureDescriptorDataEXT_ptr, instance, invokeErrorCallback);
			if(vkGetBufferOpaqueCaptureDescriptorDataEXT_ptr == null)
				return .Err;
			break;

		case "vkGetImageOpaqueCaptureDescriptorDataEXT":
			LoadFunction("vkGetImageOpaqueCaptureDescriptorDataEXT", out vkGetImageOpaqueCaptureDescriptorDataEXT_ptr, instance, invokeErrorCallback);
			if(vkGetImageOpaqueCaptureDescriptorDataEXT_ptr == null)
				return .Err;
			break;

		case "vkGetImageViewOpaqueCaptureDescriptorDataEXT":
			LoadFunction("vkGetImageViewOpaqueCaptureDescriptorDataEXT", out vkGetImageViewOpaqueCaptureDescriptorDataEXT_ptr, instance, invokeErrorCallback);
			if(vkGetImageViewOpaqueCaptureDescriptorDataEXT_ptr == null)
				return .Err;
			break;

		case "vkGetSamplerOpaqueCaptureDescriptorDataEXT":
			LoadFunction("vkGetSamplerOpaqueCaptureDescriptorDataEXT", out vkGetSamplerOpaqueCaptureDescriptorDataEXT_ptr, instance, invokeErrorCallback);
			if(vkGetSamplerOpaqueCaptureDescriptorDataEXT_ptr == null)
				return .Err;
			break;

		case "vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT":
			LoadFunction("vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT", out vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT_ptr, instance, invokeErrorCallback);
			if(vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetFragmentShadingRateEnumNV":
			LoadFunction("vkCmdSetFragmentShadingRateEnumNV", out vkCmdSetFragmentShadingRateEnumNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetFragmentShadingRateEnumNV_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawMeshTasksEXT":
			LoadFunction("vkCmdDrawMeshTasksEXT", out vkCmdDrawMeshTasksEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawMeshTasksEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawMeshTasksIndirectEXT":
			LoadFunction("vkCmdDrawMeshTasksIndirectEXT", out vkCmdDrawMeshTasksIndirectEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawMeshTasksIndirectEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawMeshTasksIndirectCountEXT":
			LoadFunction("vkCmdDrawMeshTasksIndirectCountEXT", out vkCmdDrawMeshTasksIndirectCountEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawMeshTasksIndirectCountEXT_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceFaultInfoEXT":
			LoadFunction("vkGetDeviceFaultInfoEXT", out vkGetDeviceFaultInfoEXT_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceFaultInfoEXT_ptr == null)
				return .Err;
			break;

		case "vkAcquireWinrtDisplayNV":
			LoadFunction("vkAcquireWinrtDisplayNV", out vkAcquireWinrtDisplayNV_ptr, instance, invokeErrorCallback);
			if(vkAcquireWinrtDisplayNV_ptr == null)
				return .Err;
			break;

		case "vkGetWinrtDisplayNV":
			LoadFunction("vkGetWinrtDisplayNV", out vkGetWinrtDisplayNV_ptr, instance, invokeErrorCallback);
			if(vkGetWinrtDisplayNV_ptr == null)
				return .Err;
			break;

		case "vkCreateDirectFBSurfaceEXT":
			LoadFunction("vkCreateDirectFBSurfaceEXT", out vkCreateDirectFBSurfaceEXT_ptr, instance, invokeErrorCallback);
			if(vkCreateDirectFBSurfaceEXT_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceDirectFBPresentationSupportEXT":
			LoadFunction("vkGetPhysicalDeviceDirectFBPresentationSupportEXT", out vkGetPhysicalDeviceDirectFBPresentationSupportEXT_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceDirectFBPresentationSupportEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetVertexInputEXT":
			LoadFunction("vkCmdSetVertexInputEXT", out vkCmdSetVertexInputEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetVertexInputEXT_ptr == null)
				return .Err;
			break;

		case "vkGetMemoryZirconHandleFUCHSIA":
			LoadFunction("vkGetMemoryZirconHandleFUCHSIA", out vkGetMemoryZirconHandleFUCHSIA_ptr, instance, invokeErrorCallback);
			if(vkGetMemoryZirconHandleFUCHSIA_ptr == null)
				return .Err;
			break;

		case "vkGetMemoryZirconHandlePropertiesFUCHSIA":
			LoadFunction("vkGetMemoryZirconHandlePropertiesFUCHSIA", out vkGetMemoryZirconHandlePropertiesFUCHSIA_ptr, instance, invokeErrorCallback);
			if(vkGetMemoryZirconHandlePropertiesFUCHSIA_ptr == null)
				return .Err;
			break;

		case "vkImportSemaphoreZirconHandleFUCHSIA":
			LoadFunction("vkImportSemaphoreZirconHandleFUCHSIA", out vkImportSemaphoreZirconHandleFUCHSIA_ptr, instance, invokeErrorCallback);
			if(vkImportSemaphoreZirconHandleFUCHSIA_ptr == null)
				return .Err;
			break;

		case "vkGetSemaphoreZirconHandleFUCHSIA":
			LoadFunction("vkGetSemaphoreZirconHandleFUCHSIA", out vkGetSemaphoreZirconHandleFUCHSIA_ptr, instance, invokeErrorCallback);
			if(vkGetSemaphoreZirconHandleFUCHSIA_ptr == null)
				return .Err;
			break;

		case "vkCreateBufferCollectionFUCHSIA":
			LoadFunction("vkCreateBufferCollectionFUCHSIA", out vkCreateBufferCollectionFUCHSIA_ptr, instance, invokeErrorCallback);
			if(vkCreateBufferCollectionFUCHSIA_ptr == null)
				return .Err;
			break;

		case "vkSetBufferCollectionImageConstraintsFUCHSIA":
			LoadFunction("vkSetBufferCollectionImageConstraintsFUCHSIA", out vkSetBufferCollectionImageConstraintsFUCHSIA_ptr, instance, invokeErrorCallback);
			if(vkSetBufferCollectionImageConstraintsFUCHSIA_ptr == null)
				return .Err;
			break;

		case "vkSetBufferCollectionBufferConstraintsFUCHSIA":
			LoadFunction("vkSetBufferCollectionBufferConstraintsFUCHSIA", out vkSetBufferCollectionBufferConstraintsFUCHSIA_ptr, instance, invokeErrorCallback);
			if(vkSetBufferCollectionBufferConstraintsFUCHSIA_ptr == null)
				return .Err;
			break;

		case "vkDestroyBufferCollectionFUCHSIA":
			LoadFunction("vkDestroyBufferCollectionFUCHSIA", out vkDestroyBufferCollectionFUCHSIA_ptr, instance, invokeErrorCallback);
			if(vkDestroyBufferCollectionFUCHSIA_ptr == null)
				return .Err;
			break;

		case "vkGetBufferCollectionPropertiesFUCHSIA":
			LoadFunction("vkGetBufferCollectionPropertiesFUCHSIA", out vkGetBufferCollectionPropertiesFUCHSIA_ptr, instance, invokeErrorCallback);
			if(vkGetBufferCollectionPropertiesFUCHSIA_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI":
			LoadFunction("vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI", out vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI_ptr == null)
				return .Err;
			break;

		case "vkCmdSubpassShadingHUAWEI":
			LoadFunction("vkCmdSubpassShadingHUAWEI", out vkCmdSubpassShadingHUAWEI_ptr, instance, invokeErrorCallback);
			if(vkCmdSubpassShadingHUAWEI_ptr == null)
				return .Err;
			break;

		case "vkCmdBindInvocationMaskHUAWEI":
			LoadFunction("vkCmdBindInvocationMaskHUAWEI", out vkCmdBindInvocationMaskHUAWEI_ptr, instance, invokeErrorCallback);
			if(vkCmdBindInvocationMaskHUAWEI_ptr == null)
				return .Err;
			break;

		case "vkGetMemoryRemoteAddressNV":
			LoadFunction("vkGetMemoryRemoteAddressNV", out vkGetMemoryRemoteAddressNV_ptr, instance, invokeErrorCallback);
			if(vkGetMemoryRemoteAddressNV_ptr == null)
				return .Err;
			break;

		case "vkGetPipelinePropertiesEXT":
			LoadFunction("vkGetPipelinePropertiesEXT", out vkGetPipelinePropertiesEXT_ptr, instance, invokeErrorCallback);
			if(vkGetPipelinePropertiesEXT_ptr == null)
				return .Err;
			break;

		case "vkGetFenceSciSyncFenceNV":
			LoadFunction("vkGetFenceSciSyncFenceNV", out vkGetFenceSciSyncFenceNV_ptr, instance, invokeErrorCallback);
			if(vkGetFenceSciSyncFenceNV_ptr == null)
				return .Err;
			break;

		case "vkGetFenceSciSyncObjNV":
			LoadFunction("vkGetFenceSciSyncObjNV", out vkGetFenceSciSyncObjNV_ptr, instance, invokeErrorCallback);
			if(vkGetFenceSciSyncObjNV_ptr == null)
				return .Err;
			break;

		case "vkImportFenceSciSyncFenceNV":
			LoadFunction("vkImportFenceSciSyncFenceNV", out vkImportFenceSciSyncFenceNV_ptr, instance, invokeErrorCallback);
			if(vkImportFenceSciSyncFenceNV_ptr == null)
				return .Err;
			break;

		case "vkImportFenceSciSyncObjNV":
			LoadFunction("vkImportFenceSciSyncObjNV", out vkImportFenceSciSyncObjNV_ptr, instance, invokeErrorCallback);
			if(vkImportFenceSciSyncObjNV_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceSciSyncAttributesNV":
			LoadFunction("vkGetPhysicalDeviceSciSyncAttributesNV", out vkGetPhysicalDeviceSciSyncAttributesNV_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceSciSyncAttributesNV_ptr == null)
				return .Err;
			break;

		case "vkGetSemaphoreSciSyncObjNV":
			LoadFunction("vkGetSemaphoreSciSyncObjNV", out vkGetSemaphoreSciSyncObjNV_ptr, instance, invokeErrorCallback);
			if(vkGetSemaphoreSciSyncObjNV_ptr == null)
				return .Err;
			break;

		case "vkImportSemaphoreSciSyncObjNV":
			LoadFunction("vkImportSemaphoreSciSyncObjNV", out vkImportSemaphoreSciSyncObjNV_ptr, instance, invokeErrorCallback);
			if(vkImportSemaphoreSciSyncObjNV_ptr == null)
				return .Err;
			break;

		case "vkGetMemorySciBufNV":
			LoadFunction("vkGetMemorySciBufNV", out vkGetMemorySciBufNV_ptr, instance, invokeErrorCallback);
			if(vkGetMemorySciBufNV_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV":
			LoadFunction("vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV", out vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceSciBufAttributesNV":
			LoadFunction("vkGetPhysicalDeviceSciBufAttributesNV", out vkGetPhysicalDeviceSciBufAttributesNV_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceSciBufAttributesNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetPatchControlPointsEXT":
			LoadFunction("vkCmdSetPatchControlPointsEXT", out vkCmdSetPatchControlPointsEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetPatchControlPointsEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetLogicOpEXT":
			LoadFunction("vkCmdSetLogicOpEXT", out vkCmdSetLogicOpEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetLogicOpEXT_ptr == null)
				return .Err;
			break;

		case "vkCreateScreenSurfaceQNX":
			LoadFunction("vkCreateScreenSurfaceQNX", out vkCreateScreenSurfaceQNX_ptr, instance, invokeErrorCallback);
			if(vkCreateScreenSurfaceQNX_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceScreenPresentationSupportQNX":
			LoadFunction("vkGetPhysicalDeviceScreenPresentationSupportQNX", out vkGetPhysicalDeviceScreenPresentationSupportQNX_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceScreenPresentationSupportQNX_ptr == null)
				return .Err;
			break;

		case "vkCmdSetColorWriteEnableEXT":
			LoadFunction("vkCmdSetColorWriteEnableEXT", out vkCmdSetColorWriteEnableEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetColorWriteEnableEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdTraceRaysIndirect2KHR":
			LoadFunction("vkCmdTraceRaysIndirect2KHR", out vkCmdTraceRaysIndirect2KHR_ptr, instance, invokeErrorCallback);
			if(vkCmdTraceRaysIndirect2KHR_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawMultiEXT":
			LoadFunction("vkCmdDrawMultiEXT", out vkCmdDrawMultiEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawMultiEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawMultiIndexedEXT":
			LoadFunction("vkCmdDrawMultiIndexedEXT", out vkCmdDrawMultiIndexedEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawMultiIndexedEXT_ptr == null)
				return .Err;
			break;

		case "vkCreateMicromapEXT":
			LoadFunction("vkCreateMicromapEXT", out vkCreateMicromapEXT_ptr, instance, invokeErrorCallback);
			if(vkCreateMicromapEXT_ptr == null)
				return .Err;
			break;

		case "vkDestroyMicromapEXT":
			LoadFunction("vkDestroyMicromapEXT", out vkDestroyMicromapEXT_ptr, instance, invokeErrorCallback);
			if(vkDestroyMicromapEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdBuildMicromapsEXT":
			LoadFunction("vkCmdBuildMicromapsEXT", out vkCmdBuildMicromapsEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdBuildMicromapsEXT_ptr == null)
				return .Err;
			break;

		case "vkBuildMicromapsEXT":
			LoadFunction("vkBuildMicromapsEXT", out vkBuildMicromapsEXT_ptr, instance, invokeErrorCallback);
			if(vkBuildMicromapsEXT_ptr == null)
				return .Err;
			break;

		case "vkCopyMicromapEXT":
			LoadFunction("vkCopyMicromapEXT", out vkCopyMicromapEXT_ptr, instance, invokeErrorCallback);
			if(vkCopyMicromapEXT_ptr == null)
				return .Err;
			break;

		case "vkCopyMicromapToMemoryEXT":
			LoadFunction("vkCopyMicromapToMemoryEXT", out vkCopyMicromapToMemoryEXT_ptr, instance, invokeErrorCallback);
			if(vkCopyMicromapToMemoryEXT_ptr == null)
				return .Err;
			break;

		case "vkCopyMemoryToMicromapEXT":
			LoadFunction("vkCopyMemoryToMicromapEXT", out vkCopyMemoryToMicromapEXT_ptr, instance, invokeErrorCallback);
			if(vkCopyMemoryToMicromapEXT_ptr == null)
				return .Err;
			break;

		case "vkWriteMicromapsPropertiesEXT":
			LoadFunction("vkWriteMicromapsPropertiesEXT", out vkWriteMicromapsPropertiesEXT_ptr, instance, invokeErrorCallback);
			if(vkWriteMicromapsPropertiesEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyMicromapEXT":
			LoadFunction("vkCmdCopyMicromapEXT", out vkCmdCopyMicromapEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyMicromapEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyMicromapToMemoryEXT":
			LoadFunction("vkCmdCopyMicromapToMemoryEXT", out vkCmdCopyMicromapToMemoryEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyMicromapToMemoryEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyMemoryToMicromapEXT":
			LoadFunction("vkCmdCopyMemoryToMicromapEXT", out vkCmdCopyMemoryToMicromapEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyMemoryToMicromapEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdWriteMicromapsPropertiesEXT":
			LoadFunction("vkCmdWriteMicromapsPropertiesEXT", out vkCmdWriteMicromapsPropertiesEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdWriteMicromapsPropertiesEXT_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceMicromapCompatibilityEXT":
			LoadFunction("vkGetDeviceMicromapCompatibilityEXT", out vkGetDeviceMicromapCompatibilityEXT_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceMicromapCompatibilityEXT_ptr == null)
				return .Err;
			break;

		case "vkGetMicromapBuildSizesEXT":
			LoadFunction("vkGetMicromapBuildSizesEXT", out vkGetMicromapBuildSizesEXT_ptr, instance, invokeErrorCallback);
			if(vkGetMicromapBuildSizesEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawClusterHUAWEI":
			LoadFunction("vkCmdDrawClusterHUAWEI", out vkCmdDrawClusterHUAWEI_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawClusterHUAWEI_ptr == null)
				return .Err;
			break;

		case "vkCmdDrawClusterIndirectHUAWEI":
			LoadFunction("vkCmdDrawClusterIndirectHUAWEI", out vkCmdDrawClusterIndirectHUAWEI_ptr, instance, invokeErrorCallback);
			if(vkCmdDrawClusterIndirectHUAWEI_ptr == null)
				return .Err;
			break;

		case "vkSetDeviceMemoryPriorityEXT":
			LoadFunction("vkSetDeviceMemoryPriorityEXT", out vkSetDeviceMemoryPriorityEXT_ptr, instance, invokeErrorCallback);
			if(vkSetDeviceMemoryPriorityEXT_ptr == null)
				return .Err;
			break;

		case "vkGetDescriptorSetLayoutHostMappingInfoVALVE":
			LoadFunction("vkGetDescriptorSetLayoutHostMappingInfoVALVE", out vkGetDescriptorSetLayoutHostMappingInfoVALVE_ptr, instance, invokeErrorCallback);
			if(vkGetDescriptorSetLayoutHostMappingInfoVALVE_ptr == null)
				return .Err;
			break;

		case "vkGetDescriptorSetHostMappingVALVE":
			LoadFunction("vkGetDescriptorSetHostMappingVALVE", out vkGetDescriptorSetHostMappingVALVE_ptr, instance, invokeErrorCallback);
			if(vkGetDescriptorSetHostMappingVALVE_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyMemoryIndirectNV":
			LoadFunction("vkCmdCopyMemoryIndirectNV", out vkCmdCopyMemoryIndirectNV_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyMemoryIndirectNV_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyMemoryToImageIndirectNV":
			LoadFunction("vkCmdCopyMemoryToImageIndirectNV", out vkCmdCopyMemoryToImageIndirectNV_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyMemoryToImageIndirectNV_ptr == null)
				return .Err;
			break;

		case "vkCmdDecompressMemoryNV":
			LoadFunction("vkCmdDecompressMemoryNV", out vkCmdDecompressMemoryNV_ptr, instance, invokeErrorCallback);
			if(vkCmdDecompressMemoryNV_ptr == null)
				return .Err;
			break;

		case "vkCmdDecompressMemoryIndirectCountNV":
			LoadFunction("vkCmdDecompressMemoryIndirectCountNV", out vkCmdDecompressMemoryIndirectCountNV_ptr, instance, invokeErrorCallback);
			if(vkCmdDecompressMemoryIndirectCountNV_ptr == null)
				return .Err;
			break;

		case "vkGetPipelineIndirectMemoryRequirementsNV":
			LoadFunction("vkGetPipelineIndirectMemoryRequirementsNV", out vkGetPipelineIndirectMemoryRequirementsNV_ptr, instance, invokeErrorCallback);
			if(vkGetPipelineIndirectMemoryRequirementsNV_ptr == null)
				return .Err;
			break;

		case "vkCmdUpdatePipelineIndirectBufferNV":
			LoadFunction("vkCmdUpdatePipelineIndirectBufferNV", out vkCmdUpdatePipelineIndirectBufferNV_ptr, instance, invokeErrorCallback);
			if(vkCmdUpdatePipelineIndirectBufferNV_ptr == null)
				return .Err;
			break;

		case "vkGetPipelineIndirectDeviceAddressNV":
			LoadFunction("vkGetPipelineIndirectDeviceAddressNV", out vkGetPipelineIndirectDeviceAddressNV_ptr, instance, invokeErrorCallback);
			if(vkGetPipelineIndirectDeviceAddressNV_ptr == null)
				return .Err;
			break;

		case "vkGetNativeBufferPropertiesOHOS":
			LoadFunction("vkGetNativeBufferPropertiesOHOS", out vkGetNativeBufferPropertiesOHOS_ptr, instance, invokeErrorCallback);
			if(vkGetNativeBufferPropertiesOHOS_ptr == null)
				return .Err;
			break;

		case "vkGetMemoryNativeBufferOHOS":
			LoadFunction("vkGetMemoryNativeBufferOHOS", out vkGetMemoryNativeBufferOHOS_ptr, instance, invokeErrorCallback);
			if(vkGetMemoryNativeBufferOHOS_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDepthClampEnableEXT":
			LoadFunction("vkCmdSetDepthClampEnableEXT", out vkCmdSetDepthClampEnableEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDepthClampEnableEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetPolygonModeEXT":
			LoadFunction("vkCmdSetPolygonModeEXT", out vkCmdSetPolygonModeEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetPolygonModeEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetRasterizationSamplesEXT":
			LoadFunction("vkCmdSetRasterizationSamplesEXT", out vkCmdSetRasterizationSamplesEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetRasterizationSamplesEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetSampleMaskEXT":
			LoadFunction("vkCmdSetSampleMaskEXT", out vkCmdSetSampleMaskEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetSampleMaskEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetAlphaToCoverageEnableEXT":
			LoadFunction("vkCmdSetAlphaToCoverageEnableEXT", out vkCmdSetAlphaToCoverageEnableEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetAlphaToCoverageEnableEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetAlphaToOneEnableEXT":
			LoadFunction("vkCmdSetAlphaToOneEnableEXT", out vkCmdSetAlphaToOneEnableEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetAlphaToOneEnableEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetLogicOpEnableEXT":
			LoadFunction("vkCmdSetLogicOpEnableEXT", out vkCmdSetLogicOpEnableEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetLogicOpEnableEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetColorBlendEnableEXT":
			LoadFunction("vkCmdSetColorBlendEnableEXT", out vkCmdSetColorBlendEnableEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetColorBlendEnableEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetColorBlendEquationEXT":
			LoadFunction("vkCmdSetColorBlendEquationEXT", out vkCmdSetColorBlendEquationEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetColorBlendEquationEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetColorWriteMaskEXT":
			LoadFunction("vkCmdSetColorWriteMaskEXT", out vkCmdSetColorWriteMaskEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetColorWriteMaskEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetTessellationDomainOriginEXT":
			LoadFunction("vkCmdSetTessellationDomainOriginEXT", out vkCmdSetTessellationDomainOriginEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetTessellationDomainOriginEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetRasterizationStreamEXT":
			LoadFunction("vkCmdSetRasterizationStreamEXT", out vkCmdSetRasterizationStreamEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetRasterizationStreamEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetConservativeRasterizationModeEXT":
			LoadFunction("vkCmdSetConservativeRasterizationModeEXT", out vkCmdSetConservativeRasterizationModeEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetConservativeRasterizationModeEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetExtraPrimitiveOverestimationSizeEXT":
			LoadFunction("vkCmdSetExtraPrimitiveOverestimationSizeEXT", out vkCmdSetExtraPrimitiveOverestimationSizeEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetExtraPrimitiveOverestimationSizeEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDepthClipEnableEXT":
			LoadFunction("vkCmdSetDepthClipEnableEXT", out vkCmdSetDepthClipEnableEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDepthClipEnableEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetSampleLocationsEnableEXT":
			LoadFunction("vkCmdSetSampleLocationsEnableEXT", out vkCmdSetSampleLocationsEnableEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetSampleLocationsEnableEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetColorBlendAdvancedEXT":
			LoadFunction("vkCmdSetColorBlendAdvancedEXT", out vkCmdSetColorBlendAdvancedEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetColorBlendAdvancedEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetProvokingVertexModeEXT":
			LoadFunction("vkCmdSetProvokingVertexModeEXT", out vkCmdSetProvokingVertexModeEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetProvokingVertexModeEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetLineRasterizationModeEXT":
			LoadFunction("vkCmdSetLineRasterizationModeEXT", out vkCmdSetLineRasterizationModeEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetLineRasterizationModeEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetLineStippleEnableEXT":
			LoadFunction("vkCmdSetLineStippleEnableEXT", out vkCmdSetLineStippleEnableEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetLineStippleEnableEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDepthClipNegativeOneToOneEXT":
			LoadFunction("vkCmdSetDepthClipNegativeOneToOneEXT", out vkCmdSetDepthClipNegativeOneToOneEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDepthClipNegativeOneToOneEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetViewportWScalingEnableNV":
			LoadFunction("vkCmdSetViewportWScalingEnableNV", out vkCmdSetViewportWScalingEnableNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetViewportWScalingEnableNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetViewportSwizzleNV":
			LoadFunction("vkCmdSetViewportSwizzleNV", out vkCmdSetViewportSwizzleNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetViewportSwizzleNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetCoverageToColorEnableNV":
			LoadFunction("vkCmdSetCoverageToColorEnableNV", out vkCmdSetCoverageToColorEnableNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetCoverageToColorEnableNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetCoverageToColorLocationNV":
			LoadFunction("vkCmdSetCoverageToColorLocationNV", out vkCmdSetCoverageToColorLocationNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetCoverageToColorLocationNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetCoverageModulationModeNV":
			LoadFunction("vkCmdSetCoverageModulationModeNV", out vkCmdSetCoverageModulationModeNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetCoverageModulationModeNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetCoverageModulationTableEnableNV":
			LoadFunction("vkCmdSetCoverageModulationTableEnableNV", out vkCmdSetCoverageModulationTableEnableNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetCoverageModulationTableEnableNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetCoverageModulationTableNV":
			LoadFunction("vkCmdSetCoverageModulationTableNV", out vkCmdSetCoverageModulationTableNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetCoverageModulationTableNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetShadingRateImageEnableNV":
			LoadFunction("vkCmdSetShadingRateImageEnableNV", out vkCmdSetShadingRateImageEnableNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetShadingRateImageEnableNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetRepresentativeFragmentTestEnableNV":
			LoadFunction("vkCmdSetRepresentativeFragmentTestEnableNV", out vkCmdSetRepresentativeFragmentTestEnableNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetRepresentativeFragmentTestEnableNV_ptr == null)
				return .Err;
			break;

		case "vkCmdSetCoverageReductionModeNV":
			LoadFunction("vkCmdSetCoverageReductionModeNV", out vkCmdSetCoverageReductionModeNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetCoverageReductionModeNV_ptr == null)
				return .Err;
			break;

		case "vkCreateTensorARM":
			LoadFunction("vkCreateTensorARM", out vkCreateTensorARM_ptr, instance, invokeErrorCallback);
			if(vkCreateTensorARM_ptr == null)
				return .Err;
			break;

		case "vkDestroyTensorARM":
			LoadFunction("vkDestroyTensorARM", out vkDestroyTensorARM_ptr, instance, invokeErrorCallback);
			if(vkDestroyTensorARM_ptr == null)
				return .Err;
			break;

		case "vkCreateTensorViewARM":
			LoadFunction("vkCreateTensorViewARM", out vkCreateTensorViewARM_ptr, instance, invokeErrorCallback);
			if(vkCreateTensorViewARM_ptr == null)
				return .Err;
			break;

		case "vkDestroyTensorViewARM":
			LoadFunction("vkDestroyTensorViewARM", out vkDestroyTensorViewARM_ptr, instance, invokeErrorCallback);
			if(vkDestroyTensorViewARM_ptr == null)
				return .Err;
			break;

		case "vkGetTensorMemoryRequirementsARM":
			LoadFunction("vkGetTensorMemoryRequirementsARM", out vkGetTensorMemoryRequirementsARM_ptr, instance, invokeErrorCallback);
			if(vkGetTensorMemoryRequirementsARM_ptr == null)
				return .Err;
			break;

		case "vkBindTensorMemoryARM":
			LoadFunction("vkBindTensorMemoryARM", out vkBindTensorMemoryARM_ptr, instance, invokeErrorCallback);
			if(vkBindTensorMemoryARM_ptr == null)
				return .Err;
			break;

		case "vkGetDeviceTensorMemoryRequirementsARM":
			LoadFunction("vkGetDeviceTensorMemoryRequirementsARM", out vkGetDeviceTensorMemoryRequirementsARM_ptr, instance, invokeErrorCallback);
			if(vkGetDeviceTensorMemoryRequirementsARM_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyTensorARM":
			LoadFunction("vkCmdCopyTensorARM", out vkCmdCopyTensorARM_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyTensorARM_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceExternalTensorPropertiesARM":
			LoadFunction("vkGetPhysicalDeviceExternalTensorPropertiesARM", out vkGetPhysicalDeviceExternalTensorPropertiesARM_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceExternalTensorPropertiesARM_ptr == null)
				return .Err;
			break;

		case "vkGetTensorOpaqueCaptureDescriptorDataARM":
			LoadFunction("vkGetTensorOpaqueCaptureDescriptorDataARM", out vkGetTensorOpaqueCaptureDescriptorDataARM_ptr, instance, invokeErrorCallback);
			if(vkGetTensorOpaqueCaptureDescriptorDataARM_ptr == null)
				return .Err;
			break;

		case "vkGetTensorViewOpaqueCaptureDescriptorDataARM":
			LoadFunction("vkGetTensorViewOpaqueCaptureDescriptorDataARM", out vkGetTensorViewOpaqueCaptureDescriptorDataARM_ptr, instance, invokeErrorCallback);
			if(vkGetTensorViewOpaqueCaptureDescriptorDataARM_ptr == null)
				return .Err;
			break;

		case "vkGetShaderModuleIdentifierEXT":
			LoadFunction("vkGetShaderModuleIdentifierEXT", out vkGetShaderModuleIdentifierEXT_ptr, instance, invokeErrorCallback);
			if(vkGetShaderModuleIdentifierEXT_ptr == null)
				return .Err;
			break;

		case "vkGetShaderModuleCreateInfoIdentifierEXT":
			LoadFunction("vkGetShaderModuleCreateInfoIdentifierEXT", out vkGetShaderModuleCreateInfoIdentifierEXT_ptr, instance, invokeErrorCallback);
			if(vkGetShaderModuleCreateInfoIdentifierEXT_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceOpticalFlowImageFormatsNV":
			LoadFunction("vkGetPhysicalDeviceOpticalFlowImageFormatsNV", out vkGetPhysicalDeviceOpticalFlowImageFormatsNV_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceOpticalFlowImageFormatsNV_ptr == null)
				return .Err;
			break;

		case "vkCreateOpticalFlowSessionNV":
			LoadFunction("vkCreateOpticalFlowSessionNV", out vkCreateOpticalFlowSessionNV_ptr, instance, invokeErrorCallback);
			if(vkCreateOpticalFlowSessionNV_ptr == null)
				return .Err;
			break;

		case "vkDestroyOpticalFlowSessionNV":
			LoadFunction("vkDestroyOpticalFlowSessionNV", out vkDestroyOpticalFlowSessionNV_ptr, instance, invokeErrorCallback);
			if(vkDestroyOpticalFlowSessionNV_ptr == null)
				return .Err;
			break;

		case "vkBindOpticalFlowSessionImageNV":
			LoadFunction("vkBindOpticalFlowSessionImageNV", out vkBindOpticalFlowSessionImageNV_ptr, instance, invokeErrorCallback);
			if(vkBindOpticalFlowSessionImageNV_ptr == null)
				return .Err;
			break;

		case "vkCmdOpticalFlowExecuteNV":
			LoadFunction("vkCmdOpticalFlowExecuteNV", out vkCmdOpticalFlowExecuteNV_ptr, instance, invokeErrorCallback);
			if(vkCmdOpticalFlowExecuteNV_ptr == null)
				return .Err;
			break;

		case "vkAntiLagUpdateAMD":
			LoadFunction("vkAntiLagUpdateAMD", out vkAntiLagUpdateAMD_ptr, instance, invokeErrorCallback);
			if(vkAntiLagUpdateAMD_ptr == null)
				return .Err;
			break;

		case "vkWaitForPresent2KHR":
			LoadFunction("vkWaitForPresent2KHR", out vkWaitForPresent2KHR_ptr, instance, invokeErrorCallback);
			if(vkWaitForPresent2KHR_ptr == null)
				return .Err;
			break;

		case "vkCreateShadersEXT":
			LoadFunction("vkCreateShadersEXT", out vkCreateShadersEXT_ptr, instance, invokeErrorCallback);
			if(vkCreateShadersEXT_ptr == null)
				return .Err;
			break;

		case "vkDestroyShaderEXT":
			LoadFunction("vkDestroyShaderEXT", out vkDestroyShaderEXT_ptr, instance, invokeErrorCallback);
			if(vkDestroyShaderEXT_ptr == null)
				return .Err;
			break;

		case "vkGetShaderBinaryDataEXT":
			LoadFunction("vkGetShaderBinaryDataEXT", out vkGetShaderBinaryDataEXT_ptr, instance, invokeErrorCallback);
			if(vkGetShaderBinaryDataEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdBindShadersEXT":
			LoadFunction("vkCmdBindShadersEXT", out vkCmdBindShadersEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdBindShadersEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDepthClampRangeEXT":
			LoadFunction("vkCmdSetDepthClampRangeEXT", out vkCmdSetDepthClampRangeEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDepthClampRangeEXT_ptr == null)
				return .Err;
			break;

		case "vkCreatePipelineBinariesKHR":
			LoadFunction("vkCreatePipelineBinariesKHR", out vkCreatePipelineBinariesKHR_ptr, instance, invokeErrorCallback);
			if(vkCreatePipelineBinariesKHR_ptr == null)
				return .Err;
			break;

		case "vkDestroyPipelineBinaryKHR":
			LoadFunction("vkDestroyPipelineBinaryKHR", out vkDestroyPipelineBinaryKHR_ptr, instance, invokeErrorCallback);
			if(vkDestroyPipelineBinaryKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPipelineKeyKHR":
			LoadFunction("vkGetPipelineKeyKHR", out vkGetPipelineKeyKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPipelineKeyKHR_ptr == null)
				return .Err;
			break;

		case "vkGetPipelineBinaryDataKHR":
			LoadFunction("vkGetPipelineBinaryDataKHR", out vkGetPipelineBinaryDataKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPipelineBinaryDataKHR_ptr == null)
				return .Err;
			break;

		case "vkReleaseCapturedPipelineDataKHR":
			LoadFunction("vkReleaseCapturedPipelineDataKHR", out vkReleaseCapturedPipelineDataKHR_ptr, instance, invokeErrorCallback);
			if(vkReleaseCapturedPipelineDataKHR_ptr == null)
				return .Err;
			break;

		case "vkGetFramebufferTilePropertiesQCOM":
			LoadFunction("vkGetFramebufferTilePropertiesQCOM", out vkGetFramebufferTilePropertiesQCOM_ptr, instance, invokeErrorCallback);
			if(vkGetFramebufferTilePropertiesQCOM_ptr == null)
				return .Err;
			break;

		case "vkGetDynamicRenderingTilePropertiesQCOM":
			LoadFunction("vkGetDynamicRenderingTilePropertiesQCOM", out vkGetDynamicRenderingTilePropertiesQCOM_ptr, instance, invokeErrorCallback);
			if(vkGetDynamicRenderingTilePropertiesQCOM_ptr == null)
				return .Err;
			break;

		case "vkCreateSemaphoreSciSyncPoolNV":
			LoadFunction("vkCreateSemaphoreSciSyncPoolNV", out vkCreateSemaphoreSciSyncPoolNV_ptr, instance, invokeErrorCallback);
			if(vkCreateSemaphoreSciSyncPoolNV_ptr == null)
				return .Err;
			break;

		case "vkDestroySemaphoreSciSyncPoolNV":
			LoadFunction("vkDestroySemaphoreSciSyncPoolNV", out vkDestroySemaphoreSciSyncPoolNV_ptr, instance, invokeErrorCallback);
			if(vkDestroySemaphoreSciSyncPoolNV_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceCooperativeVectorPropertiesNV":
			LoadFunction("vkGetPhysicalDeviceCooperativeVectorPropertiesNV", out vkGetPhysicalDeviceCooperativeVectorPropertiesNV_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceCooperativeVectorPropertiesNV_ptr == null)
				return .Err;
			break;

		case "vkConvertCooperativeVectorMatrixNV":
			LoadFunction("vkConvertCooperativeVectorMatrixNV", out vkConvertCooperativeVectorMatrixNV_ptr, instance, invokeErrorCallback);
			if(vkConvertCooperativeVectorMatrixNV_ptr == null)
				return .Err;
			break;

		case "vkCmdConvertCooperativeVectorMatrixNV":
			LoadFunction("vkCmdConvertCooperativeVectorMatrixNV", out vkCmdConvertCooperativeVectorMatrixNV_ptr, instance, invokeErrorCallback);
			if(vkCmdConvertCooperativeVectorMatrixNV_ptr == null)
				return .Err;
			break;

		case "vkSetLatencySleepModeNV":
			LoadFunction("vkSetLatencySleepModeNV", out vkSetLatencySleepModeNV_ptr, instance, invokeErrorCallback);
			if(vkSetLatencySleepModeNV_ptr == null)
				return .Err;
			break;

		case "vkLatencySleepNV":
			LoadFunction("vkLatencySleepNV", out vkLatencySleepNV_ptr, instance, invokeErrorCallback);
			if(vkLatencySleepNV_ptr == null)
				return .Err;
			break;

		case "vkSetLatencyMarkerNV":
			LoadFunction("vkSetLatencyMarkerNV", out vkSetLatencyMarkerNV_ptr, instance, invokeErrorCallback);
			if(vkSetLatencyMarkerNV_ptr == null)
				return .Err;
			break;

		case "vkGetLatencyTimingsNV":
			LoadFunction("vkGetLatencyTimingsNV", out vkGetLatencyTimingsNV_ptr, instance, invokeErrorCallback);
			if(vkGetLatencyTimingsNV_ptr == null)
				return .Err;
			break;

		case "vkQueueNotifyOutOfBandNV":
			LoadFunction("vkQueueNotifyOutOfBandNV", out vkQueueNotifyOutOfBandNV_ptr, instance, invokeErrorCallback);
			if(vkQueueNotifyOutOfBandNV_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR":
			LoadFunction("vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR", out vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR_ptr == null)
				return .Err;
			break;

		case "vkCreateDataGraphPipelinesARM":
			LoadFunction("vkCreateDataGraphPipelinesARM", out vkCreateDataGraphPipelinesARM_ptr, instance, invokeErrorCallback);
			if(vkCreateDataGraphPipelinesARM_ptr == null)
				return .Err;
			break;

		case "vkCreateDataGraphPipelineSessionARM":
			LoadFunction("vkCreateDataGraphPipelineSessionARM", out vkCreateDataGraphPipelineSessionARM_ptr, instance, invokeErrorCallback);
			if(vkCreateDataGraphPipelineSessionARM_ptr == null)
				return .Err;
			break;

		case "vkGetDataGraphPipelineSessionBindPointRequirementsARM":
			LoadFunction("vkGetDataGraphPipelineSessionBindPointRequirementsARM", out vkGetDataGraphPipelineSessionBindPointRequirementsARM_ptr, instance, invokeErrorCallback);
			if(vkGetDataGraphPipelineSessionBindPointRequirementsARM_ptr == null)
				return .Err;
			break;

		case "vkGetDataGraphPipelineSessionMemoryRequirementsARM":
			LoadFunction("vkGetDataGraphPipelineSessionMemoryRequirementsARM", out vkGetDataGraphPipelineSessionMemoryRequirementsARM_ptr, instance, invokeErrorCallback);
			if(vkGetDataGraphPipelineSessionMemoryRequirementsARM_ptr == null)
				return .Err;
			break;

		case "vkBindDataGraphPipelineSessionMemoryARM":
			LoadFunction("vkBindDataGraphPipelineSessionMemoryARM", out vkBindDataGraphPipelineSessionMemoryARM_ptr, instance, invokeErrorCallback);
			if(vkBindDataGraphPipelineSessionMemoryARM_ptr == null)
				return .Err;
			break;

		case "vkDestroyDataGraphPipelineSessionARM":
			LoadFunction("vkDestroyDataGraphPipelineSessionARM", out vkDestroyDataGraphPipelineSessionARM_ptr, instance, invokeErrorCallback);
			if(vkDestroyDataGraphPipelineSessionARM_ptr == null)
				return .Err;
			break;

		case "vkCmdDispatchDataGraphARM":
			LoadFunction("vkCmdDispatchDataGraphARM", out vkCmdDispatchDataGraphARM_ptr, instance, invokeErrorCallback);
			if(vkCmdDispatchDataGraphARM_ptr == null)
				return .Err;
			break;

		case "vkGetDataGraphPipelineAvailablePropertiesARM":
			LoadFunction("vkGetDataGraphPipelineAvailablePropertiesARM", out vkGetDataGraphPipelineAvailablePropertiesARM_ptr, instance, invokeErrorCallback);
			if(vkGetDataGraphPipelineAvailablePropertiesARM_ptr == null)
				return .Err;
			break;

		case "vkGetDataGraphPipelinePropertiesARM":
			LoadFunction("vkGetDataGraphPipelinePropertiesARM", out vkGetDataGraphPipelinePropertiesARM_ptr, instance, invokeErrorCallback);
			if(vkGetDataGraphPipelinePropertiesARM_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM":
			LoadFunction("vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM", out vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM":
			LoadFunction("vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM", out vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM_ptr == null)
				return .Err;
			break;

		case "vkCmdSetAttachmentFeedbackLoopEnableEXT":
			LoadFunction("vkCmdSetAttachmentFeedbackLoopEnableEXT", out vkCmdSetAttachmentFeedbackLoopEnableEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetAttachmentFeedbackLoopEnableEXT_ptr == null)
				return .Err;
			break;

		case "vkGetScreenBufferPropertiesQNX":
			LoadFunction("vkGetScreenBufferPropertiesQNX", out vkGetScreenBufferPropertiesQNX_ptr, instance, invokeErrorCallback);
			if(vkGetScreenBufferPropertiesQNX_ptr == null)
				return .Err;
			break;

		case "vkCmdSetDescriptorBufferOffsets2EXT":
			LoadFunction("vkCmdSetDescriptorBufferOffsets2EXT", out vkCmdSetDescriptorBufferOffsets2EXT_ptr, instance, invokeErrorCallback);
			if(vkCmdSetDescriptorBufferOffsets2EXT_ptr == null)
				return .Err;
			break;

		case "vkCmdBindDescriptorBufferEmbeddedSamplers2EXT":
			LoadFunction("vkCmdBindDescriptorBufferEmbeddedSamplers2EXT", out vkCmdBindDescriptorBufferEmbeddedSamplers2EXT_ptr, instance, invokeErrorCallback);
			if(vkCmdBindDescriptorBufferEmbeddedSamplers2EXT_ptr == null)
				return .Err;
			break;

		case "vkCmdBindTileMemoryQCOM":
			LoadFunction("vkCmdBindTileMemoryQCOM", out vkCmdBindTileMemoryQCOM_ptr, instance, invokeErrorCallback);
			if(vkCmdBindTileMemoryQCOM_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyMemoryIndirectKHR":
			LoadFunction("vkCmdCopyMemoryIndirectKHR", out vkCmdCopyMemoryIndirectKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyMemoryIndirectKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdCopyMemoryToImageIndirectKHR":
			LoadFunction("vkCmdCopyMemoryToImageIndirectKHR", out vkCmdCopyMemoryToImageIndirectKHR_ptr, instance, invokeErrorCallback);
			if(vkCmdCopyMemoryToImageIndirectKHR_ptr == null)
				return .Err;
			break;

		case "vkCmdDecompressMemoryEXT":
			LoadFunction("vkCmdDecompressMemoryEXT", out vkCmdDecompressMemoryEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdDecompressMemoryEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdDecompressMemoryIndirectCountEXT":
			LoadFunction("vkCmdDecompressMemoryIndirectCountEXT", out vkCmdDecompressMemoryIndirectCountEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdDecompressMemoryIndirectCountEXT_ptr == null)
				return .Err;
			break;

		case "vkCreateExternalComputeQueueNV":
			LoadFunction("vkCreateExternalComputeQueueNV", out vkCreateExternalComputeQueueNV_ptr, instance, invokeErrorCallback);
			if(vkCreateExternalComputeQueueNV_ptr == null)
				return .Err;
			break;

		case "vkDestroyExternalComputeQueueNV":
			LoadFunction("vkDestroyExternalComputeQueueNV", out vkDestroyExternalComputeQueueNV_ptr, instance, invokeErrorCallback);
			if(vkDestroyExternalComputeQueueNV_ptr == null)
				return .Err;
			break;

		case "vkGetExternalComputeQueueDataNV":
			LoadFunction("vkGetExternalComputeQueueDataNV", out vkGetExternalComputeQueueDataNV_ptr, instance, invokeErrorCallback);
			if(vkGetExternalComputeQueueDataNV_ptr == null)
				return .Err;
			break;

		case "vkGetClusterAccelerationStructureBuildSizesNV":
			LoadFunction("vkGetClusterAccelerationStructureBuildSizesNV", out vkGetClusterAccelerationStructureBuildSizesNV_ptr, instance, invokeErrorCallback);
			if(vkGetClusterAccelerationStructureBuildSizesNV_ptr == null)
				return .Err;
			break;

		case "vkCmdBuildClusterAccelerationStructureIndirectNV":
			LoadFunction("vkCmdBuildClusterAccelerationStructureIndirectNV", out vkCmdBuildClusterAccelerationStructureIndirectNV_ptr, instance, invokeErrorCallback);
			if(vkCmdBuildClusterAccelerationStructureIndirectNV_ptr == null)
				return .Err;
			break;

		case "vkGetPartitionedAccelerationStructuresBuildSizesNV":
			LoadFunction("vkGetPartitionedAccelerationStructuresBuildSizesNV", out vkGetPartitionedAccelerationStructuresBuildSizesNV_ptr, instance, invokeErrorCallback);
			if(vkGetPartitionedAccelerationStructuresBuildSizesNV_ptr == null)
				return .Err;
			break;

		case "vkCmdBuildPartitionedAccelerationStructuresNV":
			LoadFunction("vkCmdBuildPartitionedAccelerationStructuresNV", out vkCmdBuildPartitionedAccelerationStructuresNV_ptr, instance, invokeErrorCallback);
			if(vkCmdBuildPartitionedAccelerationStructuresNV_ptr == null)
				return .Err;
			break;

		case "vkGetGeneratedCommandsMemoryRequirementsEXT":
			LoadFunction("vkGetGeneratedCommandsMemoryRequirementsEXT", out vkGetGeneratedCommandsMemoryRequirementsEXT_ptr, instance, invokeErrorCallback);
			if(vkGetGeneratedCommandsMemoryRequirementsEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdPreprocessGeneratedCommandsEXT":
			LoadFunction("vkCmdPreprocessGeneratedCommandsEXT", out vkCmdPreprocessGeneratedCommandsEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdPreprocessGeneratedCommandsEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdExecuteGeneratedCommandsEXT":
			LoadFunction("vkCmdExecuteGeneratedCommandsEXT", out vkCmdExecuteGeneratedCommandsEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdExecuteGeneratedCommandsEXT_ptr == null)
				return .Err;
			break;

		case "vkCreateIndirectCommandsLayoutEXT":
			LoadFunction("vkCreateIndirectCommandsLayoutEXT", out vkCreateIndirectCommandsLayoutEXT_ptr, instance, invokeErrorCallback);
			if(vkCreateIndirectCommandsLayoutEXT_ptr == null)
				return .Err;
			break;

		case "vkDestroyIndirectCommandsLayoutEXT":
			LoadFunction("vkDestroyIndirectCommandsLayoutEXT", out vkDestroyIndirectCommandsLayoutEXT_ptr, instance, invokeErrorCallback);
			if(vkDestroyIndirectCommandsLayoutEXT_ptr == null)
				return .Err;
			break;

		case "vkCreateIndirectExecutionSetEXT":
			LoadFunction("vkCreateIndirectExecutionSetEXT", out vkCreateIndirectExecutionSetEXT_ptr, instance, invokeErrorCallback);
			if(vkCreateIndirectExecutionSetEXT_ptr == null)
				return .Err;
			break;

		case "vkDestroyIndirectExecutionSetEXT":
			LoadFunction("vkDestroyIndirectExecutionSetEXT", out vkDestroyIndirectExecutionSetEXT_ptr, instance, invokeErrorCallback);
			if(vkDestroyIndirectExecutionSetEXT_ptr == null)
				return .Err;
			break;

		case "vkUpdateIndirectExecutionSetPipelineEXT":
			LoadFunction("vkUpdateIndirectExecutionSetPipelineEXT", out vkUpdateIndirectExecutionSetPipelineEXT_ptr, instance, invokeErrorCallback);
			if(vkUpdateIndirectExecutionSetPipelineEXT_ptr == null)
				return .Err;
			break;

		case "vkUpdateIndirectExecutionSetShaderEXT":
			LoadFunction("vkUpdateIndirectExecutionSetShaderEXT", out vkUpdateIndirectExecutionSetShaderEXT_ptr, instance, invokeErrorCallback);
			if(vkUpdateIndirectExecutionSetShaderEXT_ptr == null)
				return .Err;
			break;

		case "vkCreateSurfaceOHOS":
			LoadFunction("vkCreateSurfaceOHOS", out vkCreateSurfaceOHOS_ptr, instance, invokeErrorCallback);
			if(vkCreateSurfaceOHOS_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV":
			LoadFunction("vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV", out vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV_ptr == null)
				return .Err;
			break;

		case "vkGetMemoryMetalHandleEXT":
			LoadFunction("vkGetMemoryMetalHandleEXT", out vkGetMemoryMetalHandleEXT_ptr, instance, invokeErrorCallback);
			if(vkGetMemoryMetalHandleEXT_ptr == null)
				return .Err;
			break;

		case "vkGetMemoryMetalHandlePropertiesEXT":
			LoadFunction("vkGetMemoryMetalHandlePropertiesEXT", out vkGetMemoryMetalHandlePropertiesEXT_ptr, instance, invokeErrorCallback);
			if(vkGetMemoryMetalHandlePropertiesEXT_ptr == null)
				return .Err;
			break;

		case "vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM":
			LoadFunction("vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM", out vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM_ptr, instance, invokeErrorCallback);
			if(vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM_ptr == null)
				return .Err;
			break;

		case "vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM":
			LoadFunction("vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM", out vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM_ptr, instance, invokeErrorCallback);
			if(vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM_ptr == null)
				return .Err;
			break;

		case "vkCreateShaderInstrumentationARM":
			LoadFunction("vkCreateShaderInstrumentationARM", out vkCreateShaderInstrumentationARM_ptr, instance, invokeErrorCallback);
			if(vkCreateShaderInstrumentationARM_ptr == null)
				return .Err;
			break;

		case "vkDestroyShaderInstrumentationARM":
			LoadFunction("vkDestroyShaderInstrumentationARM", out vkDestroyShaderInstrumentationARM_ptr, instance, invokeErrorCallback);
			if(vkDestroyShaderInstrumentationARM_ptr == null)
				return .Err;
			break;

		case "vkCmdBeginShaderInstrumentationARM":
			LoadFunction("vkCmdBeginShaderInstrumentationARM", out vkCmdBeginShaderInstrumentationARM_ptr, instance, invokeErrorCallback);
			if(vkCmdBeginShaderInstrumentationARM_ptr == null)
				return .Err;
			break;

		case "vkCmdEndShaderInstrumentationARM":
			LoadFunction("vkCmdEndShaderInstrumentationARM", out vkCmdEndShaderInstrumentationARM_ptr, instance, invokeErrorCallback);
			if(vkCmdEndShaderInstrumentationARM_ptr == null)
				return .Err;
			break;

		case "vkGetShaderInstrumentationValuesARM":
			LoadFunction("vkGetShaderInstrumentationValuesARM", out vkGetShaderInstrumentationValuesARM_ptr, instance, invokeErrorCallback);
			if(vkGetShaderInstrumentationValuesARM_ptr == null)
				return .Err;
			break;

		case "vkClearShaderInstrumentationMetricsARM":
			LoadFunction("vkClearShaderInstrumentationMetricsARM", out vkClearShaderInstrumentationMetricsARM_ptr, instance, invokeErrorCallback);
			if(vkClearShaderInstrumentationMetricsARM_ptr == null)
				return .Err;
			break;

		case "vkCmdEndRendering2KHR":
			LoadFunction("vkCmdEndRendering2KHR", out vkCmdEndRendering2KHR_ptr, instance, invokeErrorCallback);
			if(vkCmdEndRendering2KHR_ptr == null)
				return .Err;
			break;

		case "vkCmdBeginCustomResolveEXT":
			LoadFunction("vkCmdBeginCustomResolveEXT", out vkCmdBeginCustomResolveEXT_ptr, instance, invokeErrorCallback);
			if(vkCmdBeginCustomResolveEXT_ptr == null)
				return .Err;
			break;

		case "vkCmdSetComputeOccupancyPriorityNV":
			LoadFunction("vkCmdSetComputeOccupancyPriorityNV", out vkCmdSetComputeOccupancyPriorityNV_ptr, instance, invokeErrorCallback);
			if(vkCmdSetComputeOccupancyPriorityNV_ptr == null)
				return .Err;
			break;

		case "vkCreateUbmSurfaceSEC":
			LoadFunction("vkCreateUbmSurfaceSEC", out vkCreateUbmSurfaceSEC_ptr, instance, invokeErrorCallback);
			if(vkCreateUbmSurfaceSEC_ptr == null)
				return .Err;
			break;

		case "vkGetPhysicalDeviceUbmPresentationSupportSEC":
			LoadFunction("vkGetPhysicalDeviceUbmPresentationSupportSEC", out vkGetPhysicalDeviceUbmPresentationSupportSEC_ptr, instance, invokeErrorCallback);
			if(vkGetPhysicalDeviceUbmPresentationSupportSEC_ptr == null)
				return .Err;
			break;

		default:
			Runtime.FatalError(scope $"Unknown function name '{name}'.");
		}
		return .Ok;
	}

	private static void LoadAllFuncions(VkInstance? instance = null, List<String> excludeFunctions = null)
	{
		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateInstance"))
			LoadFunction("vkCreateInstance", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyInstance"))
			LoadFunction("vkDestroyInstance", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkEnumeratePhysicalDevices"))
			LoadFunction("vkEnumeratePhysicalDevices", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceFeatures"))
			LoadFunction("vkGetPhysicalDeviceFeatures", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceFormatProperties"))
			LoadFunction("vkGetPhysicalDeviceFormatProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceImageFormatProperties"))
			LoadFunction("vkGetPhysicalDeviceImageFormatProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceProperties"))
			LoadFunction("vkGetPhysicalDeviceProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceQueueFamilyProperties"))
			LoadFunction("vkGetPhysicalDeviceQueueFamilyProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceMemoryProperties"))
			LoadFunction("vkGetPhysicalDeviceMemoryProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetInstanceProcAddr"))
			LoadFunction("vkGetInstanceProcAddr", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceProcAddr"))
			LoadFunction("vkGetDeviceProcAddr", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateDevice"))
			LoadFunction("vkCreateDevice", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyDevice"))
			LoadFunction("vkDestroyDevice", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkEnumerateInstanceExtensionProperties"))
			LoadFunction("vkEnumerateInstanceExtensionProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkEnumerateDeviceExtensionProperties"))
			LoadFunction("vkEnumerateDeviceExtensionProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkEnumerateInstanceLayerProperties"))
			LoadFunction("vkEnumerateInstanceLayerProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkEnumerateDeviceLayerProperties"))
			LoadFunction("vkEnumerateDeviceLayerProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceQueue"))
			LoadFunction("vkGetDeviceQueue", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkQueueSubmit"))
			LoadFunction("vkQueueSubmit", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkQueueWaitIdle"))
			LoadFunction("vkQueueWaitIdle", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDeviceWaitIdle"))
			LoadFunction("vkDeviceWaitIdle", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkAllocateMemory"))
			LoadFunction("vkAllocateMemory", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkFreeMemory"))
			LoadFunction("vkFreeMemory", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkMapMemory"))
			LoadFunction("vkMapMemory", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkUnmapMemory"))
			LoadFunction("vkUnmapMemory", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkFlushMappedMemoryRanges"))
			LoadFunction("vkFlushMappedMemoryRanges", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkInvalidateMappedMemoryRanges"))
			LoadFunction("vkInvalidateMappedMemoryRanges", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceMemoryCommitment"))
			LoadFunction("vkGetDeviceMemoryCommitment", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkBindBufferMemory"))
			LoadFunction("vkBindBufferMemory", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkBindImageMemory"))
			LoadFunction("vkBindImageMemory", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetBufferMemoryRequirements"))
			LoadFunction("vkGetBufferMemoryRequirements", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetImageMemoryRequirements"))
			LoadFunction("vkGetImageMemoryRequirements", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetImageSparseMemoryRequirements"))
			LoadFunction("vkGetImageSparseMemoryRequirements", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceSparseImageFormatProperties"))
			LoadFunction("vkGetPhysicalDeviceSparseImageFormatProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkQueueBindSparse"))
			LoadFunction("vkQueueBindSparse", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateFence"))
			LoadFunction("vkCreateFence", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyFence"))
			LoadFunction("vkDestroyFence", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkResetFences"))
			LoadFunction("vkResetFences", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetFenceStatus"))
			LoadFunction("vkGetFenceStatus", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkWaitForFences"))
			LoadFunction("vkWaitForFences", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateSemaphore"))
			LoadFunction("vkCreateSemaphore", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroySemaphore"))
			LoadFunction("vkDestroySemaphore", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateQueryPool"))
			LoadFunction("vkCreateQueryPool", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyQueryPool"))
			LoadFunction("vkDestroyQueryPool", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetQueryPoolResults"))
			LoadFunction("vkGetQueryPoolResults", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateBuffer"))
			LoadFunction("vkCreateBuffer", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyBuffer"))
			LoadFunction("vkDestroyBuffer", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateImage"))
			LoadFunction("vkCreateImage", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyImage"))
			LoadFunction("vkDestroyImage", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetImageSubresourceLayout"))
			LoadFunction("vkGetImageSubresourceLayout", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateImageView"))
			LoadFunction("vkCreateImageView", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyImageView"))
			LoadFunction("vkDestroyImageView", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateCommandPool"))
			LoadFunction("vkCreateCommandPool", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyCommandPool"))
			LoadFunction("vkDestroyCommandPool", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkResetCommandPool"))
			LoadFunction("vkResetCommandPool", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkAllocateCommandBuffers"))
			LoadFunction("vkAllocateCommandBuffers", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkFreeCommandBuffers"))
			LoadFunction("vkFreeCommandBuffers", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkBeginCommandBuffer"))
			LoadFunction("vkBeginCommandBuffer", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkEndCommandBuffer"))
			LoadFunction("vkEndCommandBuffer", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkResetCommandBuffer"))
			LoadFunction("vkResetCommandBuffer", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyBuffer"))
			LoadFunction("vkCmdCopyBuffer", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyImage"))
			LoadFunction("vkCmdCopyImage", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyBufferToImage"))
			LoadFunction("vkCmdCopyBufferToImage", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyImageToBuffer"))
			LoadFunction("vkCmdCopyImageToBuffer", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdUpdateBuffer"))
			LoadFunction("vkCmdUpdateBuffer", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdFillBuffer"))
			LoadFunction("vkCmdFillBuffer", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdPipelineBarrier"))
			LoadFunction("vkCmdPipelineBarrier", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBeginQuery"))
			LoadFunction("vkCmdBeginQuery", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdEndQuery"))
			LoadFunction("vkCmdEndQuery", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdResetQueryPool"))
			LoadFunction("vkCmdResetQueryPool", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdWriteTimestamp"))
			LoadFunction("vkCmdWriteTimestamp", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyQueryPoolResults"))
			LoadFunction("vkCmdCopyQueryPoolResults", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdExecuteCommands"))
			LoadFunction("vkCmdExecuteCommands", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateEvent"))
			LoadFunction("vkCreateEvent", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyEvent"))
			LoadFunction("vkDestroyEvent", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetEventStatus"))
			LoadFunction("vkGetEventStatus", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSetEvent"))
			LoadFunction("vkSetEvent", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkResetEvent"))
			LoadFunction("vkResetEvent", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateBufferView"))
			LoadFunction("vkCreateBufferView", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyBufferView"))
			LoadFunction("vkDestroyBufferView", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateShaderModule"))
			LoadFunction("vkCreateShaderModule", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyShaderModule"))
			LoadFunction("vkDestroyShaderModule", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreatePipelineCache"))
			LoadFunction("vkCreatePipelineCache", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyPipelineCache"))
			LoadFunction("vkDestroyPipelineCache", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPipelineCacheData"))
			LoadFunction("vkGetPipelineCacheData", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkMergePipelineCaches"))
			LoadFunction("vkMergePipelineCaches", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateComputePipelines"))
			LoadFunction("vkCreateComputePipelines", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyPipeline"))
			LoadFunction("vkDestroyPipeline", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreatePipelineLayout"))
			LoadFunction("vkCreatePipelineLayout", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyPipelineLayout"))
			LoadFunction("vkDestroyPipelineLayout", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateSampler"))
			LoadFunction("vkCreateSampler", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroySampler"))
			LoadFunction("vkDestroySampler", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateDescriptorSetLayout"))
			LoadFunction("vkCreateDescriptorSetLayout", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyDescriptorSetLayout"))
			LoadFunction("vkDestroyDescriptorSetLayout", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateDescriptorPool"))
			LoadFunction("vkCreateDescriptorPool", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyDescriptorPool"))
			LoadFunction("vkDestroyDescriptorPool", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkResetDescriptorPool"))
			LoadFunction("vkResetDescriptorPool", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkAllocateDescriptorSets"))
			LoadFunction("vkAllocateDescriptorSets", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkFreeDescriptorSets"))
			LoadFunction("vkFreeDescriptorSets", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkUpdateDescriptorSets"))
			LoadFunction("vkUpdateDescriptorSets", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindPipeline"))
			LoadFunction("vkCmdBindPipeline", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindDescriptorSets"))
			LoadFunction("vkCmdBindDescriptorSets", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdClearColorImage"))
			LoadFunction("vkCmdClearColorImage", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDispatch"))
			LoadFunction("vkCmdDispatch", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDispatchIndirect"))
			LoadFunction("vkCmdDispatchIndirect", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetEvent"))
			LoadFunction("vkCmdSetEvent", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdResetEvent"))
			LoadFunction("vkCmdResetEvent", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdWaitEvents"))
			LoadFunction("vkCmdWaitEvents", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdPushConstants"))
			LoadFunction("vkCmdPushConstants", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateGraphicsPipelines"))
			LoadFunction("vkCreateGraphicsPipelines", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateFramebuffer"))
			LoadFunction("vkCreateFramebuffer", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyFramebuffer"))
			LoadFunction("vkDestroyFramebuffer", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateRenderPass"))
			LoadFunction("vkCreateRenderPass", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyRenderPass"))
			LoadFunction("vkDestroyRenderPass", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetRenderAreaGranularity"))
			LoadFunction("vkGetRenderAreaGranularity", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetViewport"))
			LoadFunction("vkCmdSetViewport", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetScissor"))
			LoadFunction("vkCmdSetScissor", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetLineWidth"))
			LoadFunction("vkCmdSetLineWidth", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDepthBias"))
			LoadFunction("vkCmdSetDepthBias", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetBlendConstants"))
			LoadFunction("vkCmdSetBlendConstants", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDepthBounds"))
			LoadFunction("vkCmdSetDepthBounds", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetStencilCompareMask"))
			LoadFunction("vkCmdSetStencilCompareMask", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetStencilWriteMask"))
			LoadFunction("vkCmdSetStencilWriteMask", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetStencilReference"))
			LoadFunction("vkCmdSetStencilReference", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindIndexBuffer"))
			LoadFunction("vkCmdBindIndexBuffer", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindVertexBuffers"))
			LoadFunction("vkCmdBindVertexBuffers", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDraw"))
			LoadFunction("vkCmdDraw", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawIndexed"))
			LoadFunction("vkCmdDrawIndexed", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawIndirect"))
			LoadFunction("vkCmdDrawIndirect", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawIndexedIndirect"))
			LoadFunction("vkCmdDrawIndexedIndirect", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBlitImage"))
			LoadFunction("vkCmdBlitImage", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdClearDepthStencilImage"))
			LoadFunction("vkCmdClearDepthStencilImage", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdClearAttachments"))
			LoadFunction("vkCmdClearAttachments", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdResolveImage"))
			LoadFunction("vkCmdResolveImage", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBeginRenderPass"))
			LoadFunction("vkCmdBeginRenderPass", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdNextSubpass"))
			LoadFunction("vkCmdNextSubpass", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdEndRenderPass"))
			LoadFunction("vkCmdEndRenderPass", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkEnumerateInstanceVersion"))
			LoadFunction("vkEnumerateInstanceVersion", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkBindBufferMemory2"))
			LoadFunction("vkBindBufferMemory2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkBindImageMemory2"))
			LoadFunction("vkBindImageMemory2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceGroupPeerMemoryFeatures"))
			LoadFunction("vkGetDeviceGroupPeerMemoryFeatures", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDeviceMask"))
			LoadFunction("vkCmdSetDeviceMask", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkEnumeratePhysicalDeviceGroups"))
			LoadFunction("vkEnumeratePhysicalDeviceGroups", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetImageMemoryRequirements2"))
			LoadFunction("vkGetImageMemoryRequirements2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetBufferMemoryRequirements2"))
			LoadFunction("vkGetBufferMemoryRequirements2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetImageSparseMemoryRequirements2"))
			LoadFunction("vkGetImageSparseMemoryRequirements2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceFeatures2"))
			LoadFunction("vkGetPhysicalDeviceFeatures2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceProperties2"))
			LoadFunction("vkGetPhysicalDeviceProperties2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceFormatProperties2"))
			LoadFunction("vkGetPhysicalDeviceFormatProperties2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceImageFormatProperties2"))
			LoadFunction("vkGetPhysicalDeviceImageFormatProperties2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceQueueFamilyProperties2"))
			LoadFunction("vkGetPhysicalDeviceQueueFamilyProperties2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceMemoryProperties2"))
			LoadFunction("vkGetPhysicalDeviceMemoryProperties2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceSparseImageFormatProperties2"))
			LoadFunction("vkGetPhysicalDeviceSparseImageFormatProperties2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkTrimCommandPool"))
			LoadFunction("vkTrimCommandPool", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceQueue2"))
			LoadFunction("vkGetDeviceQueue2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceExternalBufferProperties"))
			LoadFunction("vkGetPhysicalDeviceExternalBufferProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceExternalFenceProperties"))
			LoadFunction("vkGetPhysicalDeviceExternalFenceProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceExternalSemaphoreProperties"))
			LoadFunction("vkGetPhysicalDeviceExternalSemaphoreProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDispatchBase"))
			LoadFunction("vkCmdDispatchBase", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateDescriptorUpdateTemplate"))
			LoadFunction("vkCreateDescriptorUpdateTemplate", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyDescriptorUpdateTemplate"))
			LoadFunction("vkDestroyDescriptorUpdateTemplate", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkUpdateDescriptorSetWithTemplate"))
			LoadFunction("vkUpdateDescriptorSetWithTemplate", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDescriptorSetLayoutSupport"))
			LoadFunction("vkGetDescriptorSetLayoutSupport", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateSamplerYcbcrConversion"))
			LoadFunction("vkCreateSamplerYcbcrConversion", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroySamplerYcbcrConversion"))
			LoadFunction("vkDestroySamplerYcbcrConversion", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkResetQueryPool"))
			LoadFunction("vkResetQueryPool", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetSemaphoreCounterValue"))
			LoadFunction("vkGetSemaphoreCounterValue", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkWaitSemaphores"))
			LoadFunction("vkWaitSemaphores", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSignalSemaphore"))
			LoadFunction("vkSignalSemaphore", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetBufferDeviceAddress"))
			LoadFunction("vkGetBufferDeviceAddress", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetBufferOpaqueCaptureAddress"))
			LoadFunction("vkGetBufferOpaqueCaptureAddress", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceMemoryOpaqueCaptureAddress"))
			LoadFunction("vkGetDeviceMemoryOpaqueCaptureAddress", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawIndirectCount"))
			LoadFunction("vkCmdDrawIndirectCount", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawIndexedIndirectCount"))
			LoadFunction("vkCmdDrawIndexedIndirectCount", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateRenderPass2"))
			LoadFunction("vkCreateRenderPass2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBeginRenderPass2"))
			LoadFunction("vkCmdBeginRenderPass2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdNextSubpass2"))
			LoadFunction("vkCmdNextSubpass2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdEndRenderPass2"))
			LoadFunction("vkCmdEndRenderPass2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceToolProperties"))
			LoadFunction("vkGetPhysicalDeviceToolProperties", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreatePrivateDataSlot"))
			LoadFunction("vkCreatePrivateDataSlot", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyPrivateDataSlot"))
			LoadFunction("vkDestroyPrivateDataSlot", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSetPrivateData"))
			LoadFunction("vkSetPrivateData", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPrivateData"))
			LoadFunction("vkGetPrivateData", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdPipelineBarrier2"))
			LoadFunction("vkCmdPipelineBarrier2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdWriteTimestamp2"))
			LoadFunction("vkCmdWriteTimestamp2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkQueueSubmit2"))
			LoadFunction("vkQueueSubmit2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyBuffer2"))
			LoadFunction("vkCmdCopyBuffer2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyImage2"))
			LoadFunction("vkCmdCopyImage2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyBufferToImage2"))
			LoadFunction("vkCmdCopyBufferToImage2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyImageToBuffer2"))
			LoadFunction("vkCmdCopyImageToBuffer2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceBufferMemoryRequirements"))
			LoadFunction("vkGetDeviceBufferMemoryRequirements", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceImageMemoryRequirements"))
			LoadFunction("vkGetDeviceImageMemoryRequirements", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceImageSparseMemoryRequirements"))
			LoadFunction("vkGetDeviceImageSparseMemoryRequirements", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetEvent2"))
			LoadFunction("vkCmdSetEvent2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdResetEvent2"))
			LoadFunction("vkCmdResetEvent2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdWaitEvents2"))
			LoadFunction("vkCmdWaitEvents2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBlitImage2"))
			LoadFunction("vkCmdBlitImage2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdResolveImage2"))
			LoadFunction("vkCmdResolveImage2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBeginRendering"))
			LoadFunction("vkCmdBeginRendering", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdEndRendering"))
			LoadFunction("vkCmdEndRendering", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetCullMode"))
			LoadFunction("vkCmdSetCullMode", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetFrontFace"))
			LoadFunction("vkCmdSetFrontFace", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetPrimitiveTopology"))
			LoadFunction("vkCmdSetPrimitiveTopology", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetViewportWithCount"))
			LoadFunction("vkCmdSetViewportWithCount", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetScissorWithCount"))
			LoadFunction("vkCmdSetScissorWithCount", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindVertexBuffers2"))
			LoadFunction("vkCmdBindVertexBuffers2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDepthTestEnable"))
			LoadFunction("vkCmdSetDepthTestEnable", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDepthWriteEnable"))
			LoadFunction("vkCmdSetDepthWriteEnable", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDepthCompareOp"))
			LoadFunction("vkCmdSetDepthCompareOp", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDepthBoundsTestEnable"))
			LoadFunction("vkCmdSetDepthBoundsTestEnable", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetStencilTestEnable"))
			LoadFunction("vkCmdSetStencilTestEnable", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetStencilOp"))
			LoadFunction("vkCmdSetStencilOp", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetRasterizerDiscardEnable"))
			LoadFunction("vkCmdSetRasterizerDiscardEnable", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDepthBiasEnable"))
			LoadFunction("vkCmdSetDepthBiasEnable", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetPrimitiveRestartEnable"))
			LoadFunction("vkCmdSetPrimitiveRestartEnable", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkMapMemory2"))
			LoadFunction("vkMapMemory2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkUnmapMemory2"))
			LoadFunction("vkUnmapMemory2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceImageSubresourceLayout"))
			LoadFunction("vkGetDeviceImageSubresourceLayout", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetImageSubresourceLayout2"))
			LoadFunction("vkGetImageSubresourceLayout2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCopyMemoryToImage"))
			LoadFunction("vkCopyMemoryToImage", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCopyImageToMemory"))
			LoadFunction("vkCopyImageToMemory", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCopyImageToImage"))
			LoadFunction("vkCopyImageToImage", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkTransitionImageLayout"))
			LoadFunction("vkTransitionImageLayout", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdPushDescriptorSet"))
			LoadFunction("vkCmdPushDescriptorSet", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdPushDescriptorSetWithTemplate"))
			LoadFunction("vkCmdPushDescriptorSetWithTemplate", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindDescriptorSets2"))
			LoadFunction("vkCmdBindDescriptorSets2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdPushConstants2"))
			LoadFunction("vkCmdPushConstants2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdPushDescriptorSet2"))
			LoadFunction("vkCmdPushDescriptorSet2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdPushDescriptorSetWithTemplate2"))
			LoadFunction("vkCmdPushDescriptorSetWithTemplate2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetLineStipple"))
			LoadFunction("vkCmdSetLineStipple", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindIndexBuffer2"))
			LoadFunction("vkCmdBindIndexBuffer2", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetRenderingAreaGranularity"))
			LoadFunction("vkGetRenderingAreaGranularity", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetRenderingAttachmentLocations"))
			LoadFunction("vkCmdSetRenderingAttachmentLocations", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetRenderingInputAttachmentIndices"))
			LoadFunction("vkCmdSetRenderingInputAttachmentIndices", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetCommandPoolMemoryConsumption"))
			LoadFunction("vkGetCommandPoolMemoryConsumption", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetFaultData"))
			LoadFunction("vkGetFaultData", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroySurfaceKHR"))
			LoadFunction("vkDestroySurfaceKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceSurfaceSupportKHR"))
			LoadFunction("vkGetPhysicalDeviceSurfaceSupportKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceSurfaceCapabilitiesKHR"))
			LoadFunction("vkGetPhysicalDeviceSurfaceCapabilitiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceSurfaceFormatsKHR"))
			LoadFunction("vkGetPhysicalDeviceSurfaceFormatsKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceSurfacePresentModesKHR"))
			LoadFunction("vkGetPhysicalDeviceSurfacePresentModesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateSwapchainKHR"))
			LoadFunction("vkCreateSwapchainKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroySwapchainKHR"))
			LoadFunction("vkDestroySwapchainKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetSwapchainImagesKHR"))
			LoadFunction("vkGetSwapchainImagesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkAcquireNextImageKHR"))
			LoadFunction("vkAcquireNextImageKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkQueuePresentKHR"))
			LoadFunction("vkQueuePresentKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceGroupPresentCapabilitiesKHR"))
			LoadFunction("vkGetDeviceGroupPresentCapabilitiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceGroupSurfacePresentModesKHR"))
			LoadFunction("vkGetDeviceGroupSurfacePresentModesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDevicePresentRectanglesKHR"))
			LoadFunction("vkGetPhysicalDevicePresentRectanglesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkAcquireNextImage2KHR"))
			LoadFunction("vkAcquireNextImage2KHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceDisplayPropertiesKHR"))
			LoadFunction("vkGetPhysicalDeviceDisplayPropertiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceDisplayPlanePropertiesKHR"))
			LoadFunction("vkGetPhysicalDeviceDisplayPlanePropertiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDisplayPlaneSupportedDisplaysKHR"))
			LoadFunction("vkGetDisplayPlaneSupportedDisplaysKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDisplayModePropertiesKHR"))
			LoadFunction("vkGetDisplayModePropertiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateDisplayModeKHR"))
			LoadFunction("vkCreateDisplayModeKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDisplayPlaneCapabilitiesKHR"))
			LoadFunction("vkGetDisplayPlaneCapabilitiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateDisplayPlaneSurfaceKHR"))
			LoadFunction("vkCreateDisplayPlaneSurfaceKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateSharedSwapchainsKHR"))
			LoadFunction("vkCreateSharedSwapchainsKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateXlibSurfaceKHR"))
			LoadFunction("vkCreateXlibSurfaceKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceXlibPresentationSupportKHR"))
			LoadFunction("vkGetPhysicalDeviceXlibPresentationSupportKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateXcbSurfaceKHR"))
			LoadFunction("vkCreateXcbSurfaceKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceXcbPresentationSupportKHR"))
			LoadFunction("vkGetPhysicalDeviceXcbPresentationSupportKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateWaylandSurfaceKHR"))
			LoadFunction("vkCreateWaylandSurfaceKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceWaylandPresentationSupportKHR"))
			LoadFunction("vkGetPhysicalDeviceWaylandPresentationSupportKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateAndroidSurfaceKHR"))
			LoadFunction("vkCreateAndroidSurfaceKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateWin32SurfaceKHR"))
			LoadFunction("vkCreateWin32SurfaceKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceWin32PresentationSupportKHR"))
			LoadFunction("vkGetPhysicalDeviceWin32PresentationSupportKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateDebugReportCallbackEXT"))
			LoadFunction("vkCreateDebugReportCallbackEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyDebugReportCallbackEXT"))
			LoadFunction("vkDestroyDebugReportCallbackEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDebugReportMessageEXT"))
			LoadFunction("vkDebugReportMessageEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDebugMarkerSetObjectTagEXT"))
			LoadFunction("vkDebugMarkerSetObjectTagEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDebugMarkerSetObjectNameEXT"))
			LoadFunction("vkDebugMarkerSetObjectNameEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDebugMarkerBeginEXT"))
			LoadFunction("vkCmdDebugMarkerBeginEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDebugMarkerEndEXT"))
			LoadFunction("vkCmdDebugMarkerEndEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDebugMarkerInsertEXT"))
			LoadFunction("vkCmdDebugMarkerInsertEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceVideoCapabilitiesKHR"))
			LoadFunction("vkGetPhysicalDeviceVideoCapabilitiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceVideoFormatPropertiesKHR"))
			LoadFunction("vkGetPhysicalDeviceVideoFormatPropertiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateVideoSessionKHR"))
			LoadFunction("vkCreateVideoSessionKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyVideoSessionKHR"))
			LoadFunction("vkDestroyVideoSessionKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetVideoSessionMemoryRequirementsKHR"))
			LoadFunction("vkGetVideoSessionMemoryRequirementsKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkBindVideoSessionMemoryKHR"))
			LoadFunction("vkBindVideoSessionMemoryKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateVideoSessionParametersKHR"))
			LoadFunction("vkCreateVideoSessionParametersKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkUpdateVideoSessionParametersKHR"))
			LoadFunction("vkUpdateVideoSessionParametersKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyVideoSessionParametersKHR"))
			LoadFunction("vkDestroyVideoSessionParametersKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBeginVideoCodingKHR"))
			LoadFunction("vkCmdBeginVideoCodingKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdEndVideoCodingKHR"))
			LoadFunction("vkCmdEndVideoCodingKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdControlVideoCodingKHR"))
			LoadFunction("vkCmdControlVideoCodingKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDecodeVideoKHR"))
			LoadFunction("vkCmdDecodeVideoKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindTransformFeedbackBuffersEXT"))
			LoadFunction("vkCmdBindTransformFeedbackBuffersEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBeginTransformFeedbackEXT"))
			LoadFunction("vkCmdBeginTransformFeedbackEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdEndTransformFeedbackEXT"))
			LoadFunction("vkCmdEndTransformFeedbackEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBeginQueryIndexedEXT"))
			LoadFunction("vkCmdBeginQueryIndexedEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdEndQueryIndexedEXT"))
			LoadFunction("vkCmdEndQueryIndexedEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawIndirectByteCountEXT"))
			LoadFunction("vkCmdDrawIndirectByteCountEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateCuModuleNVX"))
			LoadFunction("vkCreateCuModuleNVX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateCuFunctionNVX"))
			LoadFunction("vkCreateCuFunctionNVX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyCuModuleNVX"))
			LoadFunction("vkDestroyCuModuleNVX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyCuFunctionNVX"))
			LoadFunction("vkDestroyCuFunctionNVX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCuLaunchKernelNVX"))
			LoadFunction("vkCmdCuLaunchKernelNVX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetImageViewHandleNVX"))
			LoadFunction("vkGetImageViewHandleNVX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetImageViewHandle64NVX"))
			LoadFunction("vkGetImageViewHandle64NVX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetImageViewAddressNVX"))
			LoadFunction("vkGetImageViewAddressNVX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceCombinedImageSamplerIndexNVX"))
			LoadFunction("vkGetDeviceCombinedImageSamplerIndexNVX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetShaderInfoAMD"))
			LoadFunction("vkGetShaderInfoAMD", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateStreamDescriptorSurfaceGGP"))
			LoadFunction("vkCreateStreamDescriptorSurfaceGGP", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceExternalImageFormatPropertiesNV"))
			LoadFunction("vkGetPhysicalDeviceExternalImageFormatPropertiesNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemoryWin32HandleNV"))
			LoadFunction("vkGetMemoryWin32HandleNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateViSurfaceNN"))
			LoadFunction("vkCreateViSurfaceNN", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemoryWin32HandleKHR"))
			LoadFunction("vkGetMemoryWin32HandleKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemoryWin32HandlePropertiesKHR"))
			LoadFunction("vkGetMemoryWin32HandlePropertiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemoryFdKHR"))
			LoadFunction("vkGetMemoryFdKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemoryFdPropertiesKHR"))
			LoadFunction("vkGetMemoryFdPropertiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkImportSemaphoreWin32HandleKHR"))
			LoadFunction("vkImportSemaphoreWin32HandleKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetSemaphoreWin32HandleKHR"))
			LoadFunction("vkGetSemaphoreWin32HandleKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkImportSemaphoreFdKHR"))
			LoadFunction("vkImportSemaphoreFdKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetSemaphoreFdKHR"))
			LoadFunction("vkGetSemaphoreFdKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBeginConditionalRenderingEXT"))
			LoadFunction("vkCmdBeginConditionalRenderingEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdEndConditionalRenderingEXT"))
			LoadFunction("vkCmdEndConditionalRenderingEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetViewportWScalingNV"))
			LoadFunction("vkCmdSetViewportWScalingNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkReleaseDisplayEXT"))
			LoadFunction("vkReleaseDisplayEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkAcquireXlibDisplayEXT"))
			LoadFunction("vkAcquireXlibDisplayEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetRandROutputDisplayEXT"))
			LoadFunction("vkGetRandROutputDisplayEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceSurfaceCapabilities2EXT"))
			LoadFunction("vkGetPhysicalDeviceSurfaceCapabilities2EXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDisplayPowerControlEXT"))
			LoadFunction("vkDisplayPowerControlEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkRegisterDeviceEventEXT"))
			LoadFunction("vkRegisterDeviceEventEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkRegisterDisplayEventEXT"))
			LoadFunction("vkRegisterDisplayEventEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetSwapchainCounterEXT"))
			LoadFunction("vkGetSwapchainCounterEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetRefreshCycleDurationGOOGLE"))
			LoadFunction("vkGetRefreshCycleDurationGOOGLE", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPastPresentationTimingGOOGLE"))
			LoadFunction("vkGetPastPresentationTimingGOOGLE", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDiscardRectangleEXT"))
			LoadFunction("vkCmdSetDiscardRectangleEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDiscardRectangleEnableEXT"))
			LoadFunction("vkCmdSetDiscardRectangleEnableEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDiscardRectangleModeEXT"))
			LoadFunction("vkCmdSetDiscardRectangleModeEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSetHdrMetadataEXT"))
			LoadFunction("vkSetHdrMetadataEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetSwapchainStatusKHR"))
			LoadFunction("vkGetSwapchainStatusKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkImportFenceWin32HandleKHR"))
			LoadFunction("vkImportFenceWin32HandleKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetFenceWin32HandleKHR"))
			LoadFunction("vkGetFenceWin32HandleKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkImportFenceFdKHR"))
			LoadFunction("vkImportFenceFdKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetFenceFdKHR"))
			LoadFunction("vkGetFenceFdKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR"))
			LoadFunction("vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR"))
			LoadFunction("vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkAcquireProfilingLockKHR"))
			LoadFunction("vkAcquireProfilingLockKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkReleaseProfilingLockKHR"))
			LoadFunction("vkReleaseProfilingLockKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceSurfaceCapabilities2KHR"))
			LoadFunction("vkGetPhysicalDeviceSurfaceCapabilities2KHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceSurfaceFormats2KHR"))
			LoadFunction("vkGetPhysicalDeviceSurfaceFormats2KHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceDisplayProperties2KHR"))
			LoadFunction("vkGetPhysicalDeviceDisplayProperties2KHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceDisplayPlaneProperties2KHR"))
			LoadFunction("vkGetPhysicalDeviceDisplayPlaneProperties2KHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDisplayModeProperties2KHR"))
			LoadFunction("vkGetDisplayModeProperties2KHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDisplayPlaneCapabilities2KHR"))
			LoadFunction("vkGetDisplayPlaneCapabilities2KHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateIOSSurfaceMVK"))
			LoadFunction("vkCreateIOSSurfaceMVK", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateMacOSSurfaceMVK"))
			LoadFunction("vkCreateMacOSSurfaceMVK", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSetDebugUtilsObjectNameEXT"))
			LoadFunction("vkSetDebugUtilsObjectNameEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSetDebugUtilsObjectTagEXT"))
			LoadFunction("vkSetDebugUtilsObjectTagEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkQueueBeginDebugUtilsLabelEXT"))
			LoadFunction("vkQueueBeginDebugUtilsLabelEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkQueueEndDebugUtilsLabelEXT"))
			LoadFunction("vkQueueEndDebugUtilsLabelEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkQueueInsertDebugUtilsLabelEXT"))
			LoadFunction("vkQueueInsertDebugUtilsLabelEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBeginDebugUtilsLabelEXT"))
			LoadFunction("vkCmdBeginDebugUtilsLabelEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdEndDebugUtilsLabelEXT"))
			LoadFunction("vkCmdEndDebugUtilsLabelEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdInsertDebugUtilsLabelEXT"))
			LoadFunction("vkCmdInsertDebugUtilsLabelEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateDebugUtilsMessengerEXT"))
			LoadFunction("vkCreateDebugUtilsMessengerEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyDebugUtilsMessengerEXT"))
			LoadFunction("vkDestroyDebugUtilsMessengerEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSubmitDebugUtilsMessageEXT"))
			LoadFunction("vkSubmitDebugUtilsMessageEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetAndroidHardwareBufferPropertiesANDROID"))
			LoadFunction("vkGetAndroidHardwareBufferPropertiesANDROID", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemoryAndroidHardwareBufferANDROID"))
			LoadFunction("vkGetMemoryAndroidHardwareBufferANDROID", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateExecutionGraphPipelinesAMDX"))
			LoadFunction("vkCreateExecutionGraphPipelinesAMDX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetExecutionGraphPipelineScratchSizeAMDX"))
			LoadFunction("vkGetExecutionGraphPipelineScratchSizeAMDX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetExecutionGraphPipelineNodeIndexAMDX"))
			LoadFunction("vkGetExecutionGraphPipelineNodeIndexAMDX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdInitializeGraphScratchMemoryAMDX"))
			LoadFunction("vkCmdInitializeGraphScratchMemoryAMDX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDispatchGraphAMDX"))
			LoadFunction("vkCmdDispatchGraphAMDX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDispatchGraphIndirectAMDX"))
			LoadFunction("vkCmdDispatchGraphIndirectAMDX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDispatchGraphIndirectCountAMDX"))
			LoadFunction("vkCmdDispatchGraphIndirectCountAMDX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkWriteSamplerDescriptorsEXT"))
			LoadFunction("vkWriteSamplerDescriptorsEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkWriteResourceDescriptorsEXT"))
			LoadFunction("vkWriteResourceDescriptorsEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindSamplerHeapEXT"))
			LoadFunction("vkCmdBindSamplerHeapEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindResourceHeapEXT"))
			LoadFunction("vkCmdBindResourceHeapEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdPushDataEXT"))
			LoadFunction("vkCmdPushDataEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetImageOpaqueCaptureDataEXT"))
			LoadFunction("vkGetImageOpaqueCaptureDataEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceDescriptorSizeEXT"))
			LoadFunction("vkGetPhysicalDeviceDescriptorSizeEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkRegisterCustomBorderColorEXT"))
			LoadFunction("vkRegisterCustomBorderColorEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkUnregisterCustomBorderColorEXT"))
			LoadFunction("vkUnregisterCustomBorderColorEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetTensorOpaqueCaptureDataARM"))
			LoadFunction("vkGetTensorOpaqueCaptureDataARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetSampleLocationsEXT"))
			LoadFunction("vkCmdSetSampleLocationsEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceMultisamplePropertiesEXT"))
			LoadFunction("vkGetPhysicalDeviceMultisamplePropertiesEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateAccelerationStructureKHR"))
			LoadFunction("vkCreateAccelerationStructureKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyAccelerationStructureKHR"))
			LoadFunction("vkDestroyAccelerationStructureKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBuildAccelerationStructuresKHR"))
			LoadFunction("vkCmdBuildAccelerationStructuresKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBuildAccelerationStructuresIndirectKHR"))
			LoadFunction("vkCmdBuildAccelerationStructuresIndirectKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkBuildAccelerationStructuresKHR"))
			LoadFunction("vkBuildAccelerationStructuresKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCopyAccelerationStructureKHR"))
			LoadFunction("vkCopyAccelerationStructureKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCopyAccelerationStructureToMemoryKHR"))
			LoadFunction("vkCopyAccelerationStructureToMemoryKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCopyMemoryToAccelerationStructureKHR"))
			LoadFunction("vkCopyMemoryToAccelerationStructureKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkWriteAccelerationStructuresPropertiesKHR"))
			LoadFunction("vkWriteAccelerationStructuresPropertiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyAccelerationStructureKHR"))
			LoadFunction("vkCmdCopyAccelerationStructureKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyAccelerationStructureToMemoryKHR"))
			LoadFunction("vkCmdCopyAccelerationStructureToMemoryKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyMemoryToAccelerationStructureKHR"))
			LoadFunction("vkCmdCopyMemoryToAccelerationStructureKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetAccelerationStructureDeviceAddressKHR"))
			LoadFunction("vkGetAccelerationStructureDeviceAddressKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdWriteAccelerationStructuresPropertiesKHR"))
			LoadFunction("vkCmdWriteAccelerationStructuresPropertiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceAccelerationStructureCompatibilityKHR"))
			LoadFunction("vkGetDeviceAccelerationStructureCompatibilityKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetAccelerationStructureBuildSizesKHR"))
			LoadFunction("vkGetAccelerationStructureBuildSizesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdTraceRaysKHR"))
			LoadFunction("vkCmdTraceRaysKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateRayTracingPipelinesKHR"))
			LoadFunction("vkCreateRayTracingPipelinesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetRayTracingShaderGroupHandlesKHR"))
			LoadFunction("vkGetRayTracingShaderGroupHandlesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetRayTracingCaptureReplayShaderGroupHandlesKHR"))
			LoadFunction("vkGetRayTracingCaptureReplayShaderGroupHandlesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdTraceRaysIndirectKHR"))
			LoadFunction("vkCmdTraceRaysIndirectKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetRayTracingShaderGroupStackSizeKHR"))
			LoadFunction("vkGetRayTracingShaderGroupStackSizeKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetRayTracingPipelineStackSizeKHR"))
			LoadFunction("vkCmdSetRayTracingPipelineStackSizeKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetImageDrmFormatModifierPropertiesEXT"))
			LoadFunction("vkGetImageDrmFormatModifierPropertiesEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateValidationCacheEXT"))
			LoadFunction("vkCreateValidationCacheEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyValidationCacheEXT"))
			LoadFunction("vkDestroyValidationCacheEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkMergeValidationCachesEXT"))
			LoadFunction("vkMergeValidationCachesEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetValidationCacheDataEXT"))
			LoadFunction("vkGetValidationCacheDataEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindShadingRateImageNV"))
			LoadFunction("vkCmdBindShadingRateImageNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetViewportShadingRatePaletteNV"))
			LoadFunction("vkCmdSetViewportShadingRatePaletteNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetCoarseSampleOrderNV"))
			LoadFunction("vkCmdSetCoarseSampleOrderNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateAccelerationStructureNV"))
			LoadFunction("vkCreateAccelerationStructureNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyAccelerationStructureNV"))
			LoadFunction("vkDestroyAccelerationStructureNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetAccelerationStructureMemoryRequirementsNV"))
			LoadFunction("vkGetAccelerationStructureMemoryRequirementsNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkBindAccelerationStructureMemoryNV"))
			LoadFunction("vkBindAccelerationStructureMemoryNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBuildAccelerationStructureNV"))
			LoadFunction("vkCmdBuildAccelerationStructureNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyAccelerationStructureNV"))
			LoadFunction("vkCmdCopyAccelerationStructureNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdTraceRaysNV"))
			LoadFunction("vkCmdTraceRaysNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateRayTracingPipelinesNV"))
			LoadFunction("vkCreateRayTracingPipelinesNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetAccelerationStructureHandleNV"))
			LoadFunction("vkGetAccelerationStructureHandleNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdWriteAccelerationStructuresPropertiesNV"))
			LoadFunction("vkCmdWriteAccelerationStructuresPropertiesNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCompileDeferredNV"))
			LoadFunction("vkCompileDeferredNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemoryHostPointerPropertiesEXT"))
			LoadFunction("vkGetMemoryHostPointerPropertiesEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdWriteBufferMarkerAMD"))
			LoadFunction("vkCmdWriteBufferMarkerAMD", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdWriteBufferMarker2AMD"))
			LoadFunction("vkCmdWriteBufferMarker2AMD", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceCalibrateableTimeDomainsKHR"))
			LoadFunction("vkGetPhysicalDeviceCalibrateableTimeDomainsKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetCalibratedTimestampsKHR"))
			LoadFunction("vkGetCalibratedTimestampsKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawMeshTasksNV"))
			LoadFunction("vkCmdDrawMeshTasksNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawMeshTasksIndirectNV"))
			LoadFunction("vkCmdDrawMeshTasksIndirectNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawMeshTasksIndirectCountNV"))
			LoadFunction("vkCmdDrawMeshTasksIndirectCountNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetExclusiveScissorEnableNV"))
			LoadFunction("vkCmdSetExclusiveScissorEnableNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetExclusiveScissorNV"))
			LoadFunction("vkCmdSetExclusiveScissorNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetCheckpointNV"))
			LoadFunction("vkCmdSetCheckpointNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetQueueCheckpointDataNV"))
			LoadFunction("vkGetQueueCheckpointDataNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetQueueCheckpointData2NV"))
			LoadFunction("vkGetQueueCheckpointData2NV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSetSwapchainPresentTimingQueueSizeEXT"))
			LoadFunction("vkSetSwapchainPresentTimingQueueSizeEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetSwapchainTimingPropertiesEXT"))
			LoadFunction("vkGetSwapchainTimingPropertiesEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetSwapchainTimeDomainPropertiesEXT"))
			LoadFunction("vkGetSwapchainTimeDomainPropertiesEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPastPresentationTimingEXT"))
			LoadFunction("vkGetPastPresentationTimingEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkInitializePerformanceApiINTEL"))
			LoadFunction("vkInitializePerformanceApiINTEL", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkUninitializePerformanceApiINTEL"))
			LoadFunction("vkUninitializePerformanceApiINTEL", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetPerformanceMarkerINTEL"))
			LoadFunction("vkCmdSetPerformanceMarkerINTEL", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetPerformanceStreamMarkerINTEL"))
			LoadFunction("vkCmdSetPerformanceStreamMarkerINTEL", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetPerformanceOverrideINTEL"))
			LoadFunction("vkCmdSetPerformanceOverrideINTEL", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkAcquirePerformanceConfigurationINTEL"))
			LoadFunction("vkAcquirePerformanceConfigurationINTEL", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkReleasePerformanceConfigurationINTEL"))
			LoadFunction("vkReleasePerformanceConfigurationINTEL", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkQueueSetPerformanceConfigurationINTEL"))
			LoadFunction("vkQueueSetPerformanceConfigurationINTEL", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPerformanceParameterINTEL"))
			LoadFunction("vkGetPerformanceParameterINTEL", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSetLocalDimmingAMD"))
			LoadFunction("vkSetLocalDimmingAMD", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateImagePipeSurfaceFUCHSIA"))
			LoadFunction("vkCreateImagePipeSurfaceFUCHSIA", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateMetalSurfaceEXT"))
			LoadFunction("vkCreateMetalSurfaceEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceFragmentShadingRatesKHR"))
			LoadFunction("vkGetPhysicalDeviceFragmentShadingRatesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetFragmentShadingRateKHR"))
			LoadFunction("vkCmdSetFragmentShadingRateKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkWaitForPresentKHR"))
			LoadFunction("vkWaitForPresentKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceCooperativeMatrixPropertiesNV"))
			LoadFunction("vkGetPhysicalDeviceCooperativeMatrixPropertiesNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV"))
			LoadFunction("vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceSurfacePresentModes2EXT"))
			LoadFunction("vkGetPhysicalDeviceSurfacePresentModes2EXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkAcquireFullScreenExclusiveModeEXT"))
			LoadFunction("vkAcquireFullScreenExclusiveModeEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkReleaseFullScreenExclusiveModeEXT"))
			LoadFunction("vkReleaseFullScreenExclusiveModeEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceGroupSurfacePresentModes2EXT"))
			LoadFunction("vkGetDeviceGroupSurfacePresentModes2EXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateHeadlessSurfaceEXT"))
			LoadFunction("vkCreateHeadlessSurfaceEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateDeferredOperationKHR"))
			LoadFunction("vkCreateDeferredOperationKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyDeferredOperationKHR"))
			LoadFunction("vkDestroyDeferredOperationKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeferredOperationMaxConcurrencyKHR"))
			LoadFunction("vkGetDeferredOperationMaxConcurrencyKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeferredOperationResultKHR"))
			LoadFunction("vkGetDeferredOperationResultKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDeferredOperationJoinKHR"))
			LoadFunction("vkDeferredOperationJoinKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPipelineExecutablePropertiesKHR"))
			LoadFunction("vkGetPipelineExecutablePropertiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPipelineExecutableStatisticsKHR"))
			LoadFunction("vkGetPipelineExecutableStatisticsKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPipelineExecutableInternalRepresentationsKHR"))
			LoadFunction("vkGetPipelineExecutableInternalRepresentationsKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkReleaseSwapchainImagesKHR"))
			LoadFunction("vkReleaseSwapchainImagesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetGeneratedCommandsMemoryRequirementsNV"))
			LoadFunction("vkGetGeneratedCommandsMemoryRequirementsNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdPreprocessGeneratedCommandsNV"))
			LoadFunction("vkCmdPreprocessGeneratedCommandsNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdExecuteGeneratedCommandsNV"))
			LoadFunction("vkCmdExecuteGeneratedCommandsNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindPipelineShaderGroupNV"))
			LoadFunction("vkCmdBindPipelineShaderGroupNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateIndirectCommandsLayoutNV"))
			LoadFunction("vkCreateIndirectCommandsLayoutNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyIndirectCommandsLayoutNV"))
			LoadFunction("vkDestroyIndirectCommandsLayoutNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDepthBias2EXT"))
			LoadFunction("vkCmdSetDepthBias2EXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkAcquireDrmDisplayEXT"))
			LoadFunction("vkAcquireDrmDisplayEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDrmDisplayEXT"))
			LoadFunction("vkGetDrmDisplayEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR"))
			LoadFunction("vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetEncodedVideoSessionParametersKHR"))
			LoadFunction("vkGetEncodedVideoSessionParametersKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdEncodeVideoKHR"))
			LoadFunction("vkCmdEncodeVideoKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateCudaModuleNV"))
			LoadFunction("vkCreateCudaModuleNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetCudaModuleCacheNV"))
			LoadFunction("vkGetCudaModuleCacheNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateCudaFunctionNV"))
			LoadFunction("vkCreateCudaFunctionNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyCudaModuleNV"))
			LoadFunction("vkDestroyCudaModuleNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyCudaFunctionNV"))
			LoadFunction("vkDestroyCudaFunctionNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCudaLaunchKernelNV"))
			LoadFunction("vkCmdCudaLaunchKernelNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdRefreshObjectsKHR"))
			LoadFunction("vkCmdRefreshObjectsKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceRefreshableObjectTypesKHR"))
			LoadFunction("vkGetPhysicalDeviceRefreshableObjectTypesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDispatchTileQCOM"))
			LoadFunction("vkCmdDispatchTileQCOM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBeginPerTileExecutionQCOM"))
			LoadFunction("vkCmdBeginPerTileExecutionQCOM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdEndPerTileExecutionQCOM"))
			LoadFunction("vkCmdEndPerTileExecutionQCOM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkExportMetalObjectsEXT"))
			LoadFunction("vkExportMetalObjectsEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDescriptorSetLayoutSizeEXT"))
			LoadFunction("vkGetDescriptorSetLayoutSizeEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDescriptorSetLayoutBindingOffsetEXT"))
			LoadFunction("vkGetDescriptorSetLayoutBindingOffsetEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDescriptorEXT"))
			LoadFunction("vkGetDescriptorEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindDescriptorBuffersEXT"))
			LoadFunction("vkCmdBindDescriptorBuffersEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDescriptorBufferOffsetsEXT"))
			LoadFunction("vkCmdSetDescriptorBufferOffsetsEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindDescriptorBufferEmbeddedSamplersEXT"))
			LoadFunction("vkCmdBindDescriptorBufferEmbeddedSamplersEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetBufferOpaqueCaptureDescriptorDataEXT"))
			LoadFunction("vkGetBufferOpaqueCaptureDescriptorDataEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetImageOpaqueCaptureDescriptorDataEXT"))
			LoadFunction("vkGetImageOpaqueCaptureDescriptorDataEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetImageViewOpaqueCaptureDescriptorDataEXT"))
			LoadFunction("vkGetImageViewOpaqueCaptureDescriptorDataEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetSamplerOpaqueCaptureDescriptorDataEXT"))
			LoadFunction("vkGetSamplerOpaqueCaptureDescriptorDataEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT"))
			LoadFunction("vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetFragmentShadingRateEnumNV"))
			LoadFunction("vkCmdSetFragmentShadingRateEnumNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawMeshTasksEXT"))
			LoadFunction("vkCmdDrawMeshTasksEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawMeshTasksIndirectEXT"))
			LoadFunction("vkCmdDrawMeshTasksIndirectEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawMeshTasksIndirectCountEXT"))
			LoadFunction("vkCmdDrawMeshTasksIndirectCountEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceFaultInfoEXT"))
			LoadFunction("vkGetDeviceFaultInfoEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkAcquireWinrtDisplayNV"))
			LoadFunction("vkAcquireWinrtDisplayNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetWinrtDisplayNV"))
			LoadFunction("vkGetWinrtDisplayNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateDirectFBSurfaceEXT"))
			LoadFunction("vkCreateDirectFBSurfaceEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceDirectFBPresentationSupportEXT"))
			LoadFunction("vkGetPhysicalDeviceDirectFBPresentationSupportEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetVertexInputEXT"))
			LoadFunction("vkCmdSetVertexInputEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemoryZirconHandleFUCHSIA"))
			LoadFunction("vkGetMemoryZirconHandleFUCHSIA", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemoryZirconHandlePropertiesFUCHSIA"))
			LoadFunction("vkGetMemoryZirconHandlePropertiesFUCHSIA", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkImportSemaphoreZirconHandleFUCHSIA"))
			LoadFunction("vkImportSemaphoreZirconHandleFUCHSIA", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetSemaphoreZirconHandleFUCHSIA"))
			LoadFunction("vkGetSemaphoreZirconHandleFUCHSIA", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateBufferCollectionFUCHSIA"))
			LoadFunction("vkCreateBufferCollectionFUCHSIA", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSetBufferCollectionImageConstraintsFUCHSIA"))
			LoadFunction("vkSetBufferCollectionImageConstraintsFUCHSIA", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSetBufferCollectionBufferConstraintsFUCHSIA"))
			LoadFunction("vkSetBufferCollectionBufferConstraintsFUCHSIA", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyBufferCollectionFUCHSIA"))
			LoadFunction("vkDestroyBufferCollectionFUCHSIA", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetBufferCollectionPropertiesFUCHSIA"))
			LoadFunction("vkGetBufferCollectionPropertiesFUCHSIA", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI"))
			LoadFunction("vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSubpassShadingHUAWEI"))
			LoadFunction("vkCmdSubpassShadingHUAWEI", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindInvocationMaskHUAWEI"))
			LoadFunction("vkCmdBindInvocationMaskHUAWEI", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemoryRemoteAddressNV"))
			LoadFunction("vkGetMemoryRemoteAddressNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPipelinePropertiesEXT"))
			LoadFunction("vkGetPipelinePropertiesEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetFenceSciSyncFenceNV"))
			LoadFunction("vkGetFenceSciSyncFenceNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetFenceSciSyncObjNV"))
			LoadFunction("vkGetFenceSciSyncObjNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkImportFenceSciSyncFenceNV"))
			LoadFunction("vkImportFenceSciSyncFenceNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkImportFenceSciSyncObjNV"))
			LoadFunction("vkImportFenceSciSyncObjNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceSciSyncAttributesNV"))
			LoadFunction("vkGetPhysicalDeviceSciSyncAttributesNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetSemaphoreSciSyncObjNV"))
			LoadFunction("vkGetSemaphoreSciSyncObjNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkImportSemaphoreSciSyncObjNV"))
			LoadFunction("vkImportSemaphoreSciSyncObjNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemorySciBufNV"))
			LoadFunction("vkGetMemorySciBufNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV"))
			LoadFunction("vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceSciBufAttributesNV"))
			LoadFunction("vkGetPhysicalDeviceSciBufAttributesNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetPatchControlPointsEXT"))
			LoadFunction("vkCmdSetPatchControlPointsEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetLogicOpEXT"))
			LoadFunction("vkCmdSetLogicOpEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateScreenSurfaceQNX"))
			LoadFunction("vkCreateScreenSurfaceQNX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceScreenPresentationSupportQNX"))
			LoadFunction("vkGetPhysicalDeviceScreenPresentationSupportQNX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetColorWriteEnableEXT"))
			LoadFunction("vkCmdSetColorWriteEnableEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdTraceRaysIndirect2KHR"))
			LoadFunction("vkCmdTraceRaysIndirect2KHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawMultiEXT"))
			LoadFunction("vkCmdDrawMultiEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawMultiIndexedEXT"))
			LoadFunction("vkCmdDrawMultiIndexedEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateMicromapEXT"))
			LoadFunction("vkCreateMicromapEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyMicromapEXT"))
			LoadFunction("vkDestroyMicromapEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBuildMicromapsEXT"))
			LoadFunction("vkCmdBuildMicromapsEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkBuildMicromapsEXT"))
			LoadFunction("vkBuildMicromapsEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCopyMicromapEXT"))
			LoadFunction("vkCopyMicromapEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCopyMicromapToMemoryEXT"))
			LoadFunction("vkCopyMicromapToMemoryEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCopyMemoryToMicromapEXT"))
			LoadFunction("vkCopyMemoryToMicromapEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkWriteMicromapsPropertiesEXT"))
			LoadFunction("vkWriteMicromapsPropertiesEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyMicromapEXT"))
			LoadFunction("vkCmdCopyMicromapEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyMicromapToMemoryEXT"))
			LoadFunction("vkCmdCopyMicromapToMemoryEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyMemoryToMicromapEXT"))
			LoadFunction("vkCmdCopyMemoryToMicromapEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdWriteMicromapsPropertiesEXT"))
			LoadFunction("vkCmdWriteMicromapsPropertiesEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceMicromapCompatibilityEXT"))
			LoadFunction("vkGetDeviceMicromapCompatibilityEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMicromapBuildSizesEXT"))
			LoadFunction("vkGetMicromapBuildSizesEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawClusterHUAWEI"))
			LoadFunction("vkCmdDrawClusterHUAWEI", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDrawClusterIndirectHUAWEI"))
			LoadFunction("vkCmdDrawClusterIndirectHUAWEI", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSetDeviceMemoryPriorityEXT"))
			LoadFunction("vkSetDeviceMemoryPriorityEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDescriptorSetLayoutHostMappingInfoVALVE"))
			LoadFunction("vkGetDescriptorSetLayoutHostMappingInfoVALVE", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDescriptorSetHostMappingVALVE"))
			LoadFunction("vkGetDescriptorSetHostMappingVALVE", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyMemoryIndirectNV"))
			LoadFunction("vkCmdCopyMemoryIndirectNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyMemoryToImageIndirectNV"))
			LoadFunction("vkCmdCopyMemoryToImageIndirectNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDecompressMemoryNV"))
			LoadFunction("vkCmdDecompressMemoryNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDecompressMemoryIndirectCountNV"))
			LoadFunction("vkCmdDecompressMemoryIndirectCountNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPipelineIndirectMemoryRequirementsNV"))
			LoadFunction("vkGetPipelineIndirectMemoryRequirementsNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdUpdatePipelineIndirectBufferNV"))
			LoadFunction("vkCmdUpdatePipelineIndirectBufferNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPipelineIndirectDeviceAddressNV"))
			LoadFunction("vkGetPipelineIndirectDeviceAddressNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetNativeBufferPropertiesOHOS"))
			LoadFunction("vkGetNativeBufferPropertiesOHOS", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemoryNativeBufferOHOS"))
			LoadFunction("vkGetMemoryNativeBufferOHOS", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDepthClampEnableEXT"))
			LoadFunction("vkCmdSetDepthClampEnableEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetPolygonModeEXT"))
			LoadFunction("vkCmdSetPolygonModeEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetRasterizationSamplesEXT"))
			LoadFunction("vkCmdSetRasterizationSamplesEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetSampleMaskEXT"))
			LoadFunction("vkCmdSetSampleMaskEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetAlphaToCoverageEnableEXT"))
			LoadFunction("vkCmdSetAlphaToCoverageEnableEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetAlphaToOneEnableEXT"))
			LoadFunction("vkCmdSetAlphaToOneEnableEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetLogicOpEnableEXT"))
			LoadFunction("vkCmdSetLogicOpEnableEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetColorBlendEnableEXT"))
			LoadFunction("vkCmdSetColorBlendEnableEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetColorBlendEquationEXT"))
			LoadFunction("vkCmdSetColorBlendEquationEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetColorWriteMaskEXT"))
			LoadFunction("vkCmdSetColorWriteMaskEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetTessellationDomainOriginEXT"))
			LoadFunction("vkCmdSetTessellationDomainOriginEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetRasterizationStreamEXT"))
			LoadFunction("vkCmdSetRasterizationStreamEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetConservativeRasterizationModeEXT"))
			LoadFunction("vkCmdSetConservativeRasterizationModeEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetExtraPrimitiveOverestimationSizeEXT"))
			LoadFunction("vkCmdSetExtraPrimitiveOverestimationSizeEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDepthClipEnableEXT"))
			LoadFunction("vkCmdSetDepthClipEnableEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetSampleLocationsEnableEXT"))
			LoadFunction("vkCmdSetSampleLocationsEnableEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetColorBlendAdvancedEXT"))
			LoadFunction("vkCmdSetColorBlendAdvancedEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetProvokingVertexModeEXT"))
			LoadFunction("vkCmdSetProvokingVertexModeEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetLineRasterizationModeEXT"))
			LoadFunction("vkCmdSetLineRasterizationModeEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetLineStippleEnableEXT"))
			LoadFunction("vkCmdSetLineStippleEnableEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDepthClipNegativeOneToOneEXT"))
			LoadFunction("vkCmdSetDepthClipNegativeOneToOneEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetViewportWScalingEnableNV"))
			LoadFunction("vkCmdSetViewportWScalingEnableNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetViewportSwizzleNV"))
			LoadFunction("vkCmdSetViewportSwizzleNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetCoverageToColorEnableNV"))
			LoadFunction("vkCmdSetCoverageToColorEnableNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetCoverageToColorLocationNV"))
			LoadFunction("vkCmdSetCoverageToColorLocationNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetCoverageModulationModeNV"))
			LoadFunction("vkCmdSetCoverageModulationModeNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetCoverageModulationTableEnableNV"))
			LoadFunction("vkCmdSetCoverageModulationTableEnableNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetCoverageModulationTableNV"))
			LoadFunction("vkCmdSetCoverageModulationTableNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetShadingRateImageEnableNV"))
			LoadFunction("vkCmdSetShadingRateImageEnableNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetRepresentativeFragmentTestEnableNV"))
			LoadFunction("vkCmdSetRepresentativeFragmentTestEnableNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetCoverageReductionModeNV"))
			LoadFunction("vkCmdSetCoverageReductionModeNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateTensorARM"))
			LoadFunction("vkCreateTensorARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyTensorARM"))
			LoadFunction("vkDestroyTensorARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateTensorViewARM"))
			LoadFunction("vkCreateTensorViewARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyTensorViewARM"))
			LoadFunction("vkDestroyTensorViewARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetTensorMemoryRequirementsARM"))
			LoadFunction("vkGetTensorMemoryRequirementsARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkBindTensorMemoryARM"))
			LoadFunction("vkBindTensorMemoryARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDeviceTensorMemoryRequirementsARM"))
			LoadFunction("vkGetDeviceTensorMemoryRequirementsARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyTensorARM"))
			LoadFunction("vkCmdCopyTensorARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceExternalTensorPropertiesARM"))
			LoadFunction("vkGetPhysicalDeviceExternalTensorPropertiesARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetTensorOpaqueCaptureDescriptorDataARM"))
			LoadFunction("vkGetTensorOpaqueCaptureDescriptorDataARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetTensorViewOpaqueCaptureDescriptorDataARM"))
			LoadFunction("vkGetTensorViewOpaqueCaptureDescriptorDataARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetShaderModuleIdentifierEXT"))
			LoadFunction("vkGetShaderModuleIdentifierEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetShaderModuleCreateInfoIdentifierEXT"))
			LoadFunction("vkGetShaderModuleCreateInfoIdentifierEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceOpticalFlowImageFormatsNV"))
			LoadFunction("vkGetPhysicalDeviceOpticalFlowImageFormatsNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateOpticalFlowSessionNV"))
			LoadFunction("vkCreateOpticalFlowSessionNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyOpticalFlowSessionNV"))
			LoadFunction("vkDestroyOpticalFlowSessionNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkBindOpticalFlowSessionImageNV"))
			LoadFunction("vkBindOpticalFlowSessionImageNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdOpticalFlowExecuteNV"))
			LoadFunction("vkCmdOpticalFlowExecuteNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkAntiLagUpdateAMD"))
			LoadFunction("vkAntiLagUpdateAMD", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkWaitForPresent2KHR"))
			LoadFunction("vkWaitForPresent2KHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateShadersEXT"))
			LoadFunction("vkCreateShadersEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyShaderEXT"))
			LoadFunction("vkDestroyShaderEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetShaderBinaryDataEXT"))
			LoadFunction("vkGetShaderBinaryDataEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindShadersEXT"))
			LoadFunction("vkCmdBindShadersEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDepthClampRangeEXT"))
			LoadFunction("vkCmdSetDepthClampRangeEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreatePipelineBinariesKHR"))
			LoadFunction("vkCreatePipelineBinariesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyPipelineBinaryKHR"))
			LoadFunction("vkDestroyPipelineBinaryKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPipelineKeyKHR"))
			LoadFunction("vkGetPipelineKeyKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPipelineBinaryDataKHR"))
			LoadFunction("vkGetPipelineBinaryDataKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkReleaseCapturedPipelineDataKHR"))
			LoadFunction("vkReleaseCapturedPipelineDataKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetFramebufferTilePropertiesQCOM"))
			LoadFunction("vkGetFramebufferTilePropertiesQCOM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDynamicRenderingTilePropertiesQCOM"))
			LoadFunction("vkGetDynamicRenderingTilePropertiesQCOM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateSemaphoreSciSyncPoolNV"))
			LoadFunction("vkCreateSemaphoreSciSyncPoolNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroySemaphoreSciSyncPoolNV"))
			LoadFunction("vkDestroySemaphoreSciSyncPoolNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceCooperativeVectorPropertiesNV"))
			LoadFunction("vkGetPhysicalDeviceCooperativeVectorPropertiesNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkConvertCooperativeVectorMatrixNV"))
			LoadFunction("vkConvertCooperativeVectorMatrixNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdConvertCooperativeVectorMatrixNV"))
			LoadFunction("vkCmdConvertCooperativeVectorMatrixNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSetLatencySleepModeNV"))
			LoadFunction("vkSetLatencySleepModeNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkLatencySleepNV"))
			LoadFunction("vkLatencySleepNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkSetLatencyMarkerNV"))
			LoadFunction("vkSetLatencyMarkerNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetLatencyTimingsNV"))
			LoadFunction("vkGetLatencyTimingsNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkQueueNotifyOutOfBandNV"))
			LoadFunction("vkQueueNotifyOutOfBandNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR"))
			LoadFunction("vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateDataGraphPipelinesARM"))
			LoadFunction("vkCreateDataGraphPipelinesARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateDataGraphPipelineSessionARM"))
			LoadFunction("vkCreateDataGraphPipelineSessionARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDataGraphPipelineSessionBindPointRequirementsARM"))
			LoadFunction("vkGetDataGraphPipelineSessionBindPointRequirementsARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDataGraphPipelineSessionMemoryRequirementsARM"))
			LoadFunction("vkGetDataGraphPipelineSessionMemoryRequirementsARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkBindDataGraphPipelineSessionMemoryARM"))
			LoadFunction("vkBindDataGraphPipelineSessionMemoryARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyDataGraphPipelineSessionARM"))
			LoadFunction("vkDestroyDataGraphPipelineSessionARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDispatchDataGraphARM"))
			LoadFunction("vkCmdDispatchDataGraphARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDataGraphPipelineAvailablePropertiesARM"))
			LoadFunction("vkGetDataGraphPipelineAvailablePropertiesARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetDataGraphPipelinePropertiesARM"))
			LoadFunction("vkGetDataGraphPipelinePropertiesARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM"))
			LoadFunction("vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM"))
			LoadFunction("vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetAttachmentFeedbackLoopEnableEXT"))
			LoadFunction("vkCmdSetAttachmentFeedbackLoopEnableEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetScreenBufferPropertiesQNX"))
			LoadFunction("vkGetScreenBufferPropertiesQNX", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetDescriptorBufferOffsets2EXT"))
			LoadFunction("vkCmdSetDescriptorBufferOffsets2EXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindDescriptorBufferEmbeddedSamplers2EXT"))
			LoadFunction("vkCmdBindDescriptorBufferEmbeddedSamplers2EXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBindTileMemoryQCOM"))
			LoadFunction("vkCmdBindTileMemoryQCOM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyMemoryIndirectKHR"))
			LoadFunction("vkCmdCopyMemoryIndirectKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdCopyMemoryToImageIndirectKHR"))
			LoadFunction("vkCmdCopyMemoryToImageIndirectKHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDecompressMemoryEXT"))
			LoadFunction("vkCmdDecompressMemoryEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdDecompressMemoryIndirectCountEXT"))
			LoadFunction("vkCmdDecompressMemoryIndirectCountEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateExternalComputeQueueNV"))
			LoadFunction("vkCreateExternalComputeQueueNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyExternalComputeQueueNV"))
			LoadFunction("vkDestroyExternalComputeQueueNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetExternalComputeQueueDataNV"))
			LoadFunction("vkGetExternalComputeQueueDataNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetClusterAccelerationStructureBuildSizesNV"))
			LoadFunction("vkGetClusterAccelerationStructureBuildSizesNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBuildClusterAccelerationStructureIndirectNV"))
			LoadFunction("vkCmdBuildClusterAccelerationStructureIndirectNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPartitionedAccelerationStructuresBuildSizesNV"))
			LoadFunction("vkGetPartitionedAccelerationStructuresBuildSizesNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBuildPartitionedAccelerationStructuresNV"))
			LoadFunction("vkCmdBuildPartitionedAccelerationStructuresNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetGeneratedCommandsMemoryRequirementsEXT"))
			LoadFunction("vkGetGeneratedCommandsMemoryRequirementsEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdPreprocessGeneratedCommandsEXT"))
			LoadFunction("vkCmdPreprocessGeneratedCommandsEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdExecuteGeneratedCommandsEXT"))
			LoadFunction("vkCmdExecuteGeneratedCommandsEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateIndirectCommandsLayoutEXT"))
			LoadFunction("vkCreateIndirectCommandsLayoutEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyIndirectCommandsLayoutEXT"))
			LoadFunction("vkDestroyIndirectCommandsLayoutEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateIndirectExecutionSetEXT"))
			LoadFunction("vkCreateIndirectExecutionSetEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyIndirectExecutionSetEXT"))
			LoadFunction("vkDestroyIndirectExecutionSetEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkUpdateIndirectExecutionSetPipelineEXT"))
			LoadFunction("vkUpdateIndirectExecutionSetPipelineEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkUpdateIndirectExecutionSetShaderEXT"))
			LoadFunction("vkUpdateIndirectExecutionSetShaderEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateSurfaceOHOS"))
			LoadFunction("vkCreateSurfaceOHOS", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV"))
			LoadFunction("vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemoryMetalHandleEXT"))
			LoadFunction("vkGetMemoryMetalHandleEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetMemoryMetalHandlePropertiesEXT"))
			LoadFunction("vkGetMemoryMetalHandlePropertiesEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM"))
			LoadFunction("vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM"))
			LoadFunction("vkEnumeratePhysicalDeviceShaderInstrumentationMetricsARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateShaderInstrumentationARM"))
			LoadFunction("vkCreateShaderInstrumentationARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkDestroyShaderInstrumentationARM"))
			LoadFunction("vkDestroyShaderInstrumentationARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBeginShaderInstrumentationARM"))
			LoadFunction("vkCmdBeginShaderInstrumentationARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdEndShaderInstrumentationARM"))
			LoadFunction("vkCmdEndShaderInstrumentationARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetShaderInstrumentationValuesARM"))
			LoadFunction("vkGetShaderInstrumentationValuesARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkClearShaderInstrumentationMetricsARM"))
			LoadFunction("vkClearShaderInstrumentationMetricsARM", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdEndRendering2KHR"))
			LoadFunction("vkCmdEndRendering2KHR", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdBeginCustomResolveEXT"))
			LoadFunction("vkCmdBeginCustomResolveEXT", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCmdSetComputeOccupancyPriorityNV"))
			LoadFunction("vkCmdSetComputeOccupancyPriorityNV", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkCreateUbmSurfaceSEC"))
			LoadFunction("vkCreateUbmSurfaceSEC", instance).IgnoreError();

		if(excludeFunctions == null || !excludeFunctions.Contains("vkGetPhysicalDeviceUbmPresentationSupportSEC"))
			LoadFunction("vkGetPhysicalDeviceUbmPresentationSupportSEC", instance).IgnoreError();

	}
}
