namespace Sedulous.RHI;

/// The shader form a device's CreateShaderModule ingests.
///
/// Vulkan and Null take SPIR-V, DX12 takes DXIL, and a browser's WebGPU takes WGSL text
/// while a native wgpu build takes SPIR-V. The shader cook picks which blob to ship by
/// asking the device through PreferredShaderFormat rather than by naming a backend.
enum ShaderFormat : uint32
{
	SpirV,
	DXIL,
	WGSL
}
