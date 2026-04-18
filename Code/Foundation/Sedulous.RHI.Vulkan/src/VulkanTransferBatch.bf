namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of ITransferBatch.
class VulkanTransferBatch : ITransferBatch
{
	private VulkanDevice mDevice;
	private VulkanQueue mQueue;
	private VkCommandPool mCmdPool;

	// Staging buffer management
	private VulkanBuffer mStagingBuffer;
	private uint64 mStagingOffset;
	private uint64 mStagingSize;

	private struct BufferCopy
	{
		public IBuffer Dst;
		public uint64 DstOffset;
		public uint64 StagingOffset;
		public uint64 Size;
	}

	private struct TextureCopy
	{
		public ITexture Dst;
		public uint64 StagingOffset;
		public uint32 MipLevel;
		public uint32 ArrayLayer;
		public Extent3D Extent;
		public TextureDataLayout DataLayout;
	}

	private List<BufferCopy> mBufferCopies = new .() ~ delete _;
	private List<TextureCopy> mTextureCopies = new .() ~ delete _;

	// Track async submit so Destroy() can wait for completion
	private VulkanFence mAsyncFence;
	private uint64 mAsyncSignalValue;

	public this(VulkanDevice device, VulkanQueue queue)
	{
		mDevice = device;
		mQueue = queue;
	}

	private Result<void> EnsureStagingBuffer(uint64 requiredSize)
	{
		if (mStagingBuffer != null && mStagingSize >= requiredSize)
			return .Ok;

		// Grow: allocate new buffer, copy existing data, then free old
		let newSize = Math.Max(requiredSize, Math.Max(mStagingSize * 2, 4 * 1024 * 1024));
		BufferDesc desc = .();
		desc.Size = newSize;
		desc.Usage = .CopySrc;
		desc.Memory = .CpuToGpu;
		desc.Label = "TransferBatch Staging";

		VulkanBuffer newBuffer = null;
		if (mDevice.CreateBuffer(desc) case .Ok(let buf))
			newBuffer = buf as VulkanBuffer;
		else
			return .Err;

		// Copy existing data from old buffer to new buffer
		if (mStagingBuffer != null && mStagingOffset > 0)
		{
			void* oldPtr = mStagingBuffer.Map();
			void* newPtr = newBuffer.Map();
			if (oldPtr != null && newPtr != null)
				Internal.MemCpy(newPtr, oldPtr, (int)mStagingOffset);
		}

		// Free old
		if (mStagingBuffer != null)
		{
			IBuffer oldBuf = mStagingBuffer;
			mDevice.DestroyBuffer(ref oldBuf);
		}

		mStagingBuffer = newBuffer;
		mStagingSize = newSize;
		return .Ok;
	}

	public void WriteBuffer(IBuffer dst, uint64 dstOffset, Span<uint8> data)
	{
		uint64 needed = mStagingOffset + (uint64)data.Length;
		if (EnsureStagingBuffer(needed) case .Err)
		{
			System.Diagnostics.Debug.WriteLine("VulkanTransferBatch.WriteBuffer: EnsureStagingBuffer failed");
			return;
		}

		void* mapped = mStagingBuffer.Map();
		if (mapped == null)
		{
			System.Diagnostics.Debug.WriteLine("VulkanTransferBatch.WriteBuffer: Map() returned null");
			return;
		}
		Internal.MemCpy((uint8*)mapped + mStagingOffset, data.Ptr, data.Length);

		mBufferCopies.Add(.() {
			Dst = dst,
			DstOffset = dstOffset,
			StagingOffset = mStagingOffset,
			Size = (uint64)data.Length
		});
		mStagingOffset += (uint64)data.Length;
		mStagingOffset = (mStagingOffset + 15) & ~(uint64)15;
	}

	public void WriteTexture(ITexture dst, Span<uint8> data,
		TextureDataLayout dataLayout, Extent3D extent,
		uint32 mipLevel = 0, uint32 arrayLayer = 0)
	{
		uint64 needed = mStagingOffset + (uint64)data.Length;
		if (EnsureStagingBuffer(needed) case .Err)
		{
			System.Diagnostics.Debug.WriteLine("VulkanTransferBatch.WriteTexture: EnsureStagingBuffer failed");
			return;
		}

		void* mapped = mStagingBuffer.Map();
		if (mapped == null)
		{
			System.Diagnostics.Debug.WriteLine("VulkanTransferBatch.WriteTexture: Map() returned null");
			return;
		}
		Internal.MemCpy((uint8*)mapped + mStagingOffset, data.Ptr, data.Length);

		mTextureCopies.Add(.() {
			Dst = dst,
			StagingOffset = mStagingOffset,
			MipLevel = mipLevel,
			ArrayLayer = arrayLayer,
			Extent = extent,
			DataLayout = dataLayout
		});
		mStagingOffset += (uint64)data.Length;
		mStagingOffset = (mStagingOffset + 15) & ~(uint64)15;
	}

	public Result<void> Submit()
	{
		if (mBufferCopies.Count == 0 && mTextureCopies.Count == 0)
		{
			System.Diagnostics.Debug.WriteLine("VulkanTransferBatch.Submit: nothing to submit (0 buffer copies, 0 texture copies)");
			return .Ok;
		}

		System.Diagnostics.Debug.WriteLine(scope $"VulkanTransferBatch.Submit: {mBufferCopies.Count} buffer copies, {mTextureCopies.Count} texture copies, staging offset={mStagingOffset}");

		var cmdBuf = RecordCommands();
		if (cmdBuf == .Null)
		{
			System.Diagnostics.Debug.WriteLine("VulkanTransferBatch.Submit: RecordCommands failed");
			return .Err;
		}

		VkSubmitInfo submitInfo = .();
		submitInfo.commandBufferCount = 1;
		submitInfo.pCommandBuffers = &cmdBuf;

		let result = VulkanNative.vkQueueSubmit(mQueue.Handle, 1, &submitInfo, .Null);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanTransferBatch.Submit: vkQueueSubmit failed ({result})");
			return .Err;
		}

		VulkanNative.vkQueueWaitIdle(mQueue.Handle);

		CleanupCmdPool();
		return .Ok;
	}

	public Result<void> SubmitAsync(IFence fence, uint64 signalValue)
	{
		if (mBufferCopies.Count == 0 && mTextureCopies.Count == 0)
			return .Ok;

		var cmdBuf = RecordCommands();
		if (cmdBuf == .Null) return .Err;

		// Submit with timeline semaphore signal
		if (let vkFence = fence as VulkanFence)
		{
			var semaphore = vkFence.Handle;
			var signal = signalValue;

			VkTimelineSemaphoreSubmitInfo timelineInfo = .();
			timelineInfo.signalSemaphoreValueCount = 1;
			timelineInfo.pSignalSemaphoreValues = &signal;

			VkSubmitInfo submitInfo = .();
			submitInfo.pNext = &timelineInfo;
			submitInfo.commandBufferCount = 1;
			submitInfo.pCommandBuffers = &cmdBuf;
			submitInfo.signalSemaphoreCount = 1;
			submitInfo.pSignalSemaphores = &semaphore;

			VulkanNative.vkQueueSubmit(mQueue.Handle, 1, &submitInfo, .Null);

			// Track so Destroy() can wait for completion
			mAsyncFence = vkFence;
			mAsyncSignalValue = signalValue;
		}

		return .Ok;
	}

	private VkCommandBuffer RecordCommands()
	{
		// Create temporary command pool if needed
		if (mCmdPool.Handle == 0)
		{
			VkCommandPoolCreateInfo poolInfo = .();
			poolInfo.flags = .VK_COMMAND_POOL_CREATE_TRANSIENT_BIT;
			poolInfo.queueFamilyIndex = mQueue.FamilyIndex;
			let poolResult = VulkanNative.vkCreateCommandPool(mDevice.Handle, &poolInfo, null, &mCmdPool);
			if (poolResult != .VK_SUCCESS)
			{
				System.Diagnostics.Debug.WriteLine(scope $"VulkanTransferBatch.RecordCommands: vkCreateCommandPool failed ({poolResult})");
				return .Null;
			}
		}

		VkCommandBufferAllocateInfo allocInfo = .();
		allocInfo.commandPool = mCmdPool;
		allocInfo.level = .VK_COMMAND_BUFFER_LEVEL_PRIMARY;
		allocInfo.commandBufferCount = 1;

		VkCommandBuffer cmdBuf = default;
		let allocResult = VulkanNative.vkAllocateCommandBuffers(mDevice.Handle, &allocInfo, &cmdBuf);
		if (allocResult != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanTransferBatch.RecordCommands: vkAllocateCommandBuffers failed ({allocResult})");
			return .Null;
		}

		VkCommandBufferBeginInfo beginInfo = .();
		beginInfo.flags = .VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
		VulkanNative.vkBeginCommandBuffer(cmdBuf, &beginInfo);

		// Record buffer copies
		for (let copy in mBufferCopies)
		{
			if (let vkDst = copy.Dst as VulkanBuffer)
			{
				VkBufferCopy region = .();
				region.srcOffset = copy.StagingOffset;
				region.dstOffset = copy.DstOffset;
				region.size = copy.Size;
				VulkanNative.vkCmdCopyBuffer(cmdBuf, mStagingBuffer.Handle, vkDst.Handle, 1, &region);
			}
		}

		// Record texture copies with layout transitions
		for (let copy in mTextureCopies)
		{
			if (let vkDst = copy.Dst as VulkanTexture)
			{
				let aspectMask = VulkanConversions.GetAspectMask(vkDst.Desc.Format);

				// Transition UNDEFINED -> TRANSFER_DST_OPTIMAL
				VkImageMemoryBarrier preCopyBarrier = .();
				preCopyBarrier.srcAccessMask = .VK_ACCESS_NONE;
				preCopyBarrier.dstAccessMask = .VK_ACCESS_TRANSFER_WRITE_BIT;
				preCopyBarrier.oldLayout = .VK_IMAGE_LAYOUT_UNDEFINED;
				preCopyBarrier.newLayout = .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
				preCopyBarrier.srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
				preCopyBarrier.dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
				preCopyBarrier.image = vkDst.Handle;
				preCopyBarrier.subresourceRange.aspectMask = aspectMask;
				preCopyBarrier.subresourceRange.baseMipLevel = copy.MipLevel;
				preCopyBarrier.subresourceRange.levelCount = 1;
				preCopyBarrier.subresourceRange.baseArrayLayer = copy.ArrayLayer;
				preCopyBarrier.subresourceRange.layerCount = 1;

				VulkanNative.vkCmdPipelineBarrier(cmdBuf,
					.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, .VK_PIPELINE_STAGE_TRANSFER_BIT,
					.None, 0, null, 0, null, 1, &preCopyBarrier);

				// Copy
				VkBufferImageCopy region = .();
				region.bufferOffset = copy.StagingOffset;
				region.bufferRowLength = 0;
				region.bufferImageHeight = 0;
				region.imageSubresource.aspectMask = aspectMask;
				region.imageSubresource.mipLevel = copy.MipLevel;
				region.imageSubresource.baseArrayLayer = copy.ArrayLayer;
				region.imageSubresource.layerCount = 1;
				region.imageExtent.width = copy.Extent.Width;
				region.imageExtent.height = copy.Extent.Height;
				region.imageExtent.depth = copy.Extent.Depth;

				VulkanNative.vkCmdCopyBufferToImage(cmdBuf, mStagingBuffer.Handle, vkDst.Handle,
					.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &region);

				// Transition TRANSFER_DST_OPTIMAL -> SHADER_READ_ONLY_OPTIMAL
				VkImageMemoryBarrier postCopyBarrier = .();
				postCopyBarrier.srcAccessMask = .VK_ACCESS_TRANSFER_WRITE_BIT;
				postCopyBarrier.dstAccessMask = .VK_ACCESS_SHADER_READ_BIT;
				postCopyBarrier.oldLayout = .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
				postCopyBarrier.newLayout = .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
				postCopyBarrier.srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
				postCopyBarrier.dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
				postCopyBarrier.image = vkDst.Handle;
				postCopyBarrier.subresourceRange = preCopyBarrier.subresourceRange;

				VulkanNative.vkCmdPipelineBarrier(cmdBuf,
					.VK_PIPELINE_STAGE_TRANSFER_BIT, .VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT,
					.None, 0, null, 0, null, 1, &postCopyBarrier);
			}
		}

		VulkanNative.vkEndCommandBuffer(cmdBuf);
		return cmdBuf;
	}

	private void CleanupCmdPool()
	{
		if (mCmdPool.Handle != 0)
		{
			VulkanNative.vkResetCommandPool(mDevice.Handle, mCmdPool, .None);
		}
	}

	public void Reset()
	{
		mBufferCopies.Clear();
		mTextureCopies.Clear();
		mStagingOffset = 0;
		CleanupCmdPool();
	}

	public void Destroy()
	{
		// Wait for any in-flight async submit before destroying resources
		if (mAsyncFence != null)
		{
			mAsyncFence.Wait(mAsyncSignalValue);
			mAsyncFence = null;
		}

		if (mCmdPool.Handle != 0)
		{
			VulkanNative.vkDestroyCommandPool(mDevice.Handle, mCmdPool, null);
			mCmdPool = .Null;
		}
		if (mStagingBuffer != null)
		{
			IBuffer buf = mStagingBuffer;
			mDevice.DestroyBuffer(ref buf);
			mStagingBuffer = null;
		}
	}
}
