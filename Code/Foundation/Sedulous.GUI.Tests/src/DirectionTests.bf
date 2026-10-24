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

	/// A panel (a widget tagged so) styled by `style`, the last child of `parent`, which holds it:
	/// it comes back borrowed.
	private static UIWidget PanelBox(Node parent, delegate void(LayoutStyle style) style)
	{
		let panel = StyleFixtures.Widget("panel");
		panel.EditLayoutStyle(style);
		parent.AddChild(panel);
		panel.ReleaseRef(); // the tree's reference keeps it
		return panel;
	}

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

	[Test]
	public static void InlineStartAndEndMarginsPaddingsAndInsetsLandOnTheSidesTheDirectionPutsThemOn()
	{
		let root = SceneFixtures.NewScene(100.0f, 100.0f);
		defer root.ReleaseRef();
		let page = StyleFixtures.Widget("panel");
		defer page.ReleaseRef();
		page.AddClass("page");
		root.AddChild(page);
		let item = StyleFixtures.Widget("panel");
		defer item.ReleaseRef();
		item.AddClass("item");
		page.AddChild(item);
		let pinned = StyleFixtures.Widget("panel");
		defer pinned.ReleaseRef();
		pinned.AddClass("pinned");
		page.AddChild(pinned);
		StringView rules = ".item { margin-inline: 4 6; padding-inline-start: 3; margin-left: 50; } " +
			".pinned { position: absolute; inset-inline-start: 7; }";
		let sheet = scope StyleSheet();
		CSSParser.Parse(rules, sheet);
		let styles = scope StyleManager(sheet);
		styles.ApplyTree(root);
		Test.Assert(Near(item.Margin.Left, 4.0f)); // the logical side wins over margin-left
		Test.Assert(Near(item.Margin.Right, 6.0f));
		Test.Assert(Near(item.Padding.Left, 3.0f));
		Test.Assert(Near(pinned.LayoutStyle.Left.Resolve(0.0f).GetValueOrDefault(-1.0f), 7.0f));

		let rtl = scope String(".page { direction: rtl; } ");
		rtl.Append(rules);
		let rtlSheet = scope StyleSheet();
		CSSParser.Parse(rtl, rtlSheet);
		styles.StyleSheet = rtlSheet;
		styles.ApplyTree(root);
		Test.Assert(Near(item.Margin.Right, 4.0f));
		Test.Assert(Near(item.Margin.Left, 6.0f));
		Test.Assert(Near(item.Padding.Right, 3.0f));
		Test.Assert(Near(item.Padding.Left, 0.0f));
		Test.Assert(Near(pinned.LayoutStyle.Right.Resolve(0.0f).GetValueOrDefault(-1.0f), 7.0f));
	}

	[Test]
	public static void ARightToLeftScrollerStartsAtItsInlineStartItsOffset0ThereAndNegativeTowardTheLeft()
	{
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		root.SetLayoutDirection(.RightToLeft);
		let strip = PanelBox(root, scope (s) =>
			{
				s.Direction = .Row;
				s.OverflowX = .Auto;
				s.Width = LayoutLength.Px(100.0f);
				s.Height = LayoutLength.Px(60.0f);
			});
		UIWidget[4] cells = default;
		for (int i = 0; i < 4; i++)
		{
			cells[i] = PanelBox(strip, scope (s) =>
				{
					s.Width = LayoutLength.Px(80.0f);
					s.Shrink = 0.0f;
				});
		}
		root.UpdateLayout();
		let area = strip.ContentBounds;

		// At the start: the first cell against the right edge, the rest past the left (CSS's model).
		Test.Assert(Near(strip.ScrollOffset.X, 0.0f));
		Test.Assert(Near(strip.ScrollMin.X, -220.0f));
		Test.Assert(Near(strip.ScrollMax.X, 0.0f));
		Test.Assert(Near(cells[0].Position.X + 80.0f, area.X + area.Width));
		Test.Assert(Near(cells[3].Position.X, area.X - 220.0f));
		// The thumb at the right, where the content starts.
		let track = strip.ScrollBarTrack(0);
		let thumb = strip.ScrollBarThumb(0);
		Test.Assert(Near(thumb.X + thumb.Width, track.X + track.Width));

		// Clamped to [-range, 0]; the end is the left.
		strip.ScrollOffset = .(50.0f, 0.0f);
		Test.Assert(Near(strip.ScrollOffset.X, 0.0f));
		strip.ScrollOffset = .(-1000.0f, 0.0f);
		Test.Assert(Near(strip.ScrollOffset.X, -220.0f));
		Test.Assert(strip.IsAtScrollEnd);
		Test.Assert(Near(strip.ScrollBarThumb(0).X, track.X));
		strip.ScrollOffset = .(0.0f, 0.0f);
		strip.ScrollToEnd(.Instant);
		Test.Assert(Near(strip.ScrollOffset.X, -220.0f));

		// A vertical wheel notch down goes toward the inline end.
		strip.ScrollOffset = .(0.0f, 0.0f);
		let d = root.EventDispatcher;
		let over = strip.ConvertToRootSpace(.(50.0f, 20.0f));
		d.InjectMouseWheel(over, .(0.0f, -1.0f));
		Test.Assert(strip.ScrollOffset.X < 0.0f);

		// Content added at the end leaves the start where it was.
		strip.ScrollOffset = .(0.0f, 0.0f);
		PanelBox(strip, scope (s) =>
			{
				s.Width = LayoutLength.Px(80.0f);
				s.Shrink = 0.0f;
			});
		root.UpdateLayout();
		Test.Assert(Near(strip.ScrollOffset.X, 0.0f));
		Test.Assert(Near(strip.ScrollMin.X, -300.0f));
		Test.Assert(Near(cells[0].Position.X + 80.0f, area.X + area.Width));
	}
}
