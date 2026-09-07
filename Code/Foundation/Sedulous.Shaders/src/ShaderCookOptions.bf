using System;

namespace Sedulous.Shaders;

/// What a corpus cook should produce and where from.
struct ShaderCookOptions
{
	/// The source root, which doubles as the include path for shared .hlsli.
	public StringView ShaderDirectory = default;
	/// Where the WGSL translator writes its intermediates. Must exist and be writable.
	public StringView ScratchDirectory = default;
	/// Which backend blobs to emit.
	public Span<CookedShaderFormat> Formats = default;
	/// Whether to run tint over the WGSL.
	public bool ValidateWgsl = true;
	/// The SPIR-V target for the SpirV blobs.
	///
	/// vulkan1.1 BY CONTRACT, not by preference: the SpirV bucket serves both Vulkan and
	/// native WebGPU, and naga rejects the SPIR-V 1.4 and later instructions a vulkan1.3
	/// compile emits. A 1.3 pack panics wgpu at pipeline creation.
	public StringView SpirvTargetEnvironment = "vulkan1.1";

	public this() {}
}
