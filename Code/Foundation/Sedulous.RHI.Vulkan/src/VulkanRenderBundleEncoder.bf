namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// An immutable, replayable secondary command buffer. Valid until the owning pool resets.
class VulkanRenderBundle : IRenderBundle
{
	private VkCommandBuffer mCmdBuf;

	public this(VkCommandBuffer cmdBuf)
	{
		mCmdBuf = cmdBuf;
	}

	public VkCommandBuffer Handle => mCmdBuf;
}

/// Records draws into a secondary command buffer. The owning command pool
/// allocates/recycles the secondary handle and frees this wrapper (+ the
/// produced bundle) on reset.
class VulkanRenderBundleEncoder : IRenderBundleEncoder
{
	private VkCommandBuffer mCmdBuf;
	private VulkanRenderPipeline mCurrentPipeline;
	private VulkanRenderBundle mBundle ~ delete _;
	private bool mFinished;

	public this(VkCommandBuffer cmdBuf)
	{
		mCmdBuf = cmdBuf;
	}

	public void SetPipeline(IRenderPipeline pipeline)
	{
		let vkPipeline = pipeline as VulkanRenderPipeline;
		mCurrentPipeline = vkPipeline;
		if (vkPipeline != null)
			VulkanNative.vkCmdBindPipeline(mCmdBuf, .VK_PIPELINE_BIND_POINT_GRAPHICS, vkPipeline.Handle);
	}

	public void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets)
	{
		let bg = bindGroup as VulkanBindGroup;
		let layout = (mCurrentPipeline != null) ? mCurrentPipeline.Layout as VulkanPipelineLayout : null;
		if (bg == null || layout == null) return;
		var set = bg.Handle;
		VulkanNative.vkCmdBindDescriptorSets(mCmdBuf, .VK_PIPELINE_BIND_POINT_GRAPHICS, layout.Handle,
			index, 1, &set, (uint32)dynamicOffsets.Length, dynamicOffsets.Ptr);
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		let layout = (mCurrentPipeline != null) ? mCurrentPipeline.Layout as VulkanPipelineLayout : null;
		if (layout == null) return;
		VulkanNative.vkCmdPushConstants(mCmdBuf, layout.Handle, VulkanBindGroupLayout.ToVkShaderStageFlags(stages), offset, size, data);
	}

	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset)
	{
		let vkBuf = buffer as VulkanBuffer;
		if (vkBuf == null) return;
		var handle = vkBuf.Handle;
		var off = offset;
		VulkanNative.vkCmdBindVertexBuffers(mCmdBuf, slot, 1, &handle, &off);
	}

	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset)
	{
		let vkBuf = buffer as VulkanBuffer;
		if (vkBuf == null) return;
		VulkanNative.vkCmdBindIndexBuffer(mCmdBuf, vkBuf.Handle, offset, VulkanConversions.ToVkIndexType(format));
	}

	public void Draw(uint32 vertexCount, uint32 instanceCount, uint32 firstVertex, uint32 firstInstance)
	{
		VulkanNative.vkCmdDraw(mCmdBuf, vertexCount, instanceCount, firstVertex, firstInstance);
	}

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount, uint32 firstIndex, int32 baseVertex, uint32 firstInstance)
	{
		VulkanNative.vkCmdDrawIndexed(mCmdBuf, indexCount, instanceCount, firstIndex, baseVertex, firstInstance);
	}

	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
	{
		let vkBuf = buffer as VulkanBuffer;
		if (vkBuf == null) return;
		VulkanNative.vkCmdDrawIndirect(mCmdBuf, vkBuf.Handle, offset, drawCount, stride > 0 ? stride : 16);
	}

	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
	{
		let vkBuf = buffer as VulkanBuffer;
		if (vkBuf == null) return;
		VulkanNative.vkCmdDrawIndexedIndirect(mCmdBuf, vkBuf.Handle, offset, drawCount, stride > 0 ? stride : 20);
	}

	public IRenderBundle Finish()
	{
		if (mFinished)
			return mBundle;
		mFinished = true;
		VulkanNative.vkEndCommandBuffer(mCmdBuf);
		mBundle = new VulkanRenderBundle(mCmdBuf);
		return mBundle;
	}
}
