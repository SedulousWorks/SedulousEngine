using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// Style model v2 P4: flex line wrapping with align content, gaps on both axes by both naming
/// schemes, and flex basis as the starting main size.
class FlexWrapTests
{
	private static bool Near(float a, float b, float epsilon = 0.03f) => Abs(a - b) <= epsilon;

	/// For values that do not land on the pixel grid.
	///
	/// Layout SNAPS bounds to whole device pixels, so a line at 36.67 arrives as 37 and an
	/// expectation written as the exact fraction is right about the intent and wrong by up to
	/// half a pixel about the result. A relative epsilon hides this; saying half a pixel says
	/// what is actually being allowed.
	private static bool NearSnapped(float a, float b) => Abs(a - b) <= 0.5f;

	/// A flex of a FIXED size, hosted inside a frame.
	///
	/// The host matters: added straight to the root the flex would be stretched to the whole
	/// viewport, and there would be nothing to wrap against.
	private class FlexFixture
	{
		public UIContext Context = new .() ~ delete _;
		public RootView Root = new .() ~ _.ReleaseRef();
		public FrameLayout Host = new .();
		public FlexLayout Flex = new .();

		public this(float width, float height, bool wrap = true,
			Orientation direction = .Horizontal)
		{
			UITest.Init(Context, Root, 800, 600);
			var size = LayoutStyle();
			size.Width = .(SizeSpec.Fixed(Unit.Dp(width)), true);
			size.Height = .(SizeSpec.Fixed(Unit.Dp(height)), true);
			Flex.SetLayout(size);
			Flex.Wrap = wrap;
			Flex.Direction = direction;
			Host.AddView(Flex);
			Root.AddView(Host);
		}

		public void Pass() => UITest.LayoutPass(Context, Root);
	}

	// ---- Wrapping ---------------------------------------------------------------------------

	[Test]
	public static void ItemsBreakIntoLinesAgainstTheMainSize()
	{
		let fixture = scope FlexFixture(250, 300);
		fixture.Flex.AlignContent = .Start;

		let items = scope TestView[5];
		for (int i < 5)
		{
			items[i] = new TestView(100, 30);
			fixture.Flex.AddView(items[i]);
		}
		fixture.Pass();

		// Two hundreds fit in two hundred and fifty, so the lines are [a b] [c d] [e].
		Test.Assert(Near(items[0].Bounds.X, 0));
		Test.Assert(Near(items[1].Bounds.X, 100));
		Test.Assert(Near(items[1].Bounds.Y, 0));
		Test.Assert(Near(items[2].Bounds.X, 0));
		Test.Assert(Near(items[2].Bounds.Y, 30));
		Test.Assert(Near(items[3].Bounds.Y, 30));
		Test.Assert(Near(items[4].Bounds.X, 0));
		Test.Assert(Near(items[4].Bounds.Y, 60));

		// WITHOUT wrap the same items run straight past the edge on one line.
		fixture.Flex.Wrap = false;
		fixture.Flex.Invalidate();
		fixture.Pass();

		Test.Assert(Near(items[4].Bounds.X, 400));
		Test.Assert(Near(items[4].Bounds.Y, 0));
	}

	/// A wrapping container MEASURES to its stacked lines, so a wrapping height is right rather
	/// than one line tall.
	[Test]
	public static void AWrappingContainerMeasuresItsStackedLines()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 800, 600);

		let host = new FrameLayout();
		let flex = new FlexLayout();
		flex.Wrap = true;
		flex.LineSpacing = 10;
		flex.Spacing = 5;
		var width = LayoutStyle();
		// Width only: the HEIGHT is what is being measured.
		width.Width = .(SizeSpec.Fixed(Unit.Dp(250)), true);
		flex.SetLayout(width);

		let items = scope TestView[5];
		for (int i < 5)
		{
			items[i] = new TestView(100, 30);
			flex.AddView(items[i]);
		}
		host.AddView(flex);
		root.AddView(host);
		UITest.LayoutPass(context, root);

		// A hundred, five of gap and a hundred is two hundred and five, which fits; a third
		// would be three hundred and ten, which does not. Three lines and two gaps.
		Test.Assert(Near(flex.Bounds.Height, 30 + 10 + 30 + 10 + 30));
		Test.Assert(Near(items[1].Bounds.X, 105));
		Test.Assert(Near(items[2].Bounds.Y, 40));
		Test.Assert(Near(items[4].Bounds.Y, 80));
	}

	[Test]
	public static void AVerticalFlexWrapsIntoColumns()
	{
		let fixture = scope FlexFixture(300, 100, true, .Vertical);
		fixture.Flex.AlignContent = .Start;

		let items = scope TestView[4];
		for (int i < 4)
		{
			items[i] = new TestView(50, 30);
			fixture.Flex.AddView(items[i]);
		}
		fixture.Pass();

		// A hundred tall takes three thirties, so the fourth starts a second column.
		Test.Assert(Near(items[2].Bounds.Y, 60));
		Test.Assert(Near(items[3].Bounds.X, 50));
		Test.Assert(Near(items[3].Bounds.Y, 0));
	}

	// ---- Align content ----------------------------------------------------------------------
	// Two hundred tall holding three lines of thirty, so there is a hundred and ten free.

	private static void BuildFiveItems(FlexFixture fixture, TestView[] items)
	{
		for (int i < items.Count)
		{
			items[i] = new TestView(100, 30);
			fixture.Flex.AddView(items[i]);
		}
	}

	[Test]
	public static void AlignContentStartPacksTheLinesAtTheTop()
	{
		let fixture = scope FlexFixture(250, 200);
		fixture.Flex.AlignContent = .Start;
		let items = scope TestView[5];
		BuildFiveItems(fixture, items);
		fixture.Pass();

		Test.Assert(Near(items[0].Bounds.Y, 0));
		Test.Assert(Near(items[4].Bounds.Y, 60));
		Test.Assert(Near(items[0].Bounds.Height, 30), "the lines keep their own size");
	}

	[Test]
	public static void AlignContentEndPacksTheLinesAtTheBottom()
	{
		let fixture = scope FlexFixture(250, 200);
		fixture.Flex.AlignContent = .End;
		let items = scope TestView[5];
		BuildFiveItems(fixture, items);
		fixture.Pass();

		Test.Assert(Near(items[0].Bounds.Y, 110));
		Test.Assert(Near(items[4].Bounds.Y, 170));
	}

	[Test]
	public static void AlignContentCentreCentresTheBlockOfLines()
	{
		let fixture = scope FlexFixture(250, 200);
		fixture.Flex.AlignContent = .Center;
		let items = scope TestView[5];
		BuildFiveItems(fixture, items);
		fixture.Pass();

		Test.Assert(Near(items[0].Bounds.Y, 55));
	}

	[Test]
	public static void AlignContentSpaceBetweenPushesTheLinesToTheEdges()
	{
		let fixture = scope FlexFixture(250, 200);
		fixture.Flex.AlignContent = .SpaceBetween;
		let items = scope TestView[5];
		BuildFiveItems(fixture, items);
		fixture.Pass();

		Test.Assert(Near(items[0].Bounds.Y, 0));
		Test.Assert(Near(items[2].Bounds.Y, 85));
		Test.Assert(Near(items[4].Bounds.Y, 170));
	}

	[Test]
	public static void AlignContentSpaceAroundHalvesTheEndGaps()
	{
		let fixture = scope FlexFixture(250, 200);
		fixture.Flex.AlignContent = .SpaceAround;
		let items = scope TestView[5];
		BuildFiveItems(fixture, items);
		fixture.Pass();

		// A hundred and ten over three lines is 36.67 around each, so half of that leads.
		Test.Assert(NearSnapped(items[0].Bounds.Y, 110.0f / 6.0f));
		Test.Assert(NearSnapped(items[2].Bounds.Y, 110.0f / 6.0f + 30 + 110.0f / 3.0f));
	}

	/// Stretch is the DEFAULT: the lines share out the free cross space, and an item whose own
	/// cross size is auto stretches with its line.
	[Test]
	public static void AlignContentStretchSharesTheFreeSpaceBetweenLines()
	{
		let fixture = scope FlexFixture(250, 200);
		Test.Assert(fixture.Flex.AlignContent == .Stretch, "the default");
		let items = scope TestView[5];
		BuildFiveItems(fixture, items);
		fixture.Pass();

		let lineCross = 30 + 110.0f / 3.0f;
		Test.Assert(NearSnapped(items[0].Bounds.Height, lineCross));
		Test.Assert(NearSnapped(items[2].Bounds.Y, lineCross));
		Test.Assert(NearSnapped(items[4].Bounds.Y, 2 * lineCross));
	}

	/// A single non wrapping line IS the container, so align content has nothing to pack and
	/// the item stretches across the whole cross axis, exactly as it did before wrapping existed.
	[Test]
	public static void ASingleLineWithoutWrapIgnoresAlignContent()
	{
		let fixture = scope FlexFixture(400, 200, false);
		fixture.Flex.AlignContent = .End;
		let a = new TestView(100, 30);
		fixture.Flex.AddView(a);
		fixture.Pass();

		Test.Assert(Near(a.Bounds.Y, 0));
		Test.Assert(Near(a.Bounds.Height, 200));
	}

	// ---- Gaps -------------------------------------------------------------------------------

	/// In a ROW, column gap is the gap between items and row gap the gap between lines. The
	/// names are by AXIS, not by role, which is why they swap when the direction does.
	[Test]
	public static void InARowColumnGapIsTheMainGap()
	{
		let fixture = scope FlexFixture(250, 300);
		fixture.Flex.AlignContent = .Start;
		fixture.Flex.ColumnGap = 20;
		fixture.Flex.RowGap = 7;
		let a = new TestView(100, 30);
		let b = new TestView(100, 30);
		let c = new TestView(100, 30);
		fixture.Flex.AddView(a);
		fixture.Flex.AddView(b);
		fixture.Flex.AddView(c);
		fixture.Pass();

		Test.Assert(Near(fixture.Flex.MainGap, 20));
		Test.Assert(Near(fixture.Flex.CrossGap, 7));
		Test.Assert(Near(b.Bounds.X, 120));
		Test.Assert(Near(c.Bounds.Y, 37));
	}

	[Test]
	public static void InAColumnRowGapIsTheMainGap()
	{
		let fixture = scope FlexFixture(300, 100, true, .Vertical);
		fixture.Flex.AlignContent = .Start;
		fixture.Flex.RowGap = 20;
		fixture.Flex.ColumnGap = 7;
		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		let c = new TestView(50, 30);
		fixture.Flex.AddView(a);
		fixture.Flex.AddView(b);
		// Thirty, twenty, thirty, twenty, thirty is a hundred and thirty against a hundred.
		fixture.Flex.AddView(c);
		fixture.Pass();

		Test.Assert(Near(b.Bounds.Y, 50));
		Test.Assert(Near(c.Bounds.X, 57));
		Test.Assert(Near(c.Bounds.Y, 0));
	}

	[Test]
	public static void WithoutAnAxisGapTheCodeSideNamesApply()
	{
		let fixture = scope FlexFixture(250, 300);
		fixture.Flex.Spacing = 10;
		fixture.Flex.LineSpacing = 4;

		Test.Assert(Near(fixture.Flex.MainGap, 10));
		Test.Assert(Near(fixture.Flex.CrossGap, 4));
	}

	// ---- Flex basis -------------------------------------------------------------------------

	/// The basis is the STARTING main size, which grow then adds to. A basis with no grow is
	/// the size outright, and the content size is ignored.
	[Test]
	public static void FlexBasisIsTheStartingMainSize()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 800, 600);

		let loader = scope StyleSheetLoader();
		context.SetStyleSheet(loader.Load(".half { flex-basis: 50%; }"));

		let host = new FrameLayout();
		let flex = new FlexLayout();
		var size = LayoutStyle();
		size.Width = .(SizeSpec.Fixed(Unit.Dp(300)), true);
		size.Height = .(SizeSpec.Fixed(Unit.Dp(50)), true);
		flex.SetLayout(size);

		// A basis of a hundred, plus its share of what is left.
		let grown = new TestView(50, 30);
		var grownLayout = LayoutStyle();
		grownLayout.FlexGrow = .(1, true);
		grownLayout.FlexBasis = .(Unit.Dp(100), true);
		flex.AddView(grown, grownLayout);

		// A basis of nought, plus its share: the `flex: 1` shorthand.
		let bare = new TestView(50, 30);
		var bareLayout = LayoutStyle();
		bareLayout.FlexGrow = .(1, true);
		flex.AddView(bare, bareLayout);

		host.AddView(flex);
		root.AddView(host);
		UITest.LayoutPass(context, root);

		// Two hundred is left over the basis, split one to one.
		Test.Assert(Near(grown.Bounds.Width, 200));
		Test.Assert(Near(bare.Bounds.Width, 100));
		Test.Assert(Near(bare.Bounds.X, 200));

		// A basis WITHOUT grow is the size, and a percentage from the sheet resolves against the
		// available main size.
		flex.RemoveView(grown);
		flex.RemoveView(bare);

		let fixedBasis = new TestView(50, 30);
		var fixedLayout = LayoutStyle();
		fixedLayout.FlexBasis = .(Unit.Dp(120), true);
		flex.AddView(fixedBasis, fixedLayout);

		let half = new TestView(50, 30);
		half.AddClass("half");
		flex.AddView(half);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(fixedBasis.Bounds.Width, 120));
		Test.Assert(Near(half.Bounds.Width, 150));
		Test.Assert(Near(half.Layout.FlexBasis.Value.percent, 50), "it came from the sheet");
	}
}
