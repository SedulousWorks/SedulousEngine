namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IRayTracingPipeline.
class VulkanRayTracingPipeline : IRayTracingPipeline
{
	private VkPipeline mPipeline;
	private VulkanPipelineLayout mLayout;

	public IPipelineLayout Layout => mLayout;

	public this() { }

	public Result<void> Init(VulkanDevice device, RayTracingPipelineDesc desc)
	{
		mLayout = desc.Layout as VulkanPipelineLayout;
		if (mLayout == null) return .Err;

		// Build shader stages
		List<VkPipelineShaderStageCreateInfo> stages = scope .();
		List<String> entryPoints = scope .();

		for (let programStage in desc.Stages)
		{
			let vkModule = programStage.Module as VulkanShaderModule;
			if (vkModule == null) return .Err;

			let entryStr = scope:: String(programStage.EntryPoint);
			entryPoints.Add(entryStr);

			VkPipelineShaderStageCreateInfo stage = .();
			stage.module = vkModule.Handle;
			stage.pName = entryStr.CStr();
			stage.stage = ToVkShaderStage(programStage.Stage);
			stages.Add(stage);
		}

		// Build shader groups
		VkRayTracingShaderGroupCreateInfoKHR[] groups = scope VkRayTracingShaderGroupCreateInfoKHR[desc.Groups.Length];
		for (int i = 0; i < desc.Groups.Length; i++)
		{
			let group = desc.Groups[i];
			groups[i] = .();
			groups[i].generalShader = VulkanNative.VK_SHADER_UNUSED_KHR;
			groups[i].closestHitShader = VulkanNative.VK_SHADER_UNUSED_KHR;
			groups[i].anyHitShader = VulkanNative.VK_SHADER_UNUSED_KHR;
			groups[i].intersectionShader = VulkanNative.VK_SHADER_UNUSED_KHR;

			switch (group.Type)
			{
			case .General:
				groups[i].type = .VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_KHR;
				if (group.GeneralShaderIndex != uint32.MaxValue)
					groups[i].generalShader = group.GeneralShaderIndex;
			case .TrianglesHitGroup:
				groups[i].type = .VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_KHR;
				if (group.ClosestHitShaderIndex != uint32.MaxValue)
					groups[i].closestHitShader = group.ClosestHitShaderIndex;
				if (group.AnyHitShaderIndex != uint32.MaxValue)
					groups[i].anyHitShader = group.AnyHitShaderIndex;
			case .ProceduralHitGroup:
				groups[i].type = .VK_RAY_TRACING_SHADER_GROUP_TYPE_PROCEDURAL_HIT_GROUP_KHR;
				if (group.ClosestHitShaderIndex != uint32.MaxValue)
					groups[i].closestHitShader = group.ClosestHitShaderIndex;
				if (group.AnyHitShaderIndex != uint32.MaxValue)
					groups[i].anyHitShader = group.AnyHitShaderIndex;
				if (group.IntersectionShaderIndex != uint32.MaxValue)
					groups[i].intersectionShader = group.IntersectionShaderIndex;
			}
		}

		VkRayTracingPipelineCreateInfoKHR pipelineInfo = .();
		pipelineInfo.stageCount = (uint32)stages.Count;
		pipelineInfo.pStages = stages.Ptr;
		pipelineInfo.groupCount = (uint32)desc.Groups.Length;
		pipelineInfo.pGroups = groups.CArray();
		pipelineInfo.maxPipelineRayRecursionDepth = desc.MaxRecursionDepth;
		pipelineInfo.layout = mLayout.Handle;

		VkPipelineCache cache = .Null;
		if (let vkCache = desc.Cache as VulkanPipelineCache)
			cache = vkCache.Handle;

		let result = VulkanNative.vkCreateRayTracingPipelinesKHR(
			device.Handle, .Null, cache, 1, &pipelineInfo, null, &mPipeline);
		if (result != .VK_SUCCESS)
			return .Err;

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

	private static VkShaderStageFlags ToVkShaderStage(ShaderStage stage)
	{
		if (stage.HasFlag(.RayGen))      return .VK_SHADER_STAGE_RAYGEN_BIT_KHR;
		if (stage.HasFlag(.ClosestHit))  return .VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR;
		if (stage.HasFlag(.Miss))        return .VK_SHADER_STAGE_MISS_BIT_KHR;
		if (stage.HasFlag(.AnyHit))      return .VK_SHADER_STAGE_ANY_HIT_BIT_KHR;
		if (stage.HasFlag(.Intersection))return .VK_SHADER_STAGE_INTERSECTION_BIT_KHR;
		if (stage.HasFlag(.Compute))     return .VK_SHADER_STAGE_COMPUTE_BIT;
		return .VK_SHADER_STAGE_ALL;
	}
}
