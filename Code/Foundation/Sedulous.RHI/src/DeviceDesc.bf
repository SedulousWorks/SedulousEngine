using System;

namespace Sedulous.RHI;

/// What to create a logical device with.
///
/// The queue counts are REQUESTS. A device may hand back fewer, or map several onto one
/// hardware queue, so a caller checks GetQueueCount afterwards rather than assuming it got
/// what it asked for.
struct DeviceDesc
{
	public DeviceFeatures RequiredFeatures = .();
	public uint32 GraphicsQueueCount = 1;
	/// Zero means "no dedicated compute queue": work still runs, on the graphics queue.
	public uint32 ComputeQueueCount = 0;
	public uint32 TransferQueueCount = 0;
	public StringView Label = default;

	public this() {}
}
