using System;
using Sedulous.UI;
using Sedulous.Engine.UI;

namespace Sedulous.Engine.UI.Tests;

/// The engine's own loading screen: its logo over the bar the player drives, with the control
/// names an authored loading document uses.
class DefaultLoadingScreenTests
{
	[Test]
	public static void TheEnginesLogoOverTheBarThePlayerDrives()
	{
		// A stand-in logo: the player passes the SedulousEngine logo's SVG text.
		const String cSvg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 885 200\"><rect width=\"885\" height=\"200\" fill=\"#F58F42\"/></svg>";
		let screen = DefaultLoadingScreen.Build(cSvg) as ViewGroup;
		Test.Assert(screen != null);
		defer screen.ReleaseRef();
		// The controls an authored loading document names, so the player drives either alike.
		Test.Assert(screen.FindByName<ProgressBar>("progress") != null);
		Test.Assert(screen.FindByName<Label>("status") != null);
		let logo = screen.FindByName<DrawableView>("logo");
		Test.Assert((logo != null) && (logo.Drawable != null));

		// No logo to draw: the bar alone.
		let bare = DefaultLoadingScreen.Build("") as ViewGroup;
		Test.Assert(bare != null);
		defer bare.ReleaseRef();
		Test.Assert(bare.FindByName<View>("logo") == null);
		Test.Assert(bare.FindByName<ProgressBar>("progress") != null);
		let unreadable = DefaultLoadingScreen.Build("not an svg") as ViewGroup;
		defer unreadable.ReleaseRef();
		Test.Assert(unreadable.FindByName<View>("logo") == null, "an unreadable logo is left out");
	}
}
