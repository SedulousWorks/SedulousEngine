using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Measure and arrange: a node asks for a size within constraints and its container places it;
/// the display kinds (flex by CSS's rules, grid, stack, dock) and the out-of-flow children; sizes
/// in lengths, percentages and auto, min and max, the box sizing; visibility against display; and
/// what a change lays out again.
class LayoutEngineTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A panel styled by `style`, the last child of `parent`, which holds it: it comes back
	/// borrowed.
	private static Panel PanelBox(Node parent, delegate void(LayoutStyle style) style)
	{
		let panel = new Panel();
		panel.EditLayoutStyle(style);
		parent.AddChild(panel);
		panel.ReleaseRef(); // the tree's reference keeps it
		return panel;
	}

	/// A panel `w` by `h` pixels, the last child of `parent` (borrowed).
	private static Panel PanelFixed(Node parent, float w, float h) => PanelBox(parent, scope (s) =>
		{
			s.Width = LayoutLength.Px(w);
			s.Height = LayoutLength.Px(h);
		});

	/// A leaf that counts how often layout asks what it holds.
	private class CountingLeaf : Node
	{
		public int Measures = 0;

		public override Float2 MeasureContent(Float2 available)
		{
			Measures++;
			return .(50.0f, 20.0f);
		}
	}

	[Test]
	public static void APlainContainerIsAFlexColumnItsChildrenStackAndStretchAcross()
	{
		let bed = scope Bed();
		let page = NodeFixtures.Box(bed.Root);
		page.Padding = Thickness(10.0f);
		let a = NodeFixtures.Box(page, scope (s) => { s.Height = LayoutLength.Px(30.0f); });
		let b = NodeFixtures.Box(page, scope (s) => { s.Height = LayoutLength.Px(50.0f); });
		bed.Layout();
		NodeFixtures.CheckRect(page, 0, 0, 400, 100); // stretched across the root; as tall as what it holds
		NodeFixtures.CheckRect(a, 10, 10, 380, 30);
		NodeFixtures.CheckRect(b, 10, 40, 380, 50);
	}

	[Test]
	public static void AnAutoSizedContainerIsAsBigAsItsChildrenAndItsChrome()
	{
		let bed = scope Bed();
		let holder = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Placement = .Absolute; // out of flow: sized by its content, not stretched
				s.Direction = .Row;
				s.ColumnGap = 5.0f;
			});
		holder.Padding = Thickness(4.0f);
		NodeFixtures.Fixed(holder, 40.0f, 20.0f);
		NodeFixtures.Fixed(holder, 60.0f, 30.0f);
		bed.Layout();
		Test.Assert(Near(holder.Size.X, 4 + 40 + 5 + 60 + 4));
		Test.Assert(Near(holder.Size.Y, 4 + 30 + 4));
	}

	/// The x of a and b, then their y, in a 100-high row justified and aligned so.
	private static float[4] Row(Justify justify, Align align)
	{
		let bed = scope Bed();
		let line = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Height = LayoutLength.Px(100.0f);
				s.Direction = .Row;
				s.JustifyContent = justify;
				s.AlignItems = align;
			});
		let a = NodeFixtures.Fixed(line, 100.0f, 20.0f);
		let b = NodeFixtures.Fixed(line, 100.0f, 40.0f);
		bed.Layout();
		return .(a.Position.X, b.Position.X, a.Position.Y, b.Position.Y);
	}

	[Test]
	public static void FlexRowsJustifyAndAlignTheirItems()
	{
		let start = Row(.Start, .Start);
		Test.Assert(Near(start[0], 0.0f));
		Test.Assert(Near(start[1], 100.0f));
		let between = Row(.SpaceBetween, .Center);
		Test.Assert(Near(between[1], 300.0f));
		Test.Assert(Near(between[2], 40.0f)); // (100 - 20) / 2
		Test.Assert(Near(between[3], 30.0f));
		let end = Row(.End, .End);
		Test.Assert(Near(end[0], 200.0f));
		Test.Assert(Near(end[2], 80.0f));
		let evenly = Row(.SpaceEvenly, .Start);
		Test.Assert(Near(evenly[0], 67.0f)); // a third of 200, on the pixel grid
		let center = Row(.Center, .Start);
		Test.Assert(Near(center[0], 100.0f));
	}

	[Test]
	public static void GrowSharesFreeSpaceShrinkTakesAnOverflowStoppingAtAMinimum()
	{
		let bed = scope Bed();
		let line = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Height = LayoutLength.Px(40.0f);
				s.Direction = .Row;
			});
		let a = NodeFixtures.Box(line, scope (s) =>
			{
				s.Width = LayoutLength.Px(100.0f);
				s.Grow = 1.0f;
			});
		let b = NodeFixtures.Box(line, scope (s) =>
			{
				s.Width = LayoutLength.Px(100.0f);
				s.Grow = 3.0f;
			});
		bed.Layout();
		Test.Assert(Near(a.Size.X, 150.0f)); // 200 free: a quarter
		Test.Assert(Near(b.Size.X, 250.0f));

		a.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(300.0f);
				s.Grow = 0.0f;
				s.MinWidth = LayoutLength.Px(280.0f);
			});
		b.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(300.0f);
				s.Grow = 0.0f;
			});
		bed.Layout();
		Test.Assert(Near(a.Size.X, 280.0f)); // its share would take it to 200
		Test.Assert(Near(b.Size.X, 120.0f));
		b.EditLayoutStyle(scope (s) => { s.Shrink = 0.0f; });
		bed.Layout();
		Test.Assert(Near(b.Size.X, 300.0f)); // does not shrink: the line overflows
	}

	[Test]
	public static void AWidthOfItsOwnHoldsWithNoRoomAnItemShrinksNoNarrowerThanAFixedChild()
	{
		// Measured with no room (its min-content), a node with a width keeps it: the room limits an
		// auto size, not one its style gives, unless the container fixes the size exactly.
		let lone = new Node();
		defer lone.ReleaseRef();
		lone.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(120.0f); });
		var none = LayoutConstraints();
		none.Min = .(0.0f, 0.0f);
		none.Max = .(0.0f, cUnbounded);
		Test.Assert(Near(lone.Measure(none).X, 120.0f));
		Test.Assert(Near(lone.Measure(LayoutConstraints.Tight(.(50.0f, 20.0f), .(-1.0f, -1.0f))).X, 50.0f));

		let bed = scope Bed();
		let line = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Height = LayoutLength.Px(40.0f);
				s.Direction = .Row;
			});
		let a = NodeFixtures.Box(line); // auto width: its content's
		NodeFixtures.Fixed(a, 150.0f, 20.0f);
		let b = NodeFixtures.Box(line, scope (s) => { s.Width = LayoutLength.Px(400.0f); });
		bed.Layout();
		Test.Assert(Near(a.Size.X, 150.0f)); // its automatic minimum: the fixed child
		Test.Assert(Near(b.Size.X, 250.0f)); // the overflow all b's
	}

	[Test]
	public static void FlexWrapsIntoLinesReverseAndOrderChangeTheSequence()
	{
		let bed = scope Bed();
		let flow = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Direction = .Row;
				s.Wrap = .Wrap;
				s.ColumnGap = 10.0f;
				s.RowGap = 10.0f;
				s.AlignContent = .Start;
			});
		let cells = scope List<Node>();
		for (int i = 0; i < 5; i++)
			cells.Add(NodeFixtures.Fixed(flow, 120.0f, 30.0f));
		bed.Layout();
		NodeFixtures.CheckRect(cells[2], 260, 0, 120, 30); // three fit in 400 with the gaps
		NodeFixtures.CheckRect(cells[3], 0, 40, 120, 30);

		let second = scope Bed();
		let row = NodeFixtures.Box(second.Root, scope (s) =>
			{
				s.Direction = .RowReverse;
				s.Height = LayoutLength.Px(30.0f);
			});
		let first = NodeFixtures.Fixed(row, 50.0f, 30.0f);
		let last = NodeFixtures.Fixed(row, 50.0f, 30.0f);
		second.Layout();
		Test.Assert(Near(first.Position.X, 350.0f));
		Test.Assert(Near(last.Position.X, 300.0f));
		first.EditLayoutStyle(scope (s) => { s.Order = 1; }); // after the other, so first from the end... last
		second.Layout();
		Test.Assert(Near(first.Position.X, 300.0f));
	}

	[Test]
	public static void MarginsPercentagesMinAndMaxAndTheBoxSizing()
	{
		let bed = scope Bed();
		let page = NodeFixtures.Box(bed.Root, scope (s) => { s.AlignItems = .Start; });
		let half = NodeFixtures.Box(page, scope (s) =>
			{
				s.Width = LayoutLength.Percent(50.0f);
				s.Height = LayoutLength.Px(20.0f);
				s.Margin = Thickness(5.0f, 6.0f, 0.0f, 4.0f);
			});
		let capped = NodeFixtures.Box(page, scope (s) =>
			{
				s.Width = LayoutLength.Percent(100.0f);
				s.MaxWidth = LayoutLength.Px(150.0f);
				s.Height = LayoutLength.Px(10.0f);
			});
		let content = NodeFixtures.Box(page, scope (s) =>
			{
				s.Width = LayoutLength.Px(100.0f);
				s.Height = LayoutLength.Px(10.0f);
				s.Sizing = .ContentBox;
			});
		content.Padding = Thickness(10.0f);
		bed.Layout();
		NodeFixtures.CheckRect(half, 5, 6, 200, 20);
		Test.Assert(Near(capped.Position.Y, 6 + 20 + 4));
		Test.Assert(Near(capped.Size.X, 150.0f));
		Test.Assert(Near(content.Size.X, 120.0f)); // its width is the content's: padding outside
		Test.Assert(Near(content.Size.Y, 30.0f));
	}

	[Test]
	public static void GridTracksOfLengthsFrAndAutoItemsFlowSpanAndSitWhereTold()
	{
		let bed = scope Bed();
		let grid = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Kind = .Grid;
				s.Columns.Add(GridTrack.Fixed(100.0f));
				s.Columns.Add(GridTrack.Flex(1.0f));
				s.Columns.Add(GridTrack.Flex(2.0f));
				s.ColumnGap = 10.0f;
				s.RowGap = 5.0f;
				s.AlignItems = .Start;
			});
		let a = NodeFixtures.Box(grid, scope (s) => { s.Height = LayoutLength.Px(20.0f); });
		let b = NodeFixtures.Box(grid, scope (s) => { s.Height = LayoutLength.Px(30.0f); });
		let c = NodeFixtures.Box(grid, scope (s) => { s.Height = LayoutLength.Px(20.0f); });
		let wide = NodeFixtures.Box(grid, scope (s) =>
			{
				s.Height = LayoutLength.Px(10.0f);
				s.Column.Span = 2;
			});
		let placed = NodeFixtures.Box(grid, scope (s) =>
			{
				s.Height = LayoutLength.Px(10.0f);
				s.Column.Start = 1;
				s.Row.Start = 3;
			});
		bed.Layout();
		// 400 - 100 - 20 gaps = 280 for 3fr: 93.33 and 186.67, edges on whole pixels.
		NodeFixtures.CheckRect(a, 0, 0, 100, 20);
		Test.Assert(Near(b.Position.X, 110.0f));
		Test.Assert(Near(b.Size.X, 93.0f)); // 110 to 203.33
		Test.Assert(Near(c.Position.X, 213.0f));
		Test.Assert(Near(wide.Position.Y, 30.0f + 5.0f)); // the first row as tall as its tallest
		Test.Assert(Near(wide.Size.X, 203.0f));
		Test.Assert(Near(placed.Position.X, 0.0f));
		Test.Assert(Near(placed.Position.Y, 35.0f + 10.0f + 5.0f));
	}

	[Test]
	public static void AStackLaysItsChildrenOverEachOtherEachAlignedOnItsOwn()
	{
		let bed = scope Bed();
		let stack = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Kind = .Stack;
				s.Height = LayoutLength.Px(200.0f);
			});
		let fill = NodeFixtures.Box(stack);
		let corner = NodeFixtures.Box(stack, scope (s) =>
			{
				s.Width = LayoutLength.Px(50.0f);
				s.Height = LayoutLength.Px(20.0f);
				s.JustifySelf = .End;
				s.AlignSelf = .End;
			});
		let middle = NodeFixtures.Box(stack, scope (s) =>
			{
				s.Width = LayoutLength.Px(100.0f);
				s.Height = LayoutLength.Px(40.0f);
				s.JustifySelf = .Center;
				s.AlignSelf = .Center;
			});
		bed.Layout();
		NodeFixtures.CheckRect(fill, 0, 0, 400, 200);
		NodeFixtures.CheckRect(corner, 350, 180, 50, 20);
		NodeFixtures.CheckRect(middle, 150, 80, 100, 40);
	}

	[Test]
	public static void DockPutsChildrenToTheSidesInOrderAndTheFillTakesTheRest()
	{
		let bed = scope Bed();
		let dock = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Kind = .Dock;
				s.Height = LayoutLength.Px(300.0f);
			});
		let top = NodeFixtures.Box(dock, scope (s) =>
			{
				s.DockSide = .Top;
				s.Height = LayoutLength.Px(30.0f);
			});
		let left = NodeFixtures.Box(dock, scope (s) =>
			{
				s.DockSide = .Left;
				s.Width = LayoutLength.Px(80.0f);
			});
		let bottom = NodeFixtures.Box(dock, scope (s) =>
			{
				s.DockSide = .Bottom;
				s.Height = LayoutLength.Px(20.0f);
			});
		let right = NodeFixtures.Box(dock, scope (s) =>
			{
				s.DockSide = .Right;
				s.Width = LayoutLength.Px(40.0f);
			});
		let fill = NodeFixtures.Box(dock);
		bed.Layout();
		NodeFixtures.CheckRect(top, 0, 0, 400, 30);
		NodeFixtures.CheckRect(left, 0, 30, 80, 270);
		NodeFixtures.CheckRect(bottom, 80, 280, 320, 20);
		NodeFixtures.CheckRect(right, 360, 30, 40, 250);
		NodeFixtures.CheckRect(fill, 80, 30, 280, 250);
	}

	[Test]
	public static void OutOfFlowByItsInsetsPlacedFromCodeRelativeMovesItAlone()
	{
		let bed = scope Bed();
		let page = NodeFixtures.Box(bed.Root, scope (s) => { s.Height = LayoutLength.Px(300.0f); });
		let first = NodeFixtures.Box(page, scope (s) => { s.Height = LayoutLength.Px(30.0f); });
		let banner = NodeFixtures.Box(page, scope (s) =>
			{
				s.Placement = .Absolute;
				s.Left = LayoutLength.Px(20.0f);
				s.Right = LayoutLength.Px(20.0f);
				s.Bottom = LayoutLength.Px(10.0f);
				s.Height = LayoutLength.Px(40.0f);
			});
		let second = NodeFixtures.Box(page, scope (s) =>
			{
				s.Height = LayoutLength.Px(30.0f);
				s.Placement = .Relative;
				s.Left = LayoutLength.Px(15.0f);
			});
		let third = NodeFixtures.Box(page, scope (s) => { s.Height = LayoutLength.Px(30.0f); });
		bed.Layout();
		NodeFixtures.CheckRect(banner, 20, 250, 360, 40); // left and right stretch it; bottom places it
		Test.Assert(Near(second.Position.Y, 30.0f)); // the banner takes no space
		Test.Assert(Near(second.Position.X, 15.0f));
		Test.Assert(Near(third.Position.X, 0.0f)); // its sibling where it was
		Test.Assert(Near(third.Position.Y, 60.0f));

		first.Position = .(200.0f, 100.0f); // from code: out of the flow, at that place
		bed.Layout();
		Test.Assert(Near(first.Position.X, 200.0f));
		Test.Assert(Near(second.Position.Y, 0.0f)); // the others closed the gap
	}

	[Test]
	public static void HiddenKeepsItsPlaceNotDisplayedTakesNoneAndComesBackAsItWas()
	{
		let bed = scope Bed();
		let row = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Kind = .Grid;
				s.Columns.Add(GridTrack.Fixed(50.0f));
				s.Columns.Add(GridTrack.Fixed(50.0f));
			});
		let a = NodeFixtures.Fixed(row, 50.0f, 20.0f);
		let b = NodeFixtures.Fixed(row, 50.0f, 20.0f);
		let c = NodeFixtures.Fixed(row, 50.0f, 20.0f);
		a.Visible = false;
		bed.Layout();
		Test.Assert(Near(b.Position.X, 50.0f)); // a still holds the first cell
		a.Displayed = false;
		bed.Layout();
		Test.Assert(Near(b.Position.X, 0.0f));
		Test.Assert(Near(c.Position.X, 50.0f));
		row.Displayed = false;
		row.Displayed = true;
		Test.Assert(row.LayoutStyle.Kind == .Grid);
	}

	[Test]
	public static void AChangeLaysOutWhatItAffectsAFixedSizeBoxStopsIt()
	{
		let bed = scope Bed();
		let outer = NodeFixtures.Box(bed.Root, scope (s) => { s.Placement = .Absolute; });
		let inner = NodeFixtures.Box(outer);
		let leaf = NodeFixtures.Fixed(inner, 30.0f, 30.0f);
		bed.Layout();
		Test.Assert(Near(outer.Size.Y, 30.0f));
		leaf.Size = .(30.0f, 70.0f);
		bed.Layout();
		Test.Assert(Near(outer.Size.Y, 70.0f)); // up through the auto-sized containers
		inner.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(100.0f);
				s.Height = LayoutLength.Px(100.0f);
			});
		bed.Layout();
		leaf.Size = .(30.0f, 40.0f);
		let count = bed.Layout();
		Test.Assert(Near(outer.Size.Y, 100.0f)); // inner's size held: outer untouched
		Test.Assert(count <= 2); // inner, and the leaf at its new size
		Test.Assert(bed.Layout() == 0); // nothing waiting: nothing laid out
	}

	/// Three equal items across a 100-unit row at `scale`: every edge whole in device pixels.
	private static void CheckEdgesAtScale(float scale)
	{
		let bed = scope Bed(400.0f, 300.0f);
		bed.Root.SetDisplayScale(scale);
		let row = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Direction = .Row;
				s.Width = LayoutLength.Px(100.0f);
				s.Height = LayoutLength.Px(10.3f);
			});
		row.Padding = Thickness(0.3f, 0.0f, 0.0f, 0.0f);
		Node[3] cells = default;
		for (int i = 0; i < 3; i++)
			cells[i] = NodeFixtures.Box(row, scope (s) => { s.Grow = 1.0f; });
		bed.Layout();
		bool Whole(float v) => Near(Round(v * scale), v * scale);
		var x = cells[0].Position.X;
		for (let cell in cells)
		{
			Test.Assert(Whole(cell.Position.X), scope $"scale {scale}");
			Test.Assert(Whole(cell.Size.X), scope $"scale {scale}");
			Test.Assert(Whole(cell.Size.Y), scope $"scale {scale}");
			Test.Assert(Near(cell.Position.X, x), scope $"scale {scale}"); // meets its neighbour
			x += cell.Size.X;
		}
		Test.Assert(Whole(row.Size.Y), scope $"scale {scale}");
		Test.Assert(Near(row.PixelScale, scale), scope $"scale {scale}");
	}

	[Test]
	public static void ArrangedEdgesRoundToTheDeviceGridAtScales1And125And2()
	{
		// Three equal items across 100 units: edges at 33.33 and 66.67. Each edge rounds on its own,
		// so neighbours still meet and the widths add up; in device pixels every edge is whole.
		float[3] scales = .(1.0f, 1.25f, 2.0f);
		for (let scale in scales)
			CheckEdgesAtScale(scale);
	}

	[Test]
	public static void ANewDisplayScaleLaysTheWholeTreeOutAgainOnItsGrid()
	{
		let bed = scope Bed(400.0f, 300.0f);
		let row = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Direction = .Row;
				s.Width = LayoutLength.Px(100.0f);
			});
		let inner = NodeFixtures.Box(row, scope (s) =>
			{
				s.Width = LayoutLength.Px(50.0f);
				s.Height = LayoutLength.Px(10.0f);
			});
		let leaf = NodeFixtures.Box(inner, scope (s) =>
			{
				s.Width = LayoutLength.Px(10.3f);
				s.Height = LayoutLength.Px(4.0f);
			});
		bed.Layout();
		Test.Assert(Near(leaf.Size.X, 10.0f));
		bed.Root.SetDisplayScale(2.0f);
		bed.Layout();
		Test.Assert(Near(leaf.PixelScale, 2.0f));
		Test.Assert(Near(leaf.Size.X, 10.5f)); // 20.6 device pixels round to 21
	}

	[Test]
	public static void ARowsItemThatDoesNotStretchIsAsTallAsItsContentOverflowingAShortRow()
	{
		let bed = scope Bed();
		let row = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Direction = .Row;
				s.Height = LayoutLength.Px(50.0f);
				s.AlignItems = .Start;
			});
		let column = NodeFixtures.Box(row);
		NodeFixtures.Fixed(column, 40.0f, 30.0f);
		NodeFixtures.Fixed(column, 40.0f, 30.0f);
		let c = NodeFixtures.Fixed(column, 40.0f, 30.0f);
		bed.Layout();
		Test.Assert(Near(column.Size.Y, 90.0f)); // not squeezed into the row's 50
		Test.Assert(Near(c.Position.Y, 60.0f));
		Test.Assert(Near(c.Size.Y, 30.0f));

		// Stretched, it is the row's height.
		row.EditLayoutStyle(scope (s) => { s.AlignItems = .Stretch; });
		bed.Layout();
		Test.Assert(Near(column.Size.Y, 50.0f));
	}

	[Test]
	public static void DeepNestingMeasuresEachNodeABoundedNumberOfTimesNotTwicePerLevel()
	{
		// Each flex level measures its item for the base size and again at the size resolved; with
		// a one-entry measure cache that doubled per level (30 levels: about a billion measures).
		let bed = scope Bed();
		Node at = bed.Root;
		for (int i = 0; i < 30; i++)
		{
			let level = NodeFixtures.Box(at);
			level.Padding = Thickness(1.0f);
			at = level;
		}
		let leaf = new CountingLeaf();
		at.AddChild(leaf);
		leaf.ReleaseRef(); // the tree's keeps it
		bed.Layout();
		Test.Assert(leaf.Measures <= 8);
		Test.Assert(Near(leaf.Size.X, 400.0f - 2.0f * 30.0f)); // stretched across each level
		Test.Assert(Near(leaf.Size.Y, 20.0f));
	}

	[Test]
	public static void AWrappingRowInAColumnIsAsTallAsItsLinesAtTheWidthItGets()
	{
		// Six items of 80 in a row 300 wide wrap to two lines (three on each): the row is two lines
		// tall, and what follows it in the column comes after both.
		let bed = scope Bed(300.0f, 400.0f);
		let column = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Direction = .Column;
				s.Width = LayoutLength.Px(300.0f);
			});
		let row = NodeFixtures.Box(column, scope (s) =>
			{
				s.Direction = .Row;
				s.Wrap = .Wrap;
			});
		for (int i = 0; i < 6; i++)
			NodeFixtures.Fixed(row, 80.0f, 20.0f);
		let after = NodeFixtures.Fixed(column, 50.0f, 10.0f);
		bed.Layout();
		Test.Assert(Near(row.Size.Y, 40.0f));
		Test.Assert(Near(after.Position.Y, 40.0f));
	}

	[Test]
	public static void AWrappingRowWhoseItemsGrowAfterALayoutWrapsAndGrowsWithThem()
	{
		// The inspector's toggles get their font after they are first laid out: narrow first (one
		// line), then 447 in all in 440 (two lines). The row must grow to both lines.
		let bed = scope Bed(600.0f, 600.0f);
		let scroller = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Width = LayoutLength.Px(448.0f);
				s.Height = LayoutLength.Px(300.0f);
				s.OverflowX = .Hidden;
				s.OverflowY = .Auto;
			});
		let column = NodeFixtures.Box(scroller, scope (s) => { s.Direction = .Column; });
		column.Padding = Thickness(4.0f);
		let row = NodeFixtures.Box(column, scope (s) =>
			{
				s.Direction = .Row;
				s.Wrap = .Wrap;
				s.ColumnGap = 8.0f;
				s.RowGap = 8.0f;
			});
		let items = scope List<Node>();
		for (int i = 0; i < 6; i++)
			items.Add(NodeFixtures.Fixed(row, 30.0f, 48.0f));
		let after = NodeFixtures.Fixed(column, 50.0f, 10.0f);
		bed.Layout();
		Test.Assert(Near(row.Size.Y, 48.0f));
		float[6] widths = .(57.0f, 58.0f, 57.0f, 93.0f, 71.0f, 71.0f);
		for (int i = 0; i < 6; i++)
			items[i].Size = .(widths[i], 48.0f);
		bed.Layout();
		Test.Assert(Near(row.Size.Y, 48.0f + 8.0f + 48.0f));
		Test.Assert(Near(after.Position.Y, 4.0f + 104.0f));
	}

	[Test]
	public static void EachLineOfAWrappingRowIsAsTallAsItsOwnItemsNotAsTheWholeRow()
	{
		// Two lines of items 20 tall with a gap of 8: the row is 48 tall; the second line starts at
		// 28 and stretched items are 20 tall (CSS gives a line the container's whole cross size only
		// when the container is single-line).
		let bed = scope Bed(600.0f, 600.0f);
		let row = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Direction = .Row;
				s.Wrap = .Wrap;
				s.ColumnGap = 8.0f;
				s.RowGap = 8.0f;
				s.Width = LayoutLength.Px(100.0f);
			});
		let items = scope List<Node>();
		for (int i = 0; i < 4; i++)
		{
			items.Add(NodeFixtures.Box(row, scope (s) =>
				{
					s.Width = LayoutLength.Px(40.0f);
					s.MinHeight = LayoutLength.Px(20.0f);
				}));
		}
		bed.Layout();
		Test.Assert(Near(row.Size.Y, 48.0f));
		Test.Assert(Near(items[0].Size.Y, 20.0f));
		Test.Assert(Near(items[2].Position.Y, 28.0f));
		Test.Assert(Near(items[2].Size.Y, 20.0f));
	}

	[Test]
	public static void ASingleLineRowMeasuredUnderAHeightLimitIsAsTallAsItsContentNotTheLimit()
	{
		// A checkbox is such a row (its box and its label): asked its height with room for 48 it
		// said 48, so a wrapping row of them made each line 48 tall and the second line fell out.
		let bed = scope Bed(600.0f, 600.0f);
		let row = NodeFixtures.Box(bed.Root, scope (s) => { s.Direction = .Row; });
		NodeFixtures.Fixed(row, 20.0f, 20.0f);
		NodeFixtures.Fixed(row, 30.0f, 13.0f);
		var limit = LayoutConstraints();
		limit.Max = .(100.0f, 48.0f);
		Test.Assert(Near(row.Measure(limit).Y, 20.0f));
		// Told its height exactly, it takes it.
		Test.Assert(Near(row.Measure(LayoutConstraints.Tight(.(100.0f, 48.0f), .(-1.0f, -1.0f))).Y, 48.0f));
	}

	[Test]
	public static void ADocksFillTakesWhatEverySideLeftWhereverItStandsAmongThem()
	{
		let bed = scope Bed();
		let dock = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Kind = .Dock;
				s.Height = LayoutLength.Px(300.0f);
			});
		let fill = NodeFixtures.Box(dock); // first, though it fills
		let left = NodeFixtures.Box(dock, scope (s) =>
			{
				s.DockSide = .Left;
				s.Width = LayoutLength.Px(80.0f);
			});
		let top = NodeFixtures.Box(dock, scope (s) =>
			{
				s.DockSide = .Top;
				s.Height = LayoutLength.Px(30.0f);
			});
		bed.Layout();
		NodeFixtures.CheckRect(left, 0, 0, 80, 300);
		NodeFixtures.CheckRect(top, 80, 0, 320, 30);
		NodeFixtures.CheckRect(fill, 80, 30, 320, 270); // not under the sides
	}

	[Test]
	public static void ASheetsInsetsAreFromInsideTheBorderAPositionCodeGivesIsInTheBox()
	{
		let bed = scope Bed();
		let holder = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Width = LayoutLength.Px(200.0f);
				s.Height = LayoutLength.Px(100.0f);
			});
		let box5 = scope NodeBox();
		box5.BorderWidths = BorderWidths(5.0f);
		holder.SetBox(box5);
		let styled = NodeFixtures.Box(holder, scope (s) =>
			{
				s.Placement = .Absolute;
				s.Left = LayoutLength.Px(10.0f);
				s.Top = LayoutLength.Px(10.0f);
				s.Width = LayoutLength.Px(20.0f);
				s.Height = LayoutLength.Px(20.0f);
			});
		let placed = NodeFixtures.Fixed(holder, 20.0f, 20.0f);
		placed.Position = .(10.0f, 10.0f);
		bed.Layout();
		NodeFixtures.CheckRect(styled, 15, 15, 20, 20); // 10 inside the 5-wide border
		NodeFixtures.CheckRect(placed, 10, 10, 20, 20); // where code put it
	}

	[Test]
	public static void FitContentIsAsWideAsWhatItHoldsNotStretchedAcross()
	{
		let bed = scope Bed();
		let column = NodeFixtures.Box(bed.Root); // a column stretches its children across
		let fit = NodeFixtures.Box(column, scope (s) => { s.Width = LayoutLength(.FitContent, 0.0f); });
		NodeFixtures.Fixed(fit, 60.0f, 20.0f);
		bed.Layout();
		Test.Assert(Near(fit.Size.X, 60.0f));
	}

	[Test]
	public static void ZIndexOrdersSiblingsForDrawingAndThePointerElseTheyStandAsTheyAre()
	{
		let bed = scope Bed();
		let stack = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Kind = .Stack;
				s.Width = LayoutLength.Px(100.0f);
				s.Height = LayoutLength.Px(100.0f);
			});
		let under = NodeFixtures.Fixed(stack, 100.0f, 100.0f);
		let over = NodeFixtures.Fixed(stack, 100.0f, 100.0f);
		bed.Layout();
		Test.Assert(bed.Root.OverFind(.(50.0f, 50.0f)) == over); // the later stands on top
		under.EditLayoutStyle(scope (s) => { s.ZIndex = 1; });
		bed.Layout();
		Test.Assert(bed.Root.OverFind(.(50.0f, 50.0f)) == under); // raised above its sibling
		let order = scope List<Node>();
		stack.ChildrenInPaintOrder(order);
		Test.Assert(order.Count == 2);
		Test.Assert(order[1] == under); // drawn last
	}

	[Test]
	public static void ASheetsDisplayFlexGridAndSizePropertiesReachTheLayout()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let grid = new Panel();
		defer grid.ReleaseRef();
		grid.AddClass("cards");
		root.AddChild(grid);
		let cards = scope List<Panel>();
		defer
		{
			for (let c in cards)
				c.ReleaseRef();
		}
		for (int i = 0; i < 4; i++)
		{
			let card = new Panel();
			card.AddClass("card");
			grid.AddChild(card);
			cards.Add(card);
		}
		let sheet = scope StyleSheet();
		CSSParser.Parse(".cards { display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px 20px; padding: 10px; }" +
			".card { height: 40px; }", sheet);
		let styles = scope StyleManager(sheet);
		styles.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(grid.LayoutStyle.Kind == .Grid);
		Test.Assert(grid.LayoutStyle.Columns.Count == 2);
		Test.Assert(Near(cards[1].Position.X, 10.0f + 180.0f + 20.0f)); // (380 - 20) / 2 a column
		Test.Assert(Near(cards[1].Position.Y, 10.0f));
		Test.Assert(Near(cards[2].Position.X, 10.0f));
		Test.Assert(Near(cards[2].Position.Y, 10.0f + 40.0f + 10.0f));

		let flexSheet = scope StyleSheet();
		CSSParser.Parse(".cards { display: flex; flex-flow: row wrap; } .card { flex: 1; width: 25%; min-width: 50px; }", flexSheet);
		let flex = scope StyleManager(flexSheet);
		flex.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(grid.LayoutStyle.Direction == .Row);
		Test.Assert(grid.LayoutStyle.Wrap == .Wrap);
		Test.Assert(Near(cards[0].LayoutStyle.Grow, 1.0f));
		Test.Assert(cards[0].LayoutStyle.Width.Kind == .Percent);
	}

	[Test]
	public static void PercentageMarginsPaddingAndGapsAreOfTheContainersContentSizeAsCSSs()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f); // 400 wide
		defer root.ReleaseRef();
		let row = PanelBox(root, scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Start;
			});
		let a = PanelFixed(row, 50.0f, 20.0f);
		let b = PanelFixed(row, 50.0f, 20.0f);
		let sheet = scope StyleSheet();
		CSSParser.Parse(".row { column-gap: 10%; padding-left: 5%; } .a { margin-left: 25%; }", sheet);
		let styles = scope StyleManager(sheet);
		row.AddClass("row");
		a.AddClass("a");
		styles.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(Near(row.Padding.Left, 20.0f)); // 5% of the root's 400
		// a starts after the padding (20) and its margin (25% of the row's content width, 380: 95).
		Test.Assert(Near(a.Position.X, 20.0f + 95.0f));
		Test.Assert(Near(b.Position.X, 20.0f + 95.0f + 50.0f + 38.0f)); // the gap: 10% of 380
	}

	[Test]
	public static void CalcMixesPixelsAndPercentagesWherePercentagesResolve()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f); // 400 wide
		defer root.ReleaseRef();
		let row = PanelBox(root, scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Start;
			});
		// Their heights from code; their widths the sheet's.
		let a = PanelBox(row, scope (s) => { s.Height = LayoutLength.Px(20.0f); });
		let b = PanelBox(row, scope (s) => { s.Height = LayoutLength.Px(20.0f); });
		row.AddClass("row");
		a.AddClass("a");
		b.AddClass("b");
		let sheet = scope StyleSheet();
		CSSParser.Parse(".row { padding-left: calc(10% - 20px); column-gap: calc(10px + 5%); }" +
			".a { width: calc(50% - 2 * 10px); margin-left: calc((10% + 4px) / 2); }" +
			".b { width: calc(1em + 4px); }", sheet);
		let styles = scope StyleManager(sheet);
		styles.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(a.LayoutStyle.Width.Kind == .Calc);
		Test.Assert(Near(row.Padding.Left, 20.0f)); // 10% of 400, less 20
		// The row's content is 380 wide: a is half of it less 20, after its margin (5% of 380, and 2).
		Test.Assert(Near(a.Size.X, 170.0f));
		Test.Assert(Near(a.Position.X, 20.0f + 21.0f));
		Test.Assert(b.LayoutStyle.Width.Kind == .Px); // no percent part: plain pixels
		Test.Assert(Near(b.Size.X, 20.0f)); // 1em of 16, and 4
		Test.Assert(Near(b.Position.X, 41.0f + 170.0f + 29.0f)); // the gap: 10 and 5% of 380
	}

	[Test]
	public static void AWrappingLabelWrapsToTheWidthItIsGivenAndShrinksNoNarrowerThanItsLongestWord()
	{
		let font = scope CachedFont(new MockFont(), null); // owns and deletes the mock
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let column = PanelBox(root, scope (s) => { s.Width = LayoutLength.Px(100.0f); });
		let text = new Label();
		defer text.ReleaseRef();
		text.Font = font;
		text.WhiteSpace = .Normal;
		text.Text = "aaaa bbbb cccc dddd"; // words of 24, a space 6: four words take 114
		column.AddChild(text);
		root.UpdateLayout();
		Test.Assert(Near(text.Size.X, 100.0f)); // stretched across
		Test.Assert(Near(text.Size.Y, 24.0f)); // two lines at 100 wide

		let row = PanelBox(root, scope (s) =>
			{
				s.Direction = .Row;
				s.Width = LayoutLength.Px(60.0f);
				s.AlignItems = .Start;
			});
		let squeezed = new Label();
		defer squeezed.ReleaseRef();
		squeezed.Font = font;
		squeezed.WhiteSpace = .Normal;
		squeezed.Text = "aaaaaaaa bb";
		row.AddChild(squeezed);
		PanelFixed(row, 50.0f, 10.0f);
		root.UpdateLayout();
		Test.Assert(Near(squeezed.Size.X, 48.0f)); // its longest word: the sibling overflows
		Test.Assert(Near(squeezed.Size.Y, 24.0f));
	}

	[Test]
	public static void ALabelsBaselineFollowsItsVerticalAlignmentAndItsWrapping()
	{
		let font = scope CachedFont(new MockFont(), null);
		let label = new Label();
		defer label.ReleaseRef();
		label.Font = font;
		label.Text = "aaaa bbbb";
		label.Padding = Thickness(2.0f);
		let size = Float2(100.0f, 40.0f); // a 36 tall content box from 2
		label.SetTextAlignment(.Left, .Top);
		Test.Assert(Near(label.BaselineAt(size), 2.0f + 10.0f));
		label.SetTextAlignment(.Left, .Middle);
		Test.Assert(Near(label.BaselineAt(size), 2.0f + 12.0f + 10.0f));
		label.SetTextAlignment(.Left, .Bottom);
		Test.Assert(Near(label.BaselineAt(size), 38.0f - 2.0f)); // the descent above the bottom
		// Wrapped to two lines in 30 wide, centred: the block of 24 starts 6 down, its first line's
		// baseline 10 below that.
		label.WhiteSpace = .Normal;
		label.SetTextAlignment(.Left, .Middle);
		Test.Assert(Near(label.BaselineAt(.(34.0f, 40.0f)), 2.0f + 6.0f + 10.0f));
		// Any other node: the bottom of its content box.
		let panel = new Panel();
		defer panel.ReleaseRef();
		panel.Padding = Thickness(0.0f, 0.0f, 0.0f, 5.0f);
		Test.Assert(Near(panel.BaselineAt(.(50.0f, 30.0f)), 25.0f));
	}

	/// The box the vertices of one colour cover (by its red, green and blue), and how many.
	private struct Extent
	{
		public int Count = 0;
		public Float2 Min = .(1.0e9f, 1.0e9f);
		public Float2 Max = .(-1.0e9f, -1.0e9f);

		public this() { }
	}

	private static Extent ExtentOf(VGContext vg, Color color)
	{
		var e = Extent();
		for (let v in vg.GetBatch().Vertices)
		{
			if ((Math.Abs(v.Color.R - color.R) < 0.01f) && (Math.Abs(v.Color.G - color.G) < 0.01f) && (Math.Abs(v.Color.B - color.B) < 0.01f))
			{
				++e.Count;
				e.Min = .(Math.Min(e.Min.X, v.Position.X), Math.Min(e.Min.Y, v.Position.Y));
				e.Max = .(Math.Max(e.Max.X, v.Position.X), Math.Max(e.Max.Y, v.Position.Y));
			}
		}
		return e;
	}

	/// `root` drawn with `overlay` into `vg`.
	private static void DrawWith(SceneRoot root, DebugOverlay overlay, VGContext vg)
	{
		root.DebugOverlay = overlay;
		let dc = scope DrawContext(vg);
		root.Draw(dc);
	}

	[Test]
	public static void TheOverlayDrawsMarginsPaddingBoundsAndTextBaselinesWhereLayoutPutThem()
	{
		let font = scope CachedFont(new MockFont(), null);
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let column = PanelBox(root, scope (s) => { s.AlignItems = .Start; });
		let framed = PanelFixed(column, 100.0f, 40.0f);
		framed.Margin = Thickness(10.0f);
		framed.Padding = Thickness(5.0f);
		let label = new Label();
		defer label.ReleaseRef();
		label.Font = font;
		label.Text = "Hi";
		column.AddChild(label); // at y 60, 12 tall, baseline 10 down
		root.UpdateLayout();

		let margin = Color(1.0f, 0.6f, 0.2f, 1.0f);
		let padding = Color(0.3f, 0.85f, 0.4f, 1.0f);
		let baseline = Color(1.0f, 0.2f, 0.9f, 1.0f);
		{
			let vg = scope VGContext();
			DrawWith(root, DebugOverlay(), vg);
			Test.Assert(ExtentOf(vg, margin).Count == 0);
			Test.Assert(ExtentOf(vg, baseline).Count == 0);
		}
		{
			let vg = scope VGContext();
			var overlay = DebugOverlay();
			overlay.Margin = true;
			DrawWith(root, overlay, vg);
			let m = ExtentOf(vg, margin); // the box's margin box: 0,0 to 120,60
			Test.Assert(m.Count > 0);
			Test.Assert(Near(m.Min.X, 0.0f));
			Test.Assert(Near(m.Min.Y, 0.0f));
			Test.Assert(Near(m.Max.X, 120.0f));
			Test.Assert(Near(m.Max.Y, 60.0f));
			Test.Assert(ExtentOf(vg, padding).Count == 0);
		}
		{
			let vg = scope VGContext();
			var overlay = DebugOverlay();
			overlay.Padding = true;
			DrawWith(root, overlay, vg);
			let p = ExtentOf(vg, padding); // within its border box: 10,10 to 110,50
			Test.Assert(p.Count > 0);
			Test.Assert(Near(p.Min.X, 10.0f));
			Test.Assert(Near(p.Max.Y, 50.0f));
		}
		{
			let vg = scope VGContext();
			var overlay = DebugOverlay();
			overlay.Baselines = true;
			DrawWith(root, overlay, vg);
			let b = ExtentOf(vg, baseline); // the label's alone, about y 70
			Test.Assert(b.Count > 0);
			Test.Assert(b.Min.Y > 68.5f); // a hairline, with its edge fringe
			Test.Assert(b.Max.Y < 71.5f);
			Test.Assert(Math.Abs(b.Min.X) < 0.02f);
		}
	}

	[Test]
	public static void ALabelAndAButtonSizeToTheirTextAndFollowIt()
	{
		let font = scope CachedFont(new MockFont(), null); // 6px a byte, 12px a line
		let bed = scope Bed();
		let row = PanelBox(bed.Root, scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Start;
				s.ColumnGap = 10.0f;
			});
		let label = new Label();
		defer label.ReleaseRef();
		label.Font = font;
		label.Text = "Score";
		label.Padding = Thickness(4.0f);
		row.AddChild(label);
		let button = new Button();
		defer button.ReleaseRef();
		button.Font = font;
		button.Text = "Play";
		button.Padding = Thickness(10.0f, 6.0f);
		row.AddChild(button);
		let area = new CheckBox();
		defer area.ReleaseRef();
		row.AddChild(area);
		bed.Layout();
		NodeFixtures.CheckRect(label, 0, 0, 5 * 6 + 8, 12 + 8);
		NodeFixtures.CheckRect(button, 38 + 10, 0, 4 * 6 + 20, 12 + 12);
		Test.Assert(Near(area.Size.X, 20.0f));
		label.Text = "Score: 120";
		bed.Layout();
		Test.Assert(Near(label.Size.X, 10 * 6 + 8));
		Test.Assert(Near(button.Position.X, 68.0f + 10.0f)); // moved along with it
	}

	[Test]
	public static void ARowAlignedByBaselineLinesUpItsItemsTextAndGrowsToHoldThem()
	{
		// The mock font's ascent is 10 on a 12 line. A label's baseline is its padding plus the
		// ascent (its line fills its content box); a button's the same; a plain box's the bottom of
		// its content box.
		let font = scope CachedFont(new MockFont(), null);
		let bed = scope Bed();
		let row = PanelBox(bed.Root, scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Baseline;
			});
		let label = new Label();
		defer label.ReleaseRef();
		label.Font = font;
		label.Text = "Name";
		label.Padding = Thickness(4.0f); // 20 tall, baseline 14
		row.AddChild(label);
		let button = new Button();
		defer button.ReleaseRef();
		button.Font = font;
		button.Text = "Go";
		button.Padding = Thickness(10.0f, 6.0f); // 24 tall, baseline 16
		row.AddChild(button);
		let area = PanelFixed(row, 40.0f, 30.0f); // baseline 30
		let pushed = new Label();
		defer pushed.ReleaseRef();
		pushed.Font = font;
		pushed.Text = "x";
		pushed.Padding = Thickness(4.0f);
		pushed.Margin = Thickness(0.0f, 6.0f, 0.0f, 0.0f); // its margin box's baseline at 20
		row.AddChild(pushed);
		bed.Layout();

		// The baselines meet at 30, the deepest above it; each item sits so its baseline is there.
		Test.Assert(Near(label.Position.Y, 16.0f));
		Test.Assert(Near(button.Position.Y, 14.0f));
		Test.Assert(Near(area.Position.Y, 0.0f));
		Test.Assert(Near(pushed.Position.Y, 16.0f)); // 10 down, then its margin
		Test.Assert(Near(label.Position.Y + label.Baseline, 30.0f));
		Test.Assert(Near(button.Position.Y + button.Baseline, 30.0f));
		// The row holds what reaches furthest below the baseline too: the button's 8.
		Test.Assert(Near(row.Size.Y, 38.0f));

		// In a column, baseline places as start.
		row.EditLayoutStyle(scope (s) => { s.Direction = .Column; });
		bed.Layout();
		Test.Assert(Near(label.Position.X, 0.0f));
		Test.Assert(Near(area.Position.X, 0.0f));
	}

	/// A leaf whose content is off the device grid, as shaped text is.
	private class FractionalLeaf : Node
	{
		public override Float2 MeasureContent(Float2 available) => .(29.06f, 15.2f);
	}

	[Test]
	public static void AContentSizeRoundsUpToTheDeviceGridSoABoxKeepsAllOfItsContent()
	{
		// Each edge rounds to the grid on its own: a label 29.06 wide placed off the grid was 29
		// wide, and its text ended in an ellipsis. Measured up to the grid, it is 30 wherever it lands.
		float[2] scales = .(1.0f, 2.0f);
		for (let scale in scales)
		{
			let bed = scope Bed();
			bed.Root.SetDisplayScale(scale);
			let row = NodeFixtures.Box(bed.Root, scope (s) =>
				{
					s.Direction = .Row;
					s.AlignItems = .Start;
				});
			row.Padding = Thickness(7.3f, 0.0f, 7.3f, 0.0f); // the leaf lands off the grid
			let leaf = new FractionalLeaf();
			leaf.EditLayoutStyle(scope (s) =>
				{
					s.Shrink = 1.0f;
					s.MinWidth = LayoutLength.Px(0.0f);
				});
			row.AddChild(leaf);
			leaf.ReleaseRef(); // the tree's reference keeps it
			bed.Layout();
			let wide = Ceil(29.06f * scale) / scale;
			let tall = Ceil(15.2f * scale) / scale;
			Test.Assert(Near(leaf.Size.X, wide));
			Test.Assert(Near(leaf.Size.Y, tall));
			Test.Assert(leaf.Size.X >= 29.06f);
		}
	}

	[Test]
	public static void ARowWhoseItemsGrowIsAsWideAsItsItemsWhenMeasuredNotTheSpaceOffered()
	{
		// A button's text grows to fill the button. Centred in a column 300 wide, the button was
		// measured 300 wide (its text grown into all of it), so it filled the column; as in CSS, a
		// row's content is its items before they grow, and they grow in the size it is given.
		let bed = scope Bed();
		let column = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Direction = .Column;
				s.Width = LayoutLength.Px(300.0f);
				s.AlignItems = .Center;
			});
		let button = NodeFixtures.Box(column, scope (s) => { s.Direction = .Row; });
		NodeFixtures.Fixed(button, 16.0f, 16.0f); // its icon
		let text = NodeFixtures.Box(button, scope (s) =>
			{
				s.Grow = 1.0f;
				s.Width = LayoutLength.Px(40.0f);
				s.Height = LayoutLength.Px(16.0f);
			});
		bed.Layout();
		Test.Assert(Near(button.Size.X, 56.0f));
		Test.Assert(Near(button.Position.X, (300.0f - 56.0f) * 0.5f));
		Test.Assert(Near(text.Size.X, 40.0f));

		// Stretched across the column, it is the column's width and its text grows into it.
		column.EditLayoutStyle(scope (s) => { s.AlignItems = .Stretch; });
		bed.Layout();
		Test.Assert(Near(button.Size.X, 300.0f));
		Test.Assert(Near(text.Size.X, 284.0f));
	}

	[Test]
	public static void AScrollerInAColumnHasNoAutomaticMinimumOnTheAxisItScrollsItsContentScrollsInsideIt()
	{
		// The model first: the view unregisters from it when the tree lets the view go.
		StringView[200] rows = .();
		for (int i = 0; i < rows.Count; ++i)
			rows[i] = "row";
		let model = scope StringListModel(rows);
		let bed = scope Bed();
		let column = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Direction = .Column;
				s.Width = LayoutLength.Px(200.0f);
				s.Height = LayoutLength.Px(200.0f);
			});
		// A virtualised list whose rows are all one height: it realises the rows its height shows.
		let list = new ListView();
		list.EditLayoutStyle(scope (s) => { s.Grow = 1.0f; });
		list.RowHeight = 20.0f;
		column.AddChild(list);
		list.ReleaseRef(); // the tree's reference keeps it
		list.Model = model;
		for (int pass = 0; pass < 5; ++pass)
		{
			bed.Layout();
			list.RequestLayout(); // again, as a frame's new line does
		}
		bed.Layout();
		Test.Assert(Near(list.Size.Y, 200.0f)); // not the rows it realised, nor all of them
		Test.Assert(Near(list.ScrollRange.Y, 200.0f * 20.0f - 200.0f));
	}
}
