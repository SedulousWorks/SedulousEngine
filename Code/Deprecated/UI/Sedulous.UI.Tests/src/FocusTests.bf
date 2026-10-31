using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// Keyboard focus: setting it, saving and restoring it around a popup, tab traversal,
/// directional movement, and the shortcut dispatch that keys off it.
class FocusTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root);
	}

	private static TestView Focusable(float width = 50, float height = 30)
	{
		let view = new TestView(width, height);
		view.IsFocusable = true;
		view.IsTabStop = true;
		return view;
	}

	// ---- Setting focus ----------------------------------------------------------------------

	[Test]
	public static void SettingFocusMovesItAndTellsBothViews()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let first = Focusable();
		let second = Focusable();
		root.AddView(first);
		root.AddView(second);

		focus.SetFocus(first);
		Test.Assert(first.IsFocused());
		Test.Assert(focus.FocusedView == first);

		focus.SetFocus(second);
		Test.Assert(!first.IsFocused(), "the old one lost it");
		Test.Assert(second.IsFocused());

		focus.ClearFocus();
		Test.Assert(!second.IsFocused());
		Test.Assert(focus.FocusedView == null);
	}

	/// Focus is HELD whatever its source; what the source decides is whether the RING draws.
	/// Pointer focus holds the keyboard without lighting up.
	[Test]
	public static void PointerFocusIsHeldButNotDrawn()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let view = Focusable();
		root.AddView(view);

		focus.SetFocus(view, .Pointer);
		Test.Assert(view.IsFocused(), "held");
		Test.Assert(!view.IsFocusVisible(), "but ringless");

		focus.SetFocus(view, .Keyboard);
		Test.Assert(view.IsFocusVisible(), "tabbing back onto it lights the ring");
	}

	// ---- Saving and restoring ---------------------------------------------------------------

	/// The ORIGINAL source comes back, so a pointer focused control returns from a modal
	/// holding focus and still ringless.
	[Test]
	public static void RestoringBringsBackTheFocusAndItsSource()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let view = Focusable();
		root.AddView(view);
		focus.SetFocus(view, .Keyboard);

		let saved = focus.SaveAndClearFocus();
		Test.Assert(focus.FocusedView == null, "saving clears it");

		focus.RestoreFocus(saved);
		Test.Assert(focus.FocusedView == view);
		Test.Assert(focus.Source == .Keyboard);
	}

	/// Each saved entry is INDEPENDENT, so popups closing out of order cannot cross restore
	/// one another's focus. A manager wide stack would get this wrong.
	[Test]
	public static void SavedEntriesCannotCrossRestore()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let first = Focusable();
		let second = Focusable();
		root.AddView(first);
		root.AddView(second);

		focus.SetFocus(first);
		let savedFirst = focus.SaveAndClearFocus(); // popup A opens

		focus.SetFocus(second);
		let savedSecond = focus.SaveAndClearFocus(); // popup B opens

		// A closes FIRST, out of order.
		focus.RestoreFocus(savedFirst);
		Test.Assert(focus.FocusedView == first, "A restored what A saved");

		focus.RestoreFocus(savedSecond);
		Test.Assert(focus.FocusedView == second, "and B what B saved");
	}

	/// Restoring onto a view that went away, or was disabled while the popup was open, leaves
	/// focus CLEARED rather than stranding the keyboard somewhere invisible.
	[Test]
	public static void RestoringSkipsAViewThatCanNoLongerTakeFocus()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let removed = Focusable();
		removed.AddRef();
		defer removed.ReleaseRef();
		root.AddView(removed);
		focus.SetFocus(removed);
		let savedRemoved = focus.SaveAndClearFocus();
		root.RemoveView(removed);

		focus.RestoreFocus(savedRemoved);
		Test.Assert(focus.FocusedView == null, "the view is gone");

		let disabled = Focusable();
		root.AddView(disabled);
		focus.SetFocus(disabled);
		let savedDisabled = focus.SaveAndClearFocus();
		disabled.IsEnabled = false;

		focus.RestoreFocus(savedDisabled);
		Test.Assert(focus.FocusedView == null, "disabled while the popup was open");
	}

	// ---- Capture ----------------------------------------------------------------------------

	[Test]
	public static void CaptureIsSetAndReleased()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let view = Focusable();
		root.AddView(view);

		focus.SetCapture(view);
		Test.Assert(focus.HasCapture);
		Test.Assert(focus.CapturedView == view);

		focus.ReleaseCapture();
		Test.Assert(!focus.HasCapture);
	}

	/// A view going away takes its focus AND its capture with it, or a released mouse would
	/// deliver to something that no longer exists.
	[Test]
	public static void DeletingAViewClearsItsFocusAndCapture()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let view = Focusable();
		view.AddRef();
		defer view.ReleaseRef();
		root.AddView(view);
		focus.SetFocus(view);
		focus.SetCapture(view);

		root.RemoveView(view);

		Test.Assert(focus.FocusedView == null);
		Test.Assert(!focus.HasCapture);
	}

	// ---- Tab traversal ----------------------------------------------------------------------

	/// Tab cycles the tab stops and WRAPS, and with nothing focused it lands on the first.
	[Test]
	public static void TabCyclesThroughTheTabStops()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let first = Focusable();
		let second = Focusable();
		let third = Focusable();
		root.AddView(first);
		root.AddView(second);
		root.AddView(third);
		UITest.LayoutPass(context, root);

		focus.FocusNext();
		Test.Assert(focus.FocusedView == first, "nothing focused lands on the first");

		focus.FocusNext();
		Test.Assert(focus.FocusedView == second);
		focus.FocusNext();
		Test.Assert(focus.FocusedView == third);
		focus.FocusNext();
		Test.Assert(focus.FocusedView == first, "wrapped");
	}

	[Test]
	public static void ShiftTabCyclesBackward()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let first = Focusable();
		let second = Focusable();
		root.AddView(first);
		root.AddView(second);
		UITest.LayoutPass(context, root);

		focus.SetFocus(second);
		focus.FocusPrev();
		Test.Assert(focus.FocusedView == first);

		focus.FocusPrev();
		Test.Assert(focus.FocusedView == second, "wrapped backward");
	}

	/// A focusable view that is NOT a tab stop is skipped: it can be clicked into or reached
	/// with the arrows, but Tab passes it by.
	[Test]
	public static void TabSkipsAViewThatIsNotATabStop()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let first = Focusable();
		let skipped = Focusable();
		skipped.IsTabStop = false;
		let last = Focusable();
		root.AddView(first);
		root.AddView(skipped);
		root.AddView(last);
		UITest.LayoutPass(context, root);

		focus.SetFocus(first);
		focus.FocusNext();

		Test.Assert(focus.FocusedView == last);
	}

	/// A disabled container takes its whole subtree out of the traversal.
	[Test]
	public static void TabSkipsTheSubtreeOfADisabledContainer()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let reachable = Focusable();
		root.AddView(reachable);

		let disabledPanel = new TestGroup();
		disabledPanel.IsEnabled = false;
		root.AddView(disabledPanel);
		let unreachable = Focusable();
		disabledPanel.AddView(unreachable);
		UITest.LayoutPass(context, root);

		focus.FocusNext();
		Test.Assert(focus.FocusedView == reachable);
		focus.FocusNext();
		Test.Assert(focus.FocusedView == reachable, "nothing else is reachable");
	}

	/// IsFocusWithin answers for the focused view AND every ancestor of it, which is what a
	/// panel highlighting itself while something inside it has focus needs.
	[Test]
	public static void FocusWithinAnswersForEveryAncestor()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new TestGroup();
		root.AddView(group);
		let inner = new TestGroup();
		group.AddView(inner);
		let view = Focusable();
		inner.AddView(view);
		let sibling = Focusable();
		root.AddView(sibling);

		context.GetFocusManager().SetFocus(view);

		Test.Assert(view.IsFocusWithin());
		Test.Assert(inner.IsFocusWithin());
		Test.Assert(group.IsFocusWithin());
		Test.Assert(!sibling.IsFocusWithin());
	}

	// ---- Directional movement ---------------------------------------------------------------

	[Test]
	public static void ArrowsMoveToTheNeighbourInThatDirection()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let top = Focusable(100, 30);
		let bottom = Focusable(100, 30);
		root.AddView(top);
		root.AddView(bottom);
		top.Layout(100, 50, 100, 30);
		bottom.Layout(100, 150, 100, 30);

		focus.SetFocus(top);
		Test.Assert(focus.MoveFocus(.Down));
		Test.Assert(focus.FocusedView == bottom);

		Test.Assert(focus.MoveFocus(.Up));
		Test.Assert(focus.FocusedView == top);
	}

	[Test]
	public static void ArrowsMoveSidewaysToo()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let left = Focusable(100, 30);
		let right = Focusable(100, 30);
		root.AddView(left);
		root.AddView(right);
		left.Layout(50, 100, 100, 30);
		right.Layout(250, 100, 100, 30);

		focus.SetFocus(left);
		Test.Assert(focus.MoveFocus(.Right));
		Test.Assert(focus.FocusedView == right);

		Test.Assert(focus.MoveFocus(.Left));
		Test.Assert(focus.FocusedView == left);
	}

	/// Nothing that way is FALSE and leaves focus alone, rather than wrapping the way Tab does:
	/// arrows are spatial, and wrapping across the screen would be disorienting.
	[Test]
	public static void MovingWhereThereIsNothingAnswersFalse()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let only = Focusable(100, 30);
		root.AddView(only);
		only.Layout(100, 100, 100, 30);
		focus.SetFocus(only);

		Test.Assert(!focus.MoveFocus(.Down));
		Test.Assert(focus.FocusedView == only);

		focus.ClearFocus();
		Test.Assert(!focus.MoveFocus(.Down), "and with nothing focused at all");
	}

	/// The nearest candidate wins, scored so a small sideways drift beats a large one. That
	/// weighting is what keeps arrow movement inside a column.
	[Test]
	public static void ArrowsPreferTheClosestCandidate()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let top = Focusable(100, 30);
		let near = Focusable(100, 30);
		let far = Focusable(100, 30);
		root.AddView(top);
		root.AddView(near);
		root.AddView(far);
		top.Layout(100, 50, 100, 30);
		near.Layout(100, 120, 100, 30);
		far.Layout(100, 400, 100, 30);

		focus.SetFocus(top);
		Test.Assert(focus.MoveFocus(.Down));
		Test.Assert(focus.FocusedView == near);
	}

	/// An EXPLICIT override beats the spatial search, which is how a layout that scores badly
	/// still navigates the way its author meant.
	[Test]
	public static void AnExplicitOverrideBeatsTheSpatialSearch()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let focus = context.GetFocusManager();

		let start = Focusable(100, 30);
		let nearest = Focusable(100, 30);
		let chosen = Focusable(100, 30);
		root.AddView(start);
		root.AddView(nearest);
		root.AddView(chosen);
		start.Layout(100, 50, 100, 30);
		nearest.Layout(100, 120, 100, 30);
		chosen.Layout(100, 400, 100, 30);

		start.NextFocusDown = chosen.Id;
		focus.SetFocus(start);

		Test.Assert(focus.MoveFocus(.Down));
		Test.Assert(focus.FocusedView == chosen, "not the spatially nearest");
	}

	// ---- Shortcuts --------------------------------------------------------------------------

	[Test]
	public static void AGlobalShortcutFiresOnItsExactChord()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let shortcuts = context.GetShortcuts();

		var fired = false;
		shortcuts.AddGlobal(.S, .Ctrl, new [&fired]() => { fired = true; });

		Test.Assert(shortcuts.TryDispatch(.S, .LeftCtrl));
		Test.Assert(fired);

		fired = false;
		Test.Assert(!shortcuts.TryDispatch(.D, .LeftCtrl), "the wrong key");
		Test.Assert(!fired);
		Test.Assert(!shortcuts.TryDispatch(.S, .None), "the wrong modifiers");
		Test.Assert(!fired);
	}

	/// A SCOPED shortcut fires only while focus is inside its scope.
	[Test]
	public static void AScopedShortcutFiresOnlyWithinItsScope()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let shortcuts = context.GetShortcuts();

		let panel = new TestGroup();
		root.AddView(panel);
		let inside = Focusable();
		panel.AddView(inside);
		let outside = Focusable();
		root.AddView(outside);

		var fired = false;
		shortcuts.AddScoped(.S, .Ctrl, new [&fired]() => { fired = true; }, panel);

		context.GetFocusManager().SetFocus(inside);
		Test.Assert(shortcuts.TryDispatch(.S, .LeftCtrl));
		Test.Assert(fired);

		fired = false;
		context.GetFocusManager().SetFocus(outside);
		Test.Assert(!shortcuts.TryDispatch(.S, .LeftCtrl));
		Test.Assert(!fired);
	}

	/// A scoped shortcut BEATS a global one on the same chord: a text editor's own Ctrl+F must
	/// not be stolen by the window's.
	[Test]
	public static void AScopedShortcutBeatsAGlobalOne()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let shortcuts = context.GetShortcuts();

		let panel = new TestGroup();
		root.AddView(panel);
		let child = Focusable();
		panel.AddView(child);

		var globalFired = false;
		var scopedFired = false;
		shortcuts.AddGlobal(.S, .Ctrl, new [&globalFired]() => { globalFired = true; });
		shortcuts.AddScoped(.S, .Ctrl, new [&scopedFired]() => { scopedFired = true; }, panel);

		context.GetFocusManager().SetFocus(child);
		shortcuts.TryDispatch(.S, .LeftCtrl);

		Test.Assert(scopedFired);
		Test.Assert(!globalFired);
	}

	[Test]
	public static void ARemovedShortcutStopsFiring()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let shortcuts = context.GetShortcuts();

		var fired = false;
		let shortcut = shortcuts.AddGlobal(.S, .Ctrl, new [&fired]() => { fired = true; });
		shortcuts.Remove(shortcut);

		Test.Assert(!shortcuts.TryDispatch(.S, .LeftCtrl));
		Test.Assert(!fired);
	}

	/// A scoped shortcut goes with the view it was scoped to, or it would keep firing for a
	/// panel that has left the tree.
	[Test]
	public static void AScopedShortcutGoesWithItsView()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }
		let shortcuts = context.GetShortcuts();

		let panel = new TestGroup();
		panel.AddRef();
		defer panel.ReleaseRef();
		root.AddView(panel);
		let child = Focusable();
		panel.AddView(child);

		var fired = false;
		shortcuts.AddScoped(.S, .Ctrl, new [&fired]() => { fired = true; }, panel);
		Test.Assert(shortcuts.Count == 1);

		root.RemoveView(panel);

		Test.Assert(shortcuts.Count == 0);
		Test.Assert(!shortcuts.TryDispatch(.S, .LeftCtrl));
		Test.Assert(!fired);
	}
}
