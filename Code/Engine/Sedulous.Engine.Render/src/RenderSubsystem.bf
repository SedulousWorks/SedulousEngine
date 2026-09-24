using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Profiler;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.VFS;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Shaders;

namespace Sedulous.Engine.Render;

/// The Context level renderer: it owns the frame, the renderer registry and the per scene
/// snapshots, and draws what extraction produced.
///
/// It renders rather than ticks, which is why it sorts LATE: everything that moves has
/// already moved by the time it runs.
class RenderSubsystem : Subsystem, ISceneObserver, ISceneRenderer, IScreenRenderer
{
	/// BORROWED: the owner outlives the subsystem.
	private IDevice mDevice;
	private uint32 mFramesInFlight;

	private ShaderSystemHost mShaderHost = new .() ~ delete _;
	/// BORROWED from the application: where the engine's shader corpus is read from.
	private IFileSystem mDataFileSystem = null;
	/// BORROWED from the host above.
	private ShaderSystem mShaders = null;

	private RendererRegistry mRegistry = new .() ~ delete _;
	/// Per scene contributors, BORROWED, and cleared when their scene is destroyed.
	private List<SceneProvider> mProviders = new .() ~ delete _;

	private OverlayRegistry<ISceneOverlay> mSceneOverlays = new .() ~ delete _;
	private OverlayRegistry<IScreenOverlay> mScreenOverlays = new .() ~ delete _;

	private RenderFrame mFrame = null ~ delete _;
	/// The GPU picker, created on the first request; owned, and freed after the frame.
	private PickSystem mPickSystem = null ~ delete _;
	// ---- the pass set, all OWNED and all OPTIONAL ----
	//
	// Every one of these degrades rather than fails: no clustering falls back to the shader's
	// all lights path, no shadows renders unshadowed, no lighting leaves flat ambient, and no
	// tonemap writes the target directly. That is what lets the renderer come up on a machine
	// that cannot do all of it.
	private PipelineStateCache mPsoCache = null ~ delete _;
	private MaterialSystem mMaterialSystem = null ~ delete _;
	private MeshRenderer mMeshRenderer = null ~ delete _;
	private SpriteRenderer mSpriteRenderer = null ~ delete _;
	private ClusterSystem mClusterSystem = null ~ delete _;
	private TonemapPass mTonemapPass = null ~ delete _;
	private ShadowSystem mShadowSystem = null ~ delete _;
	private IBLSystem mIblSystem = null ~ delete _;
	private ReflectionProbeSystem mProbeSystem = null ~ delete _;
	private SkyPass mSkyPass = null ~ delete _;
	private BloomPass mBloomPass = null ~ delete _;
	private TaaPass mTaaPass = null ~ delete _;
	private AoPass mAoPass = null ~ delete _;
	private SsrPass mSsrPass = null ~ delete _;
	private SsgiPass mSsgiPass = null ~ delete _;
	private FxaaPass mFxaaPass = null ~ delete _;
	private DebugBlitPass mDebugBlitPass = null ~ delete _;
	private DecalPass mDecalPass = null ~ delete _;
	private DebugDrawPass mDebugPass = null ~ delete _;
	private ExposurePass mExposurePass = null ~ delete _;

	/// Every grow path replacement retires through this instead of idling the GPU mid frame,
	/// which on the web would pump the event loop, expire the canvas texture and drop the
	/// frame's submission.
	private GpuRetireQueue mRetireQueue = new .() ~ delete _;

	// ---- the snapshot pool ----
	//
	// One snapshot per scene per frame, REUSED across frames rather than reallocated, with the
	// owners recorded alongside so two views of one scene share the extraction instead of
	// doing it twice.
	private List<ExtractedScene> mScenes = new .() ~ DeleteContainerAndItems!(_);
	private int mSceneCount = 0;
	private List<Scene> mSnapshotOwners = new .() ~ delete _;
	/// Per worker extraction arenas, provisioned once a frame.
	private RenderContext mRenderContext = new .() ~ delete _;

	/// Read once, from the environment, so an occlusion debug view can be forced on without a
	/// rebuild when comparing backends.
	private bool mAoDebugEnvRead = false;
	private int32 mAoDebugEnv = 0;

	// ---- global post override ----
	//
	// Exposure, bloom and the rest are AUTHORED per scene and resolved per view. These stay as
	// a GLOBAL override for a sample's debug panel: touching ANY of them latches the flag, and
	// the resolve then prefers these over what the scene authored. Left alone, which is the
	// editor's path, the scene's own settings drive.
	private bool mGlobalPostActive = false;
	private float mExposure = 1.0f;
	/// The WIND sway's clock.
	private float mTimeSeconds = 0.0f;
	private bool mBloomEnabled = true;
	private float mBloomIntensity = 0.05f;
	private float mBloomThreshold = 1.0f;
	private float mBloomKnee = 0.6f;
	/// Partial by default, because full darkens a curved surface more than it should.
	private AoMode mAoMode = .Off;
	private float mAoStrength = 0.6f;
	private float mAoRadius = 0.5f;
	private float mAoIntensity = 1.0f;
	/// A pure renderer toggle rather than an override, so it does NOT latch.
	private int32 mAoDebug = 0;
	private bool mSsrEnabled = false;
	private SsrParams mSsrParams = .();
	private uint32 mGlobalMsaaSamples = 1;
	/// The ceiling the device reported, filled once the passes are built.
	private uint32 mMaxMsaaSamples = 1;
	/// Null means multisampling is unavailable, whatever the device reports.
	private MsaaResolvePass mMsaaResolvePass = null ~ delete _;
	private bool mInstanceSharing = true;
	private bool mViewCulling = true;
	private bool mFxaaEnabled = false;
	private float mFxaaSubpixel = 0.75f;
	private bool mTaaEnabled = false;
	private float mTaaBlend = 0.97f;
	private float mTaaGamma = 1.25f;
	private float mTaaMotionScale = 32.0f;
	private float mShadowDistance = 300.0f;
	private float mShadowFarFade = 40.0f;

	// ---- debug draw destinations ----
	private DebugDraw mDebugGlobal = new .() ~ delete _;
	private DebugDraw mDebugScreen = new .() ~ delete _;
	private Dictionary<Scene, DebugDraw> mDebugScenes = new .() ~ DeleteDictionaryAndValues!(_);
	private Dictionary<void*, DebugDraw> mDebugViews = new .() ~ DeleteDictionaryAndValues!(_);

	// ---- the screen overlay attachment ----
	//
	// A stencil buffer for the screen tier's stencil then cover fills, cached at the target
	// size. A resize RETIRES the old pair rather than destroying it, because a frame still in
	// flight may be reading it, and recreates at the new size.
	private bool mOverlayDsProbed = false;
	private TextureFormat mOverlayDsFormat = .Undefined;
	private ITexture mOverlayDsTexture = null;
	private ITextureView mOverlayDsView = null;
	private uint32 mOverlayDsWidth = 0;
	private uint32 mOverlayDsHeight = 0;

	/// The PREVIOUS frame's graph inventory, OWNED, taken at compose time while the graph
	/// still holds it: the next begin rebuilds the graph and it would be gone.
	private List<DebugResourceInfo> mDebugResourceSnapshot = new .() ~ DeleteContainerAndItems!(_);

	/// The data mount is BORROWED: the application resolves the data root, owns the mount and
	/// outlives every subsystem it hands it to.
	public this(IDevice device, uint32 framesInFlight, IFileSystem dataFileSystem)
	{
		mDevice = device;
		mFramesInFlight = (framesInFlight < 1) ? 1 : framesInFlight;
		mDataFileSystem = dataFileSystem;
	}

	/// Renders rather than ticks, so it runs after everything that moves has moved.
	public override int32 UpdateOrder => 1000;

	/// Ready once the frame exists. Everything below it is inert until then, which is what a
	/// machine with no shaders gets rather than a crash.
	public bool IsReady => mFrame != null;

	public IDevice Device => mDevice;
	public ShaderSystem Shaders => mShaders;
	public uint32 FramesInFlight => mFramesInFlight;

	/// The frames in flight retire queue an EXTERNAL renderer wires its own rings into, so a
	/// grow retires the old buffer instead of idling the GPU mid frame. On the web that idle
	/// pumps the event loop, expires the canvas texture and drops the frame's submission.
	public GpuRetireQueue RetireQueue => mRetireQueue;

	// ---- extension seam --------------------------------------------------------------------

	/// The BUILT IN mesh renderer's registration id, which is what mesh shaped data routes to.
	/// A producer of MeshRenderData outside the extractor stamps THIS, never a literal nought.
	public uint16 MeshRendererId => (mMeshRenderer != null) ? mMeshRenderer.RendererId : 0;

	/// Registers an external renderer, BORROWED, and hands back the dispatch id to stamp on
	/// its render data. The pipeline drives the whole registry per frame.
	public uint16 RegisterRenderer(Renderer renderer)
	{
		mRegistry.Register(renderer);
		return renderer.RendererId;
	}

	/// Registers a render data provider FOR a scene, BORROWED. It is invoked during that
	/// scene's extraction and dropped when the scene is destroyed.
	public void RegisterProvider(Scene scene, IRenderDataProvider provider)
	{
		mProviders.Add(SceneProvider(scene, provider));
	}

	// ---- frame -----------------------------------------------------------------------------

	/// The frame delta reaches the pipeline, where the auto exposure eases against it.
	public override void Update(float deltaTime)
	{
		if (mFrame != null)
			mFrame.SetDeltaSeconds(deltaTime);
	}

	/// Drops everything keyed on a scene that is going away.
	///
	/// The providers are borrowed and about to dangle. The debug list has to go for a second
	/// reason: the map is keyed on the scene itself and anything may mint an entry, so without
	/// this every reload leaks one, and a recycled address would silently adopt the dead
	/// scene's drawings.
	public void OnDestroying(Scene scene)
	{
		for (int i = mProviders.Count - 1; i >= 0; i--)
		{
			if (mProviders[i].Scene === scene)
				mProviders.RemoveAt(i);
		}

		if (mDebugScenes.GetAndRemove(scene) case .Ok(let pair))
			delete pair.value;
	}

	// ---- global post override ---------------------------------------------------------------

	/// Whether any global setter has been touched. Until one is, the scene's authored settings
	/// are what resolve.
	public bool GlobalPostActive => mGlobalPostActive;

	/// The application's run clock in seconds, handed to the frame every time rendering
	/// begins: the WIND vertex sway's phase. Not a post setting, so it does not take the
	/// global override with it.
	public float TimeSeconds
	{
		get => mTimeSeconds;
		set => mTimeSeconds = value;
	}

	/// The linear multiplier the tonemap applies.
	public float Exposure
	{
		get => mExposure;
		set { mExposure = value; mGlobalPostActive = true; }
	}

	/// Off skips the whole pyramid rather than running it at zero strength.
	public bool BloomEnabled
	{
		get => mBloomEnabled;
		set { mBloomEnabled = value; mGlobalPostActive = true; }
	}

	public float BloomIntensity
	{
		get => mBloomIntensity;
		set { mBloomIntensity = value; mGlobalPostActive = true; }
	}

	public float BloomThreshold
	{
		get => mBloomThreshold;
		set { mBloomThreshold = value; mGlobalPostActive = true; }
	}

	public float BloomKnee
	{
		get => mBloomKnee;
		set { mBloomKnee = value; mGlobalPostActive = true; }
	}

	public AoMode AoMode
	{
		get => mAoMode;
		set { mAoMode = value; mGlobalPostActive = true; }
	}

	/// The composite amount.
	public float AoStrength
	{
		get => mAoStrength;
		set { mAoStrength = value; mGlobalPostActive = true; }
	}

	/// The world space radius the estimator searches.
	public float AoRadius
	{
		get => mAoRadius;
		set { mAoRadius = value; mGlobalPostActive = true; }
	}

	public float AoIntensity
	{
		get => mAoIntensity;
		set { mAoIntensity = value; mGlobalPostActive = true; }
	}

	/// Which intermediate the occlusion pass shows. A frame global debug view, NOT an
	/// override, so it deliberately does not latch the flag.
	public int32 AoDebug
	{
		get => mAoDebug;
		set => mAoDebug = value;
	}

	public bool SsrEnabled
	{
		get => mSsrEnabled;
		set { mSsrEnabled = value; mGlobalPostActive = true; }
	}

	public SsrParams* SsrParams => &mSsrParams;

	/// The scene pass sample count for the global path, clamped per view against the device.
	public uint32 MsaaSamples
	{
		get => mGlobalMsaaSamples;
		set
		{
			mGlobalMsaaSamples = (value < 1) ? 1 : value;
			mGlobalPostActive = true;
		}
	}

	/// Whether this EXACT count is usable on the active device.
	///
	/// The valid set is not contiguous, since some backends offer only one and four, so a
	/// menu has to ask per count rather than assume everything up to a ceiling.
	public bool SupportsMsaaSamples(uint32 count)
	{
		// One is always available, and is what off means.
		if (count <= 1)
			return true;

		// Multisampling needs the resolve pass. Without it, or without a device, only one is
		// usable however capable the hardware is.
		if ((mMsaaResolvePass == null) || (mDevice == null))
			return false;

		return (count <= mMaxMsaaSamples) && mDevice.SupportsSampleCount(count);
	}

	/// Builds the instance data once and shares it between the depth prepass and the forward
	/// pass, rather than filling it twice.
	public bool InstanceSharing
	{
		get => mInstanceSharing;
		set => mInstanceSharing = value;
	}

	/// Skips renderables outside the camera frustum, per view. Off by default: it is a no op
	/// for a benchmark that frames everything and a win for a real scene with much off screen.
	/// Shadow casters are gathered separately, so culling the camera view never drops a shadow.
	public bool ViewCulling
	{
		get => mViewCulling;
		set => mViewCulling = value;
	}

	/// Last frame's totals, summed over views. Both nought when culling was off.
	public void ViewCullStats(out uint32 culled, out uint32 total)
	{
		if (mFrame != null)
		{
			mFrame.CullStats(out culled, out total);
			return;
		}
		culled = 0;
		total = 0;
	}

	/// The fallback when temporal is off. Ignored while it is on.
	public bool FxaaEnabled
	{
		get => mFxaaEnabled;
		set { mFxaaEnabled = value; mGlobalPostActive = true; }
	}

	public float FxaaSubpixel
	{
		get => mFxaaSubpixel;
		set { mFxaaSubpixel = value; mGlobalPostActive = true; }
	}

	public bool TaaEnabled
	{
		get => mTaaEnabled;
		set { mTaaEnabled = value; mGlobalPostActive = true; }
	}

	/// The history weight, which is what stability trades against ghosting.
	public float TaaBlend
	{
		get => mTaaBlend;
		set { mTaaBlend = value; mGlobalPostActive = true; }
	}

	public float TaaGamma
	{
		get => mTaaGamma;
		set { mTaaGamma = value; mGlobalPostActive = true; }
	}

	/// How fast the history is dropped as things move.
	public float TaaMotionScale
	{
		get => mTaaMotionScale;
		set => mTaaMotionScale = value;
	}

	/// The directional shadow reach, in world units, clamped to the camera's far plane.
	public float ShadowDistance
	{
		get => mShadowDistance;
		set => mShadowDistance = value;
	}

	/// The WIDTH of the soft edge shadows dissolve across at that reach, which is what stops
	/// the coverage boundary popping as a tilted camera turns.
	public float ShadowFarFade
	{
		get => mShadowFarFade;
		set => mShadowFarFade = value;
	}

	// ---- debug draw -------------------------------------------------------------------------
	//
	// Destinations by WHERE the draw lands. Global goes into every view; a scene's goes into
	// every view OF THAT SCENE, so two scenes side by side do not bleed into each other; a
	// view's goes only into the one view whose key matches, which keeps an editor viewport's
	// grid out of a second view of the same scene; the screen one is drawn ONCE over the whole
	// window, so a three dimensional call there has no camera and is ignored.

	public DebugDraw DebugGlobal => mDebugGlobal;
	public DebugDraw DebugScreen => mDebugScreen;

	public DebugDraw DebugScene(Scene scene)
	{
		if (mDebugScenes.TryGetValue(scene, let existing))
			return existing;

		let created = new DebugDraw();
		mDebugScenes[scene] = created;
		return created;
	}

	public DebugDraw DebugView(void* viewportKey)
	{
		if (mDebugViews.TryGetValue(viewportKey, let existing))
			return existing;

		let created = new DebugDraw();
		mDebugViews[viewportKey] = created;
		return created;
	}

	// ---- GPU picking ------------------------------------------------------------------------

	/// Asks for the entities under a viewport rect, in the coordinates of the viewport's last
	/// RenderScene. Returns the request id, or PickSystem.cInvalidRequest for a null key. The
	/// pass is declared in the next frame that renders the viewport, and the result is
	/// readable a couple of frames later through TryTakePickResult.
	public uint32 RequestPick(void* viewportKey, int32 x, int32 y, uint32 width = 1,
		uint32 height = 1)
	{
		if ((viewportKey == null) || (mDevice == null))
			return PickSystem.cInvalidRequest;
		EnsurePickSystem();
		return mPickSystem.Request(viewportKey, .(x, y, width, height));
	}

	/// Takes a finished request's hits. False while it is still in flight, or once it has
	/// expired or been cancelled.
	public bool TryTakePickResult(uint32 request, PickResult outResult)
	{
		if (mPickSystem == null)
			return false;
		return mPickSystem.TryTakeResult(request, outResult);
	}

	public bool IsPickPending(uint32 request)
	{
		return (mPickSystem != null) && mPickSystem.IsPending(request);
	}

	/// Drops every request against a viewport: for a viewport closing while a pick is in
	/// flight.
	public void CancelPicks(void* viewportKey)
	{
		if (mPickSystem != null)
			mPickSystem.Cancel(viewportKey);
	}

	private void EnsurePickSystem()
	{
		if (mPickSystem != null)
			return;
		mPickSystem = new PickSystem(mDevice);
		mPickSystem.SetRetireQueue(mRetireQueue);
		if (mFrame != null)
			mFrame.SetPick(mPickSystem);
	}

	// ---- environment source -----------------------------------------------------------------

	/// Sets the scene's equirectangular environment, as four floats per texel.
	///
	/// The image based lighting rebuilds from it when the sky mode asks for one. A COPY is
	/// taken and uploaded next frame, and it is a no op where lighting is unavailable.
	public void SetSkyEquirect(uint32 width, uint32 height, Span<float> rgba)
	{
		if (mIblSystem != null)
			mIblSystem.SetEquirect(width, height, rgba);
	}

	/// Sets the scene's cube environment: six faces concatenated in the usual axis order.
	public void SetSkyCubemap(uint32 faceSize, Span<uint8> sixFaces)
	{
		if (mIblSystem != null)
			mIblSystem.SetCubemap(faceSize, sixFaces);
	}

	/// Reads back the GPU timings for the last frame.
	///
	/// IDLES the device first, because the timings are only there once the work that produced
	/// them has finished. A debug path, never a per frame one.
	public void BuildGpuProfileReport(String outReport)
	{
		if ((mFrame == null) || (mDevice == null))
			return;

		mDevice.WaitIdle();
		mFrame.ReadGpuProfile(outReport);
	}

	// ---- bring up ---------------------------------------------------------------------------

	protected override void OnInit()
	{
		// The host settles the pack versus compiler question: a cooked pack in the data root
		// means no compiler is needed, and otherwise it stands one up over the root's Shaders
		// folder with hot reload. Every consumer uses the same host over the same mount.
		if (mShaderHost.Initialize(mDevice, mDataFileSystem) case .Err)
			return; // neither a compiler nor a pack, so the renderer stays inert

		mShaders = mShaderHost.System;

		let format = mDevice.PreferredShaderFormat;
		if (mShaderHost.UsingPack)
		{
			GlobalLog(.Information, "RenderSubsystem: using a cooked shader pack, {} variants", mShaderHost.PackVariantCount);
		}
		else if (format == .WGSL)
		{
			// The runtime compiler cannot emit this format at all, so every lookup will miss
			// and the scene renders BLACK. Said loudly, because the symptom otherwise looks
			// like a broken scene rather than a missing cook.
			GlobalLog(.Error, "RenderSubsystem: the device wants WGSL and there is no cooked pack. The runtime compiler cannot produce WGSL, so NOTHING will render.");
		}

		mPsoCache = new PipelineStateCache(mShaders, mDevice);
		mMaterialSystem = new MaterialSystem();
		if (mMaterialSystem.Initialize(mDevice) case .Err)
		{
			DeleteAndNullify!(mMaterialSystem);
			return;
		}

		mMeshRenderer = new MeshRenderer(mDevice, mShaders, mPsoCache, mMaterialSystem,
			mFramesInFlight);
		if (mMeshRenderer.Initialize() case .Err)
		{
			DeleteAndNullify!(mMeshRenderer);
			return;
		}
		// FIRST, so it takes renderer id nought, which is what render data defaults to.
		mRegistry.Register(mMeshRenderer);

		mRetireQueue.Initialize(mDevice, (int32)mFramesInFlight);
		mMeshRenderer.SetRetireQueue(mRetireQueue);

		// Sprites register next, taking id one, and share the blended forward pass.
		mSpriteRenderer = new SpriteRenderer(mDevice, mShaders, mFramesInFlight);
		if (mSpriteRenderer.Initialize() case .Ok)
		{
			mRegistry.Register(mSpriteRenderer);
			mSpriteRenderer.SetRetireQueue(mRetireQueue);
		}
		else
		{
			DeleteAndNullify!(mSpriteRenderer);
		}

		// Clustered light culling, one compute pass per view.
		mClusterSystem = new ClusterSystem(mDevice, mShaders, mFramesInFlight);
		if (mClusterSystem.Initialize() case .Err)
			DeleteAndNullify!(mClusterSystem);
		else
			mClusterSystem.SetRetireQueue(mRetireQueue);

		// The forward pass renders linear high range colour; this maps it to the target.
		mTonemapPass = new TonemapPass(mDevice, mShaders, mFramesInFlight);
		if (mTonemapPass.Initialize() case .Err)
			DeleteAndNullify!(mTonemapPass);

		mShadowSystem = new ShadowSystem(mDevice, mFramesInFlight);
		if (mShadowSystem.Initialize() case .Err)
			DeleteAndNullify!(mShadowSystem);
		else
			mShadowSystem.SetRetireQueue(mRetireQueue);

		mIblSystem = new IBLSystem(mDevice, mShaders);
		if (mIblSystem.Initialize() case .Err)
			DeleteAndNullify!(mIblSystem);

		mProbeSystem = new ReflectionProbeSystem(mDevice, mShaders);
		if (mProbeSystem.Initialize() case .Err)
			DeleteAndNullify!(mProbeSystem);

		// The visible sky, drawn from the environment.
		mSkyPass = new SkyPass(mDevice, mShaders, mFramesInFlight);
		if (mSkyPass.Initialize() case .Err)
			DeleteAndNullify!(mSkyPass);

		mBloomPass = new BloomPass(mDevice, mShaders);
		if (mBloomPass.Initialize() case .Err)
			DeleteAndNullify!(mBloomPass);

		mTaaPass = new TaaPass(mDevice, mShaders);
		if (mTaaPass.Initialize() case .Err)
			DeleteAndNullify!(mTaaPass);

		mAoPass = new AoPass(mDevice, mShaders);
		if (mAoPass.Initialize() case .Err)
			DeleteAndNullify!(mAoPass);

		mSsrPass = new SsrPass(mDevice, mShaders);
		if (mSsrPass.Initialize() case .Err)
			DeleteAndNullify!(mSsrPass);

		mSsgiPass = new SsgiPass(mDevice, mShaders);
		if (mSsgiPass.Initialize() case .Err)
			DeleteAndNullify!(mSsgiPass);

		// Without the resolve pass multisampling is unavailable whatever the device can do,
		// and every view clamps itself to one sample.
		mMsaaResolvePass = new MsaaResolvePass(mDevice, mShaders);
		if (mMsaaResolvePass.Initialize() case .Err)
			DeleteAndNullify!(mMsaaResolvePass);

		mMaxMsaaSamples = (mMsaaResolvePass != null) ? mDevice.MaxColorDepthSampleCount : 1;
		GlobalLog(.Information, "RenderSubsystem: scene pass multisampling resolve={} ceiling={}x",
			(mMsaaResolvePass != null) ? "ok" : "FAILED", mMaxMsaaSamples);

		mFxaaPass = new FxaaPass(mDevice, mShaders, mFramesInFlight);
		if (mFxaaPass.Initialize() case .Err)
			DeleteAndNullify!(mFxaaPass);

		mDebugBlitPass = new DebugBlitPass(mDevice, mShaders, mFramesInFlight);
		if (mDebugBlitPass.Initialize() case .Err)
			DeleteAndNullify!(mDebugBlitPass);

		mDecalPass = new DecalPass(mDevice, mShaders, mFramesInFlight);
		if (mDecalPass.Initialize() case .Err)
			DeleteAndNullify!(mDecalPass);
		else
			mDecalPass.SetRetireQueue(mRetireQueue);

		mDebugPass = new DebugDrawPass(mDevice, mShaders, mFramesInFlight);
		if (mDebugPass.Initialize() case .Err)
			DeleteAndNullify!(mDebugPass);

		// Auto exposure goes quiet if this fails; the fixed setting still works.
		mExposurePass = new ExposurePass(mDevice, mShaders, mFramesInFlight);
		if (mExposurePass.Initialize() case .Err)
			DeleteAndNullify!(mExposurePass);

		mFrame = new RenderFrame(mDevice, mRegistry, mFramesInFlight, mClusterSystem,
			mTonemapPass, mShadowSystem, mIblSystem, mSkyPass, mBloomPass, mTaaPass, mAoPass,
			mFxaaPass, mExposurePass, mDebugBlitPass);
		// Per pass timestamps, cheap enough to leave on and read from a debug dump.
		mFrame.EnableGpuProfiling();
		if (mPickSystem != null)
			mFrame.SetPick(mPickSystem);
	}

	/// Registers as a scene observer, which is how the borrowed providers get cleaned up.
	protected override void OnReady()
	{
		if (Context == null)
			return;

		if (let scenes = Context.GetSubsystem<Sedulous.Engine.Scene.SceneSubsystem>())
			scenes.RegisterObserver(this, .Destroying);
	}

	protected override void OnShutdown()
	{
		if (Context != null)
		{
			if (let scenes = Context.GetSubsystem<Sedulous.Engine.Scene.SceneSubsystem>())
				scenes.UnregisterObserver(this);
		}

		// The GPU has to finish before anything it is still reading is freed.
		mDevice.WaitIdle();
		mRetireQueue.Flush();

		// The screen overlay attachment is not retired but destroyed outright: the device is
		// idle, so nothing is still reading it.
		if (mOverlayDsView != null)
			mDevice.DestroyTextureView(ref mOverlayDsView);
		if (mOverlayDsTexture != null)
			mDevice.DestroyTexture(ref mOverlayDsTexture);

		// EXPLICITLY ORDERED, rather than left to the field destructors.
		//
		// Beef destroys fields in reverse declaration order, which is not the order these
		// depend on each other in. The frame has to go first, because it holds the per frame
		// bind groups and encoders that still reference descriptor sets the material system
		// owns; freeing those first is what validation catches as a set still in use by a
		// command buffer. Every pass goes before the shader host it borrowed its system from,
		// the mesh renderer before the material system whose instances it holds, and the
		// material system before the pipeline cache.
		//
		// Nulled as they go, so the `~ delete _` on each field is a no-op afterwards.
		DeleteAndNullify!(mFrame);
		// After the frame, which records through it; its readback buffers go straight to the
		// idle device.
		DeleteAndNullify!(mPickSystem);

		DeleteAndNullify!(mClusterSystem);
		DeleteAndNullify!(mTonemapPass);
		DeleteAndNullify!(mExposurePass);
		DeleteAndNullify!(mShadowSystem);
		DeleteAndNullify!(mSkyPass);
		DeleteAndNullify!(mBloomPass);
		DeleteAndNullify!(mTaaPass);
		DeleteAndNullify!(mAoPass);
		DeleteAndNullify!(mSsrPass);
		DeleteAndNullify!(mSsgiPass);
		DeleteAndNullify!(mFxaaPass);
		DeleteAndNullify!(mDecalPass);
		DeleteAndNullify!(mDebugPass);
		DeleteAndNullify!(mDebugBlitPass);
		DeleteAndNullify!(mProbeSystem);
		DeleteAndNullify!(mIblSystem);
		DeleteAndNullify!(mSpriteRenderer);

		DeleteAndNullify!(mMeshRenderer);
		DeleteAndNullify!(mMaterialSystem);
		DeleteAndNullify!(mPsoCache);

		// BORROWED from the host, which owns it and frees it in Shutdown.
		mShaders = null;
		mShaderHost.Shutdown();
	}

	// ---- the frame ---------------------------------------------------------------------------

	/// Opens the frame: hands the renderer everything it needs for it, then begins recording.
	public void BeginRendering(ICommandEncoder encoder, uint32 frameIndex)
	{
		if (mFrame == null)
			return;

		// A shader reload rebuilds pipelines stamped with the old version, so the GPU is
		// idled first to let the passes destroy and rebuild theirs immediately. A development
		// hiccup only; the material path still goes through the retire ring.
		if ((mShaders != null) && (mShaders.PumpReloads() > 0))
			mDevice.WaitIdle();

		mSceneCount = 0;
		// Per frame tags, which is what lets two views of one scene share its snapshot.
		mSnapshotOwners.Clear();
		for (int i < mScenes.Count)
			mSnapshotOwners.Add(null);

		// One arena per worker slot, or a single one where there is no job system.
		let slotCount = HasGlobalJobSystem() ? (uint32)GlobalJobs().SlotCount : 1;
		mRenderContext.BeginFrame(slotCount);

		// Frees what has aged past every frame still in flight.
		mRetireQueue.Tick();

		mFrame.SetExposure(mExposure);
		// The previous value stays behind in the frame, for the motion vectors.
		mFrame.SetTime(mTimeSeconds);
		mFrame.SetBloom(mBloomEnabled ? mBloomIntensity : 0.0f, mBloomThreshold, mBloomKnee);
		mFrame.SetTaa(mTaaEnabled, mTaaBlend, mTaaGamma, mTaaMotionScale);
		mFrame.SetShadowParams(mShadowDistance, mShadowFarFade);

		// A debug harness: the environment can force the occlusion debug channel to screen, so
		// the reconstruction can be compared across backends without a rebuild.
		if (!mAoDebugEnvRead)
		{
			mAoDebugEnvRead = true;
			let value = scope String();
			if ((Environment.GetEnvironmentVariable("ENV_AO_DEBUG", value) case .Ok)
				&& !value.IsEmpty)
			{
				let first = value[0];
				if (first.IsDigit)
					mAoDebugEnv = (int32)(first - '0');
			}
		}
		if (mAoDebugEnv != 0)
			mAoDebug = mAoDebugEnv;

		mFrame.SetAo(mAoMode, mAoStrength, mAoRadius, mAoIntensity, mAoDebug);
		mFrame.SetFxaa(mFxaaEnabled, mFxaaSubpixel);
		mFrame.SetInstanceSharing(mInstanceSharing);
		mFrame.SetViewCulling(mViewCulling);
		mFrame.SetDebug(mDebugPass, mDebugGlobal, mDebugScreen);
		mFrame.SetSceneOverlays(mSceneOverlays.LiveItems);
		mFrame.SetDecal(mDecalPass);
		mFrame.SetSsr(mSsrPass);
		mFrame.SetSsgi(mSsgiPass);
		mFrame.SetSsrParams(mSsrEnabled, mSsrParams);
		mFrame.SetMsaaResolve(mMsaaResolvePass);
		mFrame.SetProbes(mProbeSystem);

		// The probe records re-accumulate per scene, so they start empty each frame.
		if (mProbeSystem != null)
			mProbeSystem.BeginFrame();

		mFrame.Begin(encoder, frameIndex);
	}

	/// Collects a scene, seen from its primary camera or from the override, into the frame.
	/// Between the brackets.
	public void RenderScene(Scene scene, ITextureView target, TextureFormat targetFormat,
		uint32 width, uint32 height, ViewportRect viewport = .(),
		CameraOverride* cameraOverride = null, TargetState targetState = .(),
		ViewPostOverride* postOverride = null, void* viewportKey = null,
		ViewDebugView debugView = null)
	{
		if ((mFrame == null) || (target == null))
			return;

		// ONE extraction per scene per frame: a scene rendered through several views, which is
		// what a split screen is, shares one snapshot, so the per scene shadow, probe and image
		// based lighting work grouped on the snapshot downstream runs once rather than per
		// view. Scenes must not mutate between the renders of one frame, which is the bracket's
		// contract.
		ExtractedScene snapshot = null;
		for (int i < mSceneCount)
		{
			if (mSnapshotOwners[i] === scene)
			{
				snapshot = mScenes[i];
				break;
			}
		}

		let firstSight = (snapshot == null);
		if (firstSight)
		{
			snapshot = AcquireScene();
			while (mSnapshotOwners.Count < mSceneCount)
				mSnapshotOwners.Add(null);
			mSnapshotOwners[mSceneCount - 1] = scene;

			using (ProfileScope("Render.Extract"))
			{
				// Parallel where the job system is up, and it resets the snapshot itself.
				RenderExtract.ExtractSceneInto(scene, snapshot, mRenderContext);
				// The instanced sets: one item each, so O(1) a frame rather than per instance.
				RenderExtract.ExtractInstancedMeshesInto(scene, snapshot);
				// Billboards, into the same snapshot and after the meshes.
				if (mSpriteRenderer != null)
					RenderExtract.ExtractSpritesInto(scene, snapshot, mSpriteRenderer.RendererId);
				// Screen space decals, which are the decal pass rather than the renderer path.
				RenderExtract.ExtractDecalsInto(scene, snapshot);
				// Lights are shading inputs, not draws.
				RenderExtract.ExtractLightsInto(scene, snapshot);
				RenderExtract.ExtractReflectionProbesInto(scene, snapshot);
				RenderExtract.ExtractEnvironmentInto(scene, snapshot);

				// Downstream systems, particles and world space UI among them, registered for
				// THIS scene contribute into the same snapshot, which is what keeps the
				// renderer ignorant of their types.
				for (let provider in mProviders)
				{
					if ((provider.Scene === scene) && (provider.Provider != null))
						provider.Provider.ExtractRenderData(snapshot);
				}

				// Maps the probes onto persistent array slots; the capture itself is later.
				if (mProbeSystem != null)
					mProbeSystem.Assign(snapshot, snapshot.ReflectionProbes);
			}
		}

		var camera = ViewCamera();
		// The cornflower fallback, for a scene with no primary camera.
		var clearColor = Color(0.392f, 0.584f, 0.929f, 1.0f);
		if (cameraOverride != null)
		{
			camera = cameraOverride.Camera;
			clearColor = cameraOverride.ClearColor;
		}
		else
		{
			// The clear comes from the camera.
			RenderExtract.ExtractPrimaryCamera(scene, ref camera, &clearColor);
		}

		var settings = ViewSettings();
		settings.Clear = .(clearColor.R, clearColor.G, clearColor.B, clearColor.A);
		settings.ViewportX = viewport.X;
		settings.ViewportY = viewport.Y;
		settings.ViewportWidth = viewport.Width;
		settings.ViewportHeight = viewport.Height;
		// The picker matches requests to views by this key.
		settings.ViewportKey = viewportKey;
		settings.TargetTexture = targetState.Texture;
		settings.TargetCurrentState = targetState.CurrentState;
		settings.TargetFinalState = targetState.FinalState;

		// This view's post processing. The programmatic global override, which is a sample's
		// debug panel, wins once touched; otherwise the scene's authored settings drive, with
		// the exposure authored in stops resolved to the tonemap's linear multiplier. The
		// antialiasing and reflection settings stay frame global.
		if (mGlobalPostActive)
		{
			settings.Post.Exposure = mExposure;
			// The legacy global API has no operator toggle.
			settings.Post.AgxTonemap = true;
			settings.Post.BloomEnabled = mBloomEnabled;
			settings.Post.BloomThreshold = mBloomThreshold;
			settings.Post.BloomKnee = mBloomKnee;
			settings.Post.BloomIntensity = mBloomIntensity;
			settings.Post.AoMode = (uint32)mAoMode;
			settings.Post.AoStrength = mAoStrength;
			settings.Post.AoRadius = mAoRadius;
			settings.Post.AoIntensity = mAoIntensity;
			settings.Post.TaaEnabled = mTaaEnabled;
			settings.Post.TaaBlend = mTaaBlend;
			settings.Post.TaaGamma = mTaaGamma;
			settings.Post.FxaaEnabled = mFxaaEnabled;
			settings.Post.FxaaSubpixel = mFxaaSubpixel;
			settings.Post.SsrEnabled = mSsrEnabled;
			settings.Post.SsrIntensity = mSsrParams.Intensity;
			settings.Post.MsaaSamples = (uint8)mGlobalMsaaSamples;
		}
		else if (let post = scene.GetSystem<PostProcessSystem>())
		{
			settings.Post = ScenePost.Resolve(*post.Post);
		}

		// An editor viewport's show flags: ephemeral per view overrides that strip effects for
		// editing clarity, layered ON TOP of the resolved settings and never written back.
		if (postOverride != null)
		{
			ScenePost.ApplyOverride(ref settings.Post, *postOverride);
			settings.FrustumCull = !postOverride.DisableCulling;
		}

		// The editor's debug view: a pass through selection, validated per view at declare
		// time, so an unknown resource name simply shows the final image.
		if (debugView != null)
			settings.Debug = debugView;

		// The motion vector requirement settles AFTER the overrides: antialiasing OR a temporal
		// reflection pass. The reflection temporal flag is frame global, which is why the
		// disjunction lands here rather than in the resolve.
		settings.Post.NeedsMotion = settings.Post.TaaEnabled
			|| (settings.Post.SsrEnabled && mSsrParams.Temporal)
			// The indirect lighting's temporal resolve reprojects by velocity.
			|| settings.Post.SsgiEnabled;

		// The scene pass's multisampling: the AUTHORED intent snapped to what the device does.
		// The supported set is NOT one through the ceiling, the web backend supporting only one
		// and four and never two, so this clamps to the ceiling and then snaps DOWN to the
		// nearest supported count. An unsupported count reaching texture or pipeline creation
		// aborts the device, so it is the snap rather than the clamp that keeps a request for
		// two from taking the web down.
		{
			var samples = (uint32)settings.Post.MsaaSamples;
			if (samples < 1)
				samples = 1;
			if (samples > mMaxMsaaSamples)
				samples = mMaxMsaaSamples;
			while ((samples > 1) && !mDevice.SupportsSampleCount(samples))
				samples >>= 1;
			settings.Post.MsaaSamples = (uint8)samples;
		}

		// Binds the view and builds and sorts its draw list.
		using (ProfileScope("Render.AddView"))
		{
			// EVERY view of a scene draws that scene's own list, which is the physics and
			// navigation debugging a play session shows. A KEYED view ADDITIONALLY draws its
			// own list, the editor's grid and selection gizmos, which never appears in another
			// view of the same scene. Either may be null when nothing was drawn this frame,
			// and the debug pass checks.
			void* sceneDebug = null;
			if (mDebugScenes.GetValue(scene) case .Ok(let debug))
				sceneDebug = Internal.UnsafeCastToPtr(debug);

			void* viewDebug = null;
			if (viewportKey != null)
			{
				if (mDebugViews.GetValue(viewportKey) case .Ok(let keyed))
					viewDebug = Internal.UnsafeCastToPtr(keyed);
			}

			mFrame.AddView(snapshot, camera, settings, target, targetFormat, width, height,
				sceneDebug, Internal.UnsafeCastToPtr(scene), viewDebug);
		}
	}

	/// Composes every collected view into the frame's encoder.
	public void EndRendering()
	{
		using (ProfileScope("Render.Compose"))
		{
			if (mFrame != null)
			{
				mFrame.End();
				// The graph's texture inventory, taken while the graph still holds it, since
				// the next begin rebuilds it. The editor's debug view picker reads this copy.
				mFrame.CollectDebugResources(mDebugResourceSnapshot);
			}
		}

		// Immediate mode: the debug lists clear AFTER rendering, so the next frame's drawing
		// starts empty. The application accumulates during its update, before the next begin.
		mDebugGlobal.Clear();
		mDebugScreen.Clear();
		for (let debug in mDebugScenes.Values)
			debug.Clear();
		for (let debug in mDebugViews.Values)
			debug.Clear();
	}

	/// The previous frame's inventory, COPIED: the caller owns the rows it receives.
	public void GetDebugResources(List<DebugResourceInfo> outResources)
	{
		ClearAndDeleteItems!(outResources);
		for (let row in mDebugResourceSnapshot)
			outResources.Add(new .(row.Name, row.Width, row.Height, row.Samples, row.IsDepth));
	}

	// ---- the overlay registries --------------------------------------------------------------

	/// The scene tier: drawn per view inside the compose, after the post stack and before the
	/// debug drawing, matched to views by their scene. Idempotent and NON OWNING.
	public void RegisterOverlay(ISceneOverlay overlay) => mSceneOverlays.Add(overlay);

	public void UnregisterOverlay(ISceneOverlay overlay) => mSceneOverlays.Remove(overlay);

	/// The screen tier: window space chrome, drawn once per target after the scene composed.
	public void RegisterOverlay(IScreenOverlay overlay) => mScreenOverlays.Add(overlay);

	public void UnregisterOverlay(IScreenOverlay overlay) => mScreenOverlays.Remove(overlay);

	/// One shared load op pass against the target, which must be in the render target state and
	/// is left there, with every registered source drawing into it in order. The HOST calls
	/// this once per window target, after the scene composed.
	public void RenderOverlays(ICommandEncoder encoder, ITextureView target,
		TextureFormat targetFormat, uint32 width, uint32 height, uint32 frameIndex)
	{
		if ((target == null) || (width == 0) || (height == 0) || mScreenOverlays.IsEmpty)
			return;

		if (!mOverlayDsProbed)
		{
			mOverlayDsFormat = StencilFormatProbe.PickStencilFormat(mDevice);
			mOverlayDsProbed = true;
		}

		if ((mOverlayDsFormat != .Undefined)
			&& ((mOverlayDsTexture == null) || (mOverlayDsWidth != width)
				|| (mOverlayDsHeight != height)))
		{
			mRetireQueue.Retire(mOverlayDsView);
			mRetireQueue.Retire(mOverlayDsTexture);
			mOverlayDsView = null;
			mOverlayDsTexture = null;

			var desc = TextureDesc();
			desc.Dimension = .Texture2D;
			desc.Format = mOverlayDsFormat;
			desc.Width = width;
			desc.Height = height;
			desc.Depth = 1;
			desc.Usage = .DepthStencil;
			desc.Label = "screen.overlay.ds";
			if (mDevice.CreateTexture(desc) case .Ok(let texture))
			{
				mOverlayDsTexture = texture;
				if (mDevice.CreateTextureView(texture, .()) case .Ok(let view))
				{
					mOverlayDsView = view;
				}
				else
				{
					mRetireQueue.Retire(mOverlayDsTexture);
					mOverlayDsTexture = null;
				}
			}

			mOverlayDsWidth = width;
			mOverlayDsHeight = height;
		}

		var pass = RenderPassDesc();
		var color = ColorAttachment();
		color.View = target;
		color.LoadOp = .Load;
		color.StoreOp = .Store;
		pass.ColorAttachments.Add(color);

		let haveDs = (mOverlayDsView != null);
		if (haveDs)
		{
			// The backend does not transition a pass's attachments itself. The buffer clears
			// fully, so its previous contents are discardable and Undefined is the right
			// source state.
			encoder.TransitionTexture(mOverlayDsTexture, .Undefined, .DepthStencilWrite);

			var depthStencil = DepthStencilAttachment();
			depthStencil.View = mOverlayDsView;
			depthStencil.DepthLoadOp = .Clear;
			depthStencil.DepthStoreOp = .DontCare;
			// Stencil then cover expects nought.
			depthStencil.StencilLoadOp = .Clear;
			depthStencil.StencilStoreOp = .DontCare;
			depthStencil.StencilClearValue = 0;
			pass.DepthStencilAttachment = depthStencil;
		}

		if (let renderPass = encoder.BeginRenderPass(pass))
		{
			var view = ScreenOverlayView();
			view.Width = width;
			view.Height = height;
			view.TargetFormat = targetFormat;
			view.DepthStencilFormat = haveDs ? mOverlayDsFormat : .Undefined;
			view.FrameIndex = frameIndex;

			for (let overlay in mScreenOverlays.Items)
				overlay.Render(renderPass, view);

			renderPass.End();
		}
	}

	/// The per frame snapshot pool: one per scene rendered, kept alive, and its arena chunks
	/// reused, until the next begin.
	private ExtractedScene AcquireScene()
	{
		if (mSceneCount == mScenes.Count)
			mScenes.Add(new .());

		let snapshot = mScenes[mSceneCount++];
		snapshot.Reset();
		return snapshot;
	}
}
