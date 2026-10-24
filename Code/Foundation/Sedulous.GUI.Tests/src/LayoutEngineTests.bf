using System;
using System.Collections;
using Sedulous.Core;
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
}
