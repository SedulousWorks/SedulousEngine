using System;
using Sedulous.Graphics;
using Sedulous.Runtime.Client;

namespace Samples.HelloWindow;

/// The smallest application there is: a window, a frame loop, and a cleared backbuffer.
///
/// What it demonstrates is the PATH rather than any feature: the core, the runtime's context
/// and subsystems, the shell, and the host driving an application through them. Everything
/// else in the samples is this plus content.
class HelloWindowApp : IApplication
{
	private float mElapsed = 0.0f;
	private uint64 mFrames = 0;

	public void OnStartup(IApplicationHost host)
	{
		Console.WriteLine("HelloWindow: started - close the window to exit.");
	}

	public void OnUpdate(IApplicationHost host, float deltaTime)
	{
		mElapsed += deltaTime;
		mFrames++;
	}

	public void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		frame.Clear(0.10f, 0.10f, 0.12f, 1.0f); // a calm dark grey
	}

	public void OnShutdown(IApplicationHost host)
	{
		Console.WriteLine("HelloWindow: shutting down.");
	}
}
