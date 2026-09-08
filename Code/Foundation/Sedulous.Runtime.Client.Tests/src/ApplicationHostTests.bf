using System;
using Sedulous.Core;
using Sedulous.Graphics;
using Sedulous.Graphics.Null;
using Sedulous.Runtime;
using Sedulous.Shell;
using Sedulous.Shell.Null;

namespace Sedulous.Runtime.Client.Tests;

/// The host driving one application, headless and step by step.
///
/// Tick takes an EXPLICIT delta, which is the whole reason a frame is testable at all: no
/// clock, no loop, and the accumulator arithmetic comes out exact.
class ApplicationHostTests
{
	/// Configure first, so the application's subsystems exist before the context starts
	/// them; then startup, then play. Anything else and a subsystem would be running
	/// before its owner had asked for it.
	[Test]
	public static void StartConfiguresThenStartsThenLaunches()
	{
		let app = scope LifecycleApp();
		let host = scope ApplicationHost();

		host.Start(app);

		Test.Assert(app.Order.Count == 3);
		Test.Assert(app.Order[0] == .Configure);
		Test.Assert(app.Order[1] == .Startup);
		Test.Assert(app.Order[2] == .Launch);
		Test.Assert(app.SubsystemLiveAtStartup, "Configure ran before the context started");
		Test.Assert(host.IsRunning);

		host.Stop();
		Test.Assert(!host.IsRunning);
		Test.Assert(app.Subsystem.Shutdowns == 1);
		Test.Assert(app.Order[app.Order.Count - 1] == .Shutdown, "OnExit, then OnShutdown last");
	}

	/// Starting twice is a no op rather than a second bring up: a host that configured the
	/// application again would register every subsystem twice.
	[Test]
	public static void StartAndStopAreIdempotent()
	{
		let app = scope LifecycleApp();
		let host = scope ApplicationHost();

		host.Start(app);
		host.Start(app);
		Test.Assert(app.CountOf(.Configure) == 1);
		Test.Assert(app.CountOf(.Launch) == 1);

		host.Stop();
		host.Stop();
		Test.Assert(app.CountOf(.Exit) == 1);
		Test.Assert(app.CountOf(.Shutdown) == 1);
	}

	[Test]
	public static void TickDrivesTheContextPhasesAndTheAccumulator()
	{
		let app = scope LifecycleApp();
		let host = scope ApplicationHost();
		host.Start(app);

		// Under one step's worth: the phases all run, the fixed hook does not.
		host.Tick(0.25f);
		Test.Assert(app.Subsystem.Begin == 1);
		Test.Assert(app.Subsystem.Updates == 1);
		Test.Assert(app.Subsystem.Post == 1);
		Test.Assert(app.Subsystem.End == 1);
		Test.Assert(app.FixedUpdates == 0);

		// Reaching half a second buys exactly one step, since the leftover carried over.
		host.Tick(0.25f);
		Test.Assert(app.FixedUpdates == 1);
		Test.Assert(app.Subsystem.Updates == 2);

		host.Tick(0.5f);
		Test.Assert(app.FixedUpdates == 2);

		// OnUpdate fires once per Tick regardless of how many fixed steps ran.
		Test.Assert(app.CountOf(.Update) == 3);
		host.Stop();
	}

	/// The frame clamp lives on the RUNNER, not in Tick: the host takes whatever delta it
	/// is given, and Settings is where a runner reads the ceiling from.
	[Test]
	public static void TheFrameClampBoundsTheStepCount()
	{
		let app = scope ClampApp();
		let host = scope ApplicationHost();
		host.Start(app);

		var deltaTime = 10.0f;
		if (deltaTime > host.Settings.MaxFrameTime)
			deltaTime = host.Settings.MaxFrameTime;

		host.Tick(deltaTime);
		Test.Assert(app.FixedUpdates == 2, "a quarter second buys two tenth second steps, not a hundred");
		host.Stop();
	}

	/// Even unclamped, the accumulator's own cap holds: a hitch drops the excess time
	/// rather than owing it, which is what keeps the next frame from being worse.
	[Test]
	public static void AHugeDeltaIsCappedByTheAccumulatorToo()
	{
		let app = scope ClampApp();
		let host = scope ApplicationHost();
		host.Start(app);

		host.Tick(10.0f);
		Test.Assert(app.FixedUpdates == (int)ApplicationSettings().MaxFixedStepsPerFrame);
		host.Stop();
	}

	[Test]
	public static void RequestExitStopsAManualRunLoop()
	{
		let app = scope LifecycleApp();
		let host = scope ApplicationHost();
		host.Start(app);

		int frames = 0;
		while (host.IsRunning)
		{
			host.Tick(0.5f);
			if (++frames == 3)
				host.RequestExit(7);
		}
		host.Stop();

		Test.Assert(frames == 3);
		Test.Assert(host.ExitCode == 7);
		Test.Assert(app.Subsystem.Updates == 3);
	}

	/// The shell is BORROWED and visible from the earliest hook, so an application can
	/// wire against it in Configure rather than waiting for startup.
	[Test]
	public static void TheHostBorrowsTheShellAndShowsItToTheApp()
	{
		let shell = scope NullShell();
		let app = scope ShellApp();
		let host = scope ApplicationHost();

		host.Start(app, shell);
		Test.Assert(app.SeenShell === shell);
		Test.Assert(host.Shell === shell);
		host.Stop();
	}

	/// Headless is a supported way to run, not a degraded one: with no shell and no
	/// device there is no main window, and a frame still ticks.
	[Test]
	public static void AHeadlessRunHasNoWindowsAndStillTicks()
	{
		let app = scope LifecycleApp();
		let host = scope ApplicationHost();
		host.Start(app);

		Test.Assert(host.MainRenderWindow == null);
		Test.Assert(host.Windows.IsEmpty);
		host.Tick(0.5f);
		Test.Assert(app.Subsystem.Updates == 1);
		host.Stop();
	}

	/// Every window renders each frame, and a close is DEFERRED to frame end: the frame a
	/// window is closed in still renders it, because the GPU is not done with it until
	/// the frame is.
	[Test]
	public static void EveryWindowRendersEachTickAndClosingIsDeferred()
	{
		let shell = scope NullShell();
		Test.Assert(NullGraphics.CreateDevice(2) case .Ok(let device));
		defer delete device;

		let app = scope RenderApp();
		let host = scope ApplicationHost();
		host.Start(app, shell, device);

		// The main window came from Start; the second from the application's OnStartup.
		Test.Assert(host.Windows.Length == 2);
		Test.Assert(app.Second != null);
		Test.Assert(host.MainRenderWindow === host.Windows[0]);

		host.Tick(0.016f);
		Test.Assert(app.Renders == 2, "one per window");

		host.CloseWindow(app.Second);
		host.Tick(0.016f);
		Test.Assert(host.Windows.Length == 1);
		Test.Assert(app.Renders == 4, "the closing frame still rendered both");

		host.Tick(0.016f);
		Test.Assert(app.Renders == 5, "only the survivor now");

		host.Stop();
		Test.Assert(host.Windows.IsEmpty);
	}

	/// Closing the same window twice queues it once. The second call names a window that
	/// is already gone, and freeing it again would be a double free.
	[Test]
	public static void ClosingTheSameWindowTwiceQueuesItOnce()
	{
		let shell = scope NullShell();
		Test.Assert(NullGraphics.CreateDevice(2) case .Ok(let device));
		defer delete device;

		let app = scope RenderApp();
		let host = scope ApplicationHost();
		host.Start(app, shell, device);

		host.CloseWindow(app.Second);
		host.CloseWindow(app.Second);
		host.Tick(0.016f);

		Test.Assert(host.Windows.Length == 1);
		host.Stop();
	}
}
