namespace Sedulous.Editor.App;

using System;

class Program
{
	static int Main(String[] args)
	{
		let app = scope EditorApplication();
		return app.Run(.() {
			Title = "Sedulous Editor",
			Width = 1600,
			Height = 900,
			Resizable = true,
			Backend = .Vulkan,
			EnableValidation = true
		});
	}
}
