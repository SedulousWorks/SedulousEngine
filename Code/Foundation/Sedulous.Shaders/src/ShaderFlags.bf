namespace Sedulous.Shaders;

/// Compile time permutation bits.
///
/// Each set flag becomes a `#define` prepended before the compile, so a shader `#ifdef`s
/// features into specialised, branch free permutations rather than branching at runtime.
///
/// Render state, blending, culling and depth, is NOT here: that is the material layer's
/// pipeline configuration. These are only the bits that change the CODE.
enum ShaderFlags : uint32
{
	case None = 0;
	case Skinned = 1;
	case Instanced = 2;
	case AlphaTest = 4;
	case NormalMap = 8;
	case Emissive = 16;
	case VertexColors = 32;
	case ReceiveShadows = 64;
	/// Forward MRT: the stage also writes a view space normal and motion.
	case GBuffer = 128;
	/// A vertex sway driven by the material's Wind properties.
	case Wind = 256;
}
