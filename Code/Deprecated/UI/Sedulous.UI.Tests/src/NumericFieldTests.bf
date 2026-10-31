using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The numeric field, and the editable label that renames in place.
///
/// Both host TextEditingBehavior; the field does it directly because its text is a RENDERING of
/// a number, and the label does it by being an EditText that spends most of its life read only.
class NumericFieldTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root);
	}

	private static NumericField AddField(UIContext context, RootView root)
	{
		let field = new NumericField();
		field.SetMin(0);
		field.SetMax(100);
		root.AddView(field);
		UITest.LayoutPass(context, root);
		return field;
	}

	private static EditableLabel AddLabel(UIContext context, RootView root, StringView text)
	{
		let label = new EditableLabel();
		label.SetText(text);
		root.AddView(label);
		UITest.LayoutPass(context, root);
		return label;
	}

	// ---- NumericField: value ------------------------------------------------------------------

	[Test]
	public static void AFieldClampsToItsRange()
	{
		let field = new NumericField();
		defer field.ReleaseRef();
		field.SetMin(0);
		field.SetMax(100);

		field.SetValue(150);
		Test.Assert(field.Value == 100);

		field.SetValue(-10);
		Test.Assert(field.Value == 0);

		field.SetValue(50);
		Test.Assert(field.Value == 50);
	}

	[Test]
	public static void SteppingMovesByTheStepAndStopsAtTheEnd()
	{
		let field = new NumericField();
		defer field.ReleaseRef();
		field.SetMin(0);
		field.SetMax(10);
		field.SetStep(5);

		field.SetValue(0);
		field.Increment();
		Test.Assert(field.Value == 5);

		field.Decrement();
		Test.Assert(field.Value == 0);

		field.SetValue(8);
		field.Increment();
		Test.Assert(field.Value == 10, "clamped rather than overshooting");
	}

	/// Setting one end pushes the other out of its way, rather than leaving the range inverted
	/// with nothing valid between them.
	[Test]
	public static void MovingOneEndPastTheOtherCarriesItAlong()
	{
		let field = new NumericField();
		defer field.ReleaseRef();
		field.SetMin(0);
		field.SetMax(10);
		field.SetValue(5);

		field.SetMin(20);
		Test.Assert(field.MaxValue == 20, "the top was carried up");
		Test.Assert(field.Value == 20, "and the value with it");

		field.SetMax(-5);
		Test.Assert(field.MinValue == -5);
		Test.Assert(field.Value == -5);
	}

	[Test]
	public static void AFieldReportsWhatItSettledOn()
	{
		let field = new NumericField();
		defer field.ReleaseRef();
		field.SetMin(0);
		field.SetMax(100);

		var fired = false;
		var firedValue = 0.0;
		field.OnValueChanged.Add(new [&fired, &firedValue](f, val) =>
			{
				fired = true;
				firedValue = val;
			});

		field.SetValue(42);
		Test.Assert(fired);
		Test.Assert(firedValue == 42);

		// Writing the value it already holds reports nothing.
		fired = false;
		field.SetValue(42);
		Test.Assert(!fired);
	}

	[Test]
	public static void TheDefaultsAreARangeOfZeroToAHundredSteppingByOne()
	{
		let field = new NumericField();
		defer field.ReleaseRef();

		Test.Assert(field.Value == 0);
		Test.Assert(field.MinValue == 0);
		Test.Assert(field.MaxValue == 100);
		Test.Assert(field.Step == 1);
		Test.Assert(field.ShowSpinButtons.Value);
		// It edits its value as text, so it always wants the keyboard.
		Test.Assert(field.WantsTextInput());
		Test.Assert(field.WantsArrowKeys);
	}

	// ---- NumericField: text -------------------------------------------------------------------

	[Test]
	public static void TheTextIsFormattedToTheDecimalPlaces()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let field = AddField(context, root);
		field.SetDecimalPlaces(2);

		field.SetValue(3.14159);
		Test.Assert(field.Text == "3.14");

		field.SetDecimalPlaces(0);
		Test.Assert(field.Text == "3");
	}

	/// The filter admits only what can appear in a number.
	[Test]
	public static void TheFilterRejectsWhatCannotBeInANumber()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let field = AddField(context, root);

		field.Behavior.HandleKeyDown(.A, .Ctrl);
		field.Behavior.HandleTextInput('5');
		field.Behavior.HandleTextInput('a');
		field.Behavior.HandleTextInput('3');

		Test.Assert(field.Text == "53");
	}

	/// Typing re-parses into the value LIVE, so a listener sees it change as it is typed, but
	/// the text is left exactly as typed: reformatting mid edit would move the caret.
	[Test]
	public static void TypingUpdatesTheValueWithoutReformattingTheText()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let field = AddField(context, root);
		field.SetDecimalPlaces(2);

		field.Behavior.HandleKeyDown(.A, .Ctrl);
		field.Behavior.HandleTextInput('7');

		Test.Assert(field.Value == 7);
		Test.Assert(field.Text == "7", "not yet 7.00");

		// Committing is what reformats.
		field.CommitText();
		Test.Assert(field.Text == "7.00");
	}

	/// Text that is not a number at all leaves the value alone, and committing puts a proper
	/// rendering of it back.
	[Test]
	public static void UnparseableTextRevertsOnCommit()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let field = AddField(context, root);
		field.SetValue(42);

		field.Behavior.HandleKeyDown(.A, .Ctrl);
		// The filter lets a lone minus through, which is not a number.
		field.Behavior.HandleTextInput('-');
		Test.Assert(field.Value == 42, "still the last good value");

		field.CommitText();
		Test.Assert(field.Text == "42");
	}

	/// Focusing selects the whole value, so typing replaces it rather than appending. That is
	/// what makes a numeric field quick to retype.
	[Test]
	public static void FocusingAFieldSelectsTheWholeValue()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let field = new NumericField();
		field.SetMin(0);
		field.SetMax(1000);
		field.SetValue(123);
		root.AddView(field);
		UITest.LayoutPass(context, root);

		Test.Assert(!field.Behavior.HasSelection);

		context.GetFocusManager().SetFocus(field);

		Test.Assert(field.IsFocused());
		Test.Assert(field.Behavior.HasSelection);
		Test.Assert(field.Behavior.SelectionStart == 0);
		Test.Assert(field.Behavior.SelectionLength == field.TextCharCount);
	}

	// ---- EditableLabel ------------------------------------------------------------------------

	/// It starts as a label: read only, unfocusable, and not a tab stop. A list of these costs
	/// no focus stops while nobody is renaming anything.
	[Test]
	public static void ALabelStartsAsALabel()
	{
		let label = new EditableLabel();
		defer label.ReleaseRef();

		Test.Assert(!label.IsEditing);
		Test.Assert(label.IsReadOnly.Value);
		Test.Assert(!label.IsFocusable);
		Test.Assert(!label.IsTabStop);
		Test.Assert(label.Cursor == CursorType.Arrow);
		Test.Assert(label.DoubleClickToEdit.Value);
		Test.Assert(label.SlowClickToEdit.Value);
	}

	/// Editing turns all of it back on, and leaving turns it off again.
	[Test]
	public static void BeginningAnEditTurnsItIntoAField()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let label = AddLabel(context, root, "Hello");

		label.BeginEdit();
		Test.Assert(label.IsEditing);
		Test.Assert(!label.IsReadOnly.Value);
		Test.Assert(label.IsFocusable);
		Test.Assert(label.IsTabStop);
		Test.Assert(label.Cursor == CursorType.IBeam);

		label.CancelEdit();
		Test.Assert(!label.IsEditing);
		Test.Assert(label.IsReadOnly.Value);
		Test.Assert(!label.IsFocusable);
		Test.Assert(label.Cursor == CursorType.Arrow);
	}

	[Test]
	public static void CommittingARenameReportsTheNewName()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let label = AddLabel(context, root, "Hello");

		var committed = false;
		let committedText = scope String();
		label.OnRenameCommitted.Add(new [&committed, &committedText](l, text) =>
			{
				committed = true;
				committedText.Set(text);
			});

		label.BeginEdit();
		label.Behavior.HandleKeyDown(.A, .Ctrl);
		for (let character in "World".DecodedChars)
			label.Behavior.HandleTextInput(character);
		label.CommitEdit();

		Test.Assert(committed);
		Test.Assert(committedText == "World");
		Test.Assert(!label.IsEditing);
	}

	[Test]
	public static void CancellingARenamePutsTheOldNameBack()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let label = AddLabel(context, root, "Original");

		var cancelled = false;
		label.OnRenameCancelled.Add(new [&cancelled](l) => { cancelled = true; });

		label.BeginEdit();
		label.Behavior.HandleKeyDown(.A, .Ctrl);
		label.Behavior.HandleTextInput('X');
		label.CancelEdit();

		Test.Assert(cancelled);
		Test.Assert(label.Text == "Original");
		Test.Assert(!label.IsEditing);
	}

	/// Three refusals, all of which CANCEL rather than commit: an empty name, an unchanged one,
	/// and one a validator turned down. Each puts the original back.
	[Test]
	public static void AnEmptyOrUnchangedOrRejectedNameCancelsInstead()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		var committed = 0;
		var cancelled = 0;

		let empty = AddLabel(context, root, "Test");
		empty.OnRenameCommitted.Add(new [&committed](l, text) => { committed++; });
		empty.OnRenameCancelled.Add(new [&cancelled](l) => { cancelled++; });
		empty.BeginEdit();
		empty.Behavior.HandleKeyDown(.A, .Ctrl);
		empty.Behavior.HandleKeyDown(.Delete, .None);
		empty.CommitEdit();
		Test.Assert(committed == 0);
		Test.Assert(cancelled == 1);
		Test.Assert(empty.Text == "Test", "restored");

		let unchanged = AddLabel(context, root, "Same");
		unchanged.OnRenameCommitted.Add(new [&committed](l, text) => { committed++; });
		unchanged.OnRenameCancelled.Add(new [&cancelled](l) => { cancelled++; });
		unchanged.BeginEdit();
		unchanged.CommitEdit();
		Test.Assert(committed == 0);
		Test.Assert(cancelled == 2);

		let validated = AddLabel(context, root, "Hello");
		validated.ValidateRename = new (text) => !text.Contains("bad");
		validated.OnRenameCommitted.Add(new [&committed](l, text) => { committed++; });
		validated.OnRenameCancelled.Add(new [&cancelled](l) => { cancelled++; });
		validated.BeginEdit();
		validated.Behavior.HandleKeyDown(.A, .Ctrl);
		for (let character in "bad".DecodedChars)
			validated.Behavior.HandleTextInput(character);
		validated.CommitEdit();
		Test.Assert(committed == 0);
		Test.Assert(cancelled == 3);
	}

	/// A name that is only whitespace counts as empty: it would render as a blank row and
	/// could not be clicked to rename back.
	[Test]
	public static void AWhitespaceOnlyNameIsRejectedAsEmpty()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let label = AddLabel(context, root, "Test");

		var cancelled = false;
		label.OnRenameCancelled.Add(new [&cancelled](l) => { cancelled = true; });

		label.BeginEdit();
		label.Behavior.HandleKeyDown(.A, .Ctrl);
		label.Behavior.HandleTextInput(' ');
		label.Behavior.HandleTextInput(' ');
		label.CommitEdit();

		Test.Assert(cancelled);
		Test.Assert(label.Text == "Test");
	}

	/// A background update must not yank the text away mid rename.
	[Test]
	public static void SettingTheTextIsIgnoredWhileEditing()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let label = AddLabel(context, root, "Original");

		label.BeginEdit();
		label.SetText("Pushed from elsewhere");

		Test.Assert(label.Text == "Original");

		// And takes effect again once the edit is over.
		label.CancelEdit();
		label.SetText("Pushed from elsewhere");
		Test.Assert(label.Text == "Pushed from elsewhere");
	}

	/// Not editing, a label handles no keys at all, so a list keeps its navigation.
	[Test]
	public static void ALabelLeavesTheKeysAloneUntilItIsEditing()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let label = AddLabel(context, root, "Hello");

		let key = scope KeyEventArgs();
		key.Set(.Down, .None, false);
		label.OnKeyDown(key);
		Test.Assert(!key.Handled);

		label.BeginEdit();

		let escape = scope KeyEventArgs();
		escape.Set(.Escape, .None, false);
		label.OnKeyDown(escape);
		Test.Assert(escape.Handled);
		Test.Assert(!label.IsEditing, "escape cancelled");
	}
}
