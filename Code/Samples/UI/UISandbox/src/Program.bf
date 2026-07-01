using System;
using Sedulous.Images.STB;
using Sedulous.Images.SDL;
using Sedulous.Runtime.Client;
using Sedulous.RuntimeGraphics;
using Sedulous.Shell.SDL3;

namespace UISandbox;

class Program
{
	public static int Main(String[] args)
	{
		STBImageLoader.Initialize();
		SDLImageLoader.Initialize();

		let shell = scope SDL3Shell();
		if (shell.Initialize() case .Err)
		{
			Console.WriteLine("ERROR: Failed to initialize shell");
			return 1;
		}
		defer shell.Shutdown();

		let graphicsResult = GraphicsDevice.Create(.() { EnableValidation = true });
		if (graphicsResult case .Err)
		{
			Console.WriteLine("ERROR: Failed to create graphics device");
			return 1;
		}
		let graphics = graphicsResult.Value;
		defer delete graphics;

		let app = scope UISandboxApp();
		return ApplicationHost.RunApplication(app, shell, graphics);
	}
}
