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
			Width = 1920,
			Height = 1080,
			TargetWidth = 1920,
			TargetHeight = 1080,
			EnableShaderCache = true
		});
	}
}
