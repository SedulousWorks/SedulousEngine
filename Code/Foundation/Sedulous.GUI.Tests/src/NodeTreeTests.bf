using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A node that counts how many of its kind were freed.
class CountedNode : Node
{
	public static int sFreed = 0;

	public ~this()
	{
		sFreed++;
	}
}

/// A reflected element type markup may create.
[GuiReflect(true, "test-box")]
class TestBox : Node
{
}

/// Another type claiming the same tag.
[GuiReflect(true, "test-box")]
class OtherTestBox : Node
{
}

/// An action that cannot move its target: it invalidates it each update.
class QuietAction : Sedulous.GUI.Action
{
	public int Runs = 0;
	private bool mDone = false;

	public override void Start() { }

	public override void Stop()
	{
		mDone = true;
	}

	public override void Update(TimeSpan elapsed)
	{
		Runs++;
		Target.Invalidate();
	}

	public override bool IsDone => mDone;
	public override float CurrentProgress => 0.0f;
	public override TimeSpan TotalTime => default;
	public override bool CanMoveTarget => false;
}

/// What the node and layout slice does beyond the ported tests: the tree's edits and its
/// references, weak references through the element table, more of flex, grid, stack and dock,
/// min and max, the box sizing, scrolling, the dirty flags, the reflected properties, the
/// element registry, and actions ticking on a node.
class NodeTreeTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	private static TimeSpan Sec(double s) => TimeSpan((int64)(s * (double)TimeSpan.TicksPerSecond));

	private static bool Reaches(Rect r, Rect area) => (r.X <= area.Right) && (area.X <= r.Right) && (r.Y <= area.Bottom) && (area.Y <= r.Bottom);

	/// The children whose drawing reaches `area`, by asking each.
	private static void ReachingByWalk(Node parent, Rect area, List<Node> outNodes)
	{
		for (int i = 0; i < parent.ChildCount; i++)
		{
			let child = parent.GetChildAt(i);
			if (Reaches(child.Transform.TransformRect(child.SubtreeInk), area))
				outNodes.Add(child);
		}
	}

	private static bool SameNodes(List<Node> a, List<Node> b)
	{
		if (a.Count != b.Count)
			return false;
		for (int i = 0; i < a.Count; i++)
		{
			if (a[i] != b[i])
				return false;
		}
		return true;
	}

	// === The tree ===

	[Test]
	public static void TheTreeAddsAtAnIndexReordersAndEmpties()
	{
		let root = new Node();
		defer root.ReleaseRef();
		let a = new Node();
		defer a.ReleaseRef();
		let b = new Node();
		defer b.ReleaseRef();
		let c = new Node();
		defer c.ReleaseRef();
		let d = new Node();
		defer d.ReleaseRef();
		root.AddChild(a);
		root.AddChild(b);
		root.AddChild(c);
		root.AddChildAt(d, 1);
		Test.Assert((root.GetChildAt(0) == a) && (root.GetChildAt(1) == d) && (root.GetChildAt(2) == b) && (root.GetChildAt(3) == c));
		Test.Assert(d.Parent == root);
		Test.Assert(d.RootNode == root);
		Test.Assert(root.GetChildAt(4) == null);
		Test.Assert(root.GetChildAt(-1) == null);

		let generation = root.ChildrenGeneration;
		root.SetChildIndex(d, 1); // where it is: no change
		Test.Assert(root.ChildrenGeneration == generation);
		root.SetChildIndex(c, 0);
		Test.Assert(root.ChildrenGeneration != generation);
		Test.Assert((root.GetChildAt(0) == c) && (root.GetChildAt(1) == a));
		root.SetChildIndex(a, 99); // past the end: the last
		Test.Assert(root.LastChild == a);
		Test.Assert(c.PrevSibling == null);
		Test.Assert(a.NextSibling == null);

		root.AddChild(root); // not its own child
		root.AddChild(null);
		root.AddChild(b); // already a child: stays where it is
		Test.Assert(root.ChildCount == 4);
		Test.Assert(root.GetChildIndex(b) == 2);

		b.RemoveFromParent();
		Test.Assert((b.Parent == null) && (root.ChildCount == 3));
		b.RemoveFromParent(); // no parent: nothing
		root.RemoveChild(b); // not a child: nothing
		Test.Assert(root.ChildCount == 3);
		root.RemoveAllChildren();
		Test.Assert(root.ChildCount == 0);
		Test.Assert((a.Parent == null) && (c.Parent == null) && (d.Parent == null));
		Test.Assert(root.FirstChild == null);
	}

	[Test]
	public static void TheTreeHoldsOneReferenceToEachChildAndARemovedChildGoesWithItsLast()
	{
		CountedNode.sFreed = 0;
		let root = new Node();
		let child = new CountedNode();
		Test.Assert(child.RefCount == 1);
		root.AddChild(child);
		Test.Assert(child.RefCount == 2);
		root.RemoveChild(child);
		Test.Assert(child.RefCount == 1);
		Test.Assert(CountedNode.sFreed == 0);
		child.ReleaseRef();
		Test.Assert(CountedNode.sFreed == 1);

		// Held by the tree alone, a child and what it holds go with the tree.
		let held = new CountedNode();
		root.AddChild(held);
		held.ReleaseRef();
		let grandchild = new CountedNode();
		held.AddChild(grandchild);
		grandchild.ReleaseRef();
		Test.Assert(CountedNode.sFreed == 1);
		root.ReleaseRef();
		Test.Assert(CountedNode.sFreed == 3);
	}

	[Test]
	public static void CloseRemovesANodeAtTheQueuesDrainKeepingItUntilThen()
	{
		CountedNode.sFreed = 0;
		let root = new GuiRoot();
		defer root.ReleaseRef();
		let child = new CountedNode();
		root.AddChild(child);
		child.ReleaseRef(); // the tree's keeps it
		child.Close();
		Test.Assert(child.Parent == root); // not yet
		Test.Assert(child.RefCount == 2); // the tree's and the queued removal's
		root.Queue.Drain();
		Test.Assert(root.ChildCount == 0);
		Test.Assert(CountedNode.sFreed == 1);

		// With no queue it goes at once.
		let plain = new Node();
		defer plain.ReleaseRef();
		let other = new CountedNode();
		plain.AddChild(other);
		other.ReleaseRef();
		other.Destroy();
		Test.Assert(plain.ChildCount == 0);
		Test.Assert(CountedNode.sFreed == 2);
	}

	[Test]
	public static void AWeakReferenceReadsAsGoneOnceItsNodeIsAndItsSlotIsReusedUnderANewGeneration()
	{
		let root = new GuiRoot();
		defer root.ReleaseRef();
		let child = NodeFixtures.Box(root); // the tree's alone
		let handle = scope Element<Node>(child);
		Test.Assert(handle.Get() == child);
		Test.Assert(handle.IsValid);
		let elementRef = child.TakeElementRef();
		Test.Assert(elementRef.Table == root.Table);
		Test.Assert(elementRef.Slot == 1);
		Test.Assert(child.TakeElementRef().Slot == 1); // its slot, taken once
		Test.Assert(root.Table.Resolve(elementRef.Slot, elementRef.Generation) == child);
		root.RememberFocus(child);
		Test.Assert(root.RememberedFocus == child);

		root.RemoveChild(child); // its last reference: it goes, and its slot with it
		Test.Assert(handle.Get() == null);
		Test.Assert(!handle.IsValid);
		Test.Assert(root.RememberedFocus == null);
		Test.Assert(root.Table.Resolve(elementRef.Slot, elementRef.Generation) == null);
		Test.Assert(root.Table.Generation(elementRef.Slot) == elementRef.Generation + 1);

		let other = NodeFixtures.Box(root);
		let otherRef = other.TakeElementRef();
		Test.Assert(otherRef.Slot == elementRef.Slot); // the freed slot, under a new generation
		Test.Assert(otherRef.Generation == elementRef.Generation + 1);
		Test.Assert(handle.Get() == null); // the old handle does not reach the new node
		let otherHandle = scope Element<Node>(other);
		Test.Assert(otherHandle.Get() == other);

		root.Table.Close(); // its GUI is going: nothing resolves
		Test.Assert(root.Table.IsClosed);
		Test.Assert(otherHandle.Get() == null);

		// A node in no GUI has no table to take a slot in.
		let detached = new Node();
		defer detached.ReleaseRef();
		Test.Assert(detached.TakeElementRef().Table == null);
		let detachedHandle = scope Element<Node>(detached);
		Test.Assert(!detachedHandle.IsValid);
		let emptyHandle = scope Element<Node>();
		Test.Assert(!emptyHandle.IsValid);
	}

	// === Layout ===

	[Test]
	public static void AFlexColumnGrowsWithItsGapAndShrinksAnItemNoShorterThanItsMinimum()
	{
		let bed = scope Bed();
		let column = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Height = LayoutLength.Px(200.0f);
				s.RowGap = 10.0f;
			});
		let a = NodeFixtures.Box(column, scope (s) =>
			{
				s.Height = LayoutLength.Px(20.0f);
				s.Grow = 1.0f;
			});
		let b = NodeFixtures.Box(column, scope (s) =>
			{
				s.Height = LayoutLength.Px(20.0f);
				s.Grow = 4.0f;
			});
		bed.Layout();
		// 200 less the gap and the bases: 150 free, a fifth to a.
		NodeFixtures.CheckRect(a, 0, 0, 400, 50);
		NodeFixtures.CheckRect(b, 0, 60, 400, 140);

		column.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(100.0f); });
		a.EditLayoutStyle(scope (s) =>
			{
				s.Height = LayoutLength.Px(60.0f);
				s.Grow = 0.0f;
				s.MinHeight = LayoutLength.Px(55.0f);
			});
		b.EditLayoutStyle(scope (s) =>
			{
				s.Height = LayoutLength.Px(60.0f);
				s.Grow = 0.0f;
			});
		bed.Layout();
		// 30 over: half each would leave a at 45, so it freezes at 55 and b takes the rest.
		NodeFixtures.CheckRect(a, 0, 0, 400, 55);
		NodeFixtures.CheckRect(b, 0, 65, 400, 35);
	}

	[Test]
	public static void AColumnReversesWrappedLinesReverseAndAGapMayBeAPercentage()
	{
		let bed = scope Bed();
		let column = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Direction = .ColumnReverse;
				s.Height = LayoutLength.Px(100.0f);
			});
		let first = NodeFixtures.Fixed(column, 50.0f, 20.0f);
		let second = NodeFixtures.Fixed(column, 50.0f, 20.0f);
		bed.Layout();
		NodeFixtures.CheckRect(first, 0, 80, 50, 20); // from the end
		NodeFixtures.CheckRect(second, 0, 60, 50, 20);

		let wrapped = scope Bed();
		let flow = NodeFixtures.Box(wrapped.Root, scope (s) =>
			{
				s.Direction = .Row;
				s.Wrap = .WrapReverse;
				s.AlignContent = .Start;
			});
		let cells = scope List<Node>();
		for (int i = 0; i < 5; i++)
			cells.Add(NodeFixtures.Fixed(flow, 120.0f, 30.0f));
		wrapped.Layout();
		Test.Assert(Near(flow.Size.Y, 60.0f));
		NodeFixtures.CheckRect(cells[3], 0, 0, 120, 30); // the second line first
		NodeFixtures.CheckRect(cells[4], 120, 0, 120, 30);
		NodeFixtures.CheckRect(cells[0], 0, 30, 120, 30);
		NodeFixtures.CheckRect(cells[2], 240, 30, 120, 30);

		let gapped = scope Bed();
		let row = NodeFixtures.Box(gapped.Root, scope (s) =>
			{
				s.Direction = .Row;
				s.ColumnGapPercent = 10.0f;
			});
		NodeFixtures.Fixed(row, 50.0f, 20.0f);
		let after = NodeFixtures.Fixed(row, 50.0f, 20.0f);
		gapped.Layout();
		Test.Assert(Near(after.Position.X, 50.0f + 40.0f)); // 10% of the row's 400
	}

	/// A grid `width` wide of minmax(100px, 1fr) and 50px: the first track `expected` wide.
	private static void CheckMinmaxShare(float width, float expected)
	{
		let bed = scope Bed();
		let shared = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Kind = .Grid;
				s.Width = LayoutLength.Px(width);
				s.Columns.Add(GridTrack(LayoutLength.Px(100.0f), LayoutLength(), 1.0f));
				s.Columns.Add(GridTrack.Fixed(50.0f));
			});
		let left = NodeFixtures.Box(shared);
		let right = NodeFixtures.Box(shared);
		bed.Layout();
		Test.Assert(Near(left.Size.X, expected));
		Test.Assert(Near(right.Position.X, expected));
		Test.Assert(Near(right.Size.X, 50.0f));
	}

	[Test]
	public static void GridRowsSizeToTheirItemsAMinmaxKeepsItsMinimumAndItemsFlowDownColumns()
	{
		let bed = scope Bed();
		let grid = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Kind = .Grid;
				s.Columns.Add(GridTrack.Fixed(100.0f));
				s.Columns.Add(GridTrack.Fixed(100.0f));
				s.AlignItems = .Start;
			});
		let a = NodeFixtures.Box(grid, scope (s) => { s.Height = LayoutLength.Px(20.0f); });
		let b = NodeFixtures.Box(grid, scope (s) => { s.Height = LayoutLength.Px(40.0f); });
		let c = NodeFixtures.Box(grid, scope (s) => { s.Height = LayoutLength.Px(10.0f); });
		bed.Layout();
		NodeFixtures.CheckRect(a, 0, 0, 100, 20); // stretched across its column
		NodeFixtures.CheckRect(b, 100, 0, 100, 40);
		NodeFixtures.CheckRect(c, 0, 40, 100, 10); // the first row as tall as its tallest
		Test.Assert(Near(grid.Size.Y, 50.0f));

		// minmax(100px, 1fr) beside 50px: the share of what is left, never under 100.
		CheckMinmaxShare(400.0f, 350.0f);
		CheckMinmaxShare(120.0f, 100.0f);

		// A percentage track is of the grid's width; the fr track shares the rest.
		let percent = scope Bed();
		let quarter = NodeFixtures.Box(percent.Root, scope (s) =>
			{
				s.Kind = .Grid;
				s.Columns.Add(GridTrack(LayoutLength.Percent(25.0f), LayoutLength.Percent(25.0f), 0.0f));
				s.Columns.Add(GridTrack.Flex(1.0f));
			});
		let narrow = NodeFixtures.Box(quarter);
		let rest = NodeFixtures.Box(quarter);
		percent.Layout();
		Test.Assert(Near(narrow.Size.X, 100.0f));
		Test.Assert(Near(rest.Position.X, 100.0f));
		Test.Assert(Near(rest.Size.X, 300.0f));

		// Flowing by column: down the two rows, then across.
		let flowed = scope Bed();
		let byColumn = NodeFixtures.Box(flowed.Root, scope (s) =>
			{
				s.Kind = .Grid;
				s.AutoFlow = .Column;
				s.Rows.Add(GridTrack.Fixed(20.0f));
				s.Rows.Add(GridTrack.Fixed(20.0f));
			});
		let first = NodeFixtures.Fixed(byColumn, 30.0f, 20.0f);
		let second = NodeFixtures.Fixed(byColumn, 30.0f, 20.0f);
		let third = NodeFixtures.Fixed(byColumn, 30.0f, 20.0f);
		flowed.Layout();
		NodeFixtures.CheckRect(first, 0, 0, 30, 20);
		NodeFixtures.CheckRect(second, 0, 20, 30, 20);
		NodeFixtures.CheckRect(third, 30, 0, 30, 20);
	}

	[Test]
	public static void AStackAlignsAChildInsideItsMarginsAndADockedSideKeepsItsMargins()
	{
		let bed = scope Bed();
		let stack = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Kind = .Stack;
				s.Width = LayoutLength.Px(200.0f);
				s.Height = LayoutLength.Px(100.0f);
			});
		let child = NodeFixtures.Box(stack, scope (s) =>
			{
				s.Width = LayoutLength.Px(50.0f);
				s.Height = LayoutLength.Px(20.0f);
				s.Margin = Thickness(10.0f);
				s.JustifySelf = .End;
				s.AlignSelf = .Center;
			});
		let dock = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Kind = .Dock;
				s.Width = LayoutLength.Px(200.0f);
				s.Height = LayoutLength.Px(100.0f);
			});
		let side = NodeFixtures.Box(dock, scope (s) =>
			{
				s.DockSide = .Left;
				s.Width = LayoutLength.Px(30.0f);
				s.Margin = Thickness(5.0f);
			});
		let fill = NodeFixtures.Box(dock);
		bed.Layout();
		NodeFixtures.CheckRect(child, 140, 40, 50, 20); // 10 in from the right; centred in the 80 left between its margins
		NodeFixtures.CheckRect(side, 5, 5, 30, 90); // the side's length less its margins
		NodeFixtures.CheckRect(fill, 40, 0, 160, 100); // what the side and its margins left
	}

	[Test]
	public static void PercentagesAreOfTheContainerMinAndMaxHoldAndABasisSetsTheMainSize()
	{
		let bed = scope Bed();
		let parent = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Width = LayoutLength.Px(300.0f);
				s.Height = LayoutLength.Px(200.0f);
			});
		let child = NodeFixtures.Box(parent, scope (s) =>
			{
				s.Width = LayoutLength.Percent(50.0f);
				s.Height = LayoutLength.Percent(25.0f);
			});
		bed.Layout();
		NodeFixtures.CheckRect(child, 0, 0, 150, 50);

		child.EditLayoutStyle(scope (s) =>
			{
				s.MaxWidth = LayoutLength.Px(100.0f);
				s.MinHeight = LayoutLength.Px(80.0f);
			});
		let based = NodeFixtures.Box(parent, scope (s) =>
			{
				s.Basis = LayoutLength.Px(70.0f);
				s.Height = LayoutLength.Px(20.0f);
			});
		bed.Layout();
		NodeFixtures.CheckRect(child, 0, 0, 100, 80);
		Test.Assert(Near(based.Position.Y, 80.0f));
		Test.Assert(Near(based.Size.Y, 70.0f)); // the basis, over its height
	}

	[Test]
	public static void ContentBoxSizingAddsThePaddingAndBorderAndMarginsKeepTheirSides()
	{
		let bed = scope Bed();
		let border = scope NodeBox();
		border.BorderWidths = BorderWidths(5.0f);
		let content = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.Width = LayoutLength.Px(100.0f);
				s.Sizing = .ContentBox;
			});
		content.Padding = Thickness(10.0f);
		content.SetBox(border);
		let borderBox = NodeFixtures.Box(bed.Root, scope (s) => { s.Width = LayoutLength.Px(100.0f); });
		borderBox.Padding = Thickness(10.0f);
		borderBox.SetBox(border);
		bed.Layout();
		Test.Assert(content.Chrome == Thickness(15.0f));
		Test.Assert(Near(content.Size.X, 130.0f)); // its width is the content's
		Test.Assert(Near(content.Size.Y, 30.0f)); // nothing in it: its chrome
		Test.Assert(content.ContentBounds == Rect(15.0f, 15.0f, 100.0f, 0.0f));
		Test.Assert(Near(borderBox.Size.X, 100.0f)); // its width holds the chrome
		Test.Assert(borderBox.ContentBounds == Rect(15.0f, 15.0f, 70.0f, 0.0f));

		let spaced = scope Bed();
		let item = NodeFixtures.Box(spaced.Root, scope (s) => { s.Height = LayoutLength.Px(10.0f); });
		item.Margin = Thickness(7.0f, 3.0f, 9.0f, 0.0f);
		spaced.Layout();
		NodeFixtures.CheckRect(item, 7, 3, 384, 10);
		item.EditLayoutStyle(scope (s) => { s.MarginPercent = Thickness(10.0f, 0.0f, 0.0f, 0.0f); });
		spaced.Layout();
		Test.Assert(Near(item.GetMarginWithin(400.0f).Left, 47.0f)); // its length and 10% of 400
		NodeFixtures.CheckRect(item, 47, 3, 344, 10);
	}

	// === Scrolling ===

	[Test]
	public static void OverflowClipsAScrollerMovesItsChildrenAndItsBarsShowItsRange()
	{
		let bed = scope Bed(300.0f, 300.0f);
		let clipped = NodeFixtures.Box(bed.Root, scope (s) => { s.OverflowY = .Hidden; });
		Test.Assert(clipped.ClipsChildren);
		Test.Assert(!clipped.IsScrollContainer);
		clipped.EditLayoutStyle(scope (s) => { s.OverflowY = .Auto; });
		Test.Assert(clipped.IsScrollContainer);

		let view = NodeFixtures.Box(bed.Root, scope (s) =>
			{
				s.OverflowX = .Auto;
				s.OverflowY = .Auto;
			});
		view.Position = .(0.0f, 0.0f);
		view.Size = .(100.0f, 100.0f);
		let rows = scope List<Node>();
		for (int i = 0; i < 6; i++)
			rows.Add(NodeFixtures.Box(view, scope (s) => { s.Height = LayoutLength.Px(50.0f); }));
		bed.Layout();
		Test.Assert(view.ContentExtent == Float2(0.0f, 300.0f));
		Test.Assert(view.ScrollRange == Float2(0.0f, 200.0f));
		Test.Assert(view.ScrollBarTrack(1) == Rect(92.0f, 0.0f, 8.0f, 100.0f)); // on the inline end, the whole height
		Test.Assert(view.ScrollBarTrack(0) == Rect()); // nothing to scroll across
		let thumb = view.ScrollBarThumb(1);
		Test.Assert(Near(thumb.Height, 100.0f / 3.0f)); // the view's share of the content
		Test.Assert(Near(thumb.Y, 0.0f));

		view.ScrollOffset = .(0.0f, 200.0f);
		Test.Assert(Near(view.ScrollBarThumb(1).Y, 100.0f - 100.0f / 3.0f));
		Test.Assert(Near(rows[2].ScreenBounds.Y, 100.0f - 200.0f)); // moved, not laid out again
		Test.Assert(Near(rows[2].Position.Y, 100.0f));
		Test.Assert(view.IsAtScrollEnd);
		view.ScrollOffset = .(0.0f, 10.4f);
		Test.Assert(view.ScrollShift == Float2(0.0f, 10.0f)); // on the device grid
		Test.Assert(Near(rows[0].ScreenPosition.Y, -10.0f));

		view.ScrollOffset = .(0.0f, -5.0f);
		Test.Assert(Near(view.ScrollOffset.Y, 0.0f)); // kept within the range
		view.ScrollOffset = .(0.0f, 999.0f);
		Test.Assert(Near(view.ScrollOffset.Y, 200.0f));
		rows.Add(NodeFixtures.Box(view, scope (s) => { s.Height = LayoutLength.Px(50.0f); }));
		view.ScrollOffset = .(0.0f, 260.0f); // a layout pending: kept as asked
		Test.Assert(Near(view.ScrollOffset.Y, 260.0f));
		bed.Layout();
		Test.Assert(Near(view.ScrollOffset.Y, 250.0f)); // the new range's end

		// Smooth with no clock: there at once.
		view.EditLayoutStyle(scope (s) => { s.Scrolling = .Smooth; });
		view.ScrollTo(.(0.0f, 100.0f));
		Test.Assert(Near(view.ScrollOffset.Y, 100.0f));
		Test.Assert(!view.IsSmoothScrolling);
	}

	[Test]
	public static void ASmoothScrollAndAFlingRunOnTheGuisClock()
	{
		let root = new GuiRoot();
		defer root.ReleaseRef();
		root.Size = .(300.0f, 300.0f);
		let view = NodeFixtures.Box(root, scope (s) => { s.OverflowY = .Auto; });
		view.Position = .(0.0f, 0.0f);
		view.Size = .(100.0f, 100.0f);
		for (int i = 0; i < 6; i++)
			NodeFixtures.Box(view, scope (s) => { s.Height = LayoutLength.Px(50.0f); });
		root.UpdateLayout();

		view.ScrollTo(.(0.0f, 100.0f), .Smooth);
		Test.Assert(view.IsSmoothScrolling);
		Test.Assert(Near(view.ScrollOffset.Y, 0.0f));
		Test.Assert(Near(view.ScrollTarget.Y, 100.0f));
		Test.Assert(root.Actions.Count == 1);
		root.Actions.Update(Sec(1.0)); // far past its time constant: arrived
		Test.Assert(Near(view.ScrollOffset.Y, 100.0f));
		Test.Assert(!view.IsSmoothScrolling);
		Test.Assert(root.Actions.Count == 0);

		view.ScrollOffset = .(0.0f, 0.0f);
		view.Fling(.(0.0f, 1000.0f));
		Test.Assert(view.IsFlinging);
		root.Actions.Update(Sec(0.05));
		Test.Assert(view.ScrollOffset.Y > 0.0f); // gliding
		root.Actions.Update(Sec(10.0)); // its whole glide, held at the end
		Test.Assert(Near(view.ScrollOffset.Y, 200.0f));
		Test.Assert(!view.IsFlinging);
		Test.Assert(root.Actions.Count == 0);
	}

	// === What a frame must redo ===

	[Test]
	public static void ALayoutRequestMarksTheContainersItReachesAndAFixedSizeStopsIt()
	{
		let bed = scope Bed();
		let page = NodeFixtures.Box(bed.Root);
		let leaf = NodeFixtures.Fixed(page, 30.0f, 30.0f);
		bed.Layout();
		Test.Assert(!bed.Root.IsLayoutDirty && !bed.Root.HasLayoutDirtyDescendant);
		Test.Assert(!page.IsLayoutDirty && !leaf.IsLayoutDirty);

		leaf.Size = .(30.0f, 70.0f);
		Test.Assert(leaf.IsLayoutDirty);
		Test.Assert(page.IsLayoutDirty && page.HasLayoutDirtyDescendant);
		Test.Assert(bed.Root.IsLayoutDirty && bed.Root.HasLayoutDirtyDescendant); // its size follows its content
		bed.Layout();
		Test.Assert(!bed.Root.IsLayoutDirty && !bed.Root.HasLayoutDirtyDescendant && !page.IsLayoutDirty && !leaf.IsLayoutDirty);

		page.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(100.0f);
				s.Height = LayoutLength.Px(100.0f);
			});
		bed.Layout();
		leaf.Size = .(30.0f, 40.0f);
		Test.Assert(page.IsLayoutDirty);
		Test.Assert(!bed.Root.IsLayoutDirty); // the page's size does not follow it
		Test.Assert(bed.Root.HasLayoutDirtyDescendant); // the pass still finds the page
	}

	[Test]
	public static void StyleAndRedrawMarksReachTheAncestorsAHiddenOrQuietNodeMarksItselfAlone()
	{
		let root = new Node();
		defer root.ReleaseRef();
		root.Size = .(100.0f, 100.0f);
		let child = NodeFixtures.Box(root);
		child.Size = .(40.0f, 40.0f);
		Test.Assert(child.IsStyleDirty && child.IsStyleSubtreeDirty); // a node starts dirty

		root.ClearStyleDirty();
		child.ClearStyleDirty();
		child.MarkStyleDirty(false);
		Test.Assert(child.IsStyleDirty && !child.IsStyleSubtreeDirty);
		Test.Assert(root.HasStyleDirtyDescendant && !root.IsStyleDirty);
		root.ClearStyleDirty();
		child.ClearStyleDirty();
		child.Hovered = true;
		Test.Assert((child.ChangedStyleStates & (Node.StateHover | Node.StateActive)) == (Node.StateHover | Node.StateActive));
		child.ClearStyleDirty();
		child.ForcedStyleStates = Node.StateDisabled;
		Test.Assert(child.ChangedStyleStates == (Node.StateDisabled | Node.StateEnabled)); // what it turns with it
		child.ForcedStyleStates = Node.StateDisabled; // the same: no change
		Test.Assert(child.ForcedStyleStates == Node.StateDisabled);
		root.ClearStyleDirty();
		NodeFixtures.Box(root);
		Test.Assert(root.ChildrenArrangementChanged && root.IsStyleDirty);

		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		root.Draw(dc);
		Test.Assert(!root.NeedsRedraw && !child.NeedsRedraw);
		child.Alpha = 0.5f;
		Test.Assert(child.NeedsRedraw && root.NeedsRedraw);
		root.Draw(dc);
		child.Visible = false; // where it showed must draw again
		Test.Assert(root.NeedsRedraw);
		root.Draw(dc);
		child.Alpha = 0.3f; // hidden: nothing on screen changes
		Test.Assert(child.NeedsRedraw && !root.NeedsRedraw);

		child.Visible = true;
		root.Draw(dc);
		child.BeginQuietInvalidation();
		child.Alpha = 0.2f;
		Test.Assert(child.NeedsRedraw && !root.NeedsRedraw);
		child.EndQuietInvalidation();
		child.Alpha = 0.1f;
		Test.Assert(root.NeedsRedraw);
	}

	[Test]
	public static void CodePinsWhatItSetsAWriteScopeDoesNotAndTheOwnValuesAreCapturedOnce()
	{
		let node = new Node();
		defer node.ReleaseRef();
		node.Alpha = 0.5f;
		Test.Assert(node.IsStylePinned(.SlotOpacity));
		using (Node.StyleWriteScope(node))
		{
			Test.Assert(node.IsStyleWriting);
			node.Padding = Thickness(4.0f);
		}
		Test.Assert(!node.IsStyleWriting);
		Test.Assert(!node.IsStylePinned(.SlotPaddingTop)); // the scope's: a sheet's or a default
		node.Padding = Thickness(4.0f);
		Test.Assert(node.IsStylePinned(.SlotPaddingTop) && node.IsStylePinned(.SlotPaddingLeft));
		node.ClearStyleDirty();
		node.UnpinStyle(SlotBit(.SlotOpacity));
		Test.Assert(!node.IsStylePinned(.SlotOpacity));
		Test.Assert(node.IsStyleDirty); // the sheet sets it again

		node.EditLayoutStyle(scope (s) => { s.Grow = 2.0f; });
		Test.Assert(node.IsStylePinned(.SlotFlexGrow));
		Test.Assert(!node.IsStylePinned(.SlotFlexShrink)); // only what changed is code's
		node.Size = .(10.0f, 20.0f);
		Test.Assert(node.IsStylePinned(.SlotWidth) && node.IsStylePinned(.SlotHeight));
		Test.Assert(node.LayoutStyle.Width == LayoutLength.Px(10.0f));

		let own = node.CaptureUnstyledValues();
		Test.Assert(own.Captured && (own.Alpha == 0.5f) && (own.Padding == Thickness(4.0f)));
		Test.Assert(own.Layout.Grow == 2.0f);
		node.Alpha = 1.0f;
		Test.Assert(node.CaptureUnstyledValues().Alpha == 0.5f); // captured once
	}

	[Test]
	public static void AManyChildrenIndexFindsWhatAWalkFindsAndIsBuiltAgainOnlyWhenAReachMoved()
	{
		let bed = scope Bed();
		let column = NodeFixtures.Box(bed.Root, scope (s) => { s.Placement = .Absolute; });
		for (int i = 0; i < 40; i++)
			NodeFixtures.Fixed(column, 100.0f, 20.0f);
		bed.Layout();
		let area = Rect(0.0f, 105.0f, 10.0f, 30.0f);
		let indexed = scope List<Node>();
		column.ChildrenReaching(area, indexed);
		Test.Assert((indexed.Count == 2) && (indexed[0] == column.GetChildAt(5)) && (indexed[1] == column.GetChildAt(6)));
		let walked = scope List<Node>();
		ReachingByWalk(column, area, walked);
		Test.Assert(SameNodes(indexed, walked));
		Test.Assert(column.ChildIndexBuilds == 1);
		Test.Assert(bed.Root.OverFind(.(10.0f, 110.0f)) == column.GetChildAt(5));

		// A child fades: something under the column changed, but no reach moved.
		column.GetChildAt(5).Alpha = 0.5f;
		indexed.Clear();
		column.ChildrenReaching(area, indexed);
		Test.Assert(column.ChildIndexBuilds == 1);

		// A child moved out of order: built again, and still agreeing.
		column.GetChildAt(3).Position = .(20.0f, 500.0f);
		let far = Rect(0.0f, 505.0f, 40.0f, 5.0f);
		indexed.Clear();
		column.ChildrenReaching(far, indexed);
		walked.Clear();
		ReachingByWalk(column, far, walked);
		Test.Assert(column.ChildIndexBuilds == 2);
		Test.Assert(SameNodes(indexed, walked));
		Test.Assert(indexed.Contains(column.GetChildAt(3)));
	}

	// === Reflection ===

	[Test]
	public static void ANodesReflectedPropertiesAreReadAndSetByTheirNames()
	{
		let info = Node.StaticGuiType;
		Test.Assert(info.Tag == "Node");
		Test.Assert(!info.CanCreate); // a plain node is no element
		let node = new Node();
		defer node.ReleaseRef();
		Test.Assert(node.GuiType == info);

		Test.Assert(info.Find("opacity").Set(node, System.Variant.Create(0.5f)));
		Test.Assert(node.Alpha == 0.5f);
		Test.Assert(node.IsStylePinned(.SlotOpacity));
		Test.Assert(info.Find("width").Set(node, System.Variant.Create(120)));
		Test.Assert(node.Size.X == 120.0f);
		Test.Assert(node.IsStylePinned(.SlotWidth));
		Test.Assert(info.Find("x").Set(node, System.Variant.Create(15.0f)));
		Test.Assert(node.Position.X == 15.0f);
		Test.Assert(info.Find("visible").Set(node, System.Variant.Create(false)));
		Test.Assert(!node.Visible);
		Test.Assert(info.Find("displayed").CanWrite);

		var pointer = System.Variant.Create(StringView("pointer"));
		defer pointer.Dispose();
		Test.Assert(info.FindCss("cursor").Set(node, pointer));
		Test.Assert(node.Cursor == .Pointer);
		var cursor = info.FindCss("cursor").Get(node);
		Test.Assert(TextOf(cursor) == "pointer");
		cursor.Dispose();

		var save = System.Variant.Create(StringView("save"));
		defer save.Dispose();
		Test.Assert(info.FindCss("nav-up").Set(node, save));
		Test.Assert(node.NavUp == "save");
		Test.Assert(info.Find("navUp") == info.FindCss("nav-up")); // by its own name too

		var rtl = System.Variant.Create(StringView("rtl"));
		defer rtl.Dispose();
		Test.Assert(info.Find("direction").Set(node, rtl));
		Test.Assert(node.IsRightToLeft);

		var pans = System.Variant.Create(StringView("pan-x pan-y"));
		defer pans.Dispose();
		Test.Assert(info.FindCss("touch-action").Set(node, pans));
		Test.Assert(node.TouchActions == (cTouchPanX | cTouchPanY));
		var touch = info.FindCss("touch-action").Get(node);
		Test.Assert(TextOf(touch) == "pan-x pan-y");
		touch.Dispose();

		Test.Assert(info.FindCss("tab-index").Set(node, System.Variant.Create(3)));
		Test.Assert(node.TabIndex == 3);
		var types = System.Variant.Create(StringView("text files"));
		defer types.Dispose();
		Test.Assert(info.FindCss("drop-types").Set(node, types));
		Test.Assert(node.TakesDropType("files") && !node.TakesDropType("gui/tab"));
		Test.Assert(info.FindCss("stick-to-end") != null);
		Test.Assert(info.FindCss("mirror-on-rtl") != null);

		// A reflected element type answers for itself, its base's properties found through it.
		Test.Assert(TestBox.StaticGuiType.Base == info);
		Test.Assert(TestBox.StaticGuiType.CanCreate);
		let made = new TestBox();
		defer made.ReleaseRef();
		Node asNode = made;
		Test.Assert(asNode.GuiType == TestBox.StaticGuiType);
		Test.Assert(TestBox.StaticGuiType.FindCss("nav-up") != null);
	}

	[Test]
	public static void TheRegistryKnowsElementTypesByTagAndASetCreatesWhatItAllows()
	{
		let type = TestBox.StaticGuiType;
		Test.Assert(ElementTypes.Register(type));
		defer ElementTypes.Unregister(type);
		Test.Assert(ElementTypes.Register(type)); // registered already
		Test.Assert(!ElementTypes.Register(OtherTestBox.StaticGuiType)); // its tag is taken
		Test.Assert(!ElementTypes.Register(Node.StaticGuiType)); // no creator
		Test.Assert(ElementTypes.Find("test-box") == type);
		Test.Assert(ElementTypes.TagOf(type) == "test-box");
		int seen = 0;
		ElementTypes.ForEach(scope [&](tag, t) =>
			{
				if (t == type)
					seen++;
			});
		Test.Assert(seen == 1);

		let all = ElementSet.All();
		defer delete all;
		let made = all.Create("test-box");
		Test.Assert(made is TestBox);
		Test.Assert(made.RefCount == 1);
		made.ReleaseRef();
		Test.Assert(all.Create("no-such-element") == null);

		let some = ElementSet.None();
		defer delete some;
		Test.Assert(some.Resolve("test-box") == null); // not allowed yet
		some.Alias("tb", "test-box");
		Test.Assert(some.Resolve("tb") == null);
		some.Allow("test-box");
		Test.Assert(some.Resolve("tb") == type);
		let copy = scope ElementSet();
		copy.Set(some);
		let byAlias = copy.Create("tb");
		Test.Assert(byAlias is TestBox);
		byAlias.ReleaseRef();
	}

	// === Actions and events ===

	[Test]
	public static void AnActionTicksOnItsNodesClockAndIsDroppedWhenTheNodeGoes()
	{
		let root = new GuiRoot();
		defer root.ReleaseRef();
		let child = NodeFixtures.Box(root); // the tree's alone
		int ticks = 0;
		double seconds = 0.0;
		let tick = new TickAction(new [&](elapsed) =>
			{
				ticks++;
				seconds += elapsed.TotalSeconds;
				return true;
			});
		child.RunAction(tick);
		Test.Assert(tick.Target == child);
		Test.Assert(tick.ResolveTarget() == child);
		Test.Assert(tick.RefCount == 2); // the manager's beside the maker's
		tick.ReleaseRef();
		Test.Assert(root.Actions.Count == 1);

		root.Actions.Update(Sec(0.1));
		Test.Assert((ticks == 1) && (Math.Abs(seconds - 0.1) < 1e-6));
		root.Actions.Update(Sec(0.5), scope (target) => 0.5f); // its root slowed to half
		Test.Assert((ticks == 2) && (Math.Abs(seconds - 0.35) < 1e-6));
		root.Actions.Update(Sec(0.5), scope (target) => 0.0f); // paused
		Test.Assert(ticks == 2);
		Test.Assert(root.Actions.AnyAction(scope [&](action, target) => target == child));

		root.RemoveChild(child); // its last reference: it goes
		root.Actions.Update(Sec(0.1));
		Test.Assert(ticks == 2); // not run on what is gone
		Test.Assert(root.Actions.Count == 0);

		// Two on one node are taken off it together.
		let other = NodeFixtures.Box(root);
		for (int i = 0; i < 2; i++)
		{
			let more = new TickAction(new (elapsed) => true);
			other.RunAction(more);
			more.ReleaseRef();
		}
		Test.Assert(root.Actions.Count == 2);
		Test.Assert(root.Actions.RemoveAllActionsFromTarget(other));
		Test.Assert(root.Actions.Count == 0);
		Test.Assert(!root.Actions.RemoveAllActionsFromTarget(other));

		// In no GUI an action is targeted, then dropped.
		let detached = new Node();
		defer detached.ReleaseRef();
		let dropped = new TickAction(null);
		detached.RunAction(dropped);
		Test.Assert(dropped.Target == detached);
		Test.Assert(dropped.RefCount == 1);
		dropped.ReleaseRef();
	}

	[Test]
	public static void AnActionThatCannotMoveItsTargetOutOfViewAsksForNoFrame()
	{
		let root = new GuiRoot();
		defer root.ReleaseRef();
		root.LastFrame = 5; // the child was not drawn in it: out of view
		let child = NodeFixtures.Box(root);
		Test.Assert(child.WasOutOfView);
		let quiet = new QuietAction();
		child.RunAction(quiet);
		quiet.ReleaseRef(); // the manager's keeps it
		root.ClearNeedsRedraw();
		child.ClearNeedsRedraw();
		root.Actions.Update(Sec(0.1));
		Test.Assert(quiet.Runs == 1);
		Test.Assert(child.NeedsRedraw && !root.NeedsRedraw);

		let moving = new TickAction(new [&](elapsed) =>
			{
				child.Invalidate();
				return false;
			});
		child.RunAction(moving);
		moving.ReleaseRef();
		root.Actions.Update(Sec(0.1));
		Test.Assert(root.NeedsRedraw); // it may bring the child into view: it asks
	}

	[Test]
	public static void EventsCarryTheirTargetFocusReachesTheAncestorsAndARouteStepRunsItsPhase()
	{
		let root = new Node();
		defer root.ReleaseRef();
		let child = NodeFixtures.Box(root);
		Node focusTarget = null;
		child.AddEventListener(.FocusGained, new [&](e) => { focusTarget = e.Target; });
		child.HandleFocusGained();
		Test.Assert(focusTarget == child);
		Test.Assert(child.IsFocused && root.IsFocusWithin && !root.IsFocused);
		child.HandleFocusLost();
		Test.Assert(!child.IsFocused && !root.IsFocusWithin);

		int captured = 0;
		int bubbled = 0;
		Node current = null;
		root.AddEventListener(.MouseDown, new [&](e) =>
			{
				captured++;
				current = e.CurrentTarget;
			}, true);
		root.AddEventListener(.MouseDown, new [&](e) => { bubbled++; });
		let down = scope MouseEvent(.MouseDown, child, .(1.0f, 1.0f));
		Test.Assert((down.Target == child) && (down.CurrentTarget == child));
		down.Phase = .Capture;
		root.DeliverRouted(down);
		Test.Assert((captured == 1) && (bubbled == 0) && (current == root));
		down.Phase = .Bubble;
		root.DeliverRouted(down);
		Test.Assert((captured == 1) && (bubbled == 1));

		int named = 0;
		root.AddNamedListener("screenenter", new [&](e) =>
			{
				named++;
				Test.Assert(((NamedEvent)e).Detail == "home");
			});
		root.SendNamedEvent("screenenter", "home");
		root.SendNamedEvent("screenleave");
		Test.Assert(named == 1);

		let request = scope DragRequest();
		let preview = new Node();
		defer preview.ReleaseRef();
		request.Preview = preview;
		Test.Assert(preview.RefCount == 2); // the request holds it
		request.Preview = null;
		Test.Assert(preview.RefCount == 1);
		request.Preview = preview;
		let result = DragResult();
		Test.Assert(result.Target == null);
	}
}
