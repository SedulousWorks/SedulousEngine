using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// One Vulkan queue.
///
/// Submission is always a single VkSubmitInfo: the RHI's three overloads differ only in
/// what they wait on and signal, not in how the command buffers are batched.
class VulkanQueue : IQueue
{
	private VkQueue mQueue;
	private QueueType mType;
	private uint32 mFamilyIndex;
	private float mTimestampPeriod;
	private VulkanDevice mDevice;

	public this(VkQueue queue, QueueType type, uint32 familyIndex, float timestampPeriod,
		VulkanDevice device)
	{
		mQueue = queue;
		mType = type;
		mFamilyIndex = familyIndex;
		mTimestampPeriod = timestampPeriod;
		mDevice = device;
	}

	public VkQueue Handle => mQueue;
	public uint32 FamilyIndex => mFamilyIndex;
	public QueueType QueueType => mType;

	/// Nanoseconds per timestamp tick, straight from the device's limits, which is what
	/// turns a query difference into a duration.
	public float TimestampPeriod() => mTimestampPeriod;

	public void WaitIdle()
	{
		if (mQueue != .Null)
			VulkanNative.vkQueueWaitIdle(mQueue);
	}

	/// Submits with no synchronisation.
	public void Submit(Span<ICommandBuffer> commandBuffers)
	{
		if (commandBuffers.IsEmpty)
			return;

		let handles = scope VkCommandBuffer[commandBuffers.Length];
		let count = Unwrap(commandBuffers, handles);
		if (count == 0)
			return;

		VkSubmitInfo submitInfo = .();
		submitInfo.commandBufferCount = (uint32)count;
		submitInfo.pCommandBuffers = &handles[0];

		if (VulkanNative.vkQueueSubmit(mQueue, 1, &submitInfo, .Null) == .VK_ERROR_DEVICE_LOST)
			mDevice.MarkLost();
	}

	/// Submits and signals the fence's timeline when the work completes.
	///
	/// A swap chain acquire and present are interleaved HERE when one is pending, because
	/// this is the submission the presented image was rendered by: the acquire semaphore is
	/// waited on and the present semaphore signalled alongside the timeline value.
	public void Submit(Span<ICommandBuffer> commandBuffers, IFence signalFence,
		uint64 signalValue)
	{
		if (commandBuffers.IsEmpty)
			return;

		let fence = signalFence as VulkanFence;
		if (fence == null)
			return;

		let handles = scope VkCommandBuffer[commandBuffers.Length];
		let count = Unwrap(commandBuffers, handles);
		if (count == 0)
			return;

		VkSemaphore acquireSemaphore = .Null;
		VkSemaphore presentSemaphore = .Null;
		let hasSwapChainSync = mDevice.ConsumePendingSwapChainSync(ref acquireSemaphore,
			ref presentSemaphore);

		var waitSemaphores = VkSemaphore[1](acquireSemaphore);
		// The wait is on the colour attachment output stage: everything before it can run
		// before the image is even acquired.
		var waitStages = VkPipelineStageFlags[1](.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT);
		// A binary semaphore carries no value, so its slot is zero and ignored.
		var waitValues = uint64[1](0);

		var signalSemaphores = VkSemaphore[2](fence.Handle, presentSemaphore);
		var signalValues = uint64[2](signalValue, 0);

		VkTimelineSemaphoreSubmitInfo timelineInfo = .();
		timelineInfo.signalSemaphoreValueCount = hasSwapChainSync ? 2 : 1;
		timelineInfo.pSignalSemaphoreValues = &signalValues[0];
		timelineInfo.waitSemaphoreValueCount = hasSwapChainSync ? 1 : 0;
		timelineInfo.pWaitSemaphoreValues = &waitValues[0];

		VkSubmitInfo submitInfo = .();
		submitInfo.pNext = &timelineInfo;
		submitInfo.commandBufferCount = (uint32)count;
		submitInfo.pCommandBuffers = &handles[0];
		submitInfo.waitSemaphoreCount = hasSwapChainSync ? 1 : 0;
		submitInfo.pWaitSemaphores = hasSwapChainSync ? &waitSemaphores[0] : null;
		submitInfo.pWaitDstStageMask = hasSwapChainSync ? &waitStages[0] : null;
		submitInfo.signalSemaphoreCount = hasSwapChainSync ? 2 : 1;
		submitInfo.pSignalSemaphores = &signalSemaphores[0];

		if (VulkanNative.vkQueueSubmit(mQueue, 1, &submitInfo, .Null) == .VK_ERROR_DEVICE_LOST)
			mDevice.MarkLost();
	}

	/// Submits after each wait fence reaches its value, then signals.
	public void Submit(Span<ICommandBuffer> commandBuffers, Span<IFence> waitFences,
		Span<uint64> waitValues, IFence signalFence, uint64 signalValue)
	{
		if (commandBuffers.IsEmpty)
			return;
		if (waitFences.Length != waitValues.Length)
			return;

		let fence = signalFence as VulkanFence;
		if (fence == null)
			return;

		let handles = scope VkCommandBuffer[commandBuffers.Length];
		let count = Unwrap(commandBuffers, handles);
		if (count == 0)
			return;

		let waitCount = waitFences.Length;
		let waitSemaphores = scope VkSemaphore[waitCount == 0 ? 1 : waitCount];
		let values = scope uint64[waitCount == 0 ? 1 : waitCount];
		// Every wait is at the top of the pipe: the RHI does not express a finer stage, and
		// a broader wait is correct if pessimistic.
		let stages = scope VkPipelineStageFlags[waitCount == 0 ? 1 : waitCount];

		int actualWaits = 0;
		for (int i < waitCount)
		{
			if (let waitFence = waitFences[i] as VulkanFence)
			{
				waitSemaphores[actualWaits] = waitFence.Handle;
				values[actualWaits] = waitValues[i];
				stages[actualWaits] = .VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
				actualWaits++;
			}
		}

		var signalSemaphore = fence.Handle;
		var signalTarget = signalValue;

		VkTimelineSemaphoreSubmitInfo timelineInfo = .();
		timelineInfo.waitSemaphoreValueCount = (uint32)actualWaits;
		timelineInfo.pWaitSemaphoreValues = (actualWaits > 0) ? &values[0] : null;
		timelineInfo.signalSemaphoreValueCount = 1;
		timelineInfo.pSignalSemaphoreValues = &signalTarget;

		VkSubmitInfo submitInfo = .();
		submitInfo.pNext = &timelineInfo;
		submitInfo.commandBufferCount = (uint32)count;
		submitInfo.pCommandBuffers = &handles[0];
		submitInfo.waitSemaphoreCount = (uint32)actualWaits;
		submitInfo.pWaitSemaphores = (actualWaits > 0) ? &waitSemaphores[0] : null;
		submitInfo.pWaitDstStageMask = (actualWaits > 0) ? &stages[0] : null;
		submitInfo.signalSemaphoreCount = 1;
		submitInfo.pSignalSemaphores = &signalSemaphore;

		if (VulkanNative.vkQueueSubmit(mQueue, 1, &submitInfo, .Null) == .VK_ERROR_DEVICE_LOST)
			mDevice.MarkLost();
	}

	/// Pulls the Vulkan handles out, skipping anything that is not ours.
	private static int Unwrap(Span<ICommandBuffer> commandBuffers, Span<VkCommandBuffer> into)
	{
		int count = 0;
		for (int i < commandBuffers.Length)
		{
			if (let buffer = commandBuffers[i] as VulkanCommandBuffer)
			{
				into[count] = buffer.Handle;
				count++;
			}
		}
		return count;
	}

	public Result<ITransferBatch> CreateTransferBatch()
	{
		return .Ok(new VulkanTransferBatch(mDevice.Handle, mDevice.Adapter.PhysicalDevice,
			mQueue, mFamilyIndex));
	}

	public void DestroyTransferBatch(ref ITransferBatch batch)
	{
		if (let vulkanBatch = batch as VulkanTransferBatch)
		{
			vulkanBatch.Destroy();
			delete vulkanBatch;
		}
		batch = null;
	}
}
