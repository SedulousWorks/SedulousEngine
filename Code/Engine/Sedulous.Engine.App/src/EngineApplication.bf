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
using Sedulous.Serialization.OpenDDL;
using Sedulous.Profiler;
using Sedulous.Shaders;
using Sedulous.Engine;
using Sedulous.Engine.Input;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.GUI;
using Sedulous.Engine.Render;

/// Full engine application base class.
/// Creates a Context with standard subsystems and manages the main loop.
/// Game logic lives in components and subsystems, not in app overrides.
///
/// The app creates the RHI device and window, then passes them to subsystems.
/// The RenderSubsystem owns swapchain, command pools, and frame pacing.
abstract class EngineApplication : IDisposable
{
	// Platform
	protected IShell mShell;
	protected IWindow mWindow;
	protected IBackend mBackend;
	protected IDevice mDevice;

	// Engine
	protected Context mContext;

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

		mShaderSystem = new ShaderSystem();
		StringView[1] shaderPaths = .(shaderDir);
		mShaderSystem.Initialize(mDevice, shaderPaths/*, cacheDir*/);

		// Create context
		mContext = new Context();

		// Register serializer provider
		mContext.Resources.SetSerializerProvider(new OpenDDLSerializerProvider());

		// Register standard subsystems
		RegisterDefaultSubsystems();

		// Let derived class add custom subsystems
		OnConfigure(mContext);

		// Start up
		mContext.Startup();
		OnStartup();

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

			// Fixed update loop
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

			mContext.BeginFrame(deltaTime);
			mContext.Update(deltaTime);
			mContext.PostUpdate(deltaTime);
			mContext.EndFrame();

			SProfiler.EndFrame();
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

	// ==================== Overrides ====================

	/// Override to register custom subsystems.
	protected virtual void OnConfigure(Context context) { }

	/// Override to set up initial scene, load assets, etc.
	/// All subsystems are initialized at this point.
	protected virtual void OnStartup() { }

	/// Override for cleanup before shutdown.
	protected virtual void OnShutdown() { }

	/// Override to release GPU resources after device WaitIdle but before subsystems are destroyed.
	protected virtual void OnCleanup() { }

	// ==================== Default Subsystems ====================

	protected virtual void RegisterDefaultSubsystems()
	{
		mContext.RegisterSubsystem(new InputSubsystem());       // -900
		mContext.RegisterSubsystem(new SceneSubsystem());        // -500
		mContext.RegisterSubsystem(new PhysicsSubsystem());      // -100
		mContext.RegisterSubsystem(new AnimationSubsystem());    //  100
		mContext.RegisterSubsystem(new AudioSubsystem());        //  200
		mContext.RegisterSubsystem(new NavigationSubsystem());   //  300
		mContext.RegisterSubsystem(new GUISubsystem());          //  400

		let renderSub = new RenderSubsystem();
		renderSub.Device = mDevice;
		renderSub.Window = mWindow;
		renderSub.Surface = mSurface;
		renderSub.SwapChainFormat = mSettings.SwapChainFormat;
		renderSub.PresentMode = mSettings.PresentMode;
		renderSub.ShaderSystem = mShaderSystem;
		renderSub.AssetDirectory = mAssetDirectory;
		mContext.RegisterSubsystem(renderSub);                   //  500
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

		// Surface (needed by RenderSubsystem for swapchain creation)
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

		// Context must be deleted before device — subsystems hold GPU resources
		delete mContext;
		mContext = null;

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
