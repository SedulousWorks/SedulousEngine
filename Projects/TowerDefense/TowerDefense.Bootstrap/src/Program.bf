namespace TowerDefense.Bootstrap;

using System;
using System.IO;
using Sedulous.Shell.SDL3;
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
		// discovery - otherwise BootstrapModule sees an empty
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

		let app = scope BootstrapModule();
		return ApplicationHost.RunApplication(app, shell, graphics);
	}
}
