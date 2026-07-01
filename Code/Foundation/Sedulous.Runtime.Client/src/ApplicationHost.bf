using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.RuntimeGraphics;
using Sedulous.Shell;
using Sedulous.Runtime;
using Sedulous.Jobs;

namespace Sedulous.Runtime.Client;

/// The concrete, generic host that drives exactly ONE IApplication.
/// Owns a Context, an optional (borrowed) GraphicsDevice, and the list of
/// RenderWindows it presents. It is infrastructure, NOT subclassed -- all
/// behavior lives in the IApplication. It is deliberately loop-agnostic:
/// RunApplication provides a blocking desktop loop, but Start/Tick/Stop can
/// be driven externally (e.g., by the editor).
sealed class ApplicationHost : IApplicationHost
{
	// Owned
	private Context mContext = new .() ~ delete _;
	private List<RenderWindow> mWindows = new .() ~ DeleteContainerAndItems!(_);
	private List<RenderWindow> mPendingClose = new .() ~ delete _;

	// Borrowed (owned by the entry point)
	private IApplication mApp;
	private IShell mShell;
	private GraphicsDevice mGraphics;

	// State
	private const int32 MaxFixedStepsPerFrame = 8;
	private ApplicationSettings mSettings;
	private bool mStarted;
	private bool mRunning;
	private int32 mExitCode;
	private float mAccumulator;

	/// Whether the host is currently in the started+running state.
	public bool IsRunning => mRunning;

	/// The exit code set by RequestExit.
	public int32 ExitCode => mExitCode;

	/// The main window (first RenderWindow, created during Start). Null for headless.
	public RenderWindow MainWindow => mWindows.Count > 0 ? mWindows[0] : null;

	// --- IApplicationHost ---

	public Context Ctx => mContext;
	public IShell Shell => mShell;
	public GraphicsDevice Graphics => mGraphics;

	public RenderWindow OpenWindow(WindowSettings settings, RenderWindowDesc renderDesc)
	{
		if (mShell == null || mGraphics == null)
			return null;

		let wm = mShell.WindowManager;
		if (wm == null)
			return null;

		IWindow osWindow;
		if (wm.CreateWindow(settings) case .Ok(let w))
			osWindow = w;
		else
			return null;

		RenderWindow rw;
		if (mGraphics.CreateRenderWindow(osWindow, renderDesc) case .Ok(let r))
			rw = r;
		else
		{
			wm.DestroyWindow(osWindow);
			return null;
		}

		mWindows.Add(rw);
		return rw;
	}

	public void CloseWindow(RenderWindow window)
	{
		if (window == null)
			return;
		if (!mPendingClose.Contains(window))
			mPendingClose.Add(window);
	}

	public void RequestExit(int32 code = 0)
	{
		mRunning = false;
		mExitCode = code;
	}

	// --- Lifecycle ---

	/// Bring the application up: read settings, register subsystems (app's
	/// Configure), start the Context, create the main RenderWindow (if shell +
	/// graphics), then enter play (app OnLaunch). Idempotent.
	public void Start(IApplication app, IShell shell, GraphicsDevice graphics = null)
	{
		if (mStarted)
			return;

		mApp = app;
		mShell = shell;
		mGraphics = graphics;
		mSettings = app.Settings();

		// Bring up the engine-wide JobSystem before any subsystem starts
		JobSystem.Initialize();

		// Create the main window BEFORE Configure so subsystems that need it
		// (e.g. RenderSubsystem) have a valid IWindow during their Init/Ready.
		// This matches the old EngineApplication order where the window existed
		// before subsystem registration.
		if (mShell != null && mGraphics != null && mShell.WindowManager != null)
		{
			let title = scope String(mSettings.Title);
			let windowSettings = WindowSettings()
			{
				Title = title,
				Width = mSettings.Width,
				Height = mSettings.Height,
				Resizable = mSettings.Resizable,
				Bordered = true
			};

			if (mShell.WindowManager.CreateWindow(windowSettings) case .Ok(let osWindow))
			{
				let renderDesc = RenderWindowDesc()
				{
					PresentMode = mSettings.PresentMode,
					Format = mSettings.SwapChainFormat
				};

				if (mGraphics.CreateRenderWindow(osWindow, renderDesc) case .Ok(let rw))
					mWindows.Add(rw);
			}
		}

		// Let the app register its subsystems (window + device are available)
		mApp.Configure(this);

		// Start the context (initializes all subsystems)
		mContext.Startup();

		mApp.OnStartup(this);
		mApp.OnLaunch(this);

		mStarted = true;
		mRunning = true;
	}

	/// Advance exactly one frame with an explicit delta.
	public void Tick(float deltaTime)
	{
		mContext.BeginFrame(deltaTime);

		// Fixed-step accumulator loop (capped to prevent spiral-of-death on
		// large deltas, e.g. the first frame which includes startup time).
		let fixedStep = mSettings.FixedTimeStep;
		mAccumulator += deltaTime;
		int32 fixedSteps = 0;
		while (mAccumulator >= fixedStep && fixedSteps < MaxFixedStepsPerFrame)
		{
			mContext.FixedUpdate(fixedStep);
			mApp.OnFixedUpdate(this, fixedStep);
			mAccumulator -= fixedStep;
			fixedSteps++;
		}
		// Clamp residual to avoid runaway accumulation
		if (mAccumulator > fixedStep * 2)
			mAccumulator = fixedStep * 2;

		// Variable update
		mContext.Update(deltaTime);
		mApp.OnUpdate(this, deltaTime);
		mContext.PostUpdate(deltaTime);

		// Render every window uniformly (main == mWindows[0])
		if (mGraphics != null)
		{
			for (let rw in mWindows)
			{
				rw.SyncSize();
				var frame = rw.BeginFrame();
				if (!frame.Valid)
					continue;
				mApp.OnRenderWindow(this, ref frame);
				rw.EndFrame(ref frame);
			}
			mGraphics.AdvanceFrame();
		}

		mContext.EndFrame();
		FlushPendingCloses();
	}

	/// Tear the application down: leave play, stop the Context, destroy windows.
	/// Idempotent.
	public void Stop()
	{
		if (!mStarted)
			return;

		mApp.OnExit(this);

		// Wait for the GPU to finish all in-flight work before tearing down
		// subsystems. Without this, Context.Shutdown destroys scenes (and their
		// GPU resources) while commands referencing them are still queued.
		if (mGraphics != null)
			mGraphics.Raw?.WaitIdle();

		mApp.OnShutdown(this);
		mContext.Shutdown();

		mPendingClose.Clear();
		ClearAndDeleteItems(mWindows);

		// Tear down the engine-wide JobSystem last
		JobSystem.Shutdown();

		mStarted = false;
		mRunning = false;
	}

	/// Convenience runner: create a host on the stack, drive a blocking loop
	/// with wall-clock timing, then tear down. Returns the exit code.
	public static int32 RunApplication(IApplication app, IShell shell, GraphicsDevice graphics = null)
	{
		ApplicationHost host = scope .();
		host.Start(app, shell, graphics);

		// Start the stopwatch AFTER Start() so the first frame's delta doesn't
		// include startup time (loading assets, creating scenes, etc.). This
		// matches EngineApplication's behavior where the stopwatch started just
		// before the loop, giving a near-zero first-frame delta. Without this,
		// FixedUpdate runs on the first frame before transforms are propagated,
		// which hits uninitialized world matrices (e.g. Jolt quaternion assert).
		Stopwatch stopwatch = scope .();
		stopwatch.Start();
		float lastTime = 0.0f;

		while (shell.IsRunning && host.IsRunning)
		{
			shell.ProcessEvents();

			float currentTime = (float)stopwatch.Elapsed.TotalSeconds;
			float deltaTime = currentTime - lastTime;
			lastTime = currentTime;

			host.Tick(deltaTime);
		}

		host.Stop();
		return host.ExitCode;
	}

	// --- Private helpers ---

	/// Destroy windows queued by CloseWindow: free the RenderWindow (GPU) then
	/// the OS window. Runs at frame end, after the GPU finished the frame.
	private void FlushPendingCloses()
	{
		if (mPendingClose.Count == 0)
			return;

		let wm = (mShell != null) ? mShell.WindowManager : null;

		for (let dead in mPendingClose)
		{
			let osWindow = dead.Window;
			mWindows.Remove(dead);
			delete dead;  // RenderWindow dtor WaitIdle + frees GPU resources
			if (wm != null && osWindow != null)
				wm.DestroyWindow(osWindow);
		}
		mPendingClose.Clear();
	}
}
