using Sedulous.RHI;

namespace Sedulous.Graphics;

struct GraphicsDeviceDesc
{
	public BackendType Backend = .Vulkan;

	/// Both the RHI's own validation wrapper and the backend's layers.
	///
	/// Follows the build config: ON for a dev build, which is there to catch API misuse, and
	/// OFF for an optimized one, which is there to measure. A host overrides it either way,
	/// and ValidationSelection reads the command line flags that do so.
#if RELEASE
	public bool EnableValidation = false;
#else
	public bool EnableValidation = true;
#endif

	/// How far ahead of the GPU the CPU may run.
	public uint32 FramesInFlight = 2;

	public DeviceFeatures RequiredFeatures = .();

	public this() {}
}
