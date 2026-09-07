namespace Sedulous.RHI;

/// Which backend a device came from.
///
/// Callers should ask a capability question rather than branch on this. It is here for
/// diagnostics and for the handful of places that genuinely need to name a backend, such
/// as picking a cooked shader blob.
enum DeviceType : uint32
{
	Vulkan,
	DX12,
	Null,
	WebGPU
}
