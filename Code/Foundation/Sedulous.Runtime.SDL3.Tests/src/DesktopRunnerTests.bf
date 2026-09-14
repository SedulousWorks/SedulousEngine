using System;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;

namespace Sedulous.Runtime.SDL3.Tests;

/// The desktop runner's loop.
///
/// Its own project rather than a case in the shell's, because this is where the runtime and
/// the shell meet: the loop, the host and a real window are all in it at once, and a unit
/// suite that pulled in a second module to reach that would stop being one.
class DesktopRunnerTests
{
	[Test]
	public static void RunApplicationDrivesTheAppUntilItAsksToStop()
	{
		WindowSettings settings = .();
		settings.Title = "Runner Test";
		settings.Width = 320;
		settings.Height = 240;

		let shell = scope SDL3Shell(settings);
		if (shell.MainWindow == null)
		{
			// No display, which is the ordinary case on a build machine. Skipped rather than
			// failed: there is nothing here that a headless box could answer.
			Console.WriteLine("SKIP: no window, so the runner has nothing to drive");
			return;
		}

		let app = scope FrameCountApp(5, 3);
		let code = DesktopRunner.RunApplication(app, shell);

		Test.Assert(app.Frames == 5, scope $"ran {app.Frames} frames");
		Test.Assert(code == 3, scope $"returned {code}, not what the app asked for");
	}
}
