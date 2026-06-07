using System;
using Sedulous.Images.STB;
using Sedulous.Images.SDL;
namespace GUISandbox;

class Program
{
	public static int Main(String[] args)
	{
		STBImageLoader.Initialize();
		SDLImageLoader.Initialize();

		let app = scope GUISandboxApp();
		return app.Run(.()
		{
			Title = "UI Sandbox",
			Width = 1280,
			Height = 720,
			EnableShaderCache = true
		});
	}
}