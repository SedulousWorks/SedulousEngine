namespace Sedulous.RHI;

using System;

/// A command queue for submitting work to the GPU.
/// Obtained from IDevice.GetQueue().
interface IQueue
{
	/// The type of this queue.
	QueueType Type { get; }

	/// Submits command buffers for execution.
	void Submit(Span<ICommandBuffer> commandBuffers);

	/// Submits a single command buffer for execution.
	void Submit(ICommandBuffer commandBuffer)
	{
		ICommandBuffer[1] bufs = .(commandBuffer);
		Submit(bufs);
	}

	/// Submits command buffers and signals a fence when work completes.
	void Submit(Span<ICommandBuffer> commandBuffers, IFence fence, uint64 signalValue);

	/// Submits with full synchronization:
	/// waits on fences before executing, signals a fence after completion.
	void Submit(
		Span<ICommandBuffer> commandBuffers,
		Span<IFence> waitFences,
		Span<uint64> waitValues,
		IFence signalFence,
		uint64 signalValue
	);

	/// Blocks until all submitted work on this queue has completed.
	void WaitIdle();

	/// Creates a transfer batch for batching multiple upload operations.
	Result<ITransferBatch> CreateTransferBatch();

	/// Destroys a transfer batch created from this queue.
	void DestroyTransferBatch(ref ITransferBatch batch);

	/// Timestamp period in nanoseconds. Multiply raw timestamps by this value.
	float TimestampPeriod { get; }
}
