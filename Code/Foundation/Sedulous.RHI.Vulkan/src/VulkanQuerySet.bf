using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A Vulkan query pool.
class VulkanQuerySet : IQuerySet
{
	private VkQueryPool mPool;
	private QueryType mType = .Timestamp;
	private uint32 mCount = 0;

	public QueryType Type => mType;
	public uint32 Count => mCount;
	public VkQueryPool Handle => mPool;

	public Result<void> Initialize(VkDevice device, QuerySetDesc desc)
	{
		mType = desc.Type;
		mCount = desc.Count;

		VkQueryPoolCreateInfo createInfo = .();
		createInfo.queryCount = desc.Count;

		switch (desc.Type)
		{
		case .Timestamp:
			createInfo.queryType = .VK_QUERY_TYPE_TIMESTAMP;
		case .Occlusion:
			createInfo.queryType = .VK_QUERY_TYPE_OCCLUSION;
		case .PipelineStatistics:
			createInfo.queryType = .VK_QUERY_TYPE_PIPELINE_STATISTICS;
			// The statistics a renderer actually looks at. They must be named at creation,
			// because the set of counters decides how wide a result is.
			createInfo.pipelineStatistics =
				.VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_VERTICES_BIT
				| .VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_PRIMITIVES_BIT
				| .VK_QUERY_PIPELINE_STATISTIC_VERTEX_SHADER_INVOCATIONS_BIT
				| .VK_QUERY_PIPELINE_STATISTIC_FRAGMENT_SHADER_INVOCATIONS_BIT
				| .VK_QUERY_PIPELINE_STATISTIC_COMPUTE_SHADER_INVOCATIONS_BIT;
		}

		if (VulkanNative.vkCreateQueryPool(device, &createInfo, null, &mPool) != .VK_SUCCESS)
			return .Err;
		return .Ok;
	}

	public void Cleanup(VkDevice device)
	{
		if (mPool != .Null)
		{
			VulkanNative.vkDestroyQueryPool(device, mPool, null);
			mPool = .Null;
		}
	}
}
