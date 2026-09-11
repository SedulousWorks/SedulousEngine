using System;
using System.Diagnostics;
using Sedulous.Graphics;
using Sedulous.Runtime.Client;
using Sedulous.Shell;

namespace Sedulous.Runtime.SDL3;

/// The DESKTOP execution model: a blocking wall clock loop driving an application against a
/// shell until either stops.
///
/// It lives apart from the shell backend and from the execution model agnostic client PRECISELY
/// because the loop is what differs between platforms: a desktop blocks in a while loop, and a
/// browser has to yield to the page through a callback instead. Its web sibling is the same
/// application, the same host, and a different runner.
///
/// The loop works only through the abstract shell interface, so it is windowing backend
/// agnostic; the concrete shell is built by the entry point and handed in.
static class DesktopRunner
{
	/// Runs until the shell or the host stops, and returns the application's exit code.
	public static int RunApplication(IApplication app, IShell shell, GraphicsDevice graphics = null)
	{
		// The process composition root.
		let host = scope ApplicationHost();
		host.Start(app, shell, graphics);

		let clock = scope Stopwatch(true);
		var lastSeconds = 0.0;

		while (shell.IsRunning && host.IsRunning)
		{
			shell.ProcessEvents();

			let nowSeconds = clock.Elapsed.TotalSeconds;
			var deltaTime = (float)(nowSeconds - lastSeconds);
			lastSeconds = nowSeconds;

			// CLAMPED, because a frame that took a second (a breakpoint, a window drag, a
			// swap chain rebuild) must not be handed to the simulation as a real second.
			if (deltaTime > host.Settings.MaxFrameTime)
				deltaTime = host.Settings.MaxFrameTime;

			host.Tick(deltaTime);
		}

		host.Stop();
		return host.ExitCode;
	}
}
