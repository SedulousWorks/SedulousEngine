namespace Sedulous.RHI;

/// How a shader reads a sampled texture.
///
/// WebGPU VALIDATES the layout's declared type against the shader: an HLSL SampleCmp
/// lowers to Depth, and an integer format reads as Uint or Sint. Vulkan and DX12 need no
/// declaration and ignore it, so a layout that is wrong here still works everywhere except
/// the backend that checks.
enum TextureSampleType : uint32
{
	Float,
	UnfilterableFloat,
	Depth,
	Uint,
	Sint
}
