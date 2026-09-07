using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// A queue that completes work the instant it is submitted.
///
/// Signalling the fence in Submit is the important part: a caller that submits and then
/// waits is the normal shape, and a queue that never signalled would hang every headless
/// test rather than running them.
class NullQueue : IQueue
{
	private NullTransferBatch mTransferBatch = new .() ~ delete _;
	private QueueType mQueueType = .Graphics;

	public QueueType QueueType => mQueueType;

	public void Initialize(QueueType queueType) => mQueueType = queueType;

	public void Submit(Span<ICommandBuffer> commandBuffers) {}

	public void Submit(Span<ICommandBuffer> commandBuffers, IFence signalFence,
		uint64 signalValue)
	{
		if (let fence = signalFence as NullFence)
			fence.Signal(signalValue);
	}

	/// The waits are ignored rather than honoured: nothing here runs asynchronously, so
	/// everything they could wait for has already happened.
	public void Submit(Span<ICommandBuffer> commandBuffers, Span<IFence> waitFences,
		Span<uint64> waitValues, IFence signalFence, uint64 signalValue)
	{
		if (let fence = signalFence as NullFence)
			fence.Signal(signalValue);
	}

	public void WaitIdle() {}

	public Result<ITransferBatch> CreateTransferBatch() => .Ok(mTransferBatch);

	/// The queue owns the batch, so this only releases the caller's handle.
	public void DestroyTransferBatch(ref ITransferBatch batch) => batch = null;

	/// One nanosecond per tick, so a timestamp difference reads directly as nanoseconds.
	public float TimestampPeriod() => 1.0f;
}
