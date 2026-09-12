using System;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The drawables' own behaviour, and the text editing primitives: the input filter and the
/// undo stack.
class DrawableAndEditingTests
{
	// ---- StateListDrawable ------------------------------------------------------------------

	/// An unset state falls back to Normal, so a theme declares only the states it cares about
	/// and the rest still draw.
	[Test]
	public static void AnUnsetStateFallsBackToNormal()
	{
		let list = new StateListDrawable();
		defer list.ReleaseRef();
		list.Set(.Normal, new ColorDrawable(Color.Red));

		let normal = list.Get(.Normal);

		Test.Assert(list.Get(.Normal) == normal);
		Test.Assert(list.Get(.Hover) == normal);
		Test.Assert(list.Get(.Pressed) == normal);
		Test.Assert(list.Get(.Disabled) == normal);
	}

	[Test]
	public static void ADeclaredStateWinsOverTheFallback()
	{
		let list = new StateListDrawable();
		defer list.ReleaseRef();
		list.Set(.Normal, new ColorDrawable(Color.Red));
		list.Set(.Hover, new ColorDrawable(Color.Blue));

		let normal = list.Get(.Normal);
		let hover = list.Get(.Hover);

		Test.Assert(hover != normal);
		Test.Assert(list.Get(.Hover) == hover);
		Test.Assert(list.Get(.Pressed) == normal, "still falls back");
	}

	/// With nothing at all declared, every lookup is null rather than some arbitrary entry.
	[Test]
	public static void AnEmptyStateListAnswersNull()
	{
		let list = new StateListDrawable();
		defer list.ReleaseRef();

		Test.Assert(list.Get(.Normal) == null);
		Test.Assert(list.Get(.Hover) == null);
	}

	/// Disabled DOMINATES the interaction flags. A disabled control under the mouse is
	/// Disabled and Hover at once, and it must render disabled rather than lighting up: a
	/// generic high to low flag strip gets this backwards.
	[Test]
	public static void DisabledDominatesTheInteractionFlags()
	{
		let list = new StateListDrawable();
		defer list.ReleaseRef();
		let normal = new ColorDrawable(Color.Black);
		let hover = new ColorDrawable(Color.Green);
		let disabled = new ColorDrawable(Color.Red);
		list.Set(.Normal, normal);
		list.Set(.Hover, hover);
		list.Set(.Disabled, disabled);

		Test.Assert(list.Get(.Disabled | .Hover) == disabled);
		Test.Assert(list.Get(.Disabled | .Pressed) == disabled);
		Test.Assert(list.Get(.Disabled | .Focused | .Hover) == disabled);

		Test.Assert(list.Get(.Hover) == hover, "unchanged");
		Test.Assert(list.Get(.Hover | .Focused) == hover, "the generic fallback still works");
	}

	// ---- The other drawables ------------------------------------------------------------------

	/// Layers CONSUME the reference handed to them, with or without an inset.
	[Test]
	public static void ALayerDrawableTakesItsLayers()
	{
		let layer = new LayerDrawable();
		defer layer.ReleaseRef();

		layer.AddLayer(new ColorDrawable(Color.Red));
		layer.AddLayer(new ColorDrawable(Color.Blue), Thickness(5.0f, 5.0f, 5.0f, 5.0f));
	}

	/// An inset drawable reports its inset as padding, so the content it wraps is laid out
	/// inside rather than under it.
	[Test]
	public static void AnInsetDrawableReportsItsInsetAsPadding()
	{
		let inset = new InsetDrawable(new ColorDrawable(Color.Red),
			Thickness(10.0f, 5.0f, 10.0f, 5.0f));
		defer inset.ReleaseRef();

		let padding = inset.DrawablePadding;

		Test.Assert(padding.Left == 10.0f);
		Test.Assert(padding.Top == 5.0f);
		Test.Assert(padding.Right == 10.0f);
		Test.Assert(padding.Bottom == 5.0f);
	}

	/// A drawable with no natural size answers none, which is what lets a view fall back to its
	/// own measurement rather than being sized by its background.
	[Test]
	public static void APaintedDrawableHasNoIntrinsicSize()
	{
		let colour = new ColorDrawable(Color.Red);
		defer colour.ReleaseRef();
		Test.Assert(colour.IntrinsicSize == null);

		let rounded = new RoundedRectDrawable(Color.Red, 4.0f, Color.Blue, 1.0f);
		defer rounded.ReleaseRef();
		Test.Assert(rounded.IntrinsicSize == null);
	}

	/// A nine slice's padding is its slices LESS whatever it was told to expand into, clamped
	/// at nought: expanding past the slice means there is no reserved edge left.
	[Test]
	public static void ANineSlicesPaddingAccountsForItsExpand()
	{
		let partial = new NineSliceDrawable(null, NineSlice(10.0f, 10.0f, 10.0f, 10.0f));
		defer partial.ReleaseRef();
		partial.Expand = .(5.0f, 5.0f, 5.0f, 5.0f);

		let padding = partial.DrawablePadding;
		Test.Assert(padding.Left == 5.0f);
		Test.Assert(padding.Top == 5.0f);
		Test.Assert(padding.Right == 5.0f);
		Test.Assert(padding.Bottom == 5.0f);

		let overExpanded = new NineSliceDrawable(null, NineSlice(5.0f, 5.0f, 5.0f, 5.0f));
		defer overExpanded.ReleaseRef();
		overExpanded.Expand = .(10.0f, 10.0f, 10.0f, 10.0f);

		let clamped = overExpanded.DrawablePadding;
		Test.Assert(clamped.Left == 0.0f, "clamped, never negative");
		Test.Assert(clamped.Top == 0.0f);
	}

	/// Constructing a drawable must not DRAW it: a shape's function runs when it is drawn and
	/// not a moment sooner.
	[Test]
	public static void ConstructingAShapeDrawableDoesNotInvokeIt()
	{
		var called = false;
		let shape = new ShapeDrawable(new [&called](ctx, bounds) => { called = true; });
		defer shape.ReleaseRef();

		Test.Assert(!called);
	}

	// ---- InputFilter ------------------------------------------------------------------------

	[Test]
	public static void TheDefaultFilterAcceptsEverything()
	{
		let filter = scope InputFilter();

		Test.Assert(filter.Accept('a'));
		Test.Assert(filter.Accept('Z'));
		Test.Assert(filter.Accept('5'));
		Test.Assert(filter.Accept(' '));
		Test.Assert(filter.Accept('!'));
	}

	[Test]
	public static void TheDigitsFilterAcceptsOnlyDigits()
	{
		let filter = InputFilter.Digits();
		defer delete filter;

		Test.Assert(filter.Accept('0'));
		Test.Assert(filter.Accept('5'));
		Test.Assert(filter.Accept('9'));
		Test.Assert(!filter.Accept('a'));
		Test.Assert(!filter.Accept(' '));
		Test.Assert(!filter.Accept('.'), "not even a decimal point");
	}

	[Test]
	public static void TheHexFilterTakesBothCases()
	{
		let filter = InputFilter.HexDigits();
		defer delete filter;

		Test.Assert(filter.Accept('0'));
		Test.Assert(filter.Accept('9'));
		Test.Assert(filter.Accept('a'));
		Test.Assert(filter.Accept('f'));
		Test.Assert(filter.Accept('A'));
		Test.Assert(filter.Accept('F'));
		Test.Assert(!filter.Accept('g'));
		Test.Assert(!filter.Accept('G'));
		Test.Assert(!filter.Accept(' '));
	}

	[Test]
	public static void ACustomFilterDecidesForItself()
	{
		let filter = scope InputFilter();
		filter.SetCustomFilter(new (character) => (character == 'x') || (character == 'y'));

		Test.Assert(filter.Accept('x'));
		Test.Assert(filter.Accept('y'));
		Test.Assert(!filter.Accept('z'));
		Test.Assert(!filter.Accept('a'));
	}

	// ---- UndoStack --------------------------------------------------------------------------

	/// The stack holds SNAPSHOTS, and undo swaps the current state for the top of the undo list
	/// while pushing what was current onto redo.
	[Test]
	public static void UndoRestoresThePushedSnapshotAndBanksTheCurrentOne()
	{
		let stack = scope UndoStack();
		Test.Assert(!stack.CanUndo);
		Test.Assert(!stack.CanRedo);

		stack.PushState("a", 1, 1);
		Test.Assert(stack.CanUndo);
		Test.Assert(stack.UndoCount == 1);

		let restored = scope String();
		// Undo takes `ref` rather than `out`, so the locals are declared first.
		int32 cursor = 0;
		int32 anchor = 0;
		Test.Assert(stack.Undo("ab", 2, 2, restored, ref cursor, ref anchor));
		Test.Assert(restored == "a");
		Test.Assert(cursor == 1);
		Test.Assert(anchor == 1);
		Test.Assert(!stack.CanUndo);
		Test.Assert(stack.CanRedo, "the `ab` state went onto redo");
	}

	[Test]
	public static void RedoGivesBackTheStateUndoneAway()
	{
		let stack = scope UndoStack();
		stack.PushState("a", 1, 1);

		let undone = scope String();
		int32 cursor = 0;
		int32 anchor = 0;
		stack.Undo("ab", 2, 2, undone, ref cursor, ref anchor);

		let redone = scope String();
		int32 redoCursor = 0;
		int32 redoAnchor = 0;
		Test.Assert(stack.Redo(undone, cursor, anchor, redone, ref redoCursor, ref redoAnchor));
		Test.Assert(redone == "ab");
		Test.Assert(redoCursor == 2);
		Test.Assert(redoAnchor == 2);
		Test.Assert(stack.CanUndo);
		Test.Assert(!stack.CanRedo);
	}

	/// A NEW edit clears the redo stack: once history diverges there is nothing coherent to
	/// redo onto.
	[Test]
	public static void PushingAfterAnUndoClearsTheRedoStack()
	{
		let stack = scope UndoStack();
		stack.PushState("a", 1, 1);

		let undone = scope String();
		int32 cursor = 0;
		int32 anchor = 0;
		stack.Undo("ab", 2, 2, undone, ref cursor, ref anchor);
		Test.Assert(stack.CanRedo);

		stack.PushState("new", 3, 3);
		Test.Assert(!stack.CanRedo);
	}

	/// The stack is BOUNDED: past its capacity the oldest entry drops, so a long editing
	/// session does not grow without limit.
	[Test]
	public static void ReachingCapacityDropsTheOldestEntry()
	{
		let stack = scope UndoStack();
		stack.MaxEntries = 2;
		Test.Assert(stack.MaxEntries == 2);

		stack.PushState("one", 0, 0);
		stack.PushState("two", 0, 0);
		stack.PushState("three", 0, 0); // drops "one"
		Test.Assert(stack.UndoCount == 2);

		let restored = scope String();
		int32 cursor = 0;
		int32 anchor = 0;
		stack.Undo("cur", 0, 0, restored, ref cursor, ref anchor);
		Test.Assert(restored == "three");

		let older = scope String();
		int32 olderCursor = 0;
		int32 olderAnchor = 0;
		stack.Undo(restored, cursor, anchor, older, ref olderCursor, ref olderAnchor);
		Test.Assert(older == "two");
		Test.Assert(!stack.CanUndo, "`one` is gone");
	}

	[Test]
	public static void UndoAndRedoOnAnEmptyStackAnswerFalse()
	{
		let stack = scope UndoStack();
		let restored = scope String();
		int32 cursor = 0;
		int32 anchor = 0;

		Test.Assert(!stack.Undo("x", 0, 0, restored, ref cursor, ref anchor));
		Test.Assert(!stack.Redo("x", 0, 0, restored, ref cursor, ref anchor));

		stack.PushState("a", 0, 0);
		stack.Clear();
		Test.Assert(!stack.CanUndo);
		Test.Assert(!stack.CanRedo);
	}
}
