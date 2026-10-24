using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Scrolling: the ScrollBar control, and any node that scrolls (overflow: scroll or auto): its
/// range over the laid-out content, the content moving without a new layout, the wheel, the keys
/// while focused, its bars (drag, page, over the content), a descendant brought into view, the
/// extent following the content, the end it sticks to, smooth scrolls, a finger's pan and fling,
/// and a pad's stick.
class ScrollTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);
	private static bool Near(double a, double b) => Math.Abs(a - b) < 1.2e-5 * (1.0 + Math.Max(Math.Abs(a), Math.Abs(b)));

	/// A 100 x 100 scroll view at the root's corner holding `count` 50-high rows (panels, each a tab
	/// stop). The root holds the tree; it goes with the scroller.
	private class Scroller
	{
		public SceneRoot Root = SceneFixtures.NewScene() ~ _.ReleaseRef();
		public ScrollView View;
		public List<Panel> Rows = new .() ~ delete _;

		public this(int count = 6)
		{
			Root.Size = .(300.0f, 300.0f);
			View = new ScrollView();
			View.Position = .(0.0f, 0.0f);
			View.Size = .(100.0f, 100.0f);
			Root.AddChild(View);
			View.ReleaseRef(); // the tree's reference keeps it
			for (int i = 0; i < count; i++)
				AddRow();
			Root.UpdateLayout();
		}

		public EventDispatcher D => Root.EventDispatcher;

		public Panel AddRow()
		{
			let row = new Panel();
			row.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(50.0f); });
			row.TabFocusable = true;
			View.AddChild(row);
			row.ReleaseRef();
			Rows.Add(row);
			return row;
		}

		/// The rows are their content's width (none) in a scroller on both axes; a finger test
		/// needs them under it.
		public void WidenRows()
		{
			for (let row in Rows)
				row.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(80.0f); });
			Root.UpdateLayout();
		}
	}

	/// A new scroll bar, held by the caller.
	private static ScrollBar NewBar(Orientation orientation, float w, float h, double max, double page)
	{
		let bar = new ScrollBar();
		bar.Orientation = orientation;
		bar.Size = .(w, h);
		bar.Max = max;
		bar.Page = page;
		return bar;
	}

	/// A new panel styled by `style`, the last child of `parent`, which holds it (borrowed).
	private static Panel NewPanel(Node parent, delegate void(LayoutStyle style) style)
	{
		let panel = new Panel();
		panel.EditLayoutStyle(style);
		parent.AddChild(panel);
		panel.ReleaseRef();
		return panel;
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

	[Test]
	public static void ScrollBarItsValueIsAnOffsetKeptWithinTheRangeLessThePageTheThumbIsThePagesShare()
	{
		let sb = new ScrollBar();
		defer sb.ReleaseRef();
		sb.Max = 400.0;
		sb.Page = 100.0; // a quarter shows
		Test.Assert(Near(sb.ThumbProportion, 0.25f));
		sb.Value = 120.0;
		Test.Assert(Near(sb.Value, 120.0));
		sb.Value = 500.0;
		Test.Assert(Near(sb.Value, 300.0)); // the maximum less the page
		sb.Page = 1000.0;
		Test.Assert(Near(sb.ThumbProportion, 1.0f));
		Test.Assert(Near(sb.Value, 0.0)); // nothing to scroll
	}

	[Test]
	public static void ScrollBarDragKeepsTrackingAfterTheCursorLeavesItCaptureAndHoverLeave()
	{
		let root = SceneFixtures.NewScene(200.0f, 400.0f);
		defer root.ReleaseRef();
		let sb = NewBar(.Vertical, 16.0f, 200.0f, 200.0, 100.0); // track 200, thumb 100 -> travel 100
		defer sb.ReleaseRef();
		int inputs = 0;
		int changes = 0;
		sb.SetOnValueChanging(new [&] (value) => { inputs++; });
		sb.SetOnValueChanged(new [&] (value) => { changes++; });
		root.AddChild(sb);
		let d = root.EventDispatcher;

		// Hover first (so a leave will fire when we drag off), then press near the top.
		d.InjectMouseMove(.(8.0f, 10.0f));
		Test.Assert(sb.Hovered);
		d.InjectMouseDown(.(8.0f, 10.0f), .Left);

		// Drag well past the bottom edge -> the value saturates at the end (still tracking after leave).
		d.InjectMouseMove(.(8.0f, 500.0f));
		Test.Assert(!sb.Hovered);
		Test.Assert(Near(sb.Value, 100.0));
		Test.Assert(inputs == 1);
		Test.Assert(changes == 0); // committed on release

		// Release ends the drag.
		d.InjectMouseUp(.(8.0f, 500.0f), .Left);
		Test.Assert(changes == 1);
		d.InjectMouseMove(.(8.0f, 10.0f));
		Test.Assert(Near(sb.Value, 100.0));
	}

	[Test]
	public static void ScrollBarDrawsTrackAndThumb()
	{
		let sb = new ScrollBar();
		defer sb.ReleaseRef();
		sb.Size = .(16.0f, 120.0f);
		sb.Max = 100.0;
		sb.Page = 30.0;
		sb.Value = 35.0;
		Test.Assert(WidgetFixtures.DrawnVertices(sb) > 0);
	}

	[Test]
	public static void ScrollBarClickingTheTrackPagesTowardTheClick()
	{
		let root = SceneFixtures.NewScene(200.0f, 400.0f);
		defer root.ReleaseRef();
		let sb = NewBar(.Vertical, 16.0f, 200.0f, 200.0, 50.0); // thumb 50 -> at value 0 occupies [0,50]
		defer sb.ReleaseRef();
		root.AddChild(sb);
		let d = root.EventDispatcher;

		// Click below the thumb (y=150) -> page down by one page.
		d.InjectMouseDown(.(8.0f, 150.0f), .Left);
		Test.Assert(Near(sb.Value, 50.0));
		d.InjectMouseUp(.(8.0f, 150.0f), .Left);
	}

	[Test]
	public static void ScrollBarGrabbingTheThumbDragsByCursorDeltaNoJumpToCenter()
	{
		let root = SceneFixtures.NewScene(200.0f, 400.0f);
		defer root.ReleaseRef();
		let sb = NewBar(.Vertical, 16.0f, 200.0f, 200.0, 100.0); // thumb 100 -> travel 100, at value 0 occupies [0,100]
		defer sb.ReleaseRef();
		root.AddChild(sb);
		let d = root.EventDispatcher;

		// Grab the thumb at y=40 (inside [0,100]); pressing there must NOT move the value.
		d.InjectMouseDown(.(8.0f, 40.0f), .Left);
		Test.Assert(Near(sb.Value, 0.0));
		// Move the cursor down 20px -> thumb moves 20px -> a fifth of the travel: 20 of the 100 it can go.
		d.InjectMouseMove(.(8.0f, 60.0f));
		Test.Assert(Near(sb.Value, 20.0));
	}

	[Test]
	public static void ANodeThatOverflowsScrollsOverItsLaidOutContentTheContentMovingWithNoLayout()
	{
		let s = scope Scroller();
		Test.Assert(s.View.IsScrollContainer);
		Test.Assert(Near(s.View.ContentExtent.Y, 300.0f));
		Test.Assert(Near(s.View.ScrollRange.X, 0.0f)); // nothing wider than it
		Test.Assert(Near(s.View.ScrollRange.Y, 200.0f));
		s.View.ScrollOffset = .(0.0f, 500.0f);
		Test.Assert(Near(s.View.ScrollOffset.Y, 200.0f));
		s.View.ScrollOffset = .(0.0f, 60.0f);
		s.Root.UpdateLayout();
		Test.Assert(s.Root.LastLayoutCount == 0); // scrolling lays nothing out
		Test.Assert(Near(s.Rows[2].Position.Y, 100.0f)); // where the layout put it
		Test.Assert(Near(s.Rows[2].ScreenBounds.Y, 40.0f)); // where it shows
		Test.Assert(s.D.IsPointerOver(.(10.0f, 45.0f)));
	}

	[Test]
	public static void TheWheelScrollsItFromTheContentKeysScrollItOnlyWhileItIsFocused()
	{
		let s = scope Scroller();
		Test.Assert(s.D.InjectMouseWheel(.(20.0f, 20.0f), .(0.0f, -1.0f)));
		Test.Assert(Near(s.View.ScrollOffset.Y, s.View.ScrollStep));
		s.D.FocusNode = s.Rows[0];
		let before = s.View.ScrollOffset.Y;
		s.D.InjectKeyDown((uint32)KeyCode.PageDown);
		Test.Assert(Near(s.View.ScrollOffset.Y, before)); // the row's key, left to navigation
		s.D.FocusNode = s.View;
		Test.Assert(s.D.InjectKeyDown((uint32)KeyCode.End));
		Test.Assert(Near(s.View.ScrollOffset.Y, 200.0f));
		Test.Assert(Near(s.View.ScrollOffset.Y, 200.0f)); // already at the end
	}

	[Test]
	public static void OneWhoseKeysAreItsOwnDoesNotScrollByThemTheWheelStillDoes()
	{
		let s = scope Scroller();
		s.View.ScrollsByKeys = false;
		s.D.FocusNode = s.View;
		s.D.InjectKeyDown((uint32)KeyCode.End);
		s.D.InjectKeyDown((uint32)KeyCode.PageDown);
		Test.Assert(Near(s.View.ScrollOffset.Y, 0.0f));
		Test.Assert(s.D.InjectMouseWheel(.(20.0f, 20.0f), .(0.0f, -1.0f)));
		Test.Assert(Near(s.View.ScrollOffset.Y, s.View.ScrollStep));
	}

	[Test]
	public static void ItsBarLiesOverTheContentTheThumbDragsTheTrackPages()
	{
		let s = scope Scroller();
		let track = s.View.ScrollBarTrack(1);
		Test.Assert(track.Height > 0.0f);
		Test.Assert(Near(track.X, 92.0f)); // over the right edge, on top of the rows
		let thumb = s.View.ScrollBarThumb(1);
		Test.Assert(Near(thumb.Height, 100.0f * 100.0f / 300.0f));
		int rowPresses = 0;
		s.Rows[0].AddEventListener(.MouseDown, new [&] (e) => { rowPresses++; });
		let grab = Float2(96.0f, thumb.Y + 5.0f);
		s.D.InjectMouseDown(grab, .Left);
		Test.Assert(rowPresses == 0); // the bar's, not the row's under it
		Test.Assert(s.D.PointerCapture == s.View);
		s.D.InjectMouseMove(.(96.0f, grab.Y + (100.0f - thumb.Height) * 0.5f));
		Test.Assert(Near(s.View.ScrollOffset.Y, 100.0f)); // half the travel: half the range
		s.D.InjectMouseUp(.(96.0f, 90.0f), .Left);
		s.View.ScrollOffset = .(0.0f, 0.0f);
		s.D.InjectMouseDown(.(96.0f, 90.0f), .Left); // the track below the thumb
		Test.Assert(Near(s.View.ScrollOffset.Y, 100.0f)); // a page down
		s.D.InjectMouseUp(.(96.0f, 90.0f), .Left);
	}

	[Test]
	public static void AFocusedDescendantComesIntoViewByTheLeastThatShowsIt()
	{
		let s = scope Scroller();
		s.D.FocusNode = s.Rows[4]; // y 200..250
		Test.Assert(Near(s.View.ScrollOffset.Y, 150.0f));
		s.D.FocusNode = s.Rows[1]; // y 50..100: above the view now
		Test.Assert(Near(s.View.ScrollOffset.Y, 50.0f));
	}

	[Test]
	public static void OverflowFromASheetMakesAnyNodeScrollHiddenClipsWithoutScrolling()
	{
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let panel = NewPanel(root, scope (st) => { });
		panel.AddClass("list");
		NewPanel(panel, scope (st) =>
			{
				st.Height = LayoutLength.Px(500.0f);
				st.Shrink = 0.0f;
			});
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, ".list { height: 120px; overflow-y: auto; }");
		styles.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(panel.IsScrollContainer);
		Test.Assert(panel.ClipsChildren);
		Test.Assert(Near(panel.ScrollRange.Y, 380.0f));
		let hidden = scope StyleManager();
		WidgetFixtures.UseSheet(hidden, ".list { overflow: hidden; }");
		hidden.ApplyTree(root);
		root.UpdateLayout();
		Test.Assert(!panel.IsScrollContainer);
		Test.Assert(panel.ClipsChildren);
	}

	[Test]
	public static void ASmoothScrollEasesThereOnTheGUIsClockAndWheelNotchesAddUp()
	{
		let s = scope Scroller(10);
		let gui = s.Root.Context;
		s.View.ScrollTo(.(0.0f, 200.0f), .Smooth);
		Test.Assert(s.View.IsSmoothScrolling);
		Test.Assert(Near(s.View.ScrollOffset.Y, 0.0f));
		Test.Assert(Near(s.View.ScrollTarget.Y, 200.0f));
		gui.Update(SceneFixtures.Seconds(0.06)); // one time constant: about 63% of the way
		let expected = 200.0f * (1.0f - 0.3679f);
		Test.Assert(Math.Abs(s.View.ScrollOffset.Y - expected) < 0.01f * (1.0f + Math.Max(Math.Abs(s.View.ScrollOffset.Y), expected)));
		for (int i = 0; i < 20; ++i)
			gui.Update(SceneFixtures.Seconds(0.05));
		Test.Assert(Near(s.View.ScrollOffset.Y, 200.0f));
		Test.Assert(!s.View.IsSmoothScrolling);

		// `scroll-behavior: smooth` makes the wheel ease; two notches go twice as far.
		s.View.ScrollOffset = .(0.0f, 0.0f);
		s.View.EditLayoutStyle(scope (st) => { st.Scrolling = .Smooth; });
		s.Root.UpdateLayout();
		s.D.InjectMouseWheel(.(50.0f, 50.0f), .(0.0f, -1.0f));
		s.D.InjectMouseWheel(.(50.0f, 50.0f), .(0.0f, -1.0f));
		Test.Assert(Near(s.View.ScrollTarget.Y, 80.0f));
		Test.Assert(s.View.ScrollOffset.Y < 80.0f);
		// An instant scroll ends the easing where it puts it.
		s.View.ScrollOffset = .(0.0f, 10.0f);
		Test.Assert(!s.View.IsSmoothScrolling);
		gui.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(Near(s.View.ScrollOffset.Y, 10.0f));
	}

	[Test]
	public static void ShiftTurnsTheWheelAcrossAndAScrollerThatOnlyScrollsAcrossTakesIt()
	{
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let strip = NewPanel(root, scope (st) =>
			{
				st.Direction = .Row;
				st.OverflowX = .Auto;
			});
		strip.Size = .(100.0f, 60.0f);
		for (int i = 0; i < 4; i++)
		{
			NewPanel(strip, scope (st) =>
				{
					st.Width = LayoutLength.Px(80.0f);
					st.Shrink = 0.0f;
				});
		}
		root.UpdateLayout();
		let d = root.EventDispatcher;
		d.InjectMouseWheel(.(50.0f, 20.0f), .(0.0f, -1.0f)); // a vertical notch
		Test.Assert(Near(strip.ScrollOffset.X, 40.0f));

		let s = scope Scroller(); // both axes may scroll; Shift and a vertical notch go across, and there is no room
		s.View.EditLayoutStyle(scope (st) => { st.OverflowX = .Auto; });
		NewPanel(s.View, scope (st) =>
			{
				st.Width = LayoutLength.Px(300.0f);
				st.Height = LayoutLength.Px(10.0f);
			});
		s.Root.UpdateLayout();
		s.D.InjectMouseWheel(.(50.0f, 50.0f), .(0.0f, -1.0f), KeyModShift);
		Test.Assert(Near(s.View.ScrollOffset.X, 40.0f));
		Test.Assert(Near(s.View.ScrollOffset.Y, 0.0f));
	}

	[Test]
	public static void AtItsEndAScrollerPassesTheWheelOnUnlessItContainsItsOverscroll()
	{
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let outer = new ScrollView();
		defer outer.ReleaseRef();
		outer.Size = .(200.0f, 200.0f);
		root.AddChild(outer);
		let inner = new ScrollView();
		defer inner.ReleaseRef();
		inner.EditLayoutStyle(scope (st) =>
			{
				st.Width = LayoutLength.Px(150.0f); // a scroller on both axes leaves its children their own width
				st.Height = LayoutLength.Px(100.0f);
				st.Shrink = 0.0f;
			});
		outer.AddChild(inner);
		NewPanel(inner, scope (st) => { st.Height = LayoutLength.Px(150.0f); });
		NewPanel(outer, scope (st) =>
			{
				st.Height = LayoutLength.Px(400.0f);
				st.Shrink = 0.0f;
			});
		root.UpdateLayout();
		let d = root.EventDispatcher;

		inner.ScrollOffset = .(0.0f, 50.0f); // at its end
		d.InjectMouseWheel(.(50.0f, 50.0f), .(0.0f, -1.0f));
		Test.Assert(Near(outer.ScrollOffset.Y, 40.0f)); // passed on

		outer.ScrollOffset = .(0.0f, 0.0f);
		inner.EditLayoutStyle(scope (st) => { st.Overscroll = .Contain; });
		root.UpdateLayout();
		Test.Assert(d.InjectMouseWheel(.(50.0f, 50.0f), .(0.0f, -1.0f)));
		Test.Assert(Near(outer.ScrollOffset.Y, 0.0f)); // kept
	}

	[Test]
	public static void ASheetSetsScrollBehaviorAndOverscrollBehavior()
	{
		let s = scope Scroller();
		s.View.AddClass("soft");
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, ".soft { scroll-behavior: smooth; overscroll-behavior: contain; }");
		styles.ApplyTree(s.Root);
		Test.Assert(s.View.LayoutStyle.Scrolling == .Smooth);
		Test.Assert(s.View.LayoutStyle.Overscroll == .Contain);
	}

	[Test]
	public static void TheBarsAreScrollbarAndScrollbarThumbStyledPerTheirOwnHoverAndDrag()
	{
		let s = scope Scroller();
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles,
			"scrollview::scrollbar { background-color: #101010; }" +
			"scrollview::scrollbar-thumb { background-color: #202020; }" +
			"scrollview::scrollbar-thumb:hover { background-color: #303030; }" +
			"scrollview::scrollbar-thumb:active { background-color: #404040; }");
		styles.ApplyTree(s.Root);
		Color Thumb() => s.View.FindPartStyle("scrollbar-thumb").Box.BackgroundColor;
		Test.Assert(s.View.FindPartStyle("scrollbar") != null);
		Test.Assert(s.View.FindPartStyle("scrollbar").Box.BackgroundColor == ParseColor("#101010").Value);
		Test.Assert(Thumb() == ParseColor("#202020").Value);

		let bar = s.View.ScrollBarThumb(1);
		let onThumb = Float2(bar.X + bar.Width * 0.5f, bar.Y + 5.0f);
		s.D.InjectMouseMove(onThumb);
		Test.Assert((s.View.GetPartStates("scrollbar-thumb") & Node.StateHover) != 0);
		styles.ApplyTree(s.Root);
		Test.Assert(Thumb() == ParseColor("#303030").Value);

		s.D.InjectMouseDown(onThumb, .Left);
		styles.ApplyTree(s.Root);
		Test.Assert(Thumb() == ParseColor("#404040").Value);
		s.D.InjectMouseUp(onThumb, .Left);

		s.D.InjectMouseMove(.(20.0f, 20.0f)); // over the content, off the bar
		Test.Assert(s.View.GetPartStates("scrollbar-thumb") == 0);
		styles.ApplyTree(s.Root);
		Test.Assert(Thumb() == ParseColor("#202020").Value);
	}

	[Test]
	public static void ScrollbarWidthThinsOrHidesTheBarsHiddenItStillScrolls()
	{
		let s = scope Scroller();
		Test.Assert(Near(s.View.ScrollBarTrack(1).Width, 8.0f));
		s.View.EditLayoutStyle(scope (st) => { st.BarWidth = .Thin; });
		Test.Assert(Near(s.View.ScrollBarTrack(1).Width, 5.0f));
		s.View.EditLayoutStyle(scope (st) => { st.BarWidth = .None; });
		Test.Assert(Near(s.View.ScrollBarTrack(1).Width, 0.0f));
		s.Root.UpdateLayout();
		s.D.InjectMouseWheel(.(95.0f, 50.0f), .(0.0f, -1.0f));
		Test.Assert(Near(s.View.ScrollOffset.Y, 40.0f));
	}

	[Test]
	public static void OverlayBarsShowWhileItScrollsOrIsHoveredThenFade()
	{
		let s = scope Scroller();
		s.View.EditLayoutStyle(scope (st) => { st.BarVisibility = .Overlay; });
		s.Root.UpdateLayout();
		let gui = s.Root.Context;
		Test.Assert(Near(s.View.ScrollbarOpacity, 0.0f));
		s.View.ScrollBy(.(0.0f, 30.0f));
		Test.Assert(Near(s.View.ScrollbarOpacity, 1.0f));
		gui.Update(SceneFixtures.Seconds(0.5)); // lingering
		Test.Assert(Near(s.View.ScrollbarOpacity, 1.0f));
		gui.Update(SceneFixtures.Seconds(0.45)); // past the linger, fading
		Test.Assert(s.View.ScrollbarOpacity < 1.0f);
		gui.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(Near(s.View.ScrollbarOpacity, 0.0f));

		// Hovered, it shows and stays.
		s.D.InjectMouseMove(.(50.0f, 50.0f));
		gui.Update(SceneFixtures.Seconds(2.0));
		Test.Assert(Near(s.View.ScrollbarOpacity, 1.0f));

		// A sheet chooses it, and the width.
		let t = scope Scroller();
		t.View.AddClass("slim");
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, ".slim { scrollbar-width: thin; scrollbar-visibility: overlay; }");
		styles.ApplyTree(t.Root);
		Test.Assert(t.View.LayoutStyle.BarWidth == .Thin);
		Test.Assert(t.View.LayoutStyle.BarVisibility == .Overlay);
	}

	[Test]
	public static void AFingerThatStaysPutTapsOneThatMovesPansCancellingThePress()
	{
		let s = scope Scroller(10);
		s.WidenRows();
		int clicks = 0;
		int cancels = 0;
		s.Rows[1].AddEventListener(.MouseClick, new [&] (e) => { clicks++; });
		s.Rows[1].AddEventListener(.PointerCancel, new [&] (e) => { cancels++; });
		let d = s.D;

		d.InjectTouchDown(1, .(40.0f, 70.0f)); // row 1 (50..100)
		d.InjectTouchMove(1, .(42.0f, 74.0f)); // within the slop
		d.InjectTouchUp(1, .(42.0f, 74.0f));
		Test.Assert(clicks == 1);
		Test.Assert(Near(s.View.ScrollOffset.Y, 0.0f));

		d.InjectTouchDown(1, .(40.0f, 90.0f));
		d.InjectTouchMove(1, .(40.0f, 75.0f)); // past the slop: a pan
		Test.Assert(d.IsPanning);
		Test.Assert(cancels == 1);
		Test.Assert(Near(s.View.ScrollOffset.Y, 15.0f)); // the content keeps to the finger
		d.InjectTouchMove(1, .(40.0f, 50.0f));
		Test.Assert(Near(s.View.ScrollOffset.Y, 40.0f));
		d.InjectTouchUp(1, .(40.0f, 50.0f)); // let go still: no fling, no click
		Test.Assert(!d.IsPanning);
		Test.Assert(!s.View.IsFlinging);
		Test.Assert(clicks == 1);
	}

	[Test]
	public static void ThePanSlopIsInDIPsAFingersTwelvePixelWobbleTapsOnADisplayOfScaleTwoAndPansAtOne()
	{
		{
			let s = scope Scroller(10);
			s.WidenRows();
			s.Root.DisplayScale = 2.0f; // device pixels twice the root's units: row 1 is 100..200 down
			s.Root.UpdateLayout();
			int clicks = 0;
			s.Rows[1].AddEventListener(.MouseClick, new [&] (e) => { clicks++; });
			let d = s.D;
			d.InjectTouchDown(1, .(80.0f, 140.0f));
			d.InjectTouchMove(1, .(80.0f, 152.0f)); // 6 DIPs: within the 8
			Test.Assert(!d.IsPanning);
			d.InjectTouchUp(1, .(80.0f, 152.0f));
			Test.Assert(clicks == 1);
		}
		{
			let s = scope Scroller(10);
			s.WidenRows();
			let d = s.D;
			d.InjectTouchDown(1, .(40.0f, 70.0f));
			d.InjectTouchMove(1, .(40.0f, 82.0f)); // 12 DIPs: past it
			Test.Assert(d.IsPanning);
			d.InjectTouchUp(1, .(40.0f, 82.0f));
		}
	}

	[Test]
	public static void LetGoMovingAPanFlingsOnSlowingAndANewFingerCatchesIt()
	{
		let s = scope Scroller(40); // 2000 tall: room to glide
		s.WidenRows();
		let gui = s.Root.Context;
		let d = s.D;
		int clicks = 0;
		for (let row in s.Rows)
			row.AddEventListener(.MouseClick, new [&] (e) => { clicks++; });

		d.InjectTouchDown(1, .(40.0f, 95.0f));
		for (int i = 1; i <= 5; ++i) // 15 px a step at 60 Hz: 900 px a second upward
		{
			gui.Update(SceneFixtures.Seconds(1.0 / 60.0));
			d.InjectTouchMove(1, .(40.0f, 95.0f - 15.0f * (float)i));
		}
		d.InjectTouchUp(1, .(40.0f, 20.0f));
		Test.Assert(s.View.IsFlinging);
		let released = s.View.ScrollOffset.Y;
		Test.Assert(Near(released, 75.0f));
		gui.Update(SceneFixtures.Seconds(0.1));
		let early = s.View.ScrollOffset.Y - released;
		gui.Update(SceneFixtures.Seconds(0.1));
		let later = s.View.ScrollOffset.Y - released - early;
		Test.Assert(early > 0.0f);
		Test.Assert(later < early); // slowing

		d.InjectTouchDown(2, .(40.0f, 50.0f)); // caught
		Test.Assert(!s.View.IsFlinging);
		let caughtAt = s.View.ScrollOffset.Y;
		d.InjectTouchUp(2, .(40.0f, 50.0f));
		gui.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(Near(s.View.ScrollOffset.Y, caughtAt));
		Test.Assert(clicks == 0); // neither the pan nor the catch clicked a row

		// Left alone, a fling stops by itself (or at the end).
		d.InjectTouchDown(3, .(40.0f, 95.0f));
		for (int i = 1; i <= 5; ++i)
		{
			gui.Update(SceneFixtures.Seconds(1.0 / 60.0));
			d.InjectTouchMove(3, .(40.0f, 95.0f - 15.0f * (float)i));
		}
		d.InjectTouchUp(3, .(40.0f, 20.0f));
		for (int i = 0; (i < 200) && s.View.IsFlinging; ++i)
			gui.Update(SceneFixtures.Seconds(1.0 / 60.0));
		Test.Assert(!s.View.IsFlinging);
	}

	[Test]
	public static void OnlyAFingerPansASidewaysFingerOverAScrollerThatCannotMoveAcrossPressesOn()
	{
		let s = scope Scroller(10);
		s.WidenRows();
		let d = s.D;
		d.InjectMouseDown(.(40.0f, 90.0f), .Left);
		d.InjectMouseMove(.(40.0f, 40.0f));
		d.InjectMouseUp(.(40.0f, 40.0f), .Left);
		Test.Assert(Near(s.View.ScrollOffset.Y, 0.0f));

		int cancels = 0;
		s.Rows[1].AddEventListener(.PointerCancel, new [&] (e) => { cancels++; });
		d.InjectTouchDown(1, .(20.0f, 70.0f));
		d.InjectTouchMove(1, .(60.0f, 72.0f)); // across: nothing scrolls that way
		Test.Assert(!d.IsPanning);
		Test.Assert(cancels == 0);
		d.InjectTouchUp(1, .(60.0f, 72.0f));
	}

	[Test]
	public static void APadsRightStickScrollsTheNearestScrollerAroundTheFocus()
	{
		let s = scope Scroller(40);
		let gui = s.Root.Context;
		let d = s.D;
		d.FocusNode = s.Rows[0];

		d.ScrollStick = .(0.0f, 0.15f); // within the dead zone
		gui.Update(SceneFixtures.Seconds(0.1));
		Test.Assert(Near(s.View.ScrollOffset.Y, 0.0f));

		d.ScrollStick = .(0.0f, 1.0f); // all the way: 1400 px a second
		gui.Update(SceneFixtures.Seconds(0.1));
		Test.Assert(Near(s.View.ScrollOffset.Y, 140.0f));

		d.ScrollStick = .(0.0f, -0.6f); // half way past the dead zone, squared: a quarter
		gui.Update(SceneFixtures.Seconds(0.1));
		Test.Assert(Near(s.View.ScrollOffset.Y, 140.0f - 35.0f));

		d.ScrollStick = .(0.0f, 0.0f); // let go
		gui.Update(SceneFixtures.Seconds(0.1));
		Test.Assert(Near(s.View.ScrollOffset.Y, 105.0f));

		// With no focus, the scroller under the pointer.
		d.FocusNode = null;
		d.InjectMouseMove(.(40.0f, 40.0f));
		d.ScrollStick = .(0.0f, 1.0f);
		gui.Update(SceneFixtures.Seconds(0.05));
		Test.Assert(Near(s.View.ScrollOffset.Y, 175.0f));
	}

	[Test]
	public static void APanMovesTheContentWithTheFingerAtADisplayScaleInTheViewsOwnUnits()
	{
		let s = scope Scroller(10);
		s.WidenRows();
		s.Root.DisplayScale = 2.0f; // a finger moves in device pixels, twice the view's units
		s.Root.UpdateLayout();
		let d = s.D;
		d.InjectTouchDown(1, .(80.0f, 180.0f));
		d.InjectTouchMove(1, .(80.0f, 150.0f)); // 30 device pixels up: 15 of the view's
		Test.Assert(d.IsPanning);
		Test.Assert(Near(s.View.ScrollOffset.Y, 15.0f));
		d.InjectTouchUp(1, .(80.0f, 150.0f));
	}
}
