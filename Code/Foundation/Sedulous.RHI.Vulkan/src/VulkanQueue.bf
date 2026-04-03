namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IQueue.
class VulkanQueue : IQueue
{
	private VkQueue mQueue;
	private QueueType mType;
	private uint32 mFamilyIndex;
	private float mTimestampPeriod;
	private VulkanDevice mDevice;

	public this(VkQueue queue, QueueType type, uint32 familyIndex, float timestampPeriod, VulkanDevice device)
	{
		mQueue = queue;
		mType = type;
		mFamilyIndex = familyIndex;
		mTimestampPeriod = timestampPeriod;
		mDevice = device;
	}

	public QueueType Type => mType;
	public float TimestampPeriod => mTimestampPeriod;

	public void Submit(Span<ICommandBuffer> commandBuffers)
	{
		if (commandBuffers.Length == 0) return;

		VkCommandBuffer[] cmdBufs = scope VkCommandBuffer[commandBuffers.Length];
		for (int i = 0; i < commandBuffers.Length; i++)
		{
			if (let vkCb = commandBuffers[i] as VulkanCommandBuffer)
				cmdBufs[i] = vkCb.Handle;
		}

		VkSubmitInfo submitInfo = .();
		submitInfo.commandBufferCount = (uint32)commandBuffers.Length;
		submitInfo.pCommandBuffers = cmdBufs.CArray();

		VulkanNative.vkQueueSubmit(mQueue, 1, &submitInfo, .Null);
	}

	public void Submit(Span<ICommandBuffer> commandBuffers, IFence fence, uint64 signalValue)
	{
		if (commandBuffers.Length == 0) return;

		VkCommandBuffer[] cmdBufs = scope VkCommandBuffer[commandBuffers.Length];
		for (int i = 0; i < commandBuffers.Length; i++)
		{
			if (let vkCb = commandBuffers[i] as VulkanCommandBuffer)
				cmdBufs[i] = vkCb.Handle;
		}

		if (let vkFence = fence as VulkanFence)
		{
			// Check for pending swapchain binary semaphores
			VkSemaphore acquireSem = .Null;
			VkSemaphore presentSem = .Null;
			bool hasSwapChainSync = mDevice.ConsumePendingSwapChainSync(out acquireSem, out presentSem);

			// Build wait semaphores: imageAvailable (binary, if present)
			VkSemaphore[1] waitSemaphores = .(acquireSem);
			VkPipelineStageFlags[1] waitStages = .(.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT);
			uint64[1] waitValues = .(0); // Binary semaphores use value 0

			// Build signal semaphores: timeline fence + renderFinished (binary, if present)
			var timelineSem = vkFence.Handle;
			var signal = signalValue;

			VkSemaphore[2] signalSemaphores = .(timelineSem, presentSem);
			uint64[2] signalValues = .(signal, 0); // Binary semaphores use value 0

			VkTimelineSemaphoreSubmitInfo timelineInfo = .();
			timelineInfo.signalSemaphoreValueCount = hasSwapChainSync ? 2 : 1;
			timelineInfo.pSignalSemaphoreValues = &signalValues;
			timelineInfo.waitSemaphoreValueCount = hasSwapChainSync ? 1 : 0;
			timelineInfo.pWaitSemaphoreValues = &waitValues;

			VkSubmitInfo submitInfo = .();
			submitInfo.pNext = &timelineInfo;
			submitInfo.commandBufferCount = (uint32)commandBuffers.Length;
			submitInfo.pCommandBuffers = cmdBufs.CArray();
			submitInfo.signalSemaphoreCount = hasSwapChainSync ? 2 : 1;
			submitInfo.pSignalSemaphores = &signalSemaphores;

			if (hasSwapChainSync)
			{
				submitInfo.waitSemaphoreCount = 1;
				submitInfo.pWaitSemaphores = &waitSemaphores;
				submitInfo.pWaitDstStageMask = &waitStages;
			}

			VulkanNative.vkQueueSubmit(mQueue, 1, &submitInfo, .Null);
		}
	}

	public void Submit(
		Span<ICommandBuffer> commandBuffers,
		Span<IFence> waitFences,
		Span<uint64> waitValues,
		IFence signalFence,
		uint64 signalValue)
	{
		if (commandBuffers.Length == 0) return;

		VkCommandBuffer[] cmdBufs = scope VkCommandBuffer[commandBuffers.Length];
		for (int i = 0; i < commandBuffers.Length; i++)
		{
			if (let vkCb = commandBuffers[i] as VulkanCommandBuffer)
				cmdBufs[i] = vkCb.Handle;
		}

		// Wait semaphores
		VkSemaphore[] waitSemaphores = scope VkSemaphore[waitFences.Length];
		VkPipelineStageFlags[] waitStages = scope VkPipelineStageFlags[waitFences.Length];
		for (int i = 0; i < waitFences.Length; i++)
		{
			if (let vkF = waitFences[i] as VulkanFence)
				waitSemaphores[i] = vkF.Handle;
			waitStages[i] = .VK_PIPELINE_STAGE_ALL_COMMANDS_BIT;
		}

		VkTimelineSemaphoreSubmitInfo timelineInfo = .();
		timelineInfo.waitSemaphoreValueCount = (uint32)waitValues.Length;
		timelineInfo.pWaitSemaphoreValues = waitValues.Ptr;

		VkSubmitInfo submitInfo = .();
		submitInfo.pNext = &timelineInfo;
		submitInfo.commandBufferCount = (uint32)commandBuffers.Length;
		submitInfo.pCommandBuffers = cmdBufs.CArray();
		submitInfo.waitSemaphoreCount = (uint32)waitFences.Length;
		submitInfo.pWaitSemaphores = waitSemaphores.CArray();
		submitInfo.pWaitDstStageMask = waitStages.CArray();

		if (let vkSignal = signalFence as VulkanFence)
		{
			var semaphore = vkSignal.Handle;
			var signal = signalValue;
			timelineInfo.signalSemaphoreValueCount = 1;
			timelineInfo.pSignalSemaphoreValues = &signal;
			submitInfo.signalSemaphoreCount = 1;
			submitInfo.pSignalSemaphores = &semaphore;
		}

		VulkanNative.vkQueueSubmit(mQueue, 1, &submitInfo, .Null);
	}

	public void WaitIdle()
	{
		VulkanNative.vkQueueWaitIdle(mQueue);
	}

	public Result<ITransferBatch> CreateTransferBatch()
	{
		return .Ok(new VulkanTransferBatch(mDevice, this));
	}

	public void DestroyTransferBatch(ref ITransferBatch batch)
	{
		if (let vk = batch as VulkanTransferBatch) { vk.Destroy(); delete vk; }
		batch = null;
	}

	// --- Internal ---
	public VkQueue Handle => mQueue;
	public uint32 FamilyIndex => mFamilyIndex;
}
