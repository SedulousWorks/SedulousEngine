using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Gamekit;

namespace Sedulous.UI.Gamekit.Tests;

/// The stack mechanics a game rides: push, pop, replace, clear, top and count, the Opaque
/// "hide what is below" rule, the lifecycle hooks, focus save and restore, and Back refusing to
/// empty the stack.
///
/// Transitions default to None here, so structural changes run inline because a test context
/// is idle, and nothing needs a frame pump. The last case is the exception, and it is there
/// precisely to prove what happens when they do not.
class ScreenStackTests
{
	/// The screen comes back with ONE reference, which Push consumes. A test that keeps the
	/// pointer afterwards adds its own first.
	private static CountingScreen MakeScreen(ScreenMode mode = .Modal)
	{
		let screen = new CountingScreen();
		screen.Mode = mode;
		return screen;
	}

	[Test]
	public static void PushAndPopTrackTopAndCount()
	{
		let bed = scope GamekitBed();

		Test.Assert(bed.Stack.Count == 0);
		Test.Assert(bed.Stack.Top == null);

		let a = MakeScreen();
		defer a.ReleaseRef();
		let b = MakeScreen();
		defer b.ReleaseRef();

		a.AddRef();
		Test.Assert(bed.Stack.Push(a) == a);
		Test.Assert(bed.Stack.Count == 1);
		Test.Assert(bed.Stack.Top == a);

		b.AddRef();
		bed.Stack.Push(b);
		Test.Assert(bed.Stack.Count == 2);
		Test.Assert(bed.Stack.Top == b);

		bed.Stack.Pop();
		Test.Assert(bed.Stack.Count == 1);
		Test.Assert(bed.Stack.Top == a);

		bed.Stack.Pop();
		Test.Assert(bed.Stack.Count == 0);

		bed.Stack.Pop(); // popping an empty stack is a safe no op
		Test.Assert(bed.Stack.Count == 0);
	}

	[Test]
	public static void ReplaceSwapsTheTopInPlace()
	{
		let bed = scope GamekitBed();

		let a = MakeScreen();
		defer a.ReleaseRef();
		let b = MakeScreen();
		defer b.ReleaseRef();

		a.AddRef();
		bed.Stack.Push(a);
		b.AddRef();
		Test.Assert(bed.Stack.Replace(b) == b);
		Test.Assert(bed.Stack.Count == 1);
		Test.Assert(bed.Stack.Top == b);

		// The old top left the tree; the new one took its place.
		Test.Assert(a.Parent == null);
		Test.Assert(b.Parent == bed.Root);
	}

	[Test]
	public static void ClearEmptiesTheStack()
	{
		let bed = scope GamekitBed();

		bed.Stack.Push(MakeScreen());
		bed.Stack.Push(MakeScreen());
		bed.Stack.Push(MakeScreen());
		Test.Assert(bed.Stack.Count == 3);

		bed.Stack.Clear();
		Test.Assert(bed.Stack.Count == 0);
		Test.Assert(bed.Stack.Top == null);
	}

	[Test]
	public static void AnOpaqueScreenHidesThoseBelowAndPoppingRevealsThem()
	{
		let bed = scope GamekitBed();

		let hud = MakeScreen(.Overlay);
		defer hud.ReleaseRef();
		let menu = MakeScreen(.Opaque);
		defer menu.ReleaseRef();

		hud.AddRef();
		bed.Stack.Push(hud);
		Test.Assert(hud.Visibility == .Visible);

		menu.AddRef();
		bed.Stack.Push(menu);
		Test.Assert(menu.Visibility == .Visible);
		Test.Assert(hud.Visibility == .Hidden, "covered by the opaque menu");

		bed.Stack.Pop();
		Test.Assert(hud.Visibility == .Visible, "revealed again");
	}

	/// The difference between the two shielding modes, and the reason there are three and not
	/// two: a pause menu must leave the frozen game visible behind it.
	[Test]
	public static void AModalScreenShieldsInputWithoutHidingWhatIsBelow()
	{
		let bed = scope GamekitBed();

		let hud = MakeScreen(.Overlay);
		defer hud.ReleaseRef();
		let dialog = MakeScreen(.Modal);
		defer dialog.ReleaseRef();

		hud.AddRef();
		bed.Stack.Push(hud);
		dialog.AddRef();
		bed.Stack.Push(dialog);

		Test.Assert(hud.Visibility == .Visible, "still visible behind the modal");
		Test.Assert(dialog.IsHitTestVisible, "a modal shields input below it");
		Test.Assert(!hud.IsHitTestVisible, "an overlay passes input through");
	}

	[Test]
	public static void LifecycleHooksFireOnPushPopCoverAndUncover()
	{
		let bed = scope GamekitBed();

		let a = MakeScreen();
		defer a.ReleaseRef();
		let b = MakeScreen();
		defer b.ReleaseRef();

		a.AddRef();
		bed.Stack.Push(a);
		Test.Assert(a.Enter == 1);
		Test.Assert(a.Shown == 1);

		b.AddRef();
		bed.Stack.Push(b); // b enters and shows; a is covered
		Test.Assert(b.Enter == 1);
		Test.Assert(b.Shown == 1);
		Test.Assert(a.Hidden == 1);

		bed.Stack.Pop(); // b exits; a is uncovered and shows again
		Test.Assert(b.Exit == 1);
		Test.Assert(a.Shown == 2);
	}

	[Test]
	public static void FocusIsSavedOnPushAndRestoredOnPop()
	{
		let bed = scope GamekitBed();
		let focus = bed.Context.GetFocusManager();
		Test.Assert(focus != null);

		let a = MakeScreen();
		defer a.ReleaseRef();
		a.AddButton("aBtn");
		a.AddRef();
		bed.Stack.Push(a); // push focuses a's first focusable
		Test.Assert(focus.FocusedView == a.FocusTarget);

		let b = MakeScreen();
		defer b.ReleaseRef();
		b.AddButton("bBtn");
		b.AddRef();
		bed.Stack.Push(b); // saves a's button, focuses b's
		Test.Assert(focus.FocusedView == b.FocusTarget);

		bed.Stack.Pop();
		Test.Assert(focus.FocusedView == a.FocusTarget, "a's button comes back");
	}

	[Test]
	public static void BackPopsTheTopUnlessItIsTheLastScreen()
	{
		let bed = scope GamekitBed();

		let a = MakeScreen();
		defer a.ReleaseRef();
		let b = MakeScreen();
		defer b.ReleaseRef();

		a.AddRef();
		bed.Stack.Push(a);
		Test.Assert(!bed.Stack.HandleBack(), "never pop the last screen out from under the player");
		Test.Assert(bed.Stack.Count == 1);

		b.AddRef();
		bed.Stack.Push(b);
		Test.Assert(bed.Stack.HandleBack());
		Test.Assert(bed.Stack.Count == 1);
		Test.Assert(bed.Stack.Top == a);
	}

	/// A REGRESSION GATE on the reason RunStructural exists.
	///
	/// BeginFrame ticks animations under a non idle phase deliberately, so a completion handler
	/// that removes its own view defers instead of running inline. Inline, the removal would
	/// reach CancelForView, which walks the very list the tick is already walking.
	[Test]
	public static void ATransitionPopDefersItsRemovalThroughTheMutationQueue()
	{
		let bed = scope GamekitBed();

		let a = MakeScreen();
		defer a.ReleaseRef();
		let b = MakeScreen();
		defer b.ReleaseRef();
		b.SetTransition(.(.Scale, 0.1f));

		a.AddRef();
		bed.Stack.Push(a);
		b.AddRef();
		bed.Stack.Push(b);
		Test.Assert(bed.Stack.Count == 2);

		// Let b's in transition finish first.
		for (int i < 4)
			bed.Context.BeginFrame(0.1f);

		Test.Assert(b.Exit == 0);
		bed.Stack.Pop();
		Test.Assert(bed.Stack.Count == 1, "the bookkeeping is synchronous");

		// One frame completes the out transition and QUEUES the removal; the next drains it.
		for (int i < 4)
			bed.Context.BeginFrame(0.1f);

		Test.Assert(b.Exit == 1, "OnExit fired, so b was really removed and nothing crashed");
		Test.Assert(bed.Stack.Top == a);
	}
}
