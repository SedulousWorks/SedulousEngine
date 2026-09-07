using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Watches a fence's timeline for the two ways it goes wrong.
class ValidatedFence : IFence
{
	private IFence mInner;
	private uint64 mLastSignaled = 0;

	public this(IFence inner) => mInner = inner;

	public IFence Inner => mInner;

	public uint64 CompletedValue() => mInner.CompletedValue();

	/// Waiting for a value NOTHING WILL EVER SIGNAL is a deadlock, and the most common way
	/// to write one is an off by one in a frame index. Warned rather than refused: the
	/// signal may still be coming from another thread.
	public bool Wait(uint64 value, uint64 timeoutNs = uint64.MaxValue)
	{
		if ((value > mLastSignaled) && (mLastSignaled > 0))
		{
			ValidationLog.Warn(scope $"Fence.Wait: waiting for value {value} but the highest signalled is {mLastSignaled}");
		}
		return mInner.Wait(value, timeoutNs);
	}

	/// A timeline only goes UP. Signalling a value already passed leaves waiters that were
	/// counting on the increase stuck.
	public void RecordSignal(uint64 value)
	{
		if ((value <= mLastSignaled) && (mLastSignaled > 0))
		{
			ValidationLog.Warn(scope $"Fence signal value {value} is not monotonically increasing, the last was {mLastSignaled}");
		}
		mLastSignaled = value;
	}

	public uint64 LastSignaled => mLastSignaled;
}
