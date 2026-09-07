using System;

namespace Sedulous.RHI;

struct ShaderModuleDesc
{
	/// The blob, in the device's PreferredShaderFormat. Bytecode for SPIR-V and DXIL, and
	/// source text for WGSL.
	public Span<uint8> Code = default;
	public StringView Label = default;

	public this() {}
}
