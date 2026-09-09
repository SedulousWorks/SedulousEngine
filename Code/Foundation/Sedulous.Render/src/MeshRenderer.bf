using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// The renderer for the mesh categories.
///
/// It owns the forward shader's permutations, the GPU rings and the mesh cache, and records
/// draws for the mesh items it is handed.
///
/// HYBRID INSTANCING. A run of consecutive draws sharing one mesh and material is issued as a
/// single instanced draw; a lone draw takes the simpler per object path. Both read the view
/// from a shared per view block. The per object path adds a per object block at a dynamic
/// offset; the instanced path adds a per instance structured buffer indexed by an instance
/// stepped vertex attribute, which is the PORTABLE addressing: the built in instance index
/// has a different base on different backends. A transparent draw is never instanced, because
/// its back to front order has to dominate.
class MeshRenderer : Renderer
{
	/// The dynamic offset alignment, which is what an object or shadow view slot costs.
	private const uint64 cViewSlot = 256;
	/// The view block is larger than one alignment unit, the cascades seeing to that.
	private const uint64 cViewDataSlot = 1024;
	/// The per view light budget, the clustering doing the narrowing.
	private const uint32 cMaxLights = 256;
	/// One per shadow pass and category run, sized with headroom since a slot is tiny.
	private const uint32 cMaxShadowPasses = 256;
	private const uint32 cMaxLocalShadows = RenderLimits.MaxLocalShadowEntries;
	/// The skinning pool's slots per frame. Each caster's bones are re-emitted per pass, so
	/// the usage is the caster count times its bones times the passes, and this is sized so a
	/// stress test does not overflow it.
	private const uint32 cMaxBoneMatrices = 1 << 20;

	private const uint64 cShBytes = sizeof(float) * 4 * 9;
	private const uint64 cProbeBufferBytes = 64 * RenderLimits.MaxReflectionProbes;

	private const int cMaxFramesInFlight = 8;
	private const int cMaxViewsPerFrame = 8;
	private const int cMaxClusterSlots = cMaxViewsPerFrame * cMaxFramesInFlight;

	/// A material instance whose material has not been drawn for this many frames is dropped,
	/// so a stale group stops holding destroyed texture views alive.
	private const uint32 cInstanceEvictFrames = 240;

	private static uint16[3] sCategories = .(RenderCategories.Opaque, RenderCategories.Masked,
		RenderCategories.Transparent);

	/// Where one skinning palette landed in the shared pool, in MATRIX units.
	private struct BoneSlot
	{
		public uint32 Base;
		public uint32 PrevBase;
	}

	/// A palette to upload. The current and previous pointers, and how many matrices the
	/// current holds. A per entity caster writes a current and a previous slab, for the
	/// motion vectors; a crowd's POSE POOL writes only its palettes.
	private struct SkinnedRef
	{
		public Float4x4* Current;
		public Float4x4* Previous;
		public uint32 Count;
		public bool HasPrevious;
	}

	/// The depth prepass's filled instance range, for the forward to reuse.
	private struct InstShare
	{
		public uint64 OffsetsByteOffset;
		public uint32 Count;
	}

	private struct RetiredBindGroup
	{
		public IBindGroup Group;
		public uint32 FramesLeft;
	}

	private struct RetiredBuffer
	{
		public IBuffer Buffer;
		public uint32 FramesLeft;
	}

	/// One view's set nought group and everything it was built against.
	private struct ViewBindGroupSlot
	{
		public IBindGroup Group;
		public uint32 ViewGeneration;
		public uint32 LightGeneration;
		public uint32 LocalGeneration;
		public uint32 BoneGeneration;
		public ITextureView Shadow;
		public uint64 ShadowGeneration;
		public ITextureView Atlas;
		public uint64 AtlasGeneration;
		public uint64 IblGeneration;
		public ITextureView Prefilter;
		public ITextureView ProbeCube;
		public IBuffer ProbeBuffer;
	}

	/// A material instance and when it was last drawn.
	private struct InstanceEntry
	{
		public MaterialInstance Instance;
		public uint32 LastFrame;
	}

	private IDevice mDevice;
	private ShaderSystem mShaders;
	private PipelineStateCache mPsoCache;
	private MaterialSystem mMaterials;
	private GpuMeshCache mMeshes ~ delete _;

	private uint32 mFramesInFlight;
	private uint32 mFrameIndex = 0;
	/// A monotonically rising count of frames prepared, which the instance eviction clocks on.
	private uint32 mFrameClock = 0;

	/// Borrowed. Null means draining the device on a grow instead.
	private GpuRetireQueue mRetire = null;

	private IBindGroupLayout mViewLayout = null;
	private IBindGroupLayout mObjectLayout = null;
	private IBindGroupLayout mInstanceLayout = null;
	private IBindGroupLayout mClusterLayout = null;
	private IBindGroupLayout mShadowViewLayout = null;

	private IPipelineLayout mShadowPipelineLayoutSingle = null;
	private IPipelineLayout mShadowPipelineLayoutInstanced = null;

	/// Built on demand per material set layout, so each material's own layout drives its
	/// pipeline and a custom shader needs no change here at all.
	private Dictionary<uint64, IPipelineLayout> mPipelineLayouts = new .() ~ delete _;
	private Dictionary<uint64, IPipelineLayout> mShadowMaskedLayouts = new .() ~ delete _;

	/// A standard material, used by any draw that carries none. It flows through the same
	/// data driven path as any other, so there is nothing special about the case.
	private Material mDefaultMaterial = null ~ delete _;
	/// Keyed by the material's IDENTITY, never its reference: a reloaded material can land at
	/// the freed address, and a reference keyed instance would serve the dead one's textures.
	private Dictionary<uint64, InstanceEntry> mInstances = new .() ~ delete _;

	private DynamicUniformRing mViewRing ~ delete _;
	private DynamicUniformRing mShadowViewRing ~ delete _;
	private DynamicUniformRing mObjectRing ~ delete _;
	private DynamicUniformRing mInstanceRing ~ delete _;
	private DynamicUniformRing mOffsetsRing ~ delete _;
	private DynamicUniformRing mLightRing ~ delete _;
	private DynamicUniformRing mLocalShadowRing ~ delete _;
	/// The skinning STAGING ring, written once a frame and copied to the device.
	private DynamicUniformRing mBoneRing ~ delete _;

	/// A device local mirror of the staging ring. Skinning is read across many passes, the
	/// forward and every cascade, so a host visible buffer would stream the same matrices over
	/// the bus once per read; one copy a frame makes the rest land at device bandwidth.
	private IBuffer mBoneDevice = null;
	private uint64 mBoneDeviceBytes = 0;
	/// Bumped on recreation, which invalidates the groups that bind it.
	private uint32 mBoneDeviceGeneration = 0;

	/// This frame's palettes, keyed by their address.
	private Dictionary<int, BoneSlot> mBoneStart = new .() ~ delete _;
	private List<SkinnedRef> mSkinnedScratch = new .() ~ delete _;

	/// The per entity previous world, for a rigid object's motion vectors. A FLAT double
	/// buffer indexed by the entity's own index rather than a map: direct, with no hashing or
	/// probing, which is what the per instance lookup cost at scale. One holds LAST frame's,
	/// read by every view; a resolve writes this frame's into the other; the two swap at the
	/// end. An entry never written reads back as the current world, so a newly visible object
	/// does not smear on its first frame.
	private List<Float4x4> mPrevWorld = new .() ~ delete _;
	private List<Float4x4> mCurWorld = new .() ~ delete _;

	/// The camera prepass fills the full instance data for each opaque group once and records
	/// the range here; the forward looks it up and REUSES it rather than filling it again.
	/// Keyed by the view, the mesh and the material, and cleared each frame.
	private Dictionary<uint64, InstShare> mInstShareCache = new .() ~ delete _;

	/// The last level selected per view and item, persisted ACROSS frames, which is the point
	/// of hysteresis. Bounded by a cap: on overflow it clears wholesale, which costs at worst
	/// one frame of unsmoothed selection.
	private Dictionary<uint64, uint32> mLodLast = new .() ~ delete _;

	private List<RetiredBindGroup> mRetiredBindGroups = new .() ~ delete _;
	private List<RetiredBuffer> mRetiredBuffers = new .() ~ delete _;

	/// One slot per view: views of different scenes bind different environments in one frame.
	private List<ViewBindGroupSlot> mViewBindGroups = new .() ~ delete _;
	/// The CURRENT view's, borrowed from its slot.
	private IBindGroup mViewBindGroup = null;

	private IBindGroup mShadowViewBindGroup = null;
	private uint32 mShadowViewBindGroupGeneration = 0;
	private uint32 mShadowViewBindGroupBoneGeneration = 0;
	private IBindGroup mObjectBindGroup = null;
	private IBindGroup mInstanceBindGroup = null;
	private uint32 mObjectBindGroupGeneration = 0;
	private uint32 mInstanceBindGroupGeneration = 0;

	private ISampler mShadowSampler = null;
	private ITexture mDummyShadowTexture = null;
	private ITextureView mDummyShadowView = null;
	private ITextureView mActiveShadowView = null;
	private uint64 mActiveShadowGeneration = 0;

	/// The dummy depth textures are bound, and statically sampled by the shader, on a frame
	/// with no real caster, but they live OUTSIDE the graph, so the barrier solver never moves
	/// them out of their undefined initial state. They are transitioned once, the first time
	/// the encoder is held, so the layout always matches what the descriptor expects.
	private bool mDummyDepthInit = false;

	private ITexture mDummyAtlasTexture = null;
	private ITextureView mDummyAtlasView = null;
	private ITextureView mActiveAtlasView = null;
	private uint64 mActiveAtlasGeneration = 0;

	private uint32 mLocalShadowBase = 0;
	private uint32 mLocalShadowPassCount = 0;
	private uint32 mCaptureFacePasses = 0;

	private ISampler mEnvSampler = null;
	private IBuffer mDummyShBuffer = null;
	private ITexture mDummyCube = null;
	private ITextureView mDummyCubeView = null;
	private ITexture mDummyBrdf = null;
	private ITextureView mDummyBrdfView = null;

	private ITexture mDummyProbeCube = null;
	private ITextureView mDummyProbeCubeView = null;
	private IBuffer mDummyProbeBuffer = null;
	private ITextureView mActiveProbeCube = null;
	private IBuffer mActiveProbeBuffer = null;
	private uint32 mActiveProbeCount = 0;

	private Dictionary<uint64, MultiMeshSet> mMultiMeshSets = new .() ~ delete _;
	/// The shared offsets ramp, which serves EVERY set: the first component indexes that set's
	/// own buffer, so one static ramp does for all of them.
	private IBuffer mRampBuffer = null;
	private uint32 mRampCapacity = 0;
	private uint32 mMultiMeshFrame = 0;

	private IBuffer mDummyClusterOffsets = null;
	private IBuffer mDummyClusterIndices = null;
	private IBindGroup mDummyClusterBindGroup = null;
	private IBindGroup[cMaxClusterSlots] mClusterBindGroups;
	private IBuffer[cMaxClusterSlots] mClusterBindGroupOffsets;
	private uint32[cMaxClusterSlots] mClusterBindGroupVersions;

	private bool mReady = false;

	public this(IDevice device, ShaderSystem shaderSystem, PipelineStateCache psoCache,
		MaterialSystem materialSystem, uint32 framesInFlight)
	{
		mDevice = device;
		mShaders = shaderSystem;
		mPsoCache = psoCache;
		mMaterials = materialSystem;
		mMeshes = new .(device);
		mFramesInFlight = (framesInFlight < 1) ? 1 : framesInFlight;

		mViewRing = new .(device, framesInFlight, cViewDataSlot, .Uniform | .CopyDst, "mesh.view");
		mShadowViewRing = new .(device, framesInFlight, cViewSlot, .Uniform | .CopyDst,
			"mesh.shadowView");
		mObjectRing = new .(device, framesInFlight, cViewSlot, .Uniform | .CopyDst, "mesh.object");
		mInstanceRing = new .(device, framesInFlight, sizeof(MeshInstanceData),
			.StorageRead | .CopyDst, "mesh.instances");
		mOffsetsRing = new .(device, framesInFlight, sizeof(MeshDataOffsets),
			.Vertex | .CopyDst, "mesh.offsets");
		mLightRing = new .(device, framesInFlight, sizeof(GpuLight), .StorageRead | .CopyDst,
			"mesh.lights");
		mLocalShadowRing = new .(device, framesInFlight, sizeof(GpuLocalShadow),
			.StorageRead | .CopyDst, "mesh.localShadows");
		mBoneRing = new .(device, framesInFlight, sizeof(Float4x4), .CopySrc, "mesh.bones.staging");
	}

	public ~this()
	{
		Shutdown();
	}

	/// Wires the retire queue the rings and buffers hand their outgrown allocations to. Null
	/// drains the device on a grow instead.
	public void SetRetireQueue(GpuRetireQueue retire)
	{
		mRetire = retire;
		mViewRing.SetRetireQueue(retire);
		mShadowViewRing.SetRetireQueue(retire);
		mObjectRing.SetRetireQueue(retire);
		mInstanceRing.SetRetireQueue(retire);
		mOffsetsRing.SetRetireQueue(retire);
		mLightRing.SetRetireQueue(retire);
		mLocalShadowRing.SetRetireQueue(retire);
		mBoneRing.SetRetireQueue(retire);
	}

	public Result<void> Initialize()
	{
		// Set nought is the frame contract every material plugs into: the view block at a
		// dynamic offset, the light list, the shadow maps and their comparison sampler, the
		// skinning pool, the environment products and the probes. Shadows fold in here rather
		// than taking a set of their own, the budget being four SETS and not four bindings.
		var viewEntry = BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment);
		viewEntry.HasDynamicOffset = true;

		var lightEntry = BindGroupLayoutEntry.StorageBuffer(0, .Fragment, true, sizeof(GpuLight));

		var shadowTexEntry = BindGroupLayoutEntry.SampledTexture(1, .Fragment, .Texture2DArray);
		shadowTexEntry.TextureSampleType = .Depth;

		var atlasTexEntry = BindGroupLayoutEntry.SampledTexture(2, .Fragment, .Texture2DArray);
		atlasTexEntry.TextureSampleType = .Depth;

		var localShadowEntry = BindGroupLayoutEntry.StorageBuffer(3, .Fragment, true,
			sizeof(GpuLocalShadow));

		var shadowSamplerEntry = BindGroupLayoutEntry();
		shadowSamplerEntry.Binding = 0;
		shadowSamplerEntry.Visibility = .Fragment;
		shadowSamplerEntry.Type = .ComparisonSampler;

		var boneEntry = BindGroupLayoutEntry.StorageBuffer(4, .Vertex, true, sizeof(Float4x4));
		var iblShEntry = BindGroupLayoutEntry.StorageBuffer(5, .Fragment, true, 16);
		var prefilterEntry = BindGroupLayoutEntry.SampledTexture(6, .Fragment, .TextureCube);
		var brdfEntry = BindGroupLayoutEntry.SampledTexture(7, .Fragment, .Texture2D);
		var envSamplerEntry = BindGroupLayoutEntry.Sampler(1, .Fragment);
		var probeEntry = BindGroupLayoutEntry.SampledTexture(8, .Fragment, .TextureCubeArray);
		var probeBufferEntry = BindGroupLayoutEntry.StorageBuffer(9, .Fragment, true,
			sizeof(GpuProbe));

		var set0 = BindGroupLayoutEntry[13](
			viewEntry, lightEntry, shadowTexEntry, atlasTexEntry, localShadowEntry,
			shadowSamplerEntry, boneEntry, iblShEntry, prefilterEntry, brdfEntry,
			envSamplerEntry, probeEntry, probeBufferEntry);

		var set0Desc = BindGroupLayoutDesc();
		set0Desc.Entries = .(&set0[0], 13);
		if (!(mDevice.CreateBindGroupLayout(set0Desc) case .Ok(let viewLayout)))
			return .Err;
		mViewLayout = viewLayout;

		// Set one, the per object form: the object block at a dynamic offset.
		var objectEntry = BindGroupLayoutEntry.UniformBuffer(0, .Vertex);
		objectEntry.HasDynamicOffset = true;
		mObjectLayout = MakeLayout(objectEntry);
		if (mObjectLayout == null)
			return .Err;

		// Set one, the instanced form: the per instance structured buffer.
		let instanceEntry = BindGroupLayoutEntry.StorageBuffer(0, .Vertex, true,
			sizeof(MeshInstanceData));
		mInstanceLayout = MakeLayout(instanceEntry);
		if (mInstanceLayout == null)
			return .Err;

		// Set two, the material, is NOT a fixed layout here: it is derived per material from
		// that material's own property list, and the pipeline layout assembled around it. That
		// is what makes the renderer material driven, a custom shader with a different
		// property set getting its own layout and pipeline with no change to this file.

		// Set three, the clustered light lists.
		var clusterOffsetsEntry = BindGroupLayoutEntry.StorageBuffer(0, .Fragment, true, 8);
		var clusterIndicesEntry = BindGroupLayoutEntry.StorageBuffer(1, .Fragment, true, 4);
		var set3 = BindGroupLayoutEntry[2](clusterOffsetsEntry, clusterIndicesEntry);

		var set3Desc = BindGroupLayoutDesc();
		set3Desc.Entries = .(&set3[0], 2);
		if (!(mDevice.CreateBindGroupLayout(set3Desc) case .Ok(let clusterLayout)))
			return .Err;
		mClusterLayout = clusterLayout;

		// The depth only path: a vertex stage and a two set layout, the light's view and the
		// SAME object or instance layouts the forward uses, so those groups are reused.
		var shadowViewEntry = BindGroupLayoutEntry.UniformBuffer(0, .Vertex);
		shadowViewEntry.HasDynamicOffset = true;
		// Its set nought carries the skinning pool too, so a skinned caster deforms its shadow.
		let shadowBoneEntry = BindGroupLayoutEntry.StorageBuffer(4, .Vertex, true,
			sizeof(Float4x4));
		var shadowSet0 = BindGroupLayoutEntry[2](shadowViewEntry, shadowBoneEntry);

		var shadowSet0Desc = BindGroupLayoutDesc();
		shadowSet0Desc.Entries = .(&shadowSet0[0], 2);
		if (!(mDevice.CreateBindGroupLayout(shadowSet0Desc) case .Ok(let shadowViewLayout)))
			return .Err;
		mShadowViewLayout = shadowViewLayout;

		mShadowPipelineLayoutSingle = MakePipelineLayout2(mShadowViewLayout, mObjectLayout);
		mShadowPipelineLayoutInstanced = MakePipelineLayout2(mShadowViewLayout, mInstanceLayout);
		if ((mShadowPipelineLayoutSingle == null) || (mShadowPipelineLayoutInstanced == null))
			return .Err;

		mDefaultMaterial = MaterialPresets.CreatePbr("__default_pbr");
		if (mDefaultMaterial == null)
			return .Err;

		if (CreateShadowResources() case .Err)
			return .Err;

		return CreateDummyClusters();
	}

	// ==================== The frame contract ====================

	public override Span<uint16> SupportedCategories => .(&sCategories[0], 3);

	/// This frame's directional shadow map, or null for the single pixel stand in.
	public override void SetShadowMap(ITextureView view, uint64 generation)
	{
		mActiveShadowView = (view != null) ? view : mDummyShadowView;
		// The stand in never changes.
		mActiveShadowGeneration = (view != null) ? generation : 0;
	}

	/// This frame's local light atlas, under the same contract. Each tile re-emits the casters,
	/// so the pass count feeds the ring sizing.
	public override void SetShadowAtlas(ITextureView view, uint64 generation, uint32 passCount)
	{
		mActiveAtlasView = (view != null) ? view : mDummyAtlasView;
		mActiveAtlasGeneration = (view != null) ? generation : 0;
		mLocalShadowPassCount = (view != null) ? passCount : 0;
	}

	/// Each probe capture face is a forward pass of its own, so they count into the rings.
	public override void SetCaptureFacePasses(uint32 passes)
	{
		mCaptureFacePasses = passes;
	}

	/// This frame's probes. A null view falls back to the stand ins and a count of nought,
	/// which keeps the shading on the global environment's reflection.
	public override void SetProbes(ITextureView cubeArray, IBuffer probeBuffer, uint32 count)
	{
		let has = (cubeArray != null) && (probeBuffer != null) && (count > 0);
		mActiveProbeCube = has ? cubeArray : mDummyProbeCubeView;
		mActiveProbeBuffer = has ? probeBuffer : mDummyProbeBuffer;
		mActiveProbeCount = has ? count : 0;
	}

	/// Uploads this frame's local shadow entries, bound whole: the shader reads them at the
	/// base stamped into each view's block.
	public override void UploadLocalShadows(Span<GpuLocalShadow> shadows, uint32 frameIndex)
	{
		mLocalShadowBase = 0;
		if (shadows.IsEmpty || !mReady)
			return;

		var count = (uint32)shadows.Length;
		if (count > cMaxLocalShadows)
			count = cMaxLocalShadows;

		let range = mLocalShadowRing.AllocateRange(count);
		if (range.Ok)
		{
			Internal.MemCpy(range.Ptr, shadows.Ptr, (int)count * sizeof(GpuLocalShadow));
			mLocalShadowBase = range.SlotIndex;
		}
	}

	/// Sizes every ring for the WHOLE frame's draws once, and opens this frame's region.
	public override void PrepareFrame(uint32 maxDraws, uint32 frameIndex)
	{
		mReady = false;
		mFrameClock++;
		PruneStaleMaterialInstances();
		// Free the per frame groups retired long enough ago to be idle, and the material
		// system's own replaced groups with them.
		TickRetired();
		mMaterials.TickRetired();

		if (maxDraws == 0)
			return;

		// The capacity is the draws times the passes that RE-EMIT them: the depth prepass and
		// the forward, then one per cascade, one per local shadow tile, and one per probe
		// capture face. Under counting overflows the rings at high draw counts, and an
		// allocation that fails is a draw that silently disappears.
		let drawCap = maxDraws * (2 + (uint32)ShadowCascades.Count + mLocalShadowPassCount
			+ mCaptureFacePasses);

		if (!mViewRing.Reserve(maxDraws) || !mShadowViewRing.Reserve(cMaxShadowPasses)
			|| !mObjectRing.Reserve(drawCap) || !mInstanceRing.Reserve(drawCap)
			|| !mOffsetsRing.Reserve(drawCap) || !mLightRing.Reserve(cMaxLights)
			|| !mLocalShadowRing.Reserve(cMaxLocalShadows) || !mBoneRing.Reserve(cMaxBoneMatrices))
			return;

		if (!EnsureBoneDevice())
			return;

		if (!EnsureShadowViewBindGroup()
			|| !EnsureRingBindGroup(mObjectRing, mObjectLayout, sizeof(MeshObjectData),
				ref mObjectBindGroup, ref mObjectBindGroupGeneration, false)
			|| !EnsureRingBindGroup(mInstanceRing, mInstanceLayout, 0, ref mInstanceBindGroup,
				ref mInstanceBindGroupGeneration, true))
			return;

		mFrameIndex = frameIndex;
		mViewRing.BeginFrame(frameIndex);
		mShadowViewRing.BeginFrame(frameIndex);
		mObjectRing.BeginFrame(frameIndex);
		mInstanceRing.BeginFrame(frameIndex);
		mOffsetsRing.BeginFrame(frameIndex);
		mLightRing.BeginFrame(frameIndex);
		mLocalShadowRing.BeginFrame(frameIndex);
		mBoneRing.BeginFrame(frameIndex);

		// Per frame: the prepass fills it and the forward reuses it, the offsets being scoped
		// to this frame's region of the ring.
		mInstShareCache.Clear();
		mReady = true;
	}

	public override void FinishFrame()
	{
		mViewRing.EndFrame();
		mShadowViewRing.EndFrame();
		mObjectRing.EndFrame();
		mInstanceRing.EndFrame();
		mBoneRing.EndFrame();
		mOffsetsRing.EndFrame();

		// This frame's worlds become next frame's previous ones. A flat swap of the two lists:
		// no clearing, since each visible entity overwrites its own slot when it resolves and a
		// slot for one that is no longer visible is never read. Both keep their capacity, so
		// the steady state allocates nothing.
		let recycled = mPrevWorld;
		mPrevWorld = mCurWorld;
		mCurWorld = recycled;
		mReady = false;
	}

	// ==================== Skinning and the instanced sets ====================

	/// The device local mirror of the staging ring, recreated when the ring's capacity moves.
	private bool EnsureBoneDevice()
	{
		let want = mBoneRing.ByteCapacity;
		if ((mBoneDevice != null) && (mBoneDeviceBytes == want))
			return true;

		// Idle only when REPLACING a live buffer: a first allocation has nothing to protect,
		// and a mid frame wait pumps the browser's event loop and drops the frame's submission.
		if (mBoneDevice != null)
			RetireOrDrainBuffer(ref mBoneDevice);

		var desc = BufferDesc();
		desc.Size = want;
		desc.Usage = .Storage | .CopyDst;
		desc.Memory = .GpuOnly;
		desc.Label = "mesh.bones.device";

		if (!(mDevice.CreateBuffer(desc) case .Ok(let buffer)))
		{
			mBoneDeviceBytes = 0;
			return false;
		}

		mBoneDevice = buffer;
		mBoneDeviceBytes = want;
		// Invalidate the groups that bind it.
		mBoneDeviceGeneration++;
		return true;
	}

	/// Writes every distinct skinned palette into the pool ONCE this frame and copies the
	/// populated range to the device, then records where each landed so a resolve can hand the
	/// draw its bone base. Before any pass: the alternative, uploading per pass, streams the
	/// same matrices once per cascade.
	public override void UploadSkinning(ExtractedScene scene, ICommandEncoder encoder)
	{
		mBoneStart.Clear();
		mSkinnedScratch.Clear();
		if (!mReady)
			return;

		UploadMultiMeshes(scene);

		// Once: bring the out of graph stand ins into the layout their descriptors expect, so
		// they are never sampled while undefined on a frame with no caster.
		if (!mDummyDepthInit)
		{
			if (mDummyShadowTexture != null)
				encoder.TransitionTexture(mDummyShadowTexture, .Undefined, .DepthStencilRead);
			if (mDummyAtlasTexture != null)
				encoder.TransitionTexture(mDummyAtlasTexture, .Undefined, .DepthStencilRead);
			if (mDummyCube != null)
				encoder.TransitionTexture(mDummyCube, .Undefined, .ShaderRead);
			if (mDummyBrdf != null)
				encoder.TransitionTexture(mDummyBrdf, .Undefined, .ShaderRead);
			if (mDummyProbeCube != null)
				encoder.TransitionTexture(mDummyProbeCube, .Undefined, .ShaderRead);
			mDummyDepthInit = true;
		}

		// First the DISTINCT palettes, keyed by address so a duplicate is skipped. Each per
		// entity caster costs twice its bones: the current slab and the previous one.
		uint32 total = 0;
		for (let data in scene.Items)
		{
			if ((data == null) || (data.RendererId != RendererId))
				continue;

			let mesh = (MeshRenderData)data;
			if ((mesh.BoneMatrices == null) || (mesh.BoneCount == 0))
				continue;
			if ((mesh.Mesh == null) || !mesh.Mesh.IsSkinned)
				continue;

			let key = (int)(void*)mesh.BoneMatrices;
			if (mBoneStart.ContainsKey(key))
				continue;

			mBoneStart[key] = .();
			mSkinnedScratch.Add(.()
				{
					Current = mesh.BoneMatrices, Previous = mesh.PreviousBoneMatrices,
					Count = mesh.BoneCount, HasPrevious = true
				});
			total += mesh.BoneCount * 2;
		}

		// Then the crowds' POSE POOLS: a set's palettes uploaded once, whatever its size.
		for (let data in scene.Items)
		{
			if ((data == null) || (data.RendererId != RendererId))
				continue;

			let mesh = (MeshRenderData)data;
			if (!mesh.MultiMesh)
				continue;

			let set = (MultiMeshRenderData)mesh;
			if ((set.PosePool == null) || (set.PoseCount == 0) || (set.BoneCount == 0))
				continue;
			if ((set.Mesh == null) || !set.Mesh.IsSkinned)
				continue;

			let key = (int)(void*)set.PosePool;
			if (mBoneStart.ContainsKey(key))
				continue;

			mBoneStart[key] = .();
			let poolCount = set.PoseCount * set.BoneCount;
			mSkinnedScratch.Add(.()
				{
					Current = set.PosePool, Previous = set.PreviousPosePool, Count = poolCount,
					HasPrevious = true
				});
			total += poolCount * 2;
		}

		if (total == 0)
		{
			mBoneStart.Clear();
			return;
		}

		let block = mBoneRing.AllocateRange(total);
		if (!block.Ok)
		{
			mBoneStart.Clear();
			return;
		}

		// Then write each into the block, current slab then previous, and record its bases.
		uint32 cursor = 0;
		for (let entry in mSkinnedScratch)
		{
			let count = entry.Count;
			let slotBase = block.SlotIndex + cursor;
			let destination = (Float4x4*)block.Ptr + cursor;

			Internal.MemCpy(destination, entry.Current, (int)count * sizeof(Float4x4));

			let key = (int)(void*)entry.Current;
			if (entry.HasPrevious)
			{
				Internal.MemCpy(destination + count,
					(entry.Previous != null) ? entry.Previous : entry.Current,
					(int)count * sizeof(Float4x4));
				mBoneStart[key] = .() { Base = slotBase, PrevBase = slotBase + count };
				cursor += count * 2;
			}
			else
			{
				mBoneStart[key] = .() { Base = slotBase, PrevBase = slotBase };
				cursor += count;
			}
		}

		// Mirror the populated range into device memory, then make it readable.
		encoder.CopyBufferToBuffer(mBoneRing.Buffer, block.ByteOffset, mBoneDevice,
			block.ByteOffset, (uint64)total * sizeof(Float4x4));
		encoder.TransitionBuffer(mBoneDevice, .CopyDst, .ShaderRead);

		FillSkinnedMultiMeshOffsets(scene);
	}

	/// Brings every instanced set's persistent buffer up to date and grows the shared ramp to
	/// the largest of them. A static set falls through instantly after its first upload, and
	/// that constant cost per frame is the whole point.
	private void UploadMultiMeshes(ExtractedScene scene)
	{
		mMultiMeshFrame++;

		uint32 maxCount = 0;
		for (let data in scene.Items)
		{
			if ((data == null) || (data.RendererId != RendererId))
				continue;

			let mesh = (MeshRenderData)data;
			if (!mesh.MultiMesh)
				continue;

			let set = (MultiMeshRenderData)mesh;
			if (set.InstanceCount > maxCount)
				maxCount = set.InstanceCount;
		}

		if (maxCount == 0)
			return;
		if (!EnsureRamp(maxCount))
			return;

		for (let data in scene.Items)
		{
			if ((data == null) || (data.RendererId != RendererId))
				continue;

			let mesh = (MeshRenderData)data;
			if (mesh.MultiMesh)
				EnsureMultiMeshSet((MultiMeshRenderData)mesh);
		}
	}

	/// Releases a replaced buffer through the retire queue when one is wired, which is what
	/// keeps a mid frame wait off the web, and drains otherwise. Nulls the reference either way.
	private void RetireOrDrainBuffer(ref IBuffer buffer)
	{
		if (buffer == null)
			return;

		if (mRetire != null)
		{
			mRetire.Retire(buffer);
			buffer = null;
			return;
		}

		mDevice.WaitIdle();
		mDevice.DestroyBuffer(ref buffer);
	}

	/// Grows the shared ramp to hold at least this many slots. Its values are static per
	/// index, so it is filled once per allocation and never rewritten.
	private bool EnsureRamp(uint32 count)
	{
		if ((mRampBuffer != null) && (count <= mRampCapacity))
			return true;

		// A frame in flight may still be reading the old one.
		if (mRampBuffer != null)
			RetireOrDrainBuffer(ref mRampBuffer);

		var desc = BufferDesc();
		desc.Size = (uint64)count * sizeof(MeshDataOffsets);
		desc.Usage = .Vertex | .CopyDst;
		desc.Memory = .CpuToGpu;
		desc.Label = "mesh.multimesh.ramp";

		if (!(mDevice.CreateBuffer(desc) case .Ok(let buffer)))
		{
			mRampCapacity = 0;
			return false;
		}
		mRampBuffer = buffer;

		let mapped = (MeshDataOffsets*)buffer.Map();
		if (mapped != null)
		{
			for (uint32 i = 0; i < count; i++)
				mapped[i] = .(i, 0, 0, 0);
			buffer.Unmap();
		}

		mRampCapacity = count;
		return true;
	}

	/// Brings one set's persistent buffer and its per region groups up to date, reallocating
	/// on first sight or a grow and re-uploading only when the version has moved.
	private void EnsureMultiMeshSet(MultiMeshRenderData multiMesh)
	{
		MultiMeshSet set;
		if (!mMultiMeshSets.TryGetValue(multiMesh.Key, out set))
		{
			set = new MultiMeshSet();
			mMultiMeshSets[multiMesh.Key] = set;
		}
		set.LastFrame = mMultiMeshFrame;

		let regions = Min(mFramesInFlight, (uint32)MultiMeshSet.cMaxFramesInFlight);
		let region = mFrameIndex % regions;

		if ((set.InstanceBuffer == null) || (multiMesh.InstanceCount > set.Capacity))
		{
			// A frame in flight may still reference the old buffer and groups: retire them
			// when a queue is wired, else drain the device once for the whole replacement.
			if ((mRetire == null)
				&& ((set.InstanceBuffer != null) || (set.InstanceBindGroups[0] != null)))
				mDevice.WaitIdle();

			for (int r < MultiMeshSet.cMaxFramesInFlight)
			{
				if (set.InstanceBindGroups[r] == null)
					continue;

				if (mRetire != null)
					mRetire.Retire(set.InstanceBindGroups[r]);
				else
					mDevice.DestroyBindGroup(ref set.InstanceBindGroups[r]);
				set.InstanceBindGroups[r] = null;
			}

			if (set.InstanceBuffer != null)
			{
				if (mRetire != null)
					mRetire.Retire(set.InstanceBuffer);
				else
					mDevice.DestroyBuffer(ref set.InstanceBuffer);
				set.InstanceBuffer = null;
			}

			let regionBytes = (uint64)multiMesh.InstanceCount * sizeof(MeshInstanceData);
			var desc = BufferDesc();
			desc.Size = (uint64)regions * regionBytes;
			desc.Usage = .StorageRead | .CopyDst;
			desc.Memory = .CpuToGpu;
			desc.Label = "mesh.multimesh.instances";

			if (!(mDevice.CreateBuffer(desc) case .Ok(let buffer)))
			{
				set.Capacity = 0;
				return;
			}
			set.InstanceBuffer = buffer;

			// A group per region, each over its own slice, so the shader's index stays within
			// the bound region and the shared ramp remains zero based.
			var ok = true;
			for (uint32 r = 0; r < regions; r++)
			{
				var entry = BindGroupEntry.BufferEntry(buffer, (uint64)r * regionBytes,
					regionBytes);
				var bindGroupDesc = BindGroupDesc();
				bindGroupDesc.Layout = mInstanceLayout;
				bindGroupDesc.Entries = .(&entry, 1);

				if (!(mDevice.CreateBindGroup(bindGroupDesc) case .Ok(let group)))
				{
					ok = false;
					break;
				}
				set.InstanceBindGroups[r] = group;
			}

			if (!ok)
			{
				for (int r < MultiMeshSet.cMaxFramesInFlight)
				{
					if (set.InstanceBindGroups[r] != null)
						mDevice.DestroyBindGroup(ref set.InstanceBindGroups[r]);
				}
				mDevice.DestroyBuffer(ref set.InstanceBuffer);
				set.Capacity = 0;
				return;
			}

			set.Capacity = multiMesh.InstanceCount;
			// Force a re-upload of every region after a reallocation.
			set.UploadedVersion = 0;
			set.DirtyFrames = regions;
		}

		set.Count = multiMesh.InstanceCount;
		set.ActiveInstanceBindGroup = set.InstanceBindGroups[region];

		// A version change re-uploads for as many frames as there are regions, so every one
		// ends up current, and then stops. A static set therefore writes only that many times
		// and a per frame dynamic one writes every frame, both without a hazard: a frame only
		// ever writes ITS OWN region while the GPU reads the previous one.
		if (set.UploadedVersion != multiMesh.Version)
		{
			set.UploadedVersion = multiMesh.Version;
			set.DirtyFrames = regions;
		}

		if ((set.DirtyFrames > 0) && (set.InstanceBuffer != null)
			&& (multiMesh.Transforms != null))
		{
			let mapped = (MeshInstanceData*)set.InstanceBuffer.Map();
			if (mapped != null)
			{
				let destination = mapped + (int)region * set.Capacity;
				for (uint32 i = 0; i < multiMesh.InstanceCount; i++)
				{
					let tint = (multiMesh.Tints != null) ? multiMesh.Tints[i] : multiMesh.Color;
					// Static content has no motion, so the previous world is the current one.
					destination[i] = .(multiMesh.Transforms[i], multiMesh.Transforms[i], tint);
				}
				set.InstanceBuffer.Unmap();
			}
			set.DirtyFrames--;
		}

		// A skinned crowd needs its own offsets buffer, whose bone bases change every frame.
		// It is allocated here and FILLED once the pool's base is known.
		set.Skinned = (multiMesh.PosePool != null) && (multiMesh.PoseCount > 0)
			&& (multiMesh.BoneCount > 0);

		if (set.Skinned
			&& ((set.OffsetsBuffer == null) || (multiMesh.InstanceCount > set.OffsetsCapacity)))
		{
			if (set.OffsetsBuffer != null)
				RetireOrDrainBuffer(ref set.OffsetsBuffer);

			var desc = BufferDesc();
			// One region per frame in flight: these are rewritten EVERY frame, so each writes
			// its own while the GPU reads the previous, never the same bytes.
			desc.Size = (uint64)mFramesInFlight * (uint64)multiMesh.InstanceCount
				* sizeof(MeshDataOffsets);
			desc.Usage = .Vertex | .CopyDst;
			desc.Memory = .CpuToGpu;
			desc.Label = "mesh.multimesh.offsets";

			if (!(mDevice.CreateBuffer(desc) case .Ok(let buffer)))
			{
				set.OffsetsCapacity = 0;
				return;
			}
			set.OffsetsBuffer = buffer;
			set.OffsetsCapacity = multiMesh.InstanceCount;
		}
	}

	/// Fills each skinned set's per instance offsets: the instance's index into its own buffer,
	/// and its pose's base in the shared pool. Once per frame, shared by every pass.
	private void FillSkinnedMultiMeshOffsets(ExtractedScene scene)
	{
		let region = mFrameIndex % mFramesInFlight;

		for (let data in scene.Items)
		{
			if ((data == null) || (data.RendererId != RendererId))
				continue;

			let mesh = (MeshRenderData)data;
			if (!mesh.MultiMesh)
				continue;

			let multiMesh = (MultiMeshRenderData)mesh;
			if ((multiMesh.PosePool == null) || (multiMesh.PoseCount == 0)
				|| (multiMesh.BoneCount == 0))
				continue;

			if (!mMultiMeshSets.TryGetValue(multiMesh.Key, let set))
				continue;
			if ((set.OffsetsBuffer == null) || (set.OffsetsCapacity == 0))
				continue;

			if (!mBoneStart.TryGetValue((int)(void*)multiMesh.PosePool, let pool))
				continue;

			// Write ONLY this frame's region; the GPU is reading the previous one.
			let regionBase = region * set.OffsetsCapacity;
			let mapped = (MeshDataOffsets*)set.OffsetsBuffer.Map();
			if (mapped == null)
				continue;

			for (uint32 i = 0; i < multiMesh.InstanceCount; i++)
			{
				// This instance's pose out of the shared palettes, by the caller's policy. The
				// slot is stable per instance across frames, so the previous pose lines up and
				// the motion vectors stay right.
				let pose = PoseSelection.SelectPose(multiMesh.PoseAssignment, i, multiMesh.PoseCount,
					multiMesh.PoseIndices);
				let bucket = pose * multiMesh.BoneCount;
				mapped[regionBase + i] = MeshDataOffsets(i, pool.Base + bucket, pool.PrevBase + bucket, 0);
			}

			set.OffsetsBuffer.Unmap();
			set.OffsetsByteOffset = regionBase * (uint32)sizeof(MeshDataOffsets);
		}
	}

	// ==================== Resolving ====================

	public override void Resolve(RenderRecordContext context, Span<DrawItem> items,
		List<ResolvedDraw> outDraws)
	{
		if (!mReady || items.IsEmpty)
			return;

		// This VIEW's set nought group, carrying its own scene's environment.
		if (!EnsureViewBindGroup(context))
			return;

		// This view's lights into the ring, bound whole: the shader reads them from the
		// offset stamped into the view block.
		var lightCount = (uint32)context.Lights.Length;
		if (lightCount > cMaxLights)
			lightCount = cMaxLights;

		uint32 lightOffset = 0;
		if (lightCount > 0)
		{
			let range = mLightRing.AllocateRange(lightCount);
			if (range.Ok)
			{
				Internal.MemCpy(range.Ptr, context.Lights.Ptr, (int)lightCount * sizeof(GpuLight));
				lightOffset = range.SlotIndex;
			}
			else
			{
				lightCount = 0;
			}
		}

		// This view's clustered light lists. Without them the grid width stays nought, which
		// is what makes the shader fall back to looping every light.
		var clusterBindGroup = mDummyClusterBindGroup;
		if (context.Cluster.Valid)
		{
			// A slot per view AND frame: two views in one frame have different buffers and must
			// not share a group, or it thrashes and frees a set still in flight.
			let slot = (int)(context.ViewIndex * mFramesInFlight
				+ (context.FrameIndex % mFramesInFlight));
			clusterBindGroup = EnsureClusterBindGroup(slot, context.Cluster.Offsets,
				context.Cluster.LightIndices, context.Cluster.Version);
		}

		let view = mViewRing.Allocate();
		if (!view.Ok)
			return;

		var viewData = MeshViewData();
		viewData.ViewProj = context.ViewProj;
		viewData.PrevViewProj = context.PrevViewProj;
		viewData.Jitter = .(context.Jitter.X, context.Jitter.Y, context.PrevJitter.X,
			context.PrevJitter.Y);
		viewData.View = context.ViewMatrix;
		viewData.CameraPos = context.CameraPos;
		viewData.Ambient = context.Ambient;

		let iblActive = context.Ibl.Valid && (context.Ibl.ShBuffer != null)
			&& (context.Ibl.PrefilterView != null) && (context.Ibl.BrdfView != null);
		// Below nought means the shading falls back to flat ambient.
		viewData.IblMaxLod = iblActive ? context.Ibl.MaxLod : -1.0f;

		// The probes are off DURING a probe capture, so a metallic surface reflects the sky
		// rather than the probe that is not built yet, which would bake it black.
		viewData.ProbeCenter = .((float)context.ProbeBase, 0, 0,
			context.ProbesEnabled ? (float)context.ProbeCount : 0.0f);

		viewData.LightCount = (float)lightCount;
		viewData.LightOffset = lightOffset;

		if (context.Cascades.Valid)
		{
			for (int c < ShadowCascades.Count)
				viewData.CascadeViewProj[c] = context.Cascades.ViewProjection[c];

			viewData.CascadeSplitFar = .(context.Cascades.SplitFar[0],
				context.Cascades.SplitFar[1], context.Cascades.SplitFar[2],
				context.Cascades.SplitFar[3]);
			viewData.CascadeTexelSize = .(context.Cascades.TexelWorldSize[0],
				context.Cascades.TexelWorldSize[1], context.Cascades.TexelWorldSize[2],
				context.Cascades.TexelWorldSize[3]);
			viewData.ShadowCascadeCount = (float)ShadowCascades.Count;
			viewData.CascadeLayerBase = (float)context.CascadeLayerBase;

			// The normal offset is in TEXELS, scaled by the cascade's world texel size in the
			// shader. It stays TINY: at larger values it shifts the receiver enough to eat the
			// light facing side of a contact shadow, and worse the coarser the cascade. The
			// acne is carried by the hardware depth bias, not by this.
			viewData.ShadowNormalBias = 0.02f;
			viewData.ShadowDepthBias = 0.0009f;
			viewData.ShadowParams.X = context.ShadowFarFade;
		}

		// The vertical sign for a shadow lookup. The shadow map rasterises the same way the
		// colour target does, so a flipped target reads it one way and a negative viewport the
		// other. OUTSIDE the cascade block: a local shadow lookup uses this sign too, and local
		// shadows exist without any directional cascade, where the default would collapse every
		// lookup onto one row of the atlas.
		viewData.ShadowParams.Y = mDevice.NeedsClipSpaceYFlip ? 1.0f : -1.0f;
		viewData.DebugParams.X = (float)context.DebugSemantic;
		viewData.IblParams = .(context.IblDiffuseIntensity, context.IblSpecularIntensity, 0, 0);

		// The ring's base plus THIS view's scene's, the scenes' entries being concatenated and
		// each light's index being relative to its own scene.
		viewData.LocalShadowBase = mLocalShadowBase + context.LocalShadowEntryBase;

		if (context.Cluster.Valid)
		{
			viewData.ClusterGridX = context.Cluster.GridX;
			viewData.ClusterGridY = context.Cluster.GridY;
			viewData.ClusterSliceCount = context.Cluster.SliceCount;
			viewData.ClusterTileSize = context.Cluster.TileSize;
			viewData.ClusterViewportX = context.Cluster.ViewportX;
			viewData.ClusterViewportY = context.Cluster.ViewportY;
			viewData.ClusterNear = context.Cluster.NearZ;
			viewData.ClusterFar = context.Cluster.FarZ;
			viewData.ClusterLogScale = context.Cluster.LogScale;
			viewData.ClusterLogBias = context.Cluster.LogBias;
		}

		*(MeshViewData*)view.Ptr = viewData;
		let viewOffset = view.ByteOffset;

		// A blended run is never instanced: its back to front order has to dominate.
		let allowInstancing = (items[0].Data.Category != RenderCategories.Transparent);

		var i = 0;
		while (i < items.Length)
		{
			let head = (MeshRenderData)items[i].Data;

			// An instanced SET is one item drawn many times from its own persistent buffer,
			// handled on its own and never merged into a neighbouring run.
			if (head.MultiMesh)
			{
				if (mMeshes.GetOrUpload(head.Mesh) case .Ok(let gpuMesh))
					ResolveMultiMesh(context, viewOffset, clusterBindGroup,
						(MultiMeshRenderData)head, gpuMesh, outDraws);
				i++;
				continue;
			}

			// A skinned mesh carries its bone base per instance now, so it batches like a
			// static one: identical skinned instances collapse into a single draw.
			let headSkinned = (head.Mesh != null) && head.Mesh.IsSkinned
				&& (head.BoneMatrices != null);

			var j = i + 1;
			if (allowInstancing)
			{
				while (j < items.Length)
				{
					let next = (MeshRenderData)items[j].Data;
					if (next.MultiMesh || (next.Mesh != head.Mesh)
						|| (next.Material != head.Material))
						break;
					j++;
				}
			}
			let runLength = (uint32)(j - i);

			if (mMeshes.GetOrUpload(head.Mesh) case .Ok(let gpuMesh))
			{
				// A skinned draw always takes the instanced path, even alone: the single path
				// has nowhere to carry a bone base.
				if ((runLength >= 2) || headSkinned)
					ResolveInstanced(context, viewOffset, clusterBindGroup, items, i, runLength,
						head, gpuMesh, outDraws);
				else
					ResolveSingle(context, viewOffset, clusterBindGroup, head, gpuMesh, outDraws);
			}

			i = j;
		}
	}

	/// Re-emits this view's draws as DEPTH ONLY casters, the context's matrix being the
	/// light's. It mirrors the batching above but produces depth only draws, reusing the object
	/// and instance rings, which is what they were sized for.
	public override void ResolveDepthOnly(RenderRecordContext context, Span<DrawItem> items,
		List<ResolvedDraw> outDraws)
	{
		if (!mReady || items.IsEmpty)
			return;

		let shadowView = mShadowViewRing.Allocate();
		if (!shadowView.Ok)
			return;

		*(MeshShadowViewData*)shadowView.Ptr = .(context.ViewProj);
		let shadowViewOffset = shadowView.ByteOffset;

		var i = 0;
		while (i < items.Length)
		{
			// OURS ONLY. The dispatcher groups runs by renderer, but a foreign item sharing a
			// category and cast to mesh data is silent nonsense, so the gate is hard.
			if (items[i].Data.RendererId != RendererId)
			{
				i++;
				continue;
			}

			let head = (MeshRenderData)items[i].Data;
			if (head.MultiMesh)
			{
				if (mMeshes.GetOrUpload(head.Mesh) case .Ok(let gpuMesh))
					ResolveMultiMeshDepth(context, shadowViewOffset, (MultiMeshRenderData)head,
						gpuMesh, outDraws);
				i++;
				continue;
			}

			let headSkinned = (head.Mesh != null) && head.Mesh.IsSkinned
				&& (head.BoneMatrices != null);

			var j = i + 1;
			while (j < items.Length)
			{
				let next = (MeshRenderData)items[j].Data;
				if (next.MultiMesh || (next.Mesh != head.Mesh) || (next.Material != head.Material))
					break;
				j++;
			}
			let runLength = (uint32)(j - i);

			if (mMeshes.GetOrUpload(head.Mesh) case .Ok(let gpuMesh))
			{
				if ((runLength >= 2) || headSkinned)
					ResolveDepthInstanced(context, shadowViewOffset, items, i, runLength, gpuMesh,
						outDraws);
				else
					ResolveDepthSingle(context, shadowViewOffset, head, gpuMesh, outDraws);
			}

			i = j;
		}
	}

	/// The per object path: one draw, its transform in a block at a dynamic offset.
	private void ResolveSingle(RenderRecordContext context, uint32 viewOffset,
		IBindGroup clusterBindGroup, MeshRenderData md, GpuMesh mesh, List<ResolvedDraw> outDraws)
	{
		let material = (md.Material != null) ? md.Material : mDefaultMaterial;
		var config = ConfigFor(md, context, false);

		// A skinned mesh draws the skinned permutation, binds the skin stream, and reads its
		// bones from the shared device pool at the base worked out once this frame. Nothing is
		// uploaded here.
		uint32 boneBase = 0;
		var skinned = (md.BoneMatrices != null) && (md.BoneCount > 0) && (md.Mesh != null)
			&& md.Mesh.IsSkinned && (mesh.SkinBuffer != null);

		if (skinned)
		{
			if (mBoneStart.TryGetValue((int)(void*)md.BoneMatrices, let slot))
			{
				boneBase = slot.Base;
				config.VertexLayout = .SkinnedMesh;
				config.ShaderFlags |= .Skinned;
			}
			else
			{
				// Not uploaded, the pool having overflowed: draw the bind pose rather than
				// whatever happens to be at index nought.
				skinned = false;
			}
		}

		let object = mObjectRing.Allocate();
		if (!object.Ok)
			return;

		var objectData = MeshObjectData();
		objectData.World = md.World;
		objectData.PrevWorld = context.NeedsMotion ? PrevWorldFor(md.EntityId, md.World) : md.World;
		objectData.Tint = md.Color;
		objectData.BoneBase = boneBase;
		objectData.PrevBoneBase = boneBase;
		*(MeshObjectData*)object.Ptr = objectData;

		var template = ResolvedDraw();
		template.ViewSet = mViewBindGroup;
		template.ViewOffset = viewOffset;
		template.ViewDynamic = true;
		template.DrawSet = mObjectBindGroup;
		template.DrawOffset = object.ByteOffset;
		template.DrawDynamic = true;
		template.ClusterSet = clusterBindGroup;
		template.VertexBuffer0 = mesh.VertexBuffer;
		template.VertexOffset0 = mesh.VertexOffset;
		if (skinned)
		{
			template.VertexBuffer1 = mesh.SkinBuffer;
			template.VertexOffset1 = mesh.SkinOffset;
		}
		template.IndexBuffer = mesh.IndexBuffer;
		template.IndexFormat = mesh.IndexFormat;
		template.InstanceCount = 1;

		EmitForward(context, config, template, material, md, mesh, false, outDraws);
	}

	/// The instanced path: one draw for a run sharing a mesh and material.
	private void ResolveInstanced(RenderRecordContext context, uint32 viewOffset,
		IBindGroup clusterBindGroup, Span<DrawItem> items, int first, uint32 count,
		MeshRenderData head, GpuMesh mesh, List<ResolvedDraw> outDraws)
	{
		let material = (head.Material != null) ? head.Material : mDefaultMaterial;
		var config = ConfigFor(head, context, true);

		// The skin stream is per MESH; each instance's bone base rides in its offsets, which is
		// what lets one draw skin many characters.
		let skinned = (head.BoneMatrices != null) && (head.Mesh != null) && head.Mesh.IsSkinned
			&& (mesh.SkinBuffer != null);
		if (skinned)
		{
			config.VertexLayout = .SkinnedMesh;
			config.ShaderFlags |= .Skinned;
		}

		// The camera prepass already filled this group's instances and offsets, the same
		// objects in the same order, and recorded the range: REUSE it rather than filling it
		// again. A miss, from no prepass or a changed count, falls back to a fresh fill.
		uint64 offsetsByteOffset;
		let shareKey = InstShareKey(head.Mesh, head.Material, context.View);

		if (mInstShareCache.TryGetValue(shareKey, let shared) && (shared.Count == count))
		{
			offsetsByteOffset = shared.OffsetsByteOffset;
		}
		else
		{
			let instances = mInstanceRing.AllocateRange(count);
			let offsets = mOffsetsRing.AllocateRange(count);
			if (!instances.Ok || !offsets.Ok)
				return;

			let instanceData = (MeshInstanceData*)instances.Ptr;
			let offsetData = (MeshDataOffsets*)offsets.Ptr;

			for (uint32 k = 0; k < count; k++)
			{
				let md = (MeshRenderData)items[first + (int)k].Data;
				instanceData[k] = .(md.World,
					context.NeedsMotion ? PrevWorldFor(md.EntityId, md.World) : md.World,
					md.Color);

				uint32 boneBase = 0;
				uint32 prevBase = 0;
				if (skinned && mBoneStart.TryGetValue((int)(void*)md.BoneMatrices, let slot))
				{
					boneBase = slot.Base;
					prevBase = slot.PrevBase;
				}
				offsetData[k] = .(instances.SlotIndex + k, boneBase, prevBase, 0);
			}

			offsetsByteOffset = offsets.ByteOffset;
		}

		var template = ResolvedDraw();
		template.ViewSet = mViewBindGroup;
		template.ViewOffset = viewOffset;
		template.ViewDynamic = true;
		template.DrawSet = mInstanceBindGroup;
		template.DrawDynamic = false;
		template.ClusterSet = clusterBindGroup;
		template.VertexBuffer0 = mesh.VertexBuffer;
		template.VertexOffset0 = mesh.VertexOffset;
		if (skinned)
		{
			template.VertexBuffer1 = mesh.SkinBuffer;
			template.VertexOffset1 = mesh.SkinOffset;
			template.VertexBuffer2 = mOffsetsRing.Buffer;
			template.VertexOffset2 = offsetsByteOffset;
		}
		else
		{
			template.VertexBuffer1 = mOffsetsRing.Buffer;
			template.VertexOffset1 = offsetsByteOffset;
		}
		template.IndexBuffer = mesh.IndexBuffer;
		template.IndexFormat = mesh.IndexFormat;
		template.InstanceCount = count;

		EmitForward(context, config, template, material, head, mesh, true, outDraws);
	}

	/// Emits the forward draws for one item: one per submesh where the mesh has its own
	/// materials or a detail chain, otherwise a single draw for the whole index range.
	///
	/// A CHAIN ROUTES BOTH BRANCHES through the selected level's submesh table: the whole
	/// buffer path would draw every level's concatenated indices at once.
	private void EmitForward(RenderRecordContext context, PipelineConfig config,
		ResolvedDraw template, Material fallback, MeshRenderData md, GpuMesh mesh, bool instanced,
		List<ResolvedDraw> outDraws)
	{
		void Emit(Material candidate, uint64 indexOffset, uint32 indexCount)
		{
			let use = (candidate != null) ? candidate : fallback;
			let set2 = mMaterials.GetOrCreateLayout(use);
			let layout = GetOrCreatePipelineLayout(set2, instanced);
			if (layout == null)
				return;

			let pipeline = mPsoCache.GetPipeline(config, layout, context.ColorFormat);
			if (pipeline == null)
				return;

			var draw = template;
			draw.Pso = pipeline;
			draw.MaterialSet = mMaterials.PrepareInstance(InstanceFor(use), set2);
			draw.IndexOffset = indexOffset;
			draw.IndexCount = indexCount;
			outDraws.Add(draw);
		}

		let hasChain = (md.Mesh != null) && (md.Mesh.LodCount > 1);
		if ((md.Mesh != null) && !md.Mesh.SubMeshes.IsEmpty
			&& ((md.SubmeshMaterialCount > 0) || hasChain))
		{
			let subMeshes = hasChain
				? md.Mesh.SubMeshesForLod(SelectLod(context, md))
				: Span<SubMesh>(md.Mesh.SubMeshes.Ptr, md.Mesh.SubMeshes.Count);
			let stride = (mesh.IndexFormat == .UInt16) ? 2UL : 4UL;

			for (let sub in subMeshes)
			{
				var candidate = ((sub.MaterialIndex >= 0)
					&& ((uint32)sub.MaterialIndex < md.SubmeshMaterialCount))
					? md.SubmeshMaterials[sub.MaterialIndex]
					: null;
				// An unresolved or out of range slot falls back to the item's own material.
				if (candidate == null)
					candidate = md.Material;

				Emit(candidate, mesh.IndexOffset + (uint64)sub.StartIndex * stride,
					(uint32)sub.IndexCount);
			}
			return;
		}

		Emit(fallback, mesh.IndexOffset, mesh.IndexCount);
	}

	private void ResolveDepthSingle(RenderRecordContext context, uint32 shadowViewOffset,
		MeshRenderData md, GpuMesh mesh, List<ResolvedDraw> outDraws)
	{
		uint32 boneBase = 0;
		var skinned = (md.BoneMatrices != null) && (md.BoneCount > 0) && (md.Mesh != null)
			&& md.Mesh.IsSkinned && (mesh.SkinBuffer != null);

		// A masked caster casts a HOLEY shadow through the alpha test, which needs its material.
		let masked = (md.Material != null) && (md.Material.Pipeline.BlendMode == .Masked);
		var config = ShadowConfigFor(context, false, masked);

		if (skinned)
		{
			if (mBoneStart.TryGetValue((int)(void*)md.BoneMatrices, let slot))
			{
				boneBase = slot.Base;
				config.VertexLayout = .SkinnedMesh;
				config.ShaderFlags |= .Skinned;
			}
			else
			{
				skinned = false;
			}
		}

		IBindGroup materialSet = null;
		var layout = mShadowPipelineLayoutSingle;
		if (masked)
		{
			let set2 = mMaterials.GetOrCreateLayout(md.Material);
			layout = GetOrCreateShadowMaskedLayout(set2, false);
			materialSet = mMaterials.PrepareInstance(InstanceFor(md.Material), set2);
			if (layout == null)
			{
				layout = mShadowPipelineLayoutSingle;
				materialSet = null;
				config = ShadowConfigFor(context, false, false);
			}
		}

		let pipeline = mPsoCache.GetPipeline(config, layout, .Undefined);
		if (pipeline == null)
			return;

		let object = mObjectRing.Allocate();
		if (!object.Ok)
			return;

		var objectData = MeshObjectData();
		objectData.World = md.World;
		// A depth pass ignores the previous world.
		objectData.PrevWorld = md.World;
		objectData.Tint = md.Color;
		objectData.BoneBase = boneBase;
		*(MeshObjectData*)object.Ptr = objectData;

		var draw = ResolvedDraw();
		draw.Pso = pipeline;
		draw.ViewSet = mShadowViewBindGroup;
		draw.ViewOffset = shadowViewOffset;
		draw.ViewDynamic = true;
		draw.DrawSet = mObjectBindGroup;
		draw.DrawOffset = object.ByteOffset;
		draw.DrawDynamic = true;
		draw.MaterialSet = materialSet;
		draw.VertexBuffer0 = mesh.VertexBuffer;
		draw.VertexOffset0 = mesh.VertexOffset;
		if (skinned)
		{
			draw.VertexBuffer1 = mesh.SkinBuffer;
			draw.VertexOffset1 = mesh.SkinOffset;
		}
		draw.IndexBuffer = mesh.IndexBuffer;
		draw.IndexOffset = mesh.IndexOffset;
		draw.IndexFormat = mesh.IndexFormat;
		draw.IndexCount = mesh.IndexCount;
		draw.InstanceCount = 1;

		EmitDepth(context, draw, md, mesh, outDraws);
	}

	private void ResolveDepthInstanced(RenderRecordContext context, uint32 shadowViewOffset,
		Span<DrawItem> items, int first, uint32 count, GpuMesh mesh, List<ResolvedDraw> outDraws)
	{
		let head = (MeshRenderData)items[first].Data;
		let skinned = (head.BoneMatrices != null) && (head.Mesh != null) && head.Mesh.IsSkinned
			&& (mesh.SkinBuffer != null);
		let masked = (head.Material != null) && (head.Material.Pipeline.BlendMode == .Masked);

		var config = ShadowConfigFor(context, true, masked);
		if (skinned)
		{
			config.VertexLayout = .SkinnedMesh;
			config.ShaderFlags |= .Skinned;
		}

		IBindGroup materialSet = null;
		var layout = mShadowPipelineLayoutInstanced;
		if (masked)
		{
			let set2 = mMaterials.GetOrCreateLayout(head.Material);
			layout = GetOrCreateShadowMaskedLayout(set2, true);
			materialSet = mMaterials.PrepareInstance(InstanceFor(head.Material), set2);
			if (layout == null)
			{
				layout = mShadowPipelineLayoutInstanced;
				materialSet = null;
				config = ShadowConfigFor(context, true, false);
				if (skinned)
				{
					config.VertexLayout = .SkinnedMesh;
					config.ShaderFlags |= .Skinned;
				}
			}
		}

		let pipeline = mPsoCache.GetPipeline(config, layout, .Undefined);
		if (pipeline == null)
			return;

		let instances = mInstanceRing.AllocateRange(count);
		let offsets = mOffsetsRing.AllocateRange(count);
		if (!instances.Ok || !offsets.Ok)
			return;

		let instanceData = (MeshInstanceData*)instances.Ptr;
		let offsetData = (MeshDataOffsets*)offsets.Ptr;

		// When this prepass FEEDS the forward, build the full instance data including the real
		// previous world, so the forward can reuse it for the motion vectors. A shadow caster
		// leaves the previous world as the current one, the depth shaders ignoring it.
		let feedsForward = context.FillInstanceCache;

		for (uint32 k = 0; k < count; k++)
		{
			let md = (MeshRenderData)items[first + (int)k].Data;
			let previous = (feedsForward && context.NeedsMotion)
				? PrevWorldFor(md.EntityId, md.World)
				: md.World;
			instanceData[k] = .(md.World, previous, md.Color);

			uint32 boneBase = 0;
			uint32 prevBase = 0;
			if (skinned && mBoneStart.TryGetValue((int)(void*)md.BoneMatrices, let slot))
			{
				boneBase = slot.Base;
				prevBase = slot.PrevBase;
			}
			offsetData[k] = .(instances.SlotIndex + k, boneBase, prevBase, 0);
		}

		if (feedsForward)
		{
			mInstShareCache[InstShareKey(head.Mesh, head.Material, context.View)] =
				.() { OffsetsByteOffset = offsets.ByteOffset, Count = count };
		}

		var draw = ResolvedDraw();
		draw.Pso = pipeline;
		draw.ViewSet = mShadowViewBindGroup;
		draw.ViewOffset = shadowViewOffset;
		draw.ViewDynamic = true;
		draw.DrawSet = mInstanceBindGroup;
		draw.DrawDynamic = false;
		draw.MaterialSet = materialSet;
		draw.VertexBuffer0 = mesh.VertexBuffer;
		draw.VertexOffset0 = mesh.VertexOffset;
		if (skinned)
		{
			draw.VertexBuffer1 = mesh.SkinBuffer;
			draw.VertexOffset1 = mesh.SkinOffset;
			draw.VertexBuffer2 = mOffsetsRing.Buffer;
			draw.VertexOffset2 = offsets.ByteOffset;
		}
		else
		{
			draw.VertexBuffer1 = mOffsetsRing.Buffer;
			draw.VertexOffset1 = offsets.ByteOffset;
		}
		draw.IndexBuffer = mesh.IndexBuffer;
		draw.IndexOffset = mesh.IndexOffset;
		draw.IndexFormat = mesh.IndexFormat;
		draw.IndexCount = mesh.IndexCount;
		draw.InstanceCount = count;

		EmitDepth(context, draw, head, mesh, outDraws);
	}

	/// Appends a depth draw, split per submesh when the mesh has a detail chain: the whole
	/// buffer path would cast every concatenated level's shadow at once.
	private void EmitDepth(RenderRecordContext context, ResolvedDraw draw, MeshRenderData md,
		GpuMesh mesh, List<ResolvedDraw> outDraws)
	{
		if ((md.Mesh != null) && (md.Mesh.LodCount > 1))
		{
			let subMeshes = md.Mesh.SubMeshesForLod(SelectLod(context, md));
			let stride = (mesh.IndexFormat == .UInt16) ? 2UL : 4UL;

			for (let sub in subMeshes)
			{
				var copy = draw;
				copy.IndexOffset = mesh.IndexOffset + (uint64)sub.StartIndex * stride;
				copy.IndexCount = (uint32)sub.IndexCount;
				outDraws.Add(copy);
			}
			return;
		}

		outDraws.Add(draw);
	}

	/// The forward draw for an instanced set: this set's own persistent instances and the
	/// shared ramp, one instanced draw per submesh material. NO fill loop, the buffer already
	/// holding what it needs, and the shader path identical to the ordinary instanced one.
	private void ResolveMultiMesh(RenderRecordContext context, uint32 viewOffset,
		IBindGroup clusterBindGroup, MultiMeshRenderData multiMesh, GpuMesh mesh,
		List<ResolvedDraw> outDraws)
	{
		if (!mMultiMeshSets.TryGetValue(multiMesh.Key, let set))
			return;
		if ((set.ActiveInstanceBindGroup == null) || (set.Count == 0))
			return;

		// A skinned crowd takes its per instance bone bases from the set's own offsets buffer;
		// a static one takes the shared ramp. A skinned set whose skin data is missing falls
		// back to the static form rather than drawing nothing.
		let skinned = set.Skinned && (set.OffsetsBuffer != null) && (mesh.SkinBuffer != null);
		if (!skinned && (mRampBuffer == null))
			return;

		let material = (multiMesh.Material != null) ? multiMesh.Material : mDefaultMaterial;
		var config = ConfigFor(multiMesh, context, true);
		if (skinned)
		{
			config.VertexLayout = .SkinnedMesh;
			config.ShaderFlags |= .Skinned;
		}

		var template = ResolvedDraw();
		template.ViewSet = mViewBindGroup;
		template.ViewOffset = viewOffset;
		template.ViewDynamic = true;
		template.DrawSet = set.ActiveInstanceBindGroup;
		template.DrawDynamic = false;
		template.ClusterSet = clusterBindGroup;
		template.VertexBuffer0 = mesh.VertexBuffer;
		template.VertexOffset0 = mesh.VertexOffset;
		if (skinned)
		{
			template.VertexBuffer1 = mesh.SkinBuffer;
			template.VertexOffset1 = mesh.SkinOffset;
			template.VertexBuffer2 = set.OffsetsBuffer;
			template.VertexOffset2 = set.OffsetsByteOffset;
		}
		else
		{
			template.VertexBuffer1 = mRampBuffer;
			template.VertexOffset1 = 0;
		}
		template.IndexBuffer = mesh.IndexBuffer;
		template.IndexFormat = mesh.IndexFormat;
		template.InstanceCount = set.Count;

		EmitForward(context, config, template, material, multiMesh, mesh, true, outDraws);
	}

	/// The depth only draw for an instanced caster, in the camera prepass and in every cascade:
	/// the same persistent buffer and ramp, under the shadow layout.
	private void ResolveMultiMeshDepth(RenderRecordContext context, uint32 shadowViewOffset,
		MultiMeshRenderData multiMesh, GpuMesh mesh, List<ResolvedDraw> outDraws)
	{
		if (!mMultiMeshSets.TryGetValue(multiMesh.Key, let set))
			return;
		if ((set.ActiveInstanceBindGroup == null) || (set.Count == 0))
			return;

		let skinned = set.Skinned && (set.OffsetsBuffer != null) && (mesh.SkinBuffer != null);
		if (!skinned && (mRampBuffer == null))
			return;

		let masked = (multiMesh.Material != null)
			&& (multiMesh.Material.Pipeline.BlendMode == .Masked);
		var config = ShadowConfigFor(context, true, masked);
		if (skinned)
		{
			config.VertexLayout = .SkinnedMesh;
			config.ShaderFlags |= .Skinned;
		}

		IBindGroup materialSet = null;
		var layout = mShadowPipelineLayoutInstanced;
		if (masked)
		{
			let set2 = mMaterials.GetOrCreateLayout(multiMesh.Material);
			layout = GetOrCreateShadowMaskedLayout(set2, true);
			materialSet = mMaterials.PrepareInstance(InstanceFor(multiMesh.Material), set2);
			if (layout == null)
			{
				layout = mShadowPipelineLayoutInstanced;
				materialSet = null;
				config = ShadowConfigFor(context, true, false);
				if (skinned)
				{
					config.VertexLayout = .SkinnedMesh;
					config.ShaderFlags |= .Skinned;
				}
			}
		}

		let pipeline = mPsoCache.GetPipeline(config, layout, .Undefined);
		if (pipeline == null)
			return;

		var draw = ResolvedDraw();
		draw.Pso = pipeline;
		draw.ViewSet = mShadowViewBindGroup;
		draw.ViewOffset = shadowViewOffset;
		draw.ViewDynamic = true;
		draw.DrawSet = set.ActiveInstanceBindGroup;
		draw.DrawDynamic = false;
		draw.MaterialSet = materialSet;
		draw.VertexBuffer0 = mesh.VertexBuffer;
		draw.VertexOffset0 = mesh.VertexOffset;
		if (skinned)
		{
			draw.VertexBuffer1 = mesh.SkinBuffer;
			draw.VertexOffset1 = mesh.SkinOffset;
			draw.VertexBuffer2 = set.OffsetsBuffer;
			draw.VertexOffset2 = set.OffsetsByteOffset;
		}
		else
		{
			draw.VertexBuffer1 = mRampBuffer;
			draw.VertexOffset1 = 0;
		}
		draw.IndexBuffer = mesh.IndexBuffer;
		draw.IndexOffset = mesh.IndexOffset;
		draw.IndexFormat = mesh.IndexFormat;
		draw.IndexCount = mesh.IndexCount;
		draw.InstanceCount = set.Count;

		EmitDepth(context, draw, multiMesh, mesh, outDraws);
	}

	// ==================== Pipeline configuration ====================

	/// The depth only configuration for a shadow pass.
	private static PipelineConfig ShadowConfigFor(RenderRecordContext context, bool instanced,
		bool masked = false)
	{
		var config = PipelineConfig();
		config.ShaderName = "shadow_depth";
		config.VertexLayout = .Mesh;
		config.Instanced = instanced;
		if (instanced)
			config.ShaderFlags |= .Instanced;

		// A masked caster runs the alpha test fragment so its shadow has holes; an opaque one
		// stays vertex only, with no fragment stage at all.
		config.DepthOnly = !masked;
		config.ColorTargetCount = 0;
		if (masked)
			config.ShaderFlags |= .AlphaTest;

		config.DepthFormat = context.DepthFormat;
		// ONLY the camera depth prepass is multisampled, its depth having to match the forward's
		// for the early rejection to work. A shadow map pass stays single sampled.
		config.SampleCount = context.DepthPrepass ? context.SampleCount : 1;
		config.DepthMode = .ReadWrite;
		config.DepthCompare = .Less;

		// FRONT faces into the shadow map. That is the conventional default and gives flat and
		// architectural casters tight contacts. A curved caster keeps a small grazing gap
		// inherent to shadow maps; the general fix is a contact shadow pass, not a cull mode
		// change, which only moves the gap onto the flat casters that are far more common.
		config.CullMode = .Back;

		// A constant offset and a slope scaled term, applied in the map's own depth space, so
		// it adds little visible gap where a positional offset would. It pairs with the
		// receiver side normal offset in the shading.
		//
		// The camera prepass must NOT bias: its depth has to equal the forward's exactly, or
		// the equal depth test rejects the very fragments it was meant to accept.
		if (!context.DepthPrepass)
		{
			config.DepthBias = 50;
			config.DepthBiasSlopeScale = 1.5f;
		}

		return config;
	}

	/// The forward configuration for one item, taken from its material and specialised for the
	/// pass it is drawing into.
	private static PipelineConfig ConfigFor(MeshRenderData md, RenderRecordContext context,
		bool instanced)
	{
		var config = (md.Material != null)
			? md.Material.Pipeline
			: PipelineConfig.ForOpaqueMesh("forward");

		config.DepthFormat = context.DepthFormat;
		// The opaque pass records at the view's sample count and the blended one at a single
		// sample, so the pipeline matches the attachments of the pass it is recorded into.
		config.SampleCount = context.SampleCount;
		config.Instanced = instanced;
		if (instanced)
			config.ShaderFlags |= .Instanced;

		// Opaque and masked draws write the whole set of targets: the shaded colour, then the
		// view space normal, the motion vector, and the roughness and metallic the reflections
		// read. A blended draw writes colour alone, its pass having only that.
		let gbuffer = (config.BlendMode == .Opaque) || (config.BlendMode == .Masked);
		if (gbuffer)
		{
			config.ColorTargetCount = 4;
			config.ColorFormats[1] = RenderFormats.GNormal;
			config.ColorFormats[2] = RenderFormats.GVelocity;
			config.ColorFormats[3] = RenderFormats.GMaterial;
			config.ShaderFlags |= .GBuffer;
			// An equal depth fragment from the prepass must PASS, so each opaque pixel is
			// shaded exactly once.
			config.DepthCompare = .LessEqual;
			if (config.BlendMode == .Masked)
				config.ShaderFlags |= .AlphaTest;
		}
		else
		{
			config.ColorTargetCount = 1;
		}

		return config;
	}

	// ==================== Layouts, groups and resources ====================

	private IBindGroupLayout MakeLayout(BindGroupLayoutEntry entry)
	{
		var e = entry;
		var desc = BindGroupLayoutDesc();
		desc.Entries = .(&e, 1);

		if (!(mDevice.CreateBindGroupLayout(desc) case .Ok(let layout)))
			return null;
		return layout;
	}

	private IPipelineLayout MakePipelineLayout2(IBindGroupLayout set0, IBindGroupLayout set1)
	{
		var layouts = IBindGroupLayout[2](set0, set1);
		var desc = PipelineLayoutDesc();
		desc.BindGroupLayouts = .(&layouts[0], 2);

		if (!(mDevice.CreatePipelineLayout(desc) case .Ok(let layout)))
			return null;
		return layout;
	}

	private IPipelineLayout MakePipelineLayout3(IBindGroupLayout set0, IBindGroupLayout set1,
		IBindGroupLayout set2)
	{
		var layouts = IBindGroupLayout[3](set0, set1, set2);
		var desc = PipelineLayoutDesc();
		desc.BindGroupLayouts = .(&layouts[0], 3);

		if (!(mDevice.CreatePipelineLayout(desc) case .Ok(let layout)))
			return null;
		return layout;
	}

	private IPipelineLayout MakePipelineLayout4(IBindGroupLayout set0, IBindGroupLayout set1,
		IBindGroupLayout set2, IBindGroupLayout set3)
	{
		var layouts = IBindGroupLayout[4](set0, set1, set2, set3);
		var desc = PipelineLayoutDesc();
		desc.BindGroupLayouts = .(&layouts[0], 4);

		if (!(mDevice.CreatePipelineLayout(desc) case .Ok(let layout)))
			return null;
		return layout;
	}

	/// Keyed by the material's set layout and whether the draw is instanced.
	private static uint64 LayoutKey(IBindGroupLayout set2, bool instanced)
	{
		return ((uint64)(int)(void*)Internal.UnsafeCastToPtr(set2) * 2) + (instanced ? 1 : 0);
	}

	/// The forward layout for a material's set layout: the view, the object or instances, the
	/// material, then the clusters.
	private IPipelineLayout GetOrCreatePipelineLayout(IBindGroupLayout set2, bool instanced)
	{
		let key = LayoutKey(set2, instanced);
		if (mPipelineLayouts.TryGetValue(key, let cached))
			return cached;

		let set1 = instanced ? mInstanceLayout : mObjectLayout;
		let layout = MakePipelineLayout4(mViewLayout, set1, set2, mClusterLayout);
		if (layout == null)
			return null;

		mPipelineLayouts[key] = layout;
		return layout;
	}

	/// The masked caster's layout: the light's view, the object or instances, and the material
	/// the alpha test samples.
	private IPipelineLayout GetOrCreateShadowMaskedLayout(IBindGroupLayout set2, bool instanced)
	{
		let key = LayoutKey(set2, instanced);
		if (mShadowMaskedLayouts.TryGetValue(key, let cached))
			return cached;

		let set1 = instanced ? mInstanceLayout : mObjectLayout;
		let layout = MakePipelineLayout3(mShadowViewLayout, set1, set2);
		if (layout == null)
			return null;

		mShadowMaskedLayouts[key] = layout;
		return layout;
	}

	/// The instance this renderer keeps for a material, created on first sight. It carries the
	/// per use overrides and its group is cached by the material system.
	private MaterialInstance InstanceFor(Material material)
	{
		if (mInstances.TryGetValue(material.Uid, var existing))
		{
			existing.LastFrame = mFrameClock;
			mInstances[material.Uid] = existing;
			return existing.Instance;
		}

		let instance = new MaterialInstance(material);
		mInstances[material.Uid] = .() { Instance = instance, LastFrame = mFrameClock };
		return instance;
	}

	/// Drops the instances of materials nothing has drawn for a long while.
	///
	/// A material here is BORROWED and not reference counted, so there is no moment at which
	/// the renderer is told one has gone. Ageing them out is what keeps a group from holding
	/// destroyed texture views alive forever after a hot reload; the cost of a wrong guess is
	/// rebuilding a group, not a fault.
	private void PruneStaleMaterialInstances()
	{
		if (mInstances.IsEmpty)
			return;

		let stale = scope List<uint64>();
		for (let pair in mInstances)
		{
			if ((mFrameClock - pair.value.LastFrame) > cInstanceEvictFrames)
				stale.Add(pair.key);
		}

		for (let key in stale)
		{
			let entry = mInstances[key];
			// The group may still be bound by a frame in flight, so it is retired rather than
			// destroyed, and the buffer with it.
			RetireBindGroup(mMaterials.DetachBindGroup(entry.Instance));
			RetireBuffer(mMaterials.DetachUniformBuffer(entry.Instance));
			mInstances.Remove(key);
			delete entry.Instance;
		}
	}

	private void RetireBindGroup(IBindGroup group)
	{
		if (group != null)
			mRetiredBindGroups.Add(.() { Group = group, FramesLeft = mFramesInFlight });
	}

	private void RetireBuffer(IBuffer buffer)
	{
		if (buffer != null)
			mRetiredBuffers.Add(.() { Buffer = buffer, FramesLeft = mFramesInFlight });
	}

	private void TickRetired()
	{
		for (int i = mRetiredBindGroups.Count - 1; i >= 0; i--)
		{
			var retired = mRetiredBindGroups[i];
			if (retired.FramesLeft <= 1)
			{
				mDevice.DestroyBindGroup(ref retired.Group);
				mRetiredBindGroups.RemoveAt(i);
				continue;
			}
			retired.FramesLeft--;
			mRetiredBindGroups[i] = retired;
		}

		for (int i = mRetiredBuffers.Count - 1; i >= 0; i--)
		{
			var retired = mRetiredBuffers[i];
			if (retired.FramesLeft <= 1)
			{
				mDevice.DestroyBuffer(ref retired.Buffer);
				mRetiredBuffers.RemoveAt(i);
				continue;
			}
			retired.FramesLeft--;
			mRetiredBuffers[i] = retired;
		}
	}

	/// Rebuilds a group over a ring's buffer when the ring has reallocated. Whole binds the
	/// entire buffer, for an indexed read; otherwise a window of one slot, for a dynamic offset.
	private bool EnsureRingBindGroup(DynamicUniformRing ring, IBindGroupLayout layout,
		uint64 bindSize, ref IBindGroup group, ref uint32 generation, bool whole)
	{
		if ((group != null) && (generation == ring.Generation))
			return true;

		// The old one may still be referenced by a frame in flight.
		RetireBindGroup(group);
		group = null;

		let buffer = ring.Buffer;
		if (buffer == null)
			return false;

		var entry = BindGroupEntry.BufferEntry(buffer, 0, whole ? ring.ByteCapacity : bindSize);
		var desc = BindGroupDesc();
		desc.Layout = layout;
		desc.Entries = .(&entry, 1);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let created)))
			return false;

		group = created;
		generation = ring.Generation;
		return true;
	}

	/// The set nought group for one view.
	///
	/// It spans two rings, the view block at a dynamic offset and the whole light list, plus
	/// the shadow maps, the skinning pool, the environment and the probes. PER VIEW SLOTS,
	/// because views of different scenes bind different environments within one frame, and the
	/// slot is keyed by every generation it was built against rather than by any address.
	private bool EnsureViewBindGroup(RenderRecordContext context)
	{
		if (mActiveShadowView == null)
			mActiveShadowView = mDummyShadowView;
		if (mActiveAtlasView == null)
			mActiveAtlasView = mDummyAtlasView;
		if (mActiveProbeCube == null)
			mActiveProbeCube = mDummyProbeCubeView;
		if (mActiveProbeBuffer == null)
			mActiveProbeBuffer = mDummyProbeBuffer;

		let iblActive = context.Ibl.Valid && (context.Ibl.ShBuffer != null)
			&& (context.Ibl.PrefilterView != null) && (context.Ibl.BrdfView != null);
		let sh = iblActive ? context.Ibl.ShBuffer : mDummyShBuffer;
		let prefilter = iblActive ? context.Ibl.PrefilterView : mDummyCubeView;
		let brdf = iblActive ? context.Ibl.BrdfView : mDummyBrdfView;
		let iblGeneration = iblActive ? context.Ibl.Generation : 0;

		let index = (int)context.ViewIndex;
		while (mViewBindGroups.Count <= index)
			mViewBindGroups.Add(.());

		if ((mViewBindGroups[index].Group != null)
			&& (mViewBindGroups[index].ViewGeneration == mViewRing.Generation)
			&& (mViewBindGroups[index].LightGeneration == mLightRing.Generation)
			&& (mViewBindGroups[index].Shadow == mActiveShadowView)
			&& (mViewBindGroups[index].ShadowGeneration == mActiveShadowGeneration)
			&& (mViewBindGroups[index].Atlas == mActiveAtlasView)
			&& (mViewBindGroups[index].AtlasGeneration == mActiveAtlasGeneration)
			&& (mViewBindGroups[index].LocalGeneration == mLocalShadowRing.Generation)
			&& (mViewBindGroups[index].BoneGeneration == mBoneDeviceGeneration)
			&& (mViewBindGroups[index].IblGeneration == iblGeneration)
			&& (mViewBindGroups[index].Prefilter == prefilter)
			&& (mViewBindGroups[index].ProbeCube == mActiveProbeCube)
			&& (mViewBindGroups[index].ProbeBuffer == mActiveProbeBuffer))
		{
			mViewBindGroup = mViewBindGroups[index].Group;
			return true;
		}

		RetireBindGroup(mViewBindGroups[index].Group);
		mViewBindGroups[index].Group = null;
		mViewBindGroup = null;

		let viewBuffer = mViewRing.Buffer;
		let lightBuffer = mLightRing.Buffer;
		let localBuffer = mLocalShadowRing.Buffer;
		// The shading reads the DEVICE mirror, not the staging ring.
		let boneBuffer = mBoneDevice;

		if ((viewBuffer == null) || (lightBuffer == null) || (localBuffer == null)
			|| (boneBuffer == null) || (mActiveShadowView == null) || (mActiveAtlasView == null)
			|| (mShadowSampler == null) || (sh == null) || (prefilter == null) || (brdf == null)
			|| (mEnvSampler == null))
			return false;

		// The ORDER must match the layout: the view block, the lights, the cascade map, the
		// local atlas, the local entries, the comparison sampler, the skinning pool, the
		// spherical harmonics, the prefiltered cube, the lookup table, the environment sampler,
		// the probe cubes and their records. The buffers bind whole.
		var entries = BindGroupEntry[13](
			BindGroupEntry.BufferEntry(viewBuffer, 0, sizeof(MeshViewData)),
			BindGroupEntry.BufferEntry(lightBuffer, 0, mLightRing.ByteCapacity),
			BindGroupEntry.TextureEntry(mActiveShadowView),
			BindGroupEntry.TextureEntry(mActiveAtlasView),
			BindGroupEntry.BufferEntry(localBuffer, 0, mLocalShadowRing.ByteCapacity),
			BindGroupEntry.SamplerEntry(mShadowSampler),
			BindGroupEntry.BufferEntry(boneBuffer, 0, mBoneDeviceBytes),
			BindGroupEntry.BufferEntry(sh, 0, cShBytes),
			BindGroupEntry.TextureEntry(prefilter),
			BindGroupEntry.TextureEntry(brdf),
			BindGroupEntry.SamplerEntry(mEnvSampler),
			BindGroupEntry.TextureEntry(mActiveProbeCube),
			BindGroupEntry.BufferEntry(mActiveProbeBuffer, 0, cProbeBufferBytes));

		var desc = BindGroupDesc();
		desc.Layout = mViewLayout;
		desc.Entries = .(&entries[0], 13);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let group)))
			return false;

		mViewBindGroups[index].Group = group;
		mViewBindGroups[index].ViewGeneration = mViewRing.Generation;
		mViewBindGroups[index].LightGeneration = mLightRing.Generation;
		mViewBindGroups[index].Shadow = mActiveShadowView;
		mViewBindGroups[index].ShadowGeneration = mActiveShadowGeneration;
		mViewBindGroups[index].Atlas = mActiveAtlasView;
		mViewBindGroups[index].AtlasGeneration = mActiveAtlasGeneration;
		mViewBindGroups[index].LocalGeneration = mLocalShadowRing.Generation;
		mViewBindGroups[index].BoneGeneration = mBoneDeviceGeneration;
		mViewBindGroups[index].IblGeneration = iblGeneration;
		mViewBindGroups[index].Prefilter = prefilter;
		mViewBindGroups[index].ProbeCube = mActiveProbeCube;
		mViewBindGroups[index].ProbeBuffer = mActiveProbeBuffer;
		mViewBindGroup = group;
		return true;
	}

	private bool EnsureShadowViewBindGroup()
	{
		if ((mShadowViewBindGroup != null)
			&& (mShadowViewBindGroupGeneration == mShadowViewRing.Generation)
			&& (mShadowViewBindGroupBoneGeneration == mBoneDeviceGeneration))
			return true;

		RetireBindGroup(mShadowViewBindGroup);
		mShadowViewBindGroup = null;

		let buffer = mShadowViewRing.Buffer;
		let boneBuffer = mBoneDevice;
		if ((buffer == null) || (boneBuffer == null))
			return false;

		var entries = BindGroupEntry[2](
			BindGroupEntry.BufferEntry(buffer, 0, sizeof(MeshShadowViewData)),
			BindGroupEntry.BufferEntry(boneBuffer, 0, mBoneDeviceBytes));

		var desc = BindGroupDesc();
		desc.Layout = mShadowViewLayout;
		desc.Entries = .(&entries[0], 2);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let group)))
			return false;

		mShadowViewBindGroup = group;
		mShadowViewBindGroupGeneration = mShadowViewRing.Generation;
		mShadowViewBindGroupBoneGeneration = mBoneDeviceGeneration;
		return true;
	}

	/// The comparison sampler and the single pixel stand ins bound when no caster exists, so
	/// the descriptor set is always complete.
	private Result<void> CreateShadowResources()
	{
		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		samplerDesc.MipmapFilter = .Nearest;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		// Lit where the fragment is no further than what the map recorded.
		samplerDesc.Compare = .LessEqual;
		samplerDesc.Label = "mesh.shadowSampler";
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let shadowSampler)))
			return .Err;
		mShadowSampler = shadowSampler;

		var shadowDesc = TextureDesc();
		shadowDesc.Format = .Depth32Float;
		shadowDesc.Width = 1;
		shadowDesc.Height = 1;
		shadowDesc.ArrayLayerCount = 1;
		shadowDesc.Usage = .DepthStencil | .Sampled;
		shadowDesc.Label = "mesh.dummyShadow";
		if (!(mDevice.CreateTexture(shadowDesc) case .Ok(let shadowTexture)))
			return .Err;
		mDummyShadowTexture = shadowTexture;

		// An ARRAY view of one layer, matching the shader's array shadow binding.
		var shadowViewDesc = TextureViewDesc();
		shadowViewDesc.Format = .Depth32Float;
		shadowViewDesc.Aspect = .DepthOnly;
		shadowViewDesc.Dimension = .Texture2DArray;
		shadowViewDesc.ArrayLayerCount = 1;
		if (!(mDevice.CreateTextureView(shadowTexture, shadowViewDesc) case .Ok(let shadowView)))
			return .Err;
		mDummyShadowView = shadowView;
		mActiveShadowView = shadowView;

		var atlasDesc = TextureDesc();
		atlasDesc.Format = .Depth32Float;
		atlasDesc.Width = 1;
		atlasDesc.Height = 1;
		atlasDesc.ArrayLayerCount = 2;
		atlasDesc.Usage = .DepthStencil | .Sampled;
		atlasDesc.Label = "mesh.dummyAtlas";
		if (!(mDevice.CreateTexture(atlasDesc) case .Ok(let atlasTexture)))
			return .Err;
		mDummyAtlasTexture = atlasTexture;

		var atlasViewDesc = TextureViewDesc();
		atlasViewDesc.Format = .Depth32Float;
		atlasViewDesc.Aspect = .DepthOnly;
		atlasViewDesc.Dimension = .Texture2DArray;
		atlasViewDesc.ArrayLayerCount = 2;
		if (!(mDevice.CreateTextureView(atlasTexture, atlasViewDesc) case .Ok(let atlasView)))
			return .Err;
		mDummyAtlasView = atlasView;
		mActiveAtlasView = atlasView;

		// The environment's stand ins: zeroed coefficients, so no ambient at all, a single
		// pixel black cube, and a single pixel lookup table. The colour ones are transitioned
		// with the depth ones the first time the encoder is held.
		var envSamplerDesc = SamplerDesc();
		envSamplerDesc.MinFilter = .Linear;
		envSamplerDesc.MagFilter = .Linear;
		envSamplerDesc.MipmapFilter = .Linear;
		envSamplerDesc.AddressU = .ClampToEdge;
		envSamplerDesc.AddressV = .ClampToEdge;
		envSamplerDesc.AddressW = .ClampToEdge;
		envSamplerDesc.Label = "mesh.envSampler";
		if (!(mDevice.CreateSampler(envSamplerDesc) case .Ok(let envSampler)))
			return .Err;
		mEnvSampler = envSampler;

		var shDesc = BufferDesc();
		shDesc.Size = cShBytes;
		shDesc.Usage = .Storage;
		shDesc.Memory = .GpuOnly;
		shDesc.Label = "mesh.dummySH";
		if (!(mDevice.CreateBuffer(shDesc) case .Ok(let shBuffer)))
			return .Err;
		mDummyShBuffer = shBuffer;

		var cubeDesc = TextureDesc();
		cubeDesc.Format = .RGBA16Float;
		cubeDesc.Width = 1;
		cubeDesc.Height = 1;
		cubeDesc.ArrayLayerCount = 6;
		cubeDesc.Usage = .Sampled | .CopyDst;
		cubeDesc.Label = "mesh.dummyCube";
		if (!(mDevice.CreateTexture(cubeDesc) case .Ok(let cube)))
			return .Err;
		mDummyCube = cube;

		var cubeViewDesc = TextureViewDesc();
		cubeViewDesc.Format = .RGBA16Float;
		cubeViewDesc.Dimension = .TextureCube;
		cubeViewDesc.ArrayLayerCount = 6;
		if (!(mDevice.CreateTextureView(cube, cubeViewDesc) case .Ok(let cubeView)))
			return .Err;
		mDummyCubeView = cubeView;

		var brdfDesc = TextureDesc();
		brdfDesc.Format = .RG16Float;
		brdfDesc.Width = 1;
		brdfDesc.Height = 1;
		brdfDesc.Usage = .Sampled | .CopyDst;
		brdfDesc.Label = "mesh.dummyBRDF";
		if (!(mDevice.CreateTexture(brdfDesc) case .Ok(let brdf)))
			return .Err;
		mDummyBrdf = brdf;

		var brdfViewDesc = TextureViewDesc();
		brdfViewDesc.Format = .RG16Float;
		brdfViewDesc.Dimension = .Texture2D;
		if (!(mDevice.CreateTextureView(brdf, brdfViewDesc) case .Ok(let brdfView)))
			return .Err;
		mDummyBrdfView = brdfView;

		// One cube's worth of layers, bound when no probe is active. The count being nought,
		// the shading stays on the global environment and the content never matters.
		var probeCubeDesc = TextureDesc();
		probeCubeDesc.Format = .RGBA16Float;
		probeCubeDesc.Width = 1;
		probeCubeDesc.Height = 1;
		probeCubeDesc.ArrayLayerCount = 6;
		probeCubeDesc.Usage = .Sampled | .CopyDst;
		probeCubeDesc.Label = "mesh.dummyProbeCube";
		if (!(mDevice.CreateTexture(probeCubeDesc) case .Ok(let probeCube)))
			return .Err;
		mDummyProbeCube = probeCube;

		var probeCubeViewDesc = TextureViewDesc();
		probeCubeViewDesc.Format = .RGBA16Float;
		probeCubeViewDesc.Dimension = .TextureCubeArray;
		probeCubeViewDesc.ArrayLayerCount = 6;
		if (!(mDevice.CreateTextureView(probeCube, probeCubeViewDesc) case .Ok(let probeCubeView)))
			return .Err;
		mDummyProbeCubeView = probeCubeView;

		var probeBufferDesc = BufferDesc();
		probeBufferDesc.Size = cProbeBufferBytes;
		probeBufferDesc.Usage = .Storage;
		probeBufferDesc.Memory = .GpuOnly;
		probeBufferDesc.Label = "mesh.dummyProbeBuf";
		if (!(mDevice.CreateBuffer(probeBufferDesc) case .Ok(let probeBuffer)))
			return .Err;
		mDummyProbeBuffer = probeBuffer;

		mActiveProbeCube = mDummyProbeCubeView;
		mActiveProbeBuffer = mDummyProbeBuffer;
		return .Ok;
	}

	/// Tiny placeholder cluster buffers and a group over them, bound when the clustering is
	/// unavailable. The shader's own zero grid path never reads them, but the set must be bound.
	private Result<void> CreateDummyClusters()
	{
		var offsetsDesc = BufferDesc();
		offsetsDesc.Size = sizeof(uint32) * 2;
		offsetsDesc.Usage = .Storage | .CopyDst;
		offsetsDesc.Memory = .GpuOnly;
		offsetsDesc.Label = "cluster.dummyOffsets";
		if (!(mDevice.CreateBuffer(offsetsDesc) case .Ok(let offsets)))
			return .Err;
		mDummyClusterOffsets = offsets;

		var indicesDesc = BufferDesc();
		indicesDesc.Size = sizeof(uint32);
		indicesDesc.Usage = .Storage | .CopyDst;
		indicesDesc.Memory = .GpuOnly;
		indicesDesc.Label = "cluster.dummyIndices";
		if (!(mDevice.CreateBuffer(indicesDesc) case .Ok(let indices)))
			return .Err;
		mDummyClusterIndices = indices;

		// ZERO THEM. A device local buffer's contents are undefined on some backends, and the
		// shading reads the second component of an offset as a LOOP COUNT: garbage there is an
		// endless loop on the GPU and a reset device.
		let queue = mDevice.GetQueue(.Graphics, 0);
		if (queue != null)
		{
			if (queue.CreateTransferBatch() case .Ok(var batch))
			{
				var zeros = uint32[2](0, 0);
				batch.WriteBuffer(mDummyClusterOffsets, 0,
					.((uint8*)&zeros[0], sizeof(uint32) * 2));

				uint32 zero = 0;
				batch.WriteBuffer(mDummyClusterIndices, 0, .((uint8*)&zero, sizeof(uint32)));

				batch.Submit().IgnoreError();
				queue.DestroyTransferBatch(ref batch);
			}
		}

		var entries = BindGroupEntry[2](
			BindGroupEntry.BufferEntry(mDummyClusterOffsets, 0, sizeof(uint32) * 2),
			BindGroupEntry.BufferEntry(mDummyClusterIndices, 0, sizeof(uint32)));

		var desc = BindGroupDesc();
		desc.Layout = mClusterLayout;
		desc.Entries = .(&entries[0], 2);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let group)))
			return .Err;
		mDummyClusterBindGroup = group;
		return .Ok;
	}

	/// The set three group for one view and frame slot.
	///
	/// It is rebuilt when the buffers' VERSION changes rather than when their addresses do: a
	/// freed buffer's address is reused by the new allocation, so a cache keyed on the address
	/// would keep pointing at a destroyed one.
	private IBindGroup EnsureClusterBindGroup(int slot, IBuffer offsets, IBuffer indices,
		uint32 version)
	{
		if ((slot < 0) || (slot >= cMaxClusterSlots) || (offsets == null) || (indices == null))
			return mDummyClusterBindGroup;

		if ((mClusterBindGroups[slot] != null) && (mClusterBindGroupOffsets[slot] == offsets)
			&& (mClusterBindGroupVersions[slot] == version))
			return mClusterBindGroups[slot];

		if (mClusterBindGroups[slot] != null)
			mDevice.DestroyBindGroup(ref mClusterBindGroups[slot]);

		var entries = BindGroupEntry[2](
			BindGroupEntry.BufferEntry(offsets, 0, offsets.Size),
			BindGroupEntry.BufferEntry(indices, 0, indices.Size));

		var desc = BindGroupDesc();
		desc.Layout = mClusterLayout;
		desc.Entries = .(&entries[0], 2);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let group)))
			return mDummyClusterBindGroup;

		mClusterBindGroups[slot] = group;
		mClusterBindGroupOffsets[slot] = offsets;
		mClusterBindGroupVersions[slot] = version;
		return group;
	}

	// ==================== Motion, sharing and detail ====================

	/// Records this frame's world for an entity and answers its previous one.
	///
	/// Indexed by the entity's own index, so several views resolving the same object read a
	/// STABLE previous: writing the current one never touches it, the two being separate
	/// buffers. An entry never written reads back as the current world, which is no motion.
	private Float4x4 PrevWorldFor(uint64 entityId, Float4x4 current)
	{
		// The identifier is a generation and an index; the index is the low half.
		let index = (int)(uint32)entityId;

		// Grows toward the highest live index and then stays put.
		while (mCurWorld.Count <= index)
			mCurWorld.Add(Float4x4.Identity());
		mCurWorld[index] = current;

		return (index < mPrevWorld.Count) ? mPrevWorld[index] : current;
	}

	/// Keyed by the VIEW rather than its index: the main view's prepass and forward share one
	/// view, but a probe capture reuses index nought with a different list entirely.
	private static uint64 InstShareKey(Object mesh, Object material, Object view)
	{
		var key = FnvOffsetBasis;
		key = (key ^ (uint64)(int)(void*)Internal.UnsafeCastToPtr(view)) &* FnvPrime;
		key = (key ^ (uint64)(int)(void*)Internal.UnsafeCastToPtr(mesh)) &* FnvPrime;
		key = (key ^ (uint64)(int)(void*)Internal.UnsafeCastToPtr(material)) &* FnvPrime;
		return key;
	}

	/// This view's level for an item: the projected coverage of its bounds against this
	/// camera, pinned by a forced level, and steadied by the hysteresis remembered per view and
	/// item, so a view's prepass and forward always agree within a frame.
	private uint32 SelectLod(RenderRecordContext context, MeshRenderData md)
	{
		let mesh = md.Mesh;
		if ((mesh == null) || (mesh.LodCount <= 1))
			return 0;

		let maxLod = (uint32)(mesh.LodCount - 1);
		if (md.ForceLod >= 0)
			return ((uint32)md.ForceLod < maxLod) ? (uint32)md.ForceLod : maxLod;

		if (context.View == null)
		{
			// A camera independent pass, which is what a local shadow tile is: the COARSEST
			// level, since a shadow is never finer than anything a view shows. A cascade passes
			// its owning view instead and shares that view's memory.
			return maxLod;
		}

		let coverage = MeshLod.LodCoverageFor(context.View.Camera, md.WorldCenter, md.WorldRadius,
			md.LodBias);
		var selection = MeshLod.PickLodLevel(mesh, coverage);

		// Keyed per view and item: the entity where there is one, else the mesh's own identity,
		// which covers a preview with no entity behind it.
		let itemId = (md.EntityId != 0) ? md.EntityId : mesh.Uid;
		var key = FnvOffsetBasis;
		key = (key ^ (uint64)(int)(void*)Internal.UnsafeCastToPtr(context.View)) &* FnvPrime;
		key = (key ^ itemId) &* FnvPrime;

		if (mLodLast.TryGetValue(key, let last))
			selection = MeshLod.ApplyLodHysteresis(mesh, coverage, selection, last);

		// Bounded memory: at worst one frame of unsmoothed selection.
		if (mLodLast.Count > 65536)
			mLodLast.Clear();

		mLodLast[key] = selection;
		return selection;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		// The instances first: their destructors tell the still live material system, which
		// owns and destroys their data driven groups.
		for (let pair in mInstances)
			delete pair.value.Instance;
		mInstances.Clear();

		mMeshes.Clear();

		for (var retired in ref mRetiredBindGroups)
		{
			if (retired.Group != null)
				mDevice.DestroyBindGroup(ref retired.Group);
		}
		mRetiredBindGroups.Clear();

		for (var retired in ref mRetiredBuffers)
		{
			if (retired.Buffer != null)
				mDevice.DestroyBuffer(ref retired.Buffer);
		}
		mRetiredBuffers.Clear();

		for (var slot in ref mViewBindGroups)
		{
			if (slot.Group != null)
				mDevice.DestroyBindGroup(ref slot.Group);
		}
		mViewBindGroups.Clear();
		// Borrowed from a slot, and already destroyed above.
		mViewBindGroup = null;

		if (mShadowViewBindGroup != null)
			mDevice.DestroyBindGroup(ref mShadowViewBindGroup);
		if (mObjectBindGroup != null)
			mDevice.DestroyBindGroup(ref mObjectBindGroup);
		if (mInstanceBindGroup != null)
			mDevice.DestroyBindGroup(ref mInstanceBindGroup);

		if (mBoneDevice != null)
		{
			mDevice.DestroyBuffer(ref mBoneDevice);
			mBoneDeviceBytes = 0;
		}

		if (mDummyShadowView != null)
			mDevice.DestroyTextureView(ref mDummyShadowView);
		if (mDummyShadowTexture != null)
			mDevice.DestroyTexture(ref mDummyShadowTexture);
		if (mDummyAtlasView != null)
			mDevice.DestroyTextureView(ref mDummyAtlasView);
		if (mDummyAtlasTexture != null)
			mDevice.DestroyTexture(ref mDummyAtlasTexture);
		if (mShadowSampler != null)
			mDevice.DestroySampler(ref mShadowSampler);

		if (mDummyCubeView != null)
			mDevice.DestroyTextureView(ref mDummyCubeView);
		if (mDummyCube != null)
			mDevice.DestroyTexture(ref mDummyCube);
		if (mDummyBrdfView != null)
			mDevice.DestroyTextureView(ref mDummyBrdfView);
		if (mDummyBrdf != null)
			mDevice.DestroyTexture(ref mDummyBrdf);
		if (mDummyProbeCubeView != null)
			mDevice.DestroyTextureView(ref mDummyProbeCubeView);
		if (mDummyProbeCube != null)
			mDevice.DestroyTexture(ref mDummyProbeCube);
		if (mDummyProbeBuffer != null)
			mDevice.DestroyBuffer(ref mDummyProbeBuffer);
		if (mDummyShBuffer != null)
			mDevice.DestroyBuffer(ref mDummyShBuffer);
		if (mEnvSampler != null)
			mDevice.DestroySampler(ref mEnvSampler);

		for (let pair in mMultiMeshSets)
		{
			let set = pair.value;
			for (int r < MultiMeshSet.cMaxFramesInFlight)
			{
				if (set.InstanceBindGroups[r] != null)
					mDevice.DestroyBindGroup(ref set.InstanceBindGroups[r]);
			}
			if (set.InstanceBuffer != null)
				mDevice.DestroyBuffer(ref set.InstanceBuffer);
			if (set.OffsetsBuffer != null)
				mDevice.DestroyBuffer(ref set.OffsetsBuffer);
			delete set;
		}
		mMultiMeshSets.Clear();

		if (mRampBuffer != null)
		{
			mDevice.DestroyBuffer(ref mRampBuffer);
			mRampCapacity = 0;
		}

		for (int i < cMaxClusterSlots)
		{
			if (mClusterBindGroups[i] != null)
				mDevice.DestroyBindGroup(ref mClusterBindGroups[i]);
		}
		if (mDummyClusterBindGroup != null)
			mDevice.DestroyBindGroup(ref mDummyClusterBindGroup);
		if (mDummyClusterOffsets != null)
			mDevice.DestroyBuffer(ref mDummyClusterOffsets);
		if (mDummyClusterIndices != null)
			mDevice.DestroyBuffer(ref mDummyClusterIndices);

		for (let pair in mPipelineLayouts)
		{
			var layout = pair.value;
			if (layout != null)
				mDevice.DestroyPipelineLayout(ref layout);
		}
		mPipelineLayouts.Clear();

		for (let pair in mShadowMaskedLayouts)
		{
			var layout = pair.value;
			if (layout != null)
				mDevice.DestroyPipelineLayout(ref layout);
		}
		mShadowMaskedLayouts.Clear();

		if (mShadowPipelineLayoutSingle != null)
			mDevice.DestroyPipelineLayout(ref mShadowPipelineLayoutSingle);
		if (mShadowPipelineLayoutInstanced != null)
			mDevice.DestroyPipelineLayout(ref mShadowPipelineLayoutInstanced);

		if (mViewLayout != null)
			mDevice.DestroyBindGroupLayout(ref mViewLayout);
		if (mObjectLayout != null)
			mDevice.DestroyBindGroupLayout(ref mObjectLayout);
		if (mInstanceLayout != null)
			mDevice.DestroyBindGroupLayout(ref mInstanceLayout);
		if (mClusterLayout != null)
			mDevice.DestroyBindGroupLayout(ref mClusterLayout);
		if (mShadowViewLayout != null)
			mDevice.DestroyBindGroupLayout(ref mShadowViewLayout);

		// The rings free their own buffers, the device still being valid past this point.
	}
}
