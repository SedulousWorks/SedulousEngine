using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// Records draws inside a render pass, and the mesh shader stage where the device has it.
class VulkanRenderPassEncoder : IRenderPassEncoder, IMeshShaderPassExt
{
	private VkCommandBuffer mCommandBuffer;
	private VkDevice mDevice;
	private VulkanRenderPipeline mPipeline;
	private VulkanMeshPipeline mMeshPipeline;

	public this(VkCommandBuffer commandBuffer, VkDevice device)
	{
		mCommandBuffer = commandBuffer;
		mDevice = device;
	}

	public void Begin(VkCommandBuffer commandBuffer)
	{
		mCommandBuffer = commandBuffer;
		mPipeline = null;
		mMeshPipeline = null;
	}

	/// Whichever kind of pipeline is bound. Both draw through the same layout, so the
	/// binding calls do not care which one it is.
	private VulkanPipelineLayout CurrentLayout()
	{
		if (mPipeline != null)
			return mPipeline.Layout as VulkanPipelineLayout;
		if (mMeshPipeline != null)
			return mMeshPipeline.Layout as VulkanPipelineLayout;
		return null;
	}

	public void SetPipeline(IRenderPipeline pipeline)
	{
		mPipeline = pipeline as VulkanRenderPipeline;
		mMeshPipeline = null;
		if (mPipeline != null)
		{
			VulkanNative.vkCmdBindPipeline(mCommandBuffer, .VK_PIPELINE_BIND_POINT_GRAPHICS,
				mPipeline.Handle);
		}
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets)
	{
		let bindGroup = group as VulkanBindGroup;
		let layout = CurrentLayout();
		if ((bindGroup == null) || (layout == null))
			return;

		var set = bindGroup.Handle;
		VulkanNative.vkCmdBindDescriptorSets(mCommandBuffer, .VK_PIPELINE_BIND_POINT_GRAPHICS,
			layout.Handle, index, 1, &set, (uint32)dynamicOffsets.Length,
			dynamicOffsets.IsEmpty ? null : dynamicOffsets.Ptr);
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		let layout = CurrentLayout();
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

	/// Y IS FLIPPED, through a negative height and an origin moved to the bottom.
	///
	/// That puts Vulkan's clip space the same way up as DX12's, so one set of shaders and
	/// one projection matrix serve both. It also inverts the apparent triangle winding,
	/// which is why the front face is what it is rather than the reverse.
	public void SetViewport(float x, float y, float width, float height, float minDepth,
		float maxDepth)
	{
		VkViewport viewport = .();
		viewport.x = x;
		viewport.y = y + height;
		viewport.width = width;
		viewport.height = -height;
		viewport.minDepth = minDepth;
		viewport.maxDepth = maxDepth;
		VulkanNative.vkCmdSetViewport(mCommandBuffer, 0, 1, &viewport);
	}

	public void SetScissor(int32 x, int32 y, uint32 width, uint32 height)
	{
		VkRect2D scissor = .();
		scissor.offset = .() { x = x, y = y };
		scissor.extent = .() { width = width, height = height };
		VulkanNative.vkCmdSetScissor(mCommandBuffer, 0, 1, &scissor);
	}

	public void SetBlendConstant(float r, float g, float b, float a)
	{
		float[4] constants = .(r, g, b, a);
		VulkanNative.vkCmdSetBlendConstants(mCommandBuffer, constants);
	}

	/// Set for BOTH faces: the RHI keeps one reference rather than one per facing, which is
	/// what almost every use wants.
	public void SetStencilReference(uint32 reference)
		=> VulkanNative.vkCmdSetStencilReference(mCommandBuffer,
			.VK_STENCIL_FACE_FRONT_AND_BACK, reference);

	public void Draw(uint32 vertexCount, uint32 instanceCount, uint32 firstVertex,
		uint32 firstInstance)
		=> VulkanNative.vkCmdDraw(mCommandBuffer, vertexCount, instanceCount, firstVertex,
			firstInstance);

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount, uint32 firstIndex,
		int32 baseVertex, uint32 firstInstance)
		=> VulkanNative.vkCmdDrawIndexed(mCommandBuffer, indexCount, instanceCount, firstIndex,
			baseVertex, firstInstance);

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

	/// Replays bundles into this pass. They are SECONDARY command buffers, so the pass must
	/// have been begun with the secondary contents flag or the driver rejects them.
	public void ExecuteBundles(Span<IRenderBundle> bundles)
	{
		if (bundles.IsEmpty)
			return;

		let secondaries = scope VkCommandBuffer[bundles.Length];
		int count = 0;
		for (int i < bundles.Length)
		{
			if (let bundle = bundles[i] as VulkanRenderBundle)
			{
				secondaries[count] = bundle.Handle;
				count++;
			}
		}
		if (count == 0)
			return;

		VulkanNative.vkCmdExecuteCommands(mCommandBuffer, (uint32)count, &secondaries[0]);
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		let query = querySet as VulkanQuerySet;
		if (query == null)
			return;
		VulkanNative.vkCmdWriteTimestamp(mCommandBuffer, .VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,
			query.Handle, index);
	}

	public void BeginOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		let query = querySet as VulkanQuerySet;
		if (query == null)
			return;
		VulkanNative.vkCmdBeginQuery(mCommandBuffer, query.Handle, index, default);
	}

	public void EndOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		let query = querySet as VulkanQuerySet;
		if (query == null)
			return;
		VulkanNative.vkCmdEndQuery(mCommandBuffer, query.Handle, index);
	}

	public void End()
	{
		VulkanNative.vkCmdEndRendering(mCommandBuffer);
		mPipeline = null;
		mMeshPipeline = null;
	}

	// ---- IMeshShaderPassExt ----

	public void SetMeshPipeline(IMeshPipeline pipeline)
	{
		mMeshPipeline = pipeline as VulkanMeshPipeline;
		mPipeline = null;
		if (mMeshPipeline != null)
		{
			VulkanNative.vkCmdBindPipeline(mCommandBuffer, .VK_PIPELINE_BIND_POINT_GRAPHICS,
				mMeshPipeline.Handle);
		}
	}

	public void DrawMeshTasks(uint32 groupCountX, uint32 groupCountY, uint32 groupCountZ)
		=> VulkanNative.vkCmdDrawMeshTasksEXT(mCommandBuffer, groupCountX, groupCountY,
			groupCountZ);

	public void DrawMeshTasksIndirect(IBuffer buffer, uint64 offset, uint32 drawCount,
		uint32 stride)
	{
		let vulkanBuffer = buffer as VulkanBuffer;
		if (vulkanBuffer == null)
			return;
		VulkanNative.vkCmdDrawMeshTasksIndirectEXT(mCommandBuffer, vulkanBuffer.Handle, offset,
			drawCount, (stride > 0) ? stride : 12);
	}

	/// The draw COUNT itself comes from a buffer, so the GPU decides how many dispatches
	/// happen and the CPU never learns the number.
	public void DrawMeshTasksIndirectCount(IBuffer buffer, uint64 offset, IBuffer countBuffer,
		uint64 countOffset, uint32 maxDrawCount, uint32 stride)
	{
		let vulkanBuffer = buffer as VulkanBuffer;
		let vulkanCount = countBuffer as VulkanBuffer;
		if ((vulkanBuffer == null) || (vulkanCount == null))
			return;
		VulkanNative.vkCmdDrawMeshTasksIndirectCountEXT(mCommandBuffer, vulkanBuffer.Handle,
			offset, vulkanCount.Handle, countOffset, maxDrawCount, (stride > 0) ? stride : 12);
	}
}
