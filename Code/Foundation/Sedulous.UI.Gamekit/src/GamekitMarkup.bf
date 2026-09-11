using System;
using Sedulous.UI;

namespace Sedulous.UI.Gamekit;

/// Teaches the markup loader the `<screen>` element, so a document whose root is a screen
/// builds a [[UIScreen]] instead of failing to resolve its element name.
///
/// Calling this is OPTIONAL: the ScreenStack wraps a non screen document root in a default
/// UIScreen, so a game that authors plain documents never needs it. Register when the screens
/// themselves want to declare their mode, transition or default focus in markup.
static class GamekitMarkup
{
	/// Idempotent; the screen host calls it at startup.
	///
	/// The guard ASKS THE REGISTRY rather than keeping a flag of its own. A flag survives
	/// MarkupRegistry.Clear, which tests call between cases, and would then report a
	/// registration that no longer exists.
	public static void Register()
	{
		if (MarkupRegistry.IsRegistered("screen"))
			return;

		MarkupRegistry.RegisterView("screen", new () => (View)new UIScreen());

		MarkupRegistry.RegisterProperty("screen", "mode", new (view, value) =>
			{
				if (let screen = view as UIScreen)
					screen.SetModeFromString(value);
			});
		MarkupRegistry.RegisterProperty("screen", "transition", new (view, value) =>
			{
				if (let screen = view as UIScreen)
					screen.SetTransitionFromString(value);
			});
		MarkupRegistry.RegisterProperty("screen", "in-transition", new (view, value) =>
			{
				if (let screen = view as UIScreen)
					screen.SetInTransitionFromString(value);
			});
		MarkupRegistry.RegisterProperty("screen", "out-transition", new (view, value) =>
			{
				if (let screen = view as UIScreen)
					screen.SetOutTransitionFromString(value);
			});
		MarkupRegistry.RegisterProperty("screen", "default-focus", new (view, value) =>
			{
				if (let screen = view as UIScreen)
					screen.SetDefaultFocus(value);
			});
	}
}
