using System;
using Sedulous.Graphics;
using Sedulous.Graphics.Gpu;
using Sedulous.Runtime.SDL3;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;

namespace Samples.UISandbox;

/// The sandbox's composition root: the shell, the graphics device and the desktop runner, in
/// that order, and nothing else.
class Program
{
	public static int Main(String[] args)
	{
		WindowSettings windowSettings = .();
		windowSettings.Title = "UI Sandbox";
		windowSettings.Width = 820;
		windowSettings.Height = 720;

		let shell = scope SDL3Shell(windowSettings);
		if (shell.MainWindow == null)
		{
			Console.Error.WriteLine("UISandbox: the shell has no main window");
			return 1;
		}

		GraphicsDeviceDesc deviceDesc = .();
		// Vulkan unless the command line says otherwise, which is what lets one built binary
		// be pointed at whichever backend a machine has.
		deviceDesc.Backend = BackendSelection.FromArguments(args);
		deviceDesc.EnableValidation = true;

		if (!(GpuGraphics.CreateDevice(deviceDesc) case .Ok(let graphics)))
		{
			Console.Error.WriteLine("UISandbox: the graphics device could not be created");
			return 1;
		}

		defer delete graphics;

		let app = scope UISandboxApp();
		return DesktopRunner.RunApplication(app, shell, graphics);
	}
}
