namespace Sedulous.RHI.Validation;

using System;
using Sedulous.RHI;

/// Validation wrapper for IFence.
/// Enforces monotonically increasing signal values.
class ValidatedFence : IFence
{
	private IFence mInner;
	private uint64 mLastSignaledValue;

	public this(IFence inner, uint64 initialValue)
	{
		mInner = inner;
		mLastSignaledValue = initialValue;
	}

	public uint64 CompletedValue => mInner.CompletedValue;

	public bool Wait(uint64 value, uint64 timeoutNs = uint64.MaxValue)
	{
		if (value > mLastSignaledValue)
		{
			let msg = scope String();
			msg.AppendF("Fence.Wait: waiting for value {} but highest signaled value is {}", value, mLastSignaledValue);
			ValidationLogger.Warn(msg);
		}

		return mInner.Wait(value, timeoutNs);
	}

	/// Track a signal operation for monotonic value checking.
	public void TrackSignal(uint64 value)
	{
		if (value <= mLastSignaledValue && value != 0)
		{
			let msg = scope String();
			msg.AppendF("Fence: signal value {} is not greater than last signaled value {} (must be monotonically increasing)", value, mLastSignaledValue);
			ValidationLogger.Error(msg);
		}
		mLastSignaledValue = value;
	}

	public IFence Inner => mInner;
}
