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
using Sedulous.Engine.Render;
using Sedulous.Renderer;
using Sedulous.Engine.Renderer;

/// Full engine application base class.
/// Creates a Context with standard subsystems and manages the main loop.
/// Game logic lives in components and subsystems, not in app overrides.
///
/// The app creates the RHI device and window, then passes them to subsystems.
/// The application owns swapchain, output textures, frame pacing, and presentation.
/// RenderSubsystem implements ISceneRenderer and focuses purely on scene rendering.
abstract class EngineApplication : IDisposable
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

	// Output targets (application-owned, Pipeline-sized)
	private ITexture mColorTarget;
	private ITextureView mColorTargetView;
	private BlitHelper mBlitHelper;

	// Cached renderer interfaces
	private ISceneRenderer mSceneRenderer;
	private List<IOverlayRenderer> mOverlayRenderers = new .() ~ delete _;

	// Assets
	private String mAssetDirectory = new .() ~ delete _;
	private String mAssetCacheDirectory = new .() ~ delete _;

	// Shader system (shared by all subsystems that need it)
	private ShaderSystem mShaderSystem;

	// Settings
	protected EngineAppSettings mSettings;
	protected bool mIsRunning = false;
	private bool mCleanedUp = false;

	// Timing
	private Stopwatch mStopwatch = new .() ~ delete _;
	private float mLastFrameTime;
	private float mFixedTimeStep = 1.0f / 60.0f;
	private float mFixedUpdateAccumulator = 0.0f;

	// Profiling
	private float mInitTimeMs;
	private int32 mMaxFixedStepsPerFrame = 8;

	/// The framework context.
	public Context Context => mContext;

	/// The shell.
	public IShell Shell => mShell;

	/// The main window.
	public IWindow Window => mWindow;

	/// The RHI device.
	public IDevice Device => mDevice;

	/// The discovered assets directory path.
	public StringView AssetDirectory => mAssetDirectory;

	/// The discovered asset cache directory path.
	public StringView AssetCacheDirectory => mAssetCacheDirectory;

	/// The shared shader system.
	public ShaderSystem ShaderSystem => mShaderSystem;

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
		mShaderSystem.Initialize(mDevice, shaderPaths/*, cacheDir*/);

		let initTimer = scope Stopwatch();
		initTimer.Start();

		// Core systems (application-owned, not Context)
		JobSystem.Initialize();
		mLogger = new Sedulous.Core.Logging.Console.ConsoleLogger(.Information);
		mResourceSystem = new ResourceSystem(mLogger);
		mResourceSystem.SetSerializerProvider(new OpenDDLSerializerProvider());
		mResourceSystem.Startup();

		// Create context
		mContext = new Context();

		// Register standard subsystems
		RegisterDefaultSubsystems();

		// Let derived class add custom subsystems
		OnConfigure(mContext);

		// Start up
		mContext.Startup();

		// Initialize presentation resources (after context startup so device is ready)
		InitializePresentation();

		// Cache renderer interfaces from registered subsystems
		mSceneRenderer = mContext.GetSubsystemByInterface<ISceneRenderer>();
		mContext.GetSubsystemsByInterface<IOverlayRenderer>(mOverlayRenderers);
		mOverlayRenderers.Sort(scope (a, b) => a.OverlayOrder <=> b.OverlayOrder);

		OnStartup();

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
				mFixedUpdateAccumulator -= mFixedTimeStep;
				fixedSteps++;
			}
			if (mFixedUpdateAccumulator > mFixedTimeStep * 2)
				mFixedUpdateAccumulator = mFixedTimeStep * 2;

			mContext.Update(deltaTime);
			OnUpdate(deltaTime);
			mContext.PostUpdate(deltaTime);
			mContext.EndFrame();

			// Presentation - application owns swapchain, output targets, blit, overlays, present.
			PresentFrame();

			SProfiler.EndFrame();

			// Shift+P: print profile frame
			let keyboard = mShell.InputManager.Keyboard;
			if (keyboard.IsKeyPressed(.P) /*&& keyboard.Modifiers.HasFlag(.Shift)*/)
				PrintProfileFrame();
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

	private void PrintProfileFrame()
	{
		let frame = SProfiler.GetCompletedFrame();

		Console.WriteLine("=== Profile ===");
		Console.WriteLine("Init: {0:F2}ms", mInitTimeMs);
		Console.WriteLine("Frame {0}: {1:F2}ms ({2} samples)", frame.FrameNumber, frame.FrameDurationMs, frame.SampleCount);

		// Sort by start time so parents appear before children
		let sorted = scope List<ProfileSample>(frame.Samples.Count);
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
		mContext.RegisterSubsystem(new SceneSubsystem());        // -500
		mContext.RegisterSubsystem(new PhysicsSubsystem());                  // -100
		mContext.RegisterSubsystem(new AnimationSubsystem(mResourceSystem));  //  100
		mContext.RegisterSubsystem(new AudioSubsystem(mResourceSystem));      //  200
		mContext.RegisterSubsystem(new NavigationSubsystem());   //  300
		let uiSub = new EngineUISubsystem();
		uiSub.Device = mDevice;
		uiSub.Window = mWindow;
		uiSub.Shell = mShell;
		uiSub.ShaderSystem = mShaderSystem;
		uiSub.SwapChainFormat = mSettings.SwapChainFormat;
		uiSub.FrameCount = MAX_FRAMES_IN_FLIGHT;
		if (mAssetDirectory.Length > 0)
			uiSub.AssetDirectory = new String(mAssetDirectory);
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

		// Output target (HDR, same size as window)
		CreateOutputTarget((uint32)mWindow.Width, (uint32)mWindow.Height);

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
			let sceneSub = mContext.GetSubsystem<Sedulous.Engine.SceneSubsystem>();
			if (sceneSub != null)
			{
				for (let scene in sceneSub.ActiveScenes)
				{
					mSceneRenderer.RenderScene(scene, encoder, mColorTarget, mColorTargetView,
						(uint32)mWindow.Width, (uint32)mWindow.Height, mFrameIndex);
					break; // Render only the first/active scene for now
				}
			}
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

		// Blit scene output -> swapchain
		using (SProfiler.Begin("Blit"))
			BlitToSwapchain(encoder);

		// Overlays (IOverlayRenderer - ScreenUIView, debug HUD, etc.)
		if (mOverlayRenderers.Count > 0)
		{
			using (SProfiler.Begin("Overlays"))
			{
				for (let overlay in mOverlayRenderers)
					overlay.RenderOverlay(encoder, mSwapChain.CurrentTextureView,
						mSwapChain.Width, mSwapChain.Height, mFrameIndex);
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

		pool.DestroyEncoder(ref encoder);
		mFrameIndex = (mFrameIndex + 1) % MAX_FRAMES_IN_FLIGHT;
	}

	private void BlitToSwapchain(ICommandEncoder encoder)
	{
		if (mColorTargetView == null || mBlitHelper == null || !mBlitHelper.IsReady)
			return;

		// Color target is already transitioned to ShaderRead by RenderScene

		ColorAttachment[1] colorAttachments = .(.()
		{
			View = mSwapChain.CurrentTextureView,
			LoadOp = .DontCare,
			StoreOp = .Store
		});

		RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };
		let renderPass = encoder.BeginRenderPass(passDesc);
		mBlitHelper.Blit(renderPass, mColorTargetView, mSwapChain.Width, mSwapChain.Height, mFrameIndex);
		renderPass.End();
	}

	private void ResizeSwapChain()
	{
		if (mDevice == null || mSwapChain == null) return;
		mDevice.WaitIdle();
		mSwapChain.Resize((uint32)mWindow.Width, (uint32)mWindow.Height);

		// Recreate output target at new size
		DestroyOutputTarget();
		CreateOutputTarget((uint32)mWindow.Width, (uint32)mWindow.Height);
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

		if (adapters[0].CreateDevice(.()) case .Ok(let rawDevice))
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

	private void Shutdown()
	{
		if (mDevice != null)
			mDevice.WaitIdle();

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

		// Shutdown core systems (after context - subsystems may have used them)
		mResourceSystem.Shutdown();
		delete mResourceSystem;
		mResourceSystem = null;
		delete mLogger;
		mLogger = null;
		JobSystem.Shutdown();

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
