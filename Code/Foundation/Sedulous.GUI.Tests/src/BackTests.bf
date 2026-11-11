using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// The `back` command: Escape, Back (a phone's back button) and the pad's East run it through the keymap; the topmost auto popup
// answers it by closing, before anything under it; a modal dialog answers it as its close button
// does; else what handles it on the focus path (a game's screen) does; a game rebinds or unbinds it
// like any key.

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

/// Back: Escape, Back and the pad's East, popups first, a modal dialog, then the focus path; rebound and
/// unbound.
class BackTests
{
	[Test]
	public static void EscapeBackAndThePadsEastRunItAndTheScreenOnTheFocusPathHearsIt()
	{
		let bed = scope BackBed();
		bed.Escape();
		Test.Assert(bed.Backs == 1);
		bed.D.InjectPadButton(.East);
		Test.Assert(bed.Backs == 2);
		bed.D.InjectKeyDown((uint32)KeyCode.Back); // a phone's back button
		Test.Assert(bed.Backs == 3);
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

	[Test]
	public static void AModalDialogAnswersItAsItsCloseButtonDoesAndOnlyWhileOpen()
	{
		let bed = scope BackBed();
		let window = new Window();
		defer window.ReleaseRef();
		window.Size = .(200.0f, 120.0f);
		int closed = 0;
		window.SetOnClose(new [&] () => { ++closed; });
		window.OpenModal(bed.Root);
		bed.Escape();
		Test.Assert(!window.IsOpen);
		Test.Assert(closed == 1);
		Test.Assert(bed.Backs == 0); // what was under the modal is inert

		// One that may not be closed keeps its back to itself: under it nothing hears it.
		window.Closable = false;
		window.OpenModal(bed.Root);
		bed.Escape();
		Test.Assert(window.IsOpen);
		Test.Assert(bed.Backs == 0);
		window.Close();

		// Not modal, it does not answer: the screen does.
		window.Closable = true;
		window.Open(bed.Screen);
		bed.D.FocusNode = bed.ScreenButton;
		bed.Escape();
		Test.Assert(window.IsOpen);
		Test.Assert(bed.Backs == 1);
	}

	[Test]
	public static void AMessageBoxPicksItsCancelResultAPopupOpenedInItClosesFirst()
	{
		let bed = scope BackBed();
		var got = MessageBox.Result.Ok;
		let dialog = new MessageBox();
		defer dialog.ReleaseRef();
		dialog.Configure("Confirm", "Delete it?", .OkCancel);
		dialog.SetOnResult(new [&] (result) => { got = result; });
		dialog.OpenModal(bed.Root);
		let list = bed.OpenAuto(dialog.ButtonAt(1)); // a combo box's list in the dialog
		defer list.ReleaseRef();
		bed.D.InjectPadButton(.East);
		Test.Assert(!bed.D.IsPopupOpen(list));
		Test.Assert(dialog.IsOpen);
		bed.Escape();
		Test.Assert(!dialog.IsOpen);
		Test.Assert(got == .Cancel);
		Test.Assert(bed.Backs == 0);
	}
}
