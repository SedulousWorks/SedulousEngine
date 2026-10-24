using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Direction: right to left mirrors flex rows, a column's cross start, grid columns and a stack's
/// start, margins staying on the sides their style names; dock stays physical, its start and end
/// sides following the direction; mirror-on-rtl flips a node's drawing; a right-to-left scroller
/// runs from its right.
class DirectionTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void ARightToLeftRowRunsFromTheRightItsMarginsOnTheSidesTheyName()
	{
		let bed = scope Bed(100.0f, 100.0f);
		let row = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Direction = .Row;
				s.ColumnGap = 5.0f;
			});
		let a = NodeFixtures.Fixed(row, 20.0f, 10.0f);
		let b = NodeFixtures.Fixed(row, 20.0f, 10.0f);
		b.Margin = Thickness(0.0f, 0.0f, 8.0f, 0.0f); // left, top, right, bottom
		bed.Layout();
		Test.Assert(Near(a.Position.X, 0.0f));
		Test.Assert(Near(b.Position.X, 25.0f));
		row.SetLayoutDirection(.RightToLeft);
		bed.Layout();
		Test.Assert(Near(a.Position.X, 80.0f));
		Test.Assert(Near(b.Position.X, 80.0f - 5.0f - 8.0f - 20.0f)); // its right margin between it and a
		row.SetLayoutDirection(.Inherit);
		bed.Layout();
		Test.Assert(Near(a.Position.X, 0.0f));
	}

	[Test]
	public static void AColumnsCrossStartGridColumnsAndAStacksStartMirrorDockDoesNot()
	{
		let bed = scope Bed(100.0f, 100.0f);
		let page = NodeFixtures.Box(bed.Root);
		page.SetLayoutDirection(.RightToLeft);
		let column = NodeFixtures.Box(page, scope (s) => { s.AlignItems = .Start; });
		let inColumn = NodeFixtures.Fixed(column, 30.0f, 10.0f);
		let grid = NodeFixtures.Box(page, scope (s) =>
			{
				s.Kind = .Grid;
				s.Columns.Add(GridTrack.Fixed(40.0f));
				s.Columns.Add(GridTrack.Fixed(40.0f));
			});
		let first = NodeFixtures.Fixed(grid, 40.0f, 10.0f);
		let second = NodeFixtures.Fixed(grid, 40.0f, 10.0f);
		let stack = NodeFixtures.Box(page, scope (s) =>
			{
				s.Kind = .Stack;
				s.JustifyItems = .Start;
			});
		let inStack = NodeFixtures.Fixed(stack, 10.0f, 10.0f);
		let dock = NodeFixtures.Box(page, scope (s) =>
			{
				s.Kind = .Dock;
				s.Height = LayoutLength.Px(20.0f);
			});
		let docked = NodeFixtures.Box(dock, scope (s) =>
			{
				s.DockSide = .Left;
				s.Width = LayoutLength.Px(15.0f);
			});
		bed.Layout();
		Test.Assert(Near(inColumn.Position.X, 70.0f));
		Test.Assert(Near(first.Position.X, 60.0f));
		Test.Assert(Near(second.Position.X, 20.0f));
		Test.Assert(Near(inStack.Position.X, 90.0f));
		Test.Assert(Near(docked.Position.X, 0.0f)); // left is left
	}

	[Test]
	public static void DocksStartAndEndAreLeftAndRightSwappedInRightToLeft()
	{
		let bed = scope Bed(100.0f, 100.0f);
		let dock = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Kind = .Dock;
				s.Height = LayoutLength.Px(20.0f);
			});
		let start = NodeFixtures.Box(dock, scope (s) =>
			{
				s.DockSide = .Start;
				s.Width = LayoutLength.Px(15.0f);
			});
		let end = NodeFixtures.Box(dock, scope (s) =>
			{
				s.DockSide = .End;
				s.Width = LayoutLength.Px(10.0f);
			});
		bed.Layout();
		Test.Assert(Near(start.Position.X, 0.0f));
		Test.Assert(Near(end.Position.X, 90.0f));
		dock.SetLayoutDirection(.RightToLeft);
		bed.Layout();
		Test.Assert(Near(start.Position.X, 85.0f));
		Test.Assert(Near(end.Position.X, 0.0f));
	}

	[Test]
	public static void MirrorOnRtlFlipsANodesDrawingAboutItsCentreOnlyWhileItRunsRightToLeft()
	{
		let bed = scope Bed(100.0f, 100.0f);
		let page = NodeFixtures.Box(bed.Root, scope (s) => { s.Direction = .Row; });
		let icon = NodeFixtures.Fixed(page, 20.0f, 10.0f);
		icon.MirrorOnRtl = true;
		bed.Layout();
		Test.Assert(!icon.IsMirrored);
		Test.Assert(Near(icon.ConvertToWorldSpace(.(0.0f, 0.0f)).X, 0.0f));
		page.SetLayoutDirection(.RightToLeft);
		bed.Layout();
		Test.Assert(icon.IsMirrored);
		// At x 80 to 100 now: its own left edge drawn at its right.
		Test.Assert(Near(icon.ConvertToWorldSpace(.(0.0f, 0.0f)).X, 100.0f));
		Test.Assert(Near(icon.ConvertToWorldSpace(.(20.0f, 0.0f)).X, 80.0f));
		page.SetLayoutDirection(.LeftToRight);
		bed.Layout();
		Test.Assert(!icon.IsMirrored);
	}

	[Test]
	public static void TheArrowTowardTheInlineEndIsAStepOnTheOtherAStepBack()
	{
		let bed = scope Bed(100.0f, 100.0f);
		let part = NodeFixtures.Box(bed.Root);
		Test.Assert(part.InlineStep(.Right) == 1);
		Test.Assert(part.InlineStep(.Left) == -1);
		Test.Assert(part.InlineStep(.Up) == 0);
		part.SetLayoutDirection(.RightToLeft);
		Test.Assert(part.InlineStep(.Left) == 1);
		Test.Assert(part.InlineStep(.Right) == -1);
	}

	[Test]
	public static void ARightToLeftScrollerHeldAtItsEndFollowsItAsTheContentGrows()
	{
		let bed = scope Bed(100.0f, 100.0f);
		bed.Root.Size = .(300.0f, 300.0f);
		bed.Root.SetLayoutDirection(.RightToLeft);
		let strip = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Direction = .Row;
				s.OverflowX = .Auto;
				s.Width = LayoutLength.Px(100.0f);
				s.Height = LayoutLength.Px(60.0f);
			});
		for (int i = 0; i < 3; i++)
		{
			NodeFixtures.Box(strip, scope (s) =>
				{
					s.Width = LayoutLength.Px(80.0f);
					s.Shrink = 0.0f;
				});
		}
		bed.Layout();
		strip.ScrollToEnd(.Instant);
		strip.StickToEnd = true;
		Test.Assert(strip.IsLatchedToEnd);
		NodeFixtures.Box(strip, scope (s) =>
			{
				s.Width = LayoutLength.Px(80.0f);
				s.Shrink = 0.0f;
			});
		bed.Layout();
		Test.Assert(Near(strip.ScrollOffset.X, -220.0f));
	}

	[Test]
	public static void ContentWiderThanARightToLeftRowOverflowsTowardItsInlineEndTheLeft()
	{
		let bed = scope Bed(100.0f, 100.0f);
		bed.Root.Size = .(300.0f, 300.0f);
		bed.Root.SetLayoutDirection(.RightToLeft);
		let row = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Direction = .Row;
				s.Width = LayoutLength.Px(100.0f);
				s.Height = LayoutLength.Px(20.0f);
			});
		let wide = NodeFixtures.Box(row, scope (s) =>
			{
				s.Width = LayoutLength.Px(130.0f);
				s.Shrink = 0.0f;
			});
		bed.Layout();
		// As CSS has it: its start against the row's right edge, the 30 past it on the left.
		Test.Assert(Near(wide.Position.X, -30.0f));
	}
}
