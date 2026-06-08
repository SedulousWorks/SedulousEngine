using System;
using Sedulous.Images.STB;
using Sedulous.Images.SDL;
namespace UISandbox;

class Program
{
	public static int Main(String[] args)
	{
		STBImageLoader.Initialize();
		SDLImageLoader.Initialize();

		let app = scope UISandboxApp();
		return app.Run(.()
		{
			Title = "UI Sandbox",
			Width = 1280,
			Height = 720,
			EnableShaderCache = true
		});
	}
}