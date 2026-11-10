using System;

namespace Sedulous.Shaders;

/// What a cook of shaders that name their entry points (ShaderPackCooker.CookEntryShaders)
/// should produce and where from.
struct ShaderEntryCookOptions
{
	/// The folder cooked, walked whole (Data/Samples/RHI). The pack names each entry by its
	/// file relative to it.
	public StringView ShaderDirectory = default;
	/// SPIR-V and DXIL. WGSL is the engine corpus's alone, and is refused here.
	public Span<CookedShaderFormat> Formats = default;

	public this() {}
}
