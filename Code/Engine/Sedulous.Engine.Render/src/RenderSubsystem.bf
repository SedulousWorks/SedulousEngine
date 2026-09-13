using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Shaders;

namespace Sedulous.Engine.Render;

/// The Context level renderer: it owns the frame, the renderer registry and the per scene
/// snapshots, and draws what extraction produced.
///
/// It renders rather than ticks, which is why it sorts LATE: everything that moves has
/// already moved by the time it runs.
class RenderSubsystem : Subsystem, ISceneObserver
{
	/// BORROWED: the owner outlives the subsystem.
	private IDevice mDevice;
	private uint32 mFramesInFlight;

	private ShaderSystemHost mShaderHost = new .() ~ delete _;
	/// BORROWED from the host above.
	private ShaderSystem mShaders = null;

	private RendererRegistry mRegistry = new .() ~ delete _;
	/// Per scene contributors, BORROWED, and cleared when their scene is destroyed.
	private List<SceneProvider> mProviders = new .() ~ delete _;

	private OverlayRegistry<ISceneOverlay> mSceneOverlays = new .() ~ delete _;
	private OverlayRegistry<IScreenOverlay> mScreenOverlays = new .() ~ delete _;

	private RenderFrame mFrame = null ~ delete _;
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

	// ---- global post override ----
	//
	// Exposure, bloom and the rest are AUTHORED per scene and resolved per view. These stay as
	// a GLOBAL override for a sample's debug panel: touching ANY of them latches the flag, and
	// the resolve then prefers these over what the scene authored. Left alone, which is the
	// editor's path, the scene's own settings drive.
	private bool mGlobalPostActive = false;
	private float mExposure = 1.0f;
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
	private bool mViewCulling = false;
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

	public this(IDevice device, uint32 framesInFlight)
	{
		mDevice = device;
		mFramesInFlight = (framesInFlight < 1) ? 1 : framesInFlight;
	}

	/// Renders rather than ticks, so it runs after everything that moves has moved.
	public override int32 UpdateOrder => 1000;

	/// Ready once the frame exists. Everything below it is inert until then, which is what a
	/// machine with no shaders gets rather than a crash.
	public bool IsReady => mFrame != null;

	public IDevice Device => mDevice;
	public ShaderSystem Shaders => mShaders;
	public uint32 FramesInFlight => mFramesInFlight;

	// ---- extension seam --------------------------------------------------------------------

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

	/// The engine's shader root, when nothing overrides it.
	private const String cEngineShaderRoot = "Shaders";

	protected override void OnInit()
	{
		// The host settles the pack versus compiler question: a cooked pack beside the
		// executable means no compiler is needed, and otherwise it stands one up over the
		// shader root with hot reload. Every consumer uses the same host.
		if (mShaderHost.Initialize(mDevice, cEngineShaderRoot) case .Err)
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
	}
}
