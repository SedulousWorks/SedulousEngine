using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// One Vulkan queue.
///
/// Submission is always a single VkSubmitInfo: the RHI's overloads differ only in what they
/// wait on and signal, not in how the command buffers are batched.
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

	/// The device holds the calibration entry point.
	public bool CalibrateTimestamps(out uint64 gpuTimestamp, out int64 cpuMicroseconds) =>
		mDevice.CalibrateTimestamps(out gpuTimestamp, out cpuMicroseconds);

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
	public void Submit(Span<ICommandBuffer> commandBuffers, IFence signalFence,
		uint64 signalValue)
	{
		SubmitSignalled(commandBuffers, .(), .(), signalFence, signalValue, .Null, .Null);
	}

	/// Submits after each wait fence reaches its value, then signals.
	public void Submit(Span<ICommandBuffer> commandBuffers, Span<IFence> waitFences,
		Span<uint64> waitValues, IFence signalFence, uint64 signalValue)
	{
		SubmitSignalled(commandBuffers, waitFences, waitValues, signalFence, signalValue, .Null, .Null);
	}

	/// The frame that renders the swap chain's acquired image: the image's acquire semaphore is
	/// waited on and its present semaphore signalled alongside the timeline value. Only this
	/// submit takes them, whatever else was submitted since the acquire.
	public void SubmitFrame(Span<ICommandBuffer> commandBuffers, ISwapChain swapChain, Span<IFence> waitFences,
		Span<uint64> waitValues, IFence signalFence, uint64 signalValue)
	{
		VkSemaphore acquireSemaphore = .Null;
		VkSemaphore presentSemaphore = .Null;
		if (let chain = swapChain as VulkanSwapChain)
		{
			acquireSemaphore = chain.CurrentAcquireSemaphore;
			presentSemaphore = chain.CurrentPresentSemaphore;
		}
		SubmitSignalled(commandBuffers, waitFences, waitValues, signalFence, signalValue, acquireSemaphore,
			presentSemaphore);
	}

	/// The fenced submits' one body: waits on `waitFences` (and `acquireSemaphore`, when a frame
	/// names its swap chain), signals `signalFence` (and `presentSemaphore`).
	private void SubmitSignalled(Span<ICommandBuffer> commandBuffers, Span<IFence> waitFences,
		Span<uint64> waitValues, IFence signalFence, uint64 signalValue, VkSemaphore acquireSemaphore,
		VkSemaphore presentSemaphore)
	{
		if (commandBuffers.IsEmpty)
			return;
		if (waitFences.Length != waitValues.Length)
			return;

		// A fenced submit without a fence is a contract violation (the validation layer
		// reports it; the plain overload is the unsignalled path).
		let fence = signalFence as VulkanFence;
		if (fence == null)
			return;

		let handles = scope VkCommandBuffer[commandBuffers.Length];
		let count = Unwrap(commandBuffers, handles);
		if (count == 0)
			return;

		let isFrame = acquireSemaphore != .Null;
		let waitCount = waitFences.Length + (isFrame ? 1 : 0);
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
		if (isFrame)
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
		let signalCount = (isFrame && (presentSemaphore != .Null)) ? 2 : 1;

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
		let batch = new VulkanTransferBatch(mDevice.Handle, mDevice.Adapter.PhysicalDevice,
			mQueue, mFamilyIndex);
		batch.Counters = mDevice.CounterBlock;
		return .Ok(batch);
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
