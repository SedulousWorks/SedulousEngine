namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of ICommandPool.
/// Uses TRANSIENT_BIT for short-lived command buffers and pools VkCommandBuffer
/// handles to avoid unbounded vkAllocateCommandBuffers growth.
class VulkanCommandPool : ICommandPool
{
	private VkCommandPool mPool;
	private VulkanDevice mDevice;
	private uint32 mQueueFamilyIndex;
	private List<VkCommandBuffer> mFreeHandles = new .() ~ delete _;
	private List<VulkanCommandBuffer> mCommandBuffers = new .() ~ delete _;

	public this() { }

	public Result<void> Init(VulkanDevice device, QueueType queueType)
	{
		mDevice = device;

		int32 familyIndex = device.Adapter.FindQueueFamily(queueType);
		if (familyIndex < 0)
		{
			System.Diagnostics.Debug.WriteLine("VulkanCommandPool: no suitable queue family found");
			return .Err;
		}
		mQueueFamilyIndex = (uint32)familyIndex;

		VkCommandPoolCreateInfo poolInfo = .();
		poolInfo.flags = .VK_COMMAND_POOL_CREATE_TRANSIENT_BIT;
		poolInfo.queueFamilyIndex = mQueueFamilyIndex;

		let result = VulkanNative.vkCreateCommandPool(device.Handle, &poolInfo, null, &mPool);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanCommandPool: vkCreateCommandPool failed ({result})");
			return .Err;
		}

		return .Ok;
	}

	public Result<ICommandEncoder> CreateEncoder()
	{
		VkCommandBuffer cmdBuf = .Null;

		if (mFreeHandles.Count > 0)
		{
			cmdBuf = mFreeHandles.PopBack();
		}
		else
		{
			VkCommandBufferAllocateInfo allocInfo = .();
			allocInfo.commandPool = mPool;
			allocInfo.level = .VK_COMMAND_BUFFER_LEVEL_PRIMARY;
			allocInfo.commandBufferCount = 1;

			let result = VulkanNative.vkAllocateCommandBuffers(mDevice.Handle, &allocInfo, &cmdBuf);
			if (result != .VK_SUCCESS)
			{
				System.Diagnostics.Debug.WriteLine(scope $"VulkanCommandPool: vkAllocateCommandBuffers failed ({result})");
				return .Err;
			}
		}

		VkCommandBufferBeginInfo beginInfo = .();
		beginInfo.flags = .VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
		VulkanNative.vkBeginCommandBuffer(cmdBuf, &beginInfo);

		return .Ok(new VulkanCommandEncoder(cmdBuf, mDevice, this));
	}

	public void DestroyEncoder(ref ICommandEncoder encoder)
	{
		if (encoder != null)
		{
			delete encoder;
			encoder = null;
		}
	}

	public void Reset()
	{
		// Reclaim handles for reuse, delete Beef wrappers
		for (let cb in mCommandBuffers)
		{
			mFreeHandles.Add(cb.Handle);
			delete cb;
		}
		mCommandBuffers.Clear();

		// Reset all buffers in one call (cheap with TRANSIENT_BIT)
		VulkanNative.vkResetCommandPool(mDevice.Handle, mPool, .None);
	}

	public void Cleanup(VulkanDevice device)
	{
		for (let cb in mCommandBuffers)
			delete cb;
		mCommandBuffers.Clear();
		mFreeHandles.Clear();

		if (mPool.Handle != 0)
		{
			VulkanNative.vkDestroyCommandPool(device.Handle, mPool, null);
			mPool = .Null;
		}
	}

	public VkCommandPool Handle => mPool;

	/// Called by VulkanCommandEncoder.Finish() to register a command buffer with this pool.
	public void TrackCommandBuffer(VulkanCommandBuffer cb)
	{
		mCommandBuffers.Add(cb);
	}
}

