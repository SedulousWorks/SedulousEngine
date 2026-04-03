namespace Sedulous.RHI.Validation;

using System;
using Sedulous.RHI;

/// Validation wrapper for ITransferBatch.
class ValidatedTransferBatch : ITransferBatch
{
	private ITransferBatch mInner;
	private bool mDestroyed;
	private int mPendingWrites;

	public this(ITransferBatch inner)
	{
		mInner = inner;
	}

	private bool CheckNotDestroyed(StringView method)
	{
		if (mDestroyed)
		{
			let msg = scope String();
			msg.AppendF("TransferBatch.{}: batch has been destroyed", method);
			ValidationLogger.Error(msg);
			return false;
		}
		return true;
	}

	public void WriteBuffer(IBuffer dst, uint64 dstOffset, Span<uint8> data)
	{
		if (!CheckNotDestroyed("WriteBuffer")) return;

		if (dst == null)
		{
			ValidationLogger.Error("WriteBuffer: dst buffer is null");
			return;
		}

		if (data.IsEmpty)
		{
			ValidationLogger.Warn("WriteBuffer: data is empty");
			return;
		}

		mPendingWrites++;
		mInner.WriteBuffer(dst, dstOffset, data);
	}

	public void WriteTexture(ITexture dst, Span<uint8> data,
		TextureDataLayout dataLayout, Extent3D extent,
		uint32 mipLevel = 0, uint32 arrayLayer = 0)
	{
		if (!CheckNotDestroyed("WriteTexture")) return;

		if (dst == null)
		{
			ValidationLogger.Error("WriteTexture: dst texture is null");
			return;
		}

		if (data.IsEmpty)
		{
			ValidationLogger.Warn("WriteTexture: data is empty");
			return;
		}

		if (extent.Width == 0 || extent.Height == 0 || extent.Depth == 0)
		{
			ValidationLogger.Error("WriteTexture: extent has zero dimension");
			return;
		}

		mPendingWrites++;
		mInner.WriteTexture(dst, data, dataLayout, extent, mipLevel, arrayLayer);
	}

	public Result<void> Submit()
	{
		if (!CheckNotDestroyed("Submit")) return .Err;

		if (mPendingWrites == 0)
		{
			ValidationLogger.Warn("TransferBatch.Submit: no writes recorded");
		}

		let result = mInner.Submit();
		mPendingWrites = 0;
		return result;
	}

	public Result<void> SubmitAsync(IFence fence, uint64 signalValue)
	{
		if (!CheckNotDestroyed("SubmitAsync")) return .Err;

		if (fence == null)
		{
			ValidationLogger.Error("SubmitAsync: fence is null");
			return .Err;
		}

		if (mPendingWrites == 0)
		{
			ValidationLogger.Warn("TransferBatch.SubmitAsync: no writes recorded");
		}

		// Unwrap validated fence
		IFence innerFence = fence;
		if (let vf = fence as ValidatedFence)
		{
			vf.TrackSignal(signalValue);
			innerFence = vf.Inner;
		}

		let result = mInner.SubmitAsync(innerFence, signalValue);
		mPendingWrites = 0;
		return result;
	}

	public void Reset()
	{
		if (!CheckNotDestroyed("Reset")) return;
		mPendingWrites = 0;
		mInner.Reset();
	}

	public void Destroy()
	{
		if (mDestroyed)
		{
			ValidationLogger.Warn("TransferBatch.Destroy: already destroyed");
			return;
		}
		mDestroyed = true;
		mInner.Destroy();
	}

	public ITransferBatch Inner => mInner;
}
