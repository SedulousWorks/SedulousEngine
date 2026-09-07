using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// A fence the CPU drives.
///
/// Waiting SUCCEEDS IMMEDIATELY and advances the counter to the value waited for, because
/// there is no GPU to be behind. That keeps a fence guarded loop making progress headlessly
/// rather than deadlocking on work that will never complete.
class NullFence : IFence
{
	private uint64 mValue = 0;

	public uint64 CompletedValue() => mValue;

	public bool Wait(uint64 value, uint64 timeoutNs = uint64.MaxValue)
	{
		if (value > mValue)
			mValue = value;
		return true;
	}

	/// What a queue submission calls to complete the work at once.
	public void Signal(uint64 value)
	{
		if (value > mValue)
			mValue = value;
	}
}
