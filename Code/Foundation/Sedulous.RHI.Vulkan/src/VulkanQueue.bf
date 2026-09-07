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
	/// Takes the swap chain's pending acquire and present semaphores, if this queue is the
	/// one they belong to.
	///
	/// AcquireNextImage latches them on the DEVICE, because the queue does not know a swap
	/// chain exists. They belong to the submission that renders the acquired image, which
	/// is a GRAPHICS submission: without the queue check whichever queue submitted first
	/// took them, so an async compute submit would wait on the acquire for nothing and
	/// signal "present" before the frame had been drawn.
	private bool TakeSwapChainSync(ref VkSemaphore acquire, ref VkSemaphore present)
	{
		if (mType != .Graphics)
			return false;
		return mDevice.ConsumePendingSwapChainSync(ref acquire, ref present);
	}

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
		let hasSwapChainSync = TakeSwapChainSync(ref acquireSemaphore, ref presentSemaphore);

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

		// This overload consumes the pending acquire too. DIVERGES from Raptor, where only
		// the two argument submit does. A sample whose only graphics submission of the
		// frame waits on another queue's fence, which is exactly what Sample017 does, then
		// has nobody wait on the acquire and nobody signal the present: the layers report
		// an unsignalled present semaphore and a presentable image modified without
		// waiting. What matters is the QUEUE, not which overload was reached for.
		VkSemaphore acquireSemaphore = .Null;
		VkSemaphore presentSemaphore = .Null;
		let hasSwapChainSync = TakeSwapChainSync(ref acquireSemaphore, ref presentSemaphore);

		let waitCount = waitFences.Length + (hasSwapChainSync ? 1 : 0);
		let waitSemaphores = scope VkSemaphore[waitCount == 0 ? 1 : waitCount];
		let values = scope uint64[waitCount == 0 ? 1 : waitCount];
		// Every fence wait is at the top of the pipe: the RHI does not express a finer
		// stage, and a broader wait is correct if pessimistic.
		let stages = scope VkPipelineStageFlags[waitCount == 0 ? 1 : waitCount];

		int actualWaits = 0;
		for (int i < waitFences.Length)
		{
			if (let waitFence = waitFences[i] as VulkanFence)
			{
				waitSemaphores[actualWaits] = waitFence.Handle;
				values[actualWaits] = waitValues[i];
				stages[actualWaits] = .VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
				actualWaits++;
			}
		}
		if (hasSwapChainSync)
		{
			waitSemaphores[actualWaits] = acquireSemaphore;
			// A binary semaphore carries no value, so its slot is zero and ignored.
			values[actualWaits] = 0;
			// Colour attachment output, not top of pipe: everything before it can run
			// before the image has even been acquired.
			stages[actualWaits] = .VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
			actualWaits++;
		}

		var signalSemaphores = VkSemaphore[2](fence.Handle, presentSemaphore);
		var signalValues = uint64[2](signalValue, 0);
		let signalCount = hasSwapChainSync ? 2 : 1;

		VkTimelineSemaphoreSubmitInfo timelineInfo = .();
		timelineInfo.waitSemaphoreValueCount = (uint32)actualWaits;
		timelineInfo.pWaitSemaphoreValues = (actualWaits > 0) ? &values[0] : null;
		timelineInfo.signalSemaphoreValueCount = (uint32)signalCount;
		timelineInfo.pSignalSemaphoreValues = &signalValues[0];

		VkSubmitInfo submitInfo = .();
		submitInfo.pNext = &timelineInfo;
		submitInfo.commandBufferCount = (uint32)count;
		submitInfo.pCommandBuffers = &handles[0];
		submitInfo.waitSemaphoreCount = (uint32)actualWaits;
		submitInfo.pWaitSemaphores = (actualWaits > 0) ? &waitSemaphores[0] : null;
		submitInfo.pWaitDstStageMask = (actualWaits > 0) ? &stages[0] : null;
		submitInfo.signalSemaphoreCount = (uint32)signalCount;
		submitInfo.pSignalSemaphores = &signalSemaphores[0];

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
