using Sedulous.Graphics;
using Sedulous.Shell;

namespace Sedulous.Runtime.Client.Tests;

/// Opens a second window at startup and counts how often it is asked to render.
class RenderApp : IApplication
{
	public RenderWindow Second = null;
	public int Renders = 0;

	public void OnStartup(IApplicationHost host)
		=> Second = host.OpenWindow(WindowSettings(), RenderWindowDesc());

	public void OnRenderWindow(IApplicationHost host, ref FrameContext frame) { Renders++; }
}
