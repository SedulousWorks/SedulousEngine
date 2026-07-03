namespace TowerDefense.Bootstrap;

using System;
using System.IO;
using Sedulous.Platform.SDL3;
using Sedulous.RuntimeGraphics;
using Sedulous.Runtime.Client;

class Program
{
	public static int Main(String[] args)
	{
		// DefaultApplication.DiscoverAssetDirectories sets
		// ProjectAssetDirectory to `<parent-of-cwd>/assets` only when
		// the directory already exists. The bootstrap is what creates
		// that directory, so pre-create it here before the app starts
		// discovery - otherwise BootstrapApp sees an empty
		// ProjectAssetDirectory and writes nowhere.
		let cwd = Directory.GetCurrentDirectory(.. scope .());
		let parent = Path.GetDirectoryPath(cwd, .. scope .());
		if (!parent.IsEmpty)
		{
			let assetsDir = scope String();
			Path.InternalCombine(assetsDir, parent, "assets");
			if (!Directory.Exists(assetsDir))
				Directory.CreateDirectory(assetsDir);
		}

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

		let app = scope BootstrapApp();
		return ApplicationHost.RunApplication(app, platform, graphics);
	}
}
