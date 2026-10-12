using System;

namespace Sedulous.RHI;

struct ShaderModuleDesc
{
	/// The blob, in the device's PreferredShaderFormat. Bytecode for SPIR-V and DXIL, and
	/// source text for WGSL.
	public Span<uint8> Code = default;
	public StringView Label = default;
	/// The entry point the code was compiled for (`VSMain`, or `main` for the engine's own
	/// shaders); a ProgrammableStage that names none uses it. Empty for a module that holds
	/// several entries: every stage built from it must then name its own.
	public StringView EntryPoint = default;

	public this() {}
}
