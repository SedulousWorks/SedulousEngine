namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of ISampler.
class VulkanSampler : ISampler
{
	private VkSampler mSampler;
	private SamplerDesc mDesc;

	public SamplerDesc Desc => mDesc;

	public this() { }

	public Result<void> Init(VulkanDevice device, SamplerDesc desc)
	{
		mDesc = desc;
		VkSamplerCreateInfo samplerInfo = .();
		samplerInfo.magFilter = VulkanConversions.ToVkFilter(desc.MagFilter);
		samplerInfo.minFilter = VulkanConversions.ToVkFilter(desc.MinFilter);
		samplerInfo.mipmapMode = VulkanConversions.ToVkMipmapMode(desc.MipmapFilter);
		samplerInfo.addressModeU = VulkanConversions.ToVkAddressMode(desc.AddressU);
		samplerInfo.addressModeV = VulkanConversions.ToVkAddressMode(desc.AddressV);
		samplerInfo.addressModeW = VulkanConversions.ToVkAddressMode(desc.AddressW);
		samplerInfo.mipLodBias = desc.MipLodBias;
		samplerInfo.anisotropyEnable = (desc.MaxAnisotropy > 1) ? VkBool32.True : VkBool32.False;
		samplerInfo.maxAnisotropy = (float)desc.MaxAnisotropy;
		samplerInfo.minLod = desc.MinLod;
		samplerInfo.maxLod = desc.MaxLod;
		samplerInfo.borderColor = VulkanConversions.ToVkBorderColor(desc.BorderColor);
		samplerInfo.unnormalizedCoordinates = VkBool32.False;

		if (desc.Compare != null)
		{
			samplerInfo.compareEnable = VkBool32.True;
			samplerInfo.compareOp = VulkanConversions.ToVkCompareOp(desc.Compare.Value);
		}
		else
		{
			samplerInfo.compareEnable = VkBool32.False;
			samplerInfo.compareOp = .VK_COMPARE_OP_ALWAYS;
		}

		let result = VulkanNative.vkCreateSampler(device.Handle, &samplerInfo, null, &mSampler);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanSampler: vkCreateSampler failed ({result})");
			return .Err;
		}

		return .Ok;
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mSampler.Handle != 0)
		{
			VulkanNative.vkDestroySampler(device.Handle, mSampler, null);
			mSampler = .Null;
		}
	}

	// --- Internal ---
	public VkSampler Handle => mSampler;
}
