using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Screen space projected decals: a sticker sprayed onto whatever the depth buffer says is
/// under the box.
///
/// The world position under each pixel is reconstructed from the scene's depth, transformed
/// into the decal's oriented unit box, clipped to it, and the decal's texture alpha blended
/// onto the lit scene. Reading the depth rather than the geometry is what lets a decal land on
/// a skinned mesh as readily as on a wall.
///
/// It runs after the forward and the sky and BEFORE the ambient occlusion and the temporal
/// resolve, so the decals are resolved along with everything else.
///
/// A decal draws a FULLSCREEN triangle rather than its own box: that is robust across a split
/// screen's sub rectangles and has no winding or culling to get wrong, and the box test lives
/// in the fragment shader anyway. The receiving surface's normal, which the angle fade needs,
/// comes from the derivatives of the reconstructed position.
class DecalPass
{
	/// What the scene is, and so what the decals blend into.
	public const TextureFormat cHdrFormat = .RGBA16Float;

	private const uint32 cRetireFrames = 3;
	/// The ring's capacity across all the frame's views, reserved once.
	private const uint32 cMaxDecalsPerFrame = 256;

	private struct Draw
	{
		public uint32 Offset;
		public ITextureView Texture;
	}

	private struct Retired
	{
		public IBindGroup BindGroup;
		public IRenderPipeline Pipeline;
		public uint32 FramesLeft;
	}

	/// Keyed by the view's address, but validated against its identity on every hit: a
	/// destroyed dynamic texture's address is reused, and the cached group would then be
	/// pointing at something else entirely.
	private struct TexBindGroup
	{
		public IBindGroup BindGroup;
		public uint64 ViewId;
	}

	private IDevice mDevice;
	private ShaderSystem mShaders;
	private DynamicUniformRing mDecalRing ~ delete _;

	private IBindGroupLayout mDepthLayout = null;
	private IBindGroupLayout mUboLayout = null;
	private IBindGroupLayout mTexLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	/// What the scene pass's sample count was when the cached pipeline was built.
	private uint32 mPipelineSampleCount = 1;
	private uint64 mPipelineShaderVersion = 0;

	private ISampler mDepthSampler = null;
	private ISampler mTexSampler = null;

	private IBindGroup mUboBindGroup = null;
	private uint32 mUboBindGroupGeneration = 0xFFFFFFFF;
	private IBindGroup mDepthBindGroup = null;
	private ITextureView mDepthView = null;
	private uint64 mDepthGeneration = 0;

	private uint32 mLastFrame = 0xFFFFFFFF;
	private bool mReserved = false;
	private List<Retired> mRetired = new .() ~ delete _;
	private Dictionary<int, TexBindGroup> mTexBindGroups = new .() ~ delete _;

	/// This frame's draws, ACROSS all its views. A pass records a range of it, and the ring's
	/// slots are only read once the whole graph executes, so a per view list would be gone by
	/// then and a shared one clobbered.
	private List<Draw> mDraws = new .() ~ delete _;

	public this(IDevice device, ShaderSystem shaders, uint32 framesInFlight)
	{
		mDevice = device;
		mShaders = shaders;
		mDecalRing = new .(device, framesInFlight,
			(sizeof(DecalUniforms) <= 256) ? 256 : 512,
			.Uniform | .CopyDst, "decal.uniforms");
	}

	public ~this()
	{
		Shutdown();
	}

	public Result<void> Initialize()
	{
		// Group nought is the scene's depth and its sampler; group one the per decal
		// constants, at a dynamic offset; group two the decal's own texture.
		var depthEntries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		// The depth is read as DATA through the point sampler, so it is declared unfilterable
		// and that sampler non filtering.
		depthEntries[0].TextureSampleType = .UnfilterableFloat;
		depthEntries[1].SamplerNonFiltering = true;

		var depthLayoutDesc = BindGroupLayoutDesc();
		depthLayoutDesc.Entries = .(&depthEntries[0], 2);
		if (!(mDevice.CreateBindGroupLayout(depthLayoutDesc) case .Ok(let depthLayout)))
			return .Err;
		mDepthLayout = depthLayout;

		var uboEntry = BindGroupLayoutEntry.UniformBuffer(0, .Fragment);
		uboEntry.HasDynamicOffset = true;

		var uboLayoutDesc = BindGroupLayoutDesc();
		uboLayoutDesc.Entries = .(&uboEntry, 1);
		if (!(mDevice.CreateBindGroupLayout(uboLayoutDesc) case .Ok(let uboLayout)))
			return .Err;
		mUboLayout = uboLayout;

		var texEntries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		var texLayoutDesc = BindGroupLayoutDesc();
		texLayoutDesc.Entries = .(&texEntries[0], 2);
		if (!(mDevice.CreateBindGroupLayout(texLayoutDesc) case .Ok(let texLayout)))
			return .Err;
		mTexLayout = texLayout;

		var layouts = IBindGroupLayout[3](mDepthLayout, mUboLayout, mTexLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 3);
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		mDepthSampler = MakeSampler(.Nearest);
		mTexSampler = MakeSampler(.Linear);
		if ((mDepthSampler == null) || (mTexSampler == null))
			return .Err;

		// Single sampled to begin with, and rebuilt for multisampling when a view asks.
		mPipeline = MakePipeline(1);
		if (mPipeline == null)
			return .Err;

		return .Ok;
	}

	/// Brackets the FRAME, not the view. The ring must not be reset per view: a view records
	/// its own slots but the GPU only reads them once the whole graph executes, so a reset
	/// would leave every view reading the last one's matrix, and the decals would swim.
	public void BeginFrame(uint32 frameIndex)
	{
		Tick(frameIndex);
		if (!mReserved)
			mReserved = mDecalRing.Reserve(cMaxDecalsPerFrame);
		mDecalRing.BeginFrame(frameIndex);
		mDraws.Clear();
	}

	public void EndFrame()
	{
		mDecalRing.EndFrame();
	}

	/// Blends the scene's decals into one view. The view projection given is this view's own,
	/// jitter and all, since its inverse is what reconstructs the world position.
	public void DeclareDecals(RenderGraph graph, RGHandle hdr, RGHandle depth,
		Span<DecalInstance> decals, Float4x4 viewProj, uint32 width, uint32 height,
		int32 viewportX, int32 viewportY, uint32 viewportWidth, uint32 viewportHeight,
		uint32 samples = 1)
	{
		if (decals.IsEmpty || (width == 0) || (height == 0) || (mDecalRing.Buffer == null))
			return;

		let sampleCount = (samples == 0) ? (uint32)1 : samples;

		// A shader reload or a change of sample count rebuilds the pipeline: the decals draw
		// into the scene's own target, so the two must agree on how many samples it has.
		let shaderVersion = mShaders.Version("decal");
		if ((shaderVersion != mPipelineShaderVersion) || (sampleCount != mPipelineSampleCount))
		{
			if (mPipeline != null)
			{
				// A rare rebuild, but the old pipeline may still be referenced by a command
				// buffer in flight, so retire it rather than idling the device here.
				mRetired.Add(.() { Pipeline = mPipeline, FramesLeft = cRetireFrames });
			}
			mPipeline = MakePipeline(sampleCount);
			mPipelineShaderVersion = shaderVersion;
			mPipelineSampleCount = sampleCount;
		}

		if (mPipeline == null)
			return;

		let invViewProj = Inverse(viewProj);
		let invSize = Float2(1.0f / (float)width, 1.0f / (float)height);

		let first = mDraws.Count;
		for (let decal in decals)
		{
			if (decal.Texture == null)
				continue;

			let range = mDecalRing.Allocate();
			if (!range.Ok)
				break;

			var uniforms = DecalUniforms();
			uniforms.World = decal.World;
			uniforms.InvWorld = Inverse(decal.World);
			uniforms.InvViewProj = invViewProj;
			uniforms.Color = .(decal.Color.R, decal.Color.G, decal.Color.B, decal.Color.A);
			uniforms.Params = .(invSize.X, invSize.Y, Cos(decal.FadeStart), Cos(decal.FadeEnd));
			// The vertical correction: under a negative viewport the emitted coordinates
			// already land on the right pixel, so the interpolant passes through untouched;
			// a flipped target mirrors it, and the negative sign un-mirrors it.
			uniforms.Flip = .(mDevice.NeedsClipSpaceYFlip ? -1.0f : 1.0f, 0.0f, 0.0f, 0.0f);
			Internal.MemCpy(range.Ptr, &uniforms, sizeof(DecalUniforms));

			mDraws.Add(.() { Offset = range.ByteOffset, Texture = decal.Texture });
		}

		let count = mDraws.Count - first;
		if (count == 0)
			return;

		let uboBindGroup = EnsureUboBindGroup();

		graph.AddRenderPass("decal", scope [&] (builder) =>
			{
				builder.SetColorTarget(0, hdr, .Load, .Store, .Black);
				builder.ReadTexture(depth);
				// The view's own sub rectangle, matching the forward and the sky, so the
				// fullscreen triangle's coordinates line up with the geometry's at each pixel.
				builder.SetViewport(viewportX, viewportY, viewportWidth, viewportHeight);
				builder.NeverCull();

				builder.SetExecute(new [=] (encoder) =>
					{
						let depthBindGroup = EnsureDepthBindGroup(graph.GetTextureView(depth),
							graph.GetTextureGeneration(depth));
						if ((depthBindGroup == null) || (uboBindGroup == null))
							return;

						encoder.SetPipeline(mPipeline);
						encoder.SetBindGroup(0, depthBindGroup);

						for (int i = first; i < first + count; i++)
						{
							let texBindGroup = EnsureTextureBindGroup(mDraws[i].Texture);
							if (texBindGroup == null)
								continue;

							var offset = mDraws[i].Offset;
							encoder.SetBindGroup(1, uboBindGroup, .(&offset, 1));
							encoder.SetBindGroup(2, texBindGroup);
							encoder.Draw(3, 1, 0, 0);
						}
					});
			});
	}

	/// Wires the retire queue the ring hands its outgrown buffers to. Null drains instead.
	public void SetRetireQueue(GpuRetireQueue retire)
	{
		mDecalRing.SetRetireQueue(retire);
	}

	private ISampler MakeSampler(FilterMode filter)
	{
		var desc = SamplerDesc();
		desc.MinFilter = filter;
		desc.MagFilter = filter;
		desc.MipmapFilter = (filter == .Nearest) ? MipmapFilterMode.Nearest : .Linear;
		desc.AddressU = .ClampToEdge;
		desc.AddressV = .ClampToEdge;
		desc.AddressW = .ClampToEdge;

		if (!(mDevice.CreateSampler(desc) case .Ok(let sampler)))
			return null;
		return sampler;
	}

	private IRenderPipeline MakePipeline(uint32 samples)
	{
		let vertex = mShaders.GetVariant("decal", .Vertex, .None);
		let fragment = mShaders.GetVariant("decal", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return null;

		var color = ColorTargetState();
		color.Format = cHdrFormat;
		color.Blend = BlendState.AlphaBlend;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&color, 1);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = .TriangleList;
		// A fullscreen triangle, with no depth attachment of its own.
		desc.Primitive.CullMode = .None;
		desc.Multisample.Count = samples;
		desc.Label = "decal";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;
		return pipeline;
	}

	/// One group over the whole ring, the decal chosen by a dynamic offset. It is only rebuilt
	/// when the ring itself is reallocated, which drains the device first, so it can never
	/// free a set still in flight.
	private IBindGroup EnsureUboBindGroup()
	{
		let generation = mDecalRing.Generation;
		if ((mUboBindGroup != null) && (mUboBindGroupGeneration == generation))
			return mUboBindGroup;

		if (mUboBindGroup != null)
			mDevice.DestroyBindGroup(ref mUboBindGroup);

		if (mDecalRing.Buffer == null)
			return null;

		var entry = BindGroupEntry.BufferEntry(mDecalRing.Buffer, 0, mDecalRing.SlotSize);

		var desc = BindGroupDesc();
		desc.Layout = mUboLayout;
		desc.Entries = .(&entry, 1);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mUboBindGroup = bindGroup;
		mUboBindGroupGeneration = generation;
		return mUboBindGroup;
	}

	/// Keyed by the view AND its generation, with a deferred free: the depth transient is
	/// aliased and recreated, so a cache keyed on the address alone would free a set a frame
	/// in flight is still reading.
	private IBindGroup EnsureDepthBindGroup(ITextureView depth, uint64 generation)
	{
		if (depth == null)
			return null;

		if ((mDepthBindGroup != null) && (mDepthView == depth) && (mDepthGeneration == generation))
			return mDepthBindGroup;

		if (mDepthBindGroup != null)
		{
			mRetired.Add(.() { BindGroup = mDepthBindGroup, FramesLeft = cRetireFrames });
			mDepthBindGroup = null;
		}

		var entries = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(depth),
			BindGroupEntry.SamplerEntry(mDepthSampler));

		var desc = BindGroupDesc();
		desc.Layout = mDepthLayout;
		desc.Entries = .(&entries[0], 2);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mDepthBindGroup = bindGroup;
		mDepthView = depth;
		mDepthGeneration = generation;
		return mDepthBindGroup;
	}

	private IBindGroup EnsureTextureBindGroup(ITextureView texture)
	{
		if (texture == null)
			return null;

		let key = (int)(void*)Internal.UnsafeCastToPtr(texture);
		if (mTexBindGroups.TryGetValue(key, let existing))
		{
			if (existing.ViewId == texture.UniqueId)
				return existing.BindGroup;

			// The address was reused: the cached group points at a DESTROYED view.
			var stale = existing.BindGroup;
			if (stale != null)
				mDevice.DestroyBindGroup(ref stale);
			mTexBindGroups.Remove(key);
		}

		var entries = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(texture),
			BindGroupEntry.SamplerEntry(mTexSampler));

		var desc = BindGroupDesc();
		desc.Layout = mTexLayout;
		desc.Entries = .(&entries[0], 2);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mTexBindGroups[key] = .() { BindGroup = bindGroup, ViewId = texture.UniqueId };
		return bindGroup;
	}

	private void Tick(uint32 frameIndex)
	{
		if (frameIndex == mLastFrame)
			return;

		mLastFrame = frameIndex;
		for (int i = mRetired.Count - 1; i >= 0; i--)
		{
			var retired = mRetired[i];
			if (retired.FramesLeft <= 1)
			{
				if (retired.BindGroup != null)
					mDevice.DestroyBindGroup(ref retired.BindGroup);
				if (retired.Pipeline != null)
					mDevice.DestroyRenderPipeline(ref retired.Pipeline);
				mRetired.RemoveAt(i);
				continue;
			}

			retired.FramesLeft--;
			mRetired[i] = retired;
		}
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (var entry in ref mTexBindGroups.Values)
		{
			if (entry.BindGroup != null)
				mDevice.DestroyBindGroup(ref entry.BindGroup);
		}
		mTexBindGroups.Clear();

		for (var retired in ref mRetired)
		{
			if (retired.BindGroup != null)
				mDevice.DestroyBindGroup(ref retired.BindGroup);
			if (retired.Pipeline != null)
				mDevice.DestroyRenderPipeline(ref retired.Pipeline);
		}
		mRetired.Clear();

		if (mDepthBindGroup != null)
			mDevice.DestroyBindGroup(ref mDepthBindGroup);
		if (mUboBindGroup != null)
			mDevice.DestroyBindGroup(ref mUboBindGroup);
		if (mPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mTexSampler != null)
			mDevice.DestroySampler(ref mTexSampler);
		if (mDepthSampler != null)
			mDevice.DestroySampler(ref mDepthSampler);
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mTexLayout != null)
			mDevice.DestroyBindGroupLayout(ref mTexLayout);
		if (mUboLayout != null)
			mDevice.DestroyBindGroupLayout(ref mUboLayout);
		if (mDepthLayout != null)
			mDevice.DestroyBindGroupLayout(ref mDepthLayout);
	}
}
