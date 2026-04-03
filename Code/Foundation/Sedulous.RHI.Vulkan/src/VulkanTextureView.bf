namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of ITextureView.
class VulkanTextureView : ITextureView
{
	private VkImageView mImageView;
	private TextureViewDesc mDesc;
	private VulkanTexture mTexture;
	private TextureFormat mFormat;
	private uint32 mWidth;
	private uint32 mHeight;

	public TextureViewDesc Desc => mDesc;
	public ITexture Texture => mTexture;

	public this() { }

	public Result<void> Init(VulkanDevice device, VulkanTexture texture, TextureViewDesc desc)
	{
		mDesc = desc;
		mTexture = texture;
		// Store dimensions for render area calculation
		mWidth = texture.Desc.Width;
		mHeight = texture.Desc.Height;
		let format = (desc.Format == .Undefined) ? texture.Desc.Format : desc.Format;
		mFormat = format;

		VkImageViewCreateInfo viewInfo = .();
		viewInfo.image = texture.Handle;
		viewInfo.viewType = VulkanConversions.ToVkImageViewType(desc.Dimension);
		viewInfo.format = VulkanConversions.ToVkFormat(format);
		viewInfo.components = VkComponentMapping()
		{
			r = .VK_COMPONENT_SWIZZLE_IDENTITY,
			g = .VK_COMPONENT_SWIZZLE_IDENTITY,
			b = .VK_COMPONENT_SWIZZLE_IDENTITY,
			a = .VK_COMPONENT_SWIZZLE_IDENTITY
		};

		uint32 mipCount = desc.MipLevelCount;
		if (mipCount == 0) mipCount = texture.Desc.MipLevelCount - desc.BaseMipLevel;

		uint32 layerCount = desc.ArrayLayerCount;
		if (layerCount == 0) layerCount = texture.Desc.ArrayLayerCount - desc.BaseArrayLayer;

		VkImageAspectFlags aspectMask;
		switch (desc.Aspect)
		{
		case .DepthOnly:   aspectMask = .VK_IMAGE_ASPECT_DEPTH_BIT;
		case .StencilOnly: aspectMask = .VK_IMAGE_ASPECT_STENCIL_BIT;
		default:           aspectMask = VulkanConversions.GetAspectMask(format);
		}

		viewInfo.subresourceRange = VkImageSubresourceRange()
		{
			aspectMask = aspectMask,
			baseMipLevel = desc.BaseMipLevel,
			levelCount = mipCount,
			baseArrayLayer = desc.BaseArrayLayer,
			layerCount = layerCount
		};

		let result = VulkanNative.vkCreateImageView(device.Handle, &viewInfo, null, &mImageView);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanTextureView: vkCreateImageView failed ({result})");
			return .Err;
		}

		return .Ok;
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mImageView.Handle != 0)
		{
			VulkanNative.vkDestroyImageView(device.Handle, mImageView, null);
			mImageView = .Null;
		}
	}

	// --- Internal ---
	public VkImageView Handle => mImageView;
	public TextureFormat Format => mFormat;
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
}
