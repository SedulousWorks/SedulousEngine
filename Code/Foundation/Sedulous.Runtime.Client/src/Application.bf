using System;
using System.Diagnostics;
using System.IO;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RHI.Validation;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;
using Sedulous.Core.Mathematics;
using Sedulous.Runtime;
using Sedulous.Profiler;
using Sedulous.Serialization.OpenDDL;
using Sedulous.Resources;
using Sedulous.Core.Logging.Abstractions;

namespace Sedulous.Runtime.Client;

/// Abstract base class for Sedulous applications.
/// Provides lifecycle methods, window management, and rendering loop.
/// Creates and owns shell, backend, and device internally.
abstract class Application
{
	protected const int MAX_FRAMES_IN_FLIGHT = 2;

	// Created and owned by Application
	protected IShell mShell;
	protected IDevice mDevice;
	protected IBackend mBackend;

	// Created by Application (owned by Application)
	protected IWindow mWindow;
	protected ISurface mSurface;
	protected ISwapChain mSwapChain;
	protected IQueue mGraphicsQueue;
	protected ICommandPool[MAX_FRAMES_IN_FLIGHT] mCommandPools;
	protected IFence mFrameFence;
	protected uint64 mNextFenceValue = 1;
	protected uint64[MAX_FRAMES_IN_FLIGHT] mFrameFenceValues;
	protected ITexture mDepthTexture;
	protected ITextureView mDepthTextureView;

	// Secondary windows (multi-window support)
	protected List<SecondaryWindowContext> mSecondaryWindows = new .() ~ delete _;
	private List<SecondaryWindowContext> mPendingDestroys = new .() ~ delete _;

	// Settings and state
	protected ApplicationSettings mSettings;
	protected bool mIsRunning;

	// Framework context (created and owned by Application)
	protected Context mContext ~ delete _;

	// Core systems (application-owned)
	private ILogger mLogger ~ delete _;
	protected ResourceSystem mResourceSystem ~ delete _;

	public ResourceSystem ResourceSystem => mResourceSystem;

	// Asset directories (discovered at construction time)
	private String mAssetDirectory = new .() ~ delete _;
	private String mAssetCacheDirectory = new .() ~ delete _;

	// Timing
	private Stopwatch mStopwatch = new .() ~ delete _;
	private float mLastFrameTime;

	// Fixed update timing
	private float mFixedTimeStep = 1.0f / 60.0f;  // 60 Hz default
	private float mFixedUpdateAccumulator = 0.0f;
	private int32 mMaxFixedStepsPerFrame = 8;  // Prevent spiral of death

	// Frame rate limiting
	private int32 mTargetFrameRate = 0;  // 0 = unlimited
	private float mTargetFrameTime = 0.0f;  // Cached 1/targetFrameRate

	/// Gets or sets the fixed timestep in seconds.
	/// Default is 1/60 (60 Hz). Minimum is 0.001 seconds.
	public float FixedTimeStep
	{
		get => mFixedTimeStep;
		set => mFixedTimeStep = Math.Max(value, 0.001f);
	}

	/// Gets or sets the maximum fixed update steps per frame.
	/// Limits CPU usage if framerate drops significantly.
	public int32 MaxFixedStepsPerFrame
	{
		get => mMaxFixedStepsPerFrame;
		set => mMaxFixedStepsPerFrame = Math.Max(value, 1);
	}

	/// Gets or sets the target frame rate for frame pacing.
	/// Set to 0 for unlimited (default). Common values: 30, 60, 120, 144.
	/// Note: This is independent of VSync which is controlled by PresentMode.
	public int32 TargetFrameRate
	{
		get => mTargetFrameRate;
		set
		{
			mTargetFrameRate = Math.Max(value, 0);
			mTargetFrameTime = (mTargetFrameRate > 0) ? (1.0f / mTargetFrameRate) : 0.0f;
		}
	}

	public this()
	{
		DiscoverAssetDirectories();
	}

	/// The RHI device for GPU operations.
	public IDevice Device => mDevice;

	/// The swap chain for presentation.
	public ISwapChain SwapChain => mSwapChain;

	/// The main application window.
	public IWindow Window => mWindow;

	/// The shell providing platform services.
	public IShell Shell => mShell;

	/// Whether the application is currently running.
	public bool IsRunning => mIsRunning;

	/// The framework context managing all subsystems.
	public Context Context => mContext;

	/// Application settings.
	public ApplicationSettings Settings => mSettings;

	/// Returns the discovered assets directory path.
	/// This is an absolute path to the sssets folder containing the .ngassets marker file.
	public StringView AssetDirectory => mAssetDirectory;

	/// Returns the discovered assetsCache directory path.
	/// This is an absolute path to the assetsCache folder for cached/compiled assets.
	public StringView AssetCacheDirectory => mAssetCacheDirectory;

	/// Returns a path relative to the assets directory.
	/// Example: GetAssetPath("shaders/mesh.vert.hlsl") returns full path to the shader.
	public void GetAssetPath(StringView relativePath, String outPath)
	{
		outPath.Clear();
		Path.InternalCombine(outPath, mAssetDirectory, relativePath);
	}

	/// Returns a path relative to the assetsCache directory.
	/// Example: GetAssetCachePath("shaders/compiled/mesh.vert.spv") returns full path.
	public void GetAssetCachePath(StringView relativePath, String outPath)
	{
		outPath.Clear();
		Path.InternalCombine(outPath, mAssetCacheDirectory, relativePath);
	}

	/// Runs the application with the given settings.
	/// @param settings Application configuration.
	/// @returns Exit code (0 for success).
	public int Run(ApplicationSettings settings)
	{
		mSettings = settings;

		if (!Initialize())
			return -1;

		// Core systems
		Sedulous.Jobs.JobSystem.Initialize();
		mLogger = CreateLogger();
		mResourceSystem = new Sedulous.Resources.ResourceSystem(mLogger);
		mResourceSystem.EnableHotReload();
		mResourceSystem.SetSerializerProvider(new Sedulous.Serialization.OpenDDL.OpenDDLSerializerProvider());
		mResourceSystem.Startup();

		// Create the framework context
		mContext = CreateContext();

		// Let derived class configure the context (register subsystems, etc.)
		OnInitialize(mContext);

		// Start up the context (initializes all subsystems)
		mContext.Startup();

		// Notify derived class that context is ready
		OnContextStarted();

		mStopwatch.Start();
		mIsRunning = true;

		while (mIsRunning && mShell.IsRunning)
		{
			SProfiler.BeginFrame();

			float frameStartTime = (float)mStopwatch.Elapsed.TotalSeconds;

			{
				using (SProfiler.Begin("ProcessEvents"))
					mShell.ProcessEvents();
			}

			float currentTime = (float)mStopwatch.Elapsed.TotalSeconds;
			float deltaTime = currentTime - mLastFrameTime;
			mLastFrameTime = currentTime;
			

			let frameContext = FrameContext()
			{
				DeltaTime = deltaTime,
				TotalTime = currentTime,
				FrameIndex = (int32)mSwapChain.CurrentImageIndex,
				FrameCount = (int32)mSwapChain.BufferCount
			};

			{
				using (SProfiler.Begin("Input"))
					OnInput(frameContext);
			}

			// Fixed update loop - may run multiple times per frame
			{
				using (SProfiler.Begin("FixedUpdate"))
				{
					mFixedUpdateAccumulator += deltaTime;
					int32 fixedSteps = 0;
					while (mFixedUpdateAccumulator >= mFixedTimeStep && fixedSteps < mMaxFixedStepsPerFrame)
					{
						mContext.FixedUpdate(mFixedTimeStep);
						OnFixedUpdate(mFixedTimeStep);
						mFixedUpdateAccumulator -= mFixedTimeStep;
						fixedSteps++;
					}
					// Clamp accumulator to prevent spiral of death
					if (mFixedUpdateAccumulator > mFixedTimeStep * 2)
						mFixedUpdateAccumulator = mFixedTimeStep * 2;
				}
			}

			// Process completed async jobs and resource loads.
			Sedulous.Jobs.JobSystem.ProcessCompletions();
			mResourceSystem.Update();

			// Update framework - BeginFrame, Update, PostUpdate
			{
				using (SProfiler.Begin("BeginFrame"))
					mContext.BeginFrame(deltaTime);
			}

			{
				using (SProfiler.Begin("Update"))
				{
					OnUpdate(frameContext);
					mContext.Update(deltaTime);
				}
			}

			{
				using (SProfiler.Begin("PostUpdate"))
					mContext.PostUpdate(deltaTime);
			}

			{
				using (SProfiler.Begin("Frame"))
					Frame(frameContext);
			}

			{
				using (SProfiler.Begin("EndFrame"))
					mContext.EndFrame();
			}

			SProfiler.EndFrame();

			// Frame rate limiting
			if (mTargetFrameTime > 0)
			{
				float frameEndTime = (float)mStopwatch.Elapsed.TotalSeconds;
				float frameElapsed = frameEndTime - frameStartTime;
				float sleepTime = mTargetFrameTime - frameElapsed;
				if (sleepTime > 0.001f)  // Only sleep if > 1ms remaining
				{
					System.Threading.Thread.Sleep((int32)(sleepTime * 1000));
				}
			}
		}

		mDevice.WaitIdle();
		OnShutdown();
		mContext.Shutdown();
		mResourceSystem.Shutdown();
		Sedulous.Jobs.JobSystem.Shutdown();
		Cleanup();

		return 0;
	}

	/// Request the application to exit.
	public void Exit()
	{
		mIsRunning = false;
	}

	// Lifecycle methods - override in user application

	/// Creates the framework context. Override to provide a custom Context subclass.
	protected virtual Context CreateContext()
	{
		return new Context();
	}

	/// Create the application logger. Override to provide a custom logger
	/// (e.g., EditorLogger that tees to a log UI panel).
	protected virtual Sedulous.Core.Logging.Abstractions.ILogger CreateLogger()
	{
		return new Sedulous.Core.Logging.Console.ConsoleLogger(.Information);
	}

	/// Called once at startup after device and swap chain are ready.
	/// Use this to register subsystems with the context.
	/// @param context The framework context (not yet started).
	protected virtual void OnInitialize(Context context) { }

	/// Called after context.Startup() completes, before the main loop.
	/// All subsystems are initialized at this point.
	protected virtual void OnContextStarted() { }

	/// Called once at shutdown before cleanup.
	protected virtual void OnShutdown() { }

	/// Called when the window is resized.
	protected virtual void OnResize(int32 width, int32 height) { }

	/// Called each frame for input handling (before Update).
	protected virtual void OnInput(FrameContext frame) { }

	/// Called at a fixed timestep for physics and deterministic game logic.
	/// May be called multiple times per frame (or not at all) depending on framerate.
	/// Use this for physics simulation, AI updates, or anything requiring consistent timing.
	/// @param fixedDeltaTime The fixed timestep duration (same as FixedTimeStep property).
	protected virtual void OnFixedUpdate(float fixedDeltaTime) { }

	/// Called each frame for game/application logic.
	protected virtual void OnUpdate(FrameContext frame) { }

	/// Called after AcquireNextImage - safe to write per-frame GPU buffers.
	protected virtual void OnPrepareFrame(FrameContext frame) { }

	/// Called for rendering with full control over the command encoder.
	/// @returns true if rendering was handled, false to use default render pass.
	protected virtual bool OnRenderFrame(RenderContext render) { return false; }

	/// Called for rendering in the default render pass (if OnRenderFrame returns false).
	protected virtual void OnRender(IRenderPassEncoder renderPass, FrameContext frame) { }

	/// Called after the frame has been submitted and presented.
	protected virtual void OnFrameEnd() { }

	/// Called each frame before rendering a secondary window.
	/// Use this to update per-window DrawingRenderer projections, build draw commands, etc.
	protected virtual void OnPrepareSecondaryFrame(SecondaryWindowContext ctx, FrameContext frame) { }

	/// Called to render into a secondary window's render pass.
	protected virtual void OnRenderSecondaryWindow(SecondaryWindowContext ctx, IRenderPassEncoder renderPass, FrameContext frame) { }

	/// Called when a secondary window is resized.
	protected virtual void OnSecondaryWindowResized(SecondaryWindowContext ctx, int32 width, int32 height) { }

	//==========================================================================
	// Secondary Window Management
	//==========================================================================

	/// Creates a secondary OS window with its own surface and swapchain.
	/// The Device and graphics queue are shared with the main window.
	/// Returns the context, or .Err on failure.
	protected Result<SecondaryWindowContext> CreateSecondaryWindow(WindowSettings settings)
	{
		if (mShell.WindowManager.CreateWindow(settings) not case .Ok(let window))
			return .Err;

		if (mBackend.CreateSurface(window.NativeHandle) not case .Ok(var surface))
		{
			mShell.WindowManager.DestroyWindow(window);
			return .Err;
		}

		SwapChainDesc desc = .()
		{
			Width = (uint32)window.Width,
			Height = (uint32)window.Height,
			Format = mSettings.SwapChainFormat,
			PresentMode = mSettings.PresentMode
		};

		if (mDevice.CreateSwapChain(surface, desc) not case .Ok(let swapChain))
		{
			mDevice.DestroySurface(ref surface);
			mShell.WindowManager.DestroyWindow(window);
			return .Err;
		}

		let ctx = new SecondaryWindowContext();
		ctx.Window = window;
		ctx.Surface = surface;
		ctx.SwapChain = swapChain;
		mSecondaryWindows.Add(ctx);
		return .Ok(ctx);
	}

	/// Destroys a secondary window and all its GPU resources.
	/// Safe to call during frame rendering (deferred until frame end).
	protected void DestroySecondaryWindow(SecondaryWindowContext ctx)
	{
		if (!mSecondaryWindows.Contains(ctx))
			return;

		// Defer actual destruction to avoid mid-frame issues
		if (!mPendingDestroys.Contains(ctx))
			mPendingDestroys.Add(ctx);
	}

	/// Immediately destroys a secondary window (call only when safe).
	private void DestroySecondaryWindowImmediate(SecondaryWindowContext ctx)
	{
		mSecondaryWindows.Remove(ctx);

		mDevice.WaitIdle();

		var swapChain = ctx.SwapChain;
		var surface = ctx.Surface;
		if (swapChain != null) mDevice.DestroySwapChain(ref swapChain);
		if (surface != null) mDevice.DestroySurface(ref surface);

		if (ctx.Window != null)
			mShell.WindowManager.DestroyWindow(ctx.Window);

		delete ctx;
	}

	/// Processes pending secondary window destructions.
	private void FlushPendingDestroys()
	{
		if (mPendingDestroys.Count == 0)
			return;

		mDevice.WaitIdle();

		for (let ctx in mPendingDestroys)
			DestroySecondaryWindowImmediate(ctx);

		mPendingDestroys.Clear();
	}

	/// Renders all secondary windows for this frame.
	private void RenderSecondaryWindows(FrameContext mainFrame)
	{
		for (let ctx in mSecondaryWindows)
		{
			if (mPendingDestroys.Contains(ctx))
				continue;

			if (ctx.Window.State == .Minimized || ctx.Window.Width == 0 || ctx.Window.Height == 0)
				continue;

			if (ctx.SwapChain.AcquireNextImage() case .Err)
			{
				if (ctx.Window.Width > 0 && ctx.Window.Height > 0)
					ctx.SwapChain.Resize((uint32)ctx.Window.Width, (uint32)ctx.Window.Height);
				continue;
			}

			let frameCtx = FrameContext()
			{
				DeltaTime = mainFrame.DeltaTime,
				TotalTime = mainFrame.TotalTime,
				FrameIndex = mainFrame.FrameIndex,
				FrameCount = mainFrame.FrameCount
			};

			OnPrepareSecondaryFrame(ctx, frameCtx);

			let pool = mCommandPools[mainFrame.FrameIndex];
			var encoder = pool.CreateEncoder().Value;

			ColorAttachment[1] colorAttachments = .(.()
			{
				View = ctx.SwapChain.CurrentTextureView,
				ResolveTarget = null,
				LoadOp = .Clear,
				StoreOp = .Store,
				ClearValue = ClearColor(
					mSettings.ClearColor.R / 255.0f,
					mSettings.ClearColor.G / 255.0f,
					mSettings.ClearColor.B / 255.0f,
					mSettings.ClearColor.A / 255.0f)
			});

			RenderPassDesc desc = .() { ColorAttachments = .(colorAttachments) };
			let renderPass = encoder.BeginRenderPass(desc);
			renderPass.SetViewport(0, 0, ctx.SwapChain.Width, ctx.SwapChain.Height, 0, 1);
			renderPass.SetScissor(0, 0, ctx.SwapChain.Width, ctx.SwapChain.Height);

			OnRenderSecondaryWindow(ctx, renderPass, frameCtx);

			renderPass.End();
			encoder.TransitionTexture(ctx.SwapChain.CurrentTexture, .RenderTarget, .Present);

			let commandBuffer = encoder.Finish();
			mFrameFenceValues[mainFrame.FrameIndex] = mNextFenceValue++;

			ICommandBuffer[1] bufs = .(commandBuffer);
			mGraphicsQueue.Submit(bufs, mFrameFence, mFrameFenceValues[mainFrame.FrameIndex]);

			ctx.SwapChain.Present(mGraphicsQueue);

			pool.DestroyEncoder(ref encoder);
		}
	}

	// Internal implementation

	private bool Initialize()
	{
		// Create shell
		let shell = new SDL3Shell();
		if (shell.Initialize() case .Err) {
			Console.WriteLine("Failed to initialize shell");
			delete shell;
			return false;
		}
		mShell = shell;

		// Create backend
		if (!CreateBackend())
		{
			delete shell;
			return false;
		}

		// Create device
		if (!CreateDevice())
			return false;

		// Create window
		String title = scope .(mSettings.Title);
		let windowSettings = WindowSettings()
		{
			Title = title,
			Width = mSettings.Width,
			Height = mSettings.Height,
			Resizable = mSettings.Resizable,
			Bordered = true
		};

		if (mShell.WindowManager.CreateWindow(windowSettings) not case .Ok(let window))
			return false;
		mWindow = window;

		// Subscribe to window events
		mShell.WindowManager.OnWindowEvent.Subscribe(new => HandleWindowEvent);

		// Create surface from window
		if (mBackend.CreateSurface(mWindow.NativeHandle) not case .Ok(let surface))
			return false;
		mSurface = surface;

		// Create swap chain
		if (!CreateSwapChain())
			return false;

		// Get graphics queue and create per-frame command pools + fence
		mGraphicsQueue = mDevice.GetQueue(.Graphics);
		for (int i = 0; i < MAX_FRAMES_IN_FLIGHT; i++)
		{
			if (mDevice.CreateCommandPool(.Graphics) case .Ok(let pool))
				mCommandPools[i] = pool;
			else
				return false;
		}
		if (mDevice.CreateFence(0) case .Ok(let fence))
			mFrameFence = fence;
		else
			return false;

		// Create depth buffer if enabled
		if (mSettings.EnableDepth)
			CreateDepthBuffer();

		return true;
	}

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
		Console.WriteLine("ERROR: Failed to create RHI backend");
		return false;
	}

	private bool CreateDevice()
	{
		// Enumerate from the inner (unwrapped) backend to get raw adapters
		IBackend innerBackend = mBackend;
		if (let validated = mBackend as ValidatedBackend)
			innerBackend = validated.Inner;

		List<IAdapter> adapters = scope .();
		innerBackend.EnumerateAdapters(adapters);
		if (adapters.IsEmpty)
		{
			Console.WriteLine("ERROR: No GPU adapters found");
			return false;
		}

		let adapterInfo = adapters[0].GetInfo();
		Console.WriteLine("Using adapter: {0}", adapterInfo.Name);
		delete adapterInfo;

		if (adapters[0].CreateDevice(.()) case .Ok(let rawDevice))
		{
			mDevice = mSettings.EnableValidation ? new ValidatedDevice(rawDevice) : rawDevice;
			return true;
		}
		Console.WriteLine("ERROR: Failed to create device");
		return false;
	}

	private bool CreateSwapChain()
	{
		SwapChainDesc desc = .()
		{
			Width = (uint32)mWindow.Width,
			Height = (uint32)mWindow.Height,
			Format = mSettings.SwapChainFormat,
			PresentMode = mSettings.PresentMode
		};

		if (mDevice.CreateSwapChain(mSurface, desc) not case .Ok(let swapChain))
			return false;

		mSwapChain = swapChain;
		return true;
	}

	private void CreateDepthBuffer()
	{
		TextureDesc desc = .()
		{
			Width = (uint32)mWindow.Width,
			Height = (uint32)mWindow.Height,
			Format = mSettings.DepthFormat,
			Usage = .DepthStencil,
			Dimension = .Texture2D,
			MipLevelCount = 1,
			ArrayLayerCount = 1,
			SampleCount = 1,
			Label = "Depth"
		};

		if (mDevice.CreateTexture(desc) case .Ok(let texture))
		{
			mDepthTexture = texture;

			TextureViewDesc viewDesc = .()
			{
				Format = mSettings.DepthFormat,
				Dimension = .Texture2D,
				BaseMipLevel = 0,
				MipLevelCount = 1,
				BaseArrayLayer = 0,
				ArrayLayerCount = 1,
				Label = "DepthView"
			};

			if (mDevice.CreateTextureView(texture, viewDesc) case .Ok(let view))
				mDepthTextureView = view;
		}
	}

	private void Frame(FrameContext frameContext)
	{
		// Skip rendering when window is minimized
		if (mWindow.State == .Minimized)
			return;

		let frameIndex = frameContext.FrameIndex;

		// Wait for this frame's previous GPU work to complete
		if (mFrameFenceValues[frameIndex] > 0)
			mFrameFence.Wait(mFrameFenceValues[frameIndex]);

		// Reset the command pool for this frame (reclaims encoders + command buffers)
		mCommandPools[frameIndex].Reset();

		// Acquire next image
		using (SProfiler.Begin("AcquireImage"))
		{
			if (mSwapChain.AcquireNextImage() case .Err)
			{
				HandleResize();
				return;
			}
		}

		OnPrepareFrame(frameContext);

		// Create encoder
		let pool = mCommandPools[frameIndex];
		var encoder = pool.CreateEncoder().Value;

		let renderContext = RenderContext()
		{
			Encoder = encoder,
			SwapChain = mSwapChain,
			CurrentTextureView = mSwapChain.CurrentTextureView,
			DepthTextureView = mDepthTextureView,
			Frame = frameContext,
			ClearColor = mSettings.ClearColor
		};

		// Let app render
		if (!OnRenderFrame(renderContext))
		{
			RenderDefaultPass(encoder, renderContext);
		}

		// Transition swapchain image to present layout
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();

		// Submit with fence (this overload also handles swapchain semaphores)
		mFrameFenceValues[frameIndex] = mNextFenceValue++;
		using (SProfiler.Begin("Submit"))
		{
			ICommandBuffer[1] bufs = .(commandBuffer);
			mGraphicsQueue.Submit(bufs, mFrameFence, mFrameFenceValues[frameIndex]);
		}

		using (SProfiler.Begin("Present"))
		{
			if (mSwapChain.Present(mGraphicsQueue) case .Err)
				HandleResize();
		}
		// Render secondary windows
		if (mSecondaryWindows.Count > 0)
			RenderSecondaryWindows(frameContext);

		OnFrameEnd();

		// Process deferred secondary window destructions
		FlushPendingDestroys();

		pool.DestroyEncoder(ref encoder);
	}

	private void RenderDefaultPass(ICommandEncoder encoder, RenderContext ctx)
	{
		ColorAttachment[1] colorAttachments = .(.()
		{
			View = ctx.CurrentTextureView,
			ResolveTarget = null,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(ctx.ClearColor.R / 255.0f, ctx.ClearColor.G / 255.0f, ctx.ClearColor.B / 255.0f, ctx.ClearColor.A / 255.0f)
		});

		RenderPassDesc desc = .() { ColorAttachments = .(colorAttachments) };

		if (mDepthTextureView != null)
		{
			desc.DepthStencilAttachment = .()
			{
				View = mDepthTextureView,
				DepthLoadOp = .Clear,
				DepthStoreOp = .Store,
				DepthClearValue = 1.0f,
				StencilLoadOp = .Clear,
				StencilStoreOp = .Store, // different from SF
				StencilClearValue = 0
			};
		}

		let renderPass = encoder.BeginRenderPass(desc);
		renderPass.SetViewport(0, 0, mSwapChain.Width, mSwapChain.Height, 0, 1);
		renderPass.SetScissor(0, 0, mSwapChain.Width, mSwapChain.Height);

		OnRender(renderPass, ctx.Frame);

		renderPass.End();
	}

	private void HandleWindowEvent(IWindow window, WindowEvent evt)
	{
		// Main window
		if (window == mWindow)
		{
			switch (evt.Type)
			{
			case .Resized:
				HandleResize();
			case .CloseRequested:
				Exit();
			default:
			}
			return;
		}

		// Secondary windows
		for (let ctx in mSecondaryWindows)
		{
			if (ctx.Window == window)
			{
				switch (evt.Type)
				{
				case .Resized:
					if (ctx.Window.Width > 0 && ctx.Window.Height > 0)
					{
						mDevice.WaitIdle();
						ctx.SwapChain.Resize((uint32)ctx.Window.Width, (uint32)ctx.Window.Height);
						OnSecondaryWindowResized(ctx, ctx.Window.Width, ctx.Window.Height);
					}
				case .CloseRequested:
					if (ctx.OnCloseRequested != null)
						ctx.OnCloseRequested(ctx);
				default:
				}
				return;
			}
		}
	}

	private void HandleResize()
	{
		if (mWindow.Width == 0 || mWindow.Height == 0)
			return;

		mDevice.WaitIdle();

		// Cleanup depth buffer
		if (mDepthTextureView != null) mDevice.DestroyTextureView(ref mDepthTextureView);
		if (mDepthTexture != null) mDevice.DestroyTexture(ref mDepthTexture);

		// Resize swap chain
		mSwapChain.Resize((uint32)mWindow.Width, (uint32)mWindow.Height);

		// Recreate depth buffer
		if (mSettings.EnableDepth)
			CreateDepthBuffer();

		OnResize(mWindow.Width, mWindow.Height);
	}

	private void Cleanup()
	{
		// Destroy all secondary windows
		while (mSecondaryWindows.Count > 0)
			DestroySecondaryWindowImmediate(mSecondaryWindows[mSecondaryWindows.Count - 1]);
		mPendingDestroys.Clear();

		// Clean up depth buffer
		if (mDepthTextureView != null) mDevice.DestroyTextureView(ref mDepthTextureView);
		if (mDepthTexture != null) mDevice.DestroyTexture(ref mDepthTexture);

		// Clean up per-frame command pools and fence
		for (int i = 0; i < MAX_FRAMES_IN_FLIGHT; i++)
		{
			if (mCommandPools[i] != null) mDevice.DestroyCommandPool(ref mCommandPools[i]);
		}
		if (mFrameFence != null) mDevice.DestroyFence(ref mFrameFence);
		if (mSwapChain != null) mDevice.DestroySwapChain(ref mSwapChain);
		if (mSurface != null) mDevice.DestroySurface(ref mSurface);

		// Destroy window
		if (mWindow != null)
			mShell.WindowManager.DestroyWindow(mWindow);

		// Destroy device (handles ValidatedDevice wrapper)
		if (mDevice != null)
		{
			mDevice.Destroy();
			if (let validated = mDevice as Sedulous.RHI.Validation.ValidatedDevice)
			{
				delete validated.Inner;
				delete validated;
			}
			else
				delete mDevice;
			mDevice = null;
		}

		// Destroy backend (handles ValidatedBackend wrapper)
		if (mBackend != null)
		{
			mBackend.Destroy();
			if (let validated = mBackend as Sedulous.RHI.Validation.ValidatedBackend)
			{
				delete validated.Inner;
				delete validated;
			}
			else
				delete mBackend;
			mBackend = null;
		}

		// Shutdown shell
		if (mShell != null)
		{
			mShell.Shutdown();
			delete mShell;
			mShell = null;
		}
	}

	/// Discovers the assets and asset cache directories.
	/// Searches from current directory upward for assets folder with .assets marker.
	private void DiscoverAssetDirectories()
	{
		// Start from current working directory
		let currentDir = Directory.GetCurrentDirectory(.. scope .());
		String searchDir = scope .(currentDir);

		while (true)
		{
			// Check if NGAssets folder exists in this directory
			let assetsPath = scope String();
			Path.InternalCombine(assetsPath, searchDir, "Assets");

			if (Directory.Exists(assetsPath))
			{
				// Check for .assets marker file
				let markerPath = scope String();
				Path.InternalCombine(markerPath, assetsPath, ".assets");

				if (File.Exists(markerPath))
				{
					mAssetDirectory.Set(assetsPath);

					// cache is a sibling folder
					Path.InternalCombine(mAssetCacheDirectory, searchDir, "Assets", "cache");

					// Create cache directory if it doesn't exist
					if (!Directory.Exists(mAssetCacheDirectory))
						Directory.CreateDirectory(mAssetCacheDirectory);

					return;
				}
			}

			// Get parent directory
			let parentDir = Path.GetDirectoryPath(searchDir, .. scope .());

			// Check if we've reached the root (parent == current)
			if (parentDir.IsEmpty || parentDir == searchDir)
			{
				// Fall back to current directory with warning
				Console.WriteLine("WARNING: Could not find Assets directory with .assets marker. Using current directory.");
				mAssetDirectory.Set(currentDir);
				mAssetCacheDirectory.Set(currentDir);
				return;
			}

			searchDir.Set(parentDir);
		}
	}
}
