using Sedulous.Shell;

namespace Sedulous.UI.Application;

/// Which way a platform wants its floating dock windows dressed.
///
/// Its own type because the rule is a PLATFORM ruling rather than host state, so it can be
/// tested without a graphics device and read by anything that needs to predict the default.
static class DockableChromePolicy
{
	/// Linux window systems get OS chromed floats.
	///
	/// Wayland punishes application positioned borderless windows, and XWayland blocks dragging
	/// one between monitors. There is deliberately NO true X11 special case: one platform
	/// default is easier to reason about than two that differ by which compositor happens to be
	/// running. Everything else keeps borderless floats with application drawn chrome.
	public static bool PrefersOSChrome(WindowSystem system) =>
		(system == .X11) || (system == .Wayland);
}
