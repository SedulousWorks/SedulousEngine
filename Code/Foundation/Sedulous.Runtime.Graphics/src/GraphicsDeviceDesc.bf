using Sedulous.RHI;

namespace Sedulous.RuntimeGraphics;

/// Configuration for creating a GraphicsDevice.
struct GraphicsDeviceDesc
{
	/// Which GPU backend to use.
	public DeviceType Backend = .Vulkan;
	/// Whether to enable RHI validation wrappers and backend validation layers.
	public bool EnableValidation = true;
	/// Number of CPU-ahead frames (ring buffer depth for per-frame resources).
	public uint32 FramesInFlight = 2;
	/// Required device features. Device creation fails if the adapter doesn't support them.
	public DeviceFeatures RequiredFeatures;
}
