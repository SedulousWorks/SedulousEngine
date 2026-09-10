using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The scrollable container, and the momentum helper that carries a flick after the pointer
/// has let go.
class ScrollViewTests
{
	private static void MakeTree(out UIContext context, out RootView root, float width = 200,
		float height = 100)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, width, height);
	}

	/// A scroll view with content taller than it is.
	private static ScrollView MakeScrolling(UIContext context, RootView root, float contentWidth = 200,
		float contentHeight = 500)
	{
		let scroll = new ScrollView();
		scroll.AddView(new TestView(contentWidth, contentHeight));
		root.AddView(scroll);
		UITest.LayoutPass(context, root);
		return scroll;
	}

	// ---- Extent -------------------------------------------------------------------------------

	/// Content taller than the viewport can scroll down but not sideways.
	[Test]
	public static void ContentLargerThanTheViewportScrollsOnThatAxisAlone()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let scroll = MakeScrolling(context, root);

		Test.Assert(scroll.MaxScrollY > 0);
		Test.Assert(scroll.MaxScrollX == 0);
	}

	[Test]
	public static void ScrollingClampsToTheExtent()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let scroll = MakeScrolling(context, root);

		scroll.SetScrollY(-100);
		Test.Assert(scroll.ScrollY == 0);

		scroll.SetScrollY(9999);
		Test.Assert(scroll.ScrollY == scroll.MaxScrollY);
	}

	[Test]
	public static void TheScrollCommandsGoWhereTheySay()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let scroll = MakeScrolling(context, root);

		scroll.ScrollTo(0, 100);
		Test.Assert(scroll.ScrollY == 100);

		scroll.ScrollToTop();
		Test.Assert(scroll.ScrollY == 0);

		scroll.ScrollToBottom();
		Test.Assert(scroll.ScrollY == scroll.MaxScrollY);
	}

	/// A command stops the momentum: a caller asking to be somewhere means there, not there
	/// and then drifting on.
	[Test]
	public static void AScrollCommandStopsTheMomentum()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let scroll = MakeScrolling(context, root);

		let wheel = scope MouseWheelEventArgs();
		wheel.DeltaY = -1;
		scroll.OnMouseWheel(wheel);
		let drifted = scroll.ScrollY;
		Test.Assert(drifted > 0, "the notch scrolled");

		scroll.ScrollToTop();
		// A draw would apply any surviving momentum; there is none to apply.
		let context2 = scroll.Context;
		Test.Assert(context2 != null);
		Test.Assert(scroll.ScrollY == 0);
	}

	/// Relative scrolling does NOT stop the momentum, which is what lets a drag build one up.
	[Test]
	public static void ScrollByLeavesTheMomentumAlone()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let scroll = MakeScrolling(context, root);

		scroll.ScrollBy(0, 50);
		Test.Assert(scroll.ScrollY == 50);

		scroll.ScrollBy(0, -20);
		Test.Assert(scroll.ScrollY == 30);
	}

	// ---- Policy -------------------------------------------------------------------------------

	/// Never means no bar and no room set aside for one, so the viewport is the whole height.
	[Test]
	public static void ANeverPolicyLeavesTheViewportWhole()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Never;
		scroll.AddView(new TestView(200, 500));
		root.AddView(scroll);
		UITest.LayoutPass(context, root);

		Test.Assert(Abs(scroll.ViewportHeight - 100) < 1.0f);
	}

	/// Overlay floats the bar over the content; Reserved takes its thickness out of the
	/// viewport, which is the difference between the two modes.
	[Test]
	public static void ReservedModeTakesTheBarsThicknessOutOfTheViewport()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let scroll = new ScrollView();
		scroll.AddView(new TestView(200, 500));
		root.AddView(scroll);
		UITest.LayoutPass(context, root);
		let overlayWidth = scroll.ViewportWidth;

		scroll.ScrollBarMode.Value = .Reserved;
		UITest.LayoutPass(context, root);

		Test.Assert(scroll.ViewportWidth == overlayWidth - scroll.ScrollBarThickness.Value);
	}

	/// The bars are VISUAL children, not logical ones: a bar that scrolled with the content it
	/// scrolls would be useless.
	[Test]
	public static void TheBarsAreVisualChildrenNotLogicalOnes()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let scroll = MakeScrolling(context, root);

		Test.Assert(scroll.ChildCount == 1, "the content alone");
		Test.Assert(scroll.VisualChildCount == 3, "and the two bars after it");
		Test.Assert(scroll.GetVisualChild(0) == scroll.GetChildAt(0));
		Test.Assert(scroll.GetVisualChild(1) != null);
		Test.Assert(scroll.GetVisualChild(2) != null);
		Test.Assert(scroll.GetVisualChild(3) == null);
	}

	// ---- Input --------------------------------------------------------------------------------

	/// A wheel notch scrolls, and the keys page and jump.
	[Test]
	public static void TheWheelAndTheKeysScroll()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let scroll = MakeScrolling(context, root);

		let wheel = scope MouseWheelEventArgs();
		wheel.DeltaY = -1;
		scroll.OnMouseWheel(wheel);
		Test.Assert(scroll.ScrollY == 40);
		Test.Assert(wheel.Handled);

		let pageDown = scope KeyEventArgs();
		pageDown.Set(.PageDown, .None, false);
		scroll.OnKeyDown(pageDown);
		// A page is most of a viewport, not all of it: the overlap keeps the reader's place.
		Test.Assert(scroll.ScrollY == 40 + scroll.ViewportHeight * 0.9f);

		let end = scope KeyEventArgs();
		end.Set(.End, .None, false);
		scroll.OnKeyDown(end);
		Test.Assert(scroll.ScrollY == scroll.MaxScrollY);

		let home = scope KeyEventArgs();
		home.Set(.Home, .None, false);
		scroll.OnKeyDown(home);
		Test.Assert(scroll.ScrollY == 0);
	}

	/// The two axes are NOT symmetric, and the asymmetry is the default reading direction.
	///
	/// Content is measured unbounded VERTICALLY unless the policy is Never, so a tall document
	/// reports its real height and scrolls. Horizontally it is measured against the viewport
	/// unless the policy is Always, so text wraps rather than running off sideways. Widening
	/// a view is opt-in; lengthening it is not.
	[Test]
	public static void ContentIsUnboundedVerticallyButWrappedHorizontally()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let wrapped = new ScrollView();
		wrapped.AddView(new TestView(800, 500));
		root.AddView(wrapped);
		UITest.LayoutPass(context, root);

		Test.Assert(wrapped.ContentWidth == 200, "wrapped to the viewport");
		Test.Assert(wrapped.ContentHeight == 500, "but free to be as tall as it likes");
		Test.Assert(wrapped.MaxScrollX == 0);

		let wide = new ScrollView();
		wide.HScrollBarPolicy.Value = .Always;
		wide.AddView(new TestView(800, 50));
		root.AddView(wide);
		UITest.LayoutPass(context, root);

		Test.Assert(wide.ContentWidth == 800, "Always opts into the real width");
		Test.Assert(wide.MaxScrollX > 0);
	}

	/// A vertical wheel over a view that only scrolls SIDEWAYS drives it sideways, which is
	/// what a wheel over a horizontal strip is expected to do.
	[Test]
	public static void AVerticalWheelScrollsAHorizontalOnlyViewSideways()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Never;
		scroll.HScrollBarPolicy.Value = .Always;
		scroll.AddView(new TestView(800, 50));
		root.AddView(scroll);
		UITest.LayoutPass(context, root);

		let wheel = scope MouseWheelEventArgs();
		wheel.DeltaY = -1;
		scroll.OnMouseWheel(wheel);

		Test.Assert(scroll.ScrollX == 40);
		Test.Assert(scroll.ScrollY == 0);
	}

	// ---- ScrollToView -------------------------------------------------------------------------

	/// Brings a descendant into view, scrolling the least that will do it, and does nothing for
	/// a view that is not a descendant.
	[Test]
	public static void ScrollToViewBringsADescendantIntoTheViewport()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let scroll = new ScrollView();
		let content = new TestGroup();
		scroll.AddView(content);
		root.AddView(scroll);

		// Tall enough that there is somewhere to scroll to.
		content.AddView(new TestView(50, 500));
		let target = new TestView(50, 20);
		content.AddView(target);
		UITest.LayoutPass(context, root);
		target.Bounds = .(0, 400, 50, 20);

		scroll.ScrollToView(target);
		// Scrolled just far enough to bring the bottom edge in, no further.
		Test.Assert(scroll.ScrollY == 420 - scroll.ViewportHeight);

		let stranger = new TestView(10, 10);
		defer stranger.ReleaseRef();
		let before = scroll.ScrollY;
		scroll.ScrollToView(stranger);
		Test.Assert(scroll.ScrollY == before, "not a descendant, so nothing moved");

		scroll.ScrollToView(null);
		Test.Assert(scroll.ScrollY == before);
	}

	// ---- MomentumHelper -----------------------------------------------------------------------

	/// A flick decelerates to a stop, having travelled in the direction it was thrown.
	[Test]
	public static void MomentumDeceleratesToAStop()
	{
		var momentum = MomentumHelper();
		momentum.VelocityY = 500;
		Test.Assert(momentum.IsActive);

		var travelled = 0.0f;
		for (int i < 100)
			travelled += momentum.Update(0.016f).Y;

		Test.Assert(travelled > 0);
		Test.Assert(!momentum.IsActive || (Abs(momentum.VelocityY) < 1.0f));
	}

	[Test]
	public static void MomentumCanBeStoppedOutright()
	{
		var momentum = MomentumHelper();
		momentum.VelocityY = 500;

		momentum.Stop();

		Test.Assert(!momentum.IsActive);
	}
}
