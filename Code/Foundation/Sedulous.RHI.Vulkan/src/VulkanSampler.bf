using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A Vulkan sampler.
class VulkanSampler : ISampler
{
	private SamplerDesc mDesc;
	private VkSampler mSampler;

	public SamplerDesc Desc => mDesc;
	public VkSampler Handle => mSampler;

	public Result<void> Initialize(VkDevice device, SamplerDesc desc)
	{
		mDesc = desc;

		VkSamplerCreateInfo createInfo = .();
		createInfo.magFilter = VulkanConversions.ToVkFilter(desc.MagFilter);
		createInfo.minFilter = VulkanConversions.ToVkFilter(desc.MinFilter);
		createInfo.mipmapMode = VulkanConversions.ToVkMipmapMode(desc.MipmapFilter);
		createInfo.addressModeU = VulkanConversions.ToVkAddressMode(desc.AddressU);
		createInfo.addressModeV = VulkanConversions.ToVkAddressMode(desc.AddressV);
		createInfo.addressModeW = VulkanConversions.ToVkAddressMode(desc.AddressW);
		createInfo.mipLodBias = desc.MipLodBias;
		// Anisotropy is enabled by ASKING for more than one sample, so a caller need not
		// set a flag and a number that could disagree.
		createInfo.anisotropyEnable = desc.MaxAnisotropy > 1;
		createInfo.maxAnisotropy = (float)desc.MaxAnisotropy;
		createInfo.minLod = desc.MinLod;
		createInfo.maxLod = desc.MaxLod;
		createInfo.borderColor = VulkanConversions.ToVkBorderColor(desc.BorderColor);
		createInfo.unnormalizedCoordinates = false;

		// A comparison sampler, which is what shadow map filtering uses: the hardware
		// compares against a reference and filters the RESULT rather than the depth.
		if (desc.Compare.HasValue)
		{
			createInfo.compareEnable = true;
			createInfo.compareOp = VulkanConversions.ToVkCompareOp(desc.Compare.Value);
		}

		if (VulkanNative.vkCreateSampler(device, &createInfo, null, &mSampler) != .VK_SUCCESS)
			return .Err;
		return .Ok;
	}

	public void Cleanup(VkDevice device)
	{
		if (mSampler != .Null)
		{
			VulkanNative.vkDestroySampler(device, mSampler, null);
			mSampler = .Null;
		}
	}
}
