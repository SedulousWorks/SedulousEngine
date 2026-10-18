using System;
using Sedulous.Engine.DefaultApp;
using Sedulous.Graphics;
using Sedulous.Graphics.Gpu;
using Sedulous.Runtime.SDL3;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;
using Sedulous.VFS;
using Sedulous.RHI.Capture;

namespace Samples.CustomShader;

/// The composition root: the shell, the graphics device, the runner.
class Program
{
	public static int Main(String[] args)
	{
		WindowSettings windowSettings = .();
		windowSettings.Title = "Custom Shader";
		windowSettings.Width = 1280;
		windowSettings.Height = 720;

		let shell = scope SDL3Shell(windowSettings);
		if (shell.MainWindow == null)
		{
			Console.Error.WriteLine("CustomShader: the shell has no main window");
			return 1;
		}

		// The backend comes from the command line, so ONE built binary runs against whichever
		// one a machine has.
		let deviceDesc = GraphicsDeviceDesc.FromArguments(args);

		if (!(GpuGraphics.CreateDevice(deviceDesc) case .Ok(let graphics)))
		{
			Console.Error.WriteLine("CustomShader: the graphics device could not be created");
			return 1;
		}
		defer delete graphics;

		let app = scope CustomShaderApp();
		// --screenshot <png> [--screenshot-frame N | --screenshot-after S] [--screenshot-exit]:
		// a capture with no hand on F11.
		app.SetScreenshotOptions(ScreenshotOptions.FromArguments(args));
		// The engine data root: --data-root when given, else the discovery walk.
		app.SetDataRoot(DataRootFromArguments(args, .. scope .()));
		return DesktopRunner.RunApplication(app, shell, graphics);
	}
}
