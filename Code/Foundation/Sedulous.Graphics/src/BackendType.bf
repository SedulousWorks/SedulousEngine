namespace Sedulous.Graphics;

/// Which RHI backend a GraphicsDevice is built on.
///
/// Null is a REAL option, not a placeholder: it is what CI, servers and the headless
/// tests run on, and it is the reference for what a GPU backend has to provide.
enum BackendType : uint8
{
	Vulkan,
	DX12,
	Null,
	WebGPU
}
