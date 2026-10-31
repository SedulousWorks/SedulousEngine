using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The modal window and the message box: OpenModal confines input to the dialog (background
/// clicks are swallowed by the dispatcher's modal popup); the message box shows the right buttons
/// and reports the pressed result, then closes; one a dispatcher's modal interceptor refuses never
/// shows and answers as its cancel (a window as its close).
class MessageBoxTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// Sum of a node's positions up to the root, plus half its size = its world-space centre
	/// (identity transforms, matching the popup/menu model). Used to click a nested button.
	private static Float2 WorldCenter(Node node)
	{
		var p = Float2(0.0f, 0.0f);
		for (var c = node; (c != null) && (c.Parent != null); c = c.Parent)
			p = .(p.X + c.Position.X, p.Y + c.Position.Y);
		let s = node.Size;
		return .(p.X + s.X * 0.5f, p.Y + s.Y * 0.5f);
	}

	[Test]
	public static void OpenModalCentresItAsAModalPopupOfItsOwner()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;

		let window = new Window();
		defer window.ReleaseRef();
		window.Size = .(200.0f, 100.0f);
		window.OpenModal(root);

		Test.Assert(window.IsOpen);
		Test.Assert(window.IsModal);
		Test.Assert(window.Parent == root);
		Test.Assert(d.TopPopup == window);
		Test.Assert(Near(window.Position.X, 100.0f)); // (400-200)/2
		Test.Assert(Near(window.Position.Y, 150.0f)); // (400-100)/2
		Test.Assert(root.ChildCount == 1); // the window (its backdrop is the top layer's)
	}

	[Test]
	public static void AModalSwallowsClicksOnTheBackground()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;

		int backgroundClicks = 0;
		let background = new Button();
		defer background.ReleaseRef();
		background.Size = .(100.0f, 40.0f);
		background.Position = .(0.0f, 0.0f); // top-left corner
		background.SetOnClick(new [&] () => { ++backgroundClicks; });
		root.AddChild(background);

		let window = new Window();
		defer window.ReleaseRef();
		window.Size = .(200.0f, 100.0f); // centred -> covers (100,150)-(300,250)
		window.OpenModal(root);

		// Click the background button (outside the modal) -> swallowed.
		d.InjectMouseDown(.(50.0f, 20.0f), .Left);
		d.InjectMouseUp(.(50.0f, 20.0f), .Left);
		Test.Assert(backgroundClicks == 0);
		Test.Assert(d.FocusNode != background);
	}

	[Test]
	public static void CloseTakesTheModalPopupDownAndCallsOnClose()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;

		int closed = 0;
		let window = new Window();
		defer window.ReleaseRef();
		window.Size = .(200.0f, 100.0f);
		window.SetOnClose(new [&] () => { ++closed; });
		window.OpenModal(root);
		Test.Assert(root.ChildCount == 1);

		window.Close();
		Test.Assert(!window.IsOpen);
		Test.Assert(window.Parent == null);
		Test.Assert(d.PopupCount == 0);
		Test.Assert(root.ChildCount == 0); // the window removed (its backdrop is the top layer's)
		Test.Assert(closed == 1);
	}

	[Test]
	public static void NonModalOpenAddsNoScrimAndNoModalRoot()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;

		let window = new Window();
		defer window.ReleaseRef();
		window.Size = .(200.0f, 100.0f);
		window.Open(root);
		Test.Assert(window.IsOpen);
		Test.Assert(!window.IsModal);
		Test.Assert(d.PopupCount == 0);
		Test.Assert(root.ChildCount == 1); // just the window
	}

	[Test]
	public static void ConfigureShowsTheRightButtonsPerStyle()
	{
		let ok = new MessageBox();
		defer ok.ReleaseRef();
		ok.Configure("Hi", "All good.", .Ok);
		Test.Assert(ok.ButtonCount == 1);
		Test.Assert(ok.Message == "All good.");

		let okCancel = new MessageBox();
		defer okCancel.ReleaseRef();
		okCancel.Configure("?", "Proceed?", .OkCancel);
		Test.Assert(okCancel.ButtonCount == 2);

		let yesNo = new MessageBox();
		defer yesNo.ReleaseRef();
		yesNo.Configure("?", "Save?", .YesNo);
		Test.Assert(yesNo.ButtonCount == 2);
	}

	[Test]
	public static void PressingAButtonReportsTheResultAndCloses()
	{
		let root = SceneFixtures.NewScene(500.0f, 500.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;

		var got = MessageBox.Result.Cancel;
		int results = 0;
		let dialog = new MessageBox();
		defer dialog.ReleaseRef();
		dialog.Configure("Confirm", "Delete it?", .OkCancel);
		dialog.SetOnResult(new [&] (result) =>
			{
				got = result;
				++results;
			});
		dialog.OpenModal(root);
		root.UpdateLayout(); // its content flows: its buttons are placed by the layout pass

		// Buttons: [Cancel, OK] (OK rightmost). Click OK.
		let okButton = dialog.ButtonAt(1);
		Test.Assert(okButton != null);
		let center = WorldCenter(okButton);
		d.InjectMouseDown(center, .Left);
		d.InjectMouseUp(center, .Left);

		Test.Assert(results == 1);
		Test.Assert(got == .Ok);
		Test.Assert(!dialog.IsOpen); // closed after the result
		Test.Assert(d.PopupCount == 0);
	}

	/// A box nothing else holds (an editor's prompt: made, opened, its reference dropped) tells its
	/// answer after its close let the popup layer's reference go: it lives until the event is out.
	[Test]
	public static void OneOnlyItsPopupHoldsTellsItsAnswerAfterClosing()
	{
		let root = SceneFixtures.NewScene(500.0f, 500.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;

		let answer = scope String();
		Button okButton = null;
		{
			let @box = new MessageBox();
			@box.Configure("Confirm", "Delete it?", .OkCancel);
			@box.AddEventListener(.Changed, new (e) => { answer.Set(@box.ResultName); });
			@box.OpenModal(root);
			root.UpdateLayout();
			okButton = @box.ButtonAt(1);
			@box.ReleaseRef(); // the popup layer holds it alone now
		}
		Test.Assert(okButton != null);
		let center = WorldCenter(okButton);
		d.InjectMouseDown(center, .Left);
		d.InjectMouseUp(center, .Left);

		Test.Assert(answer == "ok");
		Test.Assert(d.PopupCount == 0);
	}

	[Test]
	public static void ItsCloseButtonClosesItClosableAndResizableShowOrHideItsButtonAndGrip()
	{
		let root = SceneFixtures.NewScene(500.0f, 500.0f);
		defer root.ReleaseRef();
		let window = new Window();
		defer window.ReleaseRef();
		window.Size = .(240.0f, 160.0f);
		window.Title = "Tools";
		window.Open(root);
		root.UpdateLayout();
		Test.Assert(window.IsOpen);
		Test.Assert(window.Closable);
		Test.Assert(window.Resizable);
		// The close button sits at the title bar's right end.
		let w = window.ScreenBounds;
		let close = Float2(w.X + w.Width - 16.0f, w.Y + 14.0f);
		let d = root.EventDispatcher;
		d.InjectMouseDown(close, .Left);
		d.InjectMouseUp(close, .Left);
		Test.Assert(!window.IsOpen);

		window.Closable = false;
		window.Resizable = false;
		window.Open(root);
		root.UpdateLayout();
		d.InjectMouseDown(close, .Left);
		d.InjectMouseUp(close, .Left);
		Test.Assert(window.IsOpen); // no close button there now
		// No grip: a drag from the corner does not resize it.
		let corner = Float2(w.X + w.Width - 5.0f, w.Y + w.Height - 5.0f);
		d.InjectMouseDown(corner, .Left);
		d.InjectMouseMove(.(corner.X + 60.0f, corner.Y + 60.0f));
		d.InjectMouseUp(.(corner.X + 60.0f, corner.Y + 60.0f), .Left);
		Test.Assert(Near(window.Size.X, 240.0f));
	}

	[Test]
	public static void ItsMessageWrapsAndItsHeightFitsItItIsNotResizableItsCloseButtonAnswersAsEscape()
	{
		let root = SceneFixtures.NewScene(800.0f, 600.0f);
		defer root.ReleaseRef();
		let font = scope CachedFont(new MockFont(), null); // 6 px a byte
		let dialog = new MessageBox();
		defer dialog.ReleaseRef();
		dialog.Font = font;
		dialog.Configure("Confirm", "Short.", .OkCancel);
		let shortHeight = dialog.Size.Y;
		dialog.Configure("Confirm",
			"A much longer message that cannot fit on one line of a dialog this wide, so it wraps onto several lines, and the dialog grows to hold them all.",
			.OkCancel);
		Test.Assert(dialog.Size.Y > shortHeight);
		Test.Assert(!dialog.Resizable);
		var got = MessageBox.Result.Ok;
		dialog.SetOnResult(new [&] (result) => { got = result; });
		dialog.OpenModal(root);
		root.UpdateLayout();
		dialog.RequestClose(); // its close button
		Test.Assert(got == .Cancel);
		Test.Assert(!dialog.IsOpen);
	}

	[Test]
	public static void UnderTheThemeItsMessageWrapsStyledAfterItIsWrittenAndTheWindowTakesTheThemesRoundedBox()
	{
		let root = SceneFixtures.NewScene(800.0f, 600.0f);
		defer root.ReleaseRef();
		let font = scope CachedFont(new MockFont(), null);
		// Written first, as markup does, then styled: the sheet's white-space reaches the message
		// after its box sized itself.
		MessageBox Make(StringView text)
		{
			let dialog = new MessageBox();
			dialog.Font = font;
			dialog.Configure("Confirm", text, .Ok);
			root.AddChild(dialog);
			return dialog;
		}
		let shortBox = Make("Short.");
		defer shortBox.ReleaseRef();
		let longBox = Make("A much longer message that cannot fit on one line of a dialog this wide, so it wraps onto several lines, and the dialog grows to hold them all.");
		defer longBox.ReleaseRef();
		let styles = scope StyleManager();
		let theme = scope StyleSheet();
		CSSParser.Parse(Theme.DefaultThemeCSS, theme);
		styles.UserAgentSheet = theme;
		styles.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(longBox.Size.Y >= shortBox.Size.Y + 24.0f); // three lines of 12 px, not one
		Test.Assert(longBox.IsBoxFromStyle);
		Test.Assert(!longBox.Box.Radii.IsZero);
		Test.Assert(!longBox.Box.Shadows.IsEmpty);
	}

	[Test]
	public static void AMessageWrittenInLinesKeepsThemAsWellAsWrappingWithOrWithoutTheTheme()
	{
		let root = SceneFixtures.NewScene(800.0f, 600.0f);
		defer root.ReleaseRef();
		let font = scope CachedFont(new MockFont(), null);
		MessageBox Make(StringView text)
		{
			let dialog = new MessageBox();
			dialog.Font = font;
			dialog.Configure("Unsaved changes", text, .Ok);
			root.AddChild(dialog);
			return dialog;
		}
		let one = Make("These have unsaved changes: a b");
		defer one.ReleaseRef();
		let lines = Make("These have unsaved changes:\n    a\n    b");
		defer lines.ReleaseRef();
		root.UpdateLayout();
		Test.Assert(lines.Size.Y >= one.Size.Y + 24.0f); // three lines of 12 px, not one
		let styles = scope StyleManager();
		let theme = scope StyleSheet();
		CSSParser.Parse(Theme.DefaultThemeCSS, theme);
		styles.UserAgentSheet = theme;
		styles.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(lines.Size.Y >= one.Size.Y + 24.0f);
	}

	[Test]
	public static void ShownInNoGUIItRefusesRatherThanBecomingItsOwnChild()
	{
		let dialog = new MessageBox();
		defer dialog.ReleaseRef();
		Test.Assert(!dialog.Show());
		Test.Assert(dialog.Parent == null);
		Test.Assert(dialog.GetChildIndex(dialog) == Node.cInvalidIndex);
		let window = new Window();
		defer window.ReleaseRef();
		window.OpenModal(window); // inside itself: refused
		Test.Assert(!window.IsOpen);
	}

	[Test]
	public static void AButtonOfTheCallersOwnAnswersWithItsName()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let dialog = new MessageBox();
		defer dialog.ReleaseRef();
		root.AddChild(dialog);
		dialog.Configure("Save?", "Unsaved changes.", .OkCancel);
		dialog.AddButton("Discard", "discard");
		Test.Assert(dialog.ButtonCount == 3);
		bool standard = false;
		dialog.SetOnResult(new [&] (result) => { standard = true; });
		Test.Assert(dialog.Show());
		Test.Assert(dialog.ButtonAt(2).HandleActivate()); // as Return on it would
		Test.Assert(dialog.ResultName == "discard");
		Test.Assert(!standard); // no standard result
	}

	[Test]
	public static void ItsButtonsLabelsFollowTheGUIsLanguageWhereATableHasThemElseEnglish()
	{
		let table = scope Sedulous.I18N.StringTable();
		Test.Assert(table.Set("gui.ok", "pt", "Confirmar"));
		let loc = scope Sedulous.I18N.Localization();
		loc.AddTable(table);
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		root.Context.Localization = loc;
		defer { root.Context.Localization = null; }
		let @box = new MessageBox();
		defer @box.ReleaseRef();
		root.AddChild(@box);
		@box.Configure("?", "Proceed?", .OkCancel);
		root.Context.Update(SceneFixtures.Seconds(1.0 / 60.0));
		Test.Assert(@box.ButtonAt(1).Text == "OK"); // English: no table has it in English
		Test.Assert(@box.ButtonAt(0).Text == "Cancel");
		loc.SetLanguage("pt");
		root.Context.Update(SceneFixtures.Seconds(1.0 / 60.0));
		Test.Assert(@box.ButtonAt(1).Text == "Confirmar");
		Test.Assert(@box.ButtonAt(0).Text == "Cancel"); // no table names it: English
	}

	[Test]
	public static void EachButtonHasARoleThePrimaryIsFocusedTheCancelAnswersBack()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let @box = new MessageBox();
		defer @box.ReleaseRef();
		root.AddChild(@box);
		@box.Configure("Save?", "Unsaved changes.", .OkCancel);
		Test.Assert(@box.ButtonCount == 2);
		Test.Assert(@box.GetButtonRole(0) == .Cancel);
		Test.Assert(@box.ButtonAt(0).HasClass("cancel"));
		Test.Assert(@box.GetButtonRole(1) == .Primary);
		Test.Assert(@box.ButtonAt(1).HasClass("primary"));

		// A verb of the caller's own after them is not the default: the primary still is.
		@box.AddButton("Discard", "discard", .Destructive);
		Test.Assert(@box.ButtonAt(2).HasClass("destructive"));
		Test.Assert(@box.Show());
		Test.Assert(root.EventDispatcher.FocusNode == @box.ButtonAt(1));
		@box.RequestClose(); // as Escape would
		Test.Assert(@box.ResultName == "cancel");
	}

	[Test]
	public static void VerbsFromMarkupWithNoPrimaryADestructiveButtonIsNeverTheDefault()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let @box = new MessageBox();
		defer @box.ReleaseRef();
		root.AddChild(@box);
		Test.Assert(@box.SetMarkupAttribute("buttons", "Cancel:cancel:cancel | Delete:delete:destructive"));
		Test.Assert(@box.ButtonCount == 2);
		Test.Assert(@box.ButtonAt(0).Text == "Cancel");
		Test.Assert(@box.ButtonAt(1).Text == "Delete");
		Test.Assert(@box.GetButtonRole(1) == .Destructive);
		// Return alone cannot destroy: the focus goes to the last button that destroys nothing.
		Test.Assert(@box.DefaultButton == @box.ButtonAt(0));
		Test.Assert(@box.Show());
		Test.Assert(root.EventDispatcher.FocusNode == @box.ButtonAt(0));
		Test.Assert(@box.ButtonAt(1).HandleActivate());
		Test.Assert(@box.ResultName == "delete");

		// A verb with no result answers with its text in lower case; with no role it is normal.
		Test.Assert(@box.SetMarkupAttribute("buttons", "Keep|Create:create:primary"));
		Test.Assert(@box.ButtonCount == 2);
		Test.Assert(@box.GetButtonRole(0) == .Normal);
		Test.Assert(@box.DefaultButton == @box.ButtonAt(1));
		Test.Assert(@box.ButtonAt(0).HandleActivate());
		Test.Assert(@box.ResultName == "keep");

		// Back answers as the cancel button wherever it sits, not as the first one.
		Test.Assert(@box.SetMarkupAttribute("buttons", "Delete:delete:destructive | Keep:keep | Cancel:cancel:cancel"));
		@box.RequestClose(); // as Escape would
		Test.Assert(@box.ResultName == "cancel");
	}

	[Test]
	public static void RefusedByItsDispatchersModalInterceptorItNeverShowsAnsweringAsItsCancelAWindowAsItsClose()
	{
		let root = SceneFixtures.NewScene(500.0f, 500.0f);
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let asked = scope List<String>();
		defer { ClearAndDeleteItems!(asked); }
		d.SetModalInterceptor(new [&] (window) =>
			{
				if (let w = window as Window)
					asked.Add(new String(w.Title));
				return false;
			});

		let @box = new MessageBox();
		defer @box.ReleaseRef();
		@box.Configure("Unsaved changes", "Save?", .OkCancel);
		@box.AddButton("Discard", "discard", .Destructive);
		MessageBox.Result got = .Ok;
		int answers = 0;
		@box.SetOnResult(new [&] (result) =>
			{
				got = result;
				answers++;
			});
		int changed = 0;
		@box.AddEventListener(.Changed, new [&] (e) => { changed++; });
		@box.OpenModal(root);
		Test.Assert(!@box.IsOpen);
		Test.Assert(d.PopupCount == 0);
		Test.Assert(asked.Count == 1);
		Test.Assert(asked[0] == "Unsaved changes");
		Test.Assert(@box.ResultName == "cancel");
		Test.Assert(answers == 1);
		Test.Assert(got == .Cancel);
		Test.Assert(changed == 1);

		// A plain window answers as its close.
		let window = new Window();
		defer window.ReleaseRef();
		window.Title = "Preferences";
		int closes = 0;
		window.SetOnClose(new [&] () => { closes++; });
		window.OpenModal(root);
		Test.Assert(!window.IsOpen);
		Test.Assert(closes == 1);
		Test.Assert(asked.Count == 2);

		// The interceptor taken back: windows open again.
		delete d.TakeModalInterceptor();
		window.OpenModal(root);
		Test.Assert(window.IsOpen);
		window.Close();
	}
}
