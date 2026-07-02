namespace Sedulous.Editor.App;

using System;
using Sedulous.Runtime.Client;
using Sedulous.RuntimeGraphics;
using Sedulous.Shell.SDL3;
using Sedulous.Editor;

class Program
{
	static int Main(String[] args)
	{
		let shell = scope SDL3Shell();
		shell.Initialize();
		defer shell.Shutdown();

		let gfxResult = GraphicsDevice.Create(.());
		if (gfxResult case .Err)
			return -1;
		let gfx = gfxResult.Value;
		defer delete gfx;

		let app = scope EditorApplication();
		return ApplicationHost.RunApplication(app, shell, gfx);
	}
}
