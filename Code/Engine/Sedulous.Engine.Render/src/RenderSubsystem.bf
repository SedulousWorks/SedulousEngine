using System;
using System.Collections;
using Sedulous.Core;
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
	/// BORROWED from the pass set; null where image based lighting is unavailable.
	private IBLSystem mIblSystem = null;

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
	/// BORROWED from the pass set; null means multisampling is unavailable.
	private MsaaResolvePass mMsaaResolvePass = null;
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
}
