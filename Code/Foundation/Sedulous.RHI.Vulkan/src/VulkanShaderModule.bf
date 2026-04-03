namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IShaderModule.
class VulkanShaderModule : IShaderModule
{
	private VkShaderModule mModule;

	public this() { }

	public Result<void> Init(VulkanDevice device, ShaderModuleDesc desc)
	{
		VkShaderModuleCreateInfo createInfo = .();
		createInfo.codeSize = (uint)desc.Code.Length;
		createInfo.pCode = (uint32*)desc.Code.Ptr;

		let result = VulkanNative.vkCreateShaderModule(device.Handle, &createInfo, null, &mModule);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanShaderModule: vkCreateShaderModule failed ({result})");
			return .Err;
		}

		return .Ok;
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mModule.Handle != 0)
		{
			VulkanNative.vkDestroyShaderModule(device.Handle, mModule, null);
			mModule = .Null;
		}
	}

	public VkShaderModule Handle => mModule;
}
