using System;
using System.Threading;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A Vulkan image and the memory behind it.
///
/// One allocation per texture, with no sub allocation, so the live count is tracked: it
/// trends toward the driver's maxMemoryAllocationCount, and knowing how many were
/// outstanding when an allocation failed is most of the diagnosis.
class VulkanTexture : ITexture
{
	private static int32 sLiveAllocations = 0;
	private static int32 sFailureCount = 0;

	/// How many texture allocations are outstanding across the process.
	public static int32 LiveAllocations => sLiveAllocations;

	private TextureDesc mDesc;
	private VkImage mImage;
	private VkDeviceMemory mMemory;
	/// False for a swap chain image, which the chain owns and this only describes.
	private bool mOwnsImage = true;

	public TextureDesc Desc => mDesc;
	public ResourceState InitialState { get; set; } = .Undefined;
	public VkImage Handle => mImage;

	public Result<void> Initialize(VkDevice device, VulkanAdapter adapter, TextureDesc desc)
	{
		mDesc = desc;
		mOwnsImage = true;

		VkImageCreateInfo createInfo = .();
		createInfo.imageType = VulkanConversions.ToVkImageType(desc.Dimension);
		createInfo.format = VulkanConversions.ToVkFormat(desc.Format);
		createInfo.extent = .() { width = desc.Width, height = desc.Height, depth = desc.Depth };
		createInfo.mipLevels = desc.MipLevelCount;
		createInfo.arrayLayers = desc.ArrayLayerCount;
		createInfo.samples = VulkanConversions.ToVkSampleCount(desc.SampleCount);
		createInfo.tiling = .VK_IMAGE_TILING_OPTIMAL;
		createInfo.usage = VulkanConversions.ToVkImageUsage(desc.Usage);
		createInfo.sharingMode = .VK_SHARING_MODE_EXCLUSIVE;
		createInfo.initialLayout = .VK_IMAGE_LAYOUT_UNDEFINED;

		// Six or more layers on a 2D texture is what a cube map is made from, and the flag
		// has to be set at CREATION for a cube view to be possible later.
		if ((desc.ArrayLayerCount >= 6) && (desc.Dimension == .Texture2D))
			createInfo.flags |= .VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT;

		if (VulkanNative.vkCreateImage(device, &createInfo, null, &mImage) != .VK_SUCCESS)
			return .Err;

		VkMemoryRequirements requirements = default;
		VulkanNative.vkGetImageMemoryRequirements(device, mImage, &requirements);

		// Device local always: an image is never mapped, and tiling is opaque anyway.
		let memoryType = adapter.FindMemoryType(requirements.memoryTypeBits,
			.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
		if (memoryType < 0)
		{
			VulkanNative.vkDestroyImage(device, mImage, null);
			mImage = .Null;
			return .Err;
		}

		VkMemoryAllocateInfo allocateInfo = .();
		allocateInfo.allocationSize = requirements.size;
		allocateInfo.memoryTypeIndex = (uint32)memoryType;

		let allocateResult = VulkanNative.vkAllocateMemory(device, &allocateInfo, null, &mMemory);
		if (allocateResult != .VK_SUCCESS)
		{
			// Throttled so a failure storm cannot flood the log, but the FIRST one always
			// reports. The result separates running out of memory from hitting the
			// allocation count ceiling, and the live count says which is likely.
			let failures = Interlocked.Increment(ref sFailureCount);
			if (((failures - 1) % 90) == 0)
			{
				Console.Error.WriteLine(scope $"VulkanTexture: vkAllocateMemory failed ({allocateResult}) size={requirements.size} liveAllocations={sLiveAllocations} failure #{failures}");
			}
			VulkanNative.vkDestroyImage(device, mImage, null);
			mImage = .Null;
			return .Err;
		}

		Interlocked.Increment(ref sLiveAllocations);
		VulkanNative.vkBindImageMemory(device, mImage, mMemory, 0);
		return .Ok;
	}

	/// Describes an image this does NOT own, which is what a swap chain back buffer is.
	public void InitializeFromExisting(VkImage image, TextureDesc desc)
	{
		mImage = image;
		mDesc = desc;
		mOwnsImage = false;
	}

	public void Cleanup(VkDevice device)
	{
		if (mMemory != .Null)
		{
			VulkanNative.vkFreeMemory(device, mMemory, null);
			mMemory = .Null;
			Interlocked.Decrement(ref sLiveAllocations);
		}
		if (mOwnsImage && (mImage != .Null))
			VulkanNative.vkDestroyImage(device, mImage, null);
		mImage = .Null;
	}
}
