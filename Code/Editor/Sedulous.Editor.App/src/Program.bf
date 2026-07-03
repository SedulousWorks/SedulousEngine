namespace Sedulous.Editor.App;

using System;
using Sedulous.Runtime.Client;
using Sedulous.RuntimeGraphics;
using Sedulous.Platform.SDL3;
using Sedulous.Editor;

class Program
{
	static int Main(String[] args)
	{
		let platform = scope SDL3Platform();
		platform.Initialize();
		defer platform.Shutdown();

		let gfxResult = GraphicsDevice.Create(.());
		if (gfxResult case .Err)
			return -1;
		let gfx = gfxResult.Value;
		defer delete gfx;

		let app = scope EditorApplication();
		return ApplicationHost.RunApplication(app, platform, gfx);
	}
}
