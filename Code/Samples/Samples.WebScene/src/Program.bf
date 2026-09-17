using System;
using Sedulous.Graphics;
using Sedulous.Graphics.Gpu;
using Sedulous.Runtime.SDL3;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;

namespace Samples.WebScene;

/// The DESKTOP entry for WebScene. The scene itself is Samples.WebScene.App, shared verbatim
/// with the browser entry beside it.
///
/// Worth keeping rather than treating the browser as the only target: `WebScene --webgpu`
/// runs the SAME scene through the same backend on a desktop, where it can be debugged and
/// captured, and with a WGSL pack beside it the exact browser shader path as well. A web
/// render bug is then reproducible without opening a browser.
class Program
{
	public static int Main(String[] args)
	{
		WindowSettings windowSettings = .();
		windowSettings.Title = "WebScene";
		windowSettings.Width = 1280;
		windowSettings.Height = 720;

		let shell = scope SDL3Shell(windowSettings);
		if (shell.MainWindow == null)
		{
			Console.Error.WriteLine("WebScene: the shell has no main window");
			return 1;
		}

		GraphicsDeviceDesc deviceDesc = .();
		// From the command line, so ONE built binary runs against whichever backend a machine
		// has, and --webgpu is the browser comparison.
		deviceDesc.Backend = BackendSelection.FromArguments(args);
		deviceDesc.EnableValidation = true;

		if (!(GpuGraphics.CreateDevice(deviceDesc) case .Ok(let graphics)))
		{
			Console.Error.WriteLine("WebScene: the graphics device could not be created");
			return 1;
		}
		defer delete graphics;

		let app = scope WebSceneApp();
		return DesktopRunner.RunApplication(app, shell, graphics);
	}
}
