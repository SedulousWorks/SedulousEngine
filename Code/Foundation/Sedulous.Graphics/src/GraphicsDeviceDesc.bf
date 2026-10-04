using System;
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

	/// The device a desktop executable's command line asks for: the backend
	/// (BackendSelection) and the validation layer (ValidationSelection) over the config's
	/// default. The one call every entry makes, so a flag one executable honours, every
	/// executable honours.
	public static GraphicsDeviceDesc FromArguments(String[] args)
	{
		GraphicsDeviceDesc desc = .();
		desc.Backend = BackendSelection.FromArguments(args);
		desc.EnableValidation = ValidationSelection.FromArguments(args, desc.EnableValidation);
		return desc;
	}
}
