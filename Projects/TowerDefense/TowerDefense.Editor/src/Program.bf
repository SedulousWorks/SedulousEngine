namespace TowerDefense.Editor;

using System;
using Sedulous.Editor;
using TowerDefense;

class Program
{
	static int Main(String[] args)
	{
		let module = scope TowerDefenseModule();
		let app = scope EditorApplication();
		app.Module = module;
		return app.Run(.() {
			Title = "Tower Defense Editor",
			Width = 1600,
			Height = 900,
			Resizable = true,
			Backend = .Vulkan,
			EnableValidation = true,
			SwapChainFormat = .BGRA8UnormSrgb
		});
	}
}
