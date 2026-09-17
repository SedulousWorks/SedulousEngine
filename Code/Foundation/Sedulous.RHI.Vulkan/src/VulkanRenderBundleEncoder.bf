using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// Records draws into a SECONDARY command buffer.
///
/// A bundle carries no pass level state and a Vulkan secondary does not inherit dynamic
/// state, so the viewport and scissor are recorded UP FRONT from the descriptor rather
/// than taken from the pass that later executes it.
class VulkanRenderBundleEncoder : IRenderBundleEncoder
{
	private VkCommandBuffer mCommandBuffer;
	private VulkanRenderPipeline mPipeline;
	private VulkanRenderBundle mBundle ~ delete _;
	private bool mFinished = false;

	public VulkanRenderBundle ProducedBundle => mBundle;

	public Result<void> Initialize(VkDevice device, VkCommandBuffer commandBuffer,
		RenderBundleDesc desc)
	{
		mCommandBuffer = commandBuffer;

		// The attachment signature this bundle may be replayed into. Under dynamic
		// rendering a secondary inherits nothing, so it states the formats itself and the
		// driver checks them against the pass at execute time.
		let colorCount = Math.Min(desc.ColorFormatCount, (uint32)RhiLimits.MaxColorAttachments);
		let colorFormats = scope VkFormat[RhiLimits.MaxColorAttachments];
		for (uint32 i = 0; i < colorCount; i++)
			colorFormats[(int)i] = VulkanConversions.ToVkFormat(desc.ColorFormats[i]);

		let hasDepth = desc.DepthStencilFormat != .Undefined;

		VkCommandBufferInheritanceRenderingInfo inheritRendering = .();
		inheritRendering.colorAttachmentCount = colorCount;
		inheritRendering.pColorAttachmentFormats = &colorFormats[0];
		inheritRendering.depthAttachmentFormat = hasDepth
			? VulkanConversions.ToVkFormat(desc.DepthStencilFormat) : .VK_FORMAT_UNDEFINED;
		inheritRendering.stencilAttachmentFormat =
			(hasDepth && TextureFormats.HasStencil(desc.DepthStencilFormat))
				? VulkanConversions.ToVkFormat(desc.DepthStencilFormat) : .VK_FORMAT_UNDEFINED;
		inheritRendering.rasterizationSamples =
			VulkanConversions.ToVkSampleCount(desc.SampleCount > 0 ? desc.SampleCount : 1);

		VkCommandBufferInheritanceInfo inheritance = .();
		inheritance.pNext = &inheritRendering;

		VkCommandBufferBeginInfo beginInfo = .();
		beginInfo.flags = .VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT
			| .VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
		beginInfo.pInheritanceInfo = &inheritance;

		if (VulkanNative.vkBeginCommandBuffer(mCommandBuffer, &beginInfo) != .VK_SUCCESS)
			return .Err;

		// The bundle's own viewport and scissor, which may be a sub rectangle of the target
		// rather than the whole of it, as split screen wants. Y IS FLIPPED the same way the
		// pass encoder flips it, so a bundle and an inline draw agree on which way is up.
		if ((desc.Width > 0) && (desc.Height > 0))
		{
			VkViewport viewport = .();
			viewport.x = (float)desc.ViewportX;
			viewport.y = (float)desc.ViewportY + (float)desc.Height;
			viewport.width = (float)desc.Width;
			viewport.height = -(float)desc.Height;
			viewport.minDepth = 0.0f;
			viewport.maxDepth = 1.0f;
			VulkanNative.vkCmdSetViewport(mCommandBuffer, 0, 1, &viewport);

			VkRect2D scissor = .();
			scissor.offset = .() { x = desc.ViewportX, y = desc.ViewportY };
			scissor.extent = .() { width = desc.Width, height = desc.Height };
			VulkanNative.vkCmdSetScissor(mCommandBuffer, 0, 1, &scissor);
		}

		return .Ok;
	}

	public void SetPipeline(IRenderPipeline pipeline)
	{
		mPipeline = pipeline as VulkanRenderPipeline;
		if (mPipeline != null)
		{
			VulkanNative.vkCmdBindPipeline(mCommandBuffer, .VK_PIPELINE_BIND_POINT_GRAPHICS,
				mPipeline.Handle);
		}
	}

	/// The layout comes from the BOUND PIPELINE, so binding a group before a pipeline does
	/// nothing rather than binding against the wrong layout.
	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets)
	{
		let bindGroup = group as VulkanBindGroup;
		if ((bindGroup == null) || (mPipeline == null))
			return;
		let layout = mPipeline.Layout as VulkanPipelineLayout;
		if (layout == null)
			return;

		var set = bindGroup.Handle;
		VulkanNative.vkCmdBindDescriptorSets(mCommandBuffer, .VK_PIPELINE_BIND_POINT_GRAPHICS,
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

	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset)
	{
		let vulkanBuffer = buffer as VulkanBuffer;
		if (vulkanBuffer == null)
			return;
		var handle = vulkanBuffer.Handle;
		var bufferOffset = offset;
		VulkanNative.vkCmdBindVertexBuffers(mCommandBuffer, slot, 1, &handle, &bufferOffset);
	}

	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset)
	{
		let vulkanBuffer = buffer as VulkanBuffer;
		if (vulkanBuffer == null)
			return;
		VulkanNative.vkCmdBindIndexBuffer(mCommandBuffer, vulkanBuffer.Handle, offset,
			VulkanConversions.ToVkIndexType(format));
	}

	public void Draw(uint32 vertexCount, uint32 instanceCount, uint32 firstVertex,
		uint32 firstInstance)
		=> VulkanNative.vkCmdDraw(mCommandBuffer, vertexCount, instanceCount, firstVertex,
			firstInstance);

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount, uint32 firstIndex,
		int32 baseVertex, uint32 firstInstance)
		=> VulkanNative.vkCmdDrawIndexed(mCommandBuffer, indexCount, instanceCount, firstIndex,
			baseVertex, firstInstance);

	/// A stride of zero means tightly packed, which for an indirect draw command is twenty
	/// bytes, or sixteen for the non indexed form.
	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
	{
		let vulkanBuffer = buffer as VulkanBuffer;
		if (vulkanBuffer == null)
			return;
		VulkanNative.vkCmdDrawIndirect(mCommandBuffer, vulkanBuffer.Handle, offset, drawCount,
			(stride > 0) ? stride : 16);
	}

	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
	{
		let vulkanBuffer = buffer as VulkanBuffer;
		if (vulkanBuffer == null)
			return;
		VulkanNative.vkCmdDrawIndexedIndirect(mCommandBuffer, vulkanBuffer.Handle, offset,
			drawCount, (stride > 0) ? stride : 20);
	}

	/// Ends recording. Finishing twice returns the SAME bundle rather than ending an
	/// already ended buffer, which the driver would reject.
	public IRenderBundle Finish()
	{
		if (mFinished)
			return mBundle;

		mFinished = true;
		VulkanNative.vkEndCommandBuffer(mCommandBuffer);
		mBundle = new VulkanRenderBundle(mCommandBuffer);
		return mBundle;
	}
}
