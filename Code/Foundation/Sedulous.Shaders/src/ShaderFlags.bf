using System;
namespace Sedulous.Shaders;

/// Shader variant flags for compile-time permutations.
/// These flags are converted to #defines during shader compilation.
//[Flags]
[AllowDuplicates]
enum ShaderFlags : uint32
{
	None = 0,

	// ===== Mesh Features =====

	/// Enable skeletal animation with bone matrices.
	Skinned = 1 << 0,

	/// Enable GPU instancing.
	Instanced = 1 << 1,

	/// Enable alpha cutout testing.
	AlphaTest = 1 << 2,

	/// Enable normal mapping (requires tangent space).
	NormalMap = 1 << 3,

	/// Enable emissive channel.
	Emissive = 1 << 4,

	// ===== Depth Configuration =====

	/// Enable depth testing.
	DepthTest = 1 << 5,

	/// Enable depth writing.
	DepthWrite = 1 << 6,

	/// Use reverse-Z depth (1.0 near, 0.0 far).
	ReverseZ = 1 << 7,

	// ===== Shadow Configuration =====

	/// Sample shadow maps for lighting.
	ReceiveShadows = 1 << 8,

	/// Render to shadow maps.
	CastShadows = 1 << 9,

	// ===== Rendering Features =====

	/// Wireframe rendering mode.
	Wireframe = 1 << 10,

	/// Disable backface culling.
	DoubleSided = 1 << 11,

	/// Use vertex colors.
	VertexColors = 1 << 12,

	// ===== Particle Features =====

	/// Enable depth-based soft particle fading.
	SoftParticles = 1 << 13,

	// ===== Common Combinations =====

	/// Default opaque mesh flags.
	DefaultOpaque = DepthTest | DepthWrite | ReceiveShadows,

	/// Default transparent mesh flags.
	DefaultTransparent = DepthTest | ReceiveShadows,

	/// Default shadow pass flags.
	DefaultShadow = DepthTest | DepthWrite | CastShadows,

	/// Default particle flags.
	DefaultParticle = DepthTest,

	/// Default soft particle flags.
	DefaultSoftParticle = DepthTest | SoftParticles,

	/// All feature flags (excluding depth/shadow config).
	AllFeatures = Skinned | Instanced | AlphaTest | NormalMap | Emissive | Wireframe | DoubleSided | VertexColors | SoftParticles
}

extension ShaderFlags
{
	/// Generates shader #define string for these flags.
	public void AppendDefines(String outDefines)
	{
		// SKINNED define for skinned mesh shaders
		if (HasFlag(.Skinned))
			outDefines.Append("#define SKINNED 1\n");
		if (HasFlag(.Instanced))
			outDefines.Append("#define INSTANCED 1\n");
		if (HasFlag(.AlphaTest))
			outDefines.Append("#define ALPHA_TEST 1\n");
		if (HasFlag(.NormalMap))
			outDefines.Append("#define NORMAL_MAP 1\n");
		if (HasFlag(.Emissive))
			outDefines.Append("#define EMISSIVE 1\n");
		if (HasFlag(.DepthTest))
			outDefines.Append("#define DEPTH_TEST 1\n");
		if (HasFlag(.DepthWrite))
			outDefines.Append("#define DEPTH_WRITE 1\n");
		if (HasFlag(.ReverseZ))
			outDefines.Append("#define REVERSE_Z 1\n");
		if (HasFlag(.ReceiveShadows))
			outDefines.Append("#define RECEIVE_SHADOWS 1\n");
		if (HasFlag(.CastShadows))
			outDefines.Append("#define CAST_SHADOWS 1\n");
		if (HasFlag(.Wireframe))
			outDefines.Append("#define WIREFRAME 1\n");
		if (HasFlag(.DoubleSided))
			outDefines.Append("#define DOUBLE_SIDED 1\n");
		if (HasFlag(.VertexColors))
			outDefines.Append("#define VERTEX_COLORS 1\n");
		if (HasFlag(.SoftParticles))
			outDefines.Append("#define SOFT_PARTICLES 1\n");
	}

	/// Gets a short string representation for cache keys.
	public void AppendKeyString(String outKey)
	{
		if (HasFlag(.Skinned)) outKey.Append("S");
		if (HasFlag(.Instanced)) outKey.Append("I");
		if (HasFlag(.AlphaTest)) outKey.Append("A");
		if (HasFlag(.NormalMap)) outKey.Append("N");
		if (HasFlag(.Emissive)) outKey.Append("E");
		if (HasFlag(.DepthTest)) outKey.Append("Dt");
		if (HasFlag(.DepthWrite)) outKey.Append("Dw");
		if (HasFlag(.ReverseZ)) outKey.Append("Rz");
		if (HasFlag(.ReceiveShadows)) outKey.Append("Rs");
		if (HasFlag(.CastShadows)) outKey.Append("Cs");
		if (HasFlag(.Wireframe)) outKey.Append("Wf");
		if (HasFlag(.DoubleSided)) outKey.Append("Ds");
		if (HasFlag(.VertexColors)) outKey.Append("Vc");
		if (HasFlag(.SoftParticles)) outKey.Append("Sp");
	}
}
