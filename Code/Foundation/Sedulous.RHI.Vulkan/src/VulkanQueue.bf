using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// One Vulkan queue.
///
/// PARTIAL: the queue handle, its family and its timestamp period are ported; submission
/// and transfer batches land with the command buffer and transfer batch types.
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

	// ---- not yet ported ----

	public void Submit(Span<ICommandBuffer> commandBuffers) => NotYetPorted("Submit");

	public void Submit(Span<ICommandBuffer> commandBuffers, IFence signalFence,
		uint64 signalValue) => NotYetPorted("Submit");

	public void Submit(Span<ICommandBuffer> commandBuffers, Span<IFence> waitFences,
		Span<uint64> waitValues, IFence signalFence, uint64 signalValue)
		=> NotYetPorted("Submit");

	public Result<ITransferBatch> CreateTransferBatch()
	{
		NotYetPorted("CreateTransferBatch");
		return .Err;
	}

	public void DestroyTransferBatch(ref ITransferBatch batch) => batch = null;

	private static void NotYetPorted(StringView what)
		=> Console.Error.WriteLine(scope $"Sedulous.RHI.Vulkan: Queue.{what} is not ported yet");
}
