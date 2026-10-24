using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Scrolling: any node that scrolls (overflow: scroll or auto), its range over the laid-out
/// content, the content moving without a new layout, a descendant brought into view, the extent
/// following the content, and the end it sticks to.
class ScrollTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A 100 x 100 scroller at the root's corner (as a ScrollView: overflow auto on both axes, a
	/// tab stop) holding `count` 50-high rows. The root holds the tree; it goes with the scroller.
	private class Scroller
	{
		public Node Root = new .() ~ _.ReleaseRef();
		public Node View;
		public List<Node> Rows = new .() ~ delete _;

		public this(int count = 6)
		{
			Root.Size = .(300.0f, 300.0f);
			View = NodeFixtures.Box(Root, scope (s) =>
				{
					s.OverflowX = .Auto;
					s.OverflowY = .Auto;
				});
			View.TabFocusable = true;
			View.Position = .(0.0f, 0.0f);
			View.Size = .(100.0f, 100.0f);
			for (int i = 0; i < count; i++)
				AddRow();
			Root.UpdateLayout();
		}

		public Node AddRow()
		{
			let row = NodeFixtures.Box(View, scope (s) => { s.Height = LayoutLength.Px(50.0f); });
			row.TabFocusable = true;
			Rows.Add(row);
			return row;
		}

		public void WidenRows()
		{
			for (let row in Rows)
				row.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(80.0f); });
			Root.UpdateLayout();
		}
	}

	[Test]
	public static void TheExtentFollowsTheContentAsItGrowsAndShrinksTheOffsetStaysInRange()
	{
		let s = scope Scroller(2);
		Test.Assert(Near(s.View.ScrollRange.Y, 0.0f));
		s.Rows[1].EditLayoutStyle(scope (st) => { st.Height = LayoutLength.Px(250.0f); }); // a child styled taller later
		s.Root.UpdateLayout();
		Test.Assert(Near(s.View.ScrollRange.Y, 200.0f));
		s.View.ScrollOffset = .(0.0f, 200.0f);
		s.Rows[1].Displayed = false;
		s.Root.UpdateLayout();
		Test.Assert(Near(s.View.ScrollOffset.Y, 0.0f));
	}

	[Test]
	public static void AScrollReportsToTheScrollersOwnListenersOncePerMove()
	{
		let s = scope Scroller();
		int scrolls = 0;
		s.View.AddEventListener(.Scroll, new [&](e) => { scrolls++; });
		s.View.ScrollOffset = .(0.0f, 40.0f);
		Test.Assert(scrolls == 1);
		s.View.ScrollOffset = .(0.0f, 40.0f); // no move
		Test.Assert(scrolls == 1);
		s.View.ScrollBy(.(0.0f, 1000.0f)); // to the end, clamped
		Test.Assert(scrolls == 2);
		Test.Assert(Near(s.View.ScrollOffset.Y, 200.0f));
	}

	[Test]
	public static void TheHandleScrollsToAnOffsetToTheEndAndADescendantToAnAlignment()
	{
		let s = scope Scroller(10); // 500 tall in a 100 view: a range of 400
		s.View.ScrollToEnd();
		Test.Assert(Near(s.View.ScrollOffset.Y, 400.0f));
		s.View.ScrollTo(.(0.0f, 0.0f));
		s.View.ScrollIntoView(s.Rows[4], .Start); // row 4 at 200
		Test.Assert(Near(s.View.ScrollOffset.Y, 200.0f));
		s.Root.UpdateLayout();
		s.View.ScrollIntoView(s.Rows[4], .End); // its bottom (250) at the view's
		Test.Assert(Near(s.View.ScrollOffset.Y, 150.0f));
		s.Root.UpdateLayout();
		s.View.ScrollIntoView(s.Rows[4], .Center); // its middle (225) at the view's
		Test.Assert(Near(s.View.ScrollOffset.Y, 175.0f));
		s.Root.UpdateLayout();
		s.View.ScrollIntoView(s.Rows[4]); // already shown: no move
		Test.Assert(Near(s.View.ScrollOffset.Y, 175.0f));
	}

	[Test]
	public static void StuckToItsEndItFollowsTheContentScrolledAwayItLetsGoAndBackItHoldsAgain()
	{
		let s = scope Scroller(1); // 50 of content in a 100 view: at its end
		s.View.StickToEnd = true;
		Test.Assert(s.View.IsLatchedToEnd);
		void AddRows(int count)
		{
			for (int i = 0; i < count; i++)
				s.AddRow();
			s.Root.UpdateLayout();
		}
		AddRows(3); // 200 of content: the end is 100
		Test.Assert(Near(s.View.ScrollOffset.Y, 100.0f));
		AddRows(1);
		Test.Assert(Near(s.View.ScrollOffset.Y, 150.0f));

		s.View.ScrollBy(.(0.0f, -60.0f)); // away: it lets go
		Test.Assert(!s.View.IsLatchedToEnd);
		AddRows(1);
		Test.Assert(Near(s.View.ScrollOffset.Y, 90.0f));

		s.View.ScrollToEnd(); // back: it holds again
		Test.Assert(s.View.IsLatchedToEnd);
		AddRows(2);
		Test.Assert(Near(s.View.ScrollOffset.Y, 300.0f));
	}

	[Test]
	public static void ContentClippedAwayTakesNoPressARowBelowTheViewIsNotHitBeneathIt()
	{
		let s = scope Scroller(); // a 100 x 100 view of six 50-high rows: rows 2 to 5 lie below it, clipped
		s.WidenRows();
		let hit = s.Root.OverFind(.(20.0f, 150.0f));
		Test.Assert(hit != s.Rows[3]);
		Test.Assert(hit == s.Root); // what lies beyond the view there: the root
		Test.Assert(s.Root.OverFind(.(20.0f, 20.0f)) == s.Rows[0]); // inside, the row
	}

	[Test]
	public static void ASelectorMayAskForAPartsOwnStateAfterIt()
	{
		let plain = scope StyleSelector("scrollview::scrollbar-thumb");
		let hovered = scope StyleSelector("scrollview::scrollbar-thumb:hover");
		let held = scope StyleSelector("::scrollbar-thumb:active");
		Test.Assert(hovered.PseudoElement == "scrollbar-thumb");
		Test.Assert(hovered.PartPseudoClasses == PseudoHover);
		Test.Assert(held.PartPseudoClasses == PseudoActive);
		Test.Assert(plain.PartPseudoClasses == 0);
		Test.Assert(hovered.Specificity > plain.Specificity);
		// A state a part does not have matches nothing.
		let focused = scope StyleSelector("::scrollbar-thumb:focus");
		Test.Assert(focused.RuleAt(0).IsNever);
	}
}
