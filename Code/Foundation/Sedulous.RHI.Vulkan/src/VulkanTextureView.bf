using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A view onto part of an image.
class VulkanTextureView : ITextureView
{
	private TextureViewDesc mDesc;
	private ITexture mTexture;
	private VkImageView mImageView;
	private readonly uint64 mUniqueId = TextureViewIds.Next();

	private uint32 mWidth;
	private uint32 mHeight;
	private TextureFormat mFormat;

	public TextureViewDesc Desc => mDesc;
	public ITexture Texture => mTexture;
	public uint64 UniqueId => mUniqueId;
	public VkImageView Handle => mImageView;

	/// The view's BASE MIP extent, which is not the texture's own size.
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public TextureFormat Format => mFormat;

	public Result<void> Initialize(VkDevice device, VulkanTexture texture, TextureViewDesc desc)
	{
		mDesc = desc;
		mTexture = texture;

		// The extent of the mip this view STARTS at, halved per level, not the texture's
		// mip zero size. A render pass takes its render area from these, so a stale mip
		// zero size here overruns an attachment on any mip past the first and faults the
		// GPU. Shadow maps only ever target mip zero; a prefilter chain is the first thing
		// to render into a smaller one.
		mWidth = Math.Max((uint32)1, texture.Desc.Width >> desc.BaseMipLevel);
		mHeight = Math.Max((uint32)1, texture.Desc.Height >> desc.BaseMipLevel);

		// Undefined means the texture's own format. Naming a different one reinterprets,
		// which is how an sRGB target is written as linear.
		mFormat = (desc.Format == .Undefined) ? texture.Desc.Format : desc.Format;

		VkImageViewCreateInfo createInfo = .();
		createInfo.image = texture.Handle;
		createInfo.viewType = VulkanConversions.ToVkImageViewType(desc.Dimension);
		createInfo.format = VulkanConversions.ToVkFormat(mFormat);
		createInfo.components = .()
			{
				r = .VK_COMPONENT_SWIZZLE_IDENTITY,
				g = .VK_COMPONENT_SWIZZLE_IDENTITY,
				b = .VK_COMPONENT_SWIZZLE_IDENTITY,
				a = .VK_COMPONENT_SWIZZLE_IDENTITY
			};

		// Zero means "the rest", which is what a view of a whole texture asks for without
		// having to know how many levels or layers it has.
		let mipCount = (uint32)((desc.MipLevelCount > 0) ? desc.MipLevelCount
			: (texture.Desc.MipLevelCount - desc.BaseMipLevel));
		let layerCount = (uint32)((desc.ArrayLayerCount > 0) ? desc.ArrayLayerCount
			: (texture.Desc.ArrayLayerCount - desc.BaseArrayLayer));

		VkImageAspectFlags aspect;
		switch (desc.Aspect)
		{
		case .DepthOnly: aspect = .VK_IMAGE_ASPECT_DEPTH_BIT;
		case .StencilOnly: aspect = .VK_IMAGE_ASPECT_STENCIL_BIT;
		default: aspect = VulkanConversions.GetAspectMask(mFormat);
		}

		createInfo.subresourceRange = .()
			{
				aspectMask = aspect,
				baseMipLevel = desc.BaseMipLevel,
				levelCount = mipCount,
				baseArrayLayer = desc.BaseArrayLayer,
				layerCount = layerCount
			};

		if (VulkanNative.vkCreateImageView(device, &createInfo, null, &mImageView) != .VK_SUCCESS)
			return .Err;
		return .Ok;
	}

	public void Cleanup(VkDevice device)
	{
		if (mImageView != .Null)
		{
			VulkanNative.vkDestroyImageView(device, mImageView, null);
			mImageView = .Null;
		}
	}
}
