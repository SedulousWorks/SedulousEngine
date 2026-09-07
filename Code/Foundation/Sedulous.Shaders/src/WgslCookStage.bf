namespace Sedulous.Shaders;

/// Where a WGSL translation stopped.
enum WgslCookStage
{
	Ok,
	/// DXC could not turn the HLSL into SPIR-V.
	Compile,
	/// naga could not turn the SPIR-V into WGSL, or could not be run at all.
	Translate,
	/// tint rejected the WGSL as browser incompatible, or could not be run.
	Validate
}
