namespace Sedulous.Engine.Vegetation.Backend.Tests;

/// Which RHI backend a probe fixture builds its device on.
///
/// Vulkan is the REFERENCE. Every case asserts against pixels a Vulkan device wrote,
/// and the cross backend case compares the others to it rather than to a constant.
///
/// WebGpu is the DESKTOP WebGPU backend, not the browser one. That is the point: the shader
/// cook goes through a different frontend to reach it, so a divergence in the integer Load on
/// the R16Uint height texture, in the GBuffer MRT layout, or in the normal and lit path shows
/// up on a desktop test run instead of only in a browser.
enum ProbeBackend
{
	Vulkan,
	WebGpu,
	/// DX12, which only exists on Windows. The fixture answers NOT READY for it elsewhere, so
	/// every probe that iterates this list skips it on other platforms without a guard of its
	/// own.
	Dx12
}
