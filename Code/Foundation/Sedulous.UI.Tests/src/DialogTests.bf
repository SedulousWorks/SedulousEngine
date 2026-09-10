using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The modal dialog: how it opens, how it closes, and who decides.
class DialogTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root);
	}

	/// Shown with ownsView false, so the test keeps its own reference and controls the
	/// lifetime; a real caller lets the layer own it.
	private static void ShowFor(UIContext context, Dialog dialog)
	{
		dialog.Show(context, false);
	}

	// ---- Building -----------------------------------------------------------------------------

	[Test]
	public static void ADialogCarriesItsTitleAndStartsUndecided()
	{
		let dialog = new Dialog("Hello");
		defer dialog.ReleaseRef();

		Test.Assert(dialog.Title == "Hello");
		Test.Assert(dialog.Result == .None);
	}

	/// The factories build the two ordinary shapes: a message with OK, and one with a choice.
	[Test]
	public static void TheFactoriesBuildAnAlertAndAConfirm()
	{
		let alert = Dialog.Alert("Title", "Message");
		defer alert.ReleaseRef();
		Test.Assert(alert.Title == "Title");
		Test.Assert(alert.ButtonRow.ChildCount == 1);

		let confirm = Dialog.Confirm("Confirm", "Are you sure?");
		defer confirm.ReleaseRef();
		Test.Assert(confirm.Title == "Confirm");
		Test.Assert(confirm.ButtonRow.ChildCount == 2);
	}

	/// The content goes BETWEEN the title and the buttons, which is why the row is taken out
	/// and put back rather than the content simply being appended.
	[Test]
	public static void TheContentSitsBetweenTheTitleAndTheButtons()
	{
		let dialog = new Dialog("Test");
		defer dialog.ReleaseRef();
		dialog.AddButton("OK", .OK);

		let content = new TestView(100, 40);
		dialog.SetContent(content);

		Test.Assert(dialog.Content == content);

		// The internal layout holds the title, then the content, then the row.
		let layout = dialog.GetVisualChild(0) as FlexLayout;
		Test.Assert(layout.ChildCount == 3);
		Test.Assert(layout.GetChildAt(1) == content);
		Test.Assert(layout.GetChildAt(2) == dialog.ButtonRow);
	}

	/// Setting content twice releases the first, and the row survives being moved each time.
	[Test]
	public static void ReplacingTheContentKeepsTheButtonRowAlive()
	{
		let dialog = new Dialog("Test");
		defer dialog.ReleaseRef();
		dialog.AddButton("OK", .OK);
		let row = dialog.ButtonRow;

		dialog.SetContent(new TestView(100, 40));
		dialog.SetContent(new TestView(50, 20));

		Test.Assert(dialog.ButtonRow == row, "the same row throughout");
		Test.Assert(row.ChildCount == 1, "and it still holds its button");

		let layout = dialog.GetVisualChild(0) as FlexLayout;
		Test.Assert(layout.ChildCount == 3, "title, content, row");
		Test.Assert(layout.GetChildAt(2) == row, "still last");
	}

	// ---- Showing ------------------------------------------------------------------------------

	[Test]
	public static void ShowingCreatesAModalPopup()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let dialog = new Dialog("Modal Test");
		defer dialog.ReleaseRef();

		ShowFor(context, dialog);

		let layer = root.GetPopupLayer();
		Test.Assert(layer.PopupCount == 1);
		Test.Assert(layer.HasModalPopup, "everything underneath is blocked");

		dialog.Close(.Cancel);
		context.MutationQueue.Drain();

		Test.Assert(layer.PopupCount == 0);
		Test.Assert(!layer.HasModalPopup);
	}

	/// It opens keyboard-alive: focus lands inside the dialog, so Escape and Return work
	/// without a click first. Programmatic, so no focus ring is drawn.
	[Test]
	public static void ShowingPutsKeyboardFocusInsideTheDialog()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let dialog = new Dialog("Test");
		defer dialog.ReleaseRef();
		dialog.AddButton("OK", .OK);

		ShowFor(context, dialog);

		let focused = context.GetFocusManager().FocusedView;
		Test.Assert(focused != null);
		Test.Assert(dialog.IsFocusWithin());
		Test.Assert(!focused.IsFocusVisible(), "no ring: nobody reached for the keyboard");

		dialog.Close(.Cancel);
		context.MutationQueue.Drain();
	}

	/// A dialog with NOTHING focusable in it still takes focus itself, or Escape would have
	/// nowhere to arrive.
	[Test]
	public static void ADialogWithNoFocusableContentTakesFocusItself()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let dialog = new Dialog("Test");
		defer dialog.ReleaseRef();

		ShowFor(context, dialog);

		Test.Assert(context.GetFocusManager().FocusedView == dialog);

		dialog.Close(.Cancel);
		context.MutationQueue.Drain();
	}

	// ---- Closing ------------------------------------------------------------------------------

	[Test]
	public static void ClosingReportsTheResultAndTakesThePopupDown()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let dialog = new Dialog("Test");
		defer dialog.ReleaseRef();
		dialog.AddButton("OK", .OK);

		var closed = false;
		var closedResult = DialogResult.None;
		dialog.OnClosed.Add(new [&closed, &closedResult](d, result) =>
			{
				closed = true;
				closedResult = result;
			});

		ShowFor(context, dialog);
		Test.Assert(root.GetPopupLayer().PopupCount == 1);

		dialog.Close(.OK);
		context.MutationQueue.Drain();

		Test.Assert(closed);
		Test.Assert(closedResult == .OK);
		Test.Assert(dialog.Result == .OK);
		Test.Assert(root.GetPopupLayer().PopupCount == 0);
	}

	/// The close is QUEUED, so a handler running inside a click is not standing on a dialog
	/// that has already been destroyed.
	[Test]
	public static void TheCloseIsDeferredUntilTheQueueDrains()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let dialog = new Dialog("Test");
		defer dialog.ReleaseRef();
		ShowFor(context, dialog);

		dialog.Close(.OK);
		Test.Assert(root.GetPopupLayer().PopupCount == 1, "still up");

		context.MutationQueue.Drain();
		Test.Assert(root.GetPopupLayer().PopupCount == 0);
	}

	/// Escape is a CANCEL rather than a bare close: dismissing without choosing is a decision,
	/// and a caller reading the result needs to know which one it was.
	[Test]
	public static void EscapeCancels()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let dialog = new Dialog("Test");
		defer dialog.ReleaseRef();
		ShowFor(context, dialog);

		let escape = scope KeyEventArgs();
		escape.Set(.Escape, .None, false);
		dialog.OnKeyDown(escape);
		context.MutationQueue.Drain();

		Test.Assert(escape.Handled);
		Test.Assert(dialog.Result == .Cancel);
		Test.Assert(root.GetPopupLayer().PopupCount == 0);
	}

	/// A button given a real result closes with it; one given None is CALLER MANAGED and does
	/// not close at all, which is what lets a validation failure keep the dialog up.
	[Test]
	public static void AResultButtonClosesAndANoneButtonDoesNot()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let dialog = new Dialog("Test");
		defer dialog.ReleaseRef();
		let validate = dialog.AddButton("Validate", .None);
		let ok = dialog.AddButton("OK", .OK);

		var closed = false;
		dialog.OnClosed.Add(new [&closed](d, result) => { closed = true; });

		ShowFor(context, dialog);
		Test.Assert(root.GetPopupLayer().PopupCount == 1);

		validate.FireClick();
		context.MutationQueue.Drain();
		Test.Assert(!closed, "the caller's handler decides");
		Test.Assert(root.GetPopupLayer().PopupCount == 1);

		ok.FireClick();
		context.MutationQueue.Drain();
		Test.Assert(closed);
		Test.Assert(dialog.Result == .OK);
		Test.Assert(root.GetPopupLayer().PopupCount == 0);
	}

	/// Closing with None leaves whatever result the dialog already had, so a caller that set
	/// one and then closed plainly does not have it wiped.
	[Test]
	public static void ClosingWithNoneKeepsTheResultAlreadyDecided()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let dialog = new Dialog("Test");
		defer dialog.ReleaseRef();
		ShowFor(context, dialog);

		dialog.Result = .OK;
		dialog.Close();
		context.MutationQueue.Drain();

		Test.Assert(dialog.Result == .OK);
	}

	// ---- Sizing -------------------------------------------------------------------------------

	/// A dialog is bounded by its own min and max, and never takes more than most of the
	/// viewport whatever its max says.
	[Test]
	public static void ADialogIsBoundedByItsOwnLimitsAndTheViewport()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let dialog = new Dialog("Test");
		defer dialog.ReleaseRef();
		// Content far larger than the dialog's maximum.
		dialog.SetContent(new TestView(2000, 2000));
		ShowFor(context, dialog);

		Test.Assert(dialog.Width <= dialog.MaxWidth.Value);
		Test.Assert(dialog.Height <= dialog.MaxHeight.Value);
		Test.Assert(dialog.Width >= dialog.MinWidth.Value);

		// And a nearly empty one is still at least its minimum.
		let small = new Dialog("Small");
		defer small.ReleaseRef();
		small.Show(context, false);
		Test.Assert(small.Width >= small.MinWidth.Value);
		Test.Assert(small.Height >= small.MinHeight.Value);

		dialog.Close(.Cancel);
		small.Close(.Cancel);
		context.MutationQueue.Drain();
	}
}
