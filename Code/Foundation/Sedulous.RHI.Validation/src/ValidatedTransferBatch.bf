using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Watches an upload batch: what it is handed, and whether it is used after it is gone.
class ValidatedTransferBatch : ITransferBatch
{
	private ITransferBatch mInner;
	private bool mDestroyed = false;
	private int mPendingWrites = 0;

	public this(ITransferBatch inner) => mInner = inner;

	public ITransferBatch Inner => mInner;

	public void WriteBuffer(IBuffer dst, uint64 dstOffset, Span<uint8> data)
	{
		if (Destroyed("WriteBuffer"))
			return;
		if (dst == null)
		{
			ValidationLog.Error("TransferBatch.WriteBuffer: dst is null");
			return;
		}
		// An empty write is not recorded: there is nothing to stage, and counting it would
		// make a batch of nothing look like a batch with work in it.
		if (data.IsEmpty)
		{
			ValidationLog.Warn("TransferBatch.WriteBuffer: data is empty");
			return;
		}

		mPendingWrites++;
		mInner.WriteBuffer(dst, dstOffset, data);
	}

	public void WriteTexture(ITexture dst, Span<uint8> data, TextureDataLayout layout,
		Extent3D extent, uint32 mipLevel = 0, uint32 arrayLayer = 0)
	{
		if (Destroyed("WriteTexture"))
			return;
		if (dst == null)
		{
			ValidationLog.Error("TransferBatch.WriteTexture: dst is null");
			return;
		}
		if (data.IsEmpty)
		{
			ValidationLog.Warn("TransferBatch.WriteTexture: data is empty");
			return;
		}
		// A zero in any dimension writes nothing, which is almost always a size that was
		// never filled in rather than a deliberate empty write. Depth is checked too, which
		// Raptor does not: a flat write into a volume is the same mistake.
		if ((extent.Width == 0) || (extent.Height == 0) || (extent.Depth == 0))
		{
			ValidationLog.Error("TransferBatch.WriteTexture: extent has a zero dimension");
			return;
		}

		mPendingWrites++;
		mInner.WriteTexture(dst, data, layout, extent, mipLevel, arrayLayer);
	}

	public Result<void> Submit()
	{
		if (Destroyed("Submit"))
			return .Err;
		if (mPendingWrites == 0)
			ValidationLog.Warn("TransferBatch.Submit: no writes were recorded");

		let result = mInner.Submit();
		mPendingWrites = 0;
		return result;
	}

	public Result<void> SubmitAsync(IFence fence, uint64 signalValue)
	{
		if (Destroyed("SubmitAsync"))
			return .Err;
		if (fence == null)
		{
			ValidationLog.Error("TransferBatch.SubmitAsync: fence is null");
			return .Err;
		}
		if (mPendingWrites == 0)
			ValidationLog.Warn("TransferBatch.SubmitAsync: no writes were recorded");

		if (let validated = fence as ValidatedFence)
		{
			validated.RecordSignal(signalValue);
			let result = mInner.SubmitAsync(validated.Inner, signalValue);
			mPendingWrites = 0;
			return result;
		}

		let result = mInner.SubmitAsync(fence, signalValue);
		mPendingWrites = 0;
		return result;
	}

	public void Reset()
	{
		mPendingWrites = 0;
		mInner.Reset();
	}

	public void Destroy()
	{
		if (mDestroyed)
		{
			ValidationLog.Warn("TransferBatch.Destroy: already destroyed");
			return;
		}
		mDestroyed = true;
		mInner.Destroy();
	}

	private bool Destroyed(StringView operation)
	{
		if (!mDestroyed)
			return false;
		ValidationLog.Error(scope $"TransferBatch.{operation}: the batch is already destroyed");
		return true;
	}
}
