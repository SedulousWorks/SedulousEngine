namespace Sedulous.Shaders;

/// The bytecode a compile produces.
///
/// WGSL is absent because DXC does not emit it: a WGSL blob is produced by translating
/// SPIR-V afterwards, which is the cook's business rather than the compiler's.
enum ShaderTarget : uint32
{
	SPIRV,
	DXIL
}
