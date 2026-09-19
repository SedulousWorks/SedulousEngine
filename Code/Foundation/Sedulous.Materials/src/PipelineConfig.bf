using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Sedulous.Materials;

/// The full render state for a material, and the KEY a pipeline cache hashes on.
///
/// Orthogonal to ShaderFlags on purpose: the flags drive which shader permutation gets
/// compiled, this drives the fixed function state around it. Two materials differing only
/// in blend mode share one compiled shader and need two pipelines; two differing only in a
/// flag need two of each.
///
/// All value types, so it hashes by CONTENT.
struct PipelineConfig
{
	// ---- which shader ----

	/// A VIEW. It must outlive every use of this config, including its life in a cache.
	public StringView ShaderName = default;
	public ShaderFlags ShaderFlags = .None;

	// ---- vertex input ----

	public VertexLayoutType VertexLayout = .Mesh;
	public uint32 CustomVertexStride = 0;
	public uint8 CustomAttributeCount = 0;

	/// Adds a second, INSTANCE stepped vertex buffer: a uint4 of data offsets at location
	/// five, whose first component indexes a per instance structured buffer. Pair it with
	/// ShaderFlags.Instanced, which is the permutation that reads it.
	public bool Instanced = false;

	// ---- primitive assembly ----

	public PrimitiveTopology Topology = .TriangleList;
	public CullModeConfig CullMode = .Back;
	/// Counter clockwise, which is what a front face is after the Y flip in the projection.
	public FrontFace FrontFace = .CCW;
	public FillMode FillMode = .Solid;

	// ---- blend ----

	public BlendMode BlendMode = .Opaque;
	public ColorWriteMask ColorWriteMask = .All;

	// ---- depth and stencil ----

	public DepthMode DepthMode = .ReadWrite;
	public CompareFunction DepthCompare = Depth.Nearer; // the engine's depth convention
	public TextureFormat DepthFormat = .Depth32Float;
	public int16 DepthBias = 0;
	public float DepthBiasSlopeScale = 0.0f;

	// ---- render targets ----

	public TextureFormat[RhiLimits.MaxColorAttachments] ColorFormats = .(.BGRA8Unorm,);
	public uint8 ColorTargetCount = 1;
	public uint8 SampleCount = 1;

	// ---- flags ----

	public bool DepthOnly = false;

	/// Whether the draw writes the G buffer's auxiliary targets, the normal and velocity in
	/// slots one and up.
	///
	/// FALSE for a blended draw: it would otherwise clobber the opaque G buffer it is
	/// blending over. Such a draw still BINDS every target, because the render pass says so,
	/// but with the auxiliary write masks off.
	public bool WriteAuxTargets = true;

	public this() {}

	/// The content hash: the name's bytes folded with the rest of the state.
	public uint64 HashCode
	{
		get
		{
			var hash = HashBytes(ShaderName.Ptr, ShaderName.Length);

			// &* rather than *: this folds arbitrary content and MUST be allowed to wrap.
			// Trapping arithmetic here would take the pipeline cache down on a hash.
			void Mix(uint64 value) { hash = (hash &* 31) &+ value; }

			Mix((uint64)ShaderFlags);
			Mix((uint64)VertexLayout);
			Mix(CustomVertexStride);
			Mix(CustomAttributeCount);
			Mix(Instanced ? 1 : 0);
			Mix((uint64)Topology);
			Mix((uint64)CullMode);
			Mix((uint64)FrontFace);
			Mix((uint64)FillMode);
			Mix((uint64)BlendMode);
			Mix((uint64)ColorWriteMask);
			Mix((uint64)DepthMode);
			Mix((uint64)DepthCompare);
			Mix((uint64)DepthFormat);
			Mix((uint64)(uint16)DepthBias);

			for (int i = 0; (i < ColorTargetCount) && (i < RhiLimits.MaxColorAttachments); i++)
				Mix((uint64)ColorFormats[i]);

			Mix(ColorTargetCount);
			Mix(SampleCount);
			Mix(DepthOnly ? 1 : 0);
			Mix(WriteAuxTargets ? 1 : 0);
			return hash;
		}
	}

	/// Only the ACTIVE colour formats are compared, because the ones past the target count
	/// are never read and two configs that differ only there describe the same pipeline.
	[Commutable]
	public static bool operator==(PipelineConfig a, PipelineConfig b)
	{
		if ((a.ShaderName != b.ShaderName) || (a.ShaderFlags != b.ShaderFlags)
			|| (a.VertexLayout != b.VertexLayout) || (a.CustomVertexStride != b.CustomVertexStride)
			|| (a.CustomAttributeCount != b.CustomAttributeCount) || (a.Instanced != b.Instanced)
			|| (a.Topology != b.Topology) || (a.CullMode != b.CullMode)
			|| (a.FrontFace != b.FrontFace) || (a.FillMode != b.FillMode)
			|| (a.BlendMode != b.BlendMode) || (a.ColorWriteMask != b.ColorWriteMask)
			|| (a.DepthMode != b.DepthMode) || (a.DepthCompare != b.DepthCompare)
			|| (a.DepthFormat != b.DepthFormat) || (a.DepthBias != b.DepthBias)
			|| (a.DepthBiasSlopeScale != b.DepthBiasSlopeScale)
			|| (a.ColorTargetCount != b.ColorTargetCount) || (a.SampleCount != b.SampleCount)
			|| (a.DepthOnly != b.DepthOnly) || (a.WriteAuxTargets != b.WriteAuxTargets))
			return false;

		for (int i = 0; (i < a.ColorTargetCount) && (i < RhiLimits.MaxColorAttachments); i++)
		{
			if (a.ColorFormats[i] != b.ColorFormats[i])
				return false;
		}
		return true;
	}

	// ---- presets ----

	public static PipelineConfig ForOpaqueMesh(StringView shader, ShaderFlags flags = .None)
	{
		var config = PipelineConfig();
		config.ShaderName = shader;
		config.ShaderFlags = flags;
		config.VertexLayout = .Mesh;
		config.BlendMode = .Opaque;
		config.DepthMode = .ReadWrite;
		return config;
	}

	/// Depth READ ONLY, because a transparent draw must not occlude what blends after it.
	public static PipelineConfig ForTransparentMesh(StringView shader, ShaderFlags flags = .None)
	{
		var config = PipelineConfig();
		config.ShaderName = shader;
		config.ShaderFlags = flags;
		config.VertexLayout = .Mesh;
		config.BlendMode = .AlphaBlend;
		config.DepthMode = .ReadOnly;
		return config;
	}

	/// LessEqual and front face culling: a skybox is drawn at the far plane, from inside.
	public static PipelineConfig ForSkybox(StringView shader)
	{
		var config = PipelineConfig();
		config.ShaderName = shader;
		config.VertexLayout = .PositionOnly;
		config.DepthMode = .ReadOnly;
		config.DepthCompare = Depth.NearerOrEqual; // at the far plane: only a cleared pixel
		config.CullMode = .Front;
		return config;
	}

	public static PipelineConfig ForSprites(StringView shader)
	{
		var config = PipelineConfig();
		config.ShaderName = shader;
		config.VertexLayout = .PositionUVColor;
		config.BlendMode = .AlphaBlend;
		config.DepthMode = .ReadOnly;
		config.CullMode = .None;
		return config;
	}

	/// No vertex input at all: the vertex stage generates the triangle from its index.
	public static PipelineConfig ForFullscreen(StringView shader)
	{
		var config = PipelineConfig();
		config.ShaderName = shader;
		config.VertexLayout = .None;
		config.DepthMode = .Disabled;
		config.CullMode = .None;
		return config;
	}
}
