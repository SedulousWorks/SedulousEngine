using Sedulous.RHI;

namespace Sedulous.Graphics;

struct GraphicsDeviceDesc
{
	public BackendType Backend = .Vulkan;

	/// Both the RHI's own validation wrapper and the backend's layers.
	///
	/// ON here, because Beef has no release define to switch on. A shipping host sets it
	/// false itself, which is the same decision made one level up rather than by the build
	/// type.
	public bool EnableValidation = true;

	/// How far ahead of the GPU the CPU may run.
	public uint32 FramesInFlight = 2;

	public DeviceFeatures RequiredFeatures = .();

	public this() {}
}
