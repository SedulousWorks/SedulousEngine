using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Terrain;

namespace Sedulous.Engine.Terrain;

/// The chunked geo mipmap terrain drawer.
///
/// ONE 65 by 65 grid vertex buffer and one index buffer PER LEVEL are uploaded once; every
/// chunk draws that shared grid, placed and height displaced in the vertex shader from a per
/// chunk uniform and the height texture. Resolving is where the per view work lives, since
/// resolving alone holds the camera: it replays the foundation's chunk extract, which is the
/// same tested quadtree cull and coverage level selection the CPU path uses, and emits one
/// indexed draw per visible chunk at its level.
///
/// The bind sets are the view, the chunk, the height texture, and the splat material.
class TerrainRenderer : Renderer
{
	/// A terrain allocates a view slot per PASS, so this bounds how many terrains a scene
	/// draws before the ring runs dry.
	private const uint32 cMaxTerrains = 8;
	/// Matches ShadowCascades.Count.
	private const uint32 cCascadeCount = 4;
	/// In texels, which the shader scales by the cascade's world texel size: a fixed bias is
	/// either useless near or gone far.
	private const float cShadowNormalBias = 0.02f;
	private const float cShadowDepthBias = 0.0009f;
	/// Eight matrices and six vectors, padded up to the dynamic uniform alignment.
	private const uint64 cViewSlotSize = 768;
	/// Six pairs, padded the same way.
	private const uint64 cChunkSlotSize = 256;

	/// Mirrors the shader's terrain view constants: keep the field order in lockstep.
	[CRepr]
	private struct ViewUniforms
	{
		public Float4x4 ChunkToWorld;
		public Float4x4 ViewProj;
		public Float4x4 View;
		public Float4x4 PrevViewProj;
		public Float4x4[cCascadeCount] CascadeViewProj;
		public Float4 LightDir;
		public Float4 CameraPos;
		public Float4 Jitter;
		public Float4 CascadeSplitFar;
		public Float4 CascadeTexelSize;
		/// x the cascade count, y the layer base, z the normal bias, w the depth bias.
		public Float4 ShadowMeta;
		/// x the far fade width, y the uv y sign, z the height blend contrast, w whether a
		/// height map is bound.
		public Float4 ShadowParams;
		/// x the palette count, y whether weights are bound, z the base tile scale, w whether
		/// a base albedo is bound.
		public Float4 SplatParams;
		/// x whether a coverage mask array is bound; the rest spare.
		public Float4 SplatParams2;
	}

	/// Mirrors the shader's per chunk constants. Shared by the colour and the depth passes.
	[CRepr]
	private struct ChunkUniforms
	{
		public Float2 OriginXZ;
		public Float2 SizeXZ;
		public Float2 TexelBase;
		public Float2 TexelSpan;
		public Float2 HeightRange;
		public Float2 GridSize;
		/// x the skirt depth in world units, y spare.
		public Float2 Skirt;
	}

	/// A chunk with holes draws its OWN buffers, which the render data carries per chunk; a
	/// chunk cut everywhere draws nothing; every other chunk draws the shared grid the caller
	/// already put in `mesh`.
	///
	/// False means there is nothing to draw for this chunk at this level.
	private static bool SelectChunkMesh(TerrainRenderData data, uint32 chunkIndex, uint32 lod,
		ref LodMesh mesh)
	{
		let chunk = data.Chunks[chunkIndex];
		if (chunk.AllCut)
			return false;
		if (!chunk.HasHoles)
			return true;

		for (uint32 i = 0; i < data.HoledMeshCount; i++)
		{
			let holed = data.HoledMeshes[i];
			if (holed.ChunkIndex != chunkIndex)
				continue;

			mesh.IndexBuffer = holed.IndexBuffers[lod];
			mesh.IndexCount = holed.IndexCounts[lod];
			mesh.SurfaceIndexCount = holed.SurfaceIndexCounts[lod];
			return (mesh.IndexBuffer != null) && (mesh.IndexCount != 0);
		}
		// A holed chunk without its buffers, which a failed upload leaves, draws nothing.
		return false;
	}

	private struct LodMesh
	{
		public IBuffer IndexBuffer = null;
		/// The surface plus the skirt walls.
		public uint32 IndexCount = 0;
		/// The surface prefix alone, which is the skirtless draw range.
		public uint32 SurfaceIndexCount = 0;

		public this() {}
	}

	private struct DepthPso
	{
		public IRenderPipeline Pso = null;
		public TextureFormat Format = .Undefined;
		public uint64 ShaderVersion = 0;

		public this() {}
	}

	/// The pick pass's view slot: the placement and the cropped projection where the depth
	/// pass reads them, then the terrain entity's id. Mirrors terrain_pick.vs's prefix.
	[CRepr]
	private struct PickViewUniforms
	{
		public Float4x4 ChunkToWorld;
		public Float4x4 ViewProj;
		/// The entity index plus one; nought is nothing.
		public uint32 PickIndex;
		public uint32 PickGeneration;
		public uint32 Pad0;
		public uint32 Pad1;
	}

	private struct PickPso
	{
		public IRenderPipeline Pso = null;
		public TextureFormat ColorFormat = .Undefined;
		public TextureFormat DepthFormat = .Undefined;
		public uint64 ShaderVersion = 0;

		public this() {}
	}

	/// Keyed by the view's address, VALIDATED by its identity: a destroyed view's address is
	/// handed straight back to the next allocation, and the cached group would then be
	/// sampling a dead image.
	private struct HeightBindGroup
	{
		public IBindGroup BindGroup;
		public uint64 ViewId;
	}

	/// The same contract over the whole splat set: index, weight, base albedo, palette, then
	/// the base and array normal, ORM, height, and the coverage mask.
	private struct MaterialBindGroup
	{
		public IBindGroup BindGroup;
		public uint64[11] Ids;
		public uint64 TileGeneration;
	}

	private static uint16[1] sCategories = .(RenderCategories.Opaque);

	private IDevice mDevice;
	private ShaderSystem mShaders;

	private DynamicUniformRing mViewRing ~ delete _;
	private DynamicUniformRing mChunkRing ~ delete _;

	private IBindGroupLayout mViewLayout = null;
	private IBindGroupLayout mChunkLayout = null;
	private IBindGroupLayout mHeightLayout = null;
	private IBindGroupLayout mMaterialLayout = null;
	/// The colour pass binds all four sets.
	private IPipelineLayout mPipelineLayout = null;
	/// The depth pass leaves the material out, so the backend's rule that every declared set
	/// is bound holds without a spurious bind.
	private IPipelineLayout mDepthPipelineLayout = null;

	private IBuffer mGridVertexBuffer = null;
	private uint32 mGridVertexCount = 0;
	private LodMesh[TerrainMesh.MaxChunkLod + 1] mLodMeshes = .();

	private IBindGroup mViewBindGroup = null;
	private uint32 mViewBindGroupGeneration = 0;
	private ITextureView mViewBindGroupShadow = null;
	private uint64 mViewBindGroupShadowGeneration = 0;

	/// The depth and shadow cast pass keeps its OWN view group, bound to the stand in shadow
	/// map rather than the live cascade being written: a cascade cast would otherwise sample
	/// its own render attachment.
	private IBindGroup mDepthViewBindGroup = null;
	private uint32 mDepthViewBindGroupGeneration = 0;
	private ITextureView mDepthViewBindGroupShadow = null;
	private uint64 mDepthViewBindGroupShadowGeneration = 0;

	private IBindGroup mChunkBindGroup = null;
	private uint32 mChunkBindGroupGeneration = 0;

	private Dictionary<int, HeightBindGroup> mHeightBindGroups = new .() ~ delete _;
	private Dictionary<int, MaterialBindGroup> mMaterialBindGroups = new .() ~ delete _;

	/// Repeat and trilinear, for the base and the palette slices. The splat rasters are read
	/// exactly, so they have no sampler at all.
	private ISampler mAlbedoSampler = null;
	/// The stand ins an absent slot binds: zero weights read as pure base, and a white base
	/// leaves the albedo untinted.
	private ITexture mWhiteTexture = null;
	private ITextureView mWhiteView = null;
	private ITexture mZeroWeightTexture = null;
	private ITextureView mZeroWeightView = null;
	private ITexture mZeroIndexTexture = null;
	private ITextureView mZeroIndexView = null;
	private ITexture mWhiteArrayTexture = null;
	private ITextureView mWhiteArrayView = null;
	private ITexture mFlatNormalTexture = null;
	private ITextureView mFlatNormalView = null;
	private ITexture mFlatNormalArrayTexture = null;
	private ITextureView mFlatNormalArrayView = null;
	private ITexture mDefaultOrmTexture = null;
	private ITextureView mDefaultOrmView = null;
	private ITexture mDefaultOrmArrayTexture = null;
	private ITextureView mDefaultOrmArrayView = null;
	private ITexture mMidHeightTexture = null;
	private ITextureView mMidHeightView = null;
	private ITexture mMidHeightArrayTexture = null;
	private ITextureView mMidHeightArrayView = null;
	private ITexture mOpaqueMaskArrayTexture = null;
	private ITextureView mOpaqueMaskArrayView = null;
	/// One float, holding a tile scale of one.
	private IBuffer mDummyTileBuffer = null;

	/// BORROWED: the render subsystem owns and ticks it.
	private GpuRetireQueue mRetire = null;

	/// The shadow receive pair: the comparison sampler, and a one by one array depth map bound
	/// when no caster exists this frame, so the set stays complete.
	private ISampler mShadowSampler = null;
	private ITexture mDummyShadowTexture = null;
	private ITextureView mDummyShadowView = null;
	/// BORROWED: the cascade array, or the stand in.
	private ITextureView mActiveShadowView = null;
	private uint64 mActiveShadowGeneration = 0;
	/// The stand in depth left its undefined layout once, so a caster less frame never samples
	/// an image that was never written.
	private bool mDummyDepthInitialized = false;

	private IRenderPipeline mPso = null;
	private TextureFormat mPsoFormat = .Undefined;
	private uint64 mPsoShaderVersion = 0;
	/// Nought is the camera prepass, which takes no bias; one is the shadow cascade, which
	/// does.
	private DepthPso[2] mDepthPso = .();
	private PickPso mPickPso = .();
	private TextureFormat mDepthFormat = .Undefined;

	/// Scratch, reused per terrain: resolving is single threaded.
	private List<ChunkDraw> mDraws = new .() ~ delete _;

	private uint32 mFrameChunks = 0;
	private uint32 mMaxChunksSeen = 0;
	private uint32 mFrameChunkAllocations = 0;
	private uint32 mMaxChunkAllocations = 0;
	private bool mSkirtsEnabled = true;

	public this(IDevice device, ShaderSystem shaders, uint32 framesInFlight)
	{
		mDevice = device;
		mShaders = shaders;

		mViewRing = new .(device, framesInFlight, cViewSlotSize, .Uniform | .CopyDst,
			"terrain.view");
		mChunkRing = new .(device, framesInFlight, cChunkSlotSize, .Uniform | .CopyDst,
			"terrain.chunk");
	}

	public ~this()
	{
		Shutdown();
	}

	public Result<void> Initialize()
	{
		if (CreateLayouts() case .Err)
			return .Err;
		if (CreateGridBuffers() case .Err)
			return .Err;
		if (CreateShadowResources() case .Err)
			return .Err;
		if (CreateMaterialFallbacks() case .Err)
			return .Err;

		UploadFallbackPixels();
		return .Ok;
	}

	public override Span<uint16> SupportedCategories => .(&sCategories[0], 1);

	public override void PrepareFrame(uint32 maxDraws, uint32 frameIndex)
	{
		const uint32 cChunk = 4096;

		// Each terrain takes a view slot PER PASS: the colour pass, the depth prepass, and one
		// per cascade. The chunk ring holds every pass's chunk allocations, sized from the
		// observed peak across both.
		let perTerrainViews = (uint32)(cMaxTerrains * (2 + cCascadeCount));
		mViewRing.Reserve(Math.Max(perTerrainViews, (maxDraws == 0) ? 1 : maxDraws));

		let wantChunks = (uint32)(((mMaxChunkAllocations + cChunk - 1) / cChunk) * cChunk);
		mChunkRing.Reserve((wantChunks == 0) ? cChunk : wantChunks);

		mViewRing.BeginFrame(frameIndex);
		mChunkRing.BeginFrame(frameIndex);

		mFrameChunks = 0;
		mFrameChunkAllocations = 0;
	}

	public override void Resolve(RenderRecordContext context, Span<DrawItem> items,
		List<ResolvedDraw> outDraws)
	{
		if (items.IsEmpty)
			return;

		mDepthFormat = context.DepthFormat;

		let pso = EnsurePipeline(context.ColorFormat);
		if (pso == null)
			return;

		let viewBindGroup = EnsureViewBindGroup();
		let chunkBindGroup = EnsureChunkBindGroup();
		if ((viewBindGroup == null) || (chunkBindGroup == null))
			return;

		let projection = (context.View != null)
			? context.View.Camera.Projection
			: Float4x4.Identity();
		let sun = FindSun(context);

		for (let item in items)
		{
			// OURS ONLY. Dispatchers group runs by renderer id, but a foreign item slipping
			// through and being cast here is silent corruption rather than a failed draw.
			if (item.Data.RendererId != RendererId)
				continue;

			let data = item.Data as TerrainRenderData;
			if ((data == null) || (data.Chunks == null) || (data.Nodes == null)
				|| (data.HeightView == null) || (data.ChunkCount == 0))
				continue;

			let viewRange = mViewRing.Allocate();
			if (!viewRange.Ok)
				continue;

			// The vertex shader works in WORLD space, with the placement applied there rather
			// than folded into the view projection, so the pixel shader can shadow sample the
			// world position against the world space cascade matrices.
			var uniforms = ViewUniforms();
			uniforms.ChunkToWorld = data.ChunkToWorld;
			uniforms.ViewProj = context.ViewProj;
			uniforms.View = context.ViewMatrix;
			uniforms.PrevViewProj = context.PrevViewProj;
			uniforms.LightDir = .(sun.X, sun.Y, sun.Z, 0.0f);
			uniforms.CameraPos = .(context.CameraPos.X, context.CameraPos.Y, context.CameraPos.Z,
				0.0f);
			uniforms.Jitter = .(context.Jitter.X, context.Jitter.Y, context.PrevJitter.X,
				context.PrevJitter.Y);

			let uvYSign = mDevice.NeedsClipSpaceYFlip ? 1.0f : -1.0f;
			uniforms.ShadowParams = .(0.0f, uvYSign, 0.0f, 0.0f);

			// A cascade count of nought leaves the shader fully lit, which is what a scene
			// with no directional caster wants.
			if (context.Cascades.Valid)
			{
				for (int c < (int)cCascadeCount)
					uniforms.CascadeViewProj[c] = context.Cascades.ViewProjection[c];

				uniforms.CascadeSplitFar = .(context.Cascades.SplitFar[0],
					context.Cascades.SplitFar[1], context.Cascades.SplitFar[2],
					context.Cascades.SplitFar[3]);
				uniforms.CascadeTexelSize = .(context.Cascades.TexelWorldSize[0],
					context.Cascades.TexelWorldSize[1], context.Cascades.TexelWorldSize[2],
					context.Cascades.TexelWorldSize[3]);
				uniforms.ShadowMeta = .((float)cCascadeCount, (float)context.CascadeLayerBase,
					cShadowNormalBias, cShadowDepthBias);
				uniforms.ShadowParams.X = context.ShadowFarFade;
			}

			let hasWeights = (data.WeightView != null) && (data.IndexView != null)
				&& (data.PaletteArrayView != null) && (data.PaletteCount > 0);
			uniforms.SplatParams = .((float)data.PaletteCount, hasWeights ? 1.0f : 0.0f,
				data.BaseTileScale, (data.BaseAlbedoView != null) ? 1.0f : 0.0f);

			// Height blending off leaves the linear weighting, byte for byte.
			let heightBound = (data.BaseHeightView != null) || (data.HeightArrayView != null);
			uniforms.ShadowParams.Z = data.HeightBlendContrast;
			uniforms.ShadowParams.W = heightBound ? 1.0f : 0.0f;

			// And the coverage multiply is skipped the same way.
			let maskBound = data.MaskArrayView != null;
			uniforms.SplatParams2 = .(maskBound ? 1.0f : 0.0f, 0.0f, 0.0f, 0.0f);

			Internal.MemCpy(viewRange.Ptr, &uniforms, sizeof(ViewUniforms));

			BuildDraws(context, data, projection);
			if (mDraws.IsEmpty)
				continue;

			let heightBindGroup = EnsureHeightBindGroup(data.HeightView);
			let materialBindGroup = EnsureMaterialBindGroup(data);
			if ((heightBindGroup == null) || (materialBindGroup == null))
				continue;

			for (let draw in mDraws)
			{
				let lod = Math.Min(draw.Lod, TerrainMesh.MaxChunkLod);
				// The shared grid, or a holed chunk's own buffers.
				var mesh = mLodMeshes[lod];
				if (!SelectChunkMesh(data, (uint32)draw.ChunkIndex, lod, ref mesh))
					continue;
				if ((mesh.IndexBuffer == null) || (mesh.IndexCount == 0))
					continue;

				let chunkRange = mChunkRing.Allocate();
				if (!chunkRange.Ok)
					continue;

				mFrameChunks++;
				mFrameChunkAllocations++;

				var chunkUniforms = MakeChunkUniforms(data, data.Chunks[draw.ChunkIndex]);
				Internal.MemCpy(chunkRange.Ptr, &chunkUniforms, sizeof(ChunkUniforms));

				var resolved = ResolvedDraw();
				resolved.Pso = pso;
				resolved.ViewSet = viewBindGroup;
				resolved.ViewDynamic = true;
				resolved.ViewOffset = viewRange.ByteOffset;
				resolved.DrawSet = chunkBindGroup;
				resolved.DrawDynamic = true;
				resolved.DrawOffset = chunkRange.ByteOffset;
				resolved.MaterialSet = heightBindGroup;
				resolved.ClusterSet = materialBindGroup;
				resolved.VertexBuffer0 = mGridVertexBuffer;
				resolved.IndexBuffer = mesh.IndexBuffer;
				resolved.IndexFormat = .UInt32;
				// The skirtless pass draws the surface prefix alone, which is what proves the
				// skirts are what plug the seams.
				resolved.IndexCount = mSkirtsEnabled ? mesh.IndexCount : mesh.SurfaceIndexCount;
				resolved.InstanceCount = 1;
				outDraws.Add(resolved);
			}
		}
	}

	/// The depth only cast: the camera prepass, and each cascade. The same cull and level
	/// selection, but a vertex only pipeline and SURFACE indices alone, the skirts being a
	/// shading fix rather than geometry anything should cast from.
	public override void ResolveDepthOnly(RenderRecordContext context, Span<DrawItem> items,
		List<ResolvedDraw> outDraws)
	{
		ResolveDepthLike(context, items, outDraws, false);
	}

	/// The terrain as a PICK ID writer: the depth cast with the pick fragment, every chunk
	/// carrying the terrain entity's id through the view slot.
	public override void ResolvePickIds(RenderRecordContext context, Span<DrawItem> items,
		List<ResolvedDraw> outDraws)
	{
		ResolveDepthLike(context, items, outDraws, true);
	}

	private void ResolveDepthLike(RenderRecordContext context, Span<DrawItem> items,
		List<ResolvedDraw> outDraws, bool pick)
	{
		if (items.IsEmpty)
			return;

		if (!pick)
			mDepthFormat = context.DepthFormat;

		let pso = pick
			? EnsurePickPipeline(context.ColorFormat, context.DepthFormat)
			: EnsureDepthPipeline(context.DepthFormat, !context.DepthPrepass);
		let viewBindGroup = EnsureDepthViewBindGroup();
		let chunkBindGroup = EnsureChunkBindGroup();
		if ((pso == null) || (viewBindGroup == null) || (chunkBindGroup == null))
			return;

		let projection = (context.View != null)
			? context.View.Camera.Projection
			: Float4x4.Identity();

		for (let item in items)
		{
			if (item.Data.RendererId != RendererId)
				continue;

			let data = item.Data as TerrainRenderData;
			if ((data == null) || (data.Chunks == null) || (data.Nodes == null)
				|| (data.HeightView == null) || (data.ChunkCount == 0))
				continue;

			let viewRange = mViewRing.Allocate();
			if (!viewRange.Ok)
				continue;

			if (pick)
			{
				// The pick vertex shader reads the placement, the cropped projection and the
				// id; the id sits where the colour pass keeps its view matrix.
				var uniforms = PickViewUniforms();
				uniforms.ChunkToWorld = data.ChunkToWorld;
				uniforms.ViewProj = context.ViewProj;
				uniforms.PickIndex = EntityTag.Index(data.EntityId) + 1;
				uniforms.PickGeneration = EntityTag.Generation(data.EntityId);
				Internal.MemCpy(viewRange.Ptr, &uniforms, sizeof(PickViewUniforms));
			}
			else
			{
				// The depth vertex shader reads the placement and the view projection alone;
				// the rest of the slot goes unread.
				var uniforms = ViewUniforms();
				uniforms.ChunkToWorld = data.ChunkToWorld;
				uniforms.ViewProj = context.ViewProj;
				Internal.MemCpy(viewRange.Ptr, &uniforms, sizeof(ViewUniforms));
			}

			BuildDraws(context, data, projection);
			if (mDraws.IsEmpty)
				continue;

			let heightBindGroup = EnsureHeightBindGroup(data.HeightView);
			if (heightBindGroup == null)
				continue;

			for (let draw in mDraws)
			{
				let lod = Math.Min(draw.Lod, TerrainMesh.MaxChunkLod);
				var mesh = mLodMeshes[lod];
				if (!SelectChunkMesh(data, (uint32)draw.ChunkIndex, lod, ref mesh))
					continue;
				if ((mesh.IndexBuffer == null) || (mesh.SurfaceIndexCount == 0))
					continue;

				let chunkRange = mChunkRing.Allocate();
				if (!chunkRange.Ok)
					continue;

				mFrameChunkAllocations++;

				var chunkUniforms = MakeChunkUniforms(data, data.Chunks[draw.ChunkIndex]);
				Internal.MemCpy(chunkRange.Ptr, &chunkUniforms, sizeof(ChunkUniforms));

				var resolved = ResolvedDraw();
				resolved.Pso = pso;
				resolved.ViewSet = viewBindGroup;
				resolved.ViewDynamic = true;
				resolved.ViewOffset = viewRange.ByteOffset;
				resolved.DrawSet = chunkBindGroup;
				resolved.DrawDynamic = true;
				resolved.DrawOffset = chunkRange.ByteOffset;
				// The vertex shader displaces from the height texture, so the depth pass needs
				// it just as much as the colour one.
				resolved.MaterialSet = heightBindGroup;
				resolved.VertexBuffer0 = mGridVertexBuffer;
				resolved.IndexBuffer = mesh.IndexBuffer;
				resolved.IndexFormat = .UInt32;
				resolved.IndexCount = mesh.SurfaceIndexCount;
				resolved.InstanceCount = 1;
				outDraws.Add(resolved);
			}
		}
	}

	public override void FinishFrame()
	{
		mMaxChunksSeen = Math.Max(mMaxChunksSeen, mFrameChunks);
		mMaxChunkAllocations = Math.Max(mMaxChunkAllocations, mFrameChunkAllocations);

		mViewRing.EndFrame();
		mChunkRing.EndFrame();
	}

	/// Wires the frame aged queue in. The stale height and material groups retire through it
	/// too, a submitted frame still holding them in its descriptor bindings.
	public void SetRetireQueue(GpuRetireQueue retire)
	{
		mRetire = retire;
		mViewRing.SetRetireQueue(retire);
		mChunkRing.SetRetireQueue(retire);
	}

	/// This frame's cascade array; null means no caster, which binds the stand in and samples
	/// fully lit. Terrain takes only the directional cascades, so the local atlas hook stays
	/// as the base leaves it.
	public override void SetShadowMap(ITextureView shadowMap, uint64 generation)
	{
		mActiveShadowView = (shadowMap != null) ? shadowMap : mDummyShadowView;
		mActiveShadowGeneration = (shadowMap != null) ? generation : 0;
	}

	/// Terrain has no skinning. It takes this hook, the only one holding the OUTER encoder
	/// before any pass opens, purely to move the stand in shadow depth out of its undefined
	/// layout ONCE: a caster less frame would otherwise sample an image that was never
	/// written, which the validation layers reject.
	public override void UploadSkinning(ExtractedScene scene, ICommandEncoder encoder)
	{
		if (!mDummyDepthInitialized && (mDummyShadowTexture != null))
		{
			encoder.TransitionTexture(mDummyShadowTexture, .Undefined, .DepthStencilRead);
			mDummyDepthInitialized = true;
		}
	}

	/// The peak chunk draw count seen so far, which is above nought only once a frame actually
	/// emitted terrain draws, and so only once the pipeline, and with it the shaders, built.
	public uint32 MaxChunksDrawn => mMaxChunksSeen;

	/// Draws the level seam skirts, on by default. Off draws the surface alone, which is what
	/// proves the skirts plug the cracks: a skirtless mixed level frame leaks the background
	/// through its seams.
	public void SetSkirtsEnabled(bool enabled)
	{
		mSkirtsEnabled = enabled;
	}

	// ==================== Per terrain draw building ====================

	/// The scene's sun, as a direction TO the light: the first directional light, falling back
	/// to a fixed key so terrain is never unlit. Point and spot lights are not read here.
	private static Float3 FindSun(RenderRecordContext context)
	{
		var sun = Normalized(Float3(0.35f, 0.82f, 0.45f));

		for (let light in context.Lights)
		{
			if (light.Type >= 0.5f)
				continue;

			let length = Length(light.DirectionWS);
			if (length > 1.0e-4f)
				sun = light.DirectionWS * (-1.0f / length);
			break;
		}

		return sun;
	}

	private void BuildDraws(RenderRecordContext context, TerrainRenderData data,
		Float4x4 projection)
	{
		// A LOCAL space frustum, with the placement folded in, matches the chunks' own local
		// bounds.
		let frustum = BoundingFrustum(data.ChunkToWorld * context.ViewProj);

		TerrainChunks.ExtractVisibleChunkDraws(.(data.Nodes, (int)data.NodeCount),
			.(data.Chunks, (int)data.ChunkCount), data.ChunkToWorld, context.ViewMatrix,
			projection, frustum, .(&data.Thresholds[0], (int)data.ThresholdCount), data.LodBias,
			mDraws);

		// A camera independent pass, which a local shadow tile is, casts every visible chunk
		// at the COARSEST level: a shadow is never finer than any view shows. The cascades
		// carry the owning camera's view, so their levels already match the main view's.
		if (context.View == null)
		{
			for (int i < mDraws.Count)
				mDraws[i].Lod = TerrainMesh.MaxChunkLod;
		}
	}

	private static ChunkUniforms MakeChunkUniforms(TerrainRenderData data, TerrainChunk chunk)
	{
		// How far the skirt ring drops below the surface to plug a seam, bounded by the
		// chunk's own relief, since a seam cannot mismatch by more than that, with a floor for
		// near flat ground. Only ever visible AT a crack, so being generous costs nothing.
		let skirtDepth = Math.Max(1.0f, 0.5f * (chunk.Bounds.Max.Y - chunk.Bounds.Min.Y));

		var uniforms = ChunkUniforms();
		uniforms.OriginXZ = .(chunk.Bounds.Min.X, chunk.Bounds.Min.Z);
		uniforms.SizeXZ = .(chunk.Bounds.Max.X - chunk.Bounds.Min.X,
			chunk.Bounds.Max.Z - chunk.Bounds.Min.Z);
		uniforms.TexelBase = .((float)chunk.GridX0, (float)chunk.GridZ0);
		uniforms.TexelSpan = .((float)TerrainMesh.ChunkQuads, (float)TerrainMesh.ChunkQuads);
		uniforms.HeightRange = .(data.MinY, data.MaxY);
		uniforms.GridSize = .((float)data.GridSize, (float)data.GridSize);
		uniforms.Skirt = .(skirtDepth, 0.0f);
		return uniforms;
	}

	// ==================== Bind groups ====================

	/// The forward pass's view group, whose shadow slot is the LIVE cascade array, or the
	/// stand in when nothing cast this frame.
	private IBindGroup EnsureViewBindGroup()
	{
		return BuildViewBindGroup(mActiveShadowView, mActiveShadowGeneration,
			ref mViewBindGroup, ref mViewBindGroupGeneration, ref mViewBindGroupShadow,
			ref mViewBindGroupShadowGeneration);
	}

	/// The depth pass's own, whose shadow slot is ALWAYS the stand in. The depth shaders never
	/// sample it, and during a cascade cast the live cascade IS the render attachment: binding
	/// it here too is a read and write of one image in a single scope, which the backends
	/// reject. The stand in is never an attachment, so it is always safe.
	private IBindGroup EnsureDepthViewBindGroup()
	{
		return BuildViewBindGroup(mDummyShadowView, 0, ref mDepthViewBindGroup,
			ref mDepthViewBindGroupGeneration, ref mDepthViewBindGroupShadow,
			ref mDepthViewBindGroupShadowGeneration);
	}

	private IBindGroup BuildViewBindGroup(ITextureView shadowView, uint64 shadowGeneration,
		ref IBindGroup bindGroup, ref uint32 bindGroupGeneration, ref ITextureView cachedShadow,
		ref uint64 cachedShadowGeneration)
	{
		let generation = mViewRing.Generation;

		// Rebuilt on a ring roll over, or on a change of the bound shadow map. The generation
		// is checked beside the address because a freed view's address comes back around.
		if ((bindGroup != null) && (bindGroupGeneration == generation)
			&& (cachedShadow === shadowView) && (cachedShadowGeneration == shadowGeneration))
			return bindGroup;

		if (bindGroup != null)
			RetireBindGroup(ref bindGroup);

		if ((mViewRing.Buffer == null) || (shadowView == null))
			return null;

		var entries = BindGroupEntry[3](
			BindGroupEntry.BufferEntry(mViewRing.Buffer, 0, cViewSlotSize),
			BindGroupEntry.TextureEntry(shadowView),
			BindGroupEntry.SamplerEntry(mShadowSampler));

		var desc = BindGroupDesc();
		desc.Layout = mViewLayout;
		desc.Entries = .(&entries[0], 3);
		if (!(mDevice.CreateBindGroup(desc) case .Ok(let created)))
			return null;

		bindGroup = created;
		bindGroupGeneration = generation;
		cachedShadow = shadowView;
		cachedShadowGeneration = shadowGeneration;
		return bindGroup;
	}

	private IBindGroup EnsureChunkBindGroup()
	{
		let generation = mChunkRing.Generation;
		if ((mChunkBindGroup != null) && (mChunkBindGroupGeneration == generation))
			return mChunkBindGroup;

		if (mChunkBindGroup != null)
			mDevice.DestroyBindGroup(ref mChunkBindGroup);

		if (mChunkRing.Buffer == null)
			return null;

		var entry = BindGroupEntry.BufferEntry(mChunkRing.Buffer, 0, cChunkSlotSize);

		var desc = BindGroupDesc();
		desc.Layout = mChunkLayout;
		desc.Entries = .(&entry, 1);
		if (!(mDevice.CreateBindGroup(desc) case .Ok(let created)))
			return null;

		mChunkBindGroup = created;
		mChunkBindGroupGeneration = generation;
		return mChunkBindGroup;
	}

	private IBindGroup EnsureHeightBindGroup(ITextureView view)
	{
		if (view == null)
			return null;

		let key = (int)(void*)Internal.UnsafeCastToPtr(view);
		if (mHeightBindGroups.TryGetValue(key, var found))
		{
			if (found.ViewId == view.UniqueId)
				return found.BindGroup;

			if (found.BindGroup != null)
				RetireBindGroup(ref found.BindGroup);
			mHeightBindGroups.Remove(key);
		}

		var entry = BindGroupEntry.TextureEntry(view);

		var desc = BindGroupDesc();
		desc.Layout = mHeightLayout;
		desc.Entries = .(&entry, 1);
		if (!(mDevice.CreateBindGroup(desc) case .Ok(let created)))
			return null;

		mHeightBindGroups[key] = .() { BindGroup = created, ViewId = view.UniqueId };
		return created;
	}

	/// The splat material set. Keyed by the WEIGHT view's address, but validated against the
	/// identity of EVERY view plus the tile buffer's generation: addresses alias across a
	/// reload, and identities do not.
	private IBindGroup EnsureMaterialBindGroup(TerrainRenderData data)
	{
		// An absent slot binds a stand in, which is what keeps the shader free of a branch per
		// map: zero weights and indices read as pure base, a white base leaves it untinted.
		let index = (data.IndexView != null) ? data.IndexView : mZeroIndexView;
		let weight = (data.WeightView != null) ? data.WeightView : mZeroWeightView;
		let @base = (data.BaseAlbedoView != null) ? data.BaseAlbedoView : mWhiteView;
		let palette = (data.PaletteArrayView != null) ? data.PaletteArrayView : mWhiteArrayView;
		let tiles = (data.TileScaleBuffer != null) ? data.TileScaleBuffer : mDummyTileBuffer;
		let tileGeneration = (data.TileScaleBuffer != null) ? data.TileScaleGeneration : 0;

		let baseNormal = (data.BaseNormalView != null) ? data.BaseNormalView : mFlatNormalView;
		let normalArray = (data.NormalArrayView != null)
			? data.NormalArrayView
			: mFlatNormalArrayView;
		let baseOrm = (data.BaseOrmView != null) ? data.BaseOrmView : mDefaultOrmView;
		let ormArray = (data.OrmArrayView != null) ? data.OrmArrayView : mDefaultOrmArrayView;
		let baseHeight = (data.BaseHeightView != null) ? data.BaseHeightView : mMidHeightView;
		let heightArray = (data.HeightArrayView != null)
			? data.HeightArrayView
			: mMidHeightArrayView;
		let maskArray = (data.MaskArrayView != null) ? data.MaskArrayView : mOpaqueMaskArrayView;

		let key = (int)(void*)Internal.UnsafeCastToPtr(weight);
		if (mMaterialBindGroups.TryGetValue(key, var found))
		{
			let matches = (found.Ids[0] == index.UniqueId) && (found.Ids[1] == weight.UniqueId)
				&& (found.Ids[2] == @base.UniqueId) && (found.Ids[3] == palette.UniqueId)
				&& (found.Ids[4] == baseNormal.UniqueId) && (found.Ids[5] == normalArray.UniqueId)
				&& (found.Ids[6] == baseOrm.UniqueId) && (found.Ids[7] == ormArray.UniqueId)
				&& (found.Ids[8] == baseHeight.UniqueId) && (found.Ids[9] == heightArray.UniqueId)
				&& (found.Ids[10] == maskArray.UniqueId)
				&& (found.TileGeneration == tileGeneration);
			if (matches)
				return found.BindGroup;

			if (found.BindGroup != null)
				RetireBindGroup(ref found.BindGroup);
			mMaterialBindGroups.Remove(key);
		}

		let tilesSize = (data.TileScaleBuffer != null)
			? ((uint64)data.PaletteCount * sizeof(float))
			: (uint64)sizeof(float);

		var entries = BindGroupEntry[13](
			BindGroupEntry.TextureEntry(index),
			BindGroupEntry.TextureEntry(weight),
			BindGroupEntry.TextureEntry(@base),
			BindGroupEntry.TextureEntry(palette),
			BindGroupEntry.BufferEntry(tiles, 0, tilesSize),
			BindGroupEntry.TextureEntry(baseNormal),
			BindGroupEntry.TextureEntry(normalArray),
			BindGroupEntry.TextureEntry(baseOrm),
			BindGroupEntry.TextureEntry(ormArray),
			BindGroupEntry.TextureEntry(baseHeight),
			BindGroupEntry.TextureEntry(heightArray),
			BindGroupEntry.TextureEntry(maskArray),
			BindGroupEntry.SamplerEntry(mAlbedoSampler));

		var desc = BindGroupDesc();
		desc.Layout = mMaterialLayout;
		desc.Entries = .(&entries[0], 13);
		if (!(mDevice.CreateBindGroup(desc) case .Ok(let created)))
			return null;

		var entry = MaterialBindGroup();
		entry.BindGroup = created;
		entry.Ids = .(index.UniqueId, weight.UniqueId, @base.UniqueId, palette.UniqueId,
			baseNormal.UniqueId, normalArray.UniqueId, baseOrm.UniqueId, ormArray.UniqueId,
			baseHeight.UniqueId, heightArray.UniqueId, maskArray.UniqueId);
		entry.TileGeneration = tileGeneration;
		mMaterialBindGroups[key] = entry;
		return created;
	}

	/// A group may still sit in a submitted frame's descriptor bindings, so it ages out
	/// through the queue where one is wired, and is destroyed in place only where none is,
	/// which a headless test is.
	private void RetireBindGroup(ref IBindGroup bindGroup)
	{
		if (mRetire != null)
		{
			mRetire.Retire(bindGroup);
			bindGroup = null;
			return;
		}

		mDevice.DestroyBindGroup(ref bindGroup);
	}

	// ==================== Pipelines ====================

	private IRenderPipeline EnsurePipeline(TextureFormat colorFormat)
	{
		let shaderVersion = mShaders.Version("terrain");
		if ((mPso != null) && (mPsoFormat == colorFormat) && (mPsoShaderVersion == shaderVersion))
			return mPso;

		if (mPso != null)
			mDevice.DestroyRenderPipeline(ref mPso);

		let vs = mShaders.GetVariant("terrain", .Vertex, .None);
		let ps = mShaders.GetVariant("terrain", .Fragment, .None);
		if ((vs == null) || (ps == null))
			return null;

		var attributes = VertexAttribute[1](.(.Float32x3, 0, 0));

		var layout = VertexBufferLayout();
		layout.Stride = sizeof(Float3);
		layout.StepMode = .Vertex;
		layout.Attributes = .(&attributes[0], 1);

		// Opaque terrain writes the whole gbuffer: the shaded colour, the view space normal,
		// the motion vector, and the material terms. The forward pass binds all four, so the
		// pipeline must declare all four.
		var targets = ColorTargetState[4](.(), .(), .(), .());
		targets[0].Format = colorFormat;
		targets[1].Format = RenderFormats.GNormal;
		targets[2].Format = RenderFormats.GVelocity;
		targets[3].Format = RenderFormats.GMaterial;

		var fragment = FragmentState();
		fragment.Shader = .(ps, "main", .Fragment);
		fragment.Targets = .(&targets[0], 4);

		var depthStencil = DepthStencilState();
		depthStencil.Format = mDepthFormat;
		depthStencil.DepthTestEnabled = true;
		depthStencil.DepthWriteEnabled = true;
		// An equal depth fragment from the prepass must PASS, so each pixel shades once.
		depthStencil.DepthCompare = Depth.NearerOrEqual;

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vs, "main", .Vertex);
		desc.Vertex.Buffers = .(&layout, 1);
		desc.Fragment = fragment;
		desc.DepthStencil = depthStencil;
		desc.Primitive.Topology = .TriangleList;
		// The grid winds counter clockwise seen from above, which is the default front face,
		// so the top surface IS the front: cull the backs. Getting this the other way round
		// culls the top and the frame goes black.
		desc.Primitive.CullMode = .Back;
		desc.Label = "terrain";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pso)))
			return null;

		mPso = pso;
		mPsoFormat = colorFormat;
		mPsoShaderVersion = shaderVersion;
		return pso;
	}

	/// The depth only pipeline: vertex stage alone, no colour targets. `biased` adds the
	/// shadow pass's slope scaled bias.
	///
	/// INVARIANCE. The CAMERA prepass, which takes no bias, uses the MAIN terrain vertex
	/// shader, the very module the colour pass rasterizes with, so both passes produce bit
	/// identical clip positions and the colour pass's equal test never loses fragments to a
	/// last bit difference. A separately compiled twin, source identical though it is, may
	/// reassociate the transform; at distance the per pixel depth gradient falls below that
	/// difference and whole rows of fragments drop out. The extra interpolants are discarded,
	/// there being no fragment stage, and the vertex shader touches the first three sets only,
	/// so the three set layout still fits. The shadow passes keep the cheap depth shader,
	/// cascade depth never being tested against the colour pass.
	private IRenderPipeline EnsureDepthPipeline(TextureFormat depthFormat, bool biased)
	{
		let shaderName = biased ? "terrain_depth" : "terrain";
		var entry = ref mDepthPso[biased ? 1 : 0];

		let shaderVersion = mShaders.Version(shaderName);
		if ((entry.Pso != null) && (entry.Format == depthFormat)
			&& (entry.ShaderVersion == shaderVersion))
			return entry.Pso;

		if (entry.Pso != null)
			mDevice.DestroyRenderPipeline(ref entry.Pso);

		let vs = mShaders.GetVariant(shaderName, .Vertex, .None);
		if (vs == null)
			return null;

		var attributes = VertexAttribute[1](.(.Float32x3, 0, 0));

		var layout = VertexBufferLayout();
		layout.Stride = sizeof(Float3);
		layout.StepMode = .Vertex;
		layout.Attributes = .(&attributes[0], 1);

		var depthStencil = DepthStencilState();
		depthStencil.Format = depthFormat;
		depthStencil.DepthTestEnabled = true;
		depthStencil.DepthWriteEnabled = true;
		depthStencil.DepthCompare = Depth.Nearer;
		if (biased)
		{
			depthStencil.DepthBias = Depth.BiasAwayFromViewer(50);
			depthStencil.DepthBiasSlopeScale = Depth.SlopeBiasAwayFromViewer(1.5f);
		}

		var desc = RenderPipelineDesc();
		// Three sets, the material left out: the depth vertex shader samples none of it.
		desc.Layout = mDepthPipelineLayout;
		desc.Vertex.Shader = .(vs, "main", .Vertex);
		desc.Vertex.Buffers = .(&layout, 1);
		// No fragment stage and no colour targets is what makes it depth only.
		desc.DepthStencil = depthStencil;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .Back;
		desc.Label = "terrain.depth";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pso)))
			return null;

		entry.Pso = pso;
		entry.Format = depthFormat;
		entry.ShaderVersion = shaderVersion;
		return pso;
	}

	/// The pick pipeline: the depth cast's layout and vertex path with the id writing fragment
	/// into the single RG32Uint target, no bias, the nearest surface owning the texel.
	private IRenderPipeline EnsurePickPipeline(TextureFormat colorFormat,
		TextureFormat depthFormat)
	{
		let shaderVersion = mShaders.Version("terrain_pick");
		if ((mPickPso.Pso != null) && (mPickPso.ColorFormat == colorFormat)
			&& (mPickPso.DepthFormat == depthFormat) && (mPickPso.ShaderVersion == shaderVersion))
			return mPickPso.Pso;

		if (mPickPso.Pso != null)
			mDevice.DestroyRenderPipeline(ref mPickPso.Pso);

		let vs = mShaders.GetVariant("terrain_pick", .Vertex, .None);
		let ps = mShaders.GetVariant("terrain_pick", .Fragment, .None);
		if ((vs == null) || (ps == null))
			return null;

		var attributes = VertexAttribute[1](.(.Float32x3, 0, 0));

		var layout = VertexBufferLayout();
		layout.Stride = sizeof(Float3);
		layout.StepMode = .Vertex;
		layout.Attributes = .(&attributes[0], 1);

		var targets = ColorTargetState[1](.());
		targets[0].Format = colorFormat;

		var fragment = FragmentState();
		fragment.Shader = .(ps, "main", .Fragment);
		fragment.Targets = .(&targets[0], 1);

		var depthStencil = DepthStencilState();
		depthStencil.Format = depthFormat;
		depthStencil.DepthTestEnabled = true;
		depthStencil.DepthWriteEnabled = true;
		depthStencil.DepthCompare = Depth.Nearer;

		var desc = RenderPipelineDesc();
		desc.Layout = mDepthPipelineLayout;
		desc.Vertex.Shader = .(vs, "main", .Vertex);
		desc.Vertex.Buffers = .(&layout, 1);
		desc.Fragment = fragment;
		desc.DepthStencil = depthStencil;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .Back;
		desc.Label = "terrain.pick";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pso)))
			return null;

		mPickPso.Pso = pso;
		mPickPso.ColorFormat = colorFormat;
		mPickPso.DepthFormat = depthFormat;
		mPickPso.ShaderVersion = shaderVersion;
		return pso;
	}

	// ==================== Creation ====================

	private Result<void> CreateLayouts()
	{
		// Set nought: the per terrain view constants at a dynamic offset, the cascade array,
		// and the comparison sampler. The depth cast pass reads only the constants, but
		// sharing one layout keeps a single pipeline layout across both passes.
		var viewEntry = BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment);
		viewEntry.HasDynamicOffset = true;

		var shadowTextureEntry = BindGroupLayoutEntry.SampledTexture(1, .Fragment,
			.Texture2DArray);
		shadowTextureEntry.TextureSampleType = .Depth;

		var shadowSamplerEntry = BindGroupLayoutEntry();
		shadowSamplerEntry.Binding = 0;
		shadowSamplerEntry.Visibility = .Fragment;
		shadowSamplerEntry.Type = .ComparisonSampler;

		var viewEntries = BindGroupLayoutEntry[3](viewEntry, shadowTextureEntry,
			shadowSamplerEntry);
		var viewDesc = BindGroupLayoutDesc();
		viewDesc.Entries = .(&viewEntries[0], 3);
		if (!(mDevice.CreateBindGroupLayout(viewDesc) case .Ok(let viewLayout)))
			return .Err;
		mViewLayout = viewLayout;

		// Set one: the per chunk placement, one slot per visible chunk.
		var chunkEntry = BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment);
		chunkEntry.HasDynamicOffset = true;

		var chunkDesc = BindGroupLayoutDesc();
		chunkDesc.Entries = .(&chunkEntry, 1);
		if (!(mDevice.CreateBindGroupLayout(chunkDesc) case .Ok(let chunkLayout)))
			return .Err;
		mChunkLayout = chunkLayout;

		// Set two: the height texture, fetched exactly in the vertex shader, and again in the
		// pixel shader for the normal.
		var heightEntry = BindGroupLayoutEntry.SampledTexture(0, .Vertex | .Fragment);
		heightEntry.TextureSampleType = .Uint;

		var heightDesc = BindGroupLayoutDesc();
		heightDesc.Entries = .(&heightEntry, 1);
		if (!(mDevice.CreateBindGroupLayout(heightDesc) case .Ok(let heightLayout)))
			return .Err;
		mHeightLayout = heightLayout;

		// Set three: the top layer splat material. The indices and the weights are read
		// exactly; filtering a layer id would interpolate one layer into another and produce
		// a layer nobody painted.
		var indexEntry = BindGroupLayoutEntry.SampledTexture(0, .Fragment);
		indexEntry.TextureSampleType = .Uint;
		var weightEntry = BindGroupLayoutEntry.SampledTexture(1, .Fragment);
		weightEntry.TextureSampleType = .UnfilterableFloat;

		var materialEntries = BindGroupLayoutEntry[13](
			indexEntry,
			weightEntry,
			BindGroupLayoutEntry.SampledTexture(2, .Fragment),
			BindGroupLayoutEntry.SampledTexture(3, .Fragment, .Texture2DArray),
			BindGroupLayoutEntry.StorageBuffer(4, .Fragment, true, sizeof(float)),
			BindGroupLayoutEntry.SampledTexture(5, .Fragment),
			BindGroupLayoutEntry.SampledTexture(6, .Fragment, .Texture2DArray),
			BindGroupLayoutEntry.SampledTexture(7, .Fragment),
			BindGroupLayoutEntry.SampledTexture(8, .Fragment, .Texture2DArray),
			BindGroupLayoutEntry.SampledTexture(9, .Fragment),
			BindGroupLayoutEntry.SampledTexture(10, .Fragment, .Texture2DArray),
			BindGroupLayoutEntry.SampledTexture(11, .Fragment, .Texture2DArray),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		var materialDesc = BindGroupLayoutDesc();
		materialDesc.Entries = .(&materialEntries[0], 13);
		if (!(mDevice.CreateBindGroupLayout(materialDesc) case .Ok(let materialLayout)))
			return .Err;
		mMaterialLayout = materialLayout;

		var colorLayouts = IBindGroupLayout[4](mViewLayout, mChunkLayout, mHeightLayout,
			mMaterialLayout);
		var colorDesc = PipelineLayoutDesc();
		colorDesc.BindGroupLayouts = .(&colorLayouts[0], 4);
		if (!(mDevice.CreatePipelineLayout(colorDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var depthLayouts = IBindGroupLayout[3](mViewLayout, mChunkLayout, mHeightLayout);
		var depthDesc = PipelineLayoutDesc();
		depthDesc.BindGroupLayouts = .(&depthLayouts[0], 3);
		if (!(mDevice.CreatePipelineLayout(depthDesc) case .Ok(let depthPipelineLayout)))
			return .Err;
		mDepthPipelineLayout = depthPipelineLayout;

		return .Ok;
	}

	private Result<void> CreateGridBuffers()
	{
		let vertices = scope List<Float3>();
		TerrainMesh.BuildChunkGridVertices(vertices);
		mGridVertexCount = (uint32)vertices.Count;

		var vertexDesc = BufferDesc();
		vertexDesc.Size = (uint64)vertices.Count * sizeof(Float3);
		vertexDesc.Usage = .Vertex | .CopyDst;
		vertexDesc.Memory = .CpuToGpu;
		vertexDesc.Label = "terrain.grid.verts";
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mGridVertexBuffer = vertexBuffer;

		let mappedVertices = mGridVertexBuffer.Map();
		if (mappedVertices != null)
		{
			Internal.MemCpy(mappedVertices, vertices.Ptr, vertices.Count * sizeof(Float3));
			mGridVertexBuffer.Unmap();
		}

		// One index buffer per level, each a stride of two to the level over the shared grid.
		for (uint32 lod = 0; lod <= TerrainMesh.MaxChunkLod; lod++)
		{
			let indices = scope List<uint32>();
			TerrainMesh.BuildChunkGridIndices(lod, indices);

			var mesh = ref mLodMeshes[lod];
			mesh.IndexCount = (uint32)indices.Count;
			mesh.SurfaceIndexCount = TerrainMesh.ChunkLodSurfaceIndexCount(lod);
			if (mesh.IndexCount == 0)
				continue;

			var indexDesc = BufferDesc();
			indexDesc.Size = (uint64)indices.Count * sizeof(uint32);
			indexDesc.Usage = .Index | .CopyDst;
			indexDesc.Memory = .CpuToGpu;
			indexDesc.Label = "terrain.grid.indices";
			if (!(mDevice.CreateBuffer(indexDesc) case .Ok(let indexBuffer)))
				return .Err;
			mesh.IndexBuffer = indexBuffer;

			let mappedIndices = mesh.IndexBuffer.Map();
			if (mappedIndices != null)
			{
				Internal.MemCpy(mappedIndices, indices.Ptr, indices.Count * sizeof(uint32));
				mesh.IndexBuffer.Unmap();
			}
		}

		return .Ok;
	}

	private Result<void> CreateShadowResources()
	{
		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		samplerDesc.MipmapFilter = .Nearest;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		// Lit where the fragment's depth is at or before the stored one.
		samplerDesc.Compare = Depth.NearerOrEqual; // lit when the receiver is at or nearer than the occluder
		samplerDesc.Label = "terrain.shadowSampler";
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mShadowSampler = sampler;

		var textureDesc = TextureDesc();
		textureDesc.Format = .Depth32Float;
		textureDesc.Width = 1;
		textureDesc.Height = 1;
		textureDesc.ArrayLayerCount = 1;
		textureDesc.Usage = .DepthStencil | .Sampled;
		textureDesc.Label = "terrain.dummyShadow";
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return .Err;
		mDummyShadowTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .Depth32Float;
		viewDesc.Aspect = .DepthOnly;
		viewDesc.Dimension = .Texture2DArray;
		viewDesc.ArrayLayerCount = 1;
		if (!(mDevice.CreateTextureView(mDummyShadowTexture, viewDesc) case .Ok(let view)))
			return .Err;
		mDummyShadowView = view;
		mActiveShadowView = mDummyShadowView;

		return .Ok;
	}

	private Result<void> CreateMaterialFallbacks()
	{
		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		// Trilinear across the albedo mips, which the base and the palette slices carry.
		samplerDesc.MipmapFilter = .Linear;
		samplerDesc.AddressU = .Repeat;
		samplerDesc.AddressV = .Repeat;
		samplerDesc.AddressW = .Repeat;
		samplerDesc.Label = "terrain.albedoSampler";
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mAlbedoSampler = sampler;

		if (CreateFallback("terrain.white", .RGBA8Unorm, false, ref mWhiteTexture,
			ref mWhiteView) case .Err)
			return .Err;
		if (CreateFallback("terrain.zeroWeights", .RGBA8Unorm, false, ref mZeroWeightTexture,
			ref mZeroWeightView) case .Err)
			return .Err;
		if (CreateFallback("terrain.zeroIndices", .RGBA8Uint, false, ref mZeroIndexTexture,
			ref mZeroIndexView) case .Err)
			return .Err;
		if (CreateFallback("terrain.whiteArray", .RGBA8Unorm, true, ref mWhiteArrayTexture,
			ref mWhiteArrayView) case .Err)
			return .Err;
		if (CreateFallback("terrain.flatNormal", .RGBA8Unorm, false, ref mFlatNormalTexture,
			ref mFlatNormalView) case .Err)
			return .Err;
		if (CreateFallback("terrain.flatNormalArray", .RGBA8Unorm, true,
			ref mFlatNormalArrayTexture, ref mFlatNormalArrayView) case .Err)
			return .Err;
		if (CreateFallback("terrain.defaultOrm", .RGBA8Unorm, false, ref mDefaultOrmTexture,
			ref mDefaultOrmView) case .Err)
			return .Err;
		if (CreateFallback("terrain.defaultOrmArray", .RGBA8Unorm, true,
			ref mDefaultOrmArrayTexture, ref mDefaultOrmArrayView) case .Err)
			return .Err;
		if (CreateFallback("terrain.midHeight", .RGBA8Unorm, false, ref mMidHeightTexture,
			ref mMidHeightView) case .Err)
			return .Err;
		if (CreateFallback("terrain.midHeightArray", .RGBA8Unorm, true,
			ref mMidHeightArrayTexture, ref mMidHeightArrayView) case .Err)
			return .Err;
		if (CreateFallback("terrain.opaqueMaskArray", .RGBA8Unorm, true,
			ref mOpaqueMaskArrayTexture, ref mOpaqueMaskArrayView) case .Err)
			return .Err;

		var bufferDesc = BufferDesc();
		bufferDesc.Size = sizeof(float);
		bufferDesc.Usage = .StorageRead | .CopyDst;
		bufferDesc.Memory = .CpuToGpu;
		bufferDesc.Label = "terrain.dummyTileScales";
		if (!(mDevice.CreateBuffer(bufferDesc) case .Ok(let buffer)))
			return .Err;
		mDummyTileBuffer = buffer;

		let mapped = mDummyTileBuffer.Map();
		if (mapped != null)
		{
			float one = 1.0f;
			Internal.MemCpy(mapped, &one, sizeof(float));
			mDummyTileBuffer.Unmap();
		}

		return .Ok;
	}

	private Result<void> CreateFallback(StringView label, TextureFormat format, bool array,
		ref ITexture outTexture, ref ITextureView outView)
	{
		var textureDesc = TextureDesc();
		textureDesc.Format = format;
		textureDesc.Width = 1;
		textureDesc.Height = 1;
		textureDesc.ArrayLayerCount = 1;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = label;
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return .Err;
		outTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = format;
		viewDesc.Dimension = array ? .Texture2DArray : .Texture2D;
		viewDesc.ArrayLayerCount = 1;
		if (!(mDevice.CreateTextureView(texture, viewDesc) case .Ok(let view)))
			return .Err;
		outView = view;

		return .Ok;
	}

	private void UploadFallbackPixels()
	{
		let queue = mDevice.GetQueue(.Graphics);
		if (queue == null)
			return;

		if (!(queue.CreateTransferBatch() case .Ok(var batch)))
			return;

		var layout = TextureDataLayout();
		layout.BytesPerRow = 4;
		layout.RowsPerImage = 1;

		uint8[4] white = .(255, 255, 255, 255);
		uint8[4] zero = .(0, 0, 0, 0);
		// Tangent space plus Z.
		uint8[4] flatNormal = .(128, 128, 255, 255);
		// Occlusion one, roughness one, metallic nought.
		uint8[4] defaultOrm = .(255, 255, 0, 255);
		// A height of a half, read from the red channel.
		uint8[4] midHeight = .(128, 128, 128, 255);
		// Full coverage, read the same way.
		uint8[4] opaqueMask = .(255, 255, 255, 255);

		Write(batch, mWhiteTexture, ref white, layout);
		Write(batch, mZeroWeightTexture, ref zero, layout);
		Write(batch, mZeroIndexTexture, ref zero, layout);
		Write(batch, mWhiteArrayTexture, ref white, layout);
		Write(batch, mFlatNormalTexture, ref flatNormal, layout);
		Write(batch, mFlatNormalArrayTexture, ref flatNormal, layout);
		Write(batch, mDefaultOrmTexture, ref defaultOrm, layout);
		Write(batch, mDefaultOrmArrayTexture, ref defaultOrm, layout);
		Write(batch, mMidHeightTexture, ref midHeight, layout);
		Write(batch, mMidHeightArrayTexture, ref midHeight, layout);
		Write(batch, mOpaqueMaskArrayTexture, ref opaqueMask, layout);

		batch.Submit().IgnoreError();
		queue.DestroyTransferBatch(ref batch);
	}

	private static void Write(ITransferBatch batch, ITexture texture, ref uint8[4] pixel,
		TextureDataLayout layout)
	{
		if (texture == null)
			return;

		batch.WriteTexture(texture, .(&pixel[0], 4), layout, .(1, 1, 1));
	}

	// ==================== Teardown ====================

	private void Shutdown()
	{
		for (var pair in mHeightBindGroups)
		{
			var group = pair.value.BindGroup;
			if (group != null)
				mDevice.DestroyBindGroup(ref group);
		}
		mHeightBindGroups.Clear();

		for (var pair in mMaterialBindGroups)
		{
			var group = pair.value.BindGroup;
			if (group != null)
				mDevice.DestroyBindGroup(ref group);
		}
		mMaterialBindGroups.Clear();

		if (mViewBindGroup != null)
			mDevice.DestroyBindGroup(ref mViewBindGroup);
		if (mDepthViewBindGroup != null)
			mDevice.DestroyBindGroup(ref mDepthViewBindGroup);
		if (mChunkBindGroup != null)
			mDevice.DestroyBindGroup(ref mChunkBindGroup);

		if (mPso != null)
			mDevice.DestroyRenderPipeline(ref mPso);
		for (int i < mDepthPso.Count)
		{
			if (mDepthPso[i].Pso != null)
				mDevice.DestroyRenderPipeline(ref mDepthPso[i].Pso);
		}
		if (mPickPso.Pso != null)
			mDevice.DestroyRenderPipeline(ref mPickPso.Pso);

		for (int i < mLodMeshes.Count)
		{
			if (mLodMeshes[i].IndexBuffer != null)
				mDevice.DestroyBuffer(ref mLodMeshes[i].IndexBuffer);
		}
		if (mGridVertexBuffer != null)
			mDevice.DestroyBuffer(ref mGridVertexBuffer);

		if (mDummyShadowView != null)
			mDevice.DestroyTextureView(ref mDummyShadowView);
		if (mDummyShadowTexture != null)
			mDevice.DestroyTexture(ref mDummyShadowTexture);
		if (mShadowSampler != null)
			mDevice.DestroySampler(ref mShadowSampler);
		mActiveShadowView = null;

		DestroyFallback(ref mWhiteTexture, ref mWhiteView);
		DestroyFallback(ref mZeroWeightTexture, ref mZeroWeightView);
		DestroyFallback(ref mZeroIndexTexture, ref mZeroIndexView);
		DestroyFallback(ref mWhiteArrayTexture, ref mWhiteArrayView);
		DestroyFallback(ref mFlatNormalTexture, ref mFlatNormalView);
		DestroyFallback(ref mFlatNormalArrayTexture, ref mFlatNormalArrayView);
		DestroyFallback(ref mDefaultOrmTexture, ref mDefaultOrmView);
		DestroyFallback(ref mDefaultOrmArrayTexture, ref mDefaultOrmArrayView);
		DestroyFallback(ref mMidHeightTexture, ref mMidHeightView);
		DestroyFallback(ref mMidHeightArrayTexture, ref mMidHeightArrayView);
		DestroyFallback(ref mOpaqueMaskArrayTexture, ref mOpaqueMaskArrayView);

		if (mDummyTileBuffer != null)
			mDevice.DestroyBuffer(ref mDummyTileBuffer);
		if (mAlbedoSampler != null)
			mDevice.DestroySampler(ref mAlbedoSampler);

		if (mDepthPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mDepthPipelineLayout);
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);

		if (mMaterialLayout != null)
			mDevice.DestroyBindGroupLayout(ref mMaterialLayout);
		if (mHeightLayout != null)
			mDevice.DestroyBindGroupLayout(ref mHeightLayout);
		if (mChunkLayout != null)
			mDevice.DestroyBindGroupLayout(ref mChunkLayout);
		if (mViewLayout != null)
			mDevice.DestroyBindGroupLayout(ref mViewLayout);
	}

	private void DestroyFallback(ref ITexture texture, ref ITextureView view)
	{
		if (view != null)
			mDevice.DestroyTextureView(ref view);
		if (texture != null)
			mDevice.DestroyTexture(ref texture);
	}
}
