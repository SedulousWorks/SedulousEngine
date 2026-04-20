namespace Sedulous.ShaderReflection;

using System;
using System.Collections;
using Sedulous.RHI;

/// Top-level result of reflecting a single shader module.
class ReflectedShader
{
	/// Which stage this shader targets.
	public ShaderStage Stage;

	/// All resource bindings declared by the shader.
	public List<ReflectedBinding> Bindings = new .() ~ delete _;

	/// Vertex inputs (only populated for vertex shaders).
	public List<ReflectedVertexInput> VertexInputs = new .() ~ delete _;

	/// Push constant / root constant ranges.
	public List<ReflectedPushConstant> PushConstants = new .() ~ delete _;

	/// Thread group size for compute/mesh/task shaders (0,0,0 otherwise).
	public uint32[3] ThreadGroupSize;

	/// Specialization constants (SPIR-V only; DXIL has no equivalent).
	public List<ReflectedSpecConstant> SpecConstants = new .() ~ delete _;

	/// Mesh shader output properties (only populated for mesh shaders).
	public MeshOutputDesc MeshOutput;

	/// Entry point name.
	public String EntryPoint = new .() ~ delete _;

	/// String table - owns all strings that StringViews in bindings/inputs point into.
	public List<String> StringTable = new .() ~ DeleteContainerAndItems!(_);

	/// Adds a string to the string table and returns a StringView into it.
	public StringView InternString(StringView str)
	{
		let owned = new String(str);
		StringTable.Add(owned);
		return owned;
	}
}

/// A single resource binding (uniform buffer, texture, sampler, storage buffer/texture).
struct ReflectedBinding
{
	/// Binding set/space (maps to BindGroupLayout index).
	public uint32 Set;
	/// Binding slot within the set.
	public uint32 Binding;
	/// Type of resource.
	public BindingType Type;
	/// Shader stages that access this binding.
	public ShaderStage Stages;
	/// Array element count (1 for non-array bindings, 0 for runtime-sized / bindless arrays).
	public uint32 Count;
	/// Name as declared in the shader source.
	public StringView Name;
	/// Texture view dimension (for texture/storage texture bindings). Default = Texture2D.
	public TextureViewDimension TextureDimension = .Texture2D;
	/// Whether the texture is multisampled.
	public bool TextureMultisampled = false;
}

/// A vertex shader input attribute.
struct ReflectedVertexInput
{
	/// Semantic index / location.
	public uint32 Location;
	/// Vertex attribute format.
	public VertexFormat Format;
	/// Semantic name (HLSL) or variable name (GLSL).
	public StringView Name;
}

/// Output topology for mesh shaders.
enum MeshOutputTopology
{
	Unknown,
	Points,
	Lines,
	Triangles,
}

/// Mesh shader output properties.
struct MeshOutputDesc
{
	/// Output topology (points, lines, triangles).
	public MeshOutputTopology Topology;
	/// Maximum number of output vertices.
	public uint32 MaxVertices;
	/// Maximum number of output primitives.
	public uint32 MaxPrimitives;
}

/// Specialization constant scalar type.
enum SpecConstantType
{
	Unknown,
	Bool,
	Int32,
	Uint32,
	Float32,
}

/// A shader specialization constant (SPIR-V OpSpecConstant).
struct ReflectedSpecConstant
{
	/// Specialization constant ID (SpecId decoration value).
	public uint32 ConstantId;
	/// Scalar type.
	public SpecConstantType Type;
	/// Default value stored as raw bits (reinterpret based on Type).
	public uint32 DefaultValue;
	/// Name as declared in the shader source.
	public StringView Name;
}

/// A push constant / root constant range.
struct ReflectedPushConstant
{
	/// Byte offset within the push constant block.
	public uint32 Offset;
	/// Byte size.
	public uint32 Size;
	/// Shader stages that access this range.
	public ShaderStage Stages;
}
