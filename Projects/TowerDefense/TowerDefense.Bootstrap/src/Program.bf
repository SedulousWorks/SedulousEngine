namespace TowerDefense.Bootstrap;

using System;
using System.IO;
using Sedulous.Engine.App;

class Program
{
	public static int Main(String[] args)
	{
		// EngineApplication.DiscoverAssetDirectories sets
		// ProjectAssetDirectory to `<parent-of-cwd>/assets` only when
		// the directory already exists. The bootstrap is what creates
		// that directory, so pre-create it here before app.Run kicks
		// off discovery - otherwise BootstrapModule sees an empty
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

		let app = scope BootstrapApp();
		return app.Run(.()
		{
			Title = "Tower Defense Bootstrap",
			Width = 640,
			Height = 360,
			TargetWidth = 640,
			TargetHeight = 360,
			EnableShaderCache = true
		});
	}
}
