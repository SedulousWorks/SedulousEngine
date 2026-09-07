using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// Records GPU work into a primary command buffer.
class VulkanCommandEncoder : ICommandEncoder, IRayTracingEncoderExt
{
	private VkCommandBuffer mCommandBuffer;
	private VkDevice mDevice;
	private VulkanCommandPool mPool;

	private VulkanRenderPassEncoder mRenderPass ~ delete _;
	private VulkanComputePassEncoder mComputePass ~ delete _;
	private VulkanCommandBuffer mFinished;
	private VulkanRayTracingPipeline mRayTracingPipeline;

	public this(VkCommandBuffer commandBuffer, VkDevice device, VulkanCommandPool pool)
	{
		mCommandBuffer = commandBuffer;
		mDevice = device;
		mPool = pool;
		mRenderPass = new VulkanRenderPassEncoder(commandBuffer, device);
		mComputePass = new VulkanComputePassEncoder(commandBuffer);
	}

	public VkCommandBuffer Handle => mCommandBuffer;

	/// Begins a pass through DYNAMIC RENDERING: there is no render pass object and no
	/// framebuffer, only the attachments named here.
	public IRenderPassEncoder BeginRenderPass(RenderPassDesc desc)
	{
		var attachments = desc.ColorAttachments;
		let colorCount = attachments.Count;
		let colorInfos = scope VkRenderingAttachmentInfo[colorCount == 0 ? 1 : colorCount];

		for (int i < colorCount)
		{
			let attachment = attachments[i];
			let view = attachment.View as VulkanTextureView;

			colorInfos[i] = .();
			colorInfos[i].imageView = (view != null) ? view.Handle : .Null;
			colorInfos[i].imageLayout = .VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

			// Beginning a pass IMPLICITLY transitions the attachment, so the tracking is
			// updated to match or the next barrier would name the wrong old layout.
			if (view != null)
			{
				if (let texture = view.Texture as VulkanTexture)
				{
					texture.SetSubresourceLayout(view.Desc.BaseMipLevel, 1,
						view.Desc.BaseArrayLayer, 1, .VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL);
				}
			}

			colorInfos[i].loadOp = VulkanConversions.ToVkLoadOp(attachment.LoadOp);
			colorInfos[i].storeOp = VulkanConversions.ToVkStoreOp(attachment.StoreOp);
			colorInfos[i].clearValue.color.float32[0] = attachment.ClearValue.R;
			colorInfos[i].clearValue.color.float32[1] = attachment.ClearValue.G;
			colorInfos[i].clearValue.color.float32[2] = attachment.ClearValue.B;
			colorInfos[i].clearValue.color.float32[3] = attachment.ClearValue.A;

			if (let resolve = attachment.ResolveTarget as VulkanTextureView)
			{
				colorInfos[i].resolveMode = .VK_RESOLVE_MODE_AVERAGE_BIT;
				colorInfos[i].resolveImageView = resolve.Handle;
				colorInfos[i].resolveImageLayout = .VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
			}
		}

		// The render area comes from the first attachment's VIEW extent, which is the mip
		// it starts at rather than the texture's full size.
		uint32 areaWidth = 0, areaHeight = 0;
		if (colorCount > 0)
		{
			if (let view = attachments[0].View as VulkanTextureView)
			{
				areaWidth = view.Width;
				areaHeight = view.Height;
			}
		}
		else if (desc.DepthStencilAttachment.HasValue)
		{
			if (let view = desc.DepthStencilAttachment.Value.View as VulkanTextureView)
			{
				areaWidth = view.Width;
				areaHeight = view.Height;
			}
		}

		// Never zero: Vulkan requires a positive extent, and a pass with no attachments
		// would otherwise be rejected rather than simply drawing nothing.
		VkRenderingInfo renderingInfo = .();
		renderingInfo.renderArea = .()
			{
				offset = .() { x = 0, y = 0 },
				extent = .()
					{
						width = Math.Max((uint32)1, areaWidth),
						height = Math.Max((uint32)1, areaHeight)
					}
			};
		renderingInfo.layerCount = 1;
		renderingInfo.colorAttachmentCount = (uint32)colorCount;
		renderingInfo.pColorAttachments = &colorInfos[0];

		VkRenderingAttachmentInfo depthInfo = .();
		VkRenderingAttachmentInfo stencilInfo = .();

		if (desc.DepthStencilAttachment.HasValue)
		{
			let depth = desc.DepthStencilAttachment.Value;
			if (let view = depth.View as VulkanTextureView)
			{
				depthInfo.imageView = view.Handle;
				// A read only attachment takes the read only layout, which is what lets the
				// same texture be sampled while it is attached.
				depthInfo.imageLayout = depth.DepthReadOnly
					? .VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL
					: .VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

				if (let texture = view.Texture as VulkanTexture)
				{
					texture.SetSubresourceLayout(view.Desc.BaseMipLevel, 1,
						view.Desc.BaseArrayLayer, 1, depthInfo.imageLayout);
				}

				depthInfo.loadOp = VulkanConversions.ToVkLoadOp(depth.DepthLoadOp);
				depthInfo.storeOp = VulkanConversions.ToVkStoreOp(depth.DepthStoreOp);
				depthInfo.clearValue.depthStencil = .()
					{
						depth = depth.DepthClearValue,
						stencil = depth.StencilClearValue
					};
				renderingInfo.pDepthAttachment = &depthInfo;

				// The stencil aspect is a SEPARATE attachment pointing at the same view,
				// with its own load and store ops, which is how a pass clears one and keeps
				// the other.
				if (TextureFormats.HasStencil(view.Format))
				{
					stencilInfo = depthInfo;
					stencilInfo.loadOp = VulkanConversions.ToVkLoadOp(depth.StencilLoadOp);
					stencilInfo.storeOp = VulkanConversions.ToVkStoreOp(depth.StencilStoreOp);
					renderingInfo.pStencilAttachment = &stencilInfo;
				}
			}
		}

		// Vulkan must be told at BEGIN time that the body comes from secondaries; it cannot
		// be discovered when the bundles are executed.
		if (desc.Contents == .SecondaryCommandBuffers)
			renderingInfo.flags |= .VK_RENDERING_CONTENTS_SECONDARY_COMMAND_BUFFERS_BIT;

		VulkanNative.vkCmdBeginRendering(mCommandBuffer, &renderingInfo);
		mRenderPass.Begin(mCommandBuffer);
		return mRenderPass;
	}

	/// A compute pass is not a Vulkan object, so this only resets what is bound.
	public IComputePassEncoder BeginComputePass(StringView label)
	{
		mComputePass.Begin(mCommandBuffer);
		return mComputePass;
	}

	/// Bundles are POOL scoped, so this needs no open encoder and delegates.
	public IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc)
		=> mPool.CreateRenderBundleEncoder(desc);

	/// Submits every barrier in the group as ONE dependency, which is what makes a group
	/// cheaper than the same barriers issued separately.
	public void Barrier(BarrierGroup group)
	{
		let memoryCount = group.MemoryBarriers.Length;
		let bufferCount = group.BufferBarriers.Length;
		let textureCount = group.TextureBarriers.Length;

		let memoryBarriers = scope VkMemoryBarrier2[memoryCount == 0 ? 1 : memoryCount];
		let bufferBarriers = scope VkBufferMemoryBarrier2[bufferCount == 0 ? 1 : bufferCount];
		let imageBarriers = scope VkImageMemoryBarrier2[textureCount == 0 ? 1 : textureCount];

		for (int i < memoryCount)
		{
			let barrier = group.MemoryBarriers[i];
			let src = VulkanBarrierHelper.GetStageAccess(barrier.OldState);
			let dst = VulkanBarrierHelper.GetStageAccess(barrier.NewState);
			memoryBarriers[i] = .();
			memoryBarriers[i].srcStageMask = (uint64)src.StageMask;
			memoryBarriers[i].srcAccessMask = (uint64)src.AccessMask;
			memoryBarriers[i].dstStageMask = (uint64)dst.StageMask;
			memoryBarriers[i].dstAccessMask = (uint64)dst.AccessMask;
		}

		for (int i < bufferCount)
		{
			let barrier = group.BufferBarriers[i];
			let src = VulkanBarrierHelper.GetStageAccess(barrier.OldState);
			let dst = VulkanBarrierHelper.GetStageAccess(barrier.NewState);
			bufferBarriers[i] = .();
			bufferBarriers[i].srcStageMask = (uint64)src.StageMask;
			bufferBarriers[i].srcAccessMask = (uint64)src.AccessMask;
			bufferBarriers[i].dstStageMask = (uint64)dst.StageMask;
			bufferBarriers[i].dstAccessMask = (uint64)dst.AccessMask;
			// Not a queue transfer, which is a separate concern the RHI does not express.
			bufferBarriers[i].srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
			bufferBarriers[i].dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
			if (let buffer = barrier.Buffer as VulkanBuffer)
				bufferBarriers[i].buffer = buffer.Handle;
			bufferBarriers[i].offset = barrier.Offset;
			bufferBarriers[i].size = (barrier.Size == uint64.MaxValue)
				? VulkanNative.VK_WHOLE_SIZE : barrier.Size;
		}

		for (int i < textureCount)
		{
			let barrier = group.TextureBarriers[i];
			let src = VulkanBarrierHelper.GetStageAccess(barrier.OldState);
			let dst = VulkanBarrierHelper.GetStageAccess(barrier.NewState);
			let texture = barrier.Texture as VulkanTexture;
			let format = (texture != null) ? texture.Desc.Format : TextureFormat.Undefined;
			let newLayout = VulkanBarrierHelper.GetImageLayout(barrier.NewState, format);

			// The old layout comes from TRACKING rather than from the caller's stated old
			// state. The caller may not know what a previous pass left the image in, and a
			// mismatched old layout is undefined behaviour.
			VkImageLayout oldLayout;
			if (texture != null)
			{
				let wholeResource = (barrier.MipLevelCount == uint32.MaxValue)
					&& (barrier.ArrayLayerCount == uint32.MaxValue);
				oldLayout = wholeResource ? texture.CurrentLayout
					: texture.GetSubresourceLayout(barrier.BaseMipLevel, barrier.BaseArrayLayer);
				texture.SetSubresourceLayout(barrier.BaseMipLevel, barrier.MipLevelCount,
					barrier.BaseArrayLayer, barrier.ArrayLayerCount, newLayout);
			}
			else
			{
				oldLayout = VulkanBarrierHelper.GetImageLayout(barrier.OldState, format);
			}

			imageBarriers[i] = .();
			// Coming from UNDEFINED there is nothing to wait on: the contents are being
			// discarded, so naming a source access would order against writes that do not
			// matter.
			if (oldLayout == .VK_IMAGE_LAYOUT_UNDEFINED)
			{
				imageBarriers[i].srcStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT;
				imageBarriers[i].srcAccessMask = default;
			}
			else
			{
				imageBarriers[i].srcStageMask = (uint64)src.StageMask;
				imageBarriers[i].srcAccessMask = (uint64)src.AccessMask;
			}
			imageBarriers[i].dstStageMask = (uint64)dst.StageMask;
			imageBarriers[i].dstAccessMask = (uint64)dst.AccessMask;
			imageBarriers[i].oldLayout = oldLayout;
			imageBarriers[i].newLayout = newLayout;
			imageBarriers[i].srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
			imageBarriers[i].dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
			if (texture != null)
				imageBarriers[i].image = texture.Handle;

			imageBarriers[i].subresourceRange = .()
				{
					aspectMask = VulkanConversions.GetAspectMask(format),
					baseMipLevel = barrier.BaseMipLevel,
					levelCount = (barrier.MipLevelCount == uint32.MaxValue)
						? VulkanNative.VK_REMAINING_MIP_LEVELS : barrier.MipLevelCount,
					baseArrayLayer = barrier.BaseArrayLayer,
					layerCount = (barrier.ArrayLayerCount == uint32.MaxValue)
						? VulkanNative.VK_REMAINING_ARRAY_LAYERS : barrier.ArrayLayerCount
				};
		}

		VkDependencyInfo dependency = .();
		dependency.memoryBarrierCount = (uint32)memoryCount;
		dependency.pMemoryBarriers = (memoryCount > 0) ? &memoryBarriers[0] : null;
		dependency.bufferMemoryBarrierCount = (uint32)bufferCount;
		dependency.pBufferMemoryBarriers = (bufferCount > 0) ? &bufferBarriers[0] : null;
		dependency.imageMemoryBarrierCount = (uint32)textureCount;
		dependency.pImageMemoryBarriers = (textureCount > 0) ? &imageBarriers[0] : null;

		VulkanNative.vkCmdPipelineBarrier2(mCommandBuffer, &dependency);
	}

	public void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset,
		uint64 size)
	{
		let source = src as VulkanBuffer;
		let destination = dst as VulkanBuffer;
		if ((source == null) || (destination == null))
			return;

		VkBufferCopy region = .() { srcOffset = srcOffset, dstOffset = dstOffset, size = size };
		VulkanNative.vkCmdCopyBuffer(mCommandBuffer, source.Handle, destination.Handle, 1, &region);
	}

	public void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region)
	{
		let source = src as VulkanBuffer;
		let destination = dst as VulkanTexture;
		if ((source == null) || (destination == null))
			return;

		var copy = MakeBufferImageCopy(destination, region);
		VulkanNative.vkCmdCopyBufferToImage(mCommandBuffer, source.Handle, destination.Handle,
			.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &copy);
	}

	public void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region)
	{
		let source = src as VulkanTexture;
		let destination = dst as VulkanBuffer;
		if ((source == null) || (destination == null))
			return;

		var copy = MakeBufferImageCopy(source, region);
		VulkanNative.vkCmdCopyImageToBuffer(mCommandBuffer, source.Handle,
			.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, destination.Handle, 1, &copy);
	}

	private static VkBufferImageCopy MakeBufferImageCopy(VulkanTexture texture,
		BufferTextureCopyRegion region)
	{
		VkBufferImageCopy copy = default;
		copy.bufferOffset = region.BufferOffset;
		// In TEXELS, not bytes, so the caller's byte stride is converted. Zero means
		// tightly packed, which is the answer both when the caller gave no stride and when
		// the format is block compressed: a compressed format has no bytes per PIXEL to
		// divide by, and its data is packed per level anyway.
		let bytesPerPixel = TextureFormats.BytesPerPixel(texture.Desc.Format);
		copy.bufferRowLength = ((bytesPerPixel > 0) && (region.BytesPerRow > 0))
			? region.BytesPerRow / bytesPerPixel
			: 0;
		copy.bufferImageHeight = (bytesPerPixel > 0) ? region.RowsPerImage : 0;
		copy.imageSubresource = .()
			{
				aspectMask = VulkanConversions.GetAspectMask(texture.Desc.Format),
				mipLevel = region.TextureMipLevel,
				baseArrayLayer = region.TextureArrayLayer,
				layerCount = 1
			};
		copy.imageOffset = .()
			{
				x = (int32)region.TextureOrigin.X,
				y = (int32)region.TextureOrigin.Y,
				z = (int32)region.TextureOrigin.Z
			};
		copy.imageExtent = .()
			{
				width = region.TextureExtent.Width,
				height = region.TextureExtent.Height,
				depth = region.TextureExtent.Depth
			};
		return copy;
	}

	public void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region)
	{
		let source = src as VulkanTexture;
		let destination = dst as VulkanTexture;
		if ((source == null) || (destination == null))
			return;

		VkImageCopy copy = default;
		copy.srcSubresource = .()
			{
				aspectMask = VulkanConversions.GetAspectMask(source.Desc.Format),
				mipLevel = region.SrcMipLevel,
				baseArrayLayer = region.SrcArrayLayer,
				layerCount = 1
			};
		copy.dstSubresource = .()
			{
				aspectMask = VulkanConversions.GetAspectMask(destination.Desc.Format),
				mipLevel = region.DstMipLevel,
				baseArrayLayer = region.DstArrayLayer,
				layerCount = 1
			};
		copy.extent = .()
			{
				width = region.Extent.Width,
				height = region.Extent.Height,
				depth = region.Extent.Depth
			};

		VulkanNative.vkCmdCopyImage(mCommandBuffer, source.Handle,
			.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, destination.Handle,
			.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &copy);
	}

	/// A SCALED copy, so source and destination need not match in size.
	public void Blit(ITexture src, ITexture dst)
	{
		let source = src as VulkanTexture;
		let destination = dst as VulkanTexture;
		if ((source == null) || (destination == null))
			return;

		VkImageBlit blit = default;
		blit.srcSubresource = .()
			{
				aspectMask = VulkanConversions.GetAspectMask(source.Desc.Format),
				mipLevel = 0, baseArrayLayer = 0, layerCount = 1
			};
		blit.srcOffsets[1] = .()
			{
				x = (int32)source.Desc.Width,
				y = (int32)source.Desc.Height,
				z = (int32)source.Desc.Depth
			};
		blit.dstSubresource = .()
			{
				aspectMask = VulkanConversions.GetAspectMask(destination.Desc.Format),
				mipLevel = 0, baseArrayLayer = 0, layerCount = 1
			};
		blit.dstOffsets[1] = .()
			{
				x = (int32)destination.Desc.Width,
				y = (int32)destination.Desc.Height,
				z = (int32)destination.Desc.Depth
			};

		VulkanNative.vkCmdBlitImage(mCommandBuffer, source.Handle,
			.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, destination.Handle,
			.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &blit, .VK_FILTER_LINEAR);
	}

	/// Builds the mip chain by blitting each level from the one above.
	///
	/// Each level is transitioned to a transfer SOURCE once it has been written, so the
	/// next blit can read it. That is why this walks the chain rather than issuing one
	/// barrier for the whole texture.
	public void GenerateMipmaps(ITexture texture)
	{
		let target = texture as VulkanTexture;
		if (target == null)
			return;

		let mipLevels = target.Desc.MipLevelCount;
		if (mipLevels <= 1)
			return;

		let aspect = VulkanConversions.GetAspectMask(target.Desc.Format);
		var width = (int32)target.Desc.Width;
		var height = (int32)target.Desc.Height;

		for (uint32 level = 1; level < mipLevels; level++)
		{
			// The level above becomes the blit SOURCE.
			//
			// For the base level the old layout is UNDEFINED rather than the transfer
			// destination, because whatever the caller left it in is unknown: an upload
			// through the transfer batch leaves it shader readable, and naming the wrong
			// old layout is an error even though the contents are about to be read.
			// Discarding is safe here only because the base level is read, not written.
			VkImageMemoryBarrier2 toSource = .();
			toSource.srcStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
			toSource.srcAccessMask = (uint64)VkAccessFlags2.VK_ACCESS_2_TRANSFER_WRITE_BIT;
			toSource.dstStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
			toSource.dstAccessMask = (uint64)VkAccessFlags2.VK_ACCESS_2_TRANSFER_READ_BIT;
			toSource.oldLayout = (level == 1) ? .VK_IMAGE_LAYOUT_UNDEFINED
				: .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
			toSource.newLayout = .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
			toSource.srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
			toSource.dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
			toSource.image = target.Handle;
			toSource.subresourceRange = .()
				{
					aspectMask = aspect, baseMipLevel = level - 1, levelCount = 1,
					baseArrayLayer = 0, layerCount = target.Desc.ArrayLayerCount
				};

			// This level becomes the blit DESTINATION. It has never been written, so
			// UNDEFINED is both true and the cheapest thing to say.
			VkImageMemoryBarrier2 toDestination = .();
			toDestination.srcStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT;
			toDestination.srcAccessMask = 0;
			toDestination.dstStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
			toDestination.dstAccessMask = (uint64)VkAccessFlags2.VK_ACCESS_2_TRANSFER_WRITE_BIT;
			toDestination.oldLayout = .VK_IMAGE_LAYOUT_UNDEFINED;
			toDestination.newLayout = .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
			toDestination.srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
			toDestination.dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
			toDestination.image = target.Handle;
			toDestination.subresourceRange = .()
				{
					aspectMask = aspect, baseMipLevel = level, levelCount = 1,
					baseArrayLayer = 0, layerCount = target.Desc.ArrayLayerCount
				};

			VkImageMemoryBarrier2[2] barriers = .(toSource, toDestination);
			VkDependencyInfo dependency = .();
			dependency.imageMemoryBarrierCount = 2;
			dependency.pImageMemoryBarriers = &barriers[0];
			VulkanNative.vkCmdPipelineBarrier2(mCommandBuffer, &dependency);

			let nextWidth = Math.Max(1, width / 2);
			let nextHeight = Math.Max(1, height / 2);

			VkImageBlit blit = default;
			blit.srcSubresource = .()
				{
					aspectMask = aspect, mipLevel = level - 1,
					baseArrayLayer = 0, layerCount = target.Desc.ArrayLayerCount
				};
			blit.srcOffsets[1] = .() { x = width, y = height, z = 1 };
			blit.dstSubresource = .()
				{
					aspectMask = aspect, mipLevel = level,
					baseArrayLayer = 0, layerCount = target.Desc.ArrayLayerCount
				};
			blit.dstOffsets[1] = .() { x = nextWidth, y = nextHeight, z = 1 };

			VulkanNative.vkCmdBlitImage(mCommandBuffer, target.Handle,
				.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, target.Handle,
				.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &blit, .VK_FILTER_LINEAR);

			width = nextWidth;
			height = nextHeight;
		}

		// The last level was only ever written, so it is brought to match the rest. Leaving
		// it a destination would make the whole chain non uniform, and the caller's next
		// barrier over every level would then name the wrong old layout for exactly one.
		VkImageMemoryBarrier2 lastToSource = .();
		lastToSource.srcStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
		lastToSource.srcAccessMask = (uint64)VkAccessFlags2.VK_ACCESS_2_TRANSFER_WRITE_BIT;
		lastToSource.dstStageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
		lastToSource.dstAccessMask = (uint64)VkAccessFlags2.VK_ACCESS_2_TRANSFER_READ_BIT;
		lastToSource.oldLayout = .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
		lastToSource.newLayout = .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
		lastToSource.srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
		lastToSource.dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
		lastToSource.image = target.Handle;
		lastToSource.subresourceRange = .()
			{
				aspectMask = aspect, baseMipLevel = mipLevels - 1, levelCount = 1,
				baseArrayLayer = 0, layerCount = target.Desc.ArrayLayerCount
			};

		VkDependencyInfo lastDependency = .();
		lastDependency.imageMemoryBarrierCount = 1;
		lastDependency.pImageMemoryBarriers = &lastToSource;
		VulkanNative.vkCmdPipelineBarrier2(mCommandBuffer, &lastDependency);

		// EVERY level is now a transfer source, so the tracking is uniform again.
		target.CurrentLayout = .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
		target.SetSubresourceLayout(0, mipLevels, 0, uint32.MaxValue,
			.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL);
	}

	public void ResolveTexture(ITexture src, ITexture dst)
	{
		let source = src as VulkanTexture;
		let destination = dst as VulkanTexture;
		if ((source == null) || (destination == null))
			return;

		VkImageResolve resolve = default;
		resolve.srcSubresource = .()
			{
				aspectMask = VulkanConversions.GetAspectMask(source.Desc.Format),
				mipLevel = 0, baseArrayLayer = 0, layerCount = 1
			};
		resolve.dstSubresource = .()
			{
				aspectMask = VulkanConversions.GetAspectMask(destination.Desc.Format),
				mipLevel = 0, baseArrayLayer = 0, layerCount = 1
			};
		resolve.extent = .()
			{
				width = destination.Desc.Width,
				height = destination.Desc.Height,
				depth = 1
			};

		VulkanNative.vkCmdResolveImage(mCommandBuffer, source.Handle,
			.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, destination.Handle,
			.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &resolve);
	}

	/// Queries must be RESET before they are written, and only a command can do it.
	public void ResetQuerySet(IQuerySet querySet, uint32 first, uint32 count)
	{
		let query = querySet as VulkanQuerySet;
		if (query == null)
			return;
		VulkanNative.vkCmdResetQueryPool(mCommandBuffer, query.Handle, first, count);
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		let query = querySet as VulkanQuerySet;
		if (query == null)
			return;
		VulkanNative.vkCmdWriteTimestamp(mCommandBuffer, .VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,
			query.Handle, index);
	}

	/// Copies results into a buffer, WAITING for them: without that the destination holds
	/// whatever was there when the copy ran.
	public void ResolveQuerySet(IQuerySet querySet, uint32 first, uint32 count, IBuffer dst,
		uint64 dstOffset)
	{
		let query = querySet as VulkanQuerySet;
		let destination = dst as VulkanBuffer;
		if ((query == null) || (destination == null))
			return;

		VulkanNative.vkCmdCopyQueryPoolResults(mCommandBuffer, query.Handle, first, count,
			destination.Handle, dstOffset, sizeof(uint64),
			.VK_QUERY_RESULT_64_BIT | .VK_QUERY_RESULT_WAIT_BIT);
	}

	public void BeginDebugLabel(StringView label, float r, float g, float b, float a)
	{
		let text = scope String(label);
		VkDebugUtilsLabelEXT info = .();
		info.pLabelName = text.CStr();
		info.color = .(r, g, b, a);
		VulkanNative.vkCmdBeginDebugUtilsLabelEXT(mCommandBuffer, &info);
	}

	public void EndDebugLabel() => VulkanNative.vkCmdEndDebugUtilsLabelEXT(mCommandBuffer);

	public void InsertDebugLabel(StringView label, float r, float g, float b, float a)
	{
		let text = scope String(label);
		VkDebugUtilsLabelEXT info = .();
		info.pLabelName = text.CStr();
		info.color = .(r, g, b, a);
		VulkanNative.vkCmdInsertDebugUtilsLabelEXT(mCommandBuffer, &info);
	}

	/// Ends recording. The buffer is registered with the pool so its handle is recycled on
	/// the next reset rather than leaked.
	public ICommandBuffer Finish()
	{
		if (mFinished != null)
			return mFinished;

		if (VulkanNative.vkEndCommandBuffer(mCommandBuffer) != .VK_SUCCESS)
			return null;

		mFinished = new VulkanCommandBuffer(mCommandBuffer);
		mPool.TrackCommandBuffer(mFinished);
		return mFinished;
	}

	// ---- IRayTracingEncoderExt ----

	/// The address a build or a shader reaches this buffer by.
	///
	/// Zero when the buffer was not created for it, which the driver rejects rather than
	/// silently reading nothing.
	private uint64 GetBufferDeviceAddress(VulkanBuffer buffer)
	{
		if (buffer == null)
			return 0;
		VkBufferDeviceAddressInfo info = .();
		info.buffer = buffer.Handle;
		return VulkanNative.vkGetBufferDeviceAddress(mDevice, &info);
	}

	private static VkGeometryFlagsKHR ToVkGeometryFlags(GeometryFlags flags)
	{
		VkGeometryFlagsKHR result = default;
		if (flags.HasFlag(.Opaque))
			result |= .VK_GEOMETRY_OPAQUE_BIT_KHR;
		if (flags.HasFlag(.NoDuplicateAnyHitInvocation))
			result |= .VK_GEOMETRY_NO_DUPLICATE_ANY_HIT_INVOCATION_BIT_KHR;
		return result;
	}

	public void BuildBottomLevelAccelStruct(IAccelStruct dst, IBuffer scratchBuffer,
		uint64 scratchOffset, Span<AccelStructGeometryTriangles> triangles,
		Span<AccelStructGeometryAABBs> aabbs)
	{
		let accelStruct = dst as VulkanAccelStruct;
		let scratch = scratchBuffer as VulkanBuffer;
		if ((accelStruct == null) || (scratch == null))
			return;

		let total = triangles.Length + aabbs.Length;
		if (total == 0)
			return;

		let geometries = scope VkAccelerationStructureGeometryKHR[total];
		let ranges = scope VkAccelerationStructureBuildRangeInfoKHR[total];
		int count = 0;

		for (let triangle in triangles)
		{
			let vertexBuffer = triangle.VertexBuffer as VulkanBuffer;
			// A geometry with no vertices is SKIPPED rather than built empty, which keeps
			// the caller from having to filter its own list.
			if (vertexBuffer == null)
				continue;

			VkAccelerationStructureGeometryTrianglesDataKHR data = .();
			data.vertexFormat = VulkanConversions.ToVkVertexFormat(triangle.VertexFormat);
			data.vertexData.deviceAddress = GetBufferDeviceAddress(vertexBuffer)
				+ triangle.VertexOffset;
			data.vertexStride = triangle.VertexStride;
			// The highest INDEX, not the count, which is what bounds the driver's reads.
			data.maxVertex = triangle.VertexCount - 1;

			if (let indexBuffer = triangle.IndexBuffer as VulkanBuffer)
			{
				data.indexType = VulkanConversions.ToVkIndexType(triangle.IndexFormat);
				data.indexData.deviceAddress = GetBufferDeviceAddress(indexBuffer)
					+ triangle.IndexOffset;
			}
			else
			{
				data.indexType = .VK_INDEX_TYPE_NONE_KHR;
			}

			if (let transformBuffer = triangle.TransformBuffer as VulkanBuffer)
			{
				data.transformData.deviceAddress = GetBufferDeviceAddress(transformBuffer)
					+ triangle.TransformOffset;
			}

			geometries[count] = .();
			geometries[count].geometryType = .VK_GEOMETRY_TYPE_TRIANGLES_KHR;
			geometries[count].geometry.triangles = data;
			geometries[count].flags = ToVkGeometryFlags(triangle.Flags);

			ranges[count] = .();
			// Indexed geometry counts its INDICES, not its vertices, since the vertex
			// buffer is then shared between triangles.
			ranges[count].primitiveCount = (triangle.IndexBuffer != null)
				? triangle.IndexCount / 3
				: triangle.VertexCount / 3;
			count++;
		}

		for (let aabb in aabbs)
		{
			let aabbBuffer = aabb.AabbBuffer as VulkanBuffer;
			if (aabbBuffer == null)
				continue;

			VkAccelerationStructureGeometryAabbsDataKHR data = .();
			data.data.deviceAddress = GetBufferDeviceAddress(aabbBuffer) + aabb.Offset;
			data.stride = aabb.Stride;

			geometries[count] = .();
			geometries[count].geometryType = .VK_GEOMETRY_TYPE_AABBS_KHR;
			geometries[count].geometry.aabbs = data;
			geometries[count].flags = ToVkGeometryFlags(aabb.Flags);

			ranges[count] = .();
			ranges[count].primitiveCount = aabb.Count;
			count++;
		}

		if (count == 0)
			return;

		VkAccelerationStructureBuildGeometryInfoKHR buildInfo = .();
		buildInfo.type = .VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR;
		// Tracing is what these are built for, so the build pays for a faster traversal.
		buildInfo.flags = .VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_KHR;
		buildInfo.mode = .VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR;
		buildInfo.dstAccelerationStructure = accelStruct.Handle;
		buildInfo.geometryCount = (uint32)count;
		buildInfo.pGeometries = &geometries[0];
		buildInfo.scratchData.deviceAddress = GetBufferDeviceAddress(scratch) + scratchOffset;

		var rangePointer = &ranges[0];
		VulkanNative.vkCmdBuildAccelerationStructuresKHR(mCommandBuffer, 1, &buildInfo,
			&rangePointer);
	}

	public void BuildTopLevelAccelStruct(IAccelStruct dst, IBuffer scratchBuffer,
		uint64 scratchOffset, IBuffer instanceBuffer, uint64 instanceOffset,
		uint32 instanceCount)
	{
		let accelStruct = dst as VulkanAccelStruct;
		let scratch = scratchBuffer as VulkanBuffer;
		let instances = instanceBuffer as VulkanBuffer;
		if ((accelStruct == null) || (scratch == null) || (instances == null))
			return;

		VkAccelerationStructureGeometryInstancesDataKHR data = .();
		data.data.deviceAddress = GetBufferDeviceAddress(instances) + instanceOffset;

		VkAccelerationStructureGeometryKHR geometry = .();
		geometry.geometryType = .VK_GEOMETRY_TYPE_INSTANCES_KHR;
		geometry.geometry.instances = data;

		VkAccelerationStructureBuildGeometryInfoKHR buildInfo = .();
		buildInfo.type = .VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_KHR;
		buildInfo.flags = .VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_KHR;
		buildInfo.mode = .VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR;
		buildInfo.dstAccelerationStructure = accelStruct.Handle;
		// A top level structure is always exactly one geometry: the instance list.
		buildInfo.geometryCount = 1;
		buildInfo.pGeometries = &geometry;
		buildInfo.scratchData.deviceAddress = GetBufferDeviceAddress(scratch) + scratchOffset;

		VkAccelerationStructureBuildRangeInfoKHR range = .();
		range.primitiveCount = instanceCount;

		var rangePointer = &range;
		VulkanNative.vkCmdBuildAccelerationStructuresKHR(mCommandBuffer, 1, &buildInfo,
			&rangePointer);
	}

	public void SetRayTracingPipeline(IRayTracingPipeline pipeline)
	{
		mRayTracingPipeline = pipeline as VulkanRayTracingPipeline;
		if (mRayTracingPipeline != null)
		{
			VulkanNative.vkCmdBindPipeline(mCommandBuffer,
				.VK_PIPELINE_BIND_POINT_RAY_TRACING_KHR, mRayTracingPipeline.Handle);
		}
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets)
	{
		let bindGroup = group as VulkanBindGroup;
		if ((bindGroup == null) || (mRayTracingPipeline == null))
			return;
		let layout = mRayTracingPipeline.Layout as VulkanPipelineLayout;
		if (layout == null)
			return;

		var set = bindGroup.Handle;
		VulkanNative.vkCmdBindDescriptorSets(mCommandBuffer,
			.VK_PIPELINE_BIND_POINT_RAY_TRACING_KHR, layout.Handle, index, 1, &set,
			(uint32)dynamicOffsets.Length, dynamicOffsets.IsEmpty ? null : dynamicOffsets.Ptr);
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (mRayTracingPipeline == null)
			return;
		let layout = mRayTracingPipeline.Layout as VulkanPipelineLayout;
		if (layout == null)
			return;
		VulkanNative.vkCmdPushConstants(mCommandBuffer, layout.Handle,
			VulkanConversions.ToVkShaderStageFlags(stages), offset, size, data);
	}

	public void TraceRays(IBuffer raygenSBT, uint64 raygenOffset, uint64 raygenStride,
		IBuffer missSBT, uint64 missOffset, uint64 missStride,
		IBuffer hitSBT, uint64 hitOffset, uint64 hitStride,
		uint32 width, uint32 height, uint32 depth)
	{
		let raygen = raygenSBT as VulkanBuffer;
		// The raygen table is the only one a trace cannot do without.
		if (raygen == null)
			return;

		VkStridedDeviceAddressRegionKHR raygenRegion = .();
		raygenRegion.deviceAddress = GetBufferDeviceAddress(raygen) + raygenOffset;
		// Size equals stride: the raygen table holds exactly one record, and the spec
		// requires the two to match for it.
		raygenRegion.stride = raygenStride;
		raygenRegion.size = raygenStride;

		VkStridedDeviceAddressRegionKHR missRegion = .();
		if (let miss = missSBT as VulkanBuffer)
		{
			missRegion.deviceAddress = GetBufferDeviceAddress(miss) + missOffset;
			missRegion.stride = missStride;
			missRegion.size = missStride;
		}

		VkStridedDeviceAddressRegionKHR hitRegion = .();
		if (let hit = hitSBT as VulkanBuffer)
		{
			hitRegion.deviceAddress = GetBufferDeviceAddress(hit) + hitOffset;
			hitRegion.stride = hitStride;
			hitRegion.size = hitStride;
		}

		// Left empty: the RHI exposes no callable shaders, and a zeroed region is how
		// Vulkan is told there are none.
		VkStridedDeviceAddressRegionKHR callableRegion = .();

		VulkanNative.vkCmdTraceRaysKHR(mCommandBuffer, &raygenRegion, &missRegion, &hitRegion,
			&callableRegion, width, height, depth);
	}
}
