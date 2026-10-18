using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// FlexLayout: direction, spacing, grow distribution, justification and cross axis alignment.
class FlexLayoutTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	private static LayoutStyle Growth(float grow)
	{
		var layout = LayoutStyle();
		layout.FlexGrow = .(grow, true);
		return layout;
	}

	[Test]
	public static void ARowArrangesItsChildrenLeftToRight()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		flex.AddView(a);
		flex.AddView(b);
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(a.Bounds.X < b.Bounds.X);
		Test.Assert(Near(b.Bounds.X, 50));
	}

	[Test]
	public static void AColumnArrangesItsChildrenTopToBottom()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Vertical;
		let a = new TestView(50, 30);
		let b = new TestView(50, 40);
		flex.AddView(a);
		flex.AddView(b);
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(a.Bounds.Y < b.Bounds.Y);
		Test.Assert(Near(b.Bounds.Y, 30));
	}

	[Test]
	public static void SpacingSeparatesRowItems()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		flex.Spacing = 10;
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		flex.AddView(a);
		flex.AddView(b);
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(b.Bounds.X, 60));
	}

	[Test]
	public static void SpacingSeparatesColumnItems()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Vertical;
		flex.Spacing = 8;
		let a = new TestView(50, 30);
		let b = new TestView(50, 40);
		flex.AddView(a);
		flex.AddView(b);
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(b.Bounds.Y, 38));
	}

	/// Equal weights split the WHOLE main axis, not just the leftover: a growing child's basis
	/// is nought, which is what `flex: 1` means.
	[Test]
	public static void EqualGrowSplitsTheAxisEvenly()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		flex.AddView(a, Growth(1));
		flex.AddView(b, Growth(1));
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Width, 200));
		Test.Assert(Near(b.Width, 200));
	}

	[Test]
	public static void GrowIsSharedInProportionToWeight()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		let a = new TestView(0, 30);
		let b = new TestView(0, 30);
		flex.AddView(a, Growth(1));
		flex.AddView(b, Growth(3));
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Width, 100));
		Test.Assert(Near(b.Width, 300));
	}

	/// A non growing child keeps its measured size, and grow shares out what is LEFT.
	[Test]
	public static void AFixedChildKeepsItsSizeWhileTheFlexibleOneTakesTheRest()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		let fixedChild = new TestView(100, 30);
		let flexibleChild = new TestView(0, 30);
		flex.AddView(fixedChild);
		flex.AddView(flexibleChild, Growth(1));
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(fixedChild.Width, 100));
		Test.Assert(Near(flexibleChild.Width, 300));
	}

	[Test]
	public static void GrowWorksDownAColumnToo()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Vertical;
		let a = new TestView(50, 0);
		let b = new TestView(50, 0);
		flex.AddView(a, Growth(1));
		flex.AddView(b, Growth(1));
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Height, 150));
		Test.Assert(Near(b.Height, 150));
	}

	// ---- Justification ----------------------------------------------------------------------

	[Test]
	public static void JustifyEndPushesToTheFarEdge()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		flex.JustifyContent = .End;
		let a = new TestView(50, 30);
		flex.AddView(a);
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.X, 350));
	}

	[Test]
	public static void JustifyCentreSplitsTheFreeSpace()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		flex.JustifyContent = .Center;
		let a = new TestView(100, 30);
		flex.AddView(a);
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.X, 150));
	}

	/// Space between puts the whole free space BETWEEN the items, so the ends stay flush.
	[Test]
	public static void JustifySpaceBetweenKeepsTheEndsFlush()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		flex.JustifyContent = .SpaceBetween;
		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		flex.AddView(a);
		flex.AddView(b);
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.X, 0));
		Test.Assert(Near(b.Bounds.X, 350));
	}

	/// Space evenly makes every gap equal, the two END gaps included, which is what separates
	/// it from space around.
	[Test]
	public static void JustifySpaceEvenlyMakesEveryGapEqual()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		flex.JustifyContent = .SpaceEvenly;
		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		flex.AddView(a);
		flex.AddView(b);
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.X, 100));
		Test.Assert(Near(b.Bounds.X, 250));
	}

	// ---- Cross axis alignment ---------------------------------------------------------------

	[Test]
	public static void AlignStretchFillsTheCrossAxis()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		flex.AlignItems = .Stretch;
		let a = new TestView(50, 30);
		flex.AddView(a);
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Height, 300));
	}

	[Test]
	public static void AlignCentreCentresOnTheCrossAxis()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		flex.AlignItems = .Center;
		let a = new TestView(50, 30);
		flex.AddView(a);
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.Y, 135));
	}

	[Test]
	public static void AlignEndSitsAgainstTheFarCrossEdge()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		flex.AlignItems = .End;
		let a = new TestView(50, 30);
		flex.AddView(a);
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.Y, 270));
	}

	[Test]
	public static void AGoneChildIsSkippedByTheFlex()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		let a = new TestView(50, 30);
		let b = new TestView(60, 30);
		b.Visibility = .Gone;
		let c = new TestView(70, 30);
		flex.AddView(a);
		flex.AddView(b);
		flex.AddView(c);
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(c.Bounds.X, 50));
	}

	[Test]
	public static void FlexPaddingOffsetsTheChildren()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		flex.Padding = .(10, 20, 10, 20);
		let a = new TestView(50, 30);
		flex.AddView(a);
		root.AddView(flex);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.X, 10));
		Test.Assert(a.Bounds.Y >= 20);
	}

	private static LayoutStyle Shrink(float shrink)
	{
		var layout = LayoutStyle();
		layout.FlexShrink = .(shrink, true);
		return layout;
	}

	/// A 200 x 50 row holding two 150 wide children, 100 too many, laid out; the widths of
	/// both and b's x.
	private static (float a, float b, float bX) OverfullRow(LayoutStyle styleA, LayoutStyle styleB)
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		let a = new TestView(150, 30);
		let b = new TestView(150, 30);
		flex.AddView(a, styleA);
		flex.AddView(b, styleB);
		var rowSize = LayoutStyle();
		rowSize.Width = .(SizeSpec.Fixed(Unit.Px(200)), true);
		rowSize.Height = .(SizeSpec.Fixed(Unit.Px(50)), true);
		root.AddView(flex, rowSize);
		UITest.LayoutPass(context, root);
		return (a.Width, b.Width, b.Bounds.X);
	}

	/// An overflowing line takes the excess from its shrinkable children in proportion to
	/// shrink times base size; an undeclared flex-shrink is nought, so nothing shrinks.
	[Test]
	public static void ShrinkSharesTheOverflowByShrinkTimesBase()
	{
		let even = OverfullRow(Shrink(1), Shrink(1));
		Test.Assert(Near(even.a, 100) && Near(even.b, 100), scope $"{even.a} {even.b}");
		Test.Assert(Near(even.bX, 100));

		let weighted = OverfullRow(Shrink(3), Shrink(1)); // a gives three parts of four
		Test.Assert(Near(weighted.a, 75) && Near(weighted.b, 125), scope $"{weighted.a} {weighted.b}");

		let one = OverfullRow(Shrink(1), LayoutStyle()); // undeclared: does not shrink
		Test.Assert(Near(one.a, 50) && Near(one.b, 150), scope $"{one.a} {one.b}");

		let none = OverfullRow(LayoutStyle(), LayoutStyle()); // the row overflows as before
		Test.Assert(Near(none.a, 150) && Near(none.b, 150), scope $"{none.a} {none.b}");
	}

	/// A child that cannot go below its minimum freezes there, and the others give the rest.
	[Test]
	public static void ShrinkStopsAtTheMinimumAndTheRestGiveMore()
	{
		var floor = Shrink(1);
		floor.MinWidth = .(Unit.Px(120), true);
		let row = OverfullRow(floor, Shrink(1));
		Test.Assert(Near(row.a, 120), scope $"{row.a}: its share would take it to 100");
		Test.Assert(Near(row.b, 80), scope $"{row.b}");
	}
}
