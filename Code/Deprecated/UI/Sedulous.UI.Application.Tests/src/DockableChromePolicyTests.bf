using System;
using Sedulous.Shell;
using Sedulous.UI.Application;

namespace Sedulous.UI.Application.Tests;

/// The dockable window chrome ruling.
///
/// [[RuntimeDockableWindowHost]] itself needs a live graphics device and a UI host, so what is
/// pinned here is the pure platform policy it resolves through. The host side wiring, the chrome
/// flag reaching the panel, the close routing and the adorner behaviour, is pinned headless in
/// the toolkit's docking tests against a fake host.
class DockableChromePolicyTests
{
	/// Linux window systems default to OS chromed floats: Wayland punishes application
	/// positioned borderless windows and XWayland blocks cross monitor drags. The ruling is ONE
	/// platform default with no true X11 special case. Everything else keeps borderless floats.
	[Test]
	public static void LinuxWindowSystemsPreferOSChromedDockables()
	{
		Test.Assert(DockableChromePolicy.PrefersOSChrome(.X11));
		Test.Assert(DockableChromePolicy.PrefersOSChrome(.Wayland));

		Test.Assert(!DockableChromePolicy.PrefersOSChrome(.Win32));
		Test.Assert(!DockableChromePolicy.PrefersOSChrome(.Cocoa));
		Test.Assert(!DockableChromePolicy.PrefersOSChrome(.Web));
		Test.Assert(!DockableChromePolicy.PrefersOSChrome(.Unknown));
	}
}
