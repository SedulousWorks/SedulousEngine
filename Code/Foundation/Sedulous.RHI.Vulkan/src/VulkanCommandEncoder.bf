namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;
using Sedulous.RHI;

using static Sedulous.RHI.TextureFormatExt;

/// Vulkan implementation of ICommandEncoder and IRayTracingEncoderExt.
class VulkanCommandEncoder : ICommandEncoder, IRayTracingEncoderExt
{
	private VkCommandBuffer mCmdBuf;
	private VulkanDevice mDevice;
	private VulkanCommandPool mPool;
	private VulkanRenderPassEncoder mRenderPassEncoder;
	private VulkanComputePassEncoder mComputePassEncoder;
	private VulkanRayTracingPipeline mCurrentRtPipeline;

	public this(VkCommandBuffer cmdBuf, VulkanDevice device, VulkanCommandPool pool)
	{
		mCmdBuf = cmdBuf;
		mDevice = device;
		mPool = pool;
		mRenderPassEncoder = new VulkanRenderPassEncoder(cmdBuf, device);
		mComputePassEncoder = new VulkanComputePassEncoder(cmdBuf, device);
	}

	public ~this()
	{
		delete mRenderPassEncoder;
		delete mComputePassEncoder;
	}

	public IRenderPassEncoder BeginRenderPass(RenderPassDesc desc)
	{
		// Build color attachments
		VkRenderingAttachmentInfo[] colorAttachments = scope VkRenderingAttachmentInfo[desc.ColorAttachments.Count];
		for (int i = 0; i < desc.ColorAttachments.Count; i++)
		{
			let att = desc.ColorAttachments[i];
			colorAttachments[i] = .();
			if (let vkView = att.View as VulkanTextureView)
				colorAttachments[i].imageView = vkView.Handle;
			colorAttachments[i].imageLayout = .VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
			colorAttachments[i].loadOp = VulkanConversions.ToVkLoadOp(att.LoadOp);
			colorAttachments[i].storeOp = VulkanConversions.ToVkStoreOp(att.StoreOp);
			colorAttachments[i].clearValue.color = VkClearColorValue() { float32 = .(att.ClearValue.R, att.ClearValue.G, att.ClearValue.B, att.ClearValue.A) };

			if (let resolveView = att.ResolveTarget as VulkanTextureView)
			{
				colorAttachments[i].resolveMode = .VK_RESOLVE_MODE_AVERAGE_BIT;
				colorAttachments[i].resolveImageView = resolveView.Handle;
				colorAttachments[i].resolveImageLayout = .VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
			}
		}

		// Determine render area from first color attachment
		VkRect2D renderArea = .();
		if (desc.ColorAttachments.Count > 0)
		{
			if (let vkView = desc.ColorAttachments[0].View as VulkanTextureView)
			{
				renderArea.extent.width = vkView.Width;
				renderArea.extent.height = vkView.Height;
			}
		}
		else if (desc.DepthStencilAttachment != null)
		{
			if (let vkView = desc.DepthStencilAttachment.Value.View as VulkanTextureView)
			{
				renderArea.extent.width = vkView.Width;
				renderArea.extent.height = vkView.Height;
			}
		}

		VkRenderingInfo renderingInfo = .();
		renderingInfo.renderArea = renderArea;
		renderingInfo.layerCount = 1;
		renderingInfo.colorAttachmentCount = (uint32)desc.ColorAttachments.Count;
		renderingInfo.pColorAttachments = colorAttachments.CArray();

		// Depth/stencil attachment
		VkRenderingAttachmentInfo depthAttachment = .();
		VkRenderingAttachmentInfo stencilAttachment = .();
		if (desc.DepthStencilAttachment != null)
		{
			let ds = desc.DepthStencilAttachment.Value;
			if (let vkView = ds.View as VulkanTextureView)
			{
				depthAttachment.imageView = vkView.Handle;
				depthAttachment.imageLayout = ds.DepthReadOnly
					? .VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL
					: .VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
				depthAttachment.loadOp = VulkanConversions.ToVkLoadOp(ds.DepthLoadOp);
				depthAttachment.storeOp = VulkanConversions.ToVkStoreOp(ds.DepthStoreOp);
				depthAttachment.clearValue.depthStencil = VkClearDepthStencilValue() { depth = ds.DepthClearValue, stencil = ds.StencilClearValue };
				renderingInfo.pDepthAttachment = &depthAttachment;

				// Only set stencil attachment if the format actually has a stencil component
				if (vkView.Format.HasStencil())
				{
					stencilAttachment = depthAttachment;
					stencilAttachment.loadOp = VulkanConversions.ToVkLoadOp(ds.StencilLoadOp);
					stencilAttachment.storeOp = VulkanConversions.ToVkStoreOp(ds.StencilStoreOp);
					renderingInfo.pStencilAttachment = &stencilAttachment;
				}
			}
		}

		VulkanNative.vkCmdBeginRendering(mCmdBuf, &renderingInfo);
		return mRenderPassEncoder;
	}

	public IComputePassEncoder BeginComputePass(StringView label = default)
	{
		return mComputePassEncoder;
	}

	public void Barrier(BarrierGroup barriers)
	{
		List<VkMemoryBarrier2> memBarriers = scope .(barriers.MemoryBarriers.Length);
		List<VkBufferMemoryBarrier2> bufBarriers = scope .(barriers.BufferBarriers.Length);
		List<VkImageMemoryBarrier2> imgBarriers = scope .(barriers.TextureBarriers.Length);

		// Memory barriers
		for (let mb in barriers.MemoryBarriers)
		{
			let src = VulkanBarrierHelper.GetStageAccess(mb.OldState);
			let dst = VulkanBarrierHelper.GetStageAccess(mb.NewState);
			VkMemoryBarrier2 vkBarrier = .();
			vkBarrier.srcStageMask = src.StageMask;
			vkBarrier.srcAccessMask = src.AccessMask;
			vkBarrier.dstStageMask = dst.StageMask;
			vkBarrier.dstAccessMask = dst.AccessMask;
			memBarriers.Add(vkBarrier);
		}

		// Buffer barriers
		for (let bb in barriers.BufferBarriers)
		{
			let src = VulkanBarrierHelper.GetStageAccess(bb.OldState);
			let dst = VulkanBarrierHelper.GetStageAccess(bb.NewState);
			VkBufferMemoryBarrier2 vkBarrier = .();
			vkBarrier.srcStageMask = src.StageMask;
			vkBarrier.srcAccessMask = src.AccessMask;
			vkBarrier.dstStageMask = dst.StageMask;
			vkBarrier.dstAccessMask = dst.AccessMask;
			vkBarrier.srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
			vkBarrier.dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
			if (let vkBuf = bb.Buffer as VulkanBuffer)
				vkBarrier.buffer = vkBuf.Handle;
			vkBarrier.offset = bb.Offset;
			vkBarrier.size = (bb.Size == uint64.MaxValue) ? VulkanNative.VK_WHOLE_SIZE : bb.Size;
			bufBarriers.Add(vkBarrier);
		}

		// Texture barriers
		for (let tb in barriers.TextureBarriers)
		{
			let src = VulkanBarrierHelper.GetStageAccess(tb.OldState);
			let dst = VulkanBarrierHelper.GetStageAccess(tb.NewState);

			TextureFormat format = .Undefined;
			VulkanTexture vkTex = tb.Texture as VulkanTexture;
			if (vkTex != null)
				format = vkTex.Desc.Format;

			let newLayout = VulkanBarrierHelper.GetImageLayout(tb.NewState);

			let resolvedOldLayout = (vkTex != null) ? vkTex.CurrentLayout : VulkanBarrierHelper.GetImageLayout(tb.OldState);

			VkImageMemoryBarrier2 vkBarrier = .();
			// When the actual old layout is UNDEFINED (first use), there is no prior
			// work to synchronize against - use TOP_OF_PIPE with no access flags.
			if (resolvedOldLayout == .VK_IMAGE_LAYOUT_UNDEFINED)
			{
				vkBarrier.srcStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT;
				vkBarrier.srcAccessMask = 0;
			}
			else
			{
				vkBarrier.srcStageMask = src.StageMask;
				vkBarrier.srcAccessMask = src.AccessMask;
			}
			vkBarrier.dstStageMask = dst.StageMask;
			vkBarrier.dstAccessMask = dst.AccessMask;
			vkBarrier.oldLayout = resolvedOldLayout;
			vkBarrier.newLayout = newLayout;
			vkBarrier.srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
			vkBarrier.dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
			if (vkTex != null)
			{
				vkBarrier.image = vkTex.Handle;
				vkTex.CurrentLayout = newLayout;
			}
			vkBarrier.subresourceRange.aspectMask = VulkanConversions.GetAspectMask(format);
			vkBarrier.subresourceRange.baseMipLevel = tb.BaseMipLevel;
			vkBarrier.subresourceRange.levelCount = (tb.MipLevelCount == uint32.MaxValue) ? VulkanNative.VK_REMAINING_MIP_LEVELS : tb.MipLevelCount;
			vkBarrier.subresourceRange.baseArrayLayer = tb.BaseArrayLayer;
			vkBarrier.subresourceRange.layerCount = (tb.ArrayLayerCount == uint32.MaxValue) ? VulkanNative.VK_REMAINING_ARRAY_LAYERS : tb.ArrayLayerCount;
			imgBarriers.Add(vkBarrier);
		}

		VkDependencyInfo depInfo = .();
		depInfo.memoryBarrierCount = (uint32)memBarriers.Count;
		depInfo.pMemoryBarriers = memBarriers.Ptr;
		depInfo.bufferMemoryBarrierCount = (uint32)bufBarriers.Count;
		depInfo.pBufferMemoryBarriers = bufBarriers.Ptr;
		depInfo.imageMemoryBarrierCount = (uint32)imgBarriers.Count;
		depInfo.pImageMemoryBarriers = imgBarriers.Ptr;

		VulkanNative.vkCmdPipelineBarrier2(mCmdBuf, &depInfo);
	}

	public void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset, uint64 size)
	{
		let vkSrc = src as VulkanBuffer;
		let vkDst = dst as VulkanBuffer;
		if (vkSrc == null || vkDst == null) return;

		VkBufferCopy region = .();
		region.srcOffset = srcOffset;
		region.dstOffset = dstOffset;
		region.size = size;
		VulkanNative.vkCmdCopyBuffer(mCmdBuf, vkSrc.Handle, vkDst.Handle, 1, &region);
	}

	public void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region)
	{
		let vkSrc = src as VulkanBuffer;
		let vkDst = dst as VulkanTexture;
		if (vkSrc == null || vkDst == null) return;

		let bpp = vkDst.Desc.Format.BytesPerPixel();

		VkBufferImageCopy copy = .();
		copy.bufferOffset = region.BufferOffset;
		copy.bufferRowLength = (bpp > 0 && region.BytesPerRow > 0) ? region.BytesPerRow / bpp : 0;
		copy.bufferImageHeight = region.RowsPerImage;
		copy.imageSubresource.aspectMask = VulkanConversions.GetAspectMask(vkDst.Desc.Format);
		copy.imageSubresource.mipLevel = region.TextureMipLevel;
		copy.imageSubresource.baseArrayLayer = region.TextureArrayLayer;
		copy.imageSubresource.layerCount = 1;
		copy.imageExtent.width = region.TextureExtent.Width;
		copy.imageExtent.height = region.TextureExtent.Height;
		copy.imageExtent.depth = region.TextureExtent.Depth;

		VulkanNative.vkCmdCopyBufferToImage(mCmdBuf, vkSrc.Handle, vkDst.Handle,
			.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &copy);
	}

	public void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region)
	{
		let vkSrc = src as VulkanTexture;
		let vkDst = dst as VulkanBuffer;
		if (vkSrc == null || vkDst == null) return;

		let bpp = vkSrc.Desc.Format.BytesPerPixel();

		VkBufferImageCopy copy = .();
		copy.bufferOffset = region.BufferOffset;
		copy.bufferRowLength = (bpp > 0 && region.BytesPerRow > 0) ? region.BytesPerRow / bpp : 0;
		copy.bufferImageHeight = region.RowsPerImage;
		copy.imageSubresource.aspectMask = VulkanConversions.GetAspectMask(vkSrc.Desc.Format);
		copy.imageSubresource.mipLevel = region.TextureMipLevel;
		copy.imageSubresource.baseArrayLayer = region.TextureArrayLayer;
		copy.imageSubresource.layerCount = 1;
		copy.imageExtent.width = region.TextureExtent.Width;
		copy.imageExtent.height = region.TextureExtent.Height;
		copy.imageExtent.depth = region.TextureExtent.Depth;

		VulkanNative.vkCmdCopyImageToBuffer(mCmdBuf, vkSrc.Handle,
			.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, vkDst.Handle, 1, &copy);
	}

	public void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region)
	{
		let vkSrc = src as VulkanTexture;
		let vkDst = dst as VulkanTexture;
		if (vkSrc == null || vkDst == null) return;

		VkImageCopy copy = .();
		copy.srcSubresource.aspectMask = VulkanConversions.GetAspectMask(vkSrc.Desc.Format);
		copy.srcSubresource.mipLevel = region.SrcMipLevel;
		copy.srcSubresource.baseArrayLayer = region.SrcArrayLayer;
		copy.srcSubresource.layerCount = 1;
		copy.dstSubresource.aspectMask = VulkanConversions.GetAspectMask(vkDst.Desc.Format);
		copy.dstSubresource.mipLevel = region.DstMipLevel;
		copy.dstSubresource.baseArrayLayer = region.DstArrayLayer;
		copy.dstSubresource.layerCount = 1;
		copy.extent.width = region.Extent.Width;
		copy.extent.height = region.Extent.Height;
		copy.extent.depth = region.Extent.Depth;

		VulkanNative.vkCmdCopyImage(mCmdBuf, vkSrc.Handle, .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
			vkDst.Handle, .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &copy);
	}

	public void Blit(ITexture src, ITexture dst)
	{
		let vkSrc = src as VulkanTexture;
		let vkDst = dst as VulkanTexture;
		if (vkSrc == null || vkDst == null) return;

		VkImageBlit blit = .();
		blit.srcSubresource.aspectMask = VulkanConversions.GetAspectMask(vkSrc.Desc.Format);
		blit.srcSubresource.mipLevel = 0;
		blit.srcSubresource.baseArrayLayer = 0;
		blit.srcSubresource.layerCount = 1;
		blit.srcOffsets[0] = VkOffset3D() { x = 0, y = 0, z = 0 };
		blit.srcOffsets[1] = VkOffset3D() { x = (int32)vkSrc.Desc.Width, y = (int32)vkSrc.Desc.Height, z = 1 };

		blit.dstSubresource.aspectMask = VulkanConversions.GetAspectMask(vkDst.Desc.Format);
		blit.dstSubresource.mipLevel = 0;
		blit.dstSubresource.baseArrayLayer = 0;
		blit.dstSubresource.layerCount = 1;
		blit.dstOffsets[0] = VkOffset3D() { x = 0, y = 0, z = 0 };
		blit.dstOffsets[1] = VkOffset3D() { x = (int32)vkDst.Desc.Width, y = (int32)vkDst.Desc.Height, z = 1 };

		VulkanNative.vkCmdBlitImage(mCmdBuf,
			vkSrc.Handle, .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
			vkDst.Handle, .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			1, &blit, .VK_FILTER_LINEAR);
	}

	public void GenerateMipmaps(ITexture texture)
	{
		let vkTex = texture as VulkanTexture;
		if (vkTex == null) return;

		let desc = vkTex.Desc;
		if (desc.MipLevelCount <= 1) return;

		int32 mipWidth = (int32)desc.Width;
		int32 mipHeight = (int32)desc.Height;
		let aspect = VulkanConversions.GetAspectMask(desc.Format);
		uint32 layerCount = desc.ArrayLayerCount;

		for (uint32 i = 1; i < desc.MipLevelCount; i++)
		{
			// Transition mip i-1 to TRANSFER_SRC
			VkImageMemoryBarrier2 srcBarrier = .();
			srcBarrier.srcStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
			srcBarrier.srcAccessMask = (uint64)VkAccessFlags2.VK_ACCESS_2_TRANSFER_WRITE_BIT;
			srcBarrier.dstStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
			srcBarrier.dstAccessMask = (uint64)VkAccessFlags2.VK_ACCESS_2_TRANSFER_READ_BIT;
			srcBarrier.oldLayout = .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
			srcBarrier.newLayout = .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
			srcBarrier.image = vkTex.Handle;
			srcBarrier.subresourceRange.aspectMask = aspect;
			srcBarrier.subresourceRange.baseMipLevel = i - 1;
			srcBarrier.subresourceRange.levelCount = 1;
			srcBarrier.subresourceRange.baseArrayLayer = 0;
			srcBarrier.subresourceRange.layerCount = layerCount;

			// For the first mip, the caller should have transitioned mip 0 to TRANSFER_DST already
			if (i == 1)
				srcBarrier.oldLayout = .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;

			VkDependencyInfo dep = .();
			dep.imageMemoryBarrierCount = 1;
			dep.pImageMemoryBarriers = &srcBarrier;
			VulkanNative.vkCmdPipelineBarrier2(mCmdBuf, &dep);

			// Blit from mip i-1 to mip i
			int32 nextWidth = Math.Max(1, mipWidth / 2);
			int32 nextHeight = Math.Max(1, mipHeight / 2);

			VkImageBlit blit = .();
			blit.srcSubresource.aspectMask = aspect;
			blit.srcSubresource.mipLevel = i - 1;
			blit.srcSubresource.baseArrayLayer = 0;
			blit.srcSubresource.layerCount = layerCount;
			blit.srcOffsets[0] = VkOffset3D() { x = 0, y = 0, z = 0 };
			blit.srcOffsets[1] = VkOffset3D() { x = mipWidth, y = mipHeight, z = 1 };

			blit.dstSubresource.aspectMask = aspect;
			blit.dstSubresource.mipLevel = i;
			blit.dstSubresource.baseArrayLayer = 0;
			blit.dstSubresource.layerCount = layerCount;
			blit.dstOffsets[0] = VkOffset3D() { x = 0, y = 0, z = 0 };
			blit.dstOffsets[1] = VkOffset3D() { x = nextWidth, y = nextHeight, z = 1 };

			VulkanNative.vkCmdBlitImage(mCmdBuf,
				vkTex.Handle, .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
				vkTex.Handle, .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
				1, &blit, .VK_FILTER_LINEAR);

			mipWidth = nextWidth;
			mipHeight = nextHeight;
		}

		// Transition last mip level from DST to SRC (so all mips are in SRC)
		VkImageMemoryBarrier2 lastBarrier = .();
		lastBarrier.srcStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
		lastBarrier.srcAccessMask = (uint64)VkAccessFlags2.VK_ACCESS_2_TRANSFER_WRITE_BIT;
		lastBarrier.dstStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
		lastBarrier.dstAccessMask = (uint64)VkAccessFlags2.VK_ACCESS_2_TRANSFER_READ_BIT;
		lastBarrier.oldLayout = .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
		lastBarrier.newLayout = .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
		lastBarrier.image = vkTex.Handle;
		lastBarrier.subresourceRange.aspectMask = aspect;
		lastBarrier.subresourceRange.baseMipLevel = desc.MipLevelCount - 1;
		lastBarrier.subresourceRange.levelCount = 1;
		lastBarrier.subresourceRange.baseArrayLayer = 0;
		lastBarrier.subresourceRange.layerCount = layerCount;

		VkDependencyInfo lastDep = .();
		lastDep.imageMemoryBarrierCount = 1;
		lastDep.pImageMemoryBarriers = &lastBarrier;
		VulkanNative.vkCmdPipelineBarrier2(mCmdBuf, &lastDep);
	}

	public void ResolveTexture(ITexture src, ITexture dst)
	{
		let vkSrc = src as VulkanTexture;
		let vkDst = dst as VulkanTexture;
		if (vkSrc == null || vkDst == null) return;

		let aspect = VulkanConversions.GetAspectMask(vkSrc.Desc.Format);

		VkImageResolve region = .();
		region.srcSubresource.aspectMask = aspect;
		region.srcSubresource.mipLevel = 0;
		region.srcSubresource.baseArrayLayer = 0;
		region.srcSubresource.layerCount = 1;
		region.dstSubresource.aspectMask = aspect;
		region.dstSubresource.mipLevel = 0;
		region.dstSubresource.baseArrayLayer = 0;
		region.dstSubresource.layerCount = 1;
		region.extent = VkExtent3D() { width = vkSrc.Desc.Width, height = vkSrc.Desc.Height, depth = 1 };

		VulkanNative.vkCmdResolveImage(mCmdBuf,
			vkSrc.Handle, .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
			vkDst.Handle, .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			1, &region);
	}

	public void ResetQuerySet(IQuerySet querySet, uint32 first, uint32 count)
	{
		if (let vkQs = querySet as VulkanQuerySet)
			VulkanNative.vkCmdResetQueryPool(mCmdBuf, vkQs.Handle, first, count);
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (let vkQs = querySet as VulkanQuerySet)
			VulkanNative.vkCmdWriteTimestamp(mCmdBuf, .VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, vkQs.Handle, index);
	}

	public void ResolveQuerySet(IQuerySet querySet, uint32 first, uint32 count, IBuffer dst, uint64 dstOffset)
	{
		if (let vkQs = querySet as VulkanQuerySet)
		{
			if (let vkBuf = dst as VulkanBuffer)
			{
				VulkanNative.vkCmdCopyQueryPoolResults(mCmdBuf, vkQs.Handle, first, count,
					vkBuf.Handle, dstOffset, 8, // uint64 stride
					.VK_QUERY_RESULT_64_BIT | .VK_QUERY_RESULT_WAIT_BIT);
			}
		}
	}

	public void BeginDebugLabel(StringView label, float r = 0, float g = 0, float b = 0, float a = 1)
	{
		if(!mDevice.ValidationEnabled)
			return;

		char8[256] buf = default;
		let len = Math.Min(label.Length, 255);
		Internal.MemCpy(&buf, label.Ptr, len);
		buf[len] = 0;
		VkDebugUtilsLabelEXT labelInfo = .();
		labelInfo.pLabelName = &buf;
		labelInfo.color = .(r, g, b, a);
		VulkanNative.vkCmdBeginDebugUtilsLabelEXT(mCmdBuf, &labelInfo);
	}

	public void EndDebugLabel()
	{
		if(!mDevice.ValidationEnabled)
			return;

		VulkanNative.vkCmdEndDebugUtilsLabelEXT(mCmdBuf);
	}

	public void InsertDebugLabel(StringView label, float r = 0, float g = 0, float b = 0, float a = 1)
	{
		if(!mDevice.ValidationEnabled)
			return;

		char8[256] buf = default;
		let len = Math.Min(label.Length, 255);
		Internal.MemCpy(&buf, label.Ptr, len);
		buf[len] = 0;
		VkDebugUtilsLabelEXT labelInfo = .();
		labelInfo.pLabelName = &buf;
		labelInfo.color = .(r, g, b, a);
		VulkanNative.vkCmdInsertDebugUtilsLabelEXT(mCmdBuf, &labelInfo);
	}

	// ===== IRayTracingEncoderExt =====

	public void BuildBottomLevelAccelStruct(
		IAccelStruct dst, IBuffer scratchBuffer, uint64 scratchOffset,
		Span<AccelStructGeometryTriangles> triangleGeometries,
		Span<AccelStructGeometryAABBs> aabbGeometries)
	{
		let vkAs = dst as VulkanAccelStruct;
		let vkScratch = scratchBuffer as VulkanBuffer;
		if (vkAs == null || vkScratch == null) return;

		let geomCount = triangleGeometries.Length + aabbGeometries.Length;
		VkAccelerationStructureGeometryKHR[] geometries = scope VkAccelerationStructureGeometryKHR[geomCount];
		VkAccelerationStructureBuildRangeInfoKHR[] rangeInfos = scope VkAccelerationStructureBuildRangeInfoKHR[geomCount];

		int idx = 0;

		// Triangle geometries
		for (let triGeom in triangleGeometries)
		{
			let vkVertBuf = triGeom.VertexBuffer as VulkanBuffer;
			if (vkVertBuf == null) continue;

			VkAccelerationStructureGeometryTrianglesDataKHR triData = .();
			triData.vertexFormat = VulkanConversions.ToVkVertexFormat(triGeom.VertexFormat);
			triData.vertexData.deviceAddress = GetBufferDeviceAddress(vkVertBuf) + triGeom.VertexOffset;
			triData.vertexStride = triGeom.VertexStride;
			triData.maxVertex = triGeom.VertexCount - 1;

			if (let vkIdxBuf = triGeom.IndexBuffer as VulkanBuffer)
			{
				triData.indexType = VulkanConversions.ToVkIndexType(triGeom.IndexFormat);
				triData.indexData.deviceAddress = GetBufferDeviceAddress(vkIdxBuf) + triGeom.IndexOffset;
			}
			else
			{
				triData.indexType = .VK_INDEX_TYPE_NONE_KHR;
			}

			if (let vkTransBuf = triGeom.TransformBuffer as VulkanBuffer)
				triData.transformData.deviceAddress = GetBufferDeviceAddress(vkTransBuf) + triGeom.TransformOffset;

			geometries[idx] = .();
			geometries[idx].geometryType = .VK_GEOMETRY_TYPE_TRIANGLES_KHR;
			geometries[idx].geometry.triangles = triData;
			geometries[idx].flags = ToVkGeometryFlags(triGeom.Flags);

			rangeInfos[idx] = .();
			rangeInfos[idx].primitiveCount = (triGeom.IndexBuffer != null)
				? triGeom.IndexCount / 3
				: triGeom.VertexCount / 3;
			rangeInfos[idx].primitiveOffset = 0;
			rangeInfos[idx].firstVertex = 0;
			rangeInfos[idx].transformOffset = 0;

			idx++;
		}

		// AABB geometries
		for (let aabbGeom in aabbGeometries)
		{
			let vkBuf = aabbGeom.AABBBuffer as VulkanBuffer;
			if (vkBuf == null) continue;

			VkAccelerationStructureGeometryAabbsDataKHR aabbData = .();
			aabbData.data.deviceAddress = GetBufferDeviceAddress(vkBuf) + aabbGeom.Offset;
			aabbData.stride = aabbGeom.Stride;

			geometries[idx] = .();
			geometries[idx].geometryType = .VK_GEOMETRY_TYPE_AABBS_KHR;
			geometries[idx].geometry.aabbs = aabbData;
			geometries[idx].flags = ToVkGeometryFlags(aabbGeom.Flags);

			rangeInfos[idx] = .();
			rangeInfos[idx].primitiveCount = aabbGeom.Count;
			rangeInfos[idx].primitiveOffset = 0;

			idx++;
		}

		let actualGeomCount = (uint32)idx;

		VkAccelerationStructureBuildGeometryInfoKHR buildInfo = .();
		buildInfo.type = .VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR;
		buildInfo.flags = .VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_KHR;
		buildInfo.mode = .VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR;
		buildInfo.dstAccelerationStructure = vkAs.Handle;
		buildInfo.geometryCount = actualGeomCount;
		buildInfo.pGeometries = geometries.CArray();
		buildInfo.scratchData.deviceAddress = GetBufferDeviceAddress(vkScratch) + scratchOffset;

		VkAccelerationStructureBuildRangeInfoKHR* pRangeInfos = rangeInfos.CArray();
		VulkanNative.vkCmdBuildAccelerationStructuresKHR(mCmdBuf, 1, &buildInfo, &pRangeInfos);
	}

	public void BuildTopLevelAccelStruct(
		IAccelStruct dst, IBuffer scratchBuffer, uint64 scratchOffset,
		IBuffer instanceBuffer, uint64 instanceOffset, uint32 instanceCount)
	{
		let vkAs = dst as VulkanAccelStruct;
		let vkScratch = scratchBuffer as VulkanBuffer;
		let vkInstBuf = instanceBuffer as VulkanBuffer;
		if (vkAs == null || vkScratch == null || vkInstBuf == null) return;

		VkAccelerationStructureGeometryInstancesDataKHR instanceData = .();
		instanceData.arrayOfPointers = VkBool32.False;
		instanceData.data.deviceAddress = GetBufferDeviceAddress(vkInstBuf) + instanceOffset;

		VkAccelerationStructureGeometryKHR geometry = .();
		geometry.geometryType = .VK_GEOMETRY_TYPE_INSTANCES_KHR;
		geometry.geometry.instances = instanceData;

		VkAccelerationStructureBuildGeometryInfoKHR buildInfo = .();
		buildInfo.type = .VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_KHR;
		buildInfo.flags = .VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_KHR;
		buildInfo.mode = .VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR;
		buildInfo.dstAccelerationStructure = vkAs.Handle;
		buildInfo.geometryCount = 1;
		buildInfo.pGeometries = &geometry;
		buildInfo.scratchData.deviceAddress = GetBufferDeviceAddress(vkScratch) + scratchOffset;

		VkAccelerationStructureBuildRangeInfoKHR rangeInfo = .();
		rangeInfo.primitiveCount = instanceCount;

		VkAccelerationStructureBuildRangeInfoKHR* pRangeInfo = &rangeInfo;
		VulkanNative.vkCmdBuildAccelerationStructuresKHR(mCmdBuf, 1, &buildInfo, &pRangeInfo);
	}

	public void SetRayTracingPipeline(IRayTracingPipeline pipeline)
	{
		mCurrentRtPipeline = pipeline as VulkanRayTracingPipeline;
		if (mCurrentRtPipeline != null)
			VulkanNative.vkCmdBindPipeline(mCmdBuf, .VK_PIPELINE_BIND_POINT_RAY_TRACING_KHR, mCurrentRtPipeline.Handle);
	}

	void IRayTracingEncoderExt.SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets)
	{
		if (let vkBg = bindGroup as VulkanBindGroup)
		{
			if (mCurrentRtPipeline == null) return;
			let layout = mCurrentRtPipeline.Layout as VulkanPipelineLayout;
			if (layout == null) return;
			var set = vkBg.Handle;
			VulkanNative.vkCmdBindDescriptorSets(mCmdBuf, .VK_PIPELINE_BIND_POINT_RAY_TRACING_KHR,
				layout.Handle, index, 1, &set,
				(uint32)dynamicOffsets.Length, dynamicOffsets.Ptr);
		}
	}

	void IRayTracingEncoderExt.SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (mCurrentRtPipeline == null) return;
		let layout = mCurrentRtPipeline.Layout as VulkanPipelineLayout;
		if (layout == null) return;
		VulkanNative.vkCmdPushConstants(mCmdBuf, layout.Handle,
			VulkanBindGroupLayout.ToVkShaderStageFlags(stages), offset, size, data);
	}

	public void TraceRays(
		IBuffer raygenSBT, uint64 raygenOffset, uint64 raygenStride,
		IBuffer missSBT, uint64 missOffset, uint64 missStride,
		IBuffer hitSBT, uint64 hitOffset, uint64 hitStride,
		uint32 width, uint32 height, uint32 depth = 1)
	{
		let vkRaygen = raygenSBT as VulkanBuffer;
		let vkMiss = missSBT as VulkanBuffer;
		let vkHit = hitSBT as VulkanBuffer;
		if (vkRaygen == null) return;

		VkStridedDeviceAddressRegionKHR raygenRegion = .();
		raygenRegion.deviceAddress = GetBufferDeviceAddress(vkRaygen) + raygenOffset;
		raygenRegion.stride = raygenStride;
		raygenRegion.size = raygenStride; // raygen has exactly 1 entry

		VkStridedDeviceAddressRegionKHR missRegion = .();
		if (vkMiss != null)
		{
			missRegion.deviceAddress = GetBufferDeviceAddress(vkMiss) + missOffset;
			missRegion.stride = missStride;
			missRegion.size = missStride; // Caller should provide proper size
		}

		VkStridedDeviceAddressRegionKHR hitRegion = .();
		if (vkHit != null)
		{
			hitRegion.deviceAddress = GetBufferDeviceAddress(vkHit) + hitOffset;
			hitRegion.stride = hitStride;
			hitRegion.size = hitStride;
		}

		VkStridedDeviceAddressRegionKHR callableRegion = .(); // Empty - no callable shaders

		VulkanNative.vkCmdTraceRaysKHR(mCmdBuf, &raygenRegion, &missRegion, &hitRegion, &callableRegion,
			width, height, depth);
	}

	private uint64 GetBufferDeviceAddress(VulkanBuffer buffer)
	{
		VkBufferDeviceAddressInfo info = .();
		info.buffer = buffer.Handle;
		return VulkanNative.vkGetBufferDeviceAddress(mDevice.Handle, &info);
	}

	private static VkGeometryFlagsKHR ToVkGeometryFlags(GeometryFlags flags)
	{
		VkGeometryFlagsKHR vkFlags = .None;
		if (flags.HasFlag(.Opaque))
			vkFlags |= .VK_GEOMETRY_OPAQUE_BIT_KHR;
		if (flags.HasFlag(.NoDuplicateAnyHitInvocation))
			vkFlags |= .VK_GEOMETRY_NO_DUPLICATE_ANY_HIT_INVOCATION_BIT_KHR;
		return vkFlags;
	}

	public ICommandBuffer Finish()
	{
		VulkanNative.vkEndCommandBuffer(mCmdBuf);
		let cb = new VulkanCommandBuffer(mCmdBuf);
		mPool.TrackCommandBuffer(cb);
		return cb;
	}

	public VkCommandBuffer Handle => mCmdBuf;
}
