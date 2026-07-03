using System;
using Sedulous.Images.STB;
using Sedulous.Images.SDL;
using Sedulous.Runtime.Client;
using Sedulous.RuntimeGraphics;
using Sedulous.Platform.SDL3;

namespace UISandbox;

class Program
{
	public static int Main(String[] args)
	{
		STBImageLoader.Initialize();
		SDLImageLoader.Initialize();

		let platform = scope SDL3Platform();
		if (platform.Initialize() case .Err)
		{
			Console.WriteLine("ERROR: Failed to initialize platform");
			return 1;
		}
		defer platform.Shutdown();

		let graphicsResult = GraphicsDevice.Create(.() { EnableValidation = true });
		if (graphicsResult case .Err)
		{
			Console.WriteLine("ERROR: Failed to create graphics device");
			return 1;
		}
		let graphics = graphicsResult.Value;
		defer delete graphics;

		let app = scope UISandboxApp();
		return ApplicationHost.RunApplication(app, platform, graphics);
	}
}
