using System;
using Sedulous.Core;
using Sedulous.Engine.Input;
using Sedulous.Engine.UI;
using Sedulous.Shell;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Tests;

/// The screen tier turned with the game's image: a landscape game on a portrait target lays out
/// at the game's shape and draws turned three quarters (its top on the screen's left), and a tap
/// where it draws a button presses that button.
class UIScreenTurnTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) <= 0.01f * Math.Max(1.0f, Math.Abs(b));

	/// Where a layout point of `place`'s root lands on its target.
	private static Float2 Drawn(UIScreenPlacement place, Float2 layout) =>
		TransformPoint2D(.(layout.X * place.DpiScale, layout.Y * place.DpiScale), place.Transform);

	[Test]
	public static void ALandscapeGamesScreenTierOnAPortraitTargetLaysOutLandscapeDrawnTurned()
	{
		let portrait = Float2(1080, 1920);
		let landscape = Float2(1920, 1080);
		let none = Float2(0, 0);

		// Nothing asks for a fit: the plain draw.
		Test.Assert(!UISubsystem.PlaceScreen(none, .Letterbox, .Any, portrait).Fitted);
		Test.Assert(!UISubsystem.PlaceScreen(none, .Letterbox, .Landscape, landscape).Fitted);

		// No resolution: the target's own pixels at the game's shape, one layout unit a pixel.
		let turned = UISubsystem.PlaceScreen(none, .Letterbox, .Landscape, portrait);
		Test.Assert(turned.Fitted && (turned.Turn == .ThreeQuarter));
		Test.Assert(Near(turned.Rect.Width, 1080) && Near(turned.Rect.Height, 1920));
		Test.Assert(Near(turned.DrawSize.X, 1920) && Near(turned.DrawSize.Y, 1080));
		Test.Assert(Near(turned.DpiScale, 1.0f));
		// The layout's corners where the turn puts them: its top-left at the screen's bottom-left,
		// its top-right at the top-left, its bottom-right (where the touch guide's buttons sit)
		// at the top-right.
		let topLeft = Drawn(turned, .(0, 0));
		let topRight = Drawn(turned, .(1920, 0));
		let bottomRight = Drawn(turned, .(1920, 1080));
		Test.Assert(Near(topLeft.X, 0) && Near(topLeft.Y, 1920), scope $"top-left at {topLeft.X}, {topLeft.Y}");
		Test.Assert(Near(topRight.X, 0) && Near(topRight.Y, 0), scope $"top-right at {topRight.X}, {topRight.Y}");
		Test.Assert(Near(bottomRight.X, 1080) && Near(bottomRight.Y, 0), scope $"bottom-right at {bottomRight.X}, {bottomRight.Y}");

		// A render resolution turned with it: 1280x720 fills the turned-back 1920x1080 at 1.5
		// pixels a unit, its layout corner still at the screen's top-right.
		let scaled = UISubsystem.PlaceScreen(.(1280, 720), .Letterbox, .Landscape, portrait);
		Test.Assert(scaled.Fitted && Near(scaled.DpiScale, 1.5f) && Near(scaled.DrawSize.X, 1920));
		let scaledCorner = Drawn(scaled, .(1280, 720));
		Test.Assert(Near(scaledCorner.X, 1080) && Near(scaledCorner.Y, 0));

		// Unturned, a resolution draws as it always did: letterboxed, no turn.
		let upright = UISubsystem.PlaceScreen(.(320, 180), .Letterbox, .Landscape, .(1280, 1080));
		Test.Assert(upright.Fitted && (upright.Turn == .None));
		Test.Assert(Near(upright.Rect.Y, 180) && Near(upright.DrawSize.X, 1280) && Near(upright.DpiScale, 4.0f));
		Test.Assert(upright.Transform == Float4x4.Identity());
	}

	[Test]
	public static void ATapWhereATurnedScreenDrawsAButtonPressesIt()
	{
		// A landscape game on a phone held upright: the screen tier laid out landscape and drawn
		// turned, the finger read through the turned fit (as the player's fitted input reads it).
		// The window point where the button is DRAWN is the one that presses it.
		let fixture = scope UITestFixture(true);
		let devices = scope PointerFakeDevices();
		let fitted = scope FittedInputSource(devices);
		let window = Float2(1080, 1920);
		fitted.Fit = .(.(0, 0, window.X, window.Y), .(1920, 1080), .Stretch, .ThreeQuarter);
		fixture.Input.SetSourceProvider(fitted);
		fixture.UI.SetScreenOrientation(.Landscape);
		let place = UISubsystem.PlaceScreen(.(0, 0), .Letterbox, .Landscape, window);
		Test.Assert(place.Fitted);

		fixture.UI.Screens.Push(UIScreenTierTests.MenuFor(fixture, "p"));
		let root = fixture.UI.ScreenRoot;
		root.ViewportSize = place.DrawSize; // as the turned draw lays it out
		root.DpiScale = place.DpiScale;
		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(root);
		let button = root.FindByName<Button>("p-top");
		Test.Assert(button != null);
		var clicks = 0;
		button.OnClick.Add(new [&clicks] (b) => { clicks++; });
		let at = Drawn(place, button.LocalToScreen(.(20, 10)));
		Test.Assert(at.X < window.X * 0.5f, "a button near the game's top is near the screen's left");

		devices.FakeTouch.Points.Clear();
		devices.FakeTouch.Points.Add(.(0, at.X / window.X, at.Y / window.Y, 1.0f, at.X, at.Y));
		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(root);
		devices.FakeTouch.Points[0].PointerX = at.X + 0.5f; // a finger never rests quite still
		fixture.Frame();
		devices.FakeTouch.Points.Clear();
		fixture.Frame();
		Test.Assert(clicks == 1, scope $"{clicks} clicks at ({at.X}, {at.Y})");
	}
}
