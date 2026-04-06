namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Materials;

/// Key for pipeline state cache lookups.
/// Combines material/shader config with vertex layout and render target context.
struct PipelineStateCacheKey : IHashable, IEquatable<PipelineStateCacheKey>
{
	/// Hash of shader name and flags.
	public int ShaderHash;

	/// Hash of render state (blend, cull, depth).
	public int RenderStateHash;

	/// Hash of vertex buffer layouts.
	public int VertexLayoutHash;

	/// Color target format.
	public TextureFormat ColorFormat;

	/// Depth buffer format.
	public TextureFormat DepthFormat;

	/// MSAA sample count.
	public uint8 SampleCount;

	/// Additional flags for variants.
	public uint32 VariantFlags;

	public int GetHashCode()
	{
		int hash = ShaderHash;
		hash = hash * 31 + RenderStateHash;
		hash = hash * 31 + VertexLayoutHash;
		hash = hash * 31 + (int)ColorFormat;
		hash = hash * 31 + (int)DepthFormat;
		hash = hash * 31 + (int)SampleCount;
		hash = hash * 31 + (int)VariantFlags;
		return hash;
	}

	public bool Equals(PipelineStateCacheKey other)
	{
		return ShaderHash == other.ShaderHash &&
			RenderStateHash == other.RenderStateHash &&
			VertexLayoutHash == other.VertexLayoutHash &&
			ColorFormat == other.ColorFormat &&
			DepthFormat == other.DepthFormat &&
			SampleCount == other.SampleCount &&
			VariantFlags == other.VariantFlags;
	}
}

/// Variant flags for pipeline creation.
enum PipelineVariantFlags : uint32
{
	None = 0,
	Instanced = 1 << 0,
	ReceiveShadows = 1 << 1,
	BackFaceCull = 1 << 2,
	FrontFaceCull = 1 << 3,
}

/// Caches GPU render pipeline objects by configuration.
/// Creates pipelines on demand from material config + vertex layout + render target format.
/// Avoids recreating the same pipeline when different meshes share the same material/shader.
///
/// Lives in Sedulous.Renderer — scene-independent. Takes a Pipeline reference for
/// shared layouts and shader system access.
class PipelineStateCache : IDisposable
{
	private IDevice mDevice;
	private ShaderSystem mShaderSystem;
	private Pipeline mPipeline;

	private Dictionary<int, IRenderPipeline> mPipelineCache = new .() ~ delete _;
	private Dictionary<int, IPipelineLayout> mLayoutCache = new .() ~ delete _;

	public this(IDevice device, ShaderSystem shaderSystem, Pipeline pipeline)
	{
		mDevice = device;
		mShaderSystem = shaderSystem;
		mPipeline = pipeline;
	}

	/// Gets or creates a pipeline for a material config with caller-provided vertex layouts.
	public Result<IRenderPipeline> GetPipeline(
		PipelineConfig config,
		Span<VertexBufferLayout> vertexBuffers,
		IBindGroupLayout materialLayout,
		TextureFormat colorFormat,
		TextureFormat depthFormat = .Undefined,
		uint8 sampleCount = 1,
		PipelineVariantFlags variantFlags = .None,
		DepthMode? depthModeOverride = null,
		CompareFunction? depthCompareOverride = null)
	{
		// Apply overrides
		var cfg = config;
		if (depthModeOverride.HasValue)
			cfg.DepthMode = depthModeOverride.Value;
		if (depthCompareOverride.HasValue)
			cfg.DepthCompare = depthCompareOverride.Value;

		// Build cache key
		let key = BuildKey(cfg, vertexBuffers, colorFormat, depthFormat, sampleCount, variantFlags);
		let hash = key.GetHashCode();

		// Check cache
		if (mPipelineCache.TryGetValue(hash, let cached))
			return .Ok(cached);

		// Get or create pipeline layout
		let pipelineLayout = GetOrCreatePipelineLayout(materialLayout);
		if (pipelineLayout == null)
			return .Err;

		// Create new pipeline
		if (CreatePipeline(cfg, vertexBuffers, pipelineLayout, colorFormat, depthFormat, sampleCount, variantFlags) case .Ok(let pipeline))
		{
			mPipelineCache[hash] = pipeline;
			return .Ok(pipeline);
		}

		return .Err;
	}

	/// Gets or creates a pipeline from a MaterialInstance with caller-provided vertex layouts.
	public Result<IRenderPipeline> GetPipelineForMaterial(
		MaterialInstance material,
		Span<VertexBufferLayout> vertexBuffers,
		IBindGroupLayout materialLayout,
		TextureFormat colorFormat,
		TextureFormat depthFormat = .Undefined,
		uint8 sampleCount = 1,
		PipelineVariantFlags variantFlags = .None,
		DepthMode? depthModeOverride = null,
		CompareFunction? depthCompareOverride = null)
	{
		if (material == null)
			return .Err;

		var config = material.Material?.PipelineConfig ?? PipelineConfig();

		// Override blend mode from instance if set
		if (material.BlendMode != .Opaque)
			config.BlendMode = material.BlendMode;

		return GetPipeline(config, vertexBuffers, materialLayout, colorFormat, depthFormat,
			sampleCount, variantFlags, depthModeOverride, depthCompareOverride);
	}

	/// Clears all cached pipelines and layouts.
	public void Clear()
	{
		for (var kv in mPipelineCache)
		{
			var pipeline = kv.value;
			mDevice.DestroyRenderPipeline(ref pipeline);
		}
		mPipelineCache.Clear();

		for (var kv in mLayoutCache)
		{
			var layout = kv.value;
			mDevice.DestroyPipelineLayout(ref layout);
		}
		mLayoutCache.Clear();
	}

	/// Gets the number of cached pipelines.
	public int PipelineCount => mPipelineCache.Count;

	public void Dispose()
	{
		Clear();
	}

	public ~this()
	{
		Dispose();
	}

	// ==================== Internal ====================

	/// Gets or creates a pipeline layout for the 4-level bind group model.
	/// Set 0 = Frame (from Pipeline), Set 1 = Pass (TODO), Set 2 = Material, Set 3 = DrawCall (from Pipeline)
	private IPipelineLayout GetOrCreatePipelineLayout(IBindGroupLayout materialLayout)
	{
		// Use default material layout if none provided
		let effectiveMatLayout = materialLayout != null ? materialLayout : mPipeline.MaterialBindGroupLayout;

		int hash = (int)(void*)Internal.UnsafeCastToPtr(effectiveMatLayout);

		if (mLayoutCache.TryGetValue(hash, let cached))
			return cached;

		let frameLayout = mPipeline.FrameBindGroupLayout;
		let drawLayout = mPipeline.DrawCallBindGroupLayout;

		// Always create a full 4-set layout: frame (0) + pass (1) + material (2) + draw (3)
		// Set 1 (pass) reuses frame layout as placeholder for now
		IBindGroupLayout[4] layouts = .(frameLayout, frameLayout, effectiveMatLayout, drawLayout);
		PipelineLayoutDesc layoutDesc = .(Span<IBindGroupLayout>(&layouts[0], 4));

		if (mDevice.CreatePipelineLayout(layoutDesc) case .Ok(let layout))
		{
			mLayoutCache[hash] = layout;
			return layout;
		}

		return null;
	}

	private PipelineStateCacheKey BuildKey(
		PipelineConfig config,
		Span<VertexBufferLayout> vertexBuffers,
		TextureFormat colorFormat,
		TextureFormat depthFormat,
		uint8 sampleCount,
		PipelineVariantFlags variantFlags)
	{
		PipelineStateCacheKey key = .();

		// Shader hash
		key.ShaderHash = 17;
		if (!config.ShaderName.IsEmpty)
			key.ShaderHash = key.ShaderHash * 31 + config.ShaderName.GetHashCode();
		key.ShaderHash = key.ShaderHash * 31 + (int)config.ShaderFlags;

		// Render state hash
		key.RenderStateHash = 17;
		key.RenderStateHash = key.RenderStateHash * 31 + (int)config.BlendMode;
		key.RenderStateHash = key.RenderStateHash * 31 + (int)config.CullMode;
		key.RenderStateHash = key.RenderStateHash * 31 + (int)config.DepthMode;
		key.RenderStateHash = key.RenderStateHash * 31 + (int)config.DepthCompare;
		key.RenderStateHash = key.RenderStateHash * 31 + (int)config.DepthBias;
		key.RenderStateHash = key.RenderStateHash * 31 + (int)(config.DepthBiasSlopeScale * 1000);

		// Vertex layout hash
		key.VertexLayoutHash = ComputeVertexLayoutHash(vertexBuffers);

		// Render target context
		key.ColorFormat = colorFormat;
		key.DepthFormat = depthFormat;
		key.SampleCount = sampleCount;
		key.VariantFlags = (uint32)variantFlags;

		return key;
	}

	private int ComputeVertexLayoutHash(Span<VertexBufferLayout> layouts)
	{
		int hash = 17;
		for (let layout in layouts)
		{
			hash = hash * 31 + (int)layout.Stride;
			hash = hash * 31 + (int)layout.StepMode;
			for (let attr in layout.Attributes)
			{
				hash = hash * 31 + (int)attr.Format;
				hash = hash * 31 + (int)attr.Offset;
				hash = hash * 31 + (int)attr.ShaderLocation;
			}
		}
		return hash;
	}

	private Result<IRenderPipeline> CreatePipeline(
		PipelineConfig config,
		Span<VertexBufferLayout> vertexBuffers,
		IPipelineLayout layout,
		TextureFormat colorFormat,
		TextureFormat depthFormat,
		uint8 sampleCount,
		PipelineVariantFlags variantFlags)
	{
		// Build shader flags
		var shaderFlags = config.ShaderFlags;
		if (variantFlags.HasFlag(.Instanced))
			shaderFlags |= .Instanced;
		if (variantFlags.HasFlag(.ReceiveShadows))
			shaderFlags |= .ReceiveShadows;

		// Get shader name
		StringView shaderName = config.ShaderName;
		if (shaderName.IsEmpty)
			shaderName = "forward";

		// Get shaders
		let shaderResult = mShaderSystem.GetShaderPair(shaderName, shaderFlags);
		if (shaderResult case .Err)
			return .Err;

		let (vertShader, fragShader) = shaderResult.Value;

		// Color target
		ColorTargetState[1] colorTargets = default;
		int colorTargetCount = 0;
		bool hasColorTarget = !config.DepthOnly && config.ColorTargetCount > 0;

		if (hasColorTarget)
		{
			let blendState = GetBlendState(config.BlendMode);
			if (blendState.HasValue)
				colorTargets[0] = .(colorFormat, blendState.Value);
			else
				colorTargets[0] = .(colorFormat);
			colorTargetCount = 1;
		}

		// Depth stencil
		DepthStencilState? depthStencil = null;
		if (depthFormat != .Undefined && config.DepthMode != .Disabled)
		{
			var ds = GetDepthStencilState(config);
			ds.Format = depthFormat;
			if (config.DepthBias != 0 || config.DepthBiasSlopeScale != 0)
			{
				ds.DepthBias = (int32)config.DepthBias;
				ds.DepthBiasSlopeScale = config.DepthBiasSlopeScale;
			}
			depthStencil = ds;
		}

		// Cull mode (variant overrides)
		CullMode cullMode = GetCullMode(config.CullMode);
		if (variantFlags.HasFlag(.BackFaceCull))
			cullMode = .Back;
		else if (variantFlags.HasFlag(.FrontFaceCull))
			cullMode = .Front;

		RenderPipelineDesc pipelineDesc = .()
		{
			Label = scope:: $"Pipeline: {shaderName} [{config.BlendMode}]",
			Layout = layout,
			Vertex = .()
			{
				Shader = .(vertShader.Module, "main"),
				Buffers = vertexBuffers
			},
			Fragment = hasColorTarget ? .()
			{
				Shader = .(fragShader.Module, "main"),
				Targets = Span<ColorTargetState>(&colorTargets[0], colorTargetCount)
			} : null,
			Primitive = .()
			{
				Topology = config.Topology,
				FrontFace = config.FrontFace,
				CullMode = cullMode
			},
			DepthStencil = depthStencil,
			Multisample = .()
			{
				Count = sampleCount,
				Mask = uint32.MaxValue
			}
		};

		switch (mDevice.CreateRenderPipeline(pipelineDesc))
		{
		case .Ok(let pipeline):
			return .Ok(pipeline);
		case .Err:
			return .Err;
		}
	}

	// ==================== State Helpers ====================

	public static BlendState? GetBlendState(BlendMode mode)
	{
		switch (mode)
		{
		case .Opaque:             return null;
		case .AlphaBlend:         return .AlphaBlend;
		case .Additive:           return .Additive;
		case .Multiply:           return .Multiply;
		case .PremultipliedAlpha: return .PremultipliedAlpha;
		}
	}

	public static DepthStencilState GetDepthStencilState(PipelineConfig config)
	{
		bool depthTest = false;
		bool depthWrite = false;

		switch (config.DepthMode)
		{
		case .Disabled:  break;
		case .ReadWrite: depthTest = true; depthWrite = true;
		case .ReadOnly:  depthTest = true; depthWrite = false;
		case .WriteOnly: depthTest = false; depthWrite = true;
		}

		return .()
		{
			DepthTestEnabled = depthTest,
			DepthWriteEnabled = depthWrite,
			DepthCompare = config.DepthCompare
		};
	}

	public static CullMode GetCullMode(CullModeConfig mode)
	{
		switch (mode)
		{
		case .None:  return .None;
		case .Back:  return .Back;
		case .Front: return .Front;
		}
	}
}
