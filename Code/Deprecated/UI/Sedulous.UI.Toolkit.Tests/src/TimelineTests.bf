using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The ruler, the playhead, the dopesheet and the shared time transform.
///
/// The geometry these cases rely on: the ruler is 24 tall and a lane is 22, so lane 0's centre
/// is at y = 35 and lane 1's at y = 57. At a hundred pixels per second with no gutter and no
/// scroll, a time in seconds is its x in hundreds of pixels.
class TimelineTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	private static MouseEventArgs Mouse(float x, float y, MouseButton button = .Left)
	{
		let e = new MouseEventArgs();
		e.X = x;
		e.Y = y;
		e.Button = button;
		e.ClickCount = 1;
		return e;
	}

	/// OWNERSHIP transfers to SetLanes.
	private static List<DopesheetLane> Lanes(params Span<float[]> laneKeyTimes)
	{
		let lanes = new List<DopesheetLane>();
		for (let keyTimes in laneKeyTimes)
		{
			let lane = new DopesheetLane();
			for (let t in keyTimes)
				lane.KeyTimes.Add(t);
			lanes.Add(lane);
		}
		return lanes;
	}

	[Test]
	public static void PickTickStepFollowsTheOneTwoFiveSequence()
	{
		// A second across a hundred pixels with a forty eight pixel minimum wants at least
		// 0.48s, and five hundredths of a second is the smallest member that fits.
		Test.Assert(Near(Timeline.PickTickStep(100.0f, 48.0f), 0.5f));
		Test.Assert(Near(Timeline.PickTickStep(20.0f, 48.0f), 5.0f));
		Test.Assert(Near(Timeline.PickTickStep(1000.0f, 48.0f), 0.05f));
		Test.Assert(Near(Timeline.PickTickStep(10.0f, 48.0f), 5.0f));
		// 9.6 seconds needs the next decade, since ten is the only member above it.
		Test.Assert(Near(Timeline.PickTickStep(5.0f, 48.0f), 10.0f));
	}

	/// The property the sequence exists for: whatever the zoom, the chosen step is at least the
	/// minimum label width on screen, so labels never collide.
	[Test]
	public static void TheChosenStepAlwaysFitsItsLabel()
	{
		float[7] zooms = .(5.0f, 10.0f, 37.0f, 100.0f, 250.0f, 1000.0f, 3999.0f);
		for (let pixelsPerSecond in zooms)
			Test.Assert((Timeline.PickTickStep(pixelsPerSecond, 48.0f) * pixelsPerSecond) >= 48.0f);

		Test.Assert(Near(Timeline.PickTickStep(0.0f, 48.0f), 1.0f), "no division by nothing");
	}

	[Test]
	public static void TheTimeTransformRoundTripsThroughZoomAndScroll()
	{
		let timeline = new Timeline();
		defer timeline.ReleaseRef();

		timeline.SetPixelsPerSecond(120.0f);
		timeline.SetScrollSeconds(0.5f);
		timeline.LabelColumnWidth = 40.0f;

		// The scrolled-to time sits at the gutter's right edge.
		Test.Assert(Near(timeline.TimeToX(0.5f), 40.0f));
		Test.Assert(Near(timeline.TimeToX(1.5f), 160.0f));

		float[4] times = .(0.0f, 0.5f, 1.2f, 3.7f);
		for (let t in times)
			Test.Assert(Near(timeline.XToTime(timeline.TimeToX(t)), t));

		// The zoom is CLAMPED, and the transform stays consistent through the clamp.
		timeline.SetPixelsPerSecond(1.0f);
		Test.Assert(timeline.PixelsPerSecond >= 4.0f);
		Test.Assert(Near(timeline.XToTime(timeline.TimeToX(2.0f)), 2.0f));
	}

	[Test]
	public static void ThePlayheadClampsAndReportsOnlyRealMoves()
	{
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		timeline.SetDuration(2.0f);

		var fires = 0;
		var last = -1.0f;
		timeline.OnPlayheadMoved.Add(new [&fires, &last](t) => { fires++; last = t; });

		timeline.SetPlayheadTime(1.0f);
		Test.Assert(timeline.PlayheadTime == 1.0f);
		Test.Assert(fires == 1);
		Test.Assert(last == 1.0f);

		// Writing the same time again is not a move, which matters because a host playing back
		// writes the playhead every frame.
		timeline.SetPlayheadTime(1.0f);
		Test.Assert(fires == 1);

		timeline.SetPlayheadTime(5.0f);
		Test.Assert(timeline.PlayheadTime == 2.0f);
		Test.Assert(fires == 2);

		timeline.SetPlayheadTime(-3.0f);
		Test.Assert(timeline.PlayheadTime == 0.0f);
		Test.Assert(fires == 3);

		// A clip that gets shorter drags the playhead back inside it.
		timeline.SetPlayheadTime(2.0f);
		timeline.SetDuration(1.0f);
		Test.Assert(timeline.PlayheadTime == 1.0f);
	}

	[Test]
	public static void ClickingSelectsTheNearestKeyOnTheLane()
	{
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		timeline.SetPixelsPerSecond(100.0f);
		timeline.SetLanes(Lanes(scope float[](0.2f, 0.5f)));

		Test.Assert(timeline.LaneCount == 1);

		var selectionEvents = 0;
		timeline.OnSelectionChanged.Add(new [&selectionEvents]() => { selectionEvents++; });

		let down = Mouse(50.0f, 35.0f);
		defer delete down;
		timeline.OnMouseDown(down);

		Test.Assert(timeline.SelectedCount == 1);
		Test.Assert(timeline.IsKeySelected(0, 1));
		Test.Assert(!timeline.IsKeySelected(0, 0));
		Test.Assert(selectionEvents == 1);

		var moves = 0;
		timeline.OnKeysMoved.Add(new [&moves](delta) => { moves++; });

		let up = Mouse(50.0f, 35.0f);
		defer delete up;
		timeline.OnMouseUp(up);
		Test.Assert(moves == 0, "a click with no movement is not a drag");
	}

	/// A key drag is VISUAL. The widget reports a delta and leaves the model to the host, which
	/// is what keeps the model authoritative through an operation that can reorder it.
	[Test]
	public static void DraggingAKeyReportsADeltaAndLeavesTheModelAlone()
	{
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		timeline.SetPixelsPerSecond(100.0f);
		timeline.SetLanes(Lanes(scope float[](0.5f)));

		var moved = -999.0f;
		var moves = 0;
		timeline.OnKeysMoved.Add(new [&moved, &moves](delta) => { moved = delta; moves++; });

		let down = Mouse(50.0f, 35.0f);
		defer delete down;
		timeline.OnMouseDown(down);
		Test.Assert(timeline.IsKeySelected(0, 0));

		let move = Mouse(80.0f, 35.0f);
		defer delete move;
		timeline.OnMouseMove(move);

		let up = Mouse(80.0f, 35.0f);
		defer delete up;
		timeline.OnMouseUp(up);

		Test.Assert(moves == 1);
		Test.Assert(Near(moved, 0.3f), "thirty pixels at a hundred per second");

		// The key never moved, so it is still hit at its ORIGINAL position.
		let probe = Mouse(50.0f, 35.0f);
		defer delete probe;
		timeline.OnMouseDown(probe);
		Test.Assert(timeline.IsKeySelected(0, 0));
		timeline.OnMouseUp(probe);
	}

	/// Without the threshold, every selecting click would commit a sub pixel move and land an
	/// undo entry for nothing.
	[Test]
	public static void ASubEpsilonMoveIsAClickNotADrag()
	{
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		timeline.SetPixelsPerSecond(100.0f);
		timeline.SetLanes(Lanes(scope float[](0.5f)));

		var moves = 0;
		timeline.OnKeysMoved.Add(new [&moves](delta) => { moves++; });

		let down = Mouse(50.0f, 35.0f);
		defer delete down;
		timeline.OnMouseDown(down);

		let move = Mouse(51.0f, 35.0f);
		defer delete move;
		timeline.OnMouseMove(move);

		let up = Mouse(51.0f, 35.0f);
		defer delete up;
		timeline.OnMouseUp(up);

		Test.Assert(moves == 0);
	}

	[Test]
	public static void BoxSelectTakesTheKeysInsideTheRectangle()
	{
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		timeline.SetPixelsPerSecond(100.0f);
		timeline.SetLanes(Lanes(scope float[](0.2f, 0.5f), scope float[](0.8f)));

		// From (10, 26) to (60, 60): lane zero's two keys are at x 20 and 50 on a centre line
		// of 35, both inside; lane one's key is at x 80, outside.
		let down = Mouse(10.0f, 26.0f);
		defer delete down;
		timeline.OnMouseDown(down);

		let move = Mouse(60.0f, 60.0f);
		defer delete move;
		timeline.OnMouseMove(move);

		let up = Mouse(60.0f, 60.0f);
		defer delete up;
		timeline.OnMouseUp(up);

		Test.Assert(timeline.SelectedCount == 2);
		Test.Assert(timeline.IsKeySelected(0, 0));
		Test.Assert(timeline.IsKeySelected(0, 1));
		Test.Assert(!timeline.IsKeySelected(1, 0));
	}

	[Test]
	public static void ScrollClampsToTheContentAtEveryZoom()
	{
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		timeline.SetDuration(3.0f);
		timeline.SetPixelsPerSecond(100.0f);
		timeline.Measure(BoxConstraints.Tight(400.0f, 60.0f));
		timeline.Layout(0, 0, 400.0f, 60.0f);

		// The whole clip fits, so scrolling is pinned: zooming out can never push both ends
		// away from the content.
		timeline.SetScrollSeconds(5.0f);
		Test.Assert(timeline.ScrollSeconds == 0.0f);

		// Zoomed in to one visible second, scrolling reaches the end plus the grab tail.
		timeline.SetPixelsPerSecond(400.0f);
		timeline.SetScrollSeconds(50.0f);
		let visible = timeline.VisibleSeconds;
		Test.Assert(Near(visible, 1.0f));
		Test.Assert(Near(timeline.ScrollSeconds, 3.0f + (visible * 0.15f) - visible));

		// Zooming back out re-clamps what was stored.
		timeline.SetPixelsPerSecond(100.0f);
		Test.Assert(timeline.ScrollSeconds == 0.0f);

		// And so does a clip that gets shorter.
		timeline.SetPixelsPerSecond(400.0f);
		timeline.SetScrollSeconds(50.0f);
		Test.Assert(timeline.ScrollSeconds > 0.0f);
		timeline.SetDuration(0.5f);
		Test.Assert(timeline.ScrollSeconds == 0.0f);
	}

	[Test]
	public static void MiddleDragPansAndClampsAtTheEdges()
	{
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		timeline.SetDuration(10.0f);
		timeline.SetPixelsPerSecond(100.0f);
		timeline.Measure(BoxConstraints.Tight(400.0f, 60.0f));
		timeline.Layout(0, 0, 400.0f, 60.0f);

		let down = Mouse(200.0f, 10.0f, .Middle);
		defer delete down;
		timeline.OnMouseDown(down);
		Test.Assert(down.Handled);

		// Dragging a hundred pixels left moves the view one second forward.
		let move = Mouse(100.0f, 10.0f, .Middle);
		defer delete move;
		timeline.OnMouseMove(move);
		Test.Assert(Near(timeline.ScrollSeconds, 1.0f));

		let farRight = Mouse(4000.0f, 10.0f, .Middle);
		defer delete farRight;
		timeline.OnMouseMove(farRight);
		Test.Assert(timeline.ScrollSeconds == 0.0f, "never before the clip start");

		let up = Mouse(4000.0f, 10.0f, .Middle);
		defer delete up;
		timeline.OnMouseUp(up);

		let after = Mouse(100.0f, 10.0f, .Middle);
		defer delete after;
		timeline.OnMouseMove(after);
		Test.Assert(timeline.ScrollSeconds == 0.0f, "a released pan no longer follows");
	}

	[Test]
	public static void ShiftAndHorizontalWheelPanWhilePlainWheelZooms()
	{
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		timeline.SetDuration(10.0f);
		timeline.SetPixelsPerSecond(100.0f);
		timeline.Measure(BoxConstraints.Tight(400.0f, 60.0f));
		timeline.Layout(0, 0, 400.0f, 60.0f);

		let shiftWheel = scope MouseWheelEventArgs();
		shiftWheel.X = 200.0f;
		shiftWheel.DeltaY = -1.0f;
		shiftWheel.Modifiers = .Shift;
		timeline.OnMouseWheel(shiftWheel);
		Test.Assert(shiftWheel.Handled);
		Test.Assert(Near(timeline.ScrollSeconds, 0.4f), "forty pixels at a hundred per second");

		let horizontal = scope MouseWheelEventArgs();
		horizontal.X = 200.0f;
		horizontal.DeltaX = -1.0f;
		timeline.OnMouseWheel(horizontal);
		Test.Assert(Near(timeline.ScrollSeconds, 0.8f));

		// A plain vertical wheel zooms, ANCHORED at the cursor: at the left edge the scroll
		// does not move because the time under x = 0 is what stays put.
		let scrollBefore = timeline.ScrollSeconds;
		let pixelsBefore = timeline.PixelsPerSecond;
		let zoom = scope MouseWheelEventArgs();
		zoom.X = 0.0f;
		zoom.DeltaY = 1.0f;
		timeline.OnMouseWheel(zoom);

		Test.Assert(timeline.PixelsPerSecond > pixelsBefore);
		Test.Assert(Near(timeline.ScrollSeconds, scrollBefore));
	}

	/// The dopesheet IS the track list, so picking a lane, by its label or by one of its keys,
	/// is how the host learns which track to show elsewhere.
	[Test]
	public static void LaneSelectionComesFromTheGutterAndFromKeyPicks()
	{
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		timeline.SetDuration(4.0f);
		timeline.SetPixelsPerSecond(100.0f);
		timeline.LabelColumnWidth = 120.0f;

		let lanes = Lanes(scope float[](1.0f), scope float[](2.0f));
		lanes[0].Label.Set("Transform.Position");
		lanes[1].Label.Set("Light.Intensity");
		timeline.SetLanes(lanes);

		timeline.Measure(BoxConstraints.Tight(520.0f, 120.0f));
		timeline.Layout(0, 0, 520.0f, 120.0f);
		Test.Assert(timeline.SelectedLane == -1);

		var fired = -2;
		var fires = 0;
		timeline.OnLaneSelected.Add(new [&fired, &fires](lane) => { fired = lane; fires++; });

		// The gutter, on the SECOND row: the ruler is 24 and lane zero is 22, so lane one runs
		// from 46 to 68.
		let down = Mouse(30.0f, 50.0f);
		defer delete down;
		timeline.OnMouseDown(down);
		Test.Assert(down.Handled);
		Test.Assert(timeline.SelectedLane == 1);
		Test.Assert(fired == 1);
		Test.Assert(fires == 1);

		let again = Mouse(30.0f, 50.0f);
		defer delete again;
		timeline.OnMouseDown(again);
		Test.Assert(fires == 1, "re-picking the same lane reports nothing");

		// A key pick takes its lane too: lane zero's key at t = 1 sits at 120 + 100.
		let keyDown = Mouse(220.0f, 35.0f);
		defer delete keyDown;
		timeline.OnMouseDown(keyDown);
		timeline.OnMouseUp(keyDown);
		Test.Assert(timeline.SelectedLane == 0);
		Test.Assert(fired == 0);
		Test.Assert(fires == 2);

		// A programmatic set stays quiet, and out of range clamps to none.
		timeline.SetSelectedLane(1);
		Test.Assert(timeline.SelectedLane == 1);
		Test.Assert(fires == 2);
		timeline.SetSelectedLane(9);
		Test.Assert(timeline.SelectedLane == -1);

		// A shorter lane set drops a pick that no longer exists.
		timeline.SetSelectedLane(1);
		let fewer = Lanes(scope float[]());
		fewer[0].Label.Set("only");
		timeline.SetLanes(fewer);
		Test.Assert(timeline.SelectedLane == -1);
	}

	/// Anything sharing the transform, the curve canvas below, re-syncs from this.
	[Test]
	public static void ViewChangedFiresOnZoomAndOnScroll()
	{
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		timeline.SetDuration(100.0f);
		timeline.Measure(BoxConstraints.Tight(800.0f, 200.0f));
		timeline.Layout(0, 0, 800.0f, 200.0f);

		var views = 0;
		timeline.OnViewChanged.Add(new [&views]() => { views++; });

		timeline.SetPixelsPerSecond(200.0f);
		Test.Assert(views >= 1);

		let afterZoom = views;
		timeline.SetScrollSeconds(5.0f);
		Test.Assert(Near(timeline.ScrollSeconds, 5.0f));
		Test.Assert(views > afterZoom);
	}

	/// The selection survives a round trip through the reference form the host speaks.
	[Test]
	public static void TheSelectionRoundTripsThroughKeyReferences()
	{
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		timeline.SetPixelsPerSecond(100.0f);
		timeline.SetLanes(Lanes(scope float[](0.2f, 0.5f), scope float[](0.8f)));

		DopesheetKeyRef[2] keys = .(.(0, 1), .(1, 0));
		timeline.SetSelection(keys);
		Test.Assert(timeline.SelectedCount == 2);
		Test.Assert(timeline.IsKeySelected(0, 1));
		Test.Assert(timeline.IsKeySelected(1, 0));

		let readBack = scope List<DopesheetKeyRef>();
		timeline.GetSelection(readBack);
		Test.Assert(readBack.Count == 2);
		Test.Assert((readBack[0].Lane == 0) && (readBack[0].Index == 1));
		Test.Assert((readBack[1].Lane == 1) && (readBack[1].Index == 0));

		timeline.ClearSelection();
		Test.Assert(timeline.SelectedCount == 0);
	}
}
