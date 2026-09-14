using System;
using Sedulous.Graphics;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Shell;

namespace Samples.MultiWindow;

/// Two OS windows sharing ONE graphics device.
///
/// Not an RHI sample: what it exercises is the host's per window render loop and the runtime
/// window creation a detachable panel would use. Each window clears to its own colour, which
/// is what shows the presentation really is independent.
class MultiWindowApp : IApplication
{
	private RenderWindow mSecond = null;

	public void OnStartup(IApplicationHost host)
	{
		// The MAIN window already has its render window from the host's start. This is the
		// second, opened at runtime through the same call a detached panel makes.
		WindowSettings windowSettings = .();
		windowSettings.Title = "MultiWindow - Detached";
		windowSettings.Width = 480;
		windowSettings.Height = 360;
		mSecond = host.OpenWindow(windowSettings, .());

		Console.WriteLine("MultiWindow: two windows up - close the main window to exit.");
	}

	public void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		let color = (frame.Window == mSecond) ? ClearColor(0.85f, 0.45f, 0.20f, 1.0f)
			: ClearColor.CornflowerBlue;
		frame.BeginBackbufferPass(color);
		frame.EndBackbufferPass();
	}

	public void OnShutdown(IApplicationHost host)
	{
		Console.WriteLine("MultiWindow: shutting down.");
	}
}
