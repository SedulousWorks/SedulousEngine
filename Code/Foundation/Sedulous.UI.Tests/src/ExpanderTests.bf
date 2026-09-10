using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The Expander and the header band it is built from.
class ExpanderTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 400, 300);
	}

	[Test]
	public static void AnExpanderStartsOpen()
	{
		let expander = new Expander("Header");
		defer expander.ReleaseRef();

		Test.Assert(expander.IsExpanded);
	}

	/// Collapsing sets the content GONE rather than merely hiding it, so a folded body stops
	/// costing layout as well as pixels.
	[Test]
	public static void CollapsingSendsTheContentGoneAndReportsIt()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let expander = new Expander("Settings");
		let content = new TestView(100, 50);
		expander.SetContent(content);
		root.AddView(expander);

		var fired = false;
		expander.OnExpandedChanged.Add(new [&fired](e, isExpanded) => { fired = true; });

		expander.SetIsExpanded(false);
		Test.Assert(!expander.IsExpanded);
		Test.Assert(fired);
		Test.Assert(content.Visibility == .Gone);

		expander.SetIsExpanded(true);
		Test.Assert(content.Visibility == .Visible);
	}

	/// Setting the state it already holds reports nothing.
	[Test]
	public static void SettingTheStateAnExpanderAlreadyHoldsIsSilent()
	{
		let expander = new Expander("Header");
		defer expander.ReleaseRef();

		var fires = 0;
		expander.OnExpandedChanged.Add(new [&fires](e, isExpanded) => { fires++; });

		expander.SetIsExpanded(true);
		Test.Assert(fires == 0);
	}

	/// Content added to a COLLAPSED expander is matched to that state on the way in, rather
	/// than appearing until the next toggle.
	[Test]
	public static void ContentAddedWhileCollapsedIsGoneImmediately()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let expander = new Expander("Header");
		root.AddView(expander);
		expander.SetIsExpanded(false);

		let content = new TestView(100, 50);
		expander.SetContent(content);

		Test.Assert(content.Visibility == .Gone);
	}

	/// Collapsed, the expander measures to its band alone.
	[Test]
	public static void ACollapsedExpanderMeasuresToItsBand()
	{
		let expander = new Expander("Header");
		defer expander.ReleaseRef();
		expander.SetContent(new TestView(100, 50));

		expander.Measure(BoxConstraints.Loose(400, 300));
		let expandedHeight = expander.MeasuredSize.Y;

		expander.SetIsExpanded(false);
		expander.Measure(BoxConstraints.Loose(400, 300));
		let collapsedHeight = expander.MeasuredSize.Y;

		Test.Assert(collapsedHeight < expandedHeight);
		Test.Assert(collapsedHeight == expander.HeaderHeight.Value);
	}

	/// Actions taller than HeaderHeight GROW the band rather than overflowing it, which is
	/// what makes the header a real layout row instead of something painted at a fixed height.
	[Test]
	public static void OversizedHeaderActionsGrowTheBand()
	{
		let expander = new Expander("Header");
		defer expander.ReleaseRef();
		expander.SetHeaderActions(new TestView(44, 40));
		expander.SetIsExpanded(false);

		expander.Measure(BoxConstraints.Loose(400, 300));

		Test.Assert(expander.HeaderBandHeight > expander.HeaderHeight.Value);
		Test.Assert(expander.MeasuredSize.Y == expander.HeaderBandHeight);

		// Actions that fit leave the band at its minimum.
		expander.SetHeaderActions(new TestView(30, 18));
		expander.Measure(BoxConstraints.Loose(400, 300));
		Test.Assert(expander.HeaderBandHeight == expander.HeaderHeight.Value);
	}

	/// Right-aligned with a small inset, and centred down the band.
	[Test]
	public static void HeaderActionsSitAtTheRightOfTheBand()
	{
		let expander = new Expander("Header");
		defer expander.ReleaseRef();
		let actions = new TestView(44, 18);
		expander.SetHeaderActions(actions);

		expander.Measure(BoxConstraints.Tight(400, 200));
		expander.Layout(0, 0, 400, 200);

		Test.Assert(actions.Bounds.X == 400 - 44 - 4);
		Test.Assert(actions.Bounds.Y == (expander.HeaderBandHeight - 18) * 0.5f);
	}

	/// A press the actions handled never reaches the toggle, which is the whole reason the
	/// band is a layout row with real children rather than a painted strip.
	[Test]
	public static void APressHandledByTheActionsDoesNotToggle()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let expander = new Expander("Header");
		root.AddView(expander);
		expander.SetHeaderActions(new TestView(44, 18));
		expander.Measure(BoxConstraints.Tight(400, 200));
		expander.Layout(0, 0, 400, 200);

		let header = expander.GetChildAt(0);

		let handled = scope MouseEventArgs();
		handled.Set(380, 10, .Left);
		handled.Handled = true;
		header.OnMouseDown(handled);
		Test.Assert(expander.IsExpanded, "an action took it");

		// A press nothing took toggles the band.
		let plain = scope MouseEventArgs();
		plain.Set(100, 10, .Left);
		header.OnMouseDown(plain);
		Test.Assert(!expander.IsExpanded);
		Test.Assert(plain.Handled);
	}

	/// Space and Return toggle; the arrows open and close, and are left UNHANDLED when there
	/// is nothing to do, so Right inside an open expander can still move focus on.
	[Test]
	public static void TheKeyboardOpensAndClosesAnExpander()
	{
		let expander = new Expander("Header");
		defer expander.ReleaseRef();

		let left = scope KeyEventArgs();
		left.Set(.Left, .None, false);
		expander.OnKeyDown(left);
		Test.Assert(!expander.IsExpanded);
		Test.Assert(left.Handled);

		// Already closed: Left has nothing to do and lets the key past.
		let leftAgain = scope KeyEventArgs();
		leftAgain.Set(.Left, .None, false);
		expander.OnKeyDown(leftAgain);
		Test.Assert(!leftAgain.Handled);

		let right = scope KeyEventArgs();
		right.Set(.Right, .None, false);
		expander.OnKeyDown(right);
		Test.Assert(expander.IsExpanded);

		let rightAgain = scope KeyEventArgs();
		rightAgain.Set(.Right, .None, false);
		expander.OnKeyDown(rightAgain);
		Test.Assert(!rightAgain.Handled, "already open");

		let space = scope KeyEventArgs();
		space.Set(.Space, .None, false);
		expander.OnKeyDown(space);
		Test.Assert(!expander.IsExpanded);

		expander.OnActivate();
		Test.Assert(expander.IsExpanded);
	}

	/// Replacing the content releases the one held before, since the group owns it.
	[Test]
	public static void ReplacingTheContentReleasesTheOneHeldBefore()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let expander = new Expander("Header");
		root.AddView(expander);

		let first = new TestView(100, 50);
		first.AddRef(); // the test's own reference, so it outlives the expander letting go
		defer first.ReleaseRef();

		expander.SetContent(first);
		Test.Assert(first.RefCount == 2);

		expander.SetContent(new TestView(10, 10));
		Test.Assert(first.RefCount == 1, "the expander let go of the first");

		expander.SetContent(null);
		Test.Assert(expander.Content == null);
	}
}
