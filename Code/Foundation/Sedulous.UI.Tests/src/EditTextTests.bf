using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The text field, and the password box that masks it.
///
/// Everything here runs on CHARACTER indices through TextEditingBehavior, so none of it needs
/// glyph shaping. The pixel and caret geometry is exercised where the font service is.
class EditTextTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root);
	}

	private static EditText AddEdit(UIContext context, RootView root)
	{
		let edit = new EditText();
		root.AddView(edit);
		UITest.LayoutPass(context, root);
		return edit;
	}

	// ---- Text ---------------------------------------------------------------------------------

	[Test]
	public static void TheTextRoundTrips()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let edit = AddEdit(context, root);

		edit.SetText("Hello");
		Test.Assert(edit.Text == "Hello");

		edit.SetText("World");
		Test.Assert(edit.Text == "World");
	}

	/// The host interface is how the behaviour talks to the field, and a change through it
	/// reports as one.
	///
	/// Reached through a cast because these are EXPLICIT interface implementations: several of
	/// them collide by name with the field's own Property members, and an explicit impl is only
	/// visible through the interface.
	[Test]
	public static void AChangeThroughTheHostInterfaceReportsIt()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let edit = AddEdit(context, root);

		var fired = false;
		edit.OnTextChanged.Add(new [&fired](e) => { fired = true; });

		let host = (ITextEditHost)edit;
		host.ReplaceText(0, 0, "A");
		host.OnTextModified();

		Test.Assert(fired);
		Test.Assert(edit.Text == "A");
	}

	[Test]
	public static void MaxLengthIsEnforcedInCharacters()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let edit = AddEdit(context, root);
		edit.MaxLength.Value = 5;

		for (int i < 10)
			edit.Behavior.HandleTextInput('a');

		Test.Assert(edit.TextCharCount == 5);
	}

	[Test]
	public static void AnInputFilterDropsWhatItRejects()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let edit = AddEdit(context, root);
		edit.SetFilter(InputFilter.Digits());

		edit.Behavior.HandleTextInput('5');
		edit.Behavior.HandleTextInput('a');
		edit.Behavior.HandleTextInput('3');

		Test.Assert(edit.Text == "53");
	}

	[Test]
	public static void AReadOnlyFieldCannotBeTypedInto()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let edit = AddEdit(context, root);
		edit.SetText("Original");
		edit.IsReadOnly.Value = true;

		edit.Behavior.HandleTextInput('X');

		Test.Assert(edit.Text == "Original");
	}

	[Test]
	public static void TheFieldsOwnPropertiesRoundTrip()
	{
		let edit = new EditText();
		defer edit.ReleaseRef();

		edit.SetPlaceholder("Enter text...");
		Test.Assert(edit.Placeholder.Value == "Enter text...");

		Test.Assert(edit.IsFocusable);
		Test.Assert(edit.IsTabStop);
		Test.Assert(edit.Cursor == CursorType.IBeam);

		// The arrows move the caret, so focus must not spend them on moving away. A control
		// with nothing to do with them leaves them to the focus navigation, which is the
		// contrast that makes the flag mean something.
		Test.Assert(edit.WantsArrowKeys);
		let button = new Button("Test");
		defer button.ReleaseRef();
		Test.Assert(!button.WantsArrowKeys);

		Test.Assert(!edit.Multiline.Value);
		edit.Multiline.Value = true;
		Test.Assert(edit.Multiline.Value);
	}

	// ---- Editing ------------------------------------------------------------------------------

	[Test]
	public static void TheCaretMovesByCharacterAndToTheEnds()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let edit = AddEdit(context, root);
		edit.SetText("Hello");

		// SetText RESETS the caret: the old position meant something about the old text.
		Test.Assert(edit.CursorPosition == 0);

		edit.Behavior.HandleKeyDown(.Right, .None);
		Test.Assert(edit.CursorPosition == 1);

		edit.Behavior.HandleKeyDown(.End, .None);
		Test.Assert(edit.CursorPosition == 5);

		edit.Behavior.HandleKeyDown(.Home, .None);
		Test.Assert(edit.CursorPosition == 0);
	}

	[Test]
	public static void SelectAllCoversTheWholeText()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let edit = AddEdit(context, root);
		edit.SetText("Hello");

		edit.Behavior.HandleKeyDown(.A, .Ctrl);

		Test.Assert(edit.SelectionStart == 0);
		Test.Assert(edit.SelectionEnd == 5);
	}

	[Test]
	public static void BackspaceAndDeleteRemoveOnEitherSideOfTheCaret()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let edit = AddEdit(context, root);
		edit.SetText("Hello");

		edit.Behavior.HandleKeyDown(.End, .None);
		edit.Behavior.HandleKeyDown(.Backspace, .None);
		Test.Assert(edit.Text == "Hell");

		edit.SetText("Hello");
		edit.Behavior.HandleKeyDown(.Delete, .None);
		Test.Assert(edit.Text == "ello");
	}

	/// Consecutive inserts COALESCE into one undo entry, so undo steps back a word rather than
	/// a keystroke.
	[Test]
	public static void UndoAndRedoStepOverACoalescedRunOfTyping()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let edit = AddEdit(context, root);

		edit.Behavior.HandleTextInput('a');
		edit.Behavior.HandleTextInput('b');
		edit.Behavior.HandleTextInput('c');
		Test.Assert(edit.Text == "abc");

		edit.Behavior.HandleKeyDown(.Z, .Ctrl);
		Test.Assert(edit.Text == "");

		edit.Behavior.HandleKeyDown(.Y, .Ctrl);
		Test.Assert(edit.Text == "abc");
	}

	// ---- Finishing and committing ---------------------------------------------------------

	/// Losing focus finishes the edit exactly once, and does NOT submit: submitting is what
	/// Enter and activation do.
	[Test]
	public static void BlurFinishesTheEditWithoutSubmitting()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let edit = AddEdit(context, root);
		let other = AddEdit(context, root);

		var finished = 0;
		var submitted = 0;
		edit.OnEditingFinished.Add(new [&finished](e) => { finished++; });
		edit.OnSubmit.Add(new [&submitted](e) => { submitted++; });

		context.GetFocusManager().SetFocus(edit);
		edit.Behavior.HandleTextInput('x');
		Test.Assert(finished == 0, "gaining focus and typing is not an ending");

		context.GetFocusManager().SetFocus(other);

		Test.Assert(finished == 1);
		Test.Assert(submitted == 0);
	}

	/// The COMMIT is the one to subscribe for entering a value: Enter fires it, and so does
	/// blur, but only when something actually changed.
	[Test]
	public static void CommitFiresOnEnterAndOnAChangedBlurButNotAnUntouchedOne()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let edit = AddEdit(context, root);
		let other = AddEdit(context, root);

		var committed = 0;
		edit.OnCommit.Add(new [&committed](e) => { committed++; });

		// In and straight out again, untouched: nothing to commit.
		context.GetFocusManager().SetFocus(edit);
		context.GetFocusManager().SetFocus(other);
		Test.Assert(committed == 0);

		// Typed, then clicked away: the edit is not dropped.
		context.GetFocusManager().SetFocus(edit);
		edit.Behavior.HandleTextInput('x');
		context.GetFocusManager().SetFocus(other);
		Test.Assert(committed == 1);

		// Activation commits, and the blur that follows must not commit the same edit again.
		context.GetFocusManager().SetFocus(edit);
		edit.Behavior.HandleTextInput('y');
		edit.OnActivate();
		Test.Assert(committed == 2);
		context.GetFocusManager().SetFocus(other);
		Test.Assert(committed == 2);
	}

	// ---- Text input wanting -------------------------------------------------------------------

	/// A field wants platform text input while it can be typed into, and the context answers
	/// for whatever is focused. That is what drives the on screen keyboard and the IME.
	[Test]
	public static void OnlyAUsableFieldWantsTextInput()
	{
		let edit = new EditText();
		defer edit.ReleaseRef();

		Test.Assert(edit.WantsTextInput());

		edit.IsReadOnly.Value = true;
		Test.Assert(!edit.WantsTextInput());

		edit.IsReadOnly.Value = false;
		edit.IsEnabled = false;
		Test.Assert(!edit.WantsTextInput());
	}

	[Test]
	public static void ThePlainViewWantsNoTextInput()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		Test.Assert(!view.WantsTextInput());
	}

	[Test]
	public static void TheContextAnswersForWhateverIsFocused()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let edit = new EditText();
		root.AddView(edit);
		let plain = new TestView(50, 30);
		plain.IsFocusable = true;
		root.AddView(plain);

		Test.Assert(!context.WantsTextInput(), "nothing focused");

		context.GetFocusManager().SetFocus(edit);
		Test.Assert(context.WantsTextInput());

		context.GetFocusManager().SetFocus(plain);
		Test.Assert(!context.WantsTextInput());

		context.GetFocusManager().ClearFocus();
		Test.Assert(!context.WantsTextInput());
	}

	// ---- PasswordBox --------------------------------------------------------------------------

	/// Only the DISPLAY is masked; the field still holds the real text for a caller to read.
	[Test]
	public static void APasswordBoxMasksItsDisplayButKeepsItsText()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let password = new PasswordBox();
		password.SetText("secret");
		root.AddView(password);
		UITest.LayoutPass(context, root);

		let display = scope String();
		password.GetDisplayText(display);

		Test.Assert(display == "******");
		Test.Assert(password.Text == "secret");
	}

	[Test]
	public static void APasswordBoxTakesADifferentMaskCharacter()
	{
		let password = new PasswordBox();
		defer password.ReleaseRef();
		password.SetText("abc");
		password.PasswordChar.Value = '#';

		let display = scope String();
		password.GetDisplayText(display);

		Test.Assert(display == "###");
	}

	/// The mask is one character per CHARACTER, not per byte, so a multi byte character does
	/// not give away its own length.
	[Test]
	public static void APasswordBoxMasksPerCharacterNotPerByte()
	{
		let password = new PasswordBox();
		defer password.ReleaseRef();
		password.SetText("héllo");

		let display = scope String();
		password.GetDisplayText(display);

		Test.Assert(display == "*****", "five characters, six bytes");
	}

	/// Copying out is blocked at BOTH doors: the behaviour's clipboard copy is off, and the
	/// shortcuts are swallowed before they can reach it.
	[Test]
	public static void APasswordBoxRefusesToCopyOrCut()
	{
		let password = new PasswordBox();
		defer password.ReleaseRef();

		Test.Assert(!password.Behavior.AllowClipboardCopy);

		let copy = scope KeyEventArgs();
		copy.Set(.C, .Ctrl, false);
		password.OnKeyDown(copy);
		Test.Assert(copy.Handled, "swallowed rather than passed on");

		let cut = scope KeyEventArgs();
		cut.Set(.X, .Ctrl, false);
		password.OnKeyDown(cut);
		Test.Assert(cut.Handled);
	}
}
