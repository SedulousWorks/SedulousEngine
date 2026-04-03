namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IComputePassEncoder.
class VulkanComputePassEncoder : IComputePassEncoder
{
	private VkCommandBuffer mCmdBuf;
	private VulkanDevice mDevice;
	private VulkanComputePipeline mCurrentPipeline;

	public this(VkCommandBuffer cmdBuf, VulkanDevice device)
	{
		mCmdBuf = cmdBuf;
		mDevice = device;
	}

	public void SetPipeline(IComputePipeline pipeline)
	{
		mCurrentPipeline = pipeline as VulkanComputePipeline;
		if (mCurrentPipeline != null)
			VulkanNative.vkCmdBindPipeline(mCmdBuf, .VK_PIPELINE_BIND_POINT_COMPUTE, mCurrentPipeline.Handle);
	}

	public void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets = default)
	{
		if (let vkBg = bindGroup as VulkanBindGroup)
		{
			if (mCurrentPipeline == null) return;
			let layout = (mCurrentPipeline.Layout as VulkanPipelineLayout);
			if (layout == null) return;
			var set = vkBg.Handle;
			VulkanNative.vkCmdBindDescriptorSets(mCmdBuf, .VK_PIPELINE_BIND_POINT_COMPUTE,
				layout.Handle, index, 1, &set,
				(uint32)dynamicOffsets.Length, dynamicOffsets.Ptr);
		}
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (mCurrentPipeline == null) return;
		let layout = (mCurrentPipeline.Layout as VulkanPipelineLayout);
		if (layout == null) return;
		VulkanNative.vkCmdPushConstants(mCmdBuf, layout.Handle,
			VulkanBindGroupLayout.ToVkShaderStageFlags(stages), offset, size, data);
	}

	public void Dispatch(uint32 x, uint32 y = 1, uint32 z = 1)
	{
		VulkanNative.vkCmdDispatch(mCmdBuf, x, y, z);
	}

	public void DispatchIndirect(IBuffer buffer, uint64 offset)
	{
		if (let vkBuf = buffer as VulkanBuffer)
			VulkanNative.vkCmdDispatchIndirect(mCmdBuf, vkBuf.Handle, offset);
	}

	public void ComputeBarrier()
	{
		VkMemoryBarrier2 barrier = .();
		barrier.srcStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
		barrier.srcAccessMask = (uint64)VkAccessFlags2.VK_ACCESS_2_SHADER_WRITE_BIT;
		barrier.dstStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
		barrier.dstAccessMask = (uint64)VkAccessFlags2.VK_ACCESS_2_SHADER_READ_BIT |
			(uint64)VkAccessFlags2.VK_ACCESS_2_SHADER_WRITE_BIT;

		VkDependencyInfo depInfo = .();
		depInfo.memoryBarrierCount = 1;
		depInfo.pMemoryBarriers = &barrier;

		VulkanNative.vkCmdPipelineBarrier2(mCmdBuf, &depInfo);
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (let vkQs = querySet as VulkanQuerySet)
			VulkanNative.vkCmdWriteTimestamp(mCmdBuf, .VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, vkQs.Handle, index);
	}

	public void End()
	{
		mCurrentPipeline = null;
	}
}
