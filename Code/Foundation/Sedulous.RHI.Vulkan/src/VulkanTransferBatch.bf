using System;
using System.Collections;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// Stages CPU writes in one host-visible buffer and copies them all in one submission.
///
/// The batch owns its staging buffer and its command pool rather than borrowing the
/// device's, because it is filled and submitted on its own schedule.
class VulkanTransferBatch : ITransferBatch
{
	/// A pending buffer write, recorded when the batch is submitted rather than when it is
	/// staged, so one command buffer carries them all.
	private struct BufferCopy
	{
		public VulkanBuffer Dst;
		public uint64 DstOffset;
		public uint64 StagingOffset;
		public uint64 Size;
	}

	private struct TextureCopy
	{
		public VulkanTexture Dst;
		public uint64 StagingOffset;
		public uint32 MipLevel;
		public uint32 ArrayLayer;
		public Extent3D Extent;
		public TextureDataLayout Layout;
	}

	/// Staging starts here and doubles: large enough that a typical batch never grows, small
	/// enough not to reserve host memory a small batch will not use.
	private const uint64 cInitialStagingSize = 4 * 1024 * 1024;
	/// Every staged write starts on this boundary, which keeps a copy's source aligned for
	/// the formats that require it.
	private const uint64 cWriteAlignment = 16;

	private VkDevice mDevice;
	private VkPhysicalDevice mPhysicalDevice;
	private VkQueue mQueue;
	private uint32 mQueueFamilyIndex;

	private VkCommandPool mCommandPool = .Null;
	private VkBuffer mStagingBuffer = .Null;
	private VkDeviceMemory mStagingMemory = .Null;
	private void* mStagingMapped = null;
	private uint64 mStagingOffset = 0;
	private uint64 mStagingSize = 0;

	private List<BufferCopy> mBufferCopies = new List<BufferCopy>() ~ delete _;
	private List<TextureCopy> mTextureCopies = new List<TextureCopy>() ~ delete _;

	/// Held so Destroy can wait for work already in flight before freeing the staging memory
	/// the GPU is still reading from.
	private VulkanFence mAsyncFence = null;
	private uint64 mAsyncValue = 0;

	public this(VkDevice device, VkPhysicalDevice physicalDevice, VkQueue queue,
		uint32 queueFamilyIndex)
	{
		mDevice = device;
		mPhysicalDevice = physicalDevice;
		mQueue = queue;
		mQueueFamilyIndex = queueFamilyIndex;
	}

	public void WriteBuffer(IBuffer dst, uint64 dstOffset, Span<uint8> data)
	{
		let buffer = dst as VulkanBuffer;
		if (buffer == null || data.IsEmpty)
			return;

		if (EnsureStagingBuffer(mStagingOffset + (uint64)data.Length) case .Err)
			return;
		if (mStagingMapped == null)
			return;

		Internal.MemCpy((uint8*)mStagingMapped + mStagingOffset, data.Ptr, data.Length);
		mBufferCopies.Add(.()
			{
				Dst = buffer,
				DstOffset = dstOffset,
				StagingOffset = mStagingOffset,
				Size = (uint64)data.Length
			});
		mStagingOffset = Align(mStagingOffset + (uint64)data.Length);
	}

	public void WriteTexture(ITexture dst, Span<uint8> data, TextureDataLayout layout,
		Extent3D extent, uint32 mipLevel = 0, uint32 arrayLayer = 0)
	{
		let texture = dst as VulkanTexture;
		if (texture == null || data.IsEmpty)
			return;

		if (EnsureStagingBuffer(mStagingOffset + (uint64)data.Length) case .Err)
			return;
		if (mStagingMapped == null)
			return;

		Internal.MemCpy((uint8*)mStagingMapped + mStagingOffset, data.Ptr, data.Length);
		mTextureCopies.Add(.()
			{
				Dst = texture,
				StagingOffset = mStagingOffset,
				MipLevel = mipLevel,
				ArrayLayer = arrayLayer,
				Extent = extent,
				Layout = layout
			});
		mStagingOffset = Align(mStagingOffset + (uint64)data.Length);
	}

	public Result<void> Submit()
	{
		if (mBufferCopies.IsEmpty && mTextureCopies.IsEmpty)
			return .Ok;

		VkCommandBuffer commandBuffer = RecordCommands();
		if (commandBuffer == .Null)
			return .Err;

		VkSubmitInfo submitInfo = .();
		submitInfo.commandBufferCount = 1;
		submitInfo.pCommandBuffers = &commandBuffer;
		if (VulkanNative.vkQueueSubmit(mQueue, 1, &submitInfo, .Null) != .VK_SUCCESS)
			return .Err;

		VulkanNative.vkQueueWaitIdle(mQueue);
		ResetCommandPool();
		return .Ok;
	}

	public Result<void> SubmitAsync(IFence fence, uint64 signalValue)
	{
		if (mBufferCopies.IsEmpty && mTextureCopies.IsEmpty)
			return .Ok;

		let vulkanFence = fence as VulkanFence;
		if (vulkanFence == null)
			return .Err;

		VkCommandBuffer commandBuffer = RecordCommands();
		if (commandBuffer == .Null)
			return .Err;

		var semaphore = vulkanFence.Handle;
		var target = signalValue;

		VkTimelineSemaphoreSubmitInfo timelineInfo = .();
		timelineInfo.signalSemaphoreValueCount = 1;
		timelineInfo.pSignalSemaphoreValues = &target;

		VkSubmitInfo submitInfo = .();
		submitInfo.pNext = &timelineInfo;
		submitInfo.commandBufferCount = 1;
		submitInfo.pCommandBuffers = &commandBuffer;
		submitInfo.signalSemaphoreCount = 1;
		submitInfo.pSignalSemaphores = &semaphore;

		if (VulkanNative.vkQueueSubmit(mQueue, 1, &submitInfo, .Null) != .VK_SUCCESS)
			return .Err;

		mAsyncFence = vulkanFence;
		mAsyncValue = signalValue;
		return .Ok;
	}

	public void Reset()
	{
		mBufferCopies.Clear();
		mTextureCopies.Clear();
		mStagingOffset = 0;
		ResetCommandPool();
	}

	public void Destroy()
	{
		// An async submission is still reading the staging buffer, so it has to complete
		// before any of this is freed.
		if (mAsyncFence != null)
		{
			mAsyncFence.Wait(mAsyncValue);
			mAsyncFence = null;
		}

		if (mCommandPool != .Null)
		{
			VulkanNative.vkDestroyCommandPool(mDevice, mCommandPool, null);
			mCommandPool = .Null;
		}
		if (mStagingMapped != null)
		{
			VulkanNative.vkUnmapMemory(mDevice, mStagingMemory);
			mStagingMapped = null;
		}
		if (mStagingMemory != .Null)
		{
			VulkanNative.vkFreeMemory(mDevice, mStagingMemory, null);
			mStagingMemory = .Null;
		}
		if (mStagingBuffer != .Null)
		{
			VulkanNative.vkDestroyBuffer(mDevice, mStagingBuffer, null);
			mStagingBuffer = .Null;
		}
	}

	/// Recycles the pool's buffers rather than freeing them, so a reused batch does not
	/// allocate a command buffer per submission.
	private void ResetCommandPool()
	{
		if (mCommandPool != .Null)
			VulkanNative.vkResetCommandPool(mDevice, mCommandPool, .None);
	}

	private static uint64 Align(uint64 offset)
		=> (offset + cWriteAlignment - 1) & ~(cWriteAlignment - 1);

	/// Grows the staging buffer to hold `required` bytes, carrying what is already staged
	/// across, because the writes that produced it have not been recorded yet.
	private Result<void> EnsureStagingBuffer(uint64 required)
	{
		if (mStagingBuffer != .Null && mStagingSize >= required)
			return .Ok;

		uint64 newSize = Math.Max(required, Math.Max(mStagingSize * 2, cInitialStagingSize));

		VkBufferCreateInfo createInfo = .();
		createInfo.size = newSize;
		createInfo.usage = .VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
		createInfo.sharingMode = .VK_SHARING_MODE_EXCLUSIVE;

		VkBuffer newBuffer = .Null;
		if (VulkanNative.vkCreateBuffer(mDevice, &createInfo, null, &newBuffer) != .VK_SUCCESS)
			return .Err;

		VkMemoryRequirements memoryRequirements = .();
		VulkanNative.vkGetBufferMemoryRequirements(mDevice, newBuffer, &memoryRequirements);

		let memoryType = FindHostVisibleMemoryType(memoryRequirements.memoryTypeBits);
		if (memoryType < 0)
		{
			VulkanNative.vkDestroyBuffer(mDevice, newBuffer, null);
			return .Err;
		}

		VkMemoryAllocateInfo allocateInfo = .();
		allocateInfo.allocationSize = memoryRequirements.size;
		allocateInfo.memoryTypeIndex = (uint32)memoryType;

		VkDeviceMemory newMemory = .Null;
		if (VulkanNative.vkAllocateMemory(mDevice, &allocateInfo, null, &newMemory) != .VK_SUCCESS)
		{
			VulkanNative.vkDestroyBuffer(mDevice, newBuffer, null);
			return .Err;
		}
		VulkanNative.vkBindBufferMemory(mDevice, newBuffer, newMemory, 0);

		void* newMapped = null;
		VulkanNative.vkMapMemory(mDevice, newMemory, 0, newSize, 0, &newMapped);

		if (mStagingMapped != null && mStagingOffset > 0 && newMapped != null)
			Internal.MemCpy(newMapped, mStagingMapped, (int)mStagingOffset);

		if (mStagingMapped != null)
			VulkanNative.vkUnmapMemory(mDevice, mStagingMemory);
		if (mStagingMemory != .Null)
			VulkanNative.vkFreeMemory(mDevice, mStagingMemory, null);
		if (mStagingBuffer != .Null)
			VulkanNative.vkDestroyBuffer(mDevice, mStagingBuffer, null);

		mStagingBuffer = newBuffer;
		mStagingMemory = newMemory;
		mStagingMapped = newMapped;
		mStagingSize = newSize;
		return .Ok;
	}

	/// Host visible AND host coherent, so a write is seen by the GPU without an explicit
	/// flush of the mapped range.
	private int32 FindHostVisibleMemoryType(uint32 typeBits)
	{
		VkPhysicalDeviceMemoryProperties properties = .();
		VulkanNative.vkGetPhysicalDeviceMemoryProperties(mPhysicalDevice, &properties);

		const VkMemoryPropertyFlags cWanted = .VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT
			| .VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;

		for (uint32 i = 0; i < properties.memoryTypeCount; ++i)
		{
			if ((typeBits & (1 << i)) == 0)
				continue;
			if ((properties.memoryTypes[i].propertyFlags & cWanted) == cWanted)
				return (int32)i;
		}
		return -1;
	}

	private VkCommandBuffer RecordCommands()
	{
		if (mCommandPool == .Null)
		{
			VkCommandPoolCreateInfo poolInfo = .();
			// Transient: every buffer from this pool is submitted once and then reset.
			poolInfo.flags = .VK_COMMAND_POOL_CREATE_TRANSIENT_BIT;
			poolInfo.queueFamilyIndex = mQueueFamilyIndex;
			if (VulkanNative.vkCreateCommandPool(mDevice, &poolInfo, null, &mCommandPool)
				!= .VK_SUCCESS)
				return .Null;
		}

		VkCommandBufferAllocateInfo allocateInfo = .();
		allocateInfo.commandPool = mCommandPool;
		allocateInfo.level = .VK_COMMAND_BUFFER_LEVEL_PRIMARY;
		allocateInfo.commandBufferCount = 1;

		VkCommandBuffer commandBuffer = .Null;
		if (VulkanNative.vkAllocateCommandBuffers(mDevice, &allocateInfo, &commandBuffer)
			!= .VK_SUCCESS)
			return .Null;

		VkCommandBufferBeginInfo beginInfo = .();
		beginInfo.flags = .VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
		VulkanNative.vkBeginCommandBuffer(commandBuffer, &beginInfo);

		for (let copy in mBufferCopies)
		{
			VkBufferCopy region = .();
			region.srcOffset = copy.StagingOffset;
			region.dstOffset = copy.DstOffset;
			region.size = copy.Size;
			VulkanNative.vkCmdCopyBuffer(commandBuffer, mStagingBuffer, copy.Dst.Handle, 1,
				&region);
		}

		for (let copy in mTextureCopies)
			RecordTextureCopy(commandBuffer, copy);

		VulkanNative.vkEndCommandBuffer(commandBuffer);
		return commandBuffer;
	}

	private void RecordTextureCopy(VkCommandBuffer commandBuffer, TextureCopy copy)
	{
		let texture = copy.Dst;
		let aspect = VulkanConversions.GetAspectMask(texture.Desc.Format);

		VkImageSubresourceRange range = .();
		range.aspectMask = aspect;
		range.baseMipLevel = copy.MipLevel;
		range.levelCount = 1;
		range.baseArrayLayer = copy.ArrayLayer;
		range.layerCount = 1;

		// UNDEFINED as the old layout discards whatever the subresource held, which is what
		// a full overwrite wants and what saves tracking the layout across the batch.
		VkImageMemoryBarrier before = .();
		before.dstAccessMask = .VK_ACCESS_TRANSFER_WRITE_BIT;
		before.oldLayout = .VK_IMAGE_LAYOUT_UNDEFINED;
		before.newLayout = .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
		before.srcQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
		before.dstQueueFamilyIndex = VulkanNative.VK_QUEUE_FAMILY_IGNORED;
		before.image = texture.Handle;
		before.subresourceRange = range;
		VulkanNative.vkCmdPipelineBarrier(commandBuffer, .VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
			.VK_PIPELINE_STAGE_TRANSFER_BIT, .None, 0, null, 0, null, 1, &before);

		VkBufferImageCopy region = .();
		// The layout's offset is where the image starts WITHIN the staged bytes, on top of
		// where the staging allocation itself begins.
		region.bufferOffset = copy.StagingOffset + copy.Layout.Offset;
		// In TEXELS, not bytes, and zero means tightly packed to the copy extent.
		region.bufferRowLength = RowLengthInTexels(copy);
		region.bufferImageHeight = HasTexelStride(copy.Dst.Desc.Format)
			? copy.Layout.RowsPerImage
			: 0;
		region.imageSubresource.aspectMask = aspect;
		region.imageSubresource.mipLevel = copy.MipLevel;
		region.imageSubresource.baseArrayLayer = copy.ArrayLayer;
		region.imageSubresource.layerCount = 1;
		region.imageExtent = .() { width = copy.Extent.Width, height = copy.Extent.Height,
			depth = copy.Extent.Depth };
		VulkanNative.vkCmdCopyBufferToImage(commandBuffer, mStagingBuffer, texture.Handle,
			.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &region);

		VkImageMemoryBarrier after = before;
		after.srcAccessMask = .VK_ACCESS_TRANSFER_WRITE_BIT;
		after.dstAccessMask = .VK_ACCESS_SHADER_READ_BIT;
		after.oldLayout = .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
		after.newLayout = .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		VulkanNative.vkCmdPipelineBarrier(commandBuffer, .VK_PIPELINE_STAGE_TRANSFER_BIT,
			.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, .None, 0, null, 0, null, 1, &after);

		// The batch leaves every uploaded subresource readable by a shader, so the tracked
		// layout has to say so or the next barrier transitions from the wrong one.
		texture.SetSubresourceLayout(copy.MipLevel, 1, copy.ArrayLayer, 1,
			.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
	}

	/// Converts the layout's byte stride to the texel stride Vulkan wants.
	///
	/// Zero means tightly packed, which is the answer in two cases: the caller gave no
	/// stride, and the format is block compressed. A compressed format has no bytes per
	/// PIXEL to divide by, and its data is uploaded tightly packed per level, which is the
	/// same rule the command encoder's buffer to texture copy applies.
	private static uint32 RowLengthInTexels(TextureCopy copy)
	{
		if (copy.Layout.BytesPerRow == 0)
			return 0;
		if (!HasTexelStride(copy.Dst.Desc.Format))
			return 0;
		return copy.Layout.BytesPerRow / TextureFormats.BytesPerPixel(copy.Dst.Desc.Format);
	}

	/// Whether a stride in this format can be expressed in texels at all.
	private static bool HasTexelStride(TextureFormat format)
		=> TextureFormats.BytesPerPixel(format) > 0;
}
