namespace TowerDefense;

using System;
using Sedulous.Engine.App;

class Program
{
	public static int Main(String[] args)
	{
		let app = scope TowerDefenseApp();
		return app.Run(.()
		{
			Title = "Tower Defense",
			Width = 1366,
			Height = 768,
			TargetWidth = 1280,
			TargetHeight = 720,
			EnableShaderCache = true
		});
	}
}
