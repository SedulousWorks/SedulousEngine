using System;
using System.Collections;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// The command memory for one queue family.
///
/// ONE POOL PER THREAD per queue type: a Vulkan pool is not safe to record from
/// concurrently, which is why this is a separate object rather than living on the device.
///
/// It RECYCLES handles rather than freeing them. Resetting the pool invalidates every
/// buffer it produced, so the handles go back on a free list and the next encoder takes
/// one instead of allocating.
class VulkanCommandPool : ICommandPool
{
	private VkDevice mDevice;
	private VkCommandPool mPool;
	private VulkanDevice mOwner;
	private uint32 mFamilyIndex;

	private List<VkCommandBuffer> mFreeHandles = new .() ~ delete _;
	private List<VulkanCommandBuffer> mTrackedBuffers = new .() ~ DeleteContainerAndItems!(_);
	private List<VulkanCommandEncoder> mEncoders = new .() ~ DeleteContainerAndItems!(_);

	private List<VkCommandBuffer> mFreeSecondaries = new .() ~ delete _;
	private List<VkCommandBuffer> mLiveSecondaries = new .() ~ delete _;
	private List<VulkanRenderBundleEncoder> mBundleEncoders = new .() ~ DeleteContainerAndItems!(_);

	public VkCommandPool Handle => mPool;
	public VkDevice Device => mDevice;
	public VulkanDevice Owner => mOwner;

	public Result<void> Initialize(VkDevice device, VulkanAdapter adapter, QueueType queueType,
		VulkanDevice owner)
	{
		mDevice = device;
		mOwner = owner;

		let family = adapter.FindQueueFamily(queueType);
		if (family < 0)
			return .Err;
		mFamilyIndex = (uint32)family;

		VkCommandPoolCreateInfo createInfo = .();
		// Transient, because the buffers are recorded once and the pool is reset wholesale
		// rather than buffers being reset individually.
		createInfo.flags = .VK_COMMAND_POOL_CREATE_TRANSIENT_BIT;
		createInfo.queueFamilyIndex = mFamilyIndex;

		if (VulkanNative.vkCreateCommandPool(device, &createInfo, null, &mPool) != .VK_SUCCESS)
			return .Err;
		return .Ok;
	}

	/// A new encoder, already BEGUN so a caller can record straight into it.
	public Result<ICommandEncoder> CreateEncoder()
	{
		VkCommandBuffer commandBuffer = .Null;

		if (!mFreeHandles.IsEmpty)
		{
			commandBuffer = mFreeHandles.PopBack();
		}
		else
		{
			VkCommandBufferAllocateInfo allocateInfo = .();
			allocateInfo.commandPool = mPool;
			allocateInfo.level = .VK_COMMAND_BUFFER_LEVEL_PRIMARY;
			allocateInfo.commandBufferCount = 1;
			if (VulkanNative.vkAllocateCommandBuffers(mDevice, &allocateInfo, &commandBuffer)
				!= .VK_SUCCESS)
				return .Err;
		}

		VkCommandBufferBeginInfo beginInfo = .();
		// Recorded once and thrown away, which lets the driver skip preserving it for reuse.
		beginInfo.flags = .VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
		VulkanNative.vkBeginCommandBuffer(commandBuffer, &beginInfo);

		let encoder = new VulkanCommandEncoder(commandBuffer, mDevice, this);
		mEncoders.Add(encoder);
		return .Ok(encoder);
	}

	/// Releases the caller's handle. The POOL owns the encoder until it is reset, because
	/// the command buffer behind it is still the pool's.
	public void DestroyEncoder(ref ICommandEncoder encoder) => encoder = null;

	/// Recycles everything the pool produced.
	///
	/// Only safe once the GPU has finished the pool's last submission, which the caller
	/// establishes with a fence. Nothing here checks it: DX12 cannot reset an allocator
	/// whose list is still recording, and Vulkan cannot reset a pool whose buffers are
	/// still executing.
	public void Reset()
	{
		for (let buffer in mTrackedBuffers)
			mFreeHandles.Add(buffer.Handle);
		ClearAndDeleteItems!(mTrackedBuffers);
		ClearAndDeleteItems!(mEncoders);

		// Each bundle encoder frees the bundle it produced, so a bundle outlives its
		// encoder but not the pool's next reset.
		ClearAndDeleteItems!(mBundleEncoders);

		for (let secondary in mLiveSecondaries)
			mFreeSecondaries.Add(secondary);
		mLiveSecondaries.Clear();

		VulkanNative.vkResetCommandPool(mDevice, mPool, default);
	}

	/// Registers a finished buffer so its handle comes back on reset.
	public void TrackCommandBuffer(VulkanCommandBuffer buffer) => mTrackedBuffers.Add(buffer);

	/// A SECONDARY command buffer for a bundle, recycled the same way.
	public VkCommandBuffer AcquireSecondary()
	{
		VkCommandBuffer commandBuffer = .Null;

		if (!mFreeSecondaries.IsEmpty)
		{
			commandBuffer = mFreeSecondaries.PopBack();
		}
		else
		{
			VkCommandBufferAllocateInfo allocateInfo = .();
			allocateInfo.commandPool = mPool;
			allocateInfo.level = .VK_COMMAND_BUFFER_LEVEL_SECONDARY;
			allocateInfo.commandBufferCount = 1;
			if (VulkanNative.vkAllocateCommandBuffers(mDevice, &allocateInfo, &commandBuffer)
				!= .VK_SUCCESS)
				return .Null;
		}

		mLiveSecondaries.Add(commandBuffer);
		return commandBuffer;
	}

	/// Begins a bundle, declaring the attachment signature it may later be replayed into.
	public IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc)
	{
		let secondary = AcquireSecondary();
		if (secondary == .Null)
			return null;

		let encoder = new VulkanRenderBundleEncoder();
		if (encoder.Initialize(mDevice, secondary, desc) case .Err)
		{
			delete encoder;
			return null;
		}

		mBundleEncoders.Add(encoder);
		return encoder;
	}

	public void Cleanup()
	{
		ClearAndDeleteItems!(mTrackedBuffers);
		ClearAndDeleteItems!(mEncoders);
		ClearAndDeleteItems!(mBundleEncoders);
		mFreeHandles.Clear();
		mFreeSecondaries.Clear();
		mLiveSecondaries.Clear();

		if (mPool != .Null)
		{
			VulkanNative.vkDestroyCommandPool(mDevice, mPool, null);
			mPool = .Null;
		}
	}
}
