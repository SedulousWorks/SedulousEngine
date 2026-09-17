using System;
using System.Diagnostics;
using Sedulous.Graphics;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.Shell.Web;

namespace Sedulous.Runtime.Web;

/// The BROWSER execution model: one frame per requestAnimationFrame, driven by the page.
///
/// Same job as DesktopRunner, and deliberately its sibling rather than a flag on it, because
/// the loop is the thing that differs. A browser cannot own a blocking loop: it has to return
/// to the event loop to paint, to run timers, and to resolve the promises WebGPU is built on.
/// A while loop there paints nothing and resolves nothing, and the tab hangs.
///
/// So this registers a callback and RETURNS. The browser then calls back until the shell or
/// the application stops, which means the loop runs after the entry point has already
/// unwound: everything it touches has to outlive that, which is why the state below is static
/// rather than living on the returning frame.
static class WebRunner
{
	/// One page hosts one application, so one set of these.
	private static ApplicationHost sHost;
	private static IShell sShell;
	private static Stopwatch sClock;
	private static double sLastSeconds;
	private static int sExitCode;
	private static bool sStopped;

	/// Starts the application and hands the cadence to the browser.
	///
	/// Returns 0 IMMEDIATELY, and not the exit code: the run has barely begun at that point.
	/// The real exit happens inside Frame, which cancels the callback and tears down.
	public static int RunApplication(IApplication app, IShell shell, GraphicsDevice graphics = null)
	{
		sHost = new ApplicationHost();
		sHost.Start(app, shell, graphics);

		sShell = shell;
		sClock = new Stopwatch(true);
		sLastSeconds = 0.0;
		sStopped = false;

#if BF_PLATFORM_WASM
		// fps 0 asks for requestAnimationFrame, which is what matches the display rather than
		// a timer. simulateInfiniteLoop 0 returns control here rather than unwinding the stack
		// with an exception, so the caller's own teardown is never skipped.
		EmscriptenHtml5.emscripten_set_main_loop_arg(=> Frame, null, 0, 0);
		return 0;
#else
		// There is no browser to hand the cadence to. Off the web this is a programming error
		// rather than a fallback: silently running a desktop loop here would hide a wiring
		// mistake until someone wondered why the page never painted.
		Runtime.FatalError("WebRunner requires a wasm target; use DesktopRunner elsewhere");
#endif
	}

	/// One frame, driven by the browser. The body of the desktop while loop, once.
	private static void Frame(void* userData)
	{
		if (sStopped)
			return;

		if (!sShell.IsRunning || !sHost.IsRunning)
		{
			Shutdown();
			return;
		}

		sShell.ProcessEvents();

		let nowSeconds = sClock.Elapsed.TotalSeconds;
		var deltaTime = (float)(nowSeconds - sLastSeconds);
		sLastSeconds = nowSeconds;

		// CLAMPED for the same reason the desktop clamps: a tab in the background stops being
		// called at all, and the first frame after it returns would otherwise hand the
		// simulation however many seconds the user spent elsewhere.
		if (deltaTime > sHost.Settings.MaxFrameTime)
			deltaTime = sHost.Settings.MaxFrameTime;

		sHost.Tick(deltaTime);
	}

	private static void Shutdown()
	{
		sStopped = true;
		sHost.Stop();
		sExitCode = sHost.ExitCode;

#if BF_PLATFORM_WASM
		EmscriptenHtml5.emscripten_cancel_main_loop();
#endif

		DeleteAndNullify!(sClock);
		DeleteAndNullify!(sHost);
		sShell = null;
	}

	/// The exit code, once the run has actually finished. Meaningless before then, which is
	/// most of the time: the browser is still calling Frame.
	public static int ExitCode => sExitCode;
}
