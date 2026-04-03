namespace Sedulous.RHI.Validation;

using System;
using Sedulous.RHI;

/// Validation wrapper for IQueue.
class ValidatedQueue : IQueue
{
	private IQueue mInner;
	private ValidatedDevice mDevice;

	public this(IQueue inner, ValidatedDevice device)
	{
		mInner = inner;
		mDevice = device;
	}

	public QueueType Type => mInner.Type;

	public void Submit(Span<ICommandBuffer> commandBuffers)
	{
		if (commandBuffers.IsEmpty)
		{
			ValidationLogger.Warn("Queue.Submit: submitting zero command buffers");
		}

		for (int i = 0; i < commandBuffers.Length; i++)
		{
			if (commandBuffers[i] == null)
			{
				let msg = scope String();
				msg.AppendF("Queue.Submit: command buffer at index {} is null", i);
				ValidationLogger.Error(msg);
				return;
			}
		}

		mInner.Submit(commandBuffers);
	}

	public void Submit(Span<ICommandBuffer> commandBuffers, IFence fence, uint64 signalValue)
	{
		if (fence == null)
		{
			ValidationLogger.Error("Queue.Submit: signal fence is null");
			return;
		}

		for (int i = 0; i < commandBuffers.Length; i++)
		{
			if (commandBuffers[i] == null)
			{
				let msg = scope String();
				msg.AppendF("Queue.Submit: command buffer at index {} is null", i);
				ValidationLogger.Error(msg);
				return;
			}
		}

		// Unwrap validated fence
		IFence innerFence = fence;
		if (let vf = fence as ValidatedFence)
		{
			vf.TrackSignal(signalValue);
			innerFence = vf.Inner;
		}

		mInner.Submit(commandBuffers, innerFence, signalValue);
	}

	public void Submit(
		Span<ICommandBuffer> commandBuffers,
		Span<IFence> waitFences,
		Span<uint64> waitValues,
		IFence signalFence,
		uint64 signalValue
	)
	{
		if (waitFences.Length != waitValues.Length)
		{
			ValidationLogger.Error("Queue.Submit: waitFences and waitValues length mismatch");
			return;
		}

		// Unwrap fences
		let innerWaitFences = scope IFence[waitFences.Length];
		for (int i = 0; i < waitFences.Length; i++)
		{
			if (waitFences[i] == null)
			{
				let msg = scope String();
				msg.AppendF("Queue.Submit: wait fence at index {} is null", i);
				ValidationLogger.Error(msg);
				return;
			}
			innerWaitFences[i] = (waitFences[i] is ValidatedFence) ?
				((ValidatedFence)waitFences[i]).Inner : waitFences[i];
		}

		IFence innerSignalFence = signalFence;
		if (signalFence != null)
		{
			if (let vf = signalFence as ValidatedFence)
			{
				vf.TrackSignal(signalValue);
				innerSignalFence = vf.Inner;
			}
		}

		mInner.Submit(commandBuffers, Span<IFence>(innerWaitFences), waitValues,
			innerSignalFence, signalValue);
	}

	public void WaitIdle()
	{
		mInner.WaitIdle();
	}

	public Result<ITransferBatch> CreateTransferBatch()
	{
		let result = mInner.CreateTransferBatch();
		if (result case .Ok(let batch))
		{
			return .Ok(new ValidatedTransferBatch(batch));
		}
		return .Err;
	}

	public void DestroyTransferBatch(ref ITransferBatch batch)
	{
		if (let validated = batch as ValidatedTransferBatch)
		{
			ITransferBatch inner = validated.Inner;
			mInner.DestroyTransferBatch(ref inner);
			delete validated;
		}
		else
		{
			mInner.DestroyTransferBatch(ref batch);
		}
		batch = null;
	}

	public float TimestampPeriod => mInner.TimestampPeriod;

	public IQueue Inner => mInner;
}
