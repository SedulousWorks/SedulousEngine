namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IQuerySet.
class VulkanQuerySet : IQuerySet
{
	private VkQueryPool mPool;
	private QueryType mType;
	private uint32 mCount;

	public QueryType Type => mType;
	public uint32 Count => mCount;

	public this() { }

	public Result<void> Init(VulkanDevice device, QuerySetDesc desc)
	{
		mType = desc.Type;
		mCount = desc.Count;

		VkQueryPoolCreateInfo poolInfo = .();
		poolInfo.queryCount = desc.Count;

		switch (desc.Type)
		{
		case .Timestamp:
			poolInfo.queryType = .VK_QUERY_TYPE_TIMESTAMP;
		case .Occlusion:
			poolInfo.queryType = .VK_QUERY_TYPE_OCCLUSION;
		case .PipelineStatistics:
			poolInfo.queryType = .VK_QUERY_TYPE_PIPELINE_STATISTICS;
			poolInfo.pipelineStatistics =
				.VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_VERTICES_BIT |
				.VK_QUERY_PIPELINE_STATISTIC_INPUT_ASSEMBLY_PRIMITIVES_BIT |
				.VK_QUERY_PIPELINE_STATISTIC_VERTEX_SHADER_INVOCATIONS_BIT |
				.VK_QUERY_PIPELINE_STATISTIC_FRAGMENT_SHADER_INVOCATIONS_BIT |
				.VK_QUERY_PIPELINE_STATISTIC_COMPUTE_SHADER_INVOCATIONS_BIT;
		}

		let result = VulkanNative.vkCreateQueryPool(device.Handle, &poolInfo, null, &mPool);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanQuerySet: vkCreateQueryPool failed ({result})");
			return .Err;
		}

		return .Ok;
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mPool.Handle != 0)
		{
			VulkanNative.vkDestroyQueryPool(device.Handle, mPool, null);
			mPool = .Null;
		}
	}

	public VkQueryPool Handle => mPool;
}
