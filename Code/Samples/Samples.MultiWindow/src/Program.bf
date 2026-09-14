using System;
using Sedulous.Graphics;
using Sedulous.Graphics.Gpu;
using Sedulous.Runtime.SDL3;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;

namespace Samples.MultiWindow;

/// The composition root: the shell, the graphics device, the runner.
class Program
{
	public static int Main(String[] args)
	{
		WindowSettings windowSettings = .();
		windowSettings.Title = "MultiWindow - Main";
		windowSettings.Width = 800;
		windowSettings.Height = 600;

		let shell = scope SDL3Shell(windowSettings);
		if (shell.MainWindow == null)
		{
			Console.Error.WriteLine("MultiWindow: the shell has no main window");
			return 1;
		}

		GraphicsDeviceDesc deviceDesc = .();
		// The backend comes from the command line, so ONE built binary runs against whichever
		// one a machine has.
		deviceDesc.Backend = BackendSelection.FromArguments(args);
		deviceDesc.EnableValidation = true;

		if (!(GpuGraphics.CreateDevice(deviceDesc) case .Ok(let graphics)))
		{
			Console.Error.WriteLine("MultiWindow: the graphics device could not be created");
			return 1;
		}
		defer delete graphics;

		let app = scope MultiWindowApp();
		return DesktopRunner.RunApplication(app, shell, graphics);
	}
}
