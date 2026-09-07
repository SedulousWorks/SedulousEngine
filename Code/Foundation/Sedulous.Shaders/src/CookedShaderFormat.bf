namespace Sedulous.Shaders;

/// The blob format a cooked variant holds for a target backend.
///
/// WGSL is TEXT; the other two are bytecode.
enum CookedShaderFormat : uint32
{
	/// Vulkan, and native wgpu, which accepts SPIR-V too.
	SpirV = 0,
	/// DX12.
	Dxil = 1,
	/// WebGPU in a browser.
	Wgsl = 2
}
