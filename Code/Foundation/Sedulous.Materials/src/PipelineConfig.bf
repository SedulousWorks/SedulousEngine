namespace Sedulous.Materials;

using System;
using Sedulous.RHI;
using Sedulous.Shaders;

/// Blend mode presets for common rendering scenarios.
enum BlendMode : uint8
{
	/// No blending, fully opaque.
	Opaque,
	/// Standard alpha blending (src.a, 1-src.a).
	AlphaBlend,
	/// Additive blending (one, one).
	Additive,
	/// Multiplicative blending (dst, zero).
	Multiply,
	/// Premultiplied alpha (one, 1-src.a).
	PremultipliedAlpha
}

/// Depth testing mode presets.
enum DepthMode : uint8
{
	/// No depth testing or writing.
	Disabled,
	/// Depth test and write (opaque geometry).
	ReadWrite,
	/// Depth test only, no write (transparent geometry).
	ReadOnly,
	/// Depth write only, no test.
	WriteOnly
}

/// Cull mode for face culling.
enum CullModeConfig : uint8
{
	/// No culling.
	None,
	/// Cull back-facing triangles.
	Back,
	/// Cull front-facing triangles.
	Front
}

/// Vertex layout type for common mesh formats.
enum VertexLayoutType : uint8
{
	/// No vertex input (procedural rendering).
	None,
	/// Position only (skybox, shadow depth pass).
	PositionOnly,
	/// Position + UV + Color (sprites/particles).
	PositionUVColor,
	/// Simple mesh format: Position + Normal + UV (32 bytes).
	MeshNoTangent,
	/// Standard mesh format: Position + Normal + UV + Color + Tangent3 (48 bytes).
	/// Matches Sedulous.Geometry.StaticMesh.SetupCommonVertexFormat().
	Mesh,
	/// Skinned mesh format: Position + Normal + UV + Tangent + Joints + Weights (80 bytes).
	SkinnedMesh,
	/// Custom layout (use CustomVertexLayout).
	Custom
}

/// Configuration for creating a render pipeline.
/// All fields are value types for content-based hashing.
struct PipelineConfig : IHashable, IEquatable<PipelineConfig>
{
	// ===== Shader Identification =====

	/// Shader name (without extension).
	public StringView ShaderName;

	/// Shader variant flags.
	public ShaderFlags ShaderFlags;

	// ===== Vertex Input =====

	/// Predefined vertex layout type.
	public VertexLayoutType VertexLayout;

	/// Custom vertex stride (for Custom layout).
	public uint32 CustomVertexStride;

	/// Custom vertex attribute count (for Custom layout).
	public uint8 CustomAttributeCount;

	// ===== Primitive Assembly =====

	/// Primitive topology.
	public PrimitiveTopology Topology;

	/// Face culling mode.
	public CullModeConfig CullMode;

	/// Front face winding.
	public FrontFace FrontFace;

	/// Polygon fill mode.
	public FillMode FillMode;

	// ===== Blend State =====

	/// Blend mode preset.
	public BlendMode BlendMode;

	/// Color write mask.
	public ColorWriteMask ColorWriteMask;

	// ===== Depth/Stencil =====

	/// Depth mode preset.
	public DepthMode DepthMode;

	/// Depth comparison function (when not using preset).
	public CompareFunction DepthCompare;

	/// Depth format.
	public TextureFormat DepthFormat;

	/// Depth bias for shadow mapping.
	public int16 DepthBias;

	/// Depth bias slope scale.
	public float DepthBiasSlopeScale;

	// ===== Render Targets =====

	/// Color target format.
	public TextureFormat ColorFormat;

	/// Number of color targets (0 for depth-only).
	public uint8 ColorTargetCount;

	/// Multisample count (1, 2, 4, 8).
	public uint8 SampleCount;

	// ===== Flags =====

	/// Whether this is a depth-only pass (no fragment shader).
	public bool DepthOnly;

	/// Creates a default pipeline config.
	public this()
	{
		ShaderName = default;
		ShaderFlags = .None;
		VertexLayout = .Mesh;
		CustomVertexStride = 0;
		CustomAttributeCount = 0;
		Topology = .TriangleList;
		CullMode = .Back;
		FrontFace = .CCW; // Counter-clockwise after Y-flip in projection
		FillMode = .Solid;
		BlendMode = .Opaque;
		ColorWriteMask = .All;
		DepthMode = .ReadWrite;
		DepthCompare = .Less;
		DepthFormat = .Depth32Float;
		DepthBias = 0;
		DepthBiasSlopeScale = 0;
		ColorFormat = .BGRA8Unorm;
		ColorTargetCount = 1;
		SampleCount = 1;
		DepthOnly = false;
	}

	/// Computes content-based hash code.
	public int GetHashCode()
	{
		int hash = ShaderName.GetHashCode();
		hash = hash * 31 + (int)ShaderFlags;
		hash = hash * 31 + (int)VertexLayout;
		hash = hash * 31 + (int)Topology;
		hash = hash * 31 + (int)CullMode;
		hash = hash * 31 + (int)FrontFace;
		hash = hash * 31 + (int)FillMode;
		hash = hash * 31 + (int)BlendMode;
		hash = hash * 31 + (int)ColorWriteMask;
		hash = hash * 31 + (int)DepthMode;
		hash = hash * 31 + (int)DepthCompare;
		hash = hash * 31 + (int)DepthFormat;
		hash = hash * 31 + (int)DepthBias;
		hash = hash * 31 + (int)ColorFormat;
		hash = hash * 31 + (int)ColorTargetCount;
		hash = hash * 31 + (int)SampleCount;
		hash = hash * 31 + (DepthOnly ? 1 : 0);
		return hash;
	}

	/// Compares two configs for equality.
	public bool Equals(PipelineConfig other)
	{
		return ShaderName == other.ShaderName &&
			ShaderFlags == other.ShaderFlags &&
			VertexLayout == other.VertexLayout &&
			Topology == other.Topology &&
			CullMode == other.CullMode &&
			FrontFace == other.FrontFace &&
			FillMode == other.FillMode &&
			BlendMode == other.BlendMode &&
			ColorWriteMask == other.ColorWriteMask &&
			DepthMode == other.DepthMode &&
			DepthCompare == other.DepthCompare &&
			DepthFormat == other.DepthFormat &&
			DepthBias == other.DepthBias &&
			DepthBiasSlopeScale == other.DepthBiasSlopeScale &&
			ColorFormat == other.ColorFormat &&
			ColorTargetCount == other.ColorTargetCount &&
			SampleCount == other.SampleCount &&
			DepthOnly == other.DepthOnly;
	}

	// ===== Factory Methods =====

	/// Creates a config for opaque mesh rendering.
	public static Self ForOpaqueMesh(StringView shaderName, ShaderFlags flags = .None)
	{
		var config = Self();
		config.ShaderName = shaderName;
		config.ShaderFlags = flags;
		config.VertexLayout = .Mesh;
		config.BlendMode = .Opaque;
		config.DepthMode = .ReadWrite;
		return config;
	}

	/// Creates a config for transparent mesh rendering.
	public static Self ForTransparentMesh(StringView shaderName, ShaderFlags flags = .None)
	{
		var config = Self();
		config.ShaderName = shaderName;
		config.ShaderFlags = flags;
		config.VertexLayout = .Mesh;
		config.BlendMode = .AlphaBlend;
		config.DepthMode = .ReadOnly;
		return config;
	}

	/// Creates a config for skinned mesh rendering.
	public static Self ForSkinnedMesh(StringView shaderName, bool transparent = false)
	{
		var config = transparent ? ForTransparentMesh(shaderName) : ForOpaqueMesh(shaderName);
		config.ShaderFlags |= .Skinned;
		config.VertexLayout = .SkinnedMesh;
		return config;
	}

	/// Creates a config for shadow depth pass.
	public static Self ForShadow(StringView shaderName, ShaderFlags flags = .None)
	{
		var config = Self();
		config.ShaderName = shaderName;
		config.ShaderFlags = flags | .CastShadows;
		config.VertexLayout = .PositionOnly;
		config.DepthOnly = true;
		config.DepthMode = .ReadWrite;
		config.DepthFormat = .Depth32Float;
		config.ColorTargetCount = 0;
		config.DepthBias = 2;
		config.DepthBiasSlopeScale = 2.0f;
		config.CullMode = .Front;  // Front-face culling helps prevent shadow acne
		return config;
	}

	/// Creates a config for particle rendering.
	public static Self ForParticles(StringView shaderName, BlendMode blend = .AlphaBlend)
	{
		var config = Self();
		config.ShaderName = shaderName;
		config.VertexLayout = .PositionUVColor;
		config.BlendMode = blend;
		config.DepthMode = .ReadOnly;
		config.CullMode = .None;
		return config;
	}

	/// Creates a config for sprite rendering.
	public static Self ForSprites(StringView shaderName, BlendMode blend = .AlphaBlend)
	{
		var config = Self();
		config.ShaderName = shaderName;
		config.VertexLayout = .PositionUVColor;
		config.BlendMode = blend;
		config.DepthMode = .ReadOnly;
		config.CullMode = .None;
		return config;
	}

	/// Creates a config for skybox rendering.
	public static Self ForSkybox(StringView shaderName)
	{
		var config = Self();
		config.ShaderName = shaderName;
		config.VertexLayout = .PositionOnly;
		config.DepthMode = .ReadOnly;
		config.DepthCompare = .LessEqual;
		config.CullMode = .Front; // Render inside of cube
		return config;
	}

	/// Creates a config for fullscreen post-process pass.
	public static Self ForFullscreen(StringView shaderName)
	{
		var config = Self();
		config.ShaderName = shaderName;
		config.VertexLayout = .None;
		config.DepthMode = .Disabled;
		config.CullMode = .None;
		return config;
	}

	/// Creates a config for unlit mesh rendering (no lighting calculations).
	public static Self ForUnlitMesh(bool transparent = false)
	{
		var config = Self();
		config.ShaderName = "unlit";
		config.VertexLayout = .Mesh;
		if (transparent)
		{
			config.BlendMode = .AlphaBlend;
			config.DepthMode = .ReadOnly;
		}
		else
		{
			config.BlendMode = .Opaque;
			config.DepthMode = .ReadWrite;
		}
		return config;
	}
}
