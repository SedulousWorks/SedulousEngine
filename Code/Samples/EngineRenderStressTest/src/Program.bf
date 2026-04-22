namespace EngineRenderStressTest;

using System;

class Program
{
	static int Main(String[] args)
	{
		let app = scope RenderStressTestApp();
		app.Run(.() { Title = "Render Stress Test", Width = 1280, Height = 720, EnableValidation = false });
		return 0;
	}
}
