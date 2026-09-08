using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Graphics;
using Sedulous.Profiler;
using Sedulous.Runtime;
using Sedulous.Shell;

namespace Sedulous.Runtime.Client;

/// The generic host that drives exactly ONE application.
///
/// Infrastructure, not a base class: nothing subclasses this, and every behaviour lives
/// in the IApplication it runs. It is deliberately LOOP AGNOSTIC, with no run loop of its
/// own: a shell layer drives Start, Tick and Stop, which is a blocking loop on the desktop
/// and a callback in a browser, and the host is the same either way.
///
/// Multi window is uniform: the main window is windows[0] and every frame renders the
/// whole list. Windows open and close at runtime, with the close deferred to frame end.
class ApplicationHost : IApplicationHost
{
	private Context mContext = new .() ~ delete _;
	private ApplicationSettings mSettings = .();
	/// Borrowed, all three: the entry point owns them.
	private IApplication mApp = null;
	private IShell mShell = null;
	private GraphicsDevice mGraphics = null;

	/// windows[0] is the main window. OWNED.
	private List<RenderWindow> mWindows = new .() ~ DeleteContainerAndItems!(_);
	private List<RenderWindow> mPendingClose = new .() ~ delete _;

	private bool mStarted = false;
	private bool mRunning = false;
	private int mExitCode = 0;
	private FixedStepper mStepper = .();

	/// Brings the application up: read its settings, let it register subsystems, start the
	/// context, wrap the shell's main window, then enter play. IDEMPOTENT.
	///
	/// The shell and the device stay null for a headless run, which is a supported way to
	/// run rather than a degraded one.
	public void Start(IApplication app, IShell shell = null, GraphicsDevice graphics = null)
	{
		if (mStarted)
			return;

		mApp = app;
		mShell = shell;
		mGraphics = graphics;
		mSettings = app.Settings;

		// The job system comes up BEFORE any subsystem, so every one of them can use it,
		// and goes down last in Stop, after everything that might still reach for it.
		InitGlobalJobSystem();

		mApp.Configure(this);
		mContext.Startup();

		// The main window already exists on the shell; this gives it a RenderWindow.
		if ((mShell != null) && (mGraphics != null))
		{
			if (let main = mShell.MainWindow)
			{
				if (mGraphics.CreateRenderWindow(main, app.MainRenderWindow) case .Ok(let window))
					mWindows.Add(window);
			}
		}

		mApp.OnStartup(this);
		// A standalone host enters play at once; an editor would call this on Play.
		mApp.OnLaunch(this);
		mStarted = true;
		mRunning = true;
	}

	/// Advances exactly one frame with an explicit delta.
	///
	/// The runner passes wall clock time; a test calls this directly, which is what makes
	/// the whole frame deterministic.
	public void Tick(float deltaTime)
	{
		ProfileFrameBegin();
		mContext.BeginFrame(deltaTime);

		using (ProfileScope("Update"))
		{
			// The simulation lanes run on SCALED time, for slow motion and pause; the
			// application hook and the frame bookkeeping keep the raw delta.
			let scaledDelta = deltaTime * mContext.TimeScale;

			// The fixed step is CONFIG on the context, which a scene seeds its own stepper
			// from; there is no context level fixed execution lane. This stepper serves the
			// application level hook and nothing else.
			mContext.FixedTimeStep = mSettings.FixedTimeStep;
			mStepper.Step = mSettings.FixedTimeStep;
			mStepper.MaxSteps = mSettings.MaxFixedStepsPerFrame;
			let fixedSteps = mStepper.Advance(scaledDelta);
			for (uint32 i < fixedSteps)
				mApp.OnFixedUpdate(this, mSettings.FixedTimeStep);

			mContext.Update(scaledDelta);
			mApp.OnUpdate(this, deltaTime);
			mContext.PostUpdate(scaledDelta);
		}

		// Every window, uniformly. The main window is simply the first.
		if (mGraphics != null)
		{
			using (ProfileScope("Render"))
			{
				for (let window in mWindows)
				{
					window.SyncSize();

					// The acquire BLOCKS until a back buffer is free, so under vsync or on
					// a GPU bound frame this is where the CPU waits. Scoped separately, so
					// a healthy present wait reads differently from a real stall.
					FrameContext frame;
					using (ProfileScope("Render.Acquire"))
						frame = window.BeginFrame();

					if (!frame.Valid)
						continue;

					mApp.OnRenderWindow(this, ref frame);

					using (ProfileScope("Render.Present"))
						window.EndFrame(ref frame);
				}
				using (ProfileScope("Render.Advance"))
					mGraphics.AdvanceFrame();
			}
		}

		mContext.EndFrame();
		FlushPendingCloses();
		ProfileFrameEnd();
	}

	/// Tears the application down: leave play, stop the context, destroy the windows.
	/// IDEMPOTENT.
	public void Stop()
	{
		if (!mStarted)
			return;

		mApp.OnExit(this);
		mContext.Shutdown();
		mApp.OnShutdown(this);

		mPendingClose.Clear();
		// Each RenderWindow waits the device idle and frees its GPU resources.
		ClearAndDeleteItems!(mWindows);

		// Last: after every subsystem has stopped and every GPU resource is freed, so
		// nothing can still be reaching for it.
		ShutdownGlobalJobSystem();

		mStarted = false;
		mRunning = false;
	}

	// ---- IApplicationHost ----

	public Context Context => mContext;
	public IShell Shell => mShell;
	public GraphicsDevice Graphics => mGraphics;
	public RenderWindow MainRenderWindow => mWindows.IsEmpty ? null : mWindows[0];

	public void RequestExit(int code = 0)
	{
		mRunning = false;
		mExitCode = code;
	}

	public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc)
	{
		if ((mShell == null) || (mGraphics == null))
			return null;

		let manager = mShell.WindowManager;
		if (manager == null)
			return null;

		if (!(manager.CreateWindow(windowSettings) case .Ok(let osWindow)))
			return null;

		if (!(mGraphics.CreateRenderWindow(osWindow, renderDesc) case .Ok(let window)))
		{
			manager.DestroyWindow(osWindow);
			manager.FlushDestroyed();
			return null;
		}

		mWindows.Add(window);
		return window;
	}

	/// Queues a close. DEFERRED, because a window closed from inside a frame is still the
	/// GPU's until the frame ends.
	public void CloseWindow(RenderWindow window)
	{
		if (window == null)
			return;
		if (mPendingClose.Contains(window))
			return;
		mPendingClose.Add(window);
	}

	public ApplicationSettings Settings => mSettings;
	public bool IsRunning => mRunning;
	public int ExitCode => mExitCode;
	public Span<RenderWindow> Windows => mWindows;

	/// Frees what CloseWindow queued: the RenderWindow's GPU resources first, then the OS
	/// window. At frame end, once the GPU has finished the frame.
	private void FlushPendingCloses()
	{
		if (mPendingClose.IsEmpty)
			return;

		let manager = (mShell != null) ? mShell.WindowManager : null;
		for (let dead in mPendingClose)
		{
			let osWindow = dead.Window;
			if (mWindows.Remove(dead))
				delete dead;
			if (manager != null)
				manager.DestroyWindow(osWindow);
		}
		mPendingClose.Clear();
		if (manager != null)
			manager.FlushDestroyed();
	}
}
