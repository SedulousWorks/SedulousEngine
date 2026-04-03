namespace Sedulous.RHI.Null;

using System;

class NullQueue : IQueue
{
	private QueueType mType;

	public this(QueueType type) { mType = type; }

	public QueueType Type => mType;
	public float TimestampPeriod => 1.0f;

	public void Submit(Span<ICommandBuffer> commandBuffers) { }

	public void Submit(Span<ICommandBuffer> commandBuffers, IFence fence, uint64 signalValue)
	{
		if (let nullFence = fence as NullFence)
			nullFence.Signal(signalValue);
	}

	public void Submit(
		Span<ICommandBuffer> commandBuffers,
		Span<IFence> waitFences,
		Span<uint64> waitValues,
		IFence signalFence,
		uint64 signalValue)
	{
		if (let nullFence = signalFence as NullFence)
			nullFence.Signal(signalValue);
	}

	public void WaitIdle() { }

	public Result<ITransferBatch> CreateTransferBatch()
	{
		return .Ok(new NullTransferBatch());
	}

	public void DestroyTransferBatch(ref ITransferBatch batch)
	{
		delete batch;
		batch = null;
	}
}

class NullTransferBatch : ITransferBatch
{
	public void WriteBuffer(IBuffer dst, uint64 dstOffset, Span<uint8> data)
	{
		// Copy into the null buffer's backing memory if mappable
		if (let nullBuf = dst as NullBuffer)
		{
			if (let mapped = nullBuf.Map())
				Internal.MemCpy((uint8*)mapped + dstOffset, data.Ptr, data.Length);
		}
	}

	public void WriteTexture(ITexture dst, Span<uint8> data,
		TextureDataLayout dataLayout, Extent3D extent,
		uint32 mipLevel = 0, uint32 arrayLayer = 0)
	{
	}

	public Result<void> Submit() => .Ok;
	public Result<void> SubmitAsync(IFence fence, uint64 signalValue)
	{
		if (let nullFence = fence as NullFence)
			nullFence.Signal(signalValue);
		return .Ok;
	}

	public void Reset() { }
	public void Destroy() { }
}
