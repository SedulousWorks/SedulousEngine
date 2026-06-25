namespace Sedulous.Engine.App;

using System;
using System.Collections;
using System.Diagnostics;
using System.IO;
using Sedulous.RHI;
using Sedulous.RHI.Validation;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;
using Sedulous.Runtime;
using Sedulous.Resources;
using Sedulous.VFS;
using Sedulous.VFS.Disk;
using Sedulous.Jobs;
using Sedulous.Serialization.OpenDDL;
using Sedulous.Profiler;
using Sedulous.Shaders;
using Sedulous.Engine;
using Sedulous.Engine.Input;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.UI;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;
using Sedulous.Engine.Render;
using Sedulous.Renderer;
using Sedulous.Images;

/// Full engine application base class.
/// Creates a Context with standard subsystems and manages the main loop.
/// Game logic lives in components and subsystems, not in app overrides.
///
/// The app creates the RHI device and window, then passes them to subsystems.
/// The application owns swapchain, output textures, frame pacing, and presentation.
/// RenderSubsystem implements ISceneRenderer and focuses purely on scene rendering.
abstract class EngineApplication : IDisposable, IApplicationHost
{
	private const int MAX_FRAMES_IN_FLIGHT = 2;

	// Platform
	protected IShell mShell;
	protected IWindow mWindow;
	protected IBackend mBackend;
	protected IDevice mDevice;

	// Engine
	protected Context mContext;
	private Sedulous.Core.Logging.Abstractions.ILogger mLogger;
	private ResourceSystem mResourceSystem;

	/// The resource system (application-owned, shared with subsystems).
	public ResourceSystem ResourceSystem => mResourceSystem;

	// Presentation (owned by application)
	private ISwapChain mSwapChain;
	private IQueue mGraphicsQueue;
	private ICommandPool[MAX_FRAMES_IN_FLIGHT] mCommandPools;
	private IFence mFrameFence;
	private uint64 mNextFenceValue = 1;
	private uint64[MAX_FRAMES_IN_FLIGHT] mFrameFenceValues;
	private int32 mFrameIndex;

	// Output targets (application-owned, Pipeline-sized). The pipeline
	// renders into mColorTarget at (mTargetWidth, mTargetHeight); the
	// final blit stretches / letterboxes / crops onto the swapchain
	// per mSettings.FitMode.
	private ITexture mColorTarget;
	private ITextureView mColorTargetView;
	private uint32 mTargetWidth;
	private uint32 mTargetHeight;
	private BlitHelper mBlitHelper;

	// Cached renderer interfaces
	private ISceneRenderer mSceneRenderer;
	private IScreenRenderer mScreenRenderer;

	// Assets
	private String mAssetDirectory = new .() ~ delete _;
	private String mAssetCacheDirectory = new .() ~ delete _;
	// Per-project assets dir, derived from RuntimeDirectory (cwd's parent + "/assets").
	// Distinct from mAssetDirectory which is the engine's discovered Assets root
	// (shaders / fonts shipped with the engine). Apps following the standard
	// layout (exe project nested under project root with sibling "assets/"
	// folder) get this for free; others can override via Settings or by
	// reaching past this field. Empty when the convention doesn't apply.
	private String mProjectAssetDirectory = new .() ~ delete _;

	// Builtin asset mount + identity index (builtin:// scheme).
	// The mount exposes raw bytes in mAssetDirectory; the index, if a
	// "builtin.registry" file is present, maps GUIDs to URIs.
	private FileSystemMount mBuiltinMount ~ delete _;
	private InMemoryResourceIndex mBuiltinIndex ~ delete _;

	// Default font service for the engine UI. Loads Roboto through the
	// `builtin://` mount and is handed to the UI subsystem before it
	// starts. Owned by the application so the subsystem can stay
	// purely non-owning.
	private TrueTypeFontService mFontService ~ delete _;

	/// The default IFontService used by the engine UI. Derived apps can
	/// read this (e.g., to register additional font sizes) but should not
	/// delete it.
	public IFontService FontService => mFontService;

	// Runtime directory (working directory at startup - where the application project lives)
	private String mRuntimeDirectory = new .() ~ delete _;

	// Shader system (shared by all subsystems that need it)
	private ShaderSystem mShaderSystem;

	// Settings
	protected EngineAppSettings mSettings;
	protected bool mIsRunning = false;
	private bool mCleanedUp = false;

	// Application module (optional). When set, the engine invokes its lifecycle
	// hooks alongside the protected OnConfigure / OnStartup / OnShutdown
	// virtuals - module first in each case. Migration target: new games
	// implement IApplicationModule and a thin Program.bf wires it up, instead
	// of subclassing EngineApplication.
	private IApplicationModule mModule;
	private EngineUISubsystem mUISub;

	// Timing
	private Stopwatch mStopwatch = new .() ~ delete _;
	private float mLastFrameTime;
	private float mFixedTimeStep = 1.0f / 60.0f;
	private float mFixedUpdateAccumulator = 0.0f;

	// Profiling
	private float mInitTimeMs;
	private int32 mMaxFixedStepsPerFrame = 8;

	/// Set via RequestProfilePrint() from any code running inside the
	/// current frame's update path. The run loop checks this flag after
	/// SProfiler.EndFrame() and prints the just-completed frame, then
	/// clears the flag. Useful for "print right when X happens" cases
	/// (asset spawn, big state transition) that are hard to catch via
	/// the manual P hotkey.
	private bool mProfilePrintRequested = false;

	// Screenshot
	private bool mScreenshotRequested = false;
	private String mScreenshotPath ~ delete _;
	private IBuffer mScreenshotBuffer;

	/// The framework context.
	public Context Context => mContext;

	/// The shell.
	public IShell Shell => mShell;

	// IApplicationHost input passthrough. Standalone uses the shell devices
	// directly; the editor's GameEditorPage wraps them in viewport-scoped
	// adapters so coordinates / focus gating Just Work for module gameplay
	// code that's portable between both hosts.
	public Sedulous.Shell.Input.IMouse Mouse => mShell?.InputManager?.Mouse;
	public Sedulous.Shell.Input.IKeyboard Keyboard => mShell?.InputManager?.Keyboard;
	public Sedulous.Shell.Input.IGamepad GetGamepad(int32 index) =>
		mShell?.InputManager?.GetGamepad(index);

	/// The main window.
	public IWindow Window => mWindow;

	/// The RHI device.
	public IDevice Device => mDevice;

	/// Image writer for screenshots. Set by the application (e.g. SDLImageWriter).
	/// The discovered assets directory path.
	public StringView AssetDirectory => mAssetDirectory;

	/// The discovered asset cache directory path.
	public StringView AssetCacheDirectory => mAssetCacheDirectory;

	/// Per-project assets directory. For apps following the convention
	/// "exe project nested under project root with sibling assets/ folder"
	/// this resolves to `<parent of RuntimeDirectory>/assets`. Empty
	/// otherwise. Distinct from AssetDirectory (engine-shipped Assets).
	public StringView ProjectAssetDirectory => mProjectAssetDirectory;

	/// The runtime directory (working directory at startup).
	/// When running from IDE, this is the project directory (e.g., Code/Projects/TowerDefense).
	public StringView RuntimeDirectory => mRuntimeDirectory;

	/// The shared shader system.
	public ShaderSystem ShaderSystem => mShaderSystem;

	/// Optional application module. Hooks are invoked alongside the
	/// OnConfigure / OnStartup / OnShutdown virtuals (module first). Must be
	/// set before Run().
	public IApplicationModule Module
	{
		get => mModule;
		set => mModule = value;
	}

	/// Runs the application.
	public int Run(EngineAppSettings settings)
	{
		mSettings = settings;

		// Discover asset directories
		DiscoverAssetDirectories();

		if (!InitializePlatform())
			return -1;

		// Shader system
		let shaderDir = scope String();
		Path.InternalCombine(shaderDir, mAssetDirectory, "shaders");
		let cacheDir = scope String();
		Path.InternalCombine(cacheDir, mAssetCacheDirectory, "shaders");

		SProfiler.Initialize();

		mShaderSystem = new ShaderSystem();
		StringView[1] shaderPaths = .(shaderDir);
		mShaderSystem.Initialize(mDevice, shaderPaths, mSettings.EnableShaderCache ? cacheDir : default);

		let initTimer = scope Stopwatch();
		initTimer.Start();

		// Core systems (application-owned, not Context)
		JobSystem.Initialize();
		mLogger = new Sedulous.Core.Logging.Console.ConsoleLogger(.Information);
		mResourceSystem = new ResourceSystem(mLogger);
		mResourceSystem.EnableHotReload();
		mResourceSystem.SetSerializerProvider(new OpenDDLSerializerProvider());
		mResourceSystem.Startup();

		// Auto-load per-project render settings if the file is present in
		// the project assets dir. Values override the in-code defaults so
		// the editor's Project Settings panel writes a file standalone
		// picks up on next boot. Missing file is silent - apps without a
		// project assets dir (sandbox, samples) just see in-code defaults.
		if (!mProjectAssetDirectory.IsEmpty)
		{
			var projectSettings = ProjectSettings()
			{
				TargetWidth = mSettings.TargetWidth,
				TargetHeight = mSettings.TargetHeight,
				FitMode = mSettings.FitMode
			};
			if (ProjectSettingsIO.Load(mProjectAssetDirectory,
				mResourceSystem.SerializerProvider, ref projectSettings) case .Ok)
			{
				mSettings.TargetWidth = projectSettings.TargetWidth;
				mSettings.TargetHeight = projectSettings.TargetHeight;
				mSettings.FitMode = projectSettings.FitMode;
			}
		}

		// Load builtin asset registry (primitives, materials, skies)
		LoadBuiltinRegistry();

		// Create context
		mContext = new Context();

		// Register standard subsystems
		RegisterDefaultSubsystems();

		// Application module Configure runs before the legacy OnConfigure
		// virtual so subclasses can still override / patch what the module
		// set up during the transition period.
		mModule?.Configure(this);

		// Let derived class add custom subsystems
		OnConfigure(mContext);

		// Start up
		mContext.Startup();

		// Initialize presentation resources (after context startup so device is ready)
		InitializePresentation();

		// Cache renderer interfaces from registered subsystems
		mSceneRenderer = mContext.GetSubsystemByInterface<ISceneRenderer>();
		mScreenRenderer = mContext.GetSubsystemByInterface<IScreenRenderer>();

		mModule?.OnStartup(this);

		OnStartup();

		// Standalone hosts always enter runtime mode immediately before the
		// main loop. Editor hosts gate this on a Play button instead.
		mModule?.OnLaunch(this);

		initTimer.Stop();
		mInitTimeMs = (float)initTimer.Elapsed.TotalMilliseconds;

		// Main loop
		mStopwatch.Start();
		mIsRunning = true;

		while (mIsRunning && mShell.IsRunning)
		{
			SProfiler.BeginFrame();

			mShell.ProcessEvents();

			float currentTime = (float)mStopwatch.Elapsed.TotalSeconds;
			float deltaTime = currentTime - mLastFrameTime;
			mLastFrameTime = currentTime;

			// Process completed async jobs and resource loads before frame starts.
			JobSystem.ProcessCompletions();
			mResourceSystem.Update();

			// Push live window dimensions + DPI scale into the UI subsystem
			// so its per-frame Update reads current values. Standalone: UI
			// canvas always tracks the window 1:1.
			if (mUISub != null && mWindow != null)
			{
				mUISub.RenderSize = .((float)mWindow.Width, (float)mWindow.Height);
				mUISub.DpiScale = mWindow.ContentScale;
			}

			// BeginFrame runs first - resets per-frame state, polls input,
			// and initializes components created last frame.
			mContext.BeginFrame(deltaTime);

			// Fixed update loop - runs after BeginFrame so newly initialized
			// components (physics bodies, etc.) are ready for simulation.
			mFixedUpdateAccumulator += deltaTime;
			int32 fixedSteps = 0;
			while (mFixedUpdateAccumulator >= mFixedTimeStep && fixedSteps < mMaxFixedStepsPerFrame)
			{
				mContext.FixedUpdate(mFixedTimeStep);
				mModule?.OnFixedUpdate(this, mFixedTimeStep);
				mFixedUpdateAccumulator -= mFixedTimeStep;
				fixedSteps++;
			}
			if (mFixedUpdateAccumulator > mFixedTimeStep * 2)
				mFixedUpdateAccumulator = mFixedTimeStep * 2;

			mContext.Update(deltaTime);
			OnUpdate(deltaTime);
			mModule?.OnUpdate(this, deltaTime);
			mContext.PostUpdate(deltaTime);
			mContext.EndFrame();

			// Presentation - application owns swapchain, output targets, blit, overlays, present.
			PresentFrame();

			SProfiler.EndFrame();

			// Shift+P: print profile frame
			let keyboard = mShell.InputManager.Keyboard;
			if (keyboard.IsKeyPressed(.P) /*&& keyboard.Modifiers.HasFlag(.Shift)*/)
				PrintProfileFrame();

			// Programmatic profile print request (e.g. set by AddSphereBatch
			// in the stress test so the spawn frame's breakdown is captured
			// without racing the user's P hotkey).
			if (mProfilePrintRequested)
			{
				mProfilePrintRequested = false;
				PrintProfileFrame();
			}
		}

		Shutdown();
		mContext.Shutdown();
		Cleanup();

		return 0;
	}

	/// Request the application to exit.
	public void Exit()
	{
		mIsRunning = false;
	}

	// ==================== Profiling ====================

	/// Request that the current frame's profile be printed after
	/// SProfiler.EndFrame() runs. Call from inside OnUpdate (or any
	/// other code in the frame's update path) when something interesting
	/// happens and you want the breakdown without timing the P hotkey.
	public void RequestProfilePrint()
	{
		mProfilePrintRequested = true;
	}

	private void PrintProfileFrame()
	{
		let frame = SProfiler.GetCompletedFrame();

		Console.WriteLine("=== Profile ===");
		Console.WriteLine("Init: {0:F2}ms", mInitTimeMs);
		Console.WriteLine("Frame {0}: {1:F2}ms ({2} samples)", frame.FrameNumber, frame.FrameDurationMs, frame.SampleCount);

		// Sort by start time so parents appear before children
		let sorted = new List<ProfileSample>(frame.Samples.Count);
		defer delete sorted;
		for (let sample in frame.Samples)
			sorted.Add(sample);
		sorted.Sort(scope (a, b) => a.StartTimeUs <=> b.StartTimeUs);

		for (let sample in sorted)
		{
			let indent = scope String();
			for (int d = 0; d < sample.Depth; d++)
				indent.Append("  ");
			Console.WriteLine("  {0}{1}: {2:F3}ms", indent, sample.Name, sample.DurationMs);
		}

		Console.WriteLine("================");
	}

	// ==================== Overrides ====================

	/// Override to register custom subsystems.
	protected virtual void OnConfigure(Context context) { }

	/// Override to set up initial scene, load assets, etc.
	/// All subsystems are initialized at this point.
	protected virtual void OnStartup() { }

	/// Override for per-frame game logic. Called after Context.Update and before
	/// Context.PostUpdate. Used for one-off debug drawing, input polling, etc.
	protected virtual void OnUpdate(float deltaTime) { }

	/// Override for cleanup before shutdown.
	protected virtual void OnShutdown() { }

	/// Override to release GPU resources after device WaitIdle but before subsystems are destroyed.
	protected virtual void OnCleanup() { }

	// ==================== Default Subsystems ====================

	protected virtual void RegisterDefaultSubsystems()
	{
		let inputSub = new InputSubsystem();
		inputSub.SetInputManager(mShell.InputManager);
		mContext.RegisterSubsystem(inputSub);                    // -900
		mContext.RegisterSubsystem(new SceneSubsystem(mResourceSystem));        // -500
		mContext.RegisterSubsystem(new PhysicsSubsystem());                  // -100
		mContext.RegisterSubsystem(new AnimationSubsystem(mResourceSystem));  //  100
		mContext.RegisterSubsystem(new AudioSubsystem(mResourceSystem));      //  200
		mContext.RegisterSubsystem(new NavigationSubsystem());   //  300
		// Create the default font service and pre-load Roboto through the
		// `builtin://` mount. The UI subsystem doesn't own the service -
		// the application does - so it stays alive across subsystem
		// shutdown / restart and can be shared with other consumers.
		mFontService = new TrueTypeFontService(mBuiltinMount);
		let robotoLocator = "fonts/roboto/Roboto-Regular.ttf";
		if (mBuiltinMount != null && mBuiltinMount.Exists(robotoLocator))
		{
			mFontService.LoadFont("Roboto", robotoLocator, .() { PixelHeight = 16 });
			mFontService.LoadFont("Roboto", robotoLocator, .() { PixelHeight = 24 });
		}

		let uiSub = new EngineUISubsystem();
		uiSub.Device = mDevice;
		uiSub.Shell = mShell;
		uiSub.ShaderSystem = mShaderSystem;
		// UI overlays render onto the swapchain after the blit (no target-
		// resolution integration yet - the UI lays out in window space and
		// overlays on top of the letterbox, not inside it). Re-enabling
		// target-resolution UI needs a coord-transform adapter for input
		// to remain consistent; deferred.
		uiSub.OutputFormat = mSettings.SwapChainFormat;
		uiSub.FrameCount = MAX_FRAMES_IN_FLIGHT;
		uiSub.FontService = mFontService;
		// Standalone: UI canvas IS the window. Seed initial size + scale here
		// so OnStartup's dialog-centering path picks them up; the per-frame
		// sync below the main loop keeps them tracking window resizes.
		uiSub.RenderSize = .((float)mWindow.Width, (float)mWindow.Height);
		uiSub.DpiScale = mWindow.ContentScale;
		mUISub = uiSub;
		mContext.RegisterSubsystem(uiSub);                      //  400

		let renderSub = new RenderSubsystem(mResourceSystem);
		renderSub.Device = mDevice;
		renderSub.Window = mWindow;
		renderSub.ShaderSystem = mShaderSystem;
		renderSub.AssetDirectory = mAssetDirectory;
		mContext.RegisterSubsystem(renderSub);                   //  500
	}

	// ==================== Presentation ====================

	private void InitializePresentation()
	{
		if (mDevice == null || mSurface == null || mWindow == null)
			return;

		// Graphics queue
		mGraphicsQueue = mDevice.GetQueue(.Graphics);

		// Swapchain
		SwapChainDesc swapDesc = .()
		{
			Width = (uint32)mWindow.Width,
			Height = (uint32)mWindow.Height,
			Format = mSettings.SwapChainFormat,
			PresentMode = mSettings.PresentMode
		};
		if (mDevice.CreateSwapChain(mSurface, swapDesc) case .Ok(let swapChain))
			mSwapChain = swapChain;

		// Per-frame command pools
		for (int i = 0; i < MAX_FRAMES_IN_FLIGHT; i++)
		{
			if (mDevice.CreateCommandPool(.Graphics) case .Ok(let pool))
				mCommandPools[i] = pool;
		}

		// Frame fence
		if (mDevice.CreateFence(0) case .Ok(let fence))
			mFrameFence = fence;

		// Output target (HDR). When TargetWidth/Height are zero (default),
		// the target tracks the window 1:1 and ResizeSwapChain recreates
		// it on resize. When non-zero, the target is fixed at that
		// resolution and survives swapchain resizes - the blit handles
		// the size mismatch via FitMode.
		mTargetWidth = mSettings.TargetWidth > 0 ? (uint32)mSettings.TargetWidth : (uint32)mWindow.Width;
		mTargetHeight = mSettings.TargetHeight > 0 ? (uint32)mSettings.TargetHeight : (uint32)mWindow.Height;
		CreateOutputTarget(mTargetWidth, mTargetHeight);

		// Blit helper (fullscreen triangle to tonemap HDR -> swapchain)
		if (mShaderSystem != null)
		{
			mBlitHelper = new BlitHelper();
			mBlitHelper.Initialize(mDevice, mSettings.SwapChainFormat, mShaderSystem);
		}
	}

	private void CreateOutputTarget(uint32 width, uint32 height)
	{
		TextureDesc texDesc = .()
		{
			Label = "Pipeline Output",
			Width = width,
			Height = height,
			Depth = 1,
			Format = .RGBA16Float,
			Usage = .RenderTarget | .Sampled | .CopySrc,
			Dimension = .Texture2D,
			MipLevelCount = 1,
			ArrayLayerCount = 1,
			SampleCount = 1
		};

		if (mDevice.CreateTexture(texDesc) case .Ok(let tex))
			mColorTarget = tex;

		TextureViewDesc viewDesc = .()
		{
			Label = "Pipeline Output View",
			Format = .RGBA16Float,
			Dimension = .Texture2D
		};

		if (mDevice.CreateTextureView(mColorTarget, viewDesc) case .Ok(let view))
			mColorTargetView = view;
	}

	private void DestroyOutputTarget()
	{
		if (mDevice == null) return;
		if (mColorTargetView != null)
			mDevice.DestroyTextureView(ref mColorTargetView);
		if (mColorTarget != null)
			mDevice.DestroyTexture(ref mColorTarget);
	}

	private void PresentFrame()
	{
		if (mSwapChain == null || mDevice == null || mWindow.State == .Minimized)
			return;

		// Frame pacing - wait for this frame slot's previous GPU work
		using (SProfiler.Begin("GPU.WaitFence"))
		{
			if (mFrameFenceValues[mFrameIndex] > 0)
				mFrameFence.Wait(mFrameFenceValues[mFrameIndex]);
		}

		mCommandPools[mFrameIndex].Reset();

		let pool = mCommandPools[mFrameIndex];
		var encoder = pool.CreateEncoder().Value;

		// Transition output target from ShaderRead (post-process left it there)
		// to RenderTarget before clearing.
		encoder.TransitionTexture(mColorTarget, .ShaderRead, .RenderTarget);

		// Clear output target via render pass with LoadOp.Clear
		{
			ColorAttachment[1] clearAttachments = .(.()
			{
				View = mColorTargetView,
				LoadOp = .Clear,
				StoreOp = .Store,
				ClearValue = .(0, 0, 0, 1)
			});
			RenderPassDesc clearDesc = .() { ColorAttachments = .(clearAttachments) };
			let clearPass = encoder.BeginRenderPass(clearDesc);
			clearPass.End();
		}

		// Scene rendering (ISceneRenderer - implemented by RenderSubsystem)
		if (mSceneRenderer != null)
		{
			mSceneRenderer.BeginRendering(encoder, mFrameIndex);

			let sceneSub = mContext.GetSubsystem<Sedulous.Engine.SceneSubsystem>();
			if (sceneSub != null)
			{
				for (let scene in sceneSub.ActiveScenes)
				{
					mSceneRenderer.RenderScene(scene, encoder, mColorTarget, mColorTargetView,
						mTargetWidth, mTargetHeight, mFrameIndex);
					break; // Render only the first/active scene for now
				}
			}

			mSceneRenderer.EndRendering();
		}

		// Acquire swapchain image
		using (SProfiler.Begin("GPU.AcquireImage"))
		{
			if (mSwapChain.AcquireNextImage() case .Err)
			{
				pool.DestroyEncoder(ref encoder);
				ResizeSwapChain();
				return;
			}
		}

		// Transition swapchain from Present to RenderTarget before use
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Present, .RenderTarget);

		// Blit scene output -> swapchain
		using (SProfiler.Begin("Blit"))
			BlitToSwapchain(encoder);

		// Window-space overlays (ScreenUI, debug HUD, etc.) - the screen
		// renderer opens a single shared render pass and walks every
		// registered IScreenOverlay in OverlayOrder.
		if (mScreenRenderer != null)
		{
			using (SProfiler.Begin("Overlays"))
				mScreenRenderer.RenderOverlays(encoder, mSwapChain.CurrentTextureView,
					mSwapChain.Width, mSwapChain.Height, mFrameIndex);
		}

		// Screenshot capture: copy swapchain to readback buffer before present
		let screenshotThisFrame = mScreenshotRequested;
		if (screenshotThisFrame)
		{
			mScreenshotRequested = false;
			EnsureScreenshotBuffer(mSwapChain.Width, mSwapChain.Height);
			if (mScreenshotBuffer != null)
			{
				encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .CopySrc);
				BufferTextureCopyRegion region = .()
				{
					BufferOffset = 0,
					BytesPerRow = mSwapChain.Width * 4,
					RowsPerImage = 0,
					TextureMipLevel = 0,
					TextureArrayLayer = 0,
					TextureExtent = .(mSwapChain.Width, mSwapChain.Height, 1)
				};
				encoder.CopyTextureToBuffer(mSwapChain.CurrentTexture, mScreenshotBuffer, region);
				encoder.TransitionTexture(mSwapChain.CurrentTexture, .CopySrc, .RenderTarget);
			}
		}

		// Transition swapchain to present
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();

		// Submit with fence signaling
		using (SProfiler.Begin("GPU.Submit"))
		{
			mFrameFenceValues[mFrameIndex] = mNextFenceValue++;
			ICommandBuffer[1] bufs = .(commandBuffer);
			mGraphicsQueue.Submit(bufs, mFrameFence, mFrameFenceValues[mFrameIndex]);
		}

		// Present
		using (SProfiler.Begin("GPU.Present"))
		{
			if (mSwapChain.Present(mGraphicsQueue) case .Err)
				ResizeSwapChain();
		}

		// Complete screenshot: wait for GPU, read back, save
		if (screenshotThisFrame && mScreenshotBuffer != null)
		{
			mFrameFence.Wait(mFrameFenceValues[mFrameIndex]);
			SaveScreenshot(mSwapChain.Width, mSwapChain.Height);
		}

		pool.DestroyEncoder(ref encoder);
		mFrameIndex = (mFrameIndex + 1) % MAX_FRAMES_IN_FLIGHT;
	}

	// ==================== Screenshot ====================

	/// Requests a screenshot to be captured at the end of the current frame.
	/// The image is saved to the specified path (PNG format).
	public void CaptureScreenshot(StringView path)
	{
		mScreenshotRequested = true;
		delete mScreenshotPath;
		mScreenshotPath = new String(path);
	}

	/// Ensures the readback buffer exists and is large enough for the given dimensions.
	private void EnsureScreenshotBuffer(uint32 width, uint32 height)
	{
		let requiredSize = (uint64)(width * height * 4);
		if (mScreenshotBuffer != null && mScreenshotBuffer.Size >= requiredSize)
			return;

		if (mScreenshotBuffer != null)
			mDevice.DestroyBuffer(ref mScreenshotBuffer);

		BufferDesc desc = .()
		{
			Label = "Screenshot Readback",
			Size = requiredSize,
			Usage = .CopyDst,
			Memory = .GpuToCpu
		};

		if (mDevice.CreateBuffer(desc) case .Ok(let buf))
			mScreenshotBuffer = buf;
	}

	/// Reads the screenshot readback buffer and saves to file.
	private void SaveScreenshot(uint32 width, uint32 height)
	{
		if (mScreenshotPath == null || mScreenshotBuffer == null)
			return;

		let dataSize = (int)(width * height * 4);
		let pixelData = new uint8[dataSize];
		defer delete pixelData;

		TransferHelper.ReadMappedBuffer(mScreenshotBuffer, 0,
			Span<uint8>(pixelData.Ptr, dataSize));

		// Swapchain is BGRA8 - create image with that format.
		// The IImageWriter implementation handles format conversion if needed.
		let image = scope Image(width, height, .BGRA8, pixelData);

		if (ImageWriterFactory.SaveImage(image, mScreenshotPath, .PNG) case .Ok)
			Console.WriteLine("Screenshot saved: {}", mScreenshotPath);
		else
			Console.WriteLine("ERROR: Failed to save screenshot: {}", mScreenshotPath);
	}

	// ==================== Blit ====================

	private void BlitToSwapchain(ICommandEncoder encoder)
	{
		if (mColorTargetView == null || mBlitHelper == null || !mBlitHelper.IsReady)
			return;

		// Color target is already transitioned to ShaderRead by RenderScene.
		// Clear-load the swapchain so Letterbox produces black bars on
		// whichever axis the content doesn't fill. Stretch and Crop fully
		// cover the swapchain so the clear is harmless.
		ColorAttachment[1] colorAttachments = .(.()
		{
			View = mSwapChain.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = .(0, 0, 0, 1)
		});

		RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };
		let renderPass = encoder.BeginRenderPass(passDesc);

		int32 x, y;
		uint32 w, h;
		ComputeBlitRect(mTargetWidth, mTargetHeight,
			mSwapChain.Width, mSwapChain.Height, mSettings.FitMode,
			out x, out y, out w, out h);
		mBlitHelper.Blit(renderPass, mColorTargetView, x, y, w, h, mFrameIndex);

		renderPass.End();
	}

	/// Maps the pipeline output rect into the swapchain rect per FitMode.
	/// Letterbox shrinks the content to fit while preserving aspect; Crop
	/// grows the content to cover while preserving aspect (overflow gets
	/// scissored); Stretch fills the swapchain ignoring aspect.
	private static void ComputeBlitRect(uint32 srcW, uint32 srcH, uint32 dstW, uint32 dstH,
		FitMode fitMode, out int32 x, out int32 y, out uint32 w, out uint32 h)
	{
		switch (fitMode)
		{
		case .Stretch:
			x = 0; y = 0; w = dstW; h = dstH;
		case .Letterbox:
			let srcAspect = (float)srcW / (float)srcH;
			let dstAspect = (float)dstW / (float)dstH;
			if (srcAspect > dstAspect)
			{
				// Source wider than dest: fit width, bars on top/bottom.
				w = dstW;
				h = (uint32)((float)dstW / srcAspect);
				x = 0;
				y = (int32)((dstH - h) / 2);
			}
			else
			{
				// Source taller than dest: fit height, bars on sides.
				h = dstH;
				w = (uint32)((float)dstH * srcAspect);
				y = 0;
				x = (int32)((dstW - w) / 2);
			}
		case .Crop:
			let srcAspect = (float)srcW / (float)srcH;
			let dstAspect = (float)dstW / (float)dstH;
			if (srcAspect > dstAspect)
			{
				// Source wider than dest: fit height, content overflows
				// the left/right edges; scissor on the BlitHelper side
				// clips to the visible rect.
				h = dstH;
				w = (uint32)((float)dstH * srcAspect);
				y = 0;
				x = (int32)dstW / 2 - (int32)w / 2;
			}
			else
			{
				w = dstW;
				h = (uint32)((float)dstW / srcAspect);
				x = 0;
				y = (int32)dstH / 2 - (int32)h / 2;
			}
		}
	}

	private void ResizeSwapChain()
	{
		if (mDevice == null || mSwapChain == null) return;
		mDevice.WaitIdle();
		mSwapChain.Resize((uint32)mWindow.Width, (uint32)mWindow.Height);

		// Recreate the output target only when it's tracking the window
		// (no fixed target resolution configured). With a fixed target,
		// the pipeline renders at the same resolution regardless of
		// window size and the blit handles the visual fit.
		if (mSettings.TargetWidth <= 0 && mSettings.TargetHeight <= 0)
		{
			mTargetWidth = (uint32)mWindow.Width;
			mTargetHeight = (uint32)mWindow.Height;
			DestroyOutputTarget();
			CreateOutputTarget(mTargetWidth, mTargetHeight);
		}
	}

	// ==================== Platform Init ====================

	private bool InitializePlatform()
	{
		// Shell
		let shell = new SDL3Shell();
		if (shell.Initialize() case .Err)
		{
			delete shell;
			return false;
		}
		mShell = shell;

		// Backend + Device
		if (!CreateBackend())
			return false;
		if (!CreateDevice())
			return false;

		// Window
		let windowSettings = WindowSettings()
		{
			Title = scope String(mSettings.Title),
			Width = mSettings.Width,
			Height = mSettings.Height,
			Resizable = mSettings.Resizable,
			Bordered = true
		};

		if (mShell.WindowManager.CreateWindow(windowSettings) not case .Ok(let window))
			return false;
		mWindow = window;

		mShell.WindowManager.OnWindowEvent.Subscribe(new => HandleWindowEvent);

		// Surface (needed by application for swapchain creation)
		if (mBackend.CreateSurface(mWindow.NativeHandle) not case .Ok(let surface))
			return false;
		mSurface = surface;

		return true;
	}

	private ISurface mSurface;

	private bool CreateBackend()
	{
		Result<IBackend> result = .Err;
		switch (mSettings.Backend)
		{
		case .Vulkan:
			if (Sedulous.RHI.Vulkan.VulkanBackend.Create(mSettings.EnableValidation) case .Ok(let vkBackend))
				result = mSettings.EnableValidation ? .Ok(new ValidatedBackend(vkBackend)) : .Ok((IBackend)vkBackend);
		case .DX12:
			if (Sedulous.RHI.DX12.DX12Backend.Create(mSettings.EnableValidation) case .Ok(let dxBackend))
				result = mSettings.EnableValidation ? .Ok(new ValidatedBackend(dxBackend)) : .Ok((IBackend)dxBackend);
		}

		if (result case .Ok(let backend))
		{
			mBackend = backend;
			return true;
		}
		return false;
	}

	private bool CreateDevice()
	{
		IBackend innerBackend = mBackend;
		if (let validated = mBackend as ValidatedBackend)
			innerBackend = validated.Inner;

		List<IAdapter> adapters = scope .();
		innerBackend.EnumerateAdapters(adapters);
		if (adapters.IsEmpty)
			return false;

		let adapter = adapters[0];
		let adapterInfo = adapter.GetInfo();
		defer delete adapterInfo;
		mLogger?.LogInformation("GPU: {} ({})", adapterInfo.Name, adapterInfo.Type);

		if (adapter.CreateDevice(.() { DeviceValidationEnabled = mSettings.EnableValidation }) case .Ok(let rawDevice))
		{
			mDevice = mSettings.EnableValidation ? new ValidatedDevice(rawDevice) : rawDevice;
			return true;
		}
		return false;
	}

	private void HandleWindowEvent(IWindow window, WindowEvent evt)
	{
		if (window != mWindow)
			return;

		switch (evt.Type)
		{
		case .CloseRequested:
			Exit();
		case .Resized:
			// Resize swapchain and output targets
			ResizeSwapChain();

			// Notify subsystems (pipeline resize, etc.)
			if (mContext != null)
			{
				for (let subsystem in mContext.Subsystems)
				{
					if (let windowAware = subsystem as IWindowAware)
						windowAware.OnWindowResized(window, window.Width, window.Height);
				}
			}
		default:
		}
	}

	/// Sets up the builtin asset mount and (if present) its identity index.
	/// Provides builtin:// scheme resources (primitives, materials, skies)
	/// generated by the editor.
	private void LoadBuiltinRegistry()
	{
		if (mAssetDirectory.IsEmpty)
			return;

		// Always mount the asset directory under "builtin://" so resources
		// can be opened by URI even without an identity index.
		mBuiltinMount = new FileSystemMount(mAssetDirectory);
		mResourceSystem.Mount("builtin", mBuiltinMount);

		// Optional identity index: maps GUIDs to URIs for ResourceRef resolution.
		let registryPath = scope String();
		Path.InternalCombine(registryPath, mAssetDirectory, "builtin.registry");
		if (!File.Exists(registryPath))
			return;

		let stream = scope FileStream();
		if (stream.Open(registryPath, .Read, .Read) case .Err)
			return;

		mBuiltinIndex = new InMemoryResourceIndex();
		if (mBuiltinIndex.DeserializeFrom(stream) case .Ok)
		{
			mResourceSystem.AddIndex(mBuiltinIndex);
		}
		else
		{
			delete mBuiltinIndex;
			mBuiltinIndex = null;
		}
	}

	private void Shutdown()
	{
		if (mDevice != null)
			mDevice.WaitIdle();

		// Standalone hosts leave runtime mode at exit. Editor hosts call
		// OnExit when the user stops a play session.
		mModule?.OnExit(this);

		mModule?.OnShutdown(this);

		OnShutdown();
	}

	private void Cleanup()
	{
		if (mCleanedUp)
			return;
		mCleanedUp = true;

		OnCleanup();

		SProfiler.Shutdown();

		// Context must be deleted before device - subsystems hold GPU resources
		delete mContext;
		mContext = null;

		// Unregister builtin mount + index before resource system shutdown
		if (mResourceSystem != null)
		{
			if (mBuiltinIndex != null)
				mResourceSystem.RemoveIndex(mBuiltinIndex);
			if (mBuiltinMount != null)
				mResourceSystem.Unmount("builtin");
		}

		// Shutdown core systems (after context - subsystems may have used them)
		mResourceSystem.Shutdown();
		delete mResourceSystem;
		mResourceSystem = null;
		delete mLogger;
		mLogger = null;
		JobSystem.Shutdown();

		// Destroy screenshot readback buffer
		if (mScreenshotBuffer != null)
			mDevice.DestroyBuffer(ref mScreenshotBuffer);

		// Destroy presentation resources (after context - subsystems may reference device)
		if (mBlitHelper != null)
		{
			mBlitHelper.Dispose();
			delete mBlitHelper;
			mBlitHelper = null;
		}
		DestroyOutputTarget();

		for (int i = 0; i < MAX_FRAMES_IN_FLIGHT; i++)
		{
			if (mCommandPools[i] != null)
				mDevice.DestroyCommandPool(ref mCommandPools[i]);
		}
		if (mFrameFence != null)
			mDevice.DestroyFence(ref mFrameFence);
		if (mSwapChain != null)
			mDevice.DestroySwapChain(ref mSwapChain);

		mShaderSystem?.Dispose();
		delete mShaderSystem;

		// Surface is owned by app, destroyed here
		if (mSurface != null) mDevice.DestroySurface(ref mSurface);

		if (mWindow != null)
			mShell.WindowManager.DestroyWindow(mWindow);

		if (mDevice != null)
		{
			mDevice.Destroy();
			if (let validated = mDevice as ValidatedDevice)
			{
				delete validated.Inner;
				delete validated;
			}
			else
				delete mDevice;
			mDevice = null;
		}

		if (mBackend != null)
		{
			mBackend.Destroy();
			if (let validated = mBackend as ValidatedBackend)
			{
				delete validated.Inner;
				delete validated;
			}
			else
				delete mBackend;
			mBackend = null;
		}

		if (mShell != null)
		{
			mShell.Shutdown();
			delete mShell;
			mShell = null;
		}
	}

	public void Dispose()
	{
		Cleanup();
	}

	/// Returns a path relative to the assets directory.
	public void GetAssetPath(StringView relativePath, String outPath)
	{
		outPath.Clear();
		Path.InternalCombine(outPath, mAssetDirectory, relativePath);
	}

	/// Discovers the assets and asset cache directories.
	/// Searches from current directory upward for Assets folder with .assets marker.
	private void DiscoverAssetDirectories()
	{
		let currentDir = Directory.GetCurrentDirectory(.. scope .());
		mRuntimeDirectory.Set(currentDir);

		// Derive project assets dir from RuntimeDirectory by convention:
		// `<parent of cwd>/assets`. Apps following the standard layout
		// (exe project dir nested under project root with sibling
		// `assets/`) get a non-empty path here. Apps with custom layouts
		// see an empty ProjectAssetDirectory and are responsible for
		// their own project asset discovery.
		let parentOfCwd = Path.GetDirectoryPath(currentDir, .. scope .());
		if (!parentOfCwd.IsEmpty)
		{
			let candidate = scope String();
			Path.InternalCombine(candidate, parentOfCwd, "assets");
			if (Directory.Exists(candidate))
				mProjectAssetDirectory.Set(candidate);
		}

		String searchDir = scope .(currentDir);

		while (true)
		{
			let assetsPath = scope String();
			Path.InternalCombine(assetsPath, searchDir, "Assets");

			if (Directory.Exists(assetsPath))
			{
				let markerPath = scope String();
				Path.InternalCombine(markerPath, assetsPath, ".assets");

				if (File.Exists(markerPath))
				{
					mAssetDirectory.Set(assetsPath);
					Path.InternalCombine(mAssetCacheDirectory, searchDir, "Assets", "cache");

					if (!Directory.Exists(mAssetCacheDirectory))
						Directory.CreateDirectory(mAssetCacheDirectory);

					return;
				}
			}

			let parentDir = Path.GetDirectoryPath(searchDir, .. scope .());

			if (parentDir.IsEmpty || parentDir == searchDir)
			{
				Console.WriteLine("WARNING: Could not find Assets directory with .assets marker. Using current directory.");
				mAssetDirectory.Set(currentDir);
				mAssetCacheDirectory.Set(currentDir);
				return;
			}

			searchDir.Set(parentDir);
		}
	}
}
