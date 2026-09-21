using System;
using System.Collections;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A compiled ray tracing pipeline: its shaders, and the groups that address them.
class VulkanRayTracingPipeline : IRayTracingPipeline
{
	private VkPipeline mPipeline;
	private VulkanPipelineLayout mLayout;

	public IPipelineLayout Layout => mLayout;
	public VkPipeline Handle => mPipeline;

	public Result<void> Initialize(VkDevice device, RayTracingPipelineDesc desc)
	{
		mLayout = desc.Layout as VulkanPipelineLayout;
		if (mLayout == null)
			return .Err;

		let stageCount = desc.Stages.Length;
		let groupCount = desc.Groups.Length;
		if ((stageCount == 0) || (groupCount == 0))
			return .Err;

		let stages = scope VkPipelineShaderStageCreateInfo[stageCount];
		// The names must outlive the create call, which only holds pointers.
		let entryPoints = scope List<String>();
		defer { for (let entry in entryPoints) delete entry; }

		for (int i < stageCount)
		{
			let module = desc.Stages[i].Module as VulkanShaderModule;
			if (module == null)
				return .Err;

			let entry = new String(desc.Stages[i].EntryPoint);
			entryPoints.Add(entry);

			stages[i] = .();
			stages[i].module = module.Handle;
			stages[i].pName = entry.CStr();
			stages[i].stage = ToRayTracingStage(desc.Stages[i].Stage);
		}

		let groups = scope VkRayTracingShaderGroupCreateInfoKHR[groupCount];
		for (int i < groupCount)
		{
			let group = desc.Groups[i];
			groups[i] = .();
			switch (group.Type)
			{
			case .General:
				groups[i].type = .VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_KHR;
			case .TrianglesHitGroup:
				groups[i].type = .VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_KHR;
			case .ProceduralHitGroup:
				groups[i].type = .VK_RAY_TRACING_SHADER_GROUP_TYPE_PROCEDURAL_HIT_GROUP_KHR;
			}

			// An unused slot carries all ones, which is exactly VK_SHADER_UNUSED_KHR, so
			// the RHI's UnusedShader passes straight through.
			groups[i].generalShader = group.GeneralShaderIndex;
			groups[i].closestHitShader = group.ClosestHitShaderIndex;
			groups[i].anyHitShader = group.AnyHitShaderIndex;
			groups[i].intersectionShader = group.IntersectionShaderIndex;
		}

		VkRayTracingPipelineCreateInfoKHR createInfo = .();
		createInfo.stageCount = (uint32)stageCount;
		createInfo.pStages = &stages[0];
		createInfo.groupCount = (uint32)groupCount;
		createInfo.pGroups = &groups[0];
		// Declared up front because the driver sizes the traversal stack from it, and
		// exceeding it at runtime is undefined rather than diagnosed.
		createInfo.maxPipelineRayRecursionDepth = desc.MaxRecursionDepth;
		createInfo.layout = mLayout.Handle;

		VkPipelineCache cache = .Null;
		if (let pipelineCache = desc.Cache as VulkanPipelineCache)
			cache = pipelineCache.Handle;

		if (VulkanNative.vkCreateRayTracingPipelinesKHR(device, .Null, cache, 1, &createInfo,
			null, &mPipeline) != .VK_SUCCESS)
			return .Err;
		return .Ok;
	}

	/// Anything that is not a ray tracing stage falls back to ray generation: a pipeline
	/// built from a mislabelled stage fails at creation with a driver message rather than
	/// silently doing something else.
	private static VkShaderStageFlags ToRayTracingStage(ShaderStage stage)
	{
		switch (stage)
		{
		case .RayGen: return .VK_SHADER_STAGE_RAYGEN_BIT_KHR;
		case .Miss: return .VK_SHADER_STAGE_MISS_BIT_KHR;
		case .ClosestHit: return .VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR;
		case .AnyHit: return .VK_SHADER_STAGE_ANY_HIT_BIT_KHR;
		case .Intersection: return .VK_SHADER_STAGE_INTERSECTION_BIT_KHR;
		case .Callable: return .VK_SHADER_STAGE_CALLABLE_BIT_KHR;
		default: return .VK_SHADER_STAGE_RAYGEN_BIT_KHR;
		}
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
