namespace Sedulous.RHI;

/// Which engine a queue feeds.
///
/// A device may expose several of each, or map them all onto one: ask GetQueueCount rather
/// than assuming a transfer queue exists separately from graphics.
enum QueueType : uint32
{
	Graphics,
	Compute,
	Transfer
}
