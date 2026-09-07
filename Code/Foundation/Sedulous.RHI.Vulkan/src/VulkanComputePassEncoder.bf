using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// Records dispatches. A compute pass is not a Vulkan object: it is a span of the command
/// buffer, so beginning and ending it only tracks what is bound.
class VulkanComputePassEncoder : IComputePassEncoder
{
	private VkCommandBuffer mCommandBuffer;
	private VulkanComputePipeline mPipeline;

	public this(VkCommandBuffer commandBuffer) => mCommandBuffer = commandBuffer;

	/// Reused across passes on the same encoder, so each begin starts with nothing bound.
	public void Begin(VkCommandBuffer commandBuffer)
	{
		mCommandBuffer = commandBuffer;
		mPipeline = null;
	}

	public void SetPipeline(IComputePipeline pipeline)
	{
		mPipeline = pipeline as VulkanComputePipeline;
		if (mPipeline != null)
		{
			VulkanNative.vkCmdBindPipeline(mCommandBuffer, .VK_PIPELINE_BIND_POINT_COMPUTE,
				mPipeline.Handle);
		}
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets)
	{
		let bindGroup = group as VulkanBindGroup;
		if ((bindGroup == null) || (mPipeline == null))
			return;
		let layout = mPipeline.Layout as VulkanPipelineLayout;
		if (layout == null)
			return;

		var set = bindGroup.Handle;
		VulkanNative.vkCmdBindDescriptorSets(mCommandBuffer, .VK_PIPELINE_BIND_POINT_COMPUTE,
			layout.Handle, index, 1, &set, (uint32)dynamicOffsets.Length,
			dynamicOffsets.IsEmpty ? null : dynamicOffsets.Ptr);
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (mPipeline == null)
			return;
		let layout = mPipeline.Layout as VulkanPipelineLayout;
		if (layout == null)
			return;
		VulkanNative.vkCmdPushConstants(mCommandBuffer, layout.Handle,
			VulkanConversions.ToVkShaderStageFlags(stages), offset, size, data);
	}

	/// A grid of WORKGROUPS, not of threads: the total is this times the workgroup size the
	/// shader declared.
	public void Dispatch(uint32 x, uint32 y, uint32 z)
		=> VulkanNative.vkCmdDispatch(mCommandBuffer, x, y, z);

	public void DispatchIndirect(IBuffer buffer, uint64 offset)
	{
		let vulkanBuffer = buffer as VulkanBuffer;
		if (vulkanBuffer == null)
			return;
		VulkanNative.vkCmdDispatchIndirect(mCommandBuffer, vulkanBuffer.Handle, offset);
	}

	/// Orders one dispatch's writes before the next dispatch's reads.
	///
	/// A memory barrier naming no resource, because the dependency is between the two
	/// dispatches rather than attached to any one buffer.
	public void ComputeBarrier()
	{
		VkMemoryBarrier2 barrier = .();
		barrier.srcStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
		barrier.srcAccessMask = (uint64)VkAccessFlags2.VK_ACCESS_2_SHADER_WRITE_BIT;
		barrier.dstStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
		// Both, because the next dispatch may read what the last wrote and write it again.
		barrier.dstAccessMask = (uint64)(VkAccessFlags2.VK_ACCESS_2_SHADER_READ_BIT | VkAccessFlags2.VK_ACCESS_2_SHADER_WRITE_BIT);

		VkDependencyInfo dependency = .();
		dependency.memoryBarrierCount = 1;
		dependency.pMemoryBarriers = &barrier;

		VulkanNative.vkCmdPipelineBarrier2(mCommandBuffer, &dependency);
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		let query = querySet as VulkanQuerySet;
		if (query == null)
			return;
		VulkanNative.vkCmdWriteTimestamp(mCommandBuffer, .VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,
			query.Handle, index);
	}

	public void End() => mPipeline = null;
}
