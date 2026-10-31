using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// DockLayout, where each child claims an edge and shrinks what is left, and GridLayout, with
/// its fixed, auto and flex tracks.
class DockAndGridLayoutTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	private static LayoutStyle Docked(Dock dock)
	{
		var layout = LayoutStyle();
		layout.Dock = dock;
		return layout;
	}

	private static LayoutStyle Cell(int32 row, int32 column, int32 rowSpan = 1,
		int32 columnSpan = 1)
	{
		var layout = LayoutStyle();
		layout.GridRow = row;
		layout.GridColumn = column;
		layout.GridRowSpan = rowSpan;
		layout.GridColumnSpan = columnSpan;
		return layout;
	}

	// ---- DockLayout -------------------------------------------------------------------------

	/// A styled border is part of what the dock MEASURES to, not just the padding.
	///
	/// The measure deflates by the whole chrome, so the whole chrome has to come back: adding
	/// only the padding left a bordered dock short by its border.
	[Test]
	public static void AStyledBorderCountsTowardTheMeasuredSize()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		// A frame gives the dock LOOSE constraints, so it wraps its content rather than
		// being stretched to the root and hiding the difference.
		let host = new FrameLayout();
		let dock = new DockLayout();
		dock.SetStyle(.BorderWidth, 5.0f);
		dock.Padding = Thickness(2, 2, 2, 2);

		let top = new TestView(100, 50);
		dock.AddView(top, Docked(.Top));
		host.AddView(dock);
		root.AddView(host);
		UITest.LayoutPass(context, root);

		// A top docked child spans the dock rather than sizing it, so only the height is its.
		Test.Assert(Near(dock.MeasuredSize.Y, 50 + 2 * (5 + 2)), "border and padding both");
		Test.Assert(Near(top.Bounds.X, 7), "inset by the border plus the padding");
		Test.Assert(Near(top.Bounds.Y, 7));
	}

	/// A top docked child takes the full WIDTH and only the height it measured to.
	[Test]
	public static void ATopDockedChildSpansTheWidth()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let dock = new DockLayout();
		let top = new TestView(400, 50);
		dock.AddView(top, Docked(.Top));
		root.AddView(dock);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(top.Bounds.X, 0));
		Test.Assert(Near(top.Bounds.Y, 0));
		Test.Assert(Near(top.Width, 400));
		Test.Assert(Near(top.Height, 50));
	}

	[Test]
	public static void ABottomDockedChildSitsAgainstTheBottom()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let dock = new DockLayout();
		let bottom = new TestView(400, 40);
		dock.AddView(bottom, Docked(.Bottom));
		root.AddView(dock);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(bottom.Bounds.Y, 260));
		Test.Assert(Near(bottom.Width, 400));
	}

	[Test]
	public static void ALeftDockedChildSpansTheHeight()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let dock = new DockLayout();
		let left = new TestView(80, 300);
		dock.AddView(left, Docked(.Left));
		root.AddView(dock);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(left.Bounds.X, 0));
		Test.Assert(Near(left.Width, 80));
		Test.Assert(Near(left.Height, 300));
	}

	[Test]
	public static void ARightDockedChildSitsAgainstTheRight()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let dock = new DockLayout();
		let right = new TestView(60, 300);
		dock.AddView(right, Docked(.Right));
		root.AddView(dock);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(right.Bounds.X, 340));
		Test.Assert(Near(right.Width, 60));
	}

	[Test]
	public static void AFillChildTakesWhatTheEdgesLeft()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let dock = new DockLayout();
		let top = new TestView(400, 50);
		let fill = new TestView(50, 30);
		dock.AddView(top, Docked(.Top));
		dock.AddView(fill, Docked(.Fill));
		root.AddView(dock);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(fill.Bounds.Y, 50));
		Test.Assert(Near(fill.Width, 400));
		Test.Assert(Near(fill.Height, 250));
	}

	[Test]
	public static void WithoutLastChildFillTheLastChildKeepsItsSize()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let dock = new DockLayout();
		dock.LastChildFill = false;
		let top = new TestView(400, 50);
		let last = new TestView(100, 40);
		dock.AddView(top, Docked(.Top));
		dock.AddView(last, Docked(.Left));
		root.AddView(dock);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(last.Width, 100));
	}

	/// LastChildFill OVERRIDES the child's own Dock, which is what makes the usual window shape
	/// work without having to remember to say Fill.
	[Test]
	public static void LastChildFillOverridesTheLastChildsDock()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let dock = new DockLayout();
		dock.LastChildFill = true;
		let top = new TestView(400, 50);
		let last = new TestView(100, 40);
		dock.AddView(top, Docked(.Top));
		dock.AddView(last, Docked(.Left));
		root.AddView(dock);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(last.Width, 400));
		Test.Assert(Near(last.Height, 250));
	}

	/// Each docked child shrinks the frame for the ones after it, which is why ORDER matters
	/// here in a way it does not in a frame or a flex.
	[Test]
	public static void EachDockedChildShrinksWhatIsLeft()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let dock = new DockLayout();
		let top = new TestView(400, 40);
		let left = new TestView(60, 260);
		let fill = new TestView(50, 30);
		dock.AddView(top, Docked(.Top));
		dock.AddView(left, Docked(.Left));
		dock.AddView(fill, Docked(.Fill));
		root.AddView(dock);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(fill.Bounds.X, 60));
		Test.Assert(Near(fill.Bounds.Y, 40));
		Test.Assert(Near(fill.Width, 340));
		Test.Assert(Near(fill.Height, 260));
	}

	// ---- GridLayout -------------------------------------------------------------------------

	[Test]
	public static void FixedColumnsTakeExactlyTheirWidths()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(TrackSize.Fixed(100));
		grid.Columns.Add(TrackSize.Fixed(200));
		grid.Rows.Add(TrackSize.Fixed(50));
		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		grid.AddView(a, Cell(0, 0));
		grid.AddView(b, Cell(0, 1));
		root.AddView(grid);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Width, 100));
		Test.Assert(Near(b.Width, 200));
		Test.Assert(Near(b.Bounds.X, 100));
	}

	/// Flex tracks share the space in proportion to their WEIGHTS, so one and three split four
	/// hundred into a hundred and three hundred.
	[Test]
	public static void FlexColumnsSplitTheSpaceByWeight()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(TrackSize.Flex(1));
		grid.Columns.Add(TrackSize.Flex(3));
		grid.Rows.Add(TrackSize.Flex(1));
		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		grid.AddView(a, Cell(0, 0));
		grid.AddView(b, Cell(0, 1));
		root.AddView(grid);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Width, 100));
		Test.Assert(Near(b.Width, 300));
	}

	[Test]
	public static void AutoColumnsSizeToTheirContent()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(TrackSize.Auto());
		grid.Columns.Add(TrackSize.Auto());
		grid.Rows.Add(TrackSize.Auto());
		let a = new TestView(80, 30);
		let b = new TestView(120, 40);
		grid.AddView(a, Cell(0, 0));
		grid.AddView(b, Cell(0, 1));
		root.AddView(grid);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Width, 80));
		Test.Assert(Near(b.Width, 120));
	}

	[Test]
	public static void ColumnSpacingSitsBetweenTheCells()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(TrackSize.Fixed(100));
		grid.Columns.Add(TrackSize.Fixed(100));
		grid.Rows.Add(TrackSize.Fixed(50));
		grid.ColumnSpacing = 10;
		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		grid.AddView(a, Cell(0, 0));
		grid.AddView(b, Cell(0, 1));
		root.AddView(grid);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(b.Bounds.X, 110));
	}

	[Test]
	public static void AutoFlowFillsTheCellsInOrder()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let grid = new GridLayout();
		grid.AutoFlow = true;
		grid.Columns.Add(TrackSize.Flex(1));
		grid.Columns.Add(TrackSize.Flex(1));
		grid.Rows.Add(TrackSize.Flex(1));
		grid.Rows.Add(TrackSize.Flex(1));
		let a = new TestView(50, 30);
		let b = new TestView(50, 30);
		let c = new TestView(50, 30);
		let d = new TestView(50, 30);
		grid.AddView(a);
		grid.AddView(b);
		grid.AddView(c);
		grid.AddView(d);
		root.AddView(grid);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Bounds.X, 0));
		Test.Assert(Near(b.Bounds.X, 200));
		Test.Assert(Near(c.Bounds.Y, 150), "wrapped to the second row");
		Test.Assert(Near(d.Bounds.X, 200));
		Test.Assert(Near(d.Bounds.Y, 150));
	}

	/// A span swallows the GAPS between the tracks it covers as well as the tracks themselves.
	[Test]
	public static void AColumnSpanMergesItsCellsAndTheGapBetween()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(TrackSize.Fixed(100));
		grid.Columns.Add(TrackSize.Fixed(100));
		grid.Columns.Add(TrackSize.Fixed(100));
		grid.Rows.Add(TrackSize.Fixed(50));
		grid.ColumnSpacing = 5;
		let a = new TestView(50, 30);
		grid.AddView(a, Cell(0, 0, 1, 2));
		root.AddView(grid);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Width, 205), "two hundred of track plus the five between");
	}

	[Test]
	public static void ARowSpanMergesItsCellsAndTheGapBetween()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(TrackSize.Fixed(100));
		grid.Rows.Add(TrackSize.Fixed(50));
		grid.Rows.Add(TrackSize.Fixed(60));
		grid.RowSpacing = 4;
		let a = new TestView(50, 30);
		grid.AddView(a, Cell(0, 0, 2, 1));
		root.AddView(grid);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Height, 114), "fifty and sixty plus the four between");
	}

	/// Flex takes what is left AFTER the fixed and auto tracks have taken theirs.
	[Test]
	public static void FlexTakesWhatTheFixedAndAutoTracksLeft()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(TrackSize.Fixed(80));
		grid.Columns.Add(TrackSize.Auto());
		grid.Columns.Add(TrackSize.Flex(1));
		grid.Rows.Add(TrackSize.Flex(1));
		let a = new TestView(80, 30);
		let b = new TestView(60, 30);
		let c = new TestView(50, 30);
		grid.AddView(a, Cell(0, 0));
		grid.AddView(b, Cell(0, 1));
		grid.AddView(c, Cell(0, 2));
		root.AddView(grid);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(a.Width, 80));
		Test.Assert(Near(b.Width, 60));
		Test.Assert(Near(c.Width, 260));
	}

	/// Auto flow assigns cells PER PASS and never writes the placement back to the child, so the
	/// child's -1 intent survives and removing a sibling re-flows the rest.
	[Test]
	public static void AutoFlowKeepsTheChildsIntentAndReflowsOnChange()
	{
		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		UITest.Init(context, root, 400, 300);

		let grid = new GridLayout();
		grid.Columns.Add(TrackSize.Fixed(100));
		grid.Columns.Add(TrackSize.Fixed(100));
		grid.Rows.Add(TrackSize.Fixed(50));
		grid.Rows.Add(TrackSize.Fixed(50));
		grid.AutoFlow = true;
		let a = new TestView(10, 10);
		let b = new TestView(10, 10);
		let c = new TestView(10, 10);
		grid.AddView(a);
		grid.AddView(b);
		grid.AddView(c);
		root.AddView(grid);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(c.Bounds.X, 0));
		Test.Assert(Near(c.Bounds.Y, 50));
		Test.Assert(c.Layout.GridRow == -1, "the intent was not overwritten");
		Test.Assert(c.Layout.GridColumn == -1);

		grid.RemoveView(a);
		UITest.LayoutPass(context, root);

		Test.Assert(Near(c.Bounds.X, 100), "re-flowed into the second cell");
		Test.Assert(Near(c.Bounds.Y, 0));
	}
}
