namespace Sedulous.RHI;

/// A TIMELINE fence: a monotonically increasing counter the GPU signals and the CPU waits
/// on.
///
/// A timeline rather than a binary fence, so one object orders many submissions and a
/// waiter names the value it cares about instead of needing a fence per frame in flight.
interface IFence
{
	/// The highest value the GPU has signalled so far.
	uint64 CompletedValue();

	/// Blocks until the counter reaches `value`, or the timeout passes.
	///
	/// Returns whether the value was reached: FALSE means it timed out, which is not an
	/// error and leaves the fence usable.
	bool Wait(uint64 value, uint64 timeoutNs = uint64.MaxValue);
}
