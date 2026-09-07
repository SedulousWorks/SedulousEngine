namespace Samples.Framework;

/// Which RHI backend a sample runs on.
///
/// Chosen by a command line flag, so one built sample can be pointed at whichever backend a
/// machine has rather than needing a build per backend.
enum BackendType
{
	Vulkan,
	DX12,
	WebGPU
}
