using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The Splitter: panes laid out by their weights with a handle between each two; minimums held (a
/// sheet's, never the content's), the rest shared again; when even the minimums do not fit, each
/// has its own and the end is clipped; a handle moves the two panes beside it alone, by the
/// pointer and the keys; a pane that goes gives its share to its neighbours; vertical and right to
/// left.
class SplitterTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A new pane (of that minimum width when one is given), held by the caller.
	private static Panel Pane(float minWidth = -1.0f)
	{
		let pane = new Panel();
		if (minWidth >= 0.0f)
			pane.EditLayoutStyle(scope (s) => { s.MinWidth = LayoutLength.Px(minWidth); });
		return pane;
	}

	/// A root with a splitter 300 by 100 in it, its panes added. The root (and the tree) go with the
	/// bed.
	private class Bed
	{
		public SceneRoot Root = SceneFixtures.NewScene(800.0f, 600.0f) ~ _.ReleaseRef();
		public Sedulous.GUI.Splitter Splitter = new .() ~ _.ReleaseRef();
		public List<Panel> Panes = new .() ~ { for (let p in _) p.ReleaseRef(); delete _; };

		public this(int count, float width = 300.0f)
		{
			Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
			Splitter.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(width);
					s.Height = LayoutLength.Px(100.0f);
				});
			for (int i = 0; i < count; ++i)
			{
				Panes.Add(Pane());
				Splitter.AddChild(Panes.Back);
			}
			Root.AddChild(Splitter);
			Lay();
		}

		public void Lay() => Root.UpdateLayout();
		public float X(int pane) => Panes[pane].Position.X;
		public float W(int pane) => Panes[pane].Size.X;

		/// The splitter's weights now, the one at `index`.
		public float Weight(int index)
		{
			let weights = scope List<float>();
			Splitter.GetWeights(weights);
			return weights[index];
		}
	}

	[Test]
	public static void PanesByTheirWeightsAHandleBetweenEachTwoInThatOrder()
	{
		let bed = scope Bed(3);
		Test.Assert(bed.Splitter.PaneCount == 3);
		Test.Assert(bed.Splitter.ChildCount == 5); // pane, handle, pane, handle, pane
		Test.Assert(bed.Splitter.GetChildAt(0) == bed.Panes[0]);
		Test.Assert(bed.Splitter.GetChildAt(1) is SplitterHandle);
		Test.Assert(bed.Splitter.GetChildAt(2) == bed.Panes[1]);
		// 300 less two handles of 6: 96 each.
		Test.Assert(Near(bed.W(0), 96.0f));
		Test.Assert(Near(bed.W(1), 96.0f));
		Test.Assert(Near(bed.X(1), 102.0f));
		Test.Assert(Near(bed.X(2), 204.0f));
		Test.Assert(Near(bed.Panes[0].Size.Y, 100.0f));

		float[3] shares = .(1.0f, 2.0f, 1.0f);
		bed.Splitter.SetWeights(Span<float>(&shares[0], 3));
		bed.Lay();
		Test.Assert(Near(bed.W(0), 72.0f));
		Test.Assert(Near(bed.W(1), 144.0f));
		Test.Assert(Near(bed.Weight(1), 0.5f));
	}

	[Test]
	public static void APaneBelowItsMinimumHoldsItAndTheOthersShareTheRestPastTheRoomEachItsOwnClipped()
	{
		let bed = scope Bed(3);
		bed.Panes[0].EditLayoutStyle(scope (s) => { s.MinWidth = LayoutLength.Px(150.0f); });
		bed.Lay();
		Test.Assert(Near(bed.W(0), 150.0f));
		Test.Assert(Near(bed.W(1), 69.0f)); // (288 - 150) / 2
		Test.Assert(Near(bed.W(2), 69.0f));
		// Content wider than its share is no minimum: the user alone moves a handle (the pane wraps
		// or clips it where it stands).
		let wide = new Panel();
		defer wide.ReleaseRef();
		wide.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(120.0f); });
		bed.Panes[2].AddChild(wide);
		bed.Lay();
		Test.Assert(Near(bed.W(2), 69.0f));
		Test.Assert(Near(bed.W(1), 69.0f));
		bed.Panes[2].EditLayoutStyle(scope (s) => { s.MinWidth = LayoutLength.Px(120.0f); });
		bed.Lay();
		Test.Assert(Near(bed.W(2), 120.0f));
		Test.Assert(Near(bed.W(1), 18.0f)); // what is left
		// Minimums past the room: each has its own; what passes the end is clipped, never squeezed.
		bed.Panes[1].EditLayoutStyle(scope (s) => { s.MinWidth = LayoutLength.Px(100.0f); });
		bed.Lay();
		Test.Assert(Near(bed.W(0), 150.0f));
		Test.Assert(Near(bed.W(1), 100.0f));
		Test.Assert(Near(bed.W(2), 120.0f));
		Test.Assert(bed.Splitter.LayoutStyle.OverflowX == .Hidden);
	}

	[Test]
	public static void AHandleMovesTheTwoPanesBesideItAloneAsFarAsTheirMinimumsLetIt()
	{
		let bed = scope Bed(3);
		bed.Panes[1].EditLayoutStyle(scope (s) => { s.MinWidth = LayoutLength.Px(40.0f); });
		bed.Lay();
		int resized = 0;
		bed.Splitter.SetOnResized(new [&] () => { resized++; });
		bed.Splitter.MoveHandleTo(0, 120.0f); // the first pane to 120
		bed.Lay();
		Test.Assert(Near(bed.W(0), 120.0f));
		Test.Assert(Near(bed.W(1), 72.0f));
		Test.Assert(Near(bed.W(2), 96.0f)); // untouched
		Test.Assert(resized == 1);
		bed.Splitter.MoveHandleTo(0, 400.0f); // as far as the middle pane's minimum
		bed.Lay();
		Test.Assert(Near(bed.W(1), 40.0f));
		Test.Assert(Near(bed.W(0), 152.0f));
		Test.Assert(Near(bed.W(2), 96.0f));
	}

	[Test]
	public static void APaneThatGoesGivesItsShareToItsNeighboursOneThatComesTakesTheOthersAverage()
	{
		let bed = scope Bed(3);
		float[3] shares = .(1.0f, 2.0f, 3.0f);
		bed.Splitter.SetWeights(Span<float>(&shares[0], 3));
		bed.Lay();
		bed.Panes[1].RemoveFromParent(); // its 2 goes to the 1 and the 3, a quarter and three quarters
		bed.Lay();
		Test.Assert(bed.Splitter.PaneCount == 2);
		Test.Assert(bed.Splitter.ChildCount == 3);
		Test.Assert(Near(bed.Weight(0), 1.5f / 6.0f));
		Test.Assert(Near(bed.Weight(1), 4.5f / 6.0f));
		let more = Pane();
		defer more.ReleaseRef();
		bed.Splitter.AddChild(more);
		bed.Lay();
		Test.Assert(bed.Splitter.PaneCount == 3);
		Test.Assert(bed.Splitter.ChildCount == 5);
		Test.Assert(bed.Splitter.GetChildAt(3) is SplitterHandle); // before the new pane
		Test.Assert(bed.Splitter.GetChildAt(4) == more);
		// The newcomer's share is its given one (the third, 3) when it has one.
		Test.Assert(Near(bed.Weight(2), 3.0f / 9.0f));
	}

	[Test]
	public static void VerticalAndRightToLeftFromTheRight()
	{
		let bed = scope Bed(2);
		bed.Splitter.Axis = .Vertical;
		bed.Lay();
		Test.Assert(Near(bed.Panes[0].Size.Y, 47.0f)); // (100 - 6) / 2
		Test.Assert(Near(bed.Panes[1].Position.Y, 53.0f));
		Test.Assert(Near(bed.Panes[0].Size.X, 300.0f));
		Test.Assert(bed.Splitter.GetHandle(0).HasClass("vertical"));

		let rtl = scope Bed(2);
		rtl.Root.SetLayoutDirection(.RightToLeft);
		rtl.Lay();
		Test.Assert(Near(rtl.X(0), 153.0f)); // the first pane at the right
		Test.Assert(Near(rtl.X(1), 0.0f));
		rtl.Splitter.MoveHandleTo(0, 100.0f); // the handle dragged left: the first (right) pane grows
		rtl.Lay();
		Test.Assert(Near(rtl.W(0), 194.0f));
		Test.Assert(Near(rtl.W(1), 100.0f));
	}

	[Test]
	public static void AHandleMovesByTheKeysAndThePointerAndADoubleClickGivesTheSharesBack()
	{
		let bed = scope Bed(2);
		let handle = bed.Splitter.GetHandle(0);
		Test.Assert(handle != null);
		let d = bed.Root.EventDispatcher;
		handle.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Right);
		bed.Lay();
		Test.Assert(Near(bed.W(0), 155.0f)); // 147 + 8
		d.InjectKeyDown((uint32)KeyCode.Left, KeyModShift);
		bed.Lay();
		Test.Assert(Near(bed.W(0), 107.0f)); // less 48
		d.InjectKeyDown((uint32)KeyCode.Home); // as far toward the start as it goes
		bed.Lay();
		Test.Assert(Near(bed.W(0), 0.0f));

		// A drag: pressed in its middle, moved 50 to the right of where it now is.
		let at = handle.ScreenBounds;
		let middle = Float2(at.X + at.Width * 0.5f, at.Y + at.Height * 0.5f);
		d.InjectMouseMove(middle);
		d.InjectMouseDown(middle, .Left);
		d.InjectMouseMove(.(middle.X + 50.0f, middle.Y));
		d.InjectMouseUp(.(middle.X + 50.0f, middle.Y), .Left);
		bed.Lay();
		Test.Assert(Near(bed.W(0), 50.0f));
		// It keeps under the pointer through many moves, wherever the splitter stands on the screen.
		bed.Root.Padding = .(40.0f, 30.0f, 0.0f, 0.0f);
		bed.Lay();
		let from = handle.ScreenBounds;
		var pointer = Float2(from.X + 2.0f, from.Y + 10.0f);
		d.InjectMouseMove(pointer);
		d.InjectMouseDown(pointer, .Left);
		for (int step = 0; step < 10; ++step)
		{
			pointer.X += 7.0f;
			d.InjectMouseMove(pointer);
			bed.Lay();
			Test.Assert(Near(handle.ScreenBounds.X, pointer.X - 2.0f));
		}
		d.InjectMouseUp(pointer, .Left);
		Test.Assert(Near(bed.W(0), 120.0f)); // 50 + 70

		bed.Splitter.ResetWeights(); // what a double click does
		bed.Lay();
		Test.Assert(Near(bed.W(0), 147.0f));
	}

	[Test]
	public static void FromMarkupAndEachHandleReadAsASeparatorWithWhereItStands()
	{
		let loaded = MarkupFixtures.Load("<Splitter axis=\"vertical\" weights=\"1 3\"><Panel/><Panel/></Splitter>");
		Test.Assert(loaded != null);
		defer loaded.ReleaseRef();
		let splitter = loaded as Sedulous.GUI.Splitter;
		Test.Assert(splitter != null);
		Test.Assert(splitter.Axis == .Vertical);
		Test.Assert(splitter.PaneCount == 2);
		let weights = scope List<float>();
		splitter.GetWeights(weights);
		Test.Assert(Near(weights[1], 0.75f));

		let root = SceneFixtures.NewScene(400.0f, 406.0f);
		defer root.ReleaseRef();
		splitter.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(400.0f);
				s.Height = LayoutLength.Px(406.0f); // 400 for the panes, a quarter above the handle
			});
		root.AddChild(loaded);
		root.UpdateLayout();
		let tree = root.Context.BuildAccessTree(root);
		defer delete tree;
		AccessNode separator = null;
		for (let n in tree.Nodes)
		{
			if (n.Role == .Separator)
				separator = n;
		}
		Test.Assert(separator != null);
		Test.Assert(Math.Abs(separator.Max - 100.0) < 1e-5);
		Test.Assert(separator.Value == "25");
		Test.Assert((separator.States & AccessFocusable) != 0);
	}
}
