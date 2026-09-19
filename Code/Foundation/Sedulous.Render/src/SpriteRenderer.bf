using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Draws textured billboard quads.
///
/// The quad's six vertices are generated in the vertex shader from the vertex index and
/// hardware instanced, the per sprite data arriving as instance stepped vertex attributes.
/// Sprites register for the TRANSPARENT category and so interleave with transparent meshes by
/// depth, sharing the blended forward pass: alpha or additive blending, depth tested against
/// the scene but never written, and no culling.
///
/// Consecutive sprites that share a texture and a blend mode fuse into one instanced draw.
/// A resolved draw is always indexed, so a static six index buffer drives the generated quad.
class SpriteRenderer : Renderer
{
	private const int cMaxViews = 8;
	/// Two matrices, padded up to the dynamic uniform alignment.
	private const uint64 cViewSlotSize = 256;

	/// Keyed by the view's address, but validated against its identity on every hit: a
	/// destroyed dynamic texture's address is reused, and the cached group would then be
	/// sampling a dead image.
	private struct TexBindGroup
	{
		public IBindGroup BindGroup;
		public uint64 ViewId;
	}

	/// The view's two matrices, as the shader reads them.
	[CRepr]
	private struct ViewUniforms
	{
		public Float4x4 ViewProj;
		public Float4x4 View;
	}

	private static uint16[1] sCategories = .(RenderCategories.Transparent);

	private IDevice mDevice;
	private ShaderSystem mShaders;
	private DynamicUniformRing mInstanceRing ~ delete _;
	private DynamicUniformRing mViewRing ~ delete _;

	private IBindGroupLayout mViewLayout = null;
	private IBindGroupLayout mTexLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private ISampler mSampler = null;
	private IBuffer mIndexBuffer = null;

	private IBindGroup mViewBindGroup = null;
	private uint32 mViewBindGroupGeneration = 0xFFFFFFFF;

	private List<SpritePipelineEntry> mPipelines = new .() ~ delete _;
	private TextureFormat mDepthFormat = .Depth32Float;
	private Dictionary<int, TexBindGroup> mTexBindGroups = new .() ~ delete _;

	public this(IDevice device, ShaderSystem shaders, uint32 framesInFlight)
	{
		mDevice = device;
		mShaders = shaders;
		mInstanceRing = new .(device, framesInFlight, sizeof(SpriteInstance),
			.Vertex | .CopyDst, "sprite.instances");
		mViewRing = new .(device, framesInFlight, cViewSlotSize,
			.Uniform | .CopyDst, "sprite.view");
	}

	public ~this()
	{
		Shutdown();
	}

	public Result<void> Initialize()
	{
		// Group nought is the view's constants, at a dynamic offset; group one the sprite's
		// texture and its sampler.
		var viewEntry = BindGroupLayoutEntry.UniformBuffer(0, .Vertex);
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

		var layouts = IBindGroupLayout[2](mViewLayout, mTexLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 2);
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;

		// A static six index buffer, so the generated quad draws through an indexed draw.
		var indices = uint16[6](0, 1, 2, 3, 4, 5);
		var bufferDesc = BufferDesc();
		bufferDesc.Size = sizeof(uint16) * 6;
		bufferDesc.Usage = .Index | .CopyDst;
		bufferDesc.Memory = .CpuToGpu;
		bufferDesc.Label = "sprite.indices";
		if (!(mDevice.CreateBuffer(bufferDesc) case .Ok(let indexBuffer)))
			return .Err;
		mIndexBuffer = indexBuffer;

		let mapped = mIndexBuffer.Map();
		if (mapped != null)
		{
			Internal.MemCpy(mapped, &indices[0], sizeof(uint16) * 6);
			mIndexBuffer.Unmap();
		}

		return .Ok;
	}

	public override Span<uint16> SupportedCategories => .(&sCategories[0], 1);

	public override void PrepareFrame(uint32 maxDraws, uint32 frameIndex)
	{
		// One draw pass, the blended forward, so the instance ring only needs the draw count
		// itself: there are no cascades or prepasses re emitting the same sprites. The view
		// ring needs a slot per view.
		mInstanceRing.Reserve((maxDraws == 0) ? 1 : maxDraws);
		mViewRing.Reserve(cMaxViews);
		mInstanceRing.BeginFrame(frameIndex);
		mViewRing.BeginFrame(frameIndex);
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

		var viewUniforms = ViewUniforms();
		viewUniforms.ViewProj = context.ViewProj;
		viewUniforms.View = context.ViewMatrix;
		Internal.MemCpy(viewRange.Ptr, &viewUniforms, sizeof(ViewUniforms));

		// Fuse consecutive sprites sharing a texture and a blend mode into one instanced draw.
		var i = 0;
		while (i < items.Length)
		{
			let head = (SpriteRenderData)items[i].Data;

			var j = i + 1;
			while (j < items.Length)
			{
				let next = (SpriteRenderData)items[j].Data;
				if ((next.Texture != head.Texture) || (next.Additive != head.Additive))
					break;
				j++;
			}

			let count = (uint32)(j - i);
			let instanceRange = mInstanceRing.AllocateRange(count);
			if (instanceRange.Ok)
			{
				let instances = (SpriteInstance*)instanceRange.Ptr;
				for (int k = i; k < j; k++)
				{
					let sprite = (SpriteRenderData)items[k].Data;
					var instance = SpriteInstance();
					instance.PositionSize = .(sprite.WorldCenter.X, sprite.WorldCenter.Y,
						sprite.WorldCenter.Z, sprite.Size.X);
					instance.SizeOrientation = .(sprite.Size.Y, (float)sprite.Orientation, 0, 0);
					instance.Tint = .(sprite.Tint.R, sprite.Tint.G, sprite.Tint.B, sprite.Tint.A);
					instance.UvRect = sprite.UvRect;
					instance.AxisRight = .(sprite.AxisRight.X, sprite.AxisRight.Y,
						sprite.AxisRight.Z, 0);
					instance.AxisUp = .(sprite.AxisUp.X, sprite.AxisUp.Y, sprite.AxisUp.Z, 0);
					instances[k - i] = instance;
				}

				let pipeline = EnsurePipeline(context.ColorFormat, head.Additive);
				let texBindGroup = EnsureTextureBindGroup(head.Texture);
				if ((pipeline != null) && (texBindGroup != null))
				{
					var draw = ResolvedDraw();
					draw.Pso = pipeline;
					draw.ViewSet = viewBindGroup;
					draw.ViewDynamic = true;
					draw.ViewOffset = viewRange.ByteOffset;
					draw.DrawSet = texBindGroup;
					draw.VertexBuffer0 = mInstanceRing.Buffer;
					draw.VertexOffset0 = instanceRange.ByteOffset;
					draw.IndexBuffer = mIndexBuffer;
					draw.IndexFormat = .UInt16;
					draw.IndexCount = 6;
					draw.InstanceCount = count;
					outDraws.Add(draw);
				}
			}

			i = j;
		}
	}

	public override void FinishFrame()
	{
		mInstanceRing.EndFrame();
		mViewRing.EndFrame();
	}

	/// Wires the retire queue the rings hand their outgrown buffers to. Null drains instead.
	public void SetRetireQueue(GpuRetireQueue retire)
	{
		mInstanceRing.SetRetireQueue(retire);
		mViewRing.SetRetireQueue(retire);
	}

	/// One group over the whole view ring, the view chosen by a dynamic offset. It is only
	/// rebuilt when the ring itself is reallocated, which drains the device first, so it can
	/// never free a set still in flight.
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
			BindGroupEntry.SamplerEntry(mSampler));

		var desc = BindGroupDesc();
		desc.Layout = mTexLayout;
		desc.Entries = .(&entries[0], 2);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mTexBindGroups[key] = .() { BindGroup = bindGroup, ViewId = texture.UniqueId };
		return bindGroup;
	}

	private IRenderPipeline EnsurePipeline(TextureFormat colorFormat, bool additive)
	{
		let shaderVersion = mShaders.Version("sprite");

		var index = -1;
		for (int i < mPipelines.Count)
		{
			if ((mPipelines[i].Format == colorFormat) && (mPipelines[i].Additive == additive))
			{
				index = i;
				break;
			}
		}

		if (index < 0)
		{
			var fresh = SpritePipelineEntry();
			fresh.Format = colorFormat;
			fresh.Additive = additive;
			mPipelines.Add(fresh);
			index = mPipelines.Count - 1;
		}

		if ((mPipelines[index].Pipeline != null)
			&& (mPipelines[index].ShaderVersion == shaderVersion))
			return mPipelines[index].Pipeline;

		if (mPipelines[index].Pipeline != null)
		{
			var stale = mPipelines[index].Pipeline;
			mDevice.DestroyRenderPipeline(ref stale);
			mPipelines[index].Pipeline = null;
		}

		let vertex = mShaders.GetVariant("sprite", .Vertex, .None);
		let fragment = mShaders.GetVariant("sprite", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return null;

		var attributes = VertexAttribute[6](
			.(.Float32x4, 0, 0),
			.(.Float32x4, 16, 1),
			.(.Float32x4, 32, 2),
			.(.Float32x4, 48, 3),
			.(.Float32x4, 64, 4),
			.(.Float32x4, 80, 5));

		var bufferLayout = VertexBufferLayout();
		bufferLayout.Stride = sizeof(SpriteInstance);
		bufferLayout.StepMode = .Instance;
		bufferLayout.Attributes = .(&attributes[0], 6);

		var target = ColorTargetState();
		target.Format = colorFormat;
		// An additive sprite blends ALPHA WEIGHTED, rather than through the plain accumulate:
		// a texel the texture left transparent then adds nothing, instead of dumping its
		// usually white colour into the scene. Only the opaque part glows.
		target.Blend = additive
			? BlendState(.(.SrcAlpha, .One, .Add), .(.One, .One, .Add))
			: BlendState.AlphaBlend;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&target, 1);

		var depthStencil = DepthStencilState();
		depthStencil.Format = mDepthFormat;
		depthStencil.DepthTestEnabled = true;
		depthStencil.DepthWriteEnabled = false;
		depthStencil.DepthCompare = Depth.NearerOrEqual;

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Vertex.Buffers = .(&bufferLayout, 1);
		desc.Fragment = fragmentState;
		desc.DepthStencil = depthStencil;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = additive ? "sprite.additive" : "sprite.alpha";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;

		mPipelines[index].Pipeline = pipeline;
		mPipelines[index].ShaderVersion = shaderVersion;
		return pipeline;
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

		if (mViewBindGroup != null)
			mDevice.DestroyBindGroup(ref mViewBindGroup);

		for (var entry in ref mPipelines)
		{
			if (entry.Pipeline != null)
				mDevice.DestroyRenderPipeline(ref entry.Pipeline);
		}
		mPipelines.Clear();

		if (mIndexBuffer != null)
			mDevice.DestroyBuffer(ref mIndexBuffer);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mTexLayout != null)
			mDevice.DestroyBindGroupLayout(ref mTexLayout);
		if (mViewLayout != null)
			mDevice.DestroyBindGroupLayout(ref mViewLayout);
	}
}
