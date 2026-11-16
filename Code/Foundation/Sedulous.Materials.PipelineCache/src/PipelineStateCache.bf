using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Sedulous.Materials.PipelineCache;

/// The render side pipeline cache: a pipeline config, the layout it draws through and the
/// target format it writes, mapped to a compiled render pipeline.
///
/// The one piece of the shader and material stack that sits OUTSIDE the resource system. A
/// pipeline is not content: it is derived from content, per render target signature, and it
/// has no identity anybody authors.
///
/// Reload is handled by VERSION POLLING at the point of use. Each entry records the shader
/// system's version of its shader when it was built, and a request compares that against
/// the current one, rebuilding lazily when a shader has been invalidated since. That costs
/// one lookup, a key compare and an integer compare per draw, and needs no listener
/// bookkeeping at all. A superseded pipeline goes to a graveyard rather than being freed,
/// because the frames still in flight are drawing with it; TickRetired frees it once they
/// have passed.
class PipelineStateCache
{
	/// One pipeline and the whole key it was built for. The config's name is a view into the
	/// entry's own copy, since the caller's view may point at storage that goes.
	private class Entry
	{
		public String ShaderName = new .() ~ delete _;
		public PipelineConfig Config;
		public IPipelineLayout Layout;
		public TextureFormat ColorOverride;
		/// Null when the build failed for this version of the shader.
		public IRenderPipeline Pipeline;
		public uint64 BuiltVersion;

		public bool Matches(PipelineConfig config, IPipelineLayout layout, TextureFormat colorOverride) =>
			(Layout === layout) && (ColorOverride == colorOverride) && (Config == config);
	}

	private struct Retired
	{
		public IRenderPipeline Pipeline;
		public uint32 FramesLeft;
	}

	private ShaderSystem mShaders;
	private IDevice mDevice;
	private uint32 mFramesInFlight;

	/// By the key's hash; each entry holds the whole key, so two configs whose hashes collide
	/// are two pipelines.
	private Dictionary<uint64, List<Entry>> mEntries = new .() ~ { for (let bucket in _) DeleteContainerAndItems!(bucket.value); delete _; };
	private int mCount;
	private uint64 mBuilds;
	private List<Retired> mRetired = new .() ~ delete _;

	/// Both are BORROWED and must outlive this. `framesInFlight`: how many frames a pipeline
	/// superseded by a reload is kept for (TickRetired), since frames still in flight may draw
	/// with it.
	public this(ShaderSystem shaderSystem, IDevice device, uint32 framesInFlight = 3)
	{
		mShaders = shaderSystem;
		mDevice = device;
		mFramesInFlight = (framesInFlight == 0) ? 1 : framesInFlight;
	}

	public ~this()
	{
		Clear();
		ReleaseRetired();
	}

	public int Size => mCount;
	public int RetiredCount => mRetired.Count;
	/// How many pipelines it has tried to build: a failure kept is not tried again.
	public uint64 BuildAttempts => mBuilds;

	/// The pipeline for this combination, built on first request and REBUILT when its
	/// shader has been reloaded since. Null when the build fails; a failure is kept, not
	/// tried again every draw, until the shader's version changes (an edit that may fix it).
	///
	/// `layout` is the assembled pipeline layout, which the caller owns. It takes part in
	/// the key by identity: two layouts describing the same thing are still two layouts as
	/// far as a pipeline is concerned.
	public IRenderPipeline GetPipeline(PipelineConfig config, IPipelineLayout layout,
		TextureFormat colorOverride = .Undefined)
	{
		let hash = KeyOf(config, layout, colorOverride);
		let version = mShaders.Version(config.ShaderName);

		List<Entry> bucket = null;
		if (mEntries.TryGetValue(hash, out bucket))
		{
			// Matched on the whole key, not the hash.
			for (let entry in bucket)
			{
				if (!entry.Matches(config, layout, colorOverride))
					continue;
				if (entry.BuiltVersion == version)
					return entry.Pipeline; // null: it failed for this version of the shader

				// The shader was reloaded since this was built. The stale pipeline is retired
				// rather than destroyed: frames in flight are still drawing with it.
				if (entry.Pipeline != null)
					mRetired.Add(.() { Pipeline = entry.Pipeline, FramesLeft = mFramesInFlight });
				entry.Pipeline = Build(config, layout, colorOverride);
				entry.BuiltVersion = version;
				return entry.Pipeline;
			}
		}
		else
		{
			bucket = new List<Entry>();
			mEntries[hash] = bucket;
		}

		let fresh = new Entry();
		fresh.ShaderName.Set(config.ShaderName);
		fresh.Config = config;
		fresh.Config.ShaderName = fresh.ShaderName; // its own copy, not the caller's storage
		fresh.Layout = layout;
		fresh.ColorOverride = colorOverride;
		fresh.Pipeline = Build(config, layout, colorOverride);
		fresh.BuiltVersion = version;
		bucket.Add(fresh);
		mCount++;
		return fresh.Pipeline;
	}

	/// Once a frame: frees the pipelines superseded by a reload whose frames in flight have
	/// all completed (framesInFlight of these ticks after).
	public void TickRetired()
	{
		for (int i = 0; i < mRetired.Count;)
		{
			if (mRetired[i].FramesLeft <= 1)
			{
				var pipeline = mRetired[i].Pipeline;
				if (pipeline != null)
					mDevice.DestroyRenderPipeline(ref pipeline);
				mRetired.RemoveAtFast(i);
			}
			else
			{
				mRetired[i].FramesLeft--;
				i++;
			}
		}
	}

	/// Frees every pipeline superseded by a reload now: the GPU is idle (shutdown, a test).
	public void ReleaseRetired()
	{
		for (let retired in mRetired)
		{
			var pipeline = retired.Pipeline;
			if (pipeline != null)
				mDevice.DestroyRenderPipeline(ref pipeline);
		}
		mRetired.Clear();
	}

	/// Destroys every live pipeline, retiring NOTHING. For shutdown, where there are no
	/// frames left to be in flight.
	public void Clear()
	{
		for (let bucket in mEntries)
		{
			for (let entry in bucket.value)
			{
				var pipeline = entry.Pipeline;
				if (pipeline != null)
					mDevice.DestroyRenderPipeline(ref pipeline);
			}
			DeleteContainerAndItems!(bucket.value);
		}
		mEntries.Clear();
		mCount = 0;
	}

	private static uint64 KeyOf(PipelineConfig config, IPipelineLayout layout,
		TextureFormat colorOverride)
	{
		// &* and &+, because this folds content and MUST be allowed to wrap.
		var hash = config.HashCode;
		hash = (hash &* 31) &+ (uint64)(int)(void*)Internal.UnsafeCastToPtr(layout);
		hash = (hash &* 31) &+ (uint64)colorOverride;
		return hash;
	}

	private IRenderPipeline Build(PipelineConfig config, IPipelineLayout layout,
		TextureFormat colorOverride)
	{
		mBuilds++;
		let vertexModule = mShaders.GetVariant(config.ShaderName,
			Sedulous.Shaders.ShaderStage.Vertex, config.ShaderFlags);
		if (vertexModule == null)
			return null;

		var desc = RenderPipelineDesc();
		desc.Layout = layout;
		desc.Label = config.ShaderName;

		// ---- vertex ----
		//
		// Up to three buffers, in the slot order the renderer binds them: the mesh stream
		// first; the skinning stream when skinned; the instance stepped offsets when
		// instanced: [mesh], [mesh, skin], [mesh, offsets] or [mesh, skin, offsets]. The
		// shaders pin their input locations, so each combination lines up.
		VertexBufferLayout[3] buffers = .();
		buffers[0] = VertexLayouts.BufferLayout(config.VertexLayout);
		var bufferCount = (config.VertexLayout != .None) ? 1 : 0;

		if (config.VertexLayout == .SkinnedMesh)
			buffers[bufferCount++] = VertexLayouts.SkinningStreamBufferLayout();
		if (config.Instanced)
			buffers[bufferCount++] = VertexLayouts.InstanceOffsetsBufferLayout();

		desc.Vertex.Shader = .(vertexModule, Sedulous.RHI.ShaderStage.Vertex);
		if (bufferCount > 0)
			desc.Vertex.Buffers = .(&buffers[0], bufferCount);

		// ---- fragment, omitted for a depth only pass ----
		ColorTargetState[RhiLimits.MaxColorAttachments] colorTargets = .();
		if (!config.DepthOnly)
		{
			let fragmentModule = mShaders.GetVariant(config.ShaderName,
				Sedulous.Shaders.ShaderStage.Fragment, config.ShaderFlags);
			if (fragmentModule == null)
				return null;

			// The target count is honoured EXACTLY, zero included: a masked shadow pass has
			// a fragment stage that discards and writes no colour at all. Falling back to
			// one would give it a target the pass does not have.
			let count = Min((int)config.ColorTargetCount, RhiLimits.MaxColorAttachments);
			for (int i = 0; i < count; i++)
			{
				// Target zero is the shaded colour, and takes the override when one is
				// given: that is how a per view HDR or LDR format reaches the pipeline.
				colorTargets[i].Format = ((i == 0) && (colorOverride != .Undefined))
					? colorOverride : config.ColorFormats[i];

				// Only target zero blends. The rest are G buffer outputs, which are values
				// rather than colour and have nothing to blend with.
				colorTargets[i].Blend = (i == 0) ? BlendFor(config.BlendMode) : null;

				// The auxiliary targets write only when the config says so. A transparent
				// draw still BINDS them, because the render pass declares them, but leaves
				// the opaque normal and velocity underneath intact.
				colorTargets[i].WriteMask = ((i == 0) || config.WriteAuxTargets)
					? config.ColorWriteMask : .None;
			}

			var fragment = FragmentState();
			fragment.Shader = .(fragmentModule, Sedulous.RHI.ShaderStage.Fragment);
			fragment.Targets = .(&colorTargets[0], count);
			desc.Fragment = fragment;
		}

		// ---- primitive ----
		desc.Primitive.Topology = config.Topology;
		desc.Primitive.FrontFace = config.FrontFace;
		desc.Primitive.CullMode = CullFor(config.CullMode);
		desc.Primitive.FillMode = config.FillMode;
		// Asked for and supported: without the device feature the flag is invalid, and the pass
		// clips as before.
		desc.Primitive.DepthClipEnabled = !(config.DepthClamp && mDevice.Features.DepthClamp);

		// ---- depth and stencil ----
		if (config.DepthMode != .Disabled)
		{
			var depthStencil = DepthStencilState();
			depthStencil.Format = config.DepthFormat;
			depthStencil.DepthTestEnabled = (config.DepthMode == .ReadWrite)
				|| (config.DepthMode == .ReadOnly);
			depthStencil.DepthWriteEnabled = (config.DepthMode == .ReadWrite)
				|| (config.DepthMode == .WriteOnly);
			depthStencil.DepthCompare = config.DepthCompare;
			depthStencil.DepthBias = config.DepthBias;
			depthStencil.DepthBiasSlopeScale = config.DepthBiasSlopeScale;
			desc.DepthStencil = depthStencil;
		}

		// ---- multisample ----
		desc.Multisample.Count = config.SampleCount;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;
		return pipeline;
	}

	/// NULL rather than a passthrough blend for the opaque modes: disabling blending lets
	/// the hardware skip reading the target entirely, which a blend that happens to be an
	/// identity does not.
	private static BlendState? BlendFor(BlendMode mode)
	{
		switch (mode)
		{
		case .Opaque, .Masked: return null;
		case .AlphaBlend: return BlendState.AlphaBlend;
		case .Additive: return BlendState.Additive;
		case .Multiply: return BlendState.Multiply;
		case .PremultipliedAlpha: return BlendState.PremultipliedAlpha;
		}
	}

	private static CullMode CullFor(CullModeConfig mode)
	{
		switch (mode)
		{
		case .None: return .None;
		case .Back: return .Back;
		case .Front: return .Front;
		}
	}
}
