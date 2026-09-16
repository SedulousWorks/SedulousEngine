using Sedulous.Profiler;
using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.Render;

/// The SINGLE per frame driver.
///
/// Not a per view object: beginning resets the shared state, adding a view collects it, and
/// ending sizes the renderers' transients once for the whole frame and composes every view
/// into ONE graph. That is what lets several scenes and views share a frame's state without
/// clobbering each other.
class RenderFrame
{
	private RendererRegistry mRegistry;
	private ForwardPass mPass ~ delete _;
	/// ONE graph per frame, composing every view.
	private RenderGraph mGraph ~ delete _;

	// Borrowed systems. Any of them may be absent, and the composition adapts.
	private ClusterSystem mClusters = null;
	private TonemapPass mTonemap = null;
	private ShadowSystem mShadows = null;
	private IBLSystem mIbl = null;
	private SkyPass mSky = null;
	private BloomPass mBloom = null;
	private TaaPass mTaa = null;
	private AoPass mAo = null;
	private FxaaPass mFxaa = null;
	private ExposurePass mExposurePass = null;
	private DebugBlitPass mDebugBlit = null;
	private DecalPass mDecalPass = null;
	private SsrPass mSsr = null;
	private SsgiPass mSsgi = null;
	private MsaaResolvePass mMsaaResolve = null;
	private ReflectionProbeSystem mProbeSystem = null;
	private DebugDrawPass mDebugPass = null;
	private DebugDraw mDebugGlobal = null;
	private DebugDraw mDebugScreen = null;
	private List<ISceneOverlay> mSceneOverlays = null;

	private IDevice mDevice;
	private ICommandEncoder mEncoder = null;
	private uint32 mFrameIndex = 0;

	private bool mSsrEnabled = false;
	private SsrParams mSsrParams = .();

	/// The six persistent capture views, which outlive the graph's execute.
	private RenderView[6] mCaptureViews;
	/// Round robin: which dirty probe to capture this frame.
	private uint32 mProbeCaptureCursor = 0;

	/// A stencil capable format for the overlay pass, probed once. Undefined means the device
	/// has none and the pass stays colour only.
	private TextureFormat mOverlayStencilFormat = .Undefined;
	private bool mOverlayStencilProbed = false;

	private float mExposure = 1.0f;
	private bool mFxaaEnabled = false;
	private float mFxaaSubpixel = 0.75f;
	/// Sharing the prepass's instance data with the forward, which is on by default. Off
	/// re-fills in the forward, for comparison.
	private bool mInstanceSharing = true;
	/// View frustum culling of the camera draw lists, off by default.
	private bool mViewCulling = false;

	private float mShadowDistance = 300.0f;
	private float mShadowFarFade = 40.0f;

	private AoMode mAoMode = .Off;
	private int32 mAoDebug = 0;
	private float mAoStrength = 0.6f;
	private float mAoRadius = 0.5f;
	private float mAoIntensity = 1.0f;

	private float mBloomIntensity = 0.05f;
	private float mBloomThreshold = 1.0f;
	private float mBloomKnee = 0.6f;

	private bool mTaaEnabled = false;
	private float mTaaBlend = 0.97f;
	private float mTaaGamma = 1.25f;
	private float mTaaMotionScale = 32.0f;

	private float mDeltaSeconds = 1.0f / 60.0f;
	/// The jitter's phase, advancing once per frame.
	private uint32 mJitterIndex = 0;
	/// A MONOTONIC frame counter for the stochastic passes' noise.
	///
	/// The frame index the host passes in is the ring slot, and feeding that to a trace gives
	/// its noise only as many patterns as there are slots, so the accumulator converges on an
	/// average of those few and stays speckled forever.
	private uint32 mNoiseFrame = 0;
	private bool mAnyViewTaa = false;

	private List<Float4x4> mPrevViewProj = new .() ~ delete _;
	private List<Float4x4> mCurViewProj = new .() ~ delete _;
	private List<Float2> mPrevJitter = new .() ~ delete _;
	private List<Float2> mCurJitter = new .() ~ delete _;

	private List<ResolvedDraw> mPrepassResolved = new .() ~ delete _;
	private List<ResolvedDraw> mShadowResolved = new .() ~ delete _;

	/// Slot k is the k-th distinct scene this frame.
	private List<SceneShadowContext> mSceneShadowPool = new .() ~ DeleteContainerAndItems!(_);
	/// Per view, the index into the pool.
	private List<int> mViewSceneIndex = new .() ~ delete _;
	/// The scenes' entries CONCATENATED, in caster order within each scene.
	private List<GpuLocalShadow> mLocalShadows = new .() ~ delete _;

	/// The realtime atlas layer, re-rendered every frame.
	private List<AtlasDraw> mRealtimeAtlasDraws = new .() ~ delete _;
	/// The static layer's tiles, all of them, which is the cache's source.
	private List<AtlasDraw> mStaticAtlasDraws = new .() ~ delete _;
	/// The static tiles dirty THIS frame, which are the ones that render.
	private List<AtlasDraw> mStaticRenderDraws = new .() ~ delete _;
	/// The per tile culled subset, reused.
	private List<DrawItem> mShadowCullScratch = new .() ~ delete _;

	private List<ViewShadowDebug> mViewShadowDebug = new .() ~ delete _;
	private List<ShadowBinding> mViewShadows = new .() ~ delete _;

	private RenderViewPool mViews = new .() ~ delete _;
	/// The sort's ping pong buffer, reused.
	private List<DrawItem> mSortScratch = new .() ~ delete _;

	/// The distinct targets imported this frame, so several views into one target share a
	/// single imported resource.
	private List<TargetImport> mImported = new .() ~ delete _;

	private struct TargetImport
	{
		public ITextureView Target;
		public RGHandle Handle;
		public uint32 Width;
		public uint32 Height;
		public TextureFormat Format;
	}

	public this(IDevice device, RendererRegistry registry, uint32 framesInFlight,
		ClusterSystem clusters = null, TonemapPass tonemap = null, ShadowSystem shadows = null,
		IBLSystem ibl = null, SkyPass sky = null, BloomPass bloom = null, TaaPass taa = null,
		AoPass ao = null, FxaaPass fxaa = null, ExposurePass exposure = null,
		DebugBlitPass debugBlit = null)
	{
		mDevice = device;
		mRegistry = registry;
		mPass = new .(device, framesInFlight);
		mGraph = new .(device);
		mClusters = clusters;
		mTonemap = tonemap;
		mShadows = shadows;
		mIbl = ibl;
		mSky = sky;
		mBloom = bloom;
		mTaa = taa;
		mAo = ao;
		mFxaa = fxaa;
		mExposurePass = exposure;
		mDebugBlit = debugBlit;

		for (int i < 6)
			mCaptureViews[i] = new RenderView();
	}

	public ~this()
	{
		for (int i < 6)
			delete mCaptureViews[i];
	}

	// ==================== Configuration ====================

	/// The frame's own elapsed time, which the eye adaptation advances by.
	public void SetDeltaSeconds(float seconds) => mDeltaSeconds = seconds;

	/// The per frame debug lists: the pass, the GLOBAL one drawn in every view, and the SCREEN
	/// one drawn once over the whole window. A scene's own list rides on each view.
	public void SetDebug(DebugDrawPass pass, DebugDraw global, DebugDraw screen)
	{
		mDebugPass = pass;
		mDebugGlobal = global;
		mDebugScreen = screen;
	}

	/// The scene tier overlay sources, borrowed. Null or empty means no overlay pass.
	public void SetSceneOverlays(List<ISceneOverlay> overlays) => mSceneOverlays = overlays;

	public void SetDecal(DecalPass pass) => mDecalPass = pass;
	public void SetSsr(SsrPass pass) => mSsr = pass;
	public void SetSsgi(SsgiPass pass) => mSsgi = pass;
	public void SetMsaaResolve(MsaaResolvePass pass) => mMsaaResolve = pass;
	public void SetProbes(ReflectionProbeSystem probes) => mProbeSystem = probes;

	public void SetSsrParams(bool enabled, SsrParams parameters)
	{
		mSsrEnabled = enabled;
		mSsrParams = parameters;
	}

	public void EnableGpuProfiling() => mGraph.EnableGpuProfiling();

	public void SetExposure(float exposure) => mExposure = exposure;

	public void SetBloom(float intensity, float threshold, float knee)
	{
		mBloomIntensity = intensity;
		mBloomThreshold = threshold;
		mBloomKnee = knee;
	}

	public void SetTaa(bool on, float blend, float gamma, float motionScale)
	{
		mTaaEnabled = on;
		mTaaBlend = blend;
		mTaaGamma = gamma;
		mTaaMotionScale = motionScale;
	}

	public void SetAo(AoMode mode, float strength, float radius, float intensity,
		int32 debugMode = 0)
	{
		mAoMode = mode;
		mAoStrength = strength;
		mAoRadius = radius;
		mAoIntensity = intensity;
		mAoDebug = debugMode;
	}

	public void SetFxaa(bool on, float subpixelQuality)
	{
		mFxaaEnabled = on;
		mFxaaSubpixel = subpixelQuality;
	}

	public void SetInstanceSharing(bool on) => mInstanceSharing = on;
	public bool InstanceSharing => mInstanceSharing;

	public void SetViewCulling(bool on) => mViewCulling = on;
	public bool ViewCulling => mViewCulling;

	/// The directional shadows' reach in world units, clamped to the camera's own far plane,
	/// and the width of the fade at its edge. A larger reach covers more ground but spreads
	/// the cascade texel density; the fade dissolves the boundary so it does not pop along a
	/// diagonal when the camera tilts.
	public void SetShadowParams(float distance, float farFade)
	{
		mShadowDistance = distance;
		mShadowFarFade = farFade;
	}

	/// Last frame's cull totals summed over the active views. Read BEFORE beginning, which
	/// rewinds the pool.
	public void CullStats(out uint32 culled, out uint32 total)
	{
		culled = 0;
		total = 0;
		for (int i < mViews.ActiveCount)
		{
			culled += mViews.At(i).CulledCount;
			total += mViews.At(i).SceneItemCount;
		}
	}

	/// The LAST composition's per view shadow state, for the tests and the tools.
	public Span<ViewShadowDebug> ViewShadowInfo => mViewShadowDebug;
	public Span<GpuLocalShadow> LocalShadowEntries => mLocalShadows;

	public int ViewCount => mViews.ActiveCount;
	/// The frame's graph, for introspection. Valid from the end of a frame until the next
	/// begin rebuilds it.
	public RenderGraph Graph => mGraph;

	public void ReadGpuProfile(String outReport)
	{
		let profiler = mGraph.GpuProfiler;
		if (profiler != null)
			profiler.ReadResults(mGraph.LastProfiledPassCount, outReport);
		mGraph.AppendCpuPassReport(outReport);
	}

	// ==================== The frame ====================

	/// Opens the frame against the caller's encoder, which the caller owns along with the
	/// targets.
	public void Begin(ICommandEncoder encoder, uint32 frameIndex)
	{
		mEncoder = encoder;
		mFrameIndex = frameIndex;
		mNoiseFrame++;
		mViews.Begin();

		// The motion vectors are consumed only by the temporal antialiasing and the temporal
		// reflections; with neither active the forward skips the per instance previous world
		// lookup, which at scale is a whole scene's worth of work per frame.
		mPass.SetMotionNeeded(mTaaEnabled
			|| ((mSsr != null) && mSsrEnabled && mSsrParams.Temporal));
		mPass.SetShadowFarFade(mShadowFarFade);

		mGraph.BeginFrame((int32)frameIndex);
	}

	/// Collects a view over a scene. Its sorted draw list is built NOW; the recording is
	/// deferred to the end, so the transient buffers are sized once for the frame.
	///
	/// The scene list draws in every view of that scene; the view list draws ONLY here, which
	/// is what keeps a camera preview's chrome out of the main view.
	public RenderView AddView(ExtractedScene scene, ViewCamera camera, ViewSettings settings,
		ITextureView target, TextureFormat targetFormat, uint32 width, uint32 height,
		void* debugScene = null, void* sceneKey = null, void* debugView = null)
	{
		let view = mViews.Acquire();
		view.Bind(scene, camera, settings, target, targetFormat, width, height);
		view.SetDebugScene(debugScene);
		view.SetDebugView(debugView);
		view.SetSceneKey(sceneKey);
		view.BuildDrawList(mSortScratch, mViewCulling);
		return view;
	}

	// ==================== The depth and shadow bodies ====================

	/// The depth prepass: this view's OPAQUE draws, depth only from the camera, with NO bias so
	/// the depth equals the forward's exactly and the equal test accepts the redrawn fragments.
	///
	/// Masked geometry is not prepassed, the depth only shader having no way to discard, and
	/// blended geometry writes no depth at all.
	private void RecordDepthPrepass(IRenderPassEncoder encoder, RenderView view,
		RendererRegistry registry, uint32 viewIndex)
	{
		var context = RenderRecordContext();
		// The share cache is keyed by the view: the prepass fills it and the forward reuses it.
		context.View = view;
		context.ViewProj = view.Camera.ViewProjection;
		// The camera's own view matrix, because the per view LEVEL SELECTION reads it. Without
		// it the prepass selects from an identity view, which puts the camera at the origin and
		// so always picks the finest level, while the forward selects by real distance: two
		// different surfaces whose depths then fight.
		context.ViewMatrix = view.Camera.View;
		context.DepthFormat = mPass.DepthFormat;
		context.DepthPrepass = true;
		// The prepass runs at the view's sample count, so the early rejection matches the
		// forward exactly.
		context.SampleCount = (view.Settings.Post.MsaaSamples > 1)
			? view.Settings.Post.MsaaSamples
			: (uint8)1;
		context.FrameIndex = mFrameIndex;
		context.ViewIndex = viewIndex;
		// Build the FULL per instance data here, once, and record each group's range for the
		// forward to reuse. It needs the same previous world the forward would use, so the
		// motion condition is mirrored.
		context.FillInstanceCache = mInstanceSharing;
		context.NeedsMotion = view.Settings.Post.NeedsMotion;

		mPrepassResolved.Clear();
		let items = view.DrawList;
		var i = 0;
		while (i < items.Length)
		{
			// Grouped by CATEGORY AND RENDERER. An opaque run can interleave renderers, meshes
			// and terrain in one scene, and handing a whole category run to the first item's
			// renderer makes it read foreign data as its own.
			let category = items[i].Data.Category;
			let rendererId = items[i].Data.RendererId;
			var j = i + 1;
			while ((j < items.Length) && (items[j].Data.Category == category)
				&& (items[j].Data.RendererId == rendererId))
				j++;

			if (category == RenderCategories.Opaque)
			{
				let renderer = registry.ById(rendererId);
				if (renderer != null)
					renderer.ResolveDepthOnly(context, .(items.Ptr + i, j - i), mPrepassResolved);
			}

			i = j;
		}

		for (let draw in mPrepassResolved)
			DrawEmitter.EmitDraw(encoder, draw);
	}

	/// Re-emits a caster list as depth only draws from a light's point of view.
	///
	/// The casters are camera independent for a local light, being that scene's whole list, or
	/// the view's own list for a cascade. A positive cull radius rejects a caster whose sphere
	/// does not meet the light's.
	///
	/// The level view is the CAMERA whose selection the casters follow: a cascade passes its
	/// owning view, so the shadow matches what that view draws; a camera independent tile
	/// passes null, which takes each chain's coarsest level, shadows never needing to be finer
	/// than anything on screen.
	private void RecordShadowCasters(IRenderPassEncoder encoder, Span<DrawItem> casters,
		RendererRegistry registry, Float4x4 lightViewProj, Float3 cullCenter = .(0, 0, 0),
		float cullRadius = 0.0f, bool frustumCull = false, Span<Float4> cullBounds = default,
		RenderView lodView = null)
	{
		var context = RenderRecordContext();
		// The level coupling only; the light's own matrices follow.
		context.View = lodView;
		if (lodView != null)
		{
			// The owning camera's matrices, for the coverage maths ALONE. The light's matrix
			// below still drives the culling and the draw itself.
			context.ViewMatrix = lodView.Camera.View;
			context.CameraPos = lodView.Camera.Position;
		}
		context.ViewProj = lightViewProj;
		context.DepthFormat = (mShadows != null) ? mShadows.Format : TextureFormat.Depth32Float;
		context.FrameIndex = mFrameIndex;
		context.ViewIndex = 0;

		var items = casters;

		if (frustumCull)
		{
			// A cascade: reject a caster whose sphere does not meet THIS cascade's frustum.
			// The cascade's matrix already reaches back toward the light, so its frustum is the
			// right assignment volume and each caster lands in about one cascade rather than
			// being drawn into all of them.
			let frustum = BoundingFrustum(lightViewProj);
			mShadowCullScratch.Clear();

			if (cullBounds.Length == casters.Length)
			{
				// The compact bounds stream linearly, four to a cache line, rather than
				// chasing each item's own allocation. This is the hot path at scale.
				for (int k < casters.Length)
				{
					let bounds = cullBounds[k];
					let center = Float3(bounds.X, bounds.Y, bounds.Z);

					// Inline, with an early exit: outside ANY plane is out. The normals point
					// outward, so a positive distance beyond the radius rejects.
					var inside = true;
					for (int p < BoundingFrustum.PlaneCount)
					{
						if ((Dot(frustum.Planes[p].Normal, center) + frustum.Planes[p].D)
							> bounds.W)
						{
							inside = false;
							break;
						}
					}
					if (inside)
						mShadowCullScratch.Add(casters[k]);
				}
			}
			else
			{
				for (let item in casters)
				{
					if (Intersects(frustum, BoundingSphere(item.Data.WorldCenter,
						item.Data.WorldRadius)))
						mShadowCullScratch.Add(item);
				}
			}

			items = mShadowCullScratch;
		}
		else if (cullRadius > 0.0f)
		{
			mShadowCullScratch.Clear();
			for (let item in casters)
			{
				let delta = item.Data.WorldCenter - cullCenter;
				let reach = cullRadius + item.Data.WorldRadius;
				if (Dot(delta, delta) <= (reach * reach))
					mShadowCullScratch.Add(item);
			}
			items = mShadowCullScratch;
		}

		// Grouped by RENDERER rather than by category: the caster list can be a view's draw
		// list, whose blended span mixes transparent meshes and sprites interleaved by depth,
		// and handing a whole category run to the first item's renderer would give one
		// renderer another's data to read as its own. A sprite's depth only resolve does
		// nothing, sprites casting no shadows.
		mShadowResolved.Clear();
		var i = 0;
		while (i < items.Length)
		{
			let rendererId = items[i].Data.RendererId;
			var j = i + 1;
			while ((j < items.Length) && (items[j].Data.RendererId == rendererId))
				j++;

			let renderer = registry.ById(rendererId);
			if (renderer != null)
				renderer.ResolveDepthOnly(context, .(items.Ptr + i, j - i), mShadowResolved);

			i = j;
		}

		for (let draw in mShadowResolved)
			DrawEmitter.EmitDraw(encoder, draw);
	}

	/// Builds a scene's camera INDEPENDENT caster list, opaque and masked, grouped so the depth
	/// pass batches. Shared by that scene's cascades and its local tiles alike, which is what
	/// keeps view frustum culling from ever dropping a caster whose shadow is visible.
	private void BuildShadowCasterList(ExtractedScene scene, SceneShadowContext context)
	{
		context.Casters.Clear();
		context.AnimatedSpheres.Clear();

		for (let data in scene.Items)
		{
			if (data == null)
				continue;
			if ((data.Category != RenderCategories.Opaque)
				&& (data.Category != RenderCategories.Masked))
				continue;

			// The list is HETEROGENEOUS: any renderer can produce a caster, not only the mesh
			// one. Only the GENERIC base fields are read here. The one mesh specific need, a
			// skinned caster's sphere, is gated on the mesh renderer's id, which is nought by
			// contract and the only producer that carries bone data.
			var stateBits = data.SortBatchKey & ((1u << SortKeys.StateBits) - 1);

			if (data.RendererId == 0)
			{
				let mesh = (MeshRenderData)data;
				// A skinned caster deforms every frame, so its sphere is remembered and only
				// the static tiles whose light volume it overlaps are re-rendered.
				if ((mesh.BoneMatrices != null) && (mesh.BoneCount > 0))
					context.AnimatedSpheres.Add(.(mesh.WorldCenter, mesh.WorldRadius));

				stateBits = SortKeys.BatchKey(Internal.UnsafeCastToPtr(mesh.Mesh),
					(mesh.Material != null) ? Internal.UnsafeCastToPtr(mesh.Material) : null);
			}

			context.Casters.Add(.(SortKeys.MakeSortKey(data.Category, stateBits, 0), data));
		}

		DrawItemSorter.RadixSortDrawItems(context.Casters, mSortScratch);

		// The compact bounds, aligned to the SORTED order, so the per cascade cull streams them
		// rather than chasing each item.
		context.CasterBounds.Clear();
		for (let item in context.Casters)
		{
			context.CasterBounds.Add(.(item.Data.WorldCenter.X, item.Data.WorldCenter.Y,
				item.Data.WorldCenter.Z, item.Data.WorldRadius));
		}
	}

	/// A signature over the STATIC casters' quantised transforms and their count. When it
	/// moves, the cached static layer re-renders for one cycle of frames in flight.
	///
	/// The static contract is that the caster GEOMETRY does not move, so only the lights
	/// themselves feed this.
	private static uint64 StaticCasterSignature(ExtractedScene scene)
	{
		if (scene == null)
			return 0;

		var signature = FnvOffsetBasis;

		mixin Mix(float value)
		{
			// About a millimetre, which is finer than any change that ought to matter.
			let quantised = (uint64)(int64)(value * 1000.0f);
			signature = (signature ^ quantised) &* FnvPrime;
		}

		for (let caster in scene.LocalShadowCasters)
		{
			if (!caster.IsStatic)
				continue;

			Mix!((float)caster.Type);
			Mix!(caster.PositionWS.X);
			Mix!(caster.PositionWS.Y);
			Mix!(caster.PositionWS.Z);
			Mix!(caster.DirectionWS.X);
			Mix!(caster.DirectionWS.Y);
			Mix!(caster.DirectionWS.Z);
			Mix!(caster.Range);
			Mix!(caster.OuterAngle);
		}

		return signature;
	}

	// ==================== Composition ====================

	/// Pools this frame's DISTINCT scenes in order of first appearance and records which one
	/// each view reads. Returns how many there are.
	private int BuildSceneContexts()
	{
		mViewSceneIndex.Clear();
		for (int i < mViews.ActiveCount)
			mViewSceneIndex.Add(-1);

		var sceneCount = 0;
		for (int i < mViews.ActiveCount)
		{
			let scene = mViews.At(i).Scene;
			if (scene == null)
				continue;

			var slot = sceneCount;
			for (int k < sceneCount)
			{
				if (mSceneShadowPool[k].Scene == scene)
				{
					slot = k;
					break;
				}
			}

			if (slot == sceneCount)
			{
				while (mSceneShadowPool.Count <= slot)
					mSceneShadowPool.Add(new SceneShadowContext());

				let context = mSceneShadowPool[slot];
				context.Scene = scene;
				context.Casters.Clear();
				context.CasterBounds.Clear();
				context.AnimatedSpheres.Clear();
				context.StaticTiles.Clear();
				context.StaticRenderTiles.Clear();
				context.EntryBase = 0;
				context.Ibl = null;
				sceneCount++;
			}

			mViewSceneIndex[i] = slot;
		}

		// A stale slot must not alias a fresh frame's set of scenes.
		for (int k = sceneCount; k < mSceneShadowPool.Count; k++)
			mSceneShadowPool[k].Scene = null;

		return sceneCount;
	}

	/// Lays out this frame's local light tiles across the ONE atlas, per scene, and decides
	/// which static tiles are dirty enough to re-render.
	private uint32 BuildLocalShadowTiles(int sceneCount)
	{
		let capacity = mShadows.AtlasTileCapacity;
		let atlasResolution = mShadows.AtlasResolution;
		let tileResolution = mShadows.AtlasTileResolution;
		let framesInFlight = mShadows.FramesInFlight;

		// The per layer tile counters are GLOBAL, running across the scenes: one physical
		// atlas, its tile space handed out to whoever asks.
		uint32 realtimeTile = 0;
		uint32 staticTile = 0;
		uint32 staticTileCount = 0;

		for (int k < sceneCount)
		{
			let context = mSceneShadowPool[k];
			context.EntryBase = (uint32)mLocalShadows.Count;
			let sceneStaticTileBase = staticTile;

			for (let caster in context.Scene.LocalShadowCasters)
			{
				// A point light needs all six faces; a spot needs one.
				let need = (caster.Type == 1) ? (uint32)6 : (uint32)1;

				var tileCounter = caster.IsStatic ? staticTile : realtimeTile;

				// Extraction already gave this caster an index within its own scene; whether it
				// FITS depends on the whole frame's budget. One that does not fit still
				// consumes its slots, as DEGENERATE entries the shading reads as unshadowed, so
				// every later caster's index stays aligned.
				let fits = ((tileCounter + need) <= capacity)
					&& (((uint32)mLocalShadows.Count + need) <= RenderLimits.MaxLocalShadowEntries);

				if (!fits)
				{
					for (uint32 f = 0; (f < need)
						&& ((uint32)mLocalShadows.Count < RenderLimits.MaxLocalShadowEntries); f++)
					{
						var dead = GpuLocalShadow();
						// The shader's own guard reads this as unshadowed.
						dead.AtlasScaleBias = .(0, 0, 0, 0);
						mLocalShadows.Add(dead);
					}
					continue;
				}

				let destination = caster.IsStatic ? mStaticAtlasDraws : mRealtimeAtlasDraws;
				for (uint32 f = 0; f < need; f++)
				{
					let tileIndex = tileCounter + f;
					var entry = (need == 6)
						? ShadowMath.BuildPointShadowFace(caster, f, tileIndex, atlasResolution,
							tileResolution)
						: ShadowMath.BuildSpotShadow(caster, tileIndex, atlasResolution,
							tileResolution);
					entry.AtlasSelect = caster.IsStatic ? 1.0f : 0.0f;

					let rect = ShadowMath.AtlasTileRect(tileIndex, atlasResolution, tileResolution);

					var tile = LocalShadowTile();
					tile.ViewProjection = entry.ViewProjection;
					tile.X = rect.X;
					tile.Y = rect.Y;
					tile.Width = rect.Width;
					tile.Height = rect.Height;
					// A point and a spot share their position and reach, so one sphere culls
					// the casters for either.
					tile.CullCenter = caster.PositionWS;
					tile.CullRadius = Max(0.1f, caster.Range);

					destination.Add(.(tile, context));
					mLocalShadows.Add(entry);
				}

				tileCounter += need;
				if (caster.IsStatic)
					staticTile = tileCounter;
				else
					realtimeTile = tileCounter;
			}

			// The static layer, per scene: each tile is cached and re-rendered only when it has
			// to be, tracked by a COUNTDOWN so a dirtied tile refreshes every frame in flight's
			// copy. It is dirtied by the scene's static set changing, by the scene landing on a
			// different slot or tile range, which shifts the layout under it, or by an animated
			// caster overlapping it.
			context.StaticTiles.Clear();
			for (let draw in mStaticAtlasDraws)
			{
				if (draw.Context == context)
					context.StaticTiles.Add(draw.Tile);
			}

			while (context.StaticTileDirty.Count < context.StaticTiles.Count)
				context.StaticTileDirty.Add(0);

			let signature = StaticCasterSignature(context.Scene);
			if ((signature != context.StaticSignature) || (context.Scene != context.LastStaticScene)
				|| (sceneStaticTileBase != context.StaticTileBase))
			{
				context.StaticSignature = signature;
				context.LastStaticScene = context.Scene;
				context.StaticTileBase = sceneStaticTileBase;
				for (int t < context.StaticTileDirty.Count)
					context.StaticTileDirty[t] = framesInFlight;
			}

			for (int t < context.StaticTiles.Count)
			{
				for (let sphere in context.AnimatedSpheres)
				{
					if (Length(sphere.Center - context.StaticTiles[t].CullCenter)
						<= (context.StaticTiles[t].CullRadius + sphere.Radius))
					{
						context.StaticTileDirty[t] = framesInFlight;
						break;
					}
				}
			}

			context.StaticRenderTiles.Clear();
			for (int t < context.StaticTiles.Count)
			{
				if (context.StaticTileDirty[t] > 0)
				{
					context.StaticRenderTiles.Add(context.StaticTiles[t]);
					context.StaticTileDirty[t]--;
				}
			}

			staticTileCount += (uint32)context.StaticTiles.Count;
		}

		return staticTileCount;
	}

	/// Composes every collected view into the frame's encoder.
	public void End()
	{
		if (mEncoder == null)
			return;

		ProfileScopeBegin("Compose.Head");
		uint32 totalDraws = 0;
		for (int i < mViews.ActiveCount)
			totalDraws += (uint32)mViews.At(i).DrawList.Length;

		// ---- The per scene shadow composition ----
		//
		// Views can show DIFFERENT scenes in one frame. Every shadow input comes from the
		// VIEW'S OWN scene through these contexts; sourcing them from one primary scene bleeds
		// one scene's shadows into another and never renders the other's at all.
		let viewCount = (uint32)mViews.ActiveCount;
		let sceneCount = BuildSceneContexts();

		var anyDirectional = false;
		var anyLocalCasters = false;
		for (int k < sceneCount)
		{
			let context = mSceneShadowPool[k];
			anyDirectional = anyDirectional || context.Scene.DirectionalShadowData.Valid;
			anyLocalCasters = anyLocalCasters || !context.Scene.LocalShadowCasters.IsEmpty;
		}

		// ONE array shared by every view, sized for their cascades. Each view fits and renders
		// its OWN cascades into its own layer range, and samples them.
		let hasShadow = (mShadows != null) && anyDirectional;
		let shadowMap = hasShadow ? mShadows.PrepareFrame(mFrameIndex, viewCount) : null;
		let shadowGeneration = (mShadows != null) ? mShadows.Generation : 0;

		for (int k < sceneCount)
		{
			let context = mSceneShadowPool[k];
			if (context.Scene.DirectionalShadowData.Valid
				|| !context.Scene.LocalShadowCasters.IsEmpty)
				BuildShadowCasterList(context.Scene, context);
		}

		mLocalShadows.Clear();
		mRealtimeAtlasDraws.Clear();
		mStaticAtlasDraws.Clear();

		ITextureView atlasView = null;
		uint32 staticTileCount = 0;
		if ((mShadows != null) && anyLocalCasters)
			atlasView = mShadows.PrepareAtlas(mFrameIndex);
		if (atlasView != null)
			staticTileCount = BuildLocalShadowTiles(sceneCount);

		let atlasGeneration = (mShadows != null) ? mShadows.Generation : 0;

		mStaticRenderDraws.Clear();
		for (int k < sceneCount)
		{
			let context = mSceneShadowPool[k];
			for (let tile in context.StaticRenderTiles)
				mStaticRenderDraws.Add(.(tile, context));
		}
		let renderStatic = !mStaticRenderDraws.IsEmpty;

		// Only the atlas passes that actually re-emit casters this frame count toward the
		// renderers' ring sizing.
		let localPassCount = (uint32)(mRealtimeAtlasDraws.Count + mStaticRenderDraws.Count);

		ProfileScopeEnd();
		ProfileScopeBegin("Compose.Prepare");
		PrepareRenderers(totalDraws, sceneCount, shadowMap, shadowGeneration, atlasView,
			atlasGeneration, localPassCount);

		ProfileScopeEnd();
		ProfileScopeBegin("Compose.Declare");
		DeclareFrame(sceneCount, hasShadow, shadowMap, atlasView, staticTileCount, renderStatic);

		// Unmap the decal ring before the graph executes.
		if (mDecalPass != null)
			mDecalPass.EndFrame();

		ProfileScopeEnd();
		ProfileScopeBegin("Compose.Execute");
		mGraph.Execute(mEncoder).IgnoreError();
		ProfileScopeEnd();
		// Age out the transient pool. Executing only RETURNS transients to it; this is what
		// destroys the entries nothing has used for a while. Without it the pool keeps every
		// size ever seen, which is invisible while one size recurs and an unbounded leak once
		// a viewport starts resizing.
		ProfileScopeBegin("Compose.GraphEndFrame");
		mGraph.EndFrame();
		ProfileScopeEnd();

		ProfileScopeBegin("Compose.FinishFrame");
		for (let renderer in mRegistry.Unique)
			renderer.FinishFrame();
		ProfileScopeEnd();

		// This frame's matrices become next frame's previous ones.
		mPrevViewProj.Clear();
		for (let value in mCurViewProj)
			mPrevViewProj.Add(value);
		mPrevJitter.Clear();
		for (let value in mCurJitter)
			mPrevJitter.Add(value);

		// The jitter's phase advances once per frame, if any view used it.
		if (mAnyViewTaa)
			mJitterIndex = (mJitterIndex + 1) % 8;
		mAnyViewTaa = false;

		mEncoder = null;
	}

	/// Hands the renderers this frame's shared state and sizes their transients ONCE.
	private void PrepareRenderers(uint32 totalDraws, int sceneCount, ITextureView shadowMap,
		uint64 shadowGeneration, ITextureView atlasView, uint64 atlasGeneration,
		uint32 localPassCount)
	{
		for (let renderer in mRegistry.Unique)
			renderer.SetShadowMap(shadowMap, shadowGeneration);
		for (let renderer in mRegistry.Unique)
			renderer.SetShadowAtlas(atlasView, atlasGeneration, localPassCount);

		// A probe capture re-emits the draws once per face, and those passes count into the per
		// object rings or they starve the forward and its draws silently disappear.
		let captureFaces = ((mProbeSystem != null) && !mProbeSystem.Captures.IsEmpty) ? (uint32)6 : 0;
		for (let renderer in mRegistry.Unique)
			renderer.SetCaptureFacePasses(captureFaces);

		if ((mProbeSystem != null) && (mProbeSystem.ActiveCount > 0))
		{
			mProbeSystem.Upload();
			for (let renderer in mRegistry.Unique)
				renderer.SetProbes(mProbeSystem.PrefilterArrayView, mProbeSystem.ProbeBuffer,
					mProbeSystem.ActiveCount);
		}
		else
		{
			for (let renderer in mRegistry.Unique)
				renderer.SetProbes(null, null, 0);
		}

		// Any pending programmatic environment source, before the graph executes.
		if ((mIbl != null) && mIbl.Ready)
			mIbl.Upload(mEncoder);

		for (let renderer in mRegistry.Unique)
			renderer.PrepareFrame(totalDraws, mFrameIndex);
		for (let renderer in mRegistry.Unique)
			renderer.UploadLocalShadows(mLocalShadows, mFrameIndex);

		// The skinning: each distinct skeleton's matrices written ONCE into the pool and copied
		// to the device, before any pass reads them. Per DISTINCT scene, a scene's instances
		// covering every view of it.
		for (int k < sceneCount)
		{
			for (let renderer in mRegistry.Unique)
				renderer.UploadSkinning(mSceneShadowPool[k].Scene, mEncoder);
		}

		if (mClusters != null)
			mClusters.PrepareFrame(mFrameIndex);

		// The per worker pools are reset once, before any view.
		mPass.BeginFrame(mFrameIndex);
	}

	/// Declares every pass of the frame into the one graph.
	private void DeclareFrame(int sceneCount, bool hasShadow, ITextureView shadowMap,
		ITextureView atlasView, uint32 staticTileCount, bool renderStatic)
	{
		if (mViews.ActiveCount > 0)
			mGraph.SetOutputSize(mViews.At(0).Width, mViews.At(0).Height);

		let cascadeCount = (mShadows != null) ? mShadows.CascadeCount : 4;
		let shadowResolution = (mShadows != null) ? mShadows.Resolution : 1024;

		// The environment precompute, PER SCENE: each scene's authored sky builds into ITS
		// context's persistent products when dirty, and each view samples its own set. The
		// procedural sky follows that scene's key light, so its disc and its ambient agree.
		if ((mIbl != null) && mIbl.Ready)
		{
			mIbl.BeginFrame(mGraph);
			for (int k < sceneCount)
			{
				let context = mSceneShadowPool[k];
				let directional = context.Scene.DirectionalShadowData;
				let sun = directional.Valid ? directional.Direction : Float3(0.0f, -1.0f, 0.0f);
				context.Ibl = mIbl.Prepare(context.Scene, context.Scene.Sky, sun, mGraph);
			}
		}

		// The local light atlas is a two layer array. The realtime layer re-renders every
		// frame; the static one only when something dirtied it. Each pass targets its own
		// layer, clears it, and renders its tiles at their own viewports. Every forward pass
		// reads the array, which orders both ahead of it and barriers it readable.
		var atlasHandle = RGHandle.Invalid;
		let atlasActive = (atlasView != null)
			&& (!mRealtimeAtlasDraws.IsEmpty || (staticTileCount > 0));

		if (atlasActive)
		{
			atlasHandle = mShadows.ImportAtlas(mGraph, mFrameIndex);
			DeclareAtlasLayer(atlasHandle, 0, mRealtimeAtlasDraws);
			if (renderStatic)
				DeclareAtlasLayer(atlasHandle, 1, mStaticRenderDraws);
		}

		var shadowHandle = RGHandle.Invalid;
		let shadowActive = hasShadow && (shadowMap != null);
		if (shadowActive)
			shadowHandle = mShadows.ImportTarget(mGraph, mFrameIndex);

		// EVERY view's cascade passes are declared up front, before any forward pass. The
		// array is one imported resource: a forward pass sampling the whole of it declared
		// before a later view's cascade writes would find those layers still in the attachment
		// state rather than readable. Fitting them all first means every layer is written and
		// barriered before the first sample.
		mViewShadows.Clear();
		mViewShadowDebug.Clear();
		for (int i < mViews.ActiveCount)
		{
			mViewShadows.Add(.());
			mViewShadowDebug.Add(.());
		}

		for (int i < mViews.ActiveCount)
		{
			// Every view, shadowed or not, carries its scene's entry base: its lights' scene
			// relative indices offset into the frame's concatenated buffer.
			let context = (mViewSceneIndex[i] >= 0) ? mSceneShadowPool[mViewSceneIndex[i]] : null;
			mViewShadows[i].LocalShadowEntryBase = (context != null) ? context.EntryBase : 0;
			mViewShadowDebug[i].LocalEntryBase = mViewShadows[i].LocalShadowEntryBase;

			if (!shadowActive)
				continue;

			// The map exists this frame, so EVERY view binds and declares it, the views whose
			// scenes cast nothing and the views past the cascade budget included.
			mViewShadows[i].SampleView = shadowMap;
			mViewShadows[i].Handle = shadowHandle;
			mViewShadowDebug[i].MapBound = true;

			if (i >= (int)ShadowSystem.MaxShadowViews)
				continue;

			// THIS view's scene must have a caster of its own: another scene's key light must
			// never shadow, or leak light into, this one.
			if ((context == null) || !context.Scene.DirectionalShadowData.Valid)
				continue;

			let view = mViews.At(i);
			let lightDirection = context.Scene.DirectionalShadowData.Direction;
			let distance = Min(view.Camera.FarZ, mShadowDistance);
			let cascades = ShadowMath.ComputeCascades(view.Camera, lightDirection, distance,
				shadowResolution);
			let layerBase = (uint32)i * cascadeCount;

			for (uint32 c = 0; c < cascadeCount; c++)
			{
				let cascadeViewProj = cascades.ViewProjection[c];
				let layer = layerBase + c;

				// The casters come from the view's SCENE's camera independent list, not this
				// view's culled draw list, so view frustum culling cannot drop an off camera
				// caster whose shadow is visible. The per cascade cull then keeps each caster
				// to about one cascade.
				mGraph.AddRenderPass("shadow.cascade", scope (builder) =>
					{
						builder.SetDepthTarget(shadowHandle, .Clear, .Store, 1.0f,
							.(0, 0, layer, 1));
						builder.SetViewport(0, 0, shadowResolution, shadowResolution);

						builder.SetExecute(new (encoder) =>
							{
								// A cascade follows its OWNING view's level selection, so the
								// shadow matches what that view draws.
								RecordShadowCasters(encoder, context.Casters, mRegistry,
									cascadeViewProj, .(0, 0, 0), 0.0f, true, context.CasterBounds,
									view);
							});
					});
			}

			mViewShadows[i].Cascades = cascades;
			mViewShadows[i].LayerBase = layerBase;
			mViewShadows[i].Valid = true;
			mViewShadowDebug[i].Directional = true;
		}

		// The probe arrays: the captured one's layout is initialised once, so the slices no
		// probe has claimed are readable rather than undefined under the whole array binding,
		// and both are imported ONCE so the capture passes and the forward share one resource,
		// which is what orders the capture ahead of the shading.
		var probeCaptured = RGHandle.Invalid;
		var probePrefiltered = RGHandle.Invalid;
		var probeActive = false;
		if ((mProbeSystem != null) && (mProbeSystem.ActiveCount > 0))
		{
			mProbeSystem.InitLayouts(mEncoder);
			probeCaptured = mProbeSystem.ImportCaptured(mGraph);
			probePrefiltered = mProbeSystem.ImportPrefiltered(mGraph);
			probeActive = true;
		}

		if (probeActive)
			DeclareProbeCapture(sceneCount, probeCaptured, probePrefiltered, atlasHandle,
				atlasActive);

		// The frame global resources end here; the debug lookup searches a view's own range
		// first, names repeating per view, and falls back to this prefix.
		let frameGlobalResourceEnd = mGraph.Resources.Length;

		mImported.Clear();
		// The decal ring brackets the WHOLE view loop once, each view accumulating its own
		// slots within it.
		if (mDecalPass != null)
			mDecalPass.BeginFrame(mFrameIndex);

		for (int i < mViews.ActiveCount)
			DeclareView(i, atlasHandle, atlasActive, probePrefiltered, probeActive,
				frameGlobalResourceEnd);

		// The view independent screen overlay: drawn ONCE per distinct target at its full
		// extent rather than per viewport, so a whole window overlay is not duplicated across a
		// split screen. Declared after every view's passes, so it composites on top.
		if ((mDebugPass != null) && (mDebugScreen != null))
		{
			var overlayIndex = (uint32)mViews.ActiveCount;
			for (let import in mImported)
			{
				mDebugPass.DeclareScreen(mGraph, import.Handle, Float4x4.Identity(), mDebugScreen,
					null, null, import.Format, 0, 0, import.Width, import.Height, mFrameIndex,
					overlayIndex);
				overlayIndex++;
			}
		}
	}

	/// One atlas layer's depth pass over a list of tiles, which can span several scenes: each
	/// draw records ITS OWN scene's casters.
	private void DeclareAtlasLayer(RGHandle atlasHandle, uint32 layer, List<AtlasDraw> draws)
	{
		if (draws.IsEmpty)
			return;

		let atlasResolution = mShadows.AtlasResolution;

		mGraph.AddRenderPass("shadow.atlas", scope (builder) =>
			{
				builder.SetDepthTarget(atlasHandle, .Clear, .Store, 1.0f, .(0, 0, layer, 1));
				// The pass's default; each tile sets its own below.
				builder.SetViewport(0, 0, atlasResolution, atlasResolution);

				builder.SetExecute(new (encoder) =>
					{
						for (let draw in draws)
						{
							let tile = draw.Tile;
							encoder.SetViewport(tile.X, tile.Y, tile.Width, tile.Height);
							encoder.SetScissor((int32)tile.X, (int32)tile.Y, tile.Width,
								tile.Height);
							RecordShadowCasters(encoder, draw.Context.Casters, mRegistry,
								tile.ViewProjection, tile.CullCenter, tile.CullRadius);
						}
					});
			});
	}

	/// Renders one dirty probe's six faces into its slices, BEFORE the main views, which then
	/// sample the result.
	///
	/// Feedback safe: the capture's own shading samples its scene's environment only, never the
	/// probe array it is writing.
	private void DeclareProbeCapture(int sceneCount, RGHandle captured, RGHandle prefiltered,
		RGHandle atlasHandle, bool atlasActive)
	{
		if ((mIbl == null) || !mIbl.Ready || (mSky == null))
			return;
		let captures = mProbeSystem.Captures;
		if (captures.IsEmpty)
			return;

		let resolution = ReflectionProbeSystem.cCaptureResolution;
		let nearZ = ReflectionProbeSystem.cCaptureNear;
		let farZ = ReflectionProbeSystem.cCaptureFar;

		// Round robin: ONE dirty probe per frame, cycling. That keeps a capture to six faces a
		// frame and spreads a multi probe scene's work out.
		let task = captures[(int)(mProbeCaptureCursor % (uint32)captures.Length)];
		mProbeCaptureCursor++;

		// The capture renders the probe's OWNING scene, a probe in one scene never baking
		// another's geometry, and lights it with ITS scene's environment.
		let captureScene = task.Scene;
		IblContext captureIbl = null;
		for (int k < sceneCount)
		{
			if (mSceneShadowPool[k].Scene == captureScene)
			{
				captureIbl = mSceneShadowPool[k].Ibl;
				break;
			}
		}

		if ((captureScene == null) || (captureIbl == null))
			return;

		var ibl = IblBinding();
		ibl.PrefilterHandle = captureIbl.PrefilterHandle;
		ibl.BrdfHandle = mIbl.BrdfHandle;
		ibl.ShHandle = captureIbl.ShHandle;
		ibl.ShBuffer = captureIbl.ShBuffer;
		ibl.PrefilterView = captureIbl.PrefilterView;
		ibl.BrdfView = mIbl.BrdfView;
		ibl.MaxLod = mIbl.MaxLod;
		ibl.Generation = captureIbl.Generation;
		ibl.Valid = true;

		// The primary view's cascade binding is reused, along with the local atlas. The capture
		// shading samples both depth textures statically, so the binding MUST be valid or the
		// graph never barriers them readable and they stay in their attachment state. The
		// cascades are geometrically the main camera's, which is an approximation for a face.
		var shadow = mViewShadows.IsEmpty ? ShadowBinding() : mViewShadows[0];
		shadow.AtlasHandle = atlasHandle;
		shadow.AtlasValid = atlasActive;

		let layerBase = ReflectionProbeSystem.LayerBase(task.Slot);
		let sunIntensity = captureIbl.HasSunDisc ? captureIbl.Sky.SunIntensity : 0.0f;

		for (uint32 face = 0; face < 6; face++)
		{
			let camera = ProbeCapture.FaceCamera(task.Center, face, nearZ, farZ);
			let view = mCaptureViews[face];
			view.Bind(captureScene, camera, .(), null, ReflectionProbeSystem.cCubeFormat,
				resolution, resolution);
			view.BuildDrawList(mSortScratch);

			let depth = mGraph.CreateTransient("probe.depth",
				.(mPass.DepthFormat, resolution, resolution));
			let normal = mGraph.CreateTransient("probe.normal",
				.(RenderFormats.GNormal, resolution, resolution));
			let velocity = mGraph.CreateTransient("probe.velocity",
				.(RenderFormats.GVelocity, resolution, resolution));
			let material = mGraph.CreateTransient("probe.material",
				.(RenderFormats.GMaterial, resolution, resolution));

			let subresource = RGSubresourceRange(0, 0, layerBase + face, 1);
			let faceViewProj = camera.ViewProjection;

			// Lit forward, with no cluster binding, so the shading falls back to looping every
			// light rather than building a grid per face; the depth clears, there being no
			// prepass; and only the first colour slot writes, into this cube face.
			mPass.DeclarePass(view, mRegistry, mGraph, mFrameIndex,
				ProbeCapture.cViewIndexBase + face, captured, depth, true,
				ReflectionProbeSystem.cCubeFormat, normal, velocity, material, faceViewProj,
				.(0, 0), .(0, 0), .(), shadow, ibl, .Clear, subresource);

			// The sky into the same face, after the forward, loading the captured depth. Its
			// own slot is distinct per face, so a capture never shares a slot with a main view
			// or another face: the last recorder would otherwise win the slot and the captured
			// sky would read another view's camera.
			mSky.DeclareSky(mGraph, captured, velocity, depth, captureIbl.EnvHandle,
				captureIbl.EnvView, ReflectionProbeSystem.cCubeFormat, mPass.DepthFormat,
				Inverse(faceViewProj), faceViewProj, .(0, 0), .(0, 0), task.Center,
				captureIbl.Sky.BackgroundIntensity, captureIbl.SunDir,
				captureIbl.Sky.SunAngularSize, .(1.0f, 0.98f, 0.92f), sunIntensity, 0, 0,
				resolution, resolution, mFrameIndex, 10 + face, captureIbl.Uid, 1, subresource);
		}

		// Bridge the captured faces into the prefiltered array's first level, correcting the
		// mirror, so the shading samples a SEPARATE texture and never the cube just written;
		// then convolve that level into the rougher ones.
		mProbeSystem.DeclareBlit(mGraph, captured, prefiltered, task.Slot);
		mProbeSystem.DeclarePrefilter(mGraph, prefiltered, task.Slot);
		mProbeSystem.MarkCaptured(task.Slot);
	}

	/// Declares one view's whole chain: the prepass, the forward, the sky, the post stack, the
	/// overlays and the debug work.
	private void DeclareView(int index, RGHandle atlasHandle, bool atlasActive,
		RGHandle probePrefiltered, bool probeActive, int frameGlobalResourceEnd)
	{
		let view = mViews.At(index);
		let target = view.Target;
		if (target == null)
			return;

		let viewResourceBase = mGraph.Resources.Length;
		let viewIndex = (uint32)index;

		// Each distinct target is imported ONCE, so the graph orders and barriers every view
		// writing it as one resource. The first view to a target clears it; a later one loads,
		// preserving the earlier views' regions.
		var colorHandle = RGHandle.Invalid;
		var found = false;
		for (let import in mImported)
		{
			if (import.Target == target)
			{
				colorHandle = import.Handle;
				found = true;
				break;
			}
		}

		if (!found)
		{
			// A backbuffer, whose texture is null, is left alone: the host brought it into the
			// render state and will present it, so the graph touches no barrier. An offscreen
			// target the graph barriers from its current state through the render state to
			// whatever final one the caller then samples or copies from.
			let settings = view.Settings;
			colorHandle = mGraph.ImportTarget("forward.color", settings.TargetTexture, target,
				settings.TargetFinalState, settings.TargetCurrentState);
			mImported.Add(.()
				{
					Target = target, Handle = colorHandle, Width = view.Width,
					Height = view.Height, Format = view.TargetFormat
				});
		}
		let clearColor = !found;

		// The cluster build is declared before the forward, so the graph orders the binning
		// write ahead of the shading's read. The view index isolates the per view buffers.
		var cluster = ClusterBinding();
		if (mClusters != null)
			cluster = mClusters.DeclareBuild(mGraph, view, mFrameIndex, viewIndex);

		var shadow = mViewShadows[index];
		// The atlas is frame global, one pass for every view, so every view depends on it.
		shadow.AtlasHandle = atlasHandle;
		shadow.AtlasValid = atlasActive;

		let sceneContext = (mViewSceneIndex[index] >= 0)
			? mSceneShadowPool[mViewSceneIndex[index]]
			: null;

		// This view's scene's probe range, the records being the scenes' ranges concatenated.
		var probeRange = ProbeRange();
		if ((mProbeSystem != null) && probeActive)
			probeRange = mProbeSystem.RangeFor(view.Scene);

		// This view's SCENE's environment products for the shading to sample and the graph to
		// order; the lookup table is the shared piece.
		var ibl = IblBinding();
		let viewIbl = (sceneContext != null) ? sceneContext.Ibl : null;
		if (viewIbl != null)
		{
			ibl.PrefilterHandle = viewIbl.PrefilterHandle;
			ibl.BrdfHandle = mIbl.BrdfHandle;
			ibl.ShHandle = viewIbl.ShHandle;
			ibl.ShBuffer = viewIbl.ShBuffer;
			ibl.PrefilterView = viewIbl.PrefilterView;
			ibl.BrdfView = mIbl.BrdfView;
			ibl.MaxLod = mIbl.MaxLod;
			ibl.Generation = viewIbl.Generation;
			ibl.Valid = true;
		}

		// Multisampling engages only on the HIGH DYNAMIC RANGE path, where it resolves into a
		// single sampled image the post stack consumes. Without the tone map the forward writes
		// the final target directly, where a multisampled depth would not match, so it stays
		// single sampled.
		let msaaSamples = ((mMsaaResolve != null) && (mTonemap != null)
			&& (view.Settings.Post.MsaaSamples > 1))
			? view.Settings.Post.MsaaSamples
			: (uint8)1;

		RGTextureDesc MsaaDesc(TextureFormat format, uint32 width, uint32 height)
		{
			var desc = RGTextureDesc(format, width, height);
			desc.SampleCount = msaaSamples;
			return desc;
		}

		// The per view depth, shared by the forward and the sky, which depth tests against it.
		let depth = mGraph.CreateTransient("forward.depth",
			MsaaDesc(mPass.DepthFormat, view.Width, view.Height));
		let normalTarget = mGraph.CreateTransient("forward.normal",
			MsaaDesc(RenderFormats.GNormal, view.Width, view.Height));
		let velocityTarget = mGraph.CreateTransient("forward.velocity",
			MsaaDesc(RenderFormats.GVelocity, view.Width, view.Height));
		let materialTarget = mGraph.CreateTransient("forward.material",
			MsaaDesc(RenderFormats.GMaterial, view.Width, view.Height));

		// The depth a SINGLE SAMPLED overlay tests against after the post stack: the scene's own
		// when multisampling is off, but the resolved one when it is on, a single sampled
		// overlay having no way to test a multisampled attachment.
		var overlayDepth = depth;

		let post = view.Settings.Post;

		// The jitter offsets the projection so the temporal resolve accumulates subsamples. It
		// is applied BEFORE the matrix is read, so the prepass, the forward and the sky all use
		// the SAME jittered one: a mismatch would break the early rejection.
		let unjitteredViewProj = view.Camera.ViewProjection;
		var jitter = Float2(0.0f, 0.0f);
		if (post.TaaEnabled && (mTaa != null))
		{
			jitter = TaaJitter.HaltonJitter(mJitterIndex, view.Width, view.Height);
			view.ApplyProjectionJitter(jitter.X, jitter.Y);
			mAnyViewTaa = true;
		}

		// This view's previous matrix and jitter, for the motion vectors; nothing moves on
		// first sight. This frame's are recorded for the next.
		let currentViewProj = view.Camera.ViewProjection;
		let prevViewProj = (index < mPrevViewProj.Count) ? mPrevViewProj[index] : currentViewProj;
		while (mCurViewProj.Count <= index)
			mCurViewProj.Add(currentViewProj);
		mCurViewProj[index] = currentViewProj;

		let prevJitter = (index < mPrevJitter.Count) ? mPrevJitter[index] : Float2(0.0f, 0.0f);
		while (mCurJitter.Count <= index)
			mCurJitter.Add(jitter);
		mCurJitter[index] = jitter;

		// The depth prepass: opaque only, clearing and writing the camera depth so the forward
		// shades each opaque pixel once. Declared before the forward, which loads it.
		mGraph.AddRenderPass("depth.prepass", scope (builder) =>
			{
				builder.SetDepthTarget(depth, .Clear, .Store);
				builder.SetViewport(view.ViewportX, view.ViewportY, view.ViewportWidth,
					view.ViewportHeight);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						RecordDepthPrepass(encoder, view, mRegistry, viewIndex);
					});
			});

		// The visible sky, declared into a colour target after the forward.
		void DeclareSky(RGHandle colorTarget, RGHandle velocityTarget, TextureFormat colorFormat)
		{
			if ((mSky == null) || (viewIbl == null))
				return;

			// The ray is reconstructed from the UNJITTERED matrix. The background is at
			// infinity, so jittering its sampling buys no antialiasing worth having and makes
			// it oscillate below a pixel each frame, which the temporal resolve can only partly
			// cancel. Unjittered leaves a still camera's sky still; the pass still writes a
			// geometric motion vector, so a rotation reprojects.
			let invViewProj = Inverse(unjitteredViewProj);
			// The crisp disc is for the untextured skies; a textured environment carries its own.
			let sunIntensity = viewIbl.HasSunDisc ? viewIbl.Sky.SunIntensity : 0.0f;

			mSky.DeclareSky(mGraph, colorTarget, velocityTarget, depth, viewIbl.EnvHandle,
				viewIbl.EnvView, colorFormat, mPass.DepthFormat, invViewProj, prevViewProj, jitter,
				prevJitter, view.Camera.Position, viewIbl.Sky.BackgroundIntensity, viewIbl.SunDir,
				viewIbl.Sky.SunAngularSize, .(1.0f, 0.98f, 0.92f), sunIntensity, view.ViewportX,
				view.ViewportY, view.ViewportWidth, view.ViewportHeight, mFrameIndex, viewIndex,
				viewIbl.Uid, msaaSamples);
		}

		// A semantic debug view blits the scene RAW, the tone map having no business grading an
		// encoded term. Set on the tone mapped path; invalid means there is no blit to do.
		var debugSemanticSource = RGHandle.Invalid;

		if (mTonemap != null)
		{
			// The forward renders linear high range into a transient, and the tone map resolves
			// it into the final image.
			let hdr = mGraph.CreateTransient("forward.hdr",
				MsaaDesc(mTonemap.HdrFormat, view.Width, view.Height));

			mPass.DeclarePass(view, mRegistry, mGraph, mFrameIndex, viewIndex, hdr, depth, true,
				mTonemap.HdrFormat, normalTarget, velocityTarget, materialTarget, prevViewProj,
				jitter, prevJitter, cluster, shadow, ibl, .Load, .(), probePrefiltered,
				probeActive, probeRange.Base, probeRange.Count);

			DeclareSky(hdr, velocityTarget, mTonemap.HdrFormat);

			// The resolve: the opaque work and the sky wrote the multisampled targets, so the
			// colour resolves through the hardware and the depth and auxiliaries through a
			// first sample pass, and the WHOLE post stack then runs single sampled exactly as
			// it does without multisampling. With one sample the handles alias the originals
			// and no resolve pass is emitted at all.
			var postHdr = hdr;
			var postDepth = depth;
			var postNormal = normalTarget;
			var postVelocity = velocityTarget;
			var postMaterial = materialTarget;
			debugSemanticSource = hdr;

			if (msaaSamples > 1)
			{
				postHdr = mGraph.CreateTransient("forward.hdr.resolved",
					.(mTonemap.HdrFormat, view.Width, view.Height));
				let msaaHdr = hdr;
				let resolvedHdr = postHdr;

				// An EMPTY pass: the multisampled colour loads and resolves at the pass's end
				// through the fixed function resolve attachment. No draws, and never a blit.
				mGraph.AddRenderPass("msaa.colorResolve", scope (builder) =>
					{
						builder.SetColorTarget(0, msaaHdr, .Load, .Store);
						builder.SetResolveTarget(0, resolvedHdr);
						builder.NeverCull();
						builder.SetExecute(new (encoder) => {});
					});

				let resolved = mMsaaResolve.DeclareResolve(mGraph, depth, normalTarget,
					velocityTarget, materialTarget, mPass.DepthFormat, view.Width, view.Height);
				postDepth = resolved.Depth;
				postNormal = resolved.Normal;
				postVelocity = resolved.Velocity;
				postMaterial = resolved.Material;
				overlayDepth = postDepth;
				debugSemanticSource = postHdr;
			}

			// The decals reconstruct the world position from the depth and blend into the lit
			// image. AFTER the resolve, so they sample the SINGLE SAMPLED depth rather than the
			// multisampled attachment, which some backends forbid sampling at all, and the
			// first sample's depth is the resolved depth anyway. Still BEFORE the reflections
			// and the temporal resolve, so decals feed the one and are steadied by the other.
			if ((mDecalPass != null) && (view.Scene != null))
			{
				mDecalPass.DeclareDecals(mGraph, postHdr, postDepth, view.Scene.Decals,
					currentViewProj, view.Width, view.Height, view.ViewportX, view.ViewportY,
					view.ViewportWidth, view.ViewportHeight, 1);
			}

			// The bounce, BEFORE the reflections, so a reflection sees it. Additive, and it
			// produces a fresh image the rest of the chain consumes.
			var sceneHdr = postHdr;
			if ((mSsgi != null) && post.SsgiEnabled)
			{
				var parameters = SsgiParams();
				parameters.Intensity = post.SsgiIntensity;
				sceneHdr = mSsgi.DeclareSsgi(mGraph, sceneHdr, postDepth, postNormal, postVelocity,
					view.Width, view.Height, view.ViewportX, view.ViewportY, view.ViewportWidth,
					view.ViewportHeight, Inverse(view.Camera.Projection), view.Camera.Projection,
					parameters, viewIndex, mNoiseFrame);
			}

			// The reflections, after the decals and before the occlusion and the temporal
			// resolve, so the march is steadied by the latter. They read the roughness to gate
			// and fade, and lerp over the environment's specular where they hit.
			if ((mSsr != null) && post.SsrEnabled)
			{
				var parameters = mSsrParams;
				parameters.Intensity = post.SsrIntensity;
				sceneHdr = mSsr.DeclareSsr(mGraph, sceneHdr, postDepth, postNormal, postMaterial,
					postVelocity, view.Width, view.Height, view.ViewportX, view.ViewportY,
					view.ViewportWidth, view.ViewportHeight, Inverse(view.Camera.Projection),
					view.Camera.Projection, parameters, viewIndex, mFrameIndex);
			}

			// The occlusion, computed from the opaque depth and normal BEFORE the temporal
			// resolve and multiplied in there, so the resolve steadies it. Applying it after
			// would wobble: it is computed from the jittered buffers and shifts each frame.
			let viewAoMode = (AoMode)post.AoMode;
			let aoActive = (viewAoMode != .Off) || (mAoDebug != 0);
			// The debug view needs something to generate.
			let aoMode = (viewAoMode != .Off) ? viewAoMode : AoMode.GTAO;

			var aoHandle = RGHandle.Invalid;
			if ((mAo != null) && aoActive)
			{
				aoHandle = mAo.DeclareAo(mGraph, postDepth, postNormal, view.Width, view.Height,
					Inverse(view.Camera.Projection), view.Camera.Projection, post.AoRadius,
					post.AoIntensity, mFrameIndex, aoMode, mAoDebug);
			}

			let showAo = aoHandle.IsValid && (mAoDebug != 0);
			var litHdr = sceneHdr;
			if (aoHandle.IsValid && (viewAoMode != .Off) && (mAoDebug == 0))
				litHdr = mAo.DeclareApply(mGraph, sceneHdr, aoHandle, view.Width, view.Height,
					post.AoStrength);

			// The temporal resolve on the opaque, sky and occlusion image. The blended work then
			// composites on the RESOLVED one, so it is never accumulated, and so never ghosts,
			// nor jittered, and so never wobbles.
			var sceneColor = litHdr;
			if (post.TaaEnabled && (mTaa != null))
			{
				let farZ = (view.Camera.FarZ > 0.0f) ? view.Camera.FarZ : 1000.0f;
				sceneColor = mTaa.DeclareTaa(mGraph, litHdr, postVelocity, postDepth, viewIndex,
					view.Width, view.Height, post.TaaBlend, post.TaaGamma, mTaaMotionScale, 0.1f,
					farZ);
			}

			// The blended work AFTER the resolve, into the resolved image, with the UNJITTERED
			// projection: colour only, depth read only against the opaque depth, back to front.
			mPass.DeclareTransparent(view, mRegistry, mGraph, mFrameIndex, viewIndex, sceneColor,
				postDepth, mTonemap.HdrFormat, unjitteredViewProj, prevViewProj, jitter,
				prevJitter, cluster, shadow, ibl, probeRange.Base, probeRange.Count);

			var bloomHandle = RGHandle.Invalid;
			if ((mBloom != null) && post.BloomEnabled && (post.BloomIntensity > 0.0f))
				bloomHandle = mBloom.DeclareBloom(mGraph, sceneColor, view.Width, view.Height,
					post.BloomThreshold, post.BloomKnee);

			let bloomStrength = bloomHandle.IsValid ? post.BloomIntensity : 0.0f;
			// A valid binding even when it is off.
			let bloomTexture = bloomHandle.IsValid ? bloomHandle : sceneColor;
			// The occlusion is already applied, so the tone map only needs the handle for its
			// debug view.
			let aoTexture = aoHandle.IsValid ? aoHandle : sceneColor;

			// Map the tone map's fullscreen coordinates onto this view's sub rectangle of the
			// full size image, so a split screen view resolves its own region.
			let fullWidth = (float)view.Width;
			let fullHeight = (float)view.Height;
			let uvScale = Float2((float)view.ViewportWidth / fullWidth,
				(float)view.ViewportHeight / fullHeight);
			let uvOffset = Float2((float)view.ViewportX / fullWidth,
				(float)view.ViewportY / fullHeight);

			// The fallback antialiasing runs AFTER the tone map, into the final image, and is
			// NEVER stacked with the temporal one, which already resolves the aliasing.
			let fxaa = (mFxaa != null) && post.FxaaEnabled && !post.TaaEnabled;
			let tonemapOut = fxaa
				? mGraph.CreateTransient("post.ldr",
					.(view.TargetFormat, view.Width, view.Height))
				: colorHandle;

			// The eye adaptation measures and adapts the pre tone map image into this view's
			// single pixel, and the tone map then reads the adapted value along a graph edge.
			var autoExposure = TonemapAutoExposure();
			if (post.AutoExposure && (mExposurePass != null))
			{
				let adapted = mExposurePass.DeclareExposure(mGraph, sceneColor, viewIndex,
					mFrameIndex, uvScale, uvOffset, mDeltaSeconds, post.AutoExposureSpeed);
				autoExposure.Enabled = adapted.View != null;
				autoExposure.Handle = adapted.Handle;
				autoExposure.View = adapted.View;
				autoExposure.Generation = adapted.Generation;
				autoExposure.Key = post.AutoExposureKey;
				autoExposure.MinExposure = post.AutoExposureMin;
				autoExposure.MaxExposure = post.AutoExposureMax;
			}

			var grading = TonemapGrading();
			grading.View = post.GradingLut;
			grading.Uid = post.GradingLutUid;
			grading.LutSize = post.GradingLutSize;
			grading.Intensity = post.GradingIntensity;

			mTonemap.DeclareTonemap(mGraph, sceneColor, bloomTexture, aoTexture, tonemapOut,
				fxaa || clearColor, view.Settings.Clear, view.TargetFormat, view.ViewportX,
				view.ViewportY, view.ViewportWidth, view.ViewportHeight, mFrameIndex, viewIndex,
				post.Exposure, bloomStrength, uvScale, uvOffset, 0.0f, showAo, post.AgxTonemap,
				!post.TaaEnabled, autoExposure, grading);

			// The world space interface draws BETWEEN the tone map and the fallback
			// antialiasing: its authored colours survive, the antialiasing not grading, and its
			// silhouettes are smoothed. It renders single sampled, so it tests the RESOLVED
			// depth; the multisampled one would not match its target.
			mPass.DeclarePostTonemapUI(view, mRegistry, mGraph, mFrameIndex, viewIndex,
				fxaa ? tonemapOut : colorHandle, postDepth, view.TargetFormat, unjitteredViewProj,
				prevViewProj);

			if (fxaa)
			{
				let texel = Float2(1.0f / fullWidth, 1.0f / fullHeight);
				mFxaa.DeclareFxaa(mGraph, tonemapOut, colorHandle, clearColor,
					view.Settings.Clear, view.TargetFormat, view.ViewportX, view.ViewportY,
					view.ViewportWidth, view.ViewportHeight, mFrameIndex, viewIndex, texel,
					uvScale, uvOffset, post.FxaaSubpixel);
			}
		}
		else
		{
			// No tone map: the forward writes the final target directly.
			mPass.DeclarePass(view, mRegistry, mGraph, mFrameIndex, viewIndex, colorHandle, depth,
				clearColor, view.TargetFormat, normalTarget, velocityTarget, materialTarget,
				prevViewProj, jitter, prevJitter, cluster, shadow, ibl, .Load, .(),
				probePrefiltered, probeActive, probeRange.Base, probeRange.Count);

			DeclareSky(colorHandle, velocityTarget, view.TargetFormat);

			mPass.DeclareTransparent(view, mRegistry, mGraph, mFrameIndex, viewIndex, colorHandle,
				depth, view.TargetFormat, unjitteredViewProj, prevViewProj, jitter, prevJitter,
				cluster, shadow, ibl, probeRange.Base, probeRange.Count);

			mPass.DeclarePostTonemapUI(view, mRegistry, mGraph, mFrameIndex, viewIndex,
				colorHandle, depth, view.TargetFormat, unjitteredViewProj, prevViewProj);
		}

		DeclareDebugBlit(view, viewIndex, colorHandle, debugSemanticSource, viewResourceBase,
			frameGlobalResourceEnd);
		DeclareSceneOverlays(view, colorHandle, unjitteredViewProj);
		DeclareViewDebugDraw(view, viewIndex, colorHandle, overlayDepth, unjitteredViewProj);
	}

	/// The editor's debug view: overwrites this view's sub rectangle with the chosen resource.
	/// Declared BEFORE the overlays, so the gizmos and the text stay above the visualisation.
	private void DeclareDebugBlit(RenderView view, uint32 viewIndex, RGHandle colorHandle,
		RGHandle debugSemanticSource, int viewResourceBase, int frameGlobalResourceEnd)
	{
		if (mDebugBlit == null)
			return;

		let debug = view.Settings.Debug;
		if (debug == null)
			return;

		if (debug.Resource.IsEmpty && (debug.Semantic != .Off) && debugSemanticSource.IsValid)
		{
			// The shading already encoded the term into the colour, so it is shown untouched.
			let raw = scope ViewDebugView();
			mDebugBlit.DeclareDebugBlit(mGraph, debugSemanticSource, colorHandle,
				view.TargetFormat, view.ViewportX, view.ViewportY, view.ViewportWidth,
				view.ViewportHeight, mFrameIndex, viewIndex, (float)view.Width,
				(float)view.Height, false, raw);
			return;
		}

		if (debug.Resource.IsEmpty)
			return;

		// This view's OWN range first, the names repeating per view, then the frame global
		// prefix.
		var foundIndex = FindDebugResource(debug.Resource, viewResourceBase,
			mGraph.Resources.Length);
		if (foundIndex < 0)
			foundIndex = FindDebugResource(debug.Resource, 0, frameGlobalResourceEnd);
		if (foundIndex < 0)
			return;

		let resource = mGraph.Resources[foundIndex];
		// A multisampled source cannot be loaded through a plain binding; its resolved twin is
		// in the list instead.
		if (resource.TextureDesc.SampleCount > 1)
			return;

		let handle = RGHandle((uint32)foundIndex, resource.Generation);
		mDebugBlit.DeclareDebugBlit(mGraph, handle, colorHandle, view.TargetFormat,
			view.ViewportX, view.ViewportY, view.ViewportWidth, view.ViewportHeight, mFrameIndex,
			viewIndex, (float)resource.TextureDesc.Width, (float)resource.TextureDesc.Height,
			TextureFormats.IsDepthFormat(resource.TextureDesc.Format), debug);
	}

	/// The index of a named, blittable transient within a range of the graph's resources, or a
	/// negative when there is none.
	private int FindDebugResource(StringView name, int first, int last)
	{
		let resources = mGraph.Resources;
		for (int r = first; (r < last) && (r < resources.Length); r++)
		{
			let resource = resources[r];
			if (resource == null)
				continue;
			if ((resource.ResourceType != .Texture) || (resource.Lifetime != .Transient))
				continue;
			if ((resource.TextureDesc.Width == 0) || (resource.TextureDesc.Height == 0))
				continue;
			if (resource.Name == name)
				return r;
		}
		return -1;
	}

	/// The scene tier overlays: ONE shared load op pass on this view's final image, after the
	/// post stack so nothing smears or grades it, and before the debug drawing so the gizmos
	/// and the diagnostics stay on top.
	private void DeclareSceneOverlays(RenderView view, RGHandle colorHandle,
		Float4x4 unjitteredViewProj)
	{
		if ((mSceneOverlays == null) || mSceneOverlays.IsEmpty)
			return;

		// A stencil attachment for the overlays' fills: a transient cleared to nought, in a
		// format the device was probed for, which the sources check against their own pipelines
		// before recording anything that needs it.
		if (!mOverlayStencilProbed)
		{
			mOverlayStencilFormat = StencilFormatProbe.PickStencilFormat(mDevice);
			mOverlayStencilProbed = true;
		}

		var overlayView = SceneOverlayView();
		overlayView.SceneKey = view.SceneKey;
		overlayView.ViewProjection = unjitteredViewProj;
		overlayView.CameraPosition = view.Camera.Position;
		overlayView.ViewportX = view.ViewportX;
		overlayView.ViewportY = view.ViewportY;
		overlayView.ViewportWidth = view.ViewportWidth;
		overlayView.ViewportHeight = view.ViewportHeight;
		overlayView.TargetWidth = view.Width;
		overlayView.TargetHeight = view.Height;
		overlayView.TargetFormat = view.TargetFormat;
		overlayView.DepthStencilFormat = mOverlayStencilFormat;
		overlayView.FrameIndex = mFrameIndex;

		var depthStencil = RGHandle.Invalid;
		if (mOverlayStencilFormat != .Undefined)
			depthStencil = mGraph.CreateTransient("scene.overlay.ds",
				.(mOverlayStencilFormat, view.Width, view.Height));

		let overlays = mSceneOverlays;

		mGraph.AddRenderPass("scene.overlay", scope (builder) =>
			{
				builder.SetColorTarget(0, colorHandle, .Load, .Store, .Black);
				if (depthStencil.IsValid)
				{
					// The depth goes unused; the stencil clears to nought for the fills.
					builder.SetDepthTarget(depthStencil, .Clear, .DontCare, 1.0f, .(), .Clear,
						.DontCare, 0);
				}
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						for (let overlay in overlays)
							overlay.Render(encoder, overlayView);
					});
			});
	}

	/// The debug drawing for one view: the GLOBAL list, this view's SCENE list, and this view's
	/// OWN list, projected by the unjittered matrix into the final image. The scene list draws
	/// in every view of that scene; the view list only here.
	private void DeclareViewDebugDraw(RenderView view, uint32 viewIndex, RGHandle colorHandle,
		RGHandle overlayDepth, Float4x4 unjitteredViewProj)
	{
		if (mDebugPass == null)
			return;

		let sceneDebug = (DebugDraw)Internal.UnsafeCastToObject(view.DebugScene);
		let viewDebug = (DebugDraw)Internal.UnsafeCastToObject(view.DebugViewList);
		if ((mDebugGlobal == null) && (sceneDebug == null) && (viewDebug == null))
			return;

		mDebugPass.DeclareGeometry(mGraph, colorHandle, overlayDepth, unjitteredViewProj,
			mDebugGlobal, sceneDebug, viewDebug, view.TargetFormat, mPass.DepthFormat,
			view.ViewportX, view.ViewportY, view.ViewportWidth, view.ViewportHeight, mFrameIndex,
			viewIndex);

		mDebugPass.DeclareScreen(mGraph, colorHandle, unjitteredViewProj, mDebugGlobal, sceneDebug,
			viewDebug, view.TargetFormat, view.ViewportX, view.ViewportY, view.ViewportWidth,
			view.ViewportHeight, mFrameIndex, viewIndex);
	}

	/// The frame's graph texture inventory, deduplicated by name, for a debug view's picker.
	/// Valid from the end of a frame until the next begin rebuilds the graph.
	public void CollectDebugResources(List<DebugResourceInfo> outResources)
	{
		ClearAndDeleteItems!(outResources);

		for (let resource in mGraph.Resources)
		{
			// TRANSIENTS ONLY. A view's imported colour target is the blit's own write target,
			// and reading it would deadlock the layout tracking; a persistent registration
			// carries no description, so there are no dimensions to sample by. Both would list
			// as nothing at all otherwise.
			if (resource == null)
				continue;
			if ((resource.ResourceType != .Texture) || (resource.Lifetime != .Transient))
				continue;
			if ((resource.TextureDesc.Width == 0) || (resource.TextureDesc.Height == 0))
				continue;

			// The names repeat per view, every view declaring its own depth, and the picker
			// wants the SET of them; the blit resolves per view at declare time anyway.
			var seen = false;
			for (let row in outResources)
			{
				if (row.Name == resource.Name)
				{
					seen = true;
					break;
				}
			}
			if (seen)
				continue;

			outResources.Add(new DebugResourceInfo(resource.Name, resource.TextureDesc.Width,
				resource.TextureDesc.Height, (uint8)resource.TextureDesc.SampleCount,
				TextureFormats.IsDepthFormat(resource.TextureDesc.Format)));
		}
	}
}
