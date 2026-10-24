using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A focused field holding a value, 200 by 24 in a root 400 by 100, in the mock font (6px a
/// byte). The font, the root and the field go with it.
class FieldBed
{
	// Declared first, so it goes last: the field borrows it.
	public CachedFont Font = new .(new MockFont(), null) ~ delete _;
	public SceneRoot Root = SceneFixtures.NewScene(400.0f, 100.0f) ~ _.ReleaseRef();
	public TextField Field = new .() ~ _.ReleaseRef();

	public this(StringView value = default)
	{
		Field.Size = .(200.0f, 24.0f);
		Field.Font = Font;
		Root.AddChild(Field);
		if (value.Length > 0)
			Field.Text = value;
		Field.RequestFocus();
	}

	public EventDispatcher D => Root.EventDispatcher;
}

/// TextField: the keyboard and text-input path end to end. Text arrives through the dispatcher's
/// InjectText (routed to the focused node), editing keys through InjectKeyDown; a mock font (6px a
/// byte) drives caret placement.
class TextFieldTests
{
	private static bool Near(float a, float b) => TextFixtures.Near(a, b);
	private static uint32 Key(KeyCode k) => (uint32)k;

	[Test]
	public static void TypedTextIsInsertedAtTheCaretAndTheCaretAdvances()
	{
		let root = SceneFixtures.NewScene(200.0f, 100.0f);
		defer root.ReleaseRef();
		let f = new TextField();
		defer f.ReleaseRef();
		f.Size = .(100.0f, 24.0f);
		root.AddChild(f);
		let d = root.EventDispatcher;

		// Focus the field (text only routes to the focused node).
		f.RequestFocus();
		Test.Assert(f.IsFocused);

		d.InjectText("Hi");
		Test.Assert(f.Text == "Hi");
		Test.Assert(f.Caret == 2);

		// Move the caret to the start and insert there.
		d.InjectKeyDown(Key(.Home));
		Test.Assert(f.Caret == 0);
		d.InjectText("Oh ");
		Test.Assert(f.Text == "Oh Hi");
		Test.Assert(f.Caret == 3);
	}

	[Test]
	public static void TextOnlyReachesAFocusedField()
	{
		let root = SceneFixtures.NewScene(200.0f, 100.0f);
		defer root.ReleaseRef();
		let f = new TextField();
		defer f.ReleaseRef();
		f.Size = .(100.0f, 24.0f);
		root.AddChild(f);
		root.EventDispatcher.InjectText("nope"); // not focused: dropped
		Test.Assert(f.Text.Length == 0);
	}

	[Test]
	public static void BackspaceAndDeleteRemoveWholeCodepoints()
	{
		let root = SceneFixtures.NewScene(200.0f, 100.0f);
		defer root.ReleaseRef();
		let f = new TextField();
		defer f.ReleaseRef();
		f.Size = .(100.0f, 24.0f);
		root.AddChild(f);
		let d = root.EventDispatcher;
		f.RequestFocus();

		f.Text = "a\u{00E9}"; // 'a' (1) + 'é' (2 bytes), caret at the end (3)
		Test.Assert(f.Caret == 3);

		d.InjectKeyDown(Key(.Backspace)); // removes the whole 'é'
		Test.Assert(f.Text == "a");
		Test.Assert(f.Caret == 1);

		d.InjectKeyDown(Key(.Home));
		d.InjectKeyDown(Key(.Delete)); // removes 'a' at the front
		Test.Assert(f.Text.Length == 0);
		Test.Assert(f.Caret == 0);

		// Backspace at the start and delete at the end do nothing.
		d.InjectKeyDown(Key(.Backspace));
		d.InjectKeyDown(Key(.Delete));
		Test.Assert(f.Text.Length == 0);
	}

	[Test]
	public static void CaretNavigationStepsByCodepointAndClamps()
	{
		let f = new TextField();
		defer f.ReleaseRef();
		f.Size = .(100.0f, 24.0f);
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		root.AddChild(f);
		let d = root.EventDispatcher;
		f.RequestFocus();

		f.Text = "\u{00E9}\u{20AC}"; // 2 bytes + 3 bytes = 5 bytes, caret at 5
		d.InjectKeyDown(Key(.Home));
		Test.Assert(f.Caret == 0);
		d.InjectKeyDown(Key(.Right)); // over 'é'
		Test.Assert(f.Caret == 2);
		d.InjectKeyDown(Key(.Right)); // over '€'
		Test.Assert(f.Caret == 5);
		d.InjectKeyDown(Key(.Right)); // clamped at the end
		Test.Assert(f.Caret == 5);
		d.InjectKeyDown(Key(.Left)); // back over '€'
		Test.Assert(f.Caret == 2);
		d.InjectKeyDown(Key(.End));
		Test.Assert(f.Caret == 5);
	}

	[Test]
	public static void EachEditIsAnInputReturnAndLeavingCommitAChangeReturnSubmits()
	{
		let f = new TextField();
		defer f.ReleaseRef();
		f.Size = .(100.0f, 24.0f);
		let other = new TextField();
		defer other.ReleaseRef();
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		root.AddChild(f);
		root.AddChild(other);
		let d = root.EventDispatcher;
		f.RequestFocus();

		int inputs = 0;
		int changes = 0;
		int submits = 0;
		int inputEvents = 0;
		int changeEvents = 0;
		int submitEvents = 0;
		let last = scope String();
		f.SetOnTextChanging(new [&] (v) => { ++inputs; last.Set(v); });
		f.SetOnTextChanged(new [&] (v) => { ++changes; });
		f.SetOnSubmit(new [&] (v) => { ++submits; });
		f.AddEventListener(.Input, new [&] (e) => { ++inputEvents; });
		f.AddEventListener(.Changed, new [&] (e) => { ++changeEvents; });
		f.AddEventListener(.Submit, new [&] (e) => { ++submitEvents; });

		d.InjectText("x");
		Test.Assert(inputs == 1);
		Test.Assert(last == "x");
		d.InjectKeyDown(Key(.Backspace));
		Test.Assert(inputs == 2);
		Test.Assert(last.Length == 0);
		d.InjectKeyDown(Key(.Home)); // a move is no edit
		Test.Assert(inputs == 2);
		Test.Assert(inputEvents == 2);
		Test.Assert(changes == 0); // nothing committed yet (and the value is back where it was)

		d.InjectText("go");
		d.InjectKeyDown(Key(.Return));
		Test.Assert(changes == 1);
		Test.Assert(submits == 1);
		Test.Assert(changeEvents == 1);
		Test.Assert(submitEvents == 1);
		d.InjectKeyDown(Key(.Return)); // the same value: submitted again, not changed again
		Test.Assert(changes == 1);
		Test.Assert(submits == 2);

		d.InjectText("!");
		other.RequestFocus(); // leaving commits the new value
		Test.Assert(changes == 2);
		Test.Assert(submits == 2);

		f.Text = "from code"; // code's value reports nothing
		Test.Assert(inputs == 4);
		Test.Assert(changes == 2);
	}

	[Test]
	public static void AMousePressFocusesAndPlacesTheCaretAtTheNearestBoundary()
	{
		let cf = scope CachedFont(new MockFont(), null); // 6px a byte
		let root = SceneFixtures.NewScene(200.0f, 100.0f);
		defer root.ReleaseRef();
		let f = new TextField();
		defer f.ReleaseRef();
		f.Size = .(100.0f, 24.0f);
		f.Font = cf;
		f.Text = "abcd"; // widths at the boundaries: 0, 6, 12, 18, 24
		root.AddChild(f);
		let d = root.EventDispatcher;

		// A press near x = 13 (content x, no padding): the nearest boundary is offset 2 (12).
		d.InjectMouseDown(.(13.0f, 12.0f), .Left);
		Test.Assert(f.IsFocused);
		Test.Assert(f.Caret == 2);

		// Past the end: the caret at the end.
		d.InjectMouseDown(.(90.0f, 12.0f), .Left);
		Test.Assert(f.Caret == 4);

		// At the far left: the caret at the start.
		d.InjectMouseDown(.(0.0f, 12.0f), .Left);
		Test.Assert(f.Caret == 0);
	}

	[Test]
	public static void TheCaretDrawsOnlyWhileFocused()
	{
		let cf = scope CachedFont(new MockFont(), null);
		let f = new TextField();
		defer f.ReleaseRef();
		f.Size = .(100.0f, 24.0f);
		f.Font = cf;

		// Not focused: no caret geometry (an empty text, and no glyph atlas: no glyph geometry).
		Test.Assert(WidgetFixtures.DrawnGeometry(f) == 0);

		// Focused (through a root, so RequestFocus routes): the caret is drawn.
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		root.AddChild(f);
		f.RequestFocus();
		Test.Assert(WidgetFixtures.DrawnGeometry(f) > 0); // the caret's quad
	}

	[Test]
	public static void WantsTextInputDrivesTheDispatchersTextInputWishByFocus()
	{
		let root = SceneFixtures.NewScene(200.0f, 100.0f);
		defer root.ReleaseRef();
		let f = new TextField();
		defer f.ReleaseRef();
		f.Size = .(100.0f, 24.0f);
		let plain = new Button(); // a widget that does not edit
		defer plain.ReleaseRef();
		plain.Size = .(100.0f, 24.0f);
		root.AddChild(f);
		root.AddChild(plain);
		let d = root.EventDispatcher;

		Test.Assert(f.WantsTextInput); // an editable field wants text input
		Test.Assert(!plain.WantsTextInput); // a button does not

		Test.Assert(!d.WantsTextInput); // nothing focused
		f.RequestFocus();
		Test.Assert(d.WantsTextInput); // the field is focused
		plain.RequestFocus();
		Test.Assert(!d.WantsTextInput); // focus moved to a widget that does not edit

		// A disabled field does not want text input.
		f.RequestFocus();
		f.Enabled = false;
		Test.Assert(!f.WantsTextInput);
		Test.Assert(!d.WantsTextInput);
	}

	[Test]
	public static void TheBlinkTogglesTheCaretOverTimeWhileFocused()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let f = new TextField();
		defer f.ReleaseRef();
		root.AddChild(f);
		root.Size = .(200.0f, 100.0f);
		root.UpdateLayout();
		f.RequestFocus(); // shown at once
		Test.Assert(f.IsCaretShown);

		// The field drives its own blink on the GUI's clock: off after half a period, on after
		// another, and the GUI asks for frames meanwhile.
		void Frames(SceneRoot scene, int n)
		{
			for (int i = 0; i < n; ++i)
				scene.Context.Update(SceneFixtures.Seconds(0.1));
		}
		Frames(root, 3);
		Test.Assert(f.IsCaretShown);
		Test.Assert(root.NeedsFrame());
		Frames(root, 3); // 0.6 s
		Test.Assert(!f.IsCaretShown);
		Frames(root, 5); // 1.1 s
		Test.Assert(f.IsCaretShown);

		// Unfocused: no caret, and the blink stops asking for frames.
		f.ReleaseFocus();
		Frames(root, 2);
		Test.Assert(!f.IsCaretShown);
		Frames(root, 1);
		Test.Assert(!root.Context.ActionManager.AnyAction(scope (action, target) => target == f));
		// Focused again: it blinks again (a new tick), starting shown.
		f.RequestFocus();
		Test.Assert(f.IsCaretShown);
		Frames(root, 6);
		Test.Assert(!f.IsCaretShown);
	}

	// === Selection ===

	[Test]
	public static void ShiftAndTheArrowsExtendASelectionTheSelectionReportsItsText()
	{
		let fx = scope FieldBed("hello");
		fx.Field.Caret = 0;
		Test.Assert(!fx.Field.HasSelection);

		fx.D.InjectKeyDown(Key(.Right), KeyModShift);
		fx.D.InjectKeyDown(Key(.Right), KeyModShift);
		Test.Assert(fx.Field.HasSelection);
		Test.Assert(fx.Field.SelectedText == "he");
		Test.Assert(fx.Field.Caret == 2);

		// A plain Right collapses the selection to its right edge.
		fx.D.InjectKeyDown(Key(.Right));
		Test.Assert(!fx.Field.HasSelection);
		Test.Assert(fx.Field.Caret == 2);
	}

	[Test]
	public static void ShiftHomeSelectsToTheStartPlainLeftCollapsesToTheSelectionsStart()
	{
		let fx = scope FieldBed("hello");
		fx.Field.Caret = 5;
		fx.D.InjectKeyDown(Key(.Home), KeyModShift);
		Test.Assert(fx.Field.SelectedText == "hello");

		// Plain Left with a selection puts the caret at the selection's start (offset 0).
		fx.D.InjectKeyDown(Key(.Left));
		Test.Assert(!fx.Field.HasSelection);
		Test.Assert(fx.Field.Caret == 0);
	}

	[Test]
	public static void TypingOverASelectionReplacesIt()
	{
		let fx = scope FieldBed("hello");
		fx.Field.SelectAll();
		Test.Assert(fx.Field.SelectedText == "hello");
		fx.D.InjectText("X");
		Test.Assert(fx.Field.Text == "X");
		Test.Assert(fx.Field.Caret == 1);
		Test.Assert(!fx.Field.HasSelection);
	}

	[Test]
	public static void BackspaceAndDeleteRemoveTheWholeSelection()
	{
		let fx = scope FieldBed("hello");
		fx.Field.Caret = 1;
		fx.D.InjectKeyDown(Key(.Right), KeyModShift);
		fx.D.InjectKeyDown(Key(.Right), KeyModShift);
		fx.D.InjectKeyDown(Key(.Right), KeyModShift); // "ell" selected
		Test.Assert(fx.Field.SelectedText == "ell");
		fx.D.InjectKeyDown(Key(.Backspace));
		Test.Assert(fx.Field.Text == "ho");
		Test.Assert(fx.Field.Caret == 1);
	}

	// === Clipboard ===

	[Test]
	public static void CtrlCAndCtrlVCopyAndPasteASelectionThroughTheClipboard()
	{
		let clip = scope TestClipboard();
		let fx = scope FieldBed("hello");
		fx.D.Clipboard = clip;

		fx.Field.Caret = 0;
		fx.D.InjectKeyDown(Key(.Right), KeyModShift);
		fx.D.InjectKeyDown(Key(.Right), KeyModShift); // "he" selected
		fx.D.InjectKeyDown(Key(.C), KeyModCtrl);
		Test.Assert(clip.Text == "he");

		// Pasted at the end.
		fx.D.InjectKeyDown(Key(.End));
		fx.D.InjectKeyDown(Key(.V), KeyModCtrl);
		Test.Assert(fx.Field.Text == "hellohe");
	}

	[Test]
	public static void CtrlXCutsTheSelectionToTheClipboard()
	{
		let clip = scope TestClipboard();
		let fx = scope FieldBed("hello");
		fx.D.Clipboard = clip;

		fx.Field.SelectAll();
		fx.D.InjectKeyDown(Key(.X), KeyModCtrl);
		Test.Assert(clip.Text == "hello");
		Test.Assert(fx.Field.Text.Length == 0);
	}

	[Test]
	public static void APasteWithNoClipboardIsHarmless()
	{
		let fx = scope FieldBed("hi");
		fx.D.InjectKeyDown(Key(.V), KeyModCtrl); // no clipboard set: nothing happens
		Test.Assert(fx.Field.Text == "hi");
	}

	[Test]
	public static void PastedLineBreaksBecomeSpacesToKeepTheValueOnOneLine()
	{
		let clip = scope TestClipboard();
		clip.SetText("a\nb\r\nc");
		let fx = scope FieldBed();
		fx.D.Clipboard = clip;
		fx.D.InjectKeyDown(Key(.V), KeyModCtrl);
		Test.Assert(fx.Field.Text == "a b c");
	}

	// === Placeholder and max-length ===

	[Test]
	public static void APlaceholderIsStoredAndReported()
	{
		let f = new TextField();
		defer f.ReleaseRef();
		f.Placeholder = "Search...";
		Test.Assert(f.Placeholder == "Search...");
	}

	[Test]
	public static void MaxLengthCapsTypedInputAndTruncatesAPaste()
	{
		let clip = scope TestClipboard();
		let fx = scope FieldBed();
		fx.Field.MaxLength = 3;
		fx.D.InjectText("ab");
		fx.D.InjectText("cd"); // only 'c' fits (a cap of 3)
		Test.Assert(fx.Field.Text == "abc");

		// More input past the cap is dropped.
		fx.D.InjectText("z");
		Test.Assert(fx.Field.Text == "abc");

		// A paste is cut to the room left too (here: none).
		clip.SetText("XYZ");
		fx.D.Clipboard = clip;
		fx.D.InjectKeyDown(Key(.V), KeyModCtrl);
		Test.Assert(fx.Field.Text == "abc");
	}

	[Test]
	public static void MaxLengthCountsGraphemesNotBytesOrCodepoints()
	{
		let fx = scope FieldBed();
		fx.Field.MaxLength = 2;
		fx.D.InjectText("\u{00E9}\u{00E9}\u{00E9}"); // three 2-byte 'é'
		Test.Assert(fx.Field.Text == "\u{00E9}\u{00E9}");
		let combining = scope FieldBed();
		combining.Field.MaxLength = 2;
		combining.D.InjectText("e\u{0301}e\u{0301}e\u{0301}"); // e and a combining acute, three times
		Test.Assert(combining.Field.Text == "e\u{0301}e\u{0301}");
	}

	// === Mouse selection ===

	[Test]
	public static void ADoubleClickSelectsTheWordUnderThePointer()
	{
		let fx = scope FieldBed("foo bar baz"); // words at 0-3, 4-7, 8-11 (6px a byte)
		// Two presses at the same spot with no time between: a double click, inside "bar".
		let pos = Float2(5.0f * 6.0f + 3.0f, 12.0f); // about byte 5
		fx.D.InjectMouseDown(pos, .Left);
		fx.D.InjectMouseUp(pos, .Left);
		fx.D.InjectMouseDown(pos, .Left);
		Test.Assert(fx.Field.SelectedText == "bar");
	}

	[Test]
	public static void DraggingThePointerExtendsTheSelection()
	{
		let fx = scope FieldBed("hello");
		// Pressed at the start, moved right to about offset 3, released.
		fx.D.InjectMouseDown(.(0.0f, 12.0f), .Left);
		Test.Assert(!fx.Field.HasSelection);
		fx.D.InjectMouseMove(.(3.0f * 6.0f, 12.0f)); // captured by the pressed field
		Test.Assert(fx.Field.HasSelection);
		Test.Assert(fx.Field.SelectedText == "hel");
		fx.D.InjectMouseUp(.(3.0f * 6.0f, 12.0f), .Left);
		// A move after the release no longer extends it.
		fx.D.InjectMouseMove(.(5.0f * 6.0f, 12.0f));
		Test.Assert(fx.Field.SelectedText == "hel");
	}

	[Test]
	public static void ShiftClickExtendsTheSelectionFromTheCaret()
	{
		let fx = scope FieldBed("hello");
		fx.Field.Caret = 1; // after 'h'
		fx.D.InjectMouseDown(.(4.0f * 6.0f, 12.0f), .Left, KeyModShift);
		Test.Assert(fx.Field.HasSelection);
		Test.Assert(fx.Field.SelectedText == "ell");
	}

	[Test]
	public static void ARightPressKeepsTheCaretAndTheSelection()
	{
		let fx = scope FieldBed("hello");
		fx.Field.Caret = 1;
		fx.D.InjectMouseDown(.(4.0f * 6.0f, 12.0f), .Left, KeyModShift);
		fx.D.InjectMouseUp(.(4.0f * 6.0f, 12.0f), .Left);
		Test.Assert(fx.Field.SelectedText == "ell");
		fx.D.InjectMouseDown(.(0.0f, 12.0f), .Right); // where a context menu opens
		fx.D.InjectMouseUp(.(0.0f, 12.0f), .Right);
		Test.Assert(fx.Field.SelectedText == "ell");
		Test.Assert(fx.Field.Caret == 4);
		fx.D.InjectMouseMove(.(2.0f * 6.0f, 12.0f)); // and no drag-select began
		Test.Assert(fx.Field.SelectedText == "ell");
	}

	[Test]
	public static void WhatItShowsIsCutAtItsPaddingNotDrawnPastItsBox()
	{
		// 16 bytes at 6px is 96 wide, in a content box of 52 (60 less 4 each side): the selection
		// drawn behind the whole value is clipped to the content box, with room for a caret.
		let cf = scope CachedFont(new MockFont(), null);
		let root = SceneFixtures.NewScene(200.0f, 100.0f);
		defer root.ReleaseRef();
		let f = new TextField();
		defer f.ReleaseRef();
		f.Font = cf;
		f.Padding = .(4.0f, 0.0f);
		f.Size = .(60.0f, 24.0f);
		f.Text = "abcdefghijklmnop";
		root.AddChild(f);
		root.UpdateLayout();
		f.RequestFocus();
		f.SelectAll();

		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		f.Draw(dc);
		Test.Assert(!canvas.GetBatch().Commands.IsEmpty);
		for (let cmd in canvas.GetBatch().Commands)
		{
			Test.Assert(cmd.ClipRect.X >= 4.0f - 0.01f);
			Test.Assert(cmd.ClipRect.X + cmd.ClipRect.Width <= 56.0f + 1.5f + 0.01f);
		}
	}

	// === The editing model's keys and rules ===

	[Test]
	public static void TheEditingKeysAreCommandsWordMovesUndoAndABindingThatOverridesOne()
	{
		let fx = scope FieldBed("one two three");
		fx.D.InjectKeyDown(Key(.Left), KeyModCtrl);
		Test.Assert(fx.Field.Caret == 8); // before "three"
		fx.D.InjectKeyDown(Key(.Backspace), KeyModCtrl);
		Test.Assert(fx.Field.Text == "one three");
		fx.D.InjectKeyDown(Key(.Z), KeyModCtrl);
		Test.Assert(fx.Field.Text == "one two three");
		fx.D.InjectKeyDown(Key(.Y), KeyModCtrl);
		Test.Assert(fx.Field.Text == "one three");

		// A screen unbinds Ctrl+A in fields: the keystroke does nothing there now.
		fx.Field.Caret = 0;
		Test.Assert(fx.Root.Context.Keymap.Bind("ctrl-a", "", "textinput"));
		fx.D.InjectKeyDown(Key(.A), KeyModCtrl);
		Test.Assert(!fx.Field.HasSelection);
		// A menu runs the command by its name along the focus path all the same.
		Test.Assert(fx.Root.RunCommand("text.select-all"));
		Test.Assert(fx.Field.SelectedText == "one three");
		Test.Assert(fx.Root.IsCommandAvailable("text.paste"));
	}

	[Test]
	public static void TypingKeysAreTheFieldsUpAndDownStillMoveFocus()
	{
		let fx = scope FieldBed("ab");
		let below = new Button();
		defer below.ReleaseRef();
		below.Position = .(0.0f, 50.0f);
		below.Size = .(100.0f, 24.0f);
		fx.Root.AddChild(below);
		fx.Root.UpdateLayout();
		Test.Assert(fx.D.InjectKeyDown(Key(.Space))); // taken: no activation, the text comes as text input
		Test.Assert(fx.Field.IsFocused);
		fx.D.InjectKeyDown(Key(.Down));
		Test.Assert(below.IsFocused);
	}

	[Test]
	public static void AReadOnlyFieldTakesNoEditsFromKeysTypingOrPasteAndStillCopies()
	{
		let clip = scope TestClipboard();
		clip.SetText("pasted");
		let fx = scope FieldBed("fixed");
		fx.D.Clipboard = clip;
		fx.Field.IsReadOnly = true;
		fx.D.InjectText("x");
		fx.D.InjectKeyDown(Key(.Backspace));
		fx.D.InjectKeyDown(Key(.V), KeyModCtrl);
		Test.Assert(fx.Field.Text == "fixed");
		fx.Field.SelectAll();
		fx.D.InjectKeyDown(Key(.X), KeyModCtrl);
		Test.Assert(clip.Text == "fixed");
		Test.Assert(fx.Field.Text == "fixed");
	}

	[Test]
	public static void AnInputFilterLetsInOnlyWhatItAccepts()
	{
		let fx = scope FieldBed();
		fx.Field.SetInputFilter(InputFilter.Digits());
		fx.D.InjectText("a1b2");
		Test.Assert(fx.Field.Text == "12");
	}

	[Test]
	public static void ALongValueScrollsToKeepTheCaretInView()
	{
		let fx = scope FieldBed(); // 200 wide, 6px a byte: 33 characters fit
		fx.D.InjectText("0123456789012345678901234567890123456789"); // 40: 240px
		Test.Assert(fx.Field.ScrollX > 0.0f);
		Test.Assert(Near(fx.Field.ScrollX, 240.0f - (200.0f - 1.5f)));
		fx.D.InjectKeyDown(Key(.Home));
		Test.Assert(Near(fx.Field.ScrollX, 0.0f));
		// A click maps through the scroll: at the right edge after End, the caret is near the end.
		fx.D.InjectKeyDown(Key(.End));
		fx.D.InjectMouseDown(.(199.0f, 12.0f), .Left);
		Test.Assert(fx.Field.Caret >= 39);
	}

	[Test]
	public static void AShortLineSitsWhereItsAlignmentPutsItStartBeingTheRightInRightToLeft()
	{
		// 200 wide, 6px a byte: "abcd" is 24px; the view is 198.5 (the caret's width kept clear).
		Float2 At(TextField f, float x) => f.ConvertToRootSpace(.(x, 12.0f));
		{
			let fx = scope FieldBed("abcd");
			fx.Root.SetLayoutDirection(.RightToLeft);
			fx.Root.UpdateLayout();
			// Against the right edge: the line spans 174.5 to 198.5.
			fx.D.InjectMouseDown(At(fx.Field, 183.0f), .Left);
			fx.D.InjectMouseUp(At(fx.Field, 183.0f), .Left);
			Test.Assert(fx.Field.Caret == 1); // just past the a
			fx.D.InjectMouseDown(At(fx.Field, 20.0f), .Left);
			fx.D.InjectMouseUp(At(fx.Field, 20.0f), .Left);
			Test.Assert(fx.Field.Caret == 0); // left of this left-to-right run: its start
		}
		{
			let fx = scope FieldBed("abcd");
			fx.Field.SetTextAlignment(.End, .Middle);
			fx.Root.UpdateLayout();
			fx.D.InjectMouseDown(At(fx.Field, 183.0f), .Left);
			fx.D.InjectMouseUp(At(fx.Field, 183.0f), .Left);
			Test.Assert(fx.Field.Caret == 1);
			fx.Field.SetTextAlignment(.Center, .Middle); // 87.25 to 111.25
			fx.D.InjectMouseDown(At(fx.Field, 99.0f), .Left);
			fx.D.InjectMouseUp(At(fx.Field, 99.0f), .Left);
			Test.Assert(fx.Field.Caret == 2);
		}
	}

	[Test]
	public static void ALongRightToLeftLineRestsOnItsStartTheRightAndScrollsFromThere()
	{
		let fx = scope FieldBed();
		fx.Root.SetLayoutDirection(.RightToLeft);
		fx.Root.UpdateLayout();
		fx.D.InjectText("0123456789012345678901234567890123456789"); // 240px
		// The caret at the end of this left-to-right run, its right: the right part shows.
		Test.Assert(Near(fx.Field.ScrollX, 0.0f));
		fx.D.InjectKeyDown(Key(.Home)); // the run's start, its left: scrolled from the right
		Test.Assert(Near(fx.Field.ScrollX, 240.0f - (200.0f - 1.5f)));
	}

	[Test]
	public static void APasswordShowsAMaskKeepsCaretsOnItsCharactersAndLetsNothingOut()
	{
		let clip = scope TestClipboard();
		let fx = scope FieldBed();
		fx.D.Clipboard = clip;
		fx.Field.IsPassword = true;
		fx.D.InjectText("s\u{00E9}cret");
		Test.Assert(fx.Field.Text == "s\u{00E9}cret");
		// A press after the third mark (6px a byte, three bytes a bullet: 18 a character).
		fx.D.InjectMouseDown(.(3.0f * 18.0f + 1.0f, 12.0f), .Left);
		Test.Assert(fx.Field.Caret == 4); // after "séc": é is two bytes
		fx.Field.SelectAll();
		fx.D.InjectKeyDown(Key(.C), KeyModCtrl);
		fx.D.InjectKeyDown(Key(.X), KeyModCtrl);
		Test.Assert(!clip.HasText);
		Test.Assert(fx.Field.Text == "s\u{00E9}cret");
	}

	[Test]
	public static void AnIMEsCompositionShowsInPlaceOfTheSelectionUntilItCommitsAsText()
	{
		let fx = scope FieldBed("ab cd");
		fx.Field.Caret = 3; // after "ab "
		int inputs = 0;
		fx.Field.SetOnTextChanging(new [&] (text) => { ++inputs; });
		Test.Assert(fx.D.InjectComposition("xyz", 2));
		Test.Assert(fx.Field.Text == "ab cd"); // not the value yet
		Test.Assert(inputs == 0);
		// It types where the composition is, the caret two characters into it (6px a byte).
		Rect area;
		float caretX;
		Test.Assert(fx.D.GetTextInputArea(out area, out caretX));
		Test.Assert(Near(area.X, 18.0f));
		Test.Assert(Near(area.Width, 18.0f));
		Test.Assert(Near(caretX, 12.0f));

		fx.D.InjectComposition("", 0); // ended
		fx.D.InjectText("XY"); // committed
		Test.Assert(fx.Field.Text == "ab XYcd");
		Test.Assert(inputs == 1);

		// Over a selection, the committed text replaces it; leaving drops an unfinished one.
		fx.Field.SelectAll();
		fx.D.InjectComposition("q", 1);
		fx.Field.ReleaseFocus();
		Test.Assert(fx.Field.Text == "ab XYcd");
	}
}
