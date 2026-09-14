using System;
using Sedulous.Graphics;
using Sedulous.Graphics.Gpu;
using Sedulous.Runtime.SDL3;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;

namespace Samples.AnimStressTest;

/// The composition root: the shell, the graphics device, the runner.
class Program
{
	public static int Main(String[] args)
	{
		WindowSettings windowSettings = .();
		windowSettings.Title = "Anim Stress Test";
		windowSettings.Width = 1280;
		windowSettings.Height = 720;

		let shell = scope SDL3Shell(windowSettings);
		if (shell.MainWindow == null)
		{
			Console.Error.WriteLine("AnimStressTest: the shell has no main window");
			return 1;
		}

		GraphicsDeviceDesc deviceDesc = .();
		// The backend comes from the command line, so ONE built binary runs against whichever
		// one a machine has.
		deviceDesc.Backend = BackendSelection.FromArguments(args);
		deviceDesc.EnableValidation = true;

		if (!(GpuGraphics.CreateDevice(deviceDesc) case .Ok(let graphics)))
		{
			Console.Error.WriteLine("AnimStressTest: the graphics device could not be created");
			return 1;
		}
		defer delete graphics;

		let app = scope AnimStressTestApp();
		return DesktopRunner.RunApplication(app, shell, graphics);
	}
}
