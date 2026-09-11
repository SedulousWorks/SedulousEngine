using System;
using Sedulous.Core;
using Sedulous.Graphics;
using Sedulous.Graphics.Null;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.Shell.Null;
using Sedulous.UI;
using Sedulous.UI.Application;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Application.Tests;

/// The floating window host against a real UIHost over the null backend.
///
/// Headless, but NOT a fake: the reference counting this is about only happens where the real
/// UIHost takes the root and the real payload releases it, which is exactly what a hand written
/// stub would paper over.
class RuntimeDockableWindowHostTests
{
	private class FakeApplicationHost : IApplicationHost
	{
		private Context mContext = new .() ~ delete _;
		private IShell mShell;
		private GraphicsDevice mGraphics;
		private RenderWindow mMainWindow;

		public this(IShell shell, GraphicsDevice graphics, RenderWindow mainWindow)
		{
			mShell = shell;
			mGraphics = graphics;
			mMainWindow = mainWindow;
		}

		public IShell Shell => mShell;
		public GraphicsDevice Graphics => mGraphics;
		public RenderWindow MainRenderWindow => mMainWindow;

		public Context Context => mContext;

		public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc)
		{
			// One window is enough: the host only needs something to attach a root to.
			return mMainWindow;
		}

		public void CloseWindow(RenderWindow window) {}
		public void RequestExit(int code = 0) {}
	}

	/// Double clicking a float's title bar redocks it, which destroys the window. The host's
	/// entry and the UI host both held the root; releasing it twice drove its children's counts
	/// negative and the dock tree's queued deletion then tripped on one.
	[Test]
	public static void DestroyingAFloatReleasesItsRootExactlyOnce()
	{
		let shell = scope NullShell();
		Test.Assert(NullGraphics.CreateDevice(2) case .Ok(let graphics));
		defer delete graphics;

		Test.Assert(graphics.CreateRenderWindow(shell.MainWindow, .()) case .Ok(let window));
		defer delete window;

		let uiHost = scope UIHost(graphics, shell, null);
		let appHost = scope FakeApplicationHost(shell, graphics, window);
		let dockHost = scope RuntimeDockableWindowHost(appHost, uiHost);

		let floating = new DockableWindow(new DockablePanel("Floating"));

		// The host takes the view; the root it builds for it is what this is about.
		dockHost.CreateDockableWindow(floating, 200, 150, 10, 10);
		dockHost.DestroyDockableWindow(floating);
	}
}
