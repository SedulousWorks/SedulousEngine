namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IRenderPassEncoder and IMeshShaderPassExt.
class VulkanRenderPassEncoder : IRenderPassEncoder, IMeshShaderPassExt
{
	private VkCommandBuffer mCmdBuf;
	private VulkanDevice mDevice;
	private VulkanRenderPipeline mCurrentPipeline;
	private VulkanMeshPipeline mCurrentMeshPipeline;

	public this(VkCommandBuffer cmdBuf, VulkanDevice device)
	{
		mCmdBuf = cmdBuf;
		mDevice = device;
	}

	public void SetPipeline(IRenderPipeline pipeline)
	{
		mCurrentPipeline = pipeline as VulkanRenderPipeline;
		if (mCurrentPipeline != null)
			VulkanNative.vkCmdBindPipeline(mCmdBuf, .VK_PIPELINE_BIND_POINT_GRAPHICS, mCurrentPipeline.Handle);
	}

	public void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets = default)
	{
		if (let vkBg = bindGroup as VulkanBindGroup)
		{
			let layout = GetCurrentLayout();
			if (layout == null) return;
			var set = vkBg.Handle;
			VulkanNative.vkCmdBindDescriptorSets(mCmdBuf, .VK_PIPELINE_BIND_POINT_GRAPHICS,
				layout.Handle, index, 1, &set,
				(uint32)dynamicOffsets.Length, dynamicOffsets.Ptr);
		}
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		let layout = GetCurrentLayout();
		if (layout == null) return;
		VulkanNative.vkCmdPushConstants(mCmdBuf, layout.Handle,
			VulkanBindGroupLayout.ToVkShaderStageFlags(stages), offset, size, data);
	}

	private VulkanPipelineLayout GetCurrentLayout()
	{
		if (mCurrentPipeline != null)
			return mCurrentPipeline.Layout as VulkanPipelineLayout;
		if (mCurrentMeshPipeline != null)
			return mCurrentMeshPipeline.Layout as VulkanPipelineLayout;
		return null;
	}

	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset = 0)
	{
		if (let vkBuf = buffer as VulkanBuffer)
		{
			var handle = vkBuf.Handle;
			var off = offset;
			VulkanNative.vkCmdBindVertexBuffers(mCmdBuf, slot, 1, &handle, &off);
		}
	}

	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset = 0)
	{
		if (let vkBuf = buffer as VulkanBuffer)
		{
			VulkanNative.vkCmdBindIndexBuffer(mCmdBuf, vkBuf.Handle, offset,
				VulkanConversions.ToVkIndexType(format));
		}
	}

	public void SetViewport(float x, float y, float w, float h, float minDepth, float maxDepth)
	{
		// Flip Y via negative height (VK_KHR_maintenance1 / Vulkan 1.1+)
		// to match DX12's coordinate system where Y points up.
		VkViewport viewport = .();
		viewport.x = x;
		viewport.y = y + h;
		viewport.width = w;
		viewport.height = -h;
		viewport.minDepth = minDepth;
		viewport.maxDepth = maxDepth;
		VulkanNative.vkCmdSetViewport(mCmdBuf, 0, 1, &viewport);
	}

	public void SetScissor(int32 x, int32 y, uint32 w, uint32 h)
	{
		VkRect2D scissor = .();
		scissor.offset.x = x;
		scissor.offset.y = y;
		scissor.extent.width = w;
		scissor.extent.height = h;
		VulkanNative.vkCmdSetScissor(mCmdBuf, 0, 1, &scissor);
	}

	public void SetBlendConstant(float r, float g, float b, float a)
	{
		float[4] constants = .(r, g, b, a);
		VulkanNative.vkCmdSetBlendConstants(mCmdBuf, constants);
	}

	public void SetStencilReference(uint32 reference)
	{
		VulkanNative.vkCmdSetStencilReference(mCmdBuf, .VK_STENCIL_FACE_FRONT_AND_BACK, reference);
	}

	public void Draw(uint32 vertexCount, uint32 instanceCount = 1,
		uint32 firstVertex = 0, uint32 firstInstance = 0)
	{
		VulkanNative.vkCmdDraw(mCmdBuf, vertexCount, instanceCount, firstVertex, firstInstance);
	}

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount = 1,
		uint32 firstIndex = 0, int32 baseVertex = 0, uint32 firstInstance = 0)
	{
		VulkanNative.vkCmdDrawIndexed(mCmdBuf, indexCount, instanceCount, firstIndex, baseVertex, firstInstance);
	}

	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1, uint32 stride = 0)
	{
		if (let vkBuf = buffer as VulkanBuffer)
		{
			uint32 actualStride = (stride > 0) ? stride : 16; // VkDrawIndirectCommand = 4 * uint32
			VulkanNative.vkCmdDrawIndirect(mCmdBuf, vkBuf.Handle, offset, drawCount, actualStride);
		}
	}

	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1, uint32 stride = 0)
	{
		if (let vkBuf = buffer as VulkanBuffer)
		{
			uint32 actualStride = (stride > 0) ? stride : 20; // VkDrawIndexedIndirectCommand = 5 * uint32
			VulkanNative.vkCmdDrawIndexedIndirect(mCmdBuf, vkBuf.Handle, offset, drawCount, actualStride);
		}
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (let vkQs = querySet as VulkanQuerySet)
			VulkanNative.vkCmdWriteTimestamp(mCmdBuf, .VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, vkQs.Handle, index);
	}

	public void BeginOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		if (let vkQs = querySet as VulkanQuerySet)
			VulkanNative.vkCmdBeginQuery(mCmdBuf, vkQs.Handle, index, .None);
	}

	public void EndOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		if (let vkQs = querySet as VulkanQuerySet)
			VulkanNative.vkCmdEndQuery(mCmdBuf, vkQs.Handle, index);
	}

	// ===== IMeshShaderPassExt =====

	public void SetMeshPipeline(IMeshPipeline pipeline)
	{
		mCurrentMeshPipeline = pipeline as VulkanMeshPipeline;
		if (mCurrentMeshPipeline != null)
			VulkanNative.vkCmdBindPipeline(mCmdBuf, .VK_PIPELINE_BIND_POINT_GRAPHICS, mCurrentMeshPipeline.Handle);
	}

	public void DrawMeshTasks(uint32 groupCountX, uint32 groupCountY = 1, uint32 groupCountZ = 1)
	{
		VulkanNative.vkCmdDrawMeshTasksEXT(mCmdBuf, groupCountX, groupCountY, groupCountZ);
	}

	public void DrawMeshTasksIndirect(IBuffer buffer, uint64 offset,
		uint32 drawCount = 1, uint32 stride = 0)
	{
		if (let vkBuf = buffer as VulkanBuffer)
		{
			uint32 actualStride = (stride > 0) ? stride : 12; // 3 * uint32 (groupCountX/Y/Z)
			VulkanNative.vkCmdDrawMeshTasksIndirectEXT(mCmdBuf, vkBuf.Handle, offset, drawCount, actualStride);
		}
	}

	public void DrawMeshTasksIndirectCount(IBuffer buffer, uint64 offset,
		IBuffer countBuffer, uint64 countOffset,
		uint32 maxDrawCount, uint32 stride)
	{
		let vkBuf = buffer as VulkanBuffer;
		let vkCountBuf = countBuffer as VulkanBuffer;
		if (vkBuf == null || vkCountBuf == null) return;

		uint32 actualStride = (stride > 0) ? stride : 12;
		VulkanNative.vkCmdDrawMeshTasksIndirectCountEXT(mCmdBuf, vkBuf.Handle, offset,
			vkCountBuf.Handle, countOffset, maxDrawCount, actualStride);
	}

	public void End()
	{
		VulkanNative.vkCmdEndRendering(mCmdBuf);
		mCurrentPipeline = null;
		mCurrentMeshPipeline = null;
	}
}
