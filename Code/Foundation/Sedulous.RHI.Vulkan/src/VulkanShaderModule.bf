using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// One compiled SPIR-V module.
class VulkanShaderModule : IShaderModule
{
	private VkShaderModule mModule;

	public VkShaderModule Handle => mModule;

	public Result<void> Initialize(VkDevice device, ShaderModuleDesc desc)
	{
		if (desc.Code.IsEmpty)
			return .Err;

		VkShaderModuleCreateInfo createInfo = .();
		createInfo.codeSize = (uint)desc.Code.Length;
		// SPIR-V is a stream of 32 bit words, so the byte span is read as words. The
		// pointer must be 4 byte aligned, which a SPIR-V blob loaded from anywhere sane is.
		createInfo.pCode = (uint32*)desc.Code.Ptr;

		if (VulkanNative.vkCreateShaderModule(device, &createInfo, null, &mModule) != .VK_SUCCESS)
			return .Err;
		return .Ok;
	}

	public void Cleanup(VkDevice device)
	{
		if (mModule != .Null)
		{
			VulkanNative.vkDestroyShaderModule(device, mModule, null);
			mModule = .Null;
		}
	}
}
