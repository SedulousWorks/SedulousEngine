namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IComputePipeline.
class VulkanComputePipeline : IComputePipeline
{
	private VkPipeline mPipeline;
	private VulkanPipelineLayout mLayout;

	public IPipelineLayout Layout => mLayout;

	public this() { }

	public Result<void> Init(VulkanDevice device, ComputePipelineDesc desc)
	{
		mLayout = desc.Layout as VulkanPipelineLayout;
		if (mLayout == null)
		{
			System.Diagnostics.Debug.WriteLine("VulkanComputePipeline: layout is not a VulkanPipelineLayout");
			return .Err;
		}

		let vkModule = desc.Compute.Module as VulkanShaderModule;
		if (vkModule == null)
		{
			System.Diagnostics.Debug.WriteLine("VulkanComputePipeline: compute shader module is not a VulkanShaderModule");
			return .Err;
		}

		let entryStr = scope String(desc.Compute.EntryPoint);

		VkPipelineShaderStageCreateInfo stage = .();
		stage.stage = .VK_SHADER_STAGE_COMPUTE_BIT;
		stage.module = vkModule.Handle;
		stage.pName = entryStr.CStr();

		VkComputePipelineCreateInfo pipelineInfo = .();
		pipelineInfo.stage = stage;
		pipelineInfo.layout = mLayout.Handle;

		VkPipelineCache cache = .Null;
		if (let vkCache = desc.Cache as VulkanPipelineCache)
			cache = vkCache.Handle;

		let result = VulkanNative.vkCreateComputePipelines(device.Handle, cache, 1, &pipelineInfo, null, &mPipeline);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanComputePipeline: vkCreateComputePipelines failed ({result})");
			return .Err;
		}

		return .Ok;
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mPipeline.Handle != 0)
		{
			VulkanNative.vkDestroyPipeline(device.Handle, mPipeline, null);
			mPipeline = .Null;
		}
	}

	public VkPipeline Handle => mPipeline;
}
