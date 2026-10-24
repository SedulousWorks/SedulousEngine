using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// The `back` command: Escape and the pad's East run it through the keymap; the topmost auto popup
// answers it by closing, before anything under it; else what handles it on the focus path (a
// game's screen) does; a game rebinds or unbinds it like any key.

/// A GUI holding a "screen" that counts the `back`s it hears, with a focused button on it. The root
/// and the tree go with it.
class BackBed
{
	public SceneRoot Root = SceneFixtures.NewScene(400.0f, 300.0f) ~ _.ReleaseRef();
	public UIWidget Screen = new .() ~ _.ReleaseRef();
	public Button ScreenButton = new .() ~ _.ReleaseRef();
	public int Backs = 0;

	public this()
	{
		Screen.Size = .(400.0f, 300.0f);
		Root.AddChild(Screen);
		ScreenButton.Size = .(60.0f, 20.0f);
		Screen.AddChild(ScreenButton);
		Screen.OnCommand(cBackCommand, new (command) => { Backs++; });
		D.FocusNode = ScreenButton;
	}

	public EventDispatcher D => Root.EventDispatcher;

	public void Escape()
	{
		D.InjectKeyDown((uint32)KeyCode.Escape);
	}

	/// An auto popup 50 by 50 opened from `owner`, held by the caller.
	public UIWidget OpenAuto(Node owner)
	{
		let popup = new UIWidget();
		popup.Size = .(50.0f, 50.0f);
		D.OpenPopup(owner, popup, SceneFixtures.At(.(100.0f, 100.0f)));
		return popup;
	}
}

/// Back: Escape and the pad's East, popups first, then the focus path; rebound and unbound.
class BackTests
{
	[Test]
	public static void EscapeAndThePadsEastRunItAndTheScreenOnTheFocusPathHearsIt()
	{
		let bed = scope BackBed();
		bed.Escape();
		Test.Assert(bed.Backs == 1);
		bed.D.InjectPadButton(.East);
		Test.Assert(bed.Backs == 2);
		Test.Assert(bed.Root.IsCommandAvailable(cBackCommand));
	}

	[Test]
	public static void TheTopmostAutoPopupClosesFirstOneAtATimeWhetherOrNotItHoldsTheFocus()
	{
		let bed = scope BackBed();
		let outer = bed.OpenAuto(bed.ScreenButton);
		defer outer.ReleaseRef();
		let inner = bed.OpenAuto(outer); // a submenu
		defer inner.ReleaseRef();
		Test.Assert(bed.D.PopupCount == 2);
		bed.Escape();
		Test.Assert(!bed.D.IsPopupOpen(inner));
		Test.Assert(bed.D.IsPopupOpen(outer));
		bed.D.InjectPadButton(.East);
		Test.Assert(!bed.D.IsPopupOpen(outer));
		Test.Assert(bed.Backs == 0); // the screen under them heard neither
		bed.Escape();
		Test.Assert(bed.Backs == 1);
	}

	[Test]
	public static void AGameUnbindsEscapeFromItAndEscapeClosesNothing()
	{
		let bed = scope BackBed();
		bed.Root.Context.Keymap.Bind("escape", "");
		let popup = bed.OpenAuto(bed.ScreenButton);
		defer popup.ReleaseRef();
		bed.Escape();
		Test.Assert(bed.D.IsPopupOpen(popup));
		Test.Assert(bed.Backs == 0);
		bed.D.InjectPadButton(.East); // the pad's binding stands
		Test.Assert(!bed.D.IsPopupOpen(popup));
	}

	[Test]
	public static void AFocusedWidgetsOwnEscapeStillComesFirst()
	{
		let bed = scope BackBed();
		bed.ScreenButton.AddEventListener(.KeyDown, new (e) => { e.Handled = true; });
		bed.Escape();
		Test.Assert(bed.Backs == 0);
		bed.D.InjectPadButton(.East); // the pad's East is `back` first, by its binding
		Test.Assert(bed.Backs == 1);
	}
}
