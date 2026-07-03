namespace EngineRenderStressTest;

using System;
using Sedulous.Platform.SDL3;
using Sedulous.RuntimeGraphics;
using Sedulous.Runtime.Client;

class Program
{
	static int Main(String[] args)
	{
		let platform = scope SDL3Platform();
		if (platform.Initialize() case .Err)
		{
			Console.WriteLine("ERROR: Failed to initialize platform");
			return 1;
		}
		defer platform.Shutdown();

		let graphicsResult = GraphicsDevice.Create(.() { EnableValidation = false });
		if (graphicsResult case .Err)
		{
			Console.WriteLine("ERROR: Failed to create graphics device");
			return 1;
		}
		let graphics = graphicsResult.Value;
		defer delete graphics;

		let app = scope RenderStressTestApp();
		return ApplicationHost.RunApplication(app, platform, graphics);
	}
}
