namespace EngineSandbox;

using System;
using Sedulous.Engine.App;

class Program
{
	public static int Main(String[] args)
	{
		let app = scope SandboxApp();
		return app.Run(.()
		{
			Title = "Engine Sandbox",
			Width = 1280,
			Height = 720
		});
	}
}
