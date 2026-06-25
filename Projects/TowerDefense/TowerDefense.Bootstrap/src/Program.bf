namespace TowerDefense.Bootstrap;

using System;
using Sedulous.Engine.App;

class Program
{
	public static int Main(String[] args)
	{
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
