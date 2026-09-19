using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Particles;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Sedulous.Engine.Particles;

/// Draws particles: batched billboards, and trail ribbons.
///
/// Both kinds ride ONE renderer id and are told apart by their kind, which is what keeps a
/// second copy of this whole pipeline set from existing for what is a branch.
///
/// Particles register for the TRANSPARENT category, so they interleave with transparent meshes
/// by depth in the blended forward pass: depth tested against the scene but never written, and
/// never culled.
///
/// A BATCH is one draw item holding many instances, unlike the sprite path's item per sprite.
/// A particle count would otherwise flood the draw list's sort.
class ParticleRenderer : Renderer
{
	private const uint32 cMaxViews = 8;
	/// Two matrices and a vector, padded up to the dynamic uniform alignment.
	private const uint64 cViewSlotSize = 256;
	/// The identity index buffer's cap, which is the largest single ribbon.
	private const uint32 cTrailMaxIndices = 262144;
	/// The soft dot's edge, in pixels.
	private const uint32 cDotSize = 64;
	/// One pipeline per blend mode. The enum carries no count of its own, so this is the
	/// single place that has to grow when a mode is added.
	private const int cBlendModeCount = 4;

	/// Keyed by the view's address, but validated against its identity on every hit: a
	/// destroyed view's address is handed straight back to the next allocation, and the cached
	/// group would then be sampling a dead image.
	private struct TexBindGroup
	{
		public IBindGroup BindGroup;
		public uint64 ViewId;
	}

	/// A scene depth group and the frame it was made on, so it outlives every frame that
	/// could still be referencing it.
	private struct PendingBindGroup
	{
		public IBindGroup BindGroup;
		public uint64 Frame;
	}

	/// The view's two matrices and the depth reconstruction coefficients, as the shader reads
	/// them.
	[CRepr]
	private struct ViewUniforms
	{
		public Float4x4 ViewProj;
		public Float4x4 View;
		/// The projection terms that turn a sampled depth back into a view space one. The
		/// fourth lane is unused: the soft fade distance rides each instance.
		public Float4 DepthParams;
	}

	private static uint16[1] sCategories = .(RenderCategories.Transparent);

	private IDevice mDevice;
	private ShaderSystem mShaders;
	private uint32 mFramesInFlight;

	private DynamicUniformRing mInstanceRing ~ delete _;
	private DynamicUniformRing mTrailRing ~ delete _;
	private DynamicUniformRing mViewRing ~ delete _;

	private IBindGroupLayout mViewLayout = null;
	private IBindGroupLayout mTexLayout = null;
	private IBindGroupLayout mDepthLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private IPipelineLayout mTrailPipelineLayout = null;
	private ISampler mSampler = null;
	private IBuffer mIndexBuffer = null;
	private IBuffer mTrailIndexBuffer = null;

	/// The fallback: a soft radial dot, so an untextured particle reads as a glowing spark
	/// rather than a hard square.
	private ITexture mWhiteTexture = null;
	private ITextureView mWhiteView = null;

	private IBindGroup mViewBindGroup = null;
	private uint32 mViewBindGroupGeneration = 0xFFFFFFFF;

	private Dictionary<int, TexBindGroup> mTexBindGroups = new .() ~ delete _;
	private List<PendingBindGroup> mDepthPending = new .() ~ delete _;
	private uint64 mFrameCounter = 0;

	private ParticlePipelineEntry[cBlendModeCount] mBillboard = .();
	private ParticlePipelineEntry[cBlendModeCount] mTrail = .();

	private TextureFormat mDepthFormat = .Depth32Float;

	// The ring sizing: a batch is one ITEM holding many INSTANCES, and every system allocates
	// from the one ring within a frame, since the cursor only resets at the frame's end. So
	// the size follows the frame's SUM rather than its largest single system, or the systems
	// later in the sorted list fail to allocate and simply vanish.
	private uint32 mFrameInstances = 0;
	private uint32 mFrameTrailVertices = 0;
	private uint32 mMaxInstancesSeen = 0;
	private uint32 mMaxTrailVerticesSeen = 0;

	public this(IDevice device, ShaderSystem shaders, uint32 framesInFlight)
	{
		mDevice = device;
		mShaders = shaders;
		mFramesInFlight = (framesInFlight < 1) ? 1 : framesInFlight;

		mInstanceRing = new .(device, framesInFlight, sizeof(ParticleBillboardInstance),
			.Vertex | .CopyDst, "particle.instances");
		mTrailRing = new .(device, framesInFlight, sizeof(TrailVertex),
			.Vertex | .CopyDst, "particle.trailverts");
		mViewRing = new .(device, framesInFlight, cViewSlotSize,
			.Uniform | .CopyDst, "particle.view");
	}

	public ~this()
	{
		Shutdown();
	}

	public Result<void> Initialize()
	{
		// Group nought is the view's constants at a dynamic offset, group one the texture and
		// its sampler, and group two the opaque scene depth the soft fade reads.
		var viewEntry = BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment);
		viewEntry.HasDynamicOffset = true;

		var viewLayoutDesc = BindGroupLayoutDesc();
		viewLayoutDesc.Entries = .(&viewEntry, 1);
		if (!(mDevice.CreateBindGroupLayout(viewLayoutDesc) case .Ok(let viewLayout)))
			return .Err;
		mViewLayout = viewLayout;

		var texEntries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		var texLayoutDesc = BindGroupLayoutDesc();
		texLayoutDesc.Entries = .(&texEntries[0], 2);
		if (!(mDevice.CreateBindGroupLayout(texLayoutDesc) case .Ok(let texLayout)))
			return .Err;
		mTexLayout = texLayout;

		var depthEntry = BindGroupLayoutEntry.SampledTexture(0, .Fragment);
		// The DEPTH view is read as data rather than filtered. The web backend needs saying
		// so; the others ignore it.
		depthEntry.TextureSampleType = .UnfilterableFloat;

		var depthLayoutDesc = BindGroupLayoutDesc();
		depthLayoutDesc.Entries = .(&depthEntry, 1);
		if (!(mDevice.CreateBindGroupLayout(depthLayoutDesc) case .Ok(let depthLayout)))
			return .Err;
		mDepthLayout = depthLayout;

		var layouts = IBindGroupLayout[3](mViewLayout, mTexLayout, mDepthLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 3);
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		// The ribbons carry no depth set, so they get their own two group layout.
		var trailLayouts = IBindGroupLayout[2](mViewLayout, mTexLayout);
		var trailLayoutDesc = PipelineLayoutDesc();
		trailLayoutDesc.BindGroupLayouts = .(&trailLayouts[0], 2);
		if (!(mDevice.CreatePipelineLayout(trailLayoutDesc) case .Ok(let trailPipelineLayout)))
			return .Err;
		mTrailPipelineLayout = trailPipelineLayout;

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;

		if (CreateQuadIndices() case .Err)
			return .Err;
		if (CreateTrailIndices() case .Err)
			return .Err;
		if (CreateSoftDot() case .Err)
			return .Err;

		return .Ok;
	}

	public override Span<uint16> SupportedCategories => .(&sCategories[0], 1);

	public override void PrepareFrame(uint32 maxDraws, uint32 frameIndex)
	{
		// Rounded up in chunks, so growth ramps for one frame and then holds: a ring cannot
		// grow mid frame.
		const uint32 cChunk = 8192;
		let want = (uint32)Math.Max(maxDraws, ((mMaxInstancesSeen + cChunk - 1) / cChunk) * cChunk);
		mInstanceRing.Reserve((want == 0) ? 1 : want);

		let trailWant = ((mMaxTrailVerticesSeen + cChunk - 1) / cChunk) * cChunk;
		mTrailRing.Reserve((trailWant == 0) ? 1 : (uint32)trailWant);

		mViewRing.Reserve(cMaxViews);

		mInstanceRing.BeginFrame(frameIndex);
		mTrailRing.BeginFrame(frameIndex);
		mViewRing.BeginFrame(frameIndex);

		mFrameInstances = 0;
		mFrameTrailVertices = 0;

		// Retire the depth groups made far enough back that no frame still in flight can be
		// referencing them.
		mFrameCounter++;
		var keep = 0;
		for (int i = 0; i < mDepthPending.Count; i++)
		{
			if (mFrameCounter >= (mDepthPending[i].Frame + mFramesInFlight))
				mDevice.DestroyBindGroup(ref mDepthPending[i].BindGroup);
			else
				mDepthPending[keep++] = mDepthPending[i];
		}
		mDepthPending.Count = keep;
	}

	public override void Resolve(RenderRecordContext context, Span<DrawItem> items,
		List<ResolvedDraw> outDraws)
	{
		if (items.IsEmpty)
			return;

		// Match the blended pass's own depth attachment, which the pipeline must agree with.
		mDepthFormat = context.DepthFormat;

		let viewBindGroup = EnsureViewBindGroup();
		if (viewBindGroup == null)
			return;

		let viewRange = mViewRing.Allocate();
		if (!viewRange.Ok)
			return;

		let projection = (context.View != null) ? context.View.Camera.Projection : Float4x4.Identity();

		var viewUniforms = ViewUniforms();
		viewUniforms.ViewProj = context.ViewProj;
		viewUniforms.View = context.ViewMatrix;
		viewUniforms.DepthParams = .(projection.M[2][2], projection.M[3][2], projection.M[2][3],
			0.0f);
		Internal.MemCpy(viewRange.Ptr, &viewUniforms, sizeof(ViewUniforms));

		// The scene depth the soft fade reads. The transparent pass hands over the opaque
		// depth already in a readable state; with none, the fallback stands in so the set is
		// still complete and the shader simply finds nothing to fade against.
		let depthBindGroup = AcquireDepthBindGroup((context.SceneDepthView != null)
			? context.SceneDepthView : mWhiteView);
		if (depthBindGroup == null)
			return;

		var i = 0;
		while (i < items.Length)
		{
			let head = (ParticleRenderDataBase)items[i].Data;

			if (head.ParticleKind == 1)
			{
				EmitTrailDraw(context, (ParticleTrailRenderData)head, viewBindGroup, viewRange,
					outDraws);
				i++;
				continue;
			}

			// Consecutive billboards sharing a texture and a blend mode fuse into one
			// instanced draw.
			let batch = (ParticleBillboardRenderData)head;
			var j = i + 1;
			var total = batch.Count;
			while (j < items.Length)
			{
				let next = (ParticleRenderDataBase)items[j].Data;
				if (next.ParticleKind != 0)
					break;

				let candidate = (ParticleBillboardRenderData)next;
				if ((candidate.Texture !== batch.Texture) || (candidate.Blend != batch.Blend))
					break;

				total += candidate.Count;
				j++;
			}

			if (total > 0)
				EmitBillboardDraw(context, items, i, j, total, batch, viewBindGroup, viewRange,
					depthBindGroup, outDraws);

			i = j;
		}
	}

	public override void FinishFrame()
	{
		mMaxInstancesSeen = Math.Max(mMaxInstancesSeen, mFrameInstances);
		mMaxTrailVerticesSeen = Math.Max(mMaxTrailVerticesSeen, mFrameTrailVertices);

		mInstanceRing.EndFrame();
		mTrailRing.EndFrame();
		mViewRing.EndFrame();
	}

	/// Wires the render subsystem's retire queue in, so a ring RETIRES its old buffer when it
	/// grows rather than idling the GPU mid frame.
	public void SetRetireQueue(GpuRetireQueue retire)
	{
		mInstanceRing.SetRetireQueue(retire);
		mTrailRing.SetRetireQueue(retire);
		mViewRing.SetRetireQueue(retire);
	}

	private void EmitBillboardDraw(RenderRecordContext context, Span<DrawItem> items, int first,
		int last, uint32 total, ParticleBillboardRenderData head, IBindGroup viewBindGroup,
		DynamicUniformRange viewRange, IBindGroup depthBindGroup, List<ResolvedDraw> outDraws)
	{
		// The frame's SUM is what sizes the ring next frame.
		mFrameInstances += total;

		let range = mInstanceRing.AllocateRange(total);
		if (!range.Ok)
			return;

		var destination = (ParticleBillboardInstance*)range.Ptr;
		uint32 written = 0;
		for (int k = first; k < last; k++)
		{
			let batch = (ParticleBillboardRenderData)items[k].Data;
			if ((batch.Count == 0) || (batch.Instances == null))
				continue;

			Internal.MemCpy(destination + written, batch.Instances,
				(int)batch.Count * sizeof(ParticleBillboardInstance));
			written += batch.Count;
		}

		if (written == 0)
			return;

		let pso = EnsurePipeline(context.ColorFormat, head.Blend);
		let texBindGroup = EnsureTextureBindGroup((head.Texture != null) ? head.Texture
			: mWhiteView);
		if ((pso == null) || (texBindGroup == null))
			return;

		var draw = ResolvedDraw();
		draw.Pso = pso;
		draw.ViewSet = viewBindGroup;
		draw.ViewDynamic = true;
		draw.ViewOffset = (uint32)viewRange.ByteOffset;
		draw.DrawSet = texBindGroup;
		draw.MaterialSet = depthBindGroup;
		draw.VertexBuffer0 = mInstanceRing.Buffer;
		draw.VertexOffset0 = range.ByteOffset;
		draw.IndexBuffer = mIndexBuffer;
		draw.IndexFormat = .UInt16;
		draw.IndexCount = 6;
		draw.InstanceCount = written;
		outDraws.Add(draw);
	}

	/// One system's ribbon: upload its already oriented vertices and draw them as a triangle
	/// list through the identity index buffer, a resolved draw always being indexed.
	private void EmitTrailDraw(RenderRecordContext context, ParticleTrailRenderData batch,
		IBindGroup viewBindGroup, DynamicUniformRange viewRange, List<ResolvedDraw> outDraws)
	{
		if ((batch.VertexCount == 0) || (batch.Vertices == null))
			return;

		let count = (uint32)Math.Min(batch.VertexCount, cTrailMaxIndices);
		mFrameTrailVertices += count;

		let range = mTrailRing.AllocateRange(count);
		if (!range.Ok)
			return;

		Internal.MemCpy(range.Ptr, batch.Vertices, (int)count * sizeof(TrailVertex));

		let pso = EnsureTrailPipeline(context.ColorFormat, batch.Blend);
		let texBindGroup = EnsureTextureBindGroup((batch.Texture != null) ? batch.Texture
			: mWhiteView);
		if ((pso == null) || (texBindGroup == null))
			return;

		var draw = ResolvedDraw();
		draw.Pso = pso;
		draw.ViewSet = viewBindGroup;
		draw.ViewDynamic = true;
		draw.ViewOffset = (uint32)viewRange.ByteOffset;
		draw.DrawSet = texBindGroup;
		draw.VertexBuffer0 = mTrailRing.Buffer;
		draw.VertexOffset0 = range.ByteOffset;
		draw.IndexBuffer = mTrailIndexBuffer;
		draw.IndexFormat = .UInt32;
		draw.IndexCount = count;
		draw.InstanceCount = 1;
		outDraws.Add(draw);
	}

	private IBindGroup EnsureViewBindGroup()
	{
		let generation = mViewRing.Generation;
		if ((mViewBindGroup != null) && (mViewBindGroupGeneration == generation))
			return mViewBindGroup;

		if (mViewBindGroup != null)
			mDevice.DestroyBindGroup(ref mViewBindGroup);

		if (mViewRing.Buffer == null)
			return null;

		var entry = BindGroupEntry.BufferEntry(mViewRing.Buffer, 0, cViewSlotSize);
		var desc = BindGroupDesc();
		desc.Layout = mViewLayout;
		desc.Entries = .(&entry, 1);
		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mViewBindGroup = bindGroup;
		mViewBindGroupGeneration = generation;
		return mViewBindGroup;
	}

	/// A FRESH group over the scene depth each resolve, tracked for deferred destruction so a
	/// frame still in flight never references a freed set. One group a resolve is cheap.
	private IBindGroup AcquireDepthBindGroup(ITextureView depth)
	{
		if (depth == null)
			return null;

		var entry = BindGroupEntry.TextureEntry(depth);
		var desc = BindGroupDesc();
		desc.Layout = mDepthLayout;
		desc.Entries = .(&entry, 1);
		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mDepthPending.Add(.() { BindGroup = bindGroup, Frame = mFrameCounter });
		return bindGroup;
	}

	private IBindGroup EnsureTextureBindGroup(ITextureView texture)
	{
		if (texture == null)
			return null;

		let key = (int)(void*)Internal.UnsafeCastToPtr(texture);
		if (mTexBindGroups.TryGetValue(key, let found))
		{
			if (found.ViewId == texture.UniqueId)
				return found.BindGroup;

			// The address was reused: the cached group names a DESTROYED view, so rebuild.
			var stale = found.BindGroup;
			if (stale != null)
				mDevice.DestroyBindGroup(ref stale);
			mTexBindGroups.Remove(key);
		}

		var entries = BindGroupEntry[2](BindGroupEntry.TextureEntry(texture),
			BindGroupEntry.SamplerEntry(mSampler));
		var desc = BindGroupDesc();
		desc.Layout = mTexLayout;
		desc.Entries = .(&entries[0], 2);
		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mTexBindGroups[key] = .() { BindGroup = bindGroup, ViewId = texture.UniqueId };
		return bindGroup;
	}

	/// Additive keeps the particle's own source alpha factor rather than the plain one the RHI
	/// offers: an un premultiplied soft dot still reads as a glow instead of blowing out.
	private static BlendState BlendFor(ParticleBlendMode mode)
	{
		switch (mode)
		{
		case .Additive:
			var state = BlendState();
			state.Color = .(.SrcAlpha, .One, .Add);
			state.Alpha = .(.One, .One, .Add);
			return state;
		case .Premultiplied: return BlendState.PremultipliedAlpha;
		case .Multiply: return BlendState.Multiply;
		default: return BlendState.AlphaBlend;
		}
	}

	private static StringView BlendLabel(ParticleBlendMode mode)
	{
		switch (mode)
		{
		case .Additive: return "particle.additive";
		case .Premultiplied: return "particle.premultiplied";
		case .Multiply: return "particle.multiply";
		default: return "particle.alpha";
		}
	}

	private IRenderPipeline EnsurePipeline(TextureFormat colorFormat, ParticleBlendMode mode)
	{
		var entry = ref mBillboard[(int)mode];
		// A reload bumps the version, which is what rebuilds a stale pipeline.
		let shaderVersion = mShaders.Version("particle");
		if ((entry.Pso != null) && (entry.Format == colorFormat)
			&& (entry.ShaderVersion == shaderVersion))
			return entry.Pso;

		if (entry.Pso != null)
			mDevice.DestroyRenderPipeline(ref entry.Pso);

		let vs = mShaders.GetVariant("particle", .Vertex, .None);
		let ps = mShaders.GetVariant("particle", .Fragment, .None);
		if ((vs == null) || (ps == null))
			return null;

		var attributes = VertexAttribute[5](
			.(.Float32x4, 0, 0),
			.(.Float32x4, 16, 1),
			.(.Float32x4, 32, 2),
			.(.Float32x4, 48, 3),
			.(.Float32x4, 64, 4));

		var layout = VertexBufferLayout();
		layout.Stride = sizeof(ParticleBillboardInstance);
		layout.StepMode = .Instance;
		layout.Attributes = .(&attributes[0], 5);

		let pso = CreatePipeline(mPipelineLayout, vs, ps, ref layout, colorFormat, mode);
		if (pso == null)
			return null;

		entry.Pso = pso;
		entry.Format = colorFormat;
		entry.ShaderVersion = shaderVersion;
		return pso;
	}

	private IRenderPipeline EnsureTrailPipeline(TextureFormat colorFormat, ParticleBlendMode mode)
	{
		var entry = ref mTrail[(int)mode];
		let shaderVersion = mShaders.Version("particletrail");
		if ((entry.Pso != null) && (entry.Format == colorFormat)
			&& (entry.ShaderVersion == shaderVersion))
			return entry.Pso;

		if (entry.Pso != null)
			mDevice.DestroyRenderPipeline(ref entry.Pso);

		let vs = mShaders.GetVariant("particletrail", .Vertex, .None);
		let ps = mShaders.GetVariant("particletrail", .Fragment, .None);
		if ((vs == null) || (ps == null))
			return null;

		var attributes = VertexAttribute[3](
			.(.Float32x3, 0, 0),
			.(.Float32x2, 12, 1),
			.(.Float32x4, 20, 2));

		var layout = VertexBufferLayout();
		layout.Stride = sizeof(TrailVertex);
		layout.StepMode = .Vertex;
		layout.Attributes = .(&attributes[0], 3);

		let pso = CreatePipeline(mTrailPipelineLayout, vs, ps, ref layout, colorFormat, mode);
		if (pso == null)
			return null;

		entry.Pso = pso;
		entry.Format = colorFormat;
		entry.ShaderVersion = shaderVersion;
		return pso;
	}

	/// What both pipelines share: blended, depth tested against the scene but never writing to
	/// it, and never culled.
	private IRenderPipeline CreatePipeline(IPipelineLayout pipelineLayout, IShaderModule vs,
		IShaderModule ps, ref VertexBufferLayout vertexLayout, TextureFormat colorFormat,
		ParticleBlendMode mode)
	{
		var target = ColorTargetState();
		target.Format = colorFormat;
		target.Blend = BlendFor(mode);

		var fragment = FragmentState();
		fragment.Shader = .(ps, "main", .Fragment);
		fragment.Targets = .(&target, 1);

		var depthStencil = DepthStencilState();
		depthStencil.Format = mDepthFormat;
		depthStencil.DepthTestEnabled = true;
		depthStencil.DepthWriteEnabled = false;
		depthStencil.DepthCompare = Depth.NearerOrEqual;

		var desc = RenderPipelineDesc();
		desc.Layout = pipelineLayout;
		desc.Vertex.Shader = .(vs, "main", .Vertex);
		desc.Vertex.Buffers = .(&vertexLayout, 1);
		desc.Fragment = fragment;
		desc.DepthStencil = depthStencil;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = BlendLabel(mode);

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pso)))
			return null;
		return pso;
	}

	/// Six indices, so the shader generated quad draws through an indexed draw.
	private Result<void> CreateQuadIndices()
	{
		var indices = uint16[6](0, 1, 2, 3, 4, 5);

		var desc = BufferDesc();
		desc.Size = sizeof(uint16) * 6;
		desc.Usage = .Index | .CopyDst;
		desc.Memory = .CpuToGpu;
		desc.Label = "particle.indices";
		if (!(mDevice.CreateBuffer(desc) case .Ok(let buffer)))
			return .Err;
		mIndexBuffer = buffer;

		let mapped = mIndexBuffer.Map();
		if (mapped != null)
		{
			Internal.MemCpy(mapped, &indices[0], sizeof(uint16) * 6);
			mIndexBuffer.Unmap();
		}
		return .Ok;
	}

	/// An IDENTITY index buffer, which is what lets a ribbon's triangle list go through the
	/// indexed draw a resolved draw always is.
	private Result<void> CreateTrailIndices()
	{
		var desc = BufferDesc();
		desc.Size = (uint64)cTrailMaxIndices * sizeof(uint32);
		desc.Usage = .Index | .CopyDst;
		desc.Memory = .CpuToGpu;
		desc.Label = "particle.trailindices";
		if (!(mDevice.CreateBuffer(desc) case .Ok(let buffer)))
			return .Err;
		mTrailIndexBuffer = buffer;

		let mapped = mTrailIndexBuffer.Map();
		if (mapped != null)
		{
			var indices = (uint32*)mapped;
			for (uint32 k < cTrailMaxIndices)
				indices[k] = k;
			mTrailIndexBuffer.Unmap();
		}
		return .Ok;
	}

	/// The default texture: white with a squared falloff to the edge, generated once. A
	/// component can still supply its own atlas over it.
	private Result<void> CreateSoftDot()
	{
		let pixels = scope uint8[cDotSize * cDotSize * 4];
		for (uint32 y < cDotSize)
		{
			for (uint32 x < cDotSize)
			{
				let fx = ((float)x + 0.5f) / cDotSize * 2.0f - 1.0f;
				let fy = ((float)y + 0.5f) / cDotSize * 2.0f - 1.0f;
				// Nought at the centre through one at the edge.
				let distance = Math.Sqrt(fx * fx + fy * fy);
				var alpha = 1.0f - distance;
				alpha = (alpha < 0.0f) ? 0.0f : alpha * alpha;

				let i = (int)(y * cDotSize + x) * 4;
				pixels[i + 0] = 255;
				pixels[i + 1] = 255;
				pixels[i + 2] = 255;
				pixels[i + 3] = (uint8)(alpha * 255.0f);
			}
		}

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cDotSize;
		textureDesc.Height = cDotSize;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "particle.softdot";
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return .Err;
		mWhiteTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		viewDesc.Dimension = .Texture2D;
		if (!(mDevice.CreateTextureView(mWhiteTexture, viewDesc) case .Ok(let view)))
			return .Err;
		mWhiteView = view;

		let queue = mDevice.GetQueue(.Graphics);
		if (queue == null)
			return .Ok;

		if (queue.CreateTransferBatch() case .Ok(var batch))
		{
			var layout = TextureDataLayout();
			layout.BytesPerRow = cDotSize * 4;
			layout.RowsPerImage = cDotSize;
			batch.WriteTexture(mWhiteTexture, pixels, layout, .(cDotSize, cDotSize, 1));
			batch.Submit().IgnoreError();
			queue.DestroyTransferBatch(ref batch);
		}
		return .Ok;
	}

	private void Shutdown()
	{
		for (var pair in mTexBindGroups)
		{
			var bindGroup = pair.value.BindGroup;
			if (bindGroup != null)
				mDevice.DestroyBindGroup(ref bindGroup);
		}
		mTexBindGroups.Clear();

		for (int i = 0; i < mDepthPending.Count; i++)
			mDevice.DestroyBindGroup(ref mDepthPending[i].BindGroup);
		mDepthPending.Clear();

		if (mViewBindGroup != null)
			mDevice.DestroyBindGroup(ref mViewBindGroup);

		for (int i = 0; i < mBillboard.Count; i++)
		{
			if (mBillboard[i].Pso != null)
				mDevice.DestroyRenderPipeline(ref mBillboard[i].Pso);
		}
		for (int i = 0; i < mTrail.Count; i++)
		{
			if (mTrail[i].Pso != null)
				mDevice.DestroyRenderPipeline(ref mTrail[i].Pso);
		}

		if (mTrailIndexBuffer != null)
			mDevice.DestroyBuffer(ref mTrailIndexBuffer);
		if (mIndexBuffer != null)
			mDevice.DestroyBuffer(ref mIndexBuffer);
		if (mTrailPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mTrailPipelineLayout);
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mWhiteView != null)
			mDevice.DestroyTextureView(ref mWhiteView);
		if (mWhiteTexture != null)
			mDevice.DestroyTexture(ref mWhiteTexture);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mDepthLayout != null)
			mDevice.DestroyBindGroupLayout(ref mDepthLayout);
		if (mTexLayout != null)
			mDevice.DestroyBindGroupLayout(ref mTexLayout);
		if (mViewLayout != null)
			mDevice.DestroyBindGroupLayout(ref mViewLayout);
	}
}
