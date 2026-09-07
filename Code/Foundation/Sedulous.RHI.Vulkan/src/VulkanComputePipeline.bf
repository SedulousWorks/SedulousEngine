using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A compiled compute pipeline.
class VulkanComputePipeline : IComputePipeline
{
	private VkPipeline mPipeline;
	private VulkanPipelineLayout mLayout;

	public IPipelineLayout Layout => mLayout;
	public VkPipeline Handle => mPipeline;

	public Result<void> Initialize(VkDevice device, ComputePipelineDesc desc)
	{
		mLayout = desc.Layout as VulkanPipelineLayout;
		if (mLayout == null)
			return .Err;

		let module = desc.Compute.Module as VulkanShaderModule;
		if (module == null)
			return .Err;

		// Outlives the create call, which only holds a pointer to it.
		let entryPoint = scope String(desc.Compute.EntryPoint);

		VkPipelineShaderStageCreateInfo stage = .();
		stage.stage = .VK_SHADER_STAGE_COMPUTE_BIT;
		stage.module = module.Handle;
		stage.pName = entryPoint.CStr();

		VkComputePipelineCreateInfo createInfo = .();
		createInfo.stage = stage;
		createInfo.layout = mLayout.Handle;

		VkPipelineCache cache = .Null;
		if (let pipelineCache = desc.Cache as VulkanPipelineCache)
			cache = pipelineCache.Handle;

		if (VulkanNative.vkCreateComputePipelines(device, cache, 1, &createInfo, null, &mPipeline)
			!= .VK_SUCCESS)
			return .Err;
		return .Ok;
	}

	public void Cleanup(VkDevice device)
	{
		if (mPipeline != .Null)
		{
			VulkanNative.vkDestroyPipeline(device, mPipeline, null);
			mPipeline = .Null;
		}
	}
}
