using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The View cluster itself: identity and tree links, the mutation queue, and the context's
/// root list, registry and clocks.
class ViewClusterTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	// ---- MutationQueue ----------------------------------------------------------------------

	[Test]
	public static void AnEmptyQueueHasNothingPending()
	{
		let queue = scope MutationQueue();

		Test.Assert(!queue.HasPending);
	}

	[Test]
	public static void QueueingAnActionMakesItPending()
	{
		let queue = scope MutationQueue();
		queue.QueueAction(new () => {});

		Test.Assert(queue.HasPending);
	}

	[Test]
	public static void DrainingRunsTheActionsAndEmptiesTheQueue()
	{
		let queue = scope MutationQueue();
		var counter = 0;
		queue.QueueAction(new [&counter]() => { counter++; });
		queue.QueueAction(new [&counter]() => { counter++; });

		queue.Drain();

		Test.Assert(counter == 2);
		Test.Assert(!queue.HasPending);
	}

	[Test]
	public static void ActionsRunInTheOrderTheyWereQueued()
	{
		let queue = scope MutationQueue();
		var order = 0;
		var first = -1;
		var second = -1;
		queue.QueueAction(new [&]() => { first = order++; });
		queue.QueueAction(new [&]() => { second = order++; });

		queue.Drain();

		Test.Assert(first == 0);
		Test.Assert(second == 1);
	}

	/// An action may queue MORE work, and the drain has to pick it up rather than leave it for
	/// the next frame: this is how a handler that removes its own view then triggers a relayout
	/// settles in one pass.
	[Test]
	public static void DrainingHandlesActionsQueuedDuringTheDrain()
	{
		let queue = scope MutationQueue();
		var counter = 0;
		queue.QueueAction(new [&]() =>
			{
				counter++;
				queue.QueueAction(new [&counter]() => { counter++; });
			});

		queue.Drain();

		Test.Assert(counter == 2, "both the original and the re-entrant one ran");
		Test.Assert(!queue.HasPending);
	}

	[Test]
	public static void BeginFrameDrainsTheQueue()
	{
		let context = scope UIContext();
		var counter = 0;
		context.MutationQueue.QueueAction(new [&counter]() => { counter++; });

		context.BeginFrame(0.016f);

		Test.Assert(counter == 1);
	}

	/// Queueing the same view twice must not remove it twice. The pending flag is what guards
	/// it, and it is set at QUEUE time rather than at drain time for exactly that reason.
	[Test]
	public static void QueueingADeleteTwiceIsHarmless()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root);

		let view = new TestView();
		root.AddView(view);

		context.MutationQueue.QueueDelete(view);
		Test.Assert(view.IsPendingDeletion);

		context.MutationQueue.QueueDelete(view);
		context.MutationQueue.Drain();
	}

	// ---- UIContext: root views --------------------------------------------------------------

	[Test]
	public static void AddingARootRegistersItAndMakesItActive()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		context.AddRootView(root);

		Test.Assert(context.RootViewCount == 1);
		Test.Assert(context.ActiveInputRoot == root);
		Test.Assert(root.Context == context);
	}

	/// The FIRST root becomes active and stays that way: adding a second window must not steal
	/// input from the one the person is using.
	[Test]
	public static void TheFirstRootStaysActiveWhenAnotherIsAdded()
	{
		let context = scope UIContext();
		let first = new RootView();
		defer first.ReleaseRef();
		let second = new RootView();
		defer second.ReleaseRef();

		context.AddRootView(first);
		context.AddRootView(second);

		Test.Assert(context.ActiveInputRoot == first);
	}

	/// Removing the ACTIVE root hands the role to a survivor rather than leaving input pointing
	/// at nothing.
	[Test]
	public static void RemovingTheActiveRootPromotesAnother()
	{
		let context = scope UIContext();
		let first = new RootView();
		defer first.ReleaseRef();
		let second = new RootView();
		defer second.ReleaseRef();

		context.AddRootView(first);
		context.AddRootView(second);
		context.RemoveRootView(first);

		Test.Assert(context.RootViewCount == 1);
		Test.Assert(context.ActiveInputRoot == second);
	}

	[Test]
	public static void RemovingTheLastRootClearsTheContextAndTheActiveRoot()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();

		context.AddRootView(root);
		context.RemoveRootView(root);

		Test.Assert(root.Context == null);
		Test.Assert(context.RootViewCount == 0);
		Test.Assert(context.ActiveInputRoot == null);
	}

	// ---- UIContext: the registry ------------------------------------------------------------

	[Test]
	public static void AnAttachedViewIsFoundByIdPlainlyAndTyped()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root);

		let child = new TestView(50, 30);
		root.AddView(child);

		Test.Assert(context.GetViewById(child.Id) == child);
		Test.Assert(context.GetViewById<TestView>(child.Id) == child);
	}

	[Test]
	public static void ARemovedViewStopsResolving()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root);

		let child = new TestView(50, 30);
		child.AddRef(); // held past the removal so the id can be looked up afterwards
		defer child.ReleaseRef();
		root.AddView(child);
		let id = child.Id;

		root.RemoveView(child);

		Test.Assert(context.GetViewById(id) == null);
	}

	/// Attaching registers the WHOLE subtree, so a tree built detached and added in one go is
	/// as findable as one built in place.
	[Test]
	public static void AttachingRegistersTheWholeSubtree()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root);

		let group = new TestGroup();
		let child = new TestView(50, 30);
		group.AddView(child); // the subtree is built BEFORE it is attached
		root.AddView(group);

		Test.Assert(context.GetViewById(group.Id) == group);
		Test.Assert(context.GetViewById(child.Id) == child);
		Test.Assert(child.Context == context);
	}

	[Test]
	public static void DetachingUnregistersTheWholeSubtree()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root);

		let group = new TestGroup();
		group.AddRef(); // held past the removal
		defer group.ReleaseRef();
		let child = new TestView(50, 30);
		child.AddRef();
		defer child.ReleaseRef();
		root.AddView(group);
		group.AddView(child);
		let groupId = group.Id;
		let childId = child.Id;

		root.RemoveView(group);

		Test.Assert(context.GetViewById(groupId) == null);
		Test.Assert(context.GetViewById(childId) == null);
	}

	// ---- UIContext: clocks and DPI ----------------------------------------------------------

	[Test]
	public static void BeginFrameAdvancesTheDeltaAndTheTotal()
	{
		let context = scope UIContext();

		context.BeginFrame(0.016f);
		Test.Assert(Near(context.DeltaTime, 0.016f));
		Test.Assert(Near(context.TotalTime, 0.016f));

		context.BeginFrame(0.016f);
		Test.Assert(Near(context.TotalTime, 0.032f));
	}

	[Test]
	public static void TheDpiScaleComesFromTheActiveRootAndDefaultsToOne()
	{
		let context = scope UIContext();
		Test.Assert(context.DpiScale == 1.0f, "with no root at all");

		let root = new RootView();
		defer root.ReleaseRef();
		root.DpiScale = 2.0f;
		context.AddRootView(root);

		Test.Assert(context.DpiScale == 2.0f);
	}

	/// The managers exist from construction, so nothing has to null check one before asking it
	/// a question.
	[Test]
	public static void TheManagersExistByDefault()
	{
		let context = scope UIContext();

		Test.Assert(context.GetInputManager() != null);
		Test.Assert(context.GetFocusManager() != null);
		Test.Assert(context.GetShortcuts() != null);
		Test.Assert(context.DragDrop != null);
		Test.Assert(context.Animations != null);
		Test.Assert(context.Tooltips != null);
	}

	// ---- View: identity and tree ------------------------------------------------------------

	[Test]
	public static void EveryViewHasItsOwnValidId()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root);

		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		root.AddView(a);
		root.AddView(b);

		Test.Assert(!a.Id.Equals(b.Id));
		Test.Assert(a.Id.IsValid);
		Test.Assert(b.Id.IsValid);
	}

	[Test]
	public static void AddingSetsTheParentAndTheContextAndRemovingClearsBoth()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root);

		let child = new TestView(50, 30);
		child.AddRef(); // held past the removal
		defer child.ReleaseRef();
		root.AddView(child);

		Test.Assert(child.Parent == root);
		Test.Assert(child.Context == context);

		root.RemoveView(child);

		Test.Assert(child.Context == null);
		Test.Assert(child.Parent == null);
	}

	/// Root walks UP, so every view in a tree answers the same root, the root itself included.
	[Test]
	public static void RootWalksUpFromAnyDepth()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root);

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		Test.Assert(child.Root() == root);
		Test.Assert(group.Root() == root);
		Test.Assert(root.Root() == root);
	}

	// ---- View: measure, arrange and damage ---------------------------------------------------

	[Test]
	public static void AZeroSizedViewMeasuresToZero()
	{
		let view = new TestView(0, 0);
		defer view.ReleaseRef();

		view.Measure(BoxConstraints.Loose(100, 100));

		Test.Assert(view.MeasuredSize.X == 0);
		Test.Assert(view.MeasuredSize.Y == 0);
	}

	[Test]
	public static void LayoutSetsTheBounds()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();

		view.Layout(10, 20, 100, 50);

		Test.Assert(view.Bounds.X == 10);
		Test.Assert(view.Bounds.Y == 20);
		Test.Assert(view.Width == 100);
		Test.Assert(view.Height == 50);
	}

	/// A view starts DIRTY, since it has never been drawn, and invalidating marks both the view
	/// and its context.
	[Test]
	public static void InvalidateMarksTheViewAndTheContext()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root);

		let child = new TestView(50, 30);
		root.AddView(child);

		Test.Assert(child.NeedsRedraw);
		child.ClearRedrawFlag();
		Test.Assert(!child.NeedsRedraw);

		child.Invalidate();

		Test.Assert(child.NeedsRedraw);
		Test.Assert(context.NeedsRedraw);
	}

	[Test]
	public static void AGoneChildSurvivesAWholeLayoutPass()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root);

		let child = new TestView(100, 50);
		child.Visibility = .Gone;
		root.AddView(child);

		UITest.LayoutPass(context, root);
		// A Gone view contributes nothing and must not fault on the way past.
	}

	// ---- View: coordinates ------------------------------------------------------------------

	[Test]
	public static void LocalToScreenAndBackAccumulateEveryAncestorsOrigin()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root);

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		group.Layout(10, 20, 100, 100);
		child.Layout(5, 5, 50, 30);

		let screen = child.LocalToScreen(.(0, 0));
		Test.Assert(Near(screen.X, 15));
		Test.Assert(Near(screen.Y, 25));

		let local = child.ScreenToLocal(.(15, 25));
		Test.Assert(Near(local.X, 0));
		Test.Assert(Near(local.Y, 0));
	}

	// ---- View: effective state --------------------------------------------------------------

	/// Disabling a panel disables everything inside it WITHOUT touching the children, so the
	/// children's own IsEnabled still says what they asked for.
	[Test]
	public static void EffectiveEnablementWalksTheParents()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root);

		let group = new TestGroup();
		let child = new TestView(50, 30);
		root.AddView(group);
		group.AddView(child);

		Test.Assert(child.IsEffectivelyEnabled());

		group.IsEnabled = false;

		Test.Assert(!child.IsEffectivelyEnabled());
		Test.Assert(!group.IsEffectivelyEnabled());
		Test.Assert(child.IsEnabled, "the child itself never asked to be disabled");
	}

	[Test]
	public static void ADisabledViewReportsTheDisabledControlState()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();
		view.IsEnabled = false;

		Test.Assert(view.GetControlState().HasFlag(.Disabled));
	}

	/// The cursor walks UP for the first view that is not Default, so a panel can set a cursor
	/// for everything inside it and a child can still override.
	[Test]
	public static void TheEffectiveCursorInheritsUnlessTheChildOverrides()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root);

		let group = new TestGroup();
		group.Cursor = .Hand;
		let inherits = new TestView(50, 30);
		let overrides = new TestView(50, 30);
		overrides.Cursor = .IBeam;
		root.AddView(group);
		group.AddView(inherits);
		group.AddView(overrides);

		Test.Assert(inherits.EffectiveCursor(.(0, 0)) == .Hand);
		Test.Assert(inherits.Cursor == .Default, "it never set one of its own");
		Test.Assert(overrides.EffectiveCursor(.(0, 0)) == .IBeam);
	}

	// ---- View: user data --------------------------------------------------------------------

	/// User data is NON owning and untyped: the caller keeps it alive.
	[Test]
	public static void UserDataRoundTripsAndAnswersNullWhenUnset()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();
		let value = scope String("hello");

		view.SetUserData("key", Internal.UnsafeCastToPtr(value));

		Test.Assert(view.GetUserData("key") == Internal.UnsafeCastToPtr(value));
		Test.Assert(view.GetUserData("missing") == null);
	}

	/// The typed getter hands back a pointer to the stored DATA, so it suits a value type.
	///
	/// Raptor's version of this test stores a String, which works there because a C++ String is
	/// a value and `&str` is a pointer to it. In Beef a String is a reference, so the address
	/// stored is the object's and `String*` would be a pointer to a reference slot: a different
	/// thing entirely, and dereferencing it would read the wrong memory. A class comes back
	/// through GetUserData plus a cast instead, which is what the case above does.
	[Test]
	public static void TheTypedGetterSuitsAValueType()
	{
		let view = new TestView(50, 30);
		defer view.ReleaseRef();
		var payload = Float2(3, 4);

		view.SetUserData("payload", &payload);

		let typed = view.GetUserData<Float2>("payload");
		Test.Assert(typed == &payload);
		Test.Assert(typed.X == 3);
		Test.Assert(typed.Y == 4);
	}
}
