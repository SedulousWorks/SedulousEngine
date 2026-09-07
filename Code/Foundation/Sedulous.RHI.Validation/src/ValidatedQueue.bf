using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Watches submissions: what goes in, and whether the fence bookkeeping holds up.
class ValidatedQueue : IQueue
{
	private IQueue mInner;
	private ValidatedTransferBatch mTransferBatch ~ delete _;

	public this(IQueue inner) => mInner = inner;

	public IQueue Inner => mInner;
	public QueueType QueueType => mInner.QueueType;

	public void Submit(Span<ICommandBuffer> commandBuffers)
	{
		if (!CheckBuffers(commandBuffers))
			return;
		mInner.Submit(commandBuffers);
	}

	public void Submit(Span<ICommandBuffer> commandBuffers, IFence signalFence,
		uint64 signalValue)
	{
		if (!CheckBuffers(commandBuffers))
			return;
		if (signalFence == null)
		{
			ValidationLog.Error("Queue.Submit: signalFence is null");
			return;
		}
		mInner.Submit(commandBuffers, Unwrap(signalFence, signalValue), signalValue);
	}

	public void Submit(Span<ICommandBuffer> commandBuffers, Span<IFence> waitFences,
		Span<uint64> waitValues, IFence signalFence, uint64 signalValue)
	{
		if (!CheckBuffers(commandBuffers))
			return;

		// The two spans are positional, so a length mismatch silently pairs a fence with
		// the wrong value or reads past the end.
		if (waitFences.Length != waitValues.Length)
		{
			ValidationLog.Error("Queue.Submit: waitFences and waitValues counts do not match");
			return;
		}
		if (signalFence == null)
		{
			ValidationLog.Error("Queue.Submit: signalFence is null");
			return;
		}

		let unwrapped = scope IFence[waitFences.Length];
		for (int i < waitFences.Length)
		{
			if (let validated = waitFences[i] as ValidatedFence)
				unwrapped[i] = validated.Inner;
			else
				unwrapped[i] = waitFences[i];
		}

		mInner.Submit(commandBuffers, unwrapped, waitValues, Unwrap(signalFence, signalValue),
			signalValue);
	}

	public void WaitIdle() => mInner.WaitIdle();

	public Result<ITransferBatch> CreateTransferBatch()
	{
		if (mInner.CreateTransferBatch() case .Ok(let inner))
		{
			delete mTransferBatch;
			mTransferBatch = new ValidatedTransferBatch(inner);
			return .Ok(mTransferBatch);
		}
		return .Err;
	}

	public void DestroyTransferBatch(ref ITransferBatch batch)
	{
		if (let validated = batch as ValidatedTransferBatch)
		{
			var inner = validated.Inner;
			mInner.DestroyTransferBatch(ref inner);
			if (validated === mTransferBatch)
			{
				delete mTransferBatch;
				mTransferBatch = null;
			}
			batch = null;
			return;
		}
		mInner.DestroyTransferBatch(ref batch);
	}

	public float TimestampPeriod() => mInner.TimestampPeriod();

	/// A null command buffer is almost always a Finish that was never called, and a backend
	/// dereferences it without checking.
	private bool CheckBuffers(Span<ICommandBuffer> commandBuffers)
	{
		for (int i < commandBuffers.Length)
		{
			if (commandBuffers[i] == null)
			{
				ValidationLog.Error(scope $"Queue.Submit: commandBuffer[{i}] is null");
				return false;
			}
		}
		return true;
	}

	/// Records the signal against the wrapper's timeline and hands the inner fence down.
	private IFence Unwrap(IFence fence, uint64 signalValue)
	{
		if (let validated = fence as ValidatedFence)
		{
			validated.RecordSignal(signalValue);
			return validated.Inner;
		}
		return fence;
	}
}
