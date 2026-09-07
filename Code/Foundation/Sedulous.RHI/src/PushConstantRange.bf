namespace Sedulous.RHI;

/// A push constant block within a pipeline layout.
struct PushConstantRange
{
	public ShaderStage Stages = .None;
	public uint32 Offset = 0;
	public uint32 Size = 0;

	/// Used ONLY where push constants are emulated. A device with no push constant or
	/// immediates path, meaning a browser or a native WebGPU build with the fallback
	/// forced, binds the block as an ordinary uniform buffer at this group and binding
	/// zero, which matches the WGSL the web shader cook emits. Vulkan, DX12 and a WebGPU
	/// with native immediates ignore it.
	///
	/// Defaults to one, the engine's dominant push constant space.
	public uint32 BindGroupIndex = 1;

	public this() {}
}
