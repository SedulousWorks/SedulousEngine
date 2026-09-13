using System;
using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;

namespace Sedulous.Engine.DefaultApp.Tests;

/// A headless host: no shell, no graphics, no windows, which is exactly the shape a command
/// line or test process presents. A null graphics device also exercises the texture factory's
/// gating.
class StubHost : IApplicationHost
{
	public Context Context { get; } = new .() ~ delete _;

	public IShell Shell => null;
	public GraphicsDevice Graphics => null;
	public RenderWindow MainRenderWindow => null;

	public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc) =>
		null;

	public void CloseWindow(RenderWindow window) {}
	public void RequestExit(int code = 0) {}
}
