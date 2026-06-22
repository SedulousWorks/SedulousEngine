namespace EngineAnimationSandbox;

using System;
using Sedulous.Engine.App;

class Program
{
	public static int Main(String[] args)
	{
		let app = scope AnimationSandboxApp();
		return app.Run(.()
		{
			Title = "Engine Animation Sandbox",
			Width = 1280,
			Height = 720,
			EnableShaderCache = true,
			EnableValidation = false
		});
	}
}
