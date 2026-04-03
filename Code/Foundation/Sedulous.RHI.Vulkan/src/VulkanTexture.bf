namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of ITexture.
class VulkanTexture : ITexture
{
	private VkImage mImage;
	private VkDeviceMemory mMemory;
	private TextureDesc mDesc;
	private bool mOwnsImage = true;
	private VkImageLayout mCurrentLayout = .VK_IMAGE_LAYOUT_UNDEFINED;

	public TextureDesc Desc => mDesc;
	public ResourceState InitialState => .Undefined;

	public this() { }

	/// Initialize from a TextureDesc (creates VkImage + allocates memory).
	public Result<void> Init(VulkanDevice device, VulkanAdapter adapter, TextureDesc desc)
	{
		mDesc = desc;

		VkImageCreateInfo imageInfo = .();
		imageInfo.imageType = VulkanConversions.ToVkImageType(desc.Dimension);
		imageInfo.format = VulkanConversions.ToVkFormat(desc.Format);
		imageInfo.extent.width = desc.Width;
		imageInfo.extent.height = desc.Height;
		imageInfo.extent.depth = desc.Depth;
		imageInfo.mipLevels = desc.MipLevelCount;
		imageInfo.arrayLayers = desc.ArrayLayerCount;
		imageInfo.samples = VulkanConversions.ToVkSampleCount(desc.SampleCount);
		imageInfo.tiling = .VK_IMAGE_TILING_OPTIMAL;
		imageInfo.usage = VulkanConversions.ToVkImageUsage(desc.Usage);
		imageInfo.sharingMode = .VK_SHARING_MODE_EXCLUSIVE;
		imageInfo.initialLayout = .VK_IMAGE_LAYOUT_UNDEFINED;

		// Cube maps
		if (desc.ArrayLayerCount >= 6 && desc.Dimension == .Texture2D)
			imageInfo.flags |= .VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT;

		let result = VulkanNative.vkCreateImage(device.Handle, &imageInfo, null, &mImage);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanTexture: vkCreateImage failed ({result})");
			return .Err;
		}

		// Allocate memory
		VkMemoryRequirements memReqs = default;
		VulkanNative.vkGetImageMemoryRequirements(device.Handle, mImage, &memReqs);

		int32 memTypeIndex = adapter.FindMemoryType((uint32)memReqs.memoryTypeBits,
			.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
		if (memTypeIndex < 0)
		{
			System.Diagnostics.Debug.WriteLine("VulkanTexture: no suitable memory type found");
			VulkanNative.vkDestroyImage(device.Handle, mImage, null);
			mImage = .Null;
			return .Err;
		}

		VkMemoryAllocateInfo allocInfo = .();
		allocInfo.allocationSize = memReqs.size;
		allocInfo.memoryTypeIndex = (uint32)memTypeIndex;

		let allocResult = VulkanNative.vkAllocateMemory(device.Handle, &allocInfo, null, &mMemory);
		if (allocResult != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanTexture: vkAllocateMemory failed ({allocResult})");
			VulkanNative.vkDestroyImage(device.Handle, mImage, null);
			mImage = .Null;
			return .Err;
		}

		VulkanNative.vkBindImageMemory(device.Handle, mImage, mMemory, 0);
		return .Ok;
	}

	/// Initialize from an existing VkImage (e.g. swap chain image). Does not own the image.
	public void InitFromExisting(VkImage image, TextureDesc desc)
	{
		mImage = image;
		mDesc = desc;
		mOwnsImage = false;
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mMemory.Handle != 0)
		{
			VulkanNative.vkFreeMemory(device.Handle, mMemory, null);
			mMemory = .Null;
		}
		if (mOwnsImage && mImage.Handle != 0)
		{
			VulkanNative.vkDestroyImage(device.Handle, mImage, null);
		}
		mImage = .Null;
	}

	// --- Internal ---
	public VkImage Handle => mImage;
	public VkFormat VkFormat => VulkanConversions.ToVkFormat(mDesc.Format);
	public VkImageLayout CurrentLayout
	{
		get => mCurrentLayout;
		set => mCurrentLayout = value;
	}
}
