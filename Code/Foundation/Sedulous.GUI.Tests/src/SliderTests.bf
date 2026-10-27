using System;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Slider tests: value clamping and the change callbacks, drag-to-set, and pointer capture (a drag
/// keeps tracking after the cursor leaves the slider), keys and the wheel, Escape putting a drag
/// back, the wheel's switch, vertical and exponential; a step read from a float.
class SliderTests
{
	private static bool Near(double a, double b, double epsilon = 1.2e-5) =>
		Math.Abs(a - b) < epsilon * (1.0 + Math.Max(Math.Abs(a), Math.Abs(b)));

	/// A new slider `w` by `h`, the last child of `root`, held by the caller.
	private static Slider NewSlider(Node root, float w, float h)
	{
		let s = new Slider();
		s.Size = .(w, h);
		if (root != null)
			root.AddChild(s);
		return s;
	}

	[Test]
	public static void ValueClampsToItsRangeAndSnapsToItsStepCodesValueReportsNothing()
	{
		let s = NewSlider(null, 0.0f, 0.0f);
		defer s.ReleaseRef();
		int changes = 0;
		s.SetOnValueChanged(new [&] (value) => { changes++; });
		s.SetOnValueChanging(new [&] (value) => { changes++; });

		s.Value = 0.5;
		Test.Assert(Near(s.Value, 0.5));
		s.Value = 2.0; // clamps to 1
		Test.Assert(Near(s.Value, 1.0));
		s.Value = -1.0; // clamps to 0
		Test.Assert(Near(s.Value, 0.0));
		Test.Assert(changes == 0);

		s.Min = 10.0;
		s.Max = 20.0;
		s.Step = 2.5;
		Test.Assert(Near(s.Value, 10.0)); // into the new range
		s.Value = 13.9;
		Test.Assert(Near(s.Value, 15.0)); // the nearest step
	}

	[Test]
	public static void PressSetsValueFromTheCursorX()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let s = NewSlider(root, 100.0f, 20.0f); // handleR = 10 -> usable x in [10, 90]
		defer s.ReleaseRef();
		let d = root.EventDispatcher;

		d.InjectMouseDown(.(50.0f, 10.0f), .Left); // (50-10)/(90-10) = 0.5
		Test.Assert(Near(s.Value, 0.5));
	}

	[Test]
	public static void DragKeepsTrackingAfterTheCursorLeavesItPointerCapture()
	{
		let root = SceneFixtures.NewScene(300.0f, 200.0f);
		defer root.ReleaseRef();
		let s = NewSlider(root, 100.0f, 20.0f);
		defer s.ReleaseRef();
		let d = root.EventDispatcher;

		d.InjectMouseDown(.(10.0f, 10.0f), .Left); // value 0
		Test.Assert(Near(s.Value, 0.0));

		// Move the cursor well past the right edge of the slider - still captured, value saturates at 1.
		d.InjectMouseMove(.(250.0f, 10.0f));
		Test.Assert(Near(s.Value, 1.0));

		// Drag back to the middle.
		d.InjectMouseMove(.(50.0f, 10.0f));
		Test.Assert(Near(s.Value, 0.5));

		// Release ends the drag; a later move (button up) no longer changes the value.
		d.InjectMouseUp(.(50.0f, 10.0f), .Left);
		d.InjectMouseMove(.(90.0f, 10.0f));
		Test.Assert(Near(s.Value, 0.5));
	}

	[Test]
	public static void HoverThenPressThenDragOffStillTracksLeaveClearsPressed()
	{
		// Regression: hovering the slider first (so a MouseLeave fires when the cursor drags off)
		// used to cancel the drag - the leave clears the node's pressed state and the move gated on
		// it. The slider's own dragging flag survives the leave.
		let root = SceneFixtures.NewScene(300.0f, 200.0f);
		defer root.ReleaseRef();
		let s = NewSlider(root, 100.0f, 20.0f); // usable x in [10, 90]
		defer s.ReleaseRef();
		let d = root.EventDispatcher;

		// Hover the slider first (this is what the capture-only test skipped).
		d.InjectMouseMove(.(50.0f, 10.0f));
		Test.Assert(s.Hovered);

		// Press, then drag off the right edge - the MouseLeave must not cancel the drag.
		d.InjectMouseDown(.(50.0f, 10.0f), .Left);
		Test.Assert(Near(s.Value, 0.5));
		d.InjectMouseMove(.(250.0f, 10.0f)); // off to the right -> leave fires, then move
		Test.Assert(!s.Hovered); // the leave did happen
		Test.Assert(Near(s.Value, 1.0)); // ...but the drag kept tracking

		// Release ends the drag.
		d.InjectMouseUp(.(250.0f, 10.0f), .Left);
		d.InjectMouseMove(.(30.0f, 10.0f));
		Test.Assert(Near(s.Value, 1.0)); // no longer dragging
	}

	[Test]
	public static void DrawsTrackFillAndHandle()
	{
		let s = NewSlider(null, 120.0f, 20.0f);
		defer s.ReleaseRef();
		s.Value = 0.5;
		Test.Assert(WidgetFixtures.DrawnVertices(s) > 0);
	}

	/// The vertices of `s` drawn in `ring`'s colour.
	private static int RingVertices(Slider s, Color ring)
	{
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		s.Draw(dc);
		int ringVertices = 0;
		for (let v in canvas.GetBatch().Vertices)
		{
			if ((v.Color.R == ring.R) && (v.Color.G == ring.G) && (v.Color.B == ring.B))
				++ringVertices;
		}
		return ringVertices;
	}

	[Test]
	public static void VisibleFocusMarksTheThumbInTheColourOfItsFocusPart()
	{
		let s = NewSlider(null, 120.0f, 20.0f);
		defer s.ReleaseRef();
		s.Value = 0.5;
		let ring = Color(1.0f, 0.0f, 1.0f, 1.0f);
		s.FocusColor = ring;
		Test.Assert(RingVertices(s, ring) == 0);
		s.HandleFocusGained();
		Test.Assert(RingVertices(s, ring) == 0); // focused after a click: no mark
		s.FocusVisible = true;
		Test.Assert(RingVertices(s, ring) > 0); // the ring and halo round the thumb
	}

	[Test]
	public static void RightButtonDoesNotDragTheValue()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let s = NewSlider(root, 100.0f, 20.0f);
		defer s.ReleaseRef();
		let d = root.EventDispatcher;

		d.InjectMouseDown(.(50.0f, 10.0f), .Right); // right press
		d.InjectMouseMove(.(90.0f, 10.0f));
		Test.Assert(Near(s.Value, 0.0)); // unchanged - only the left button drags
	}

	[Test]
	public static void ADragReportsInputAsItGoesAndOneChangeOnReleaseKeysAndTheWheelStep()
	{
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let s = NewSlider(null, 100.0f, 20.0f); // usable x in [10, 90]
		defer s.ReleaseRef();
		s.Max = 100.0;
		s.Step = 1.0;
		root.AddChild(s);
		let d = root.EventDispatcher;
		int inputs = 0;
		int changes = 0;
		int changeEvents = 0;
		s.SetOnValueChanging(new [&] (value) => { inputs++; });
		s.SetOnValueChanged(new [&] (value) => { changes++; });
		s.AddEventListener(.Changed, new [&] (e) => { changeEvents++; });
		d.InjectMouseDown(.(30.0f, 10.0f), .Left); // 25
		d.InjectMouseMove(.(50.0f, 10.0f)); // 50
		d.InjectMouseMove(.(70.0f, 10.0f)); // 75
		Test.Assert(Near(s.Value, 75.0));
		Test.Assert(inputs == 3);
		Test.Assert(changes == 0);
		d.InjectMouseUp(.(70.0f, 10.0f), .Left);
		Test.Assert(changes == 1);
		Test.Assert(changeEvents == 1);

		s.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Right);
		Test.Assert(Near(s.Value, 76.0)); // its step
		d.InjectKeyDown((uint32)KeyCode.PageDown);
		Test.Assert(Near(s.Value, 66.0)); // a tenth of the range
		s.Page = 25.0;
		d.InjectKeyDown((uint32)KeyCode.PageUp);
		Test.Assert(Near(s.Value, 91.0));
		d.InjectKeyDown((uint32)KeyCode.End);
		Test.Assert(Near(s.Value, 100.0));
		Test.Assert(changes == 5);

		// The wheel over it steps it; at its end it is left to what holds the slider.
		int wheelsAbove = 0;
		root.AddEventListener(.MouseWheel, new [&] (e) => { wheelsAbove++; });
		d.InjectMouseWheel(.(50.0f, 10.0f), .(0.0f, 1.0f));
		Test.Assert(Near(s.Value, 100.0));
		Test.Assert(wheelsAbove == 1); // it could not move: the wheel went on up
		d.InjectMouseWheel(.(50.0f, 10.0f), .(0.0f, -2.0f));
		Test.Assert(Near(s.Value, 98.0));
		Test.Assert(wheelsAbove == 1);
	}

	[Test]
	public static void EscapeDuringADragPutsTheValueBackAndReportsItCancelledTheWheelMayBeLeftToWhatHoldsIt()
	{
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let s = NewSlider(null, 100.0f, 20.0f); // usable x in [10, 90]
		defer s.ReleaseRef();
		s.Max = 100.0;
		s.Step = 1.0;
		s.Value = 40.0;
		root.AddChild(s);
		let d = root.EventDispatcher;
		int changes = 0;
		int cancels = 0;
		s.SetOnValueChanged(new [&] (value) => { changes++; });
		s.SetOnValueCancelled(new [&] () => { cancels++; });
		s.RequestFocus();
		d.InjectMouseDown(.(70.0f, 10.0f), .Left); // 75
		Test.Assert(s.IsDragging);
		Test.Assert(Near(s.Value, 75.0));
		d.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!s.IsDragging);
		Test.Assert(Near(s.Value, 40.0)); // as before the drag
		Test.Assert(cancels == 1);
		d.InjectMouseMove(.(30.0f, 10.0f));
		d.InjectMouseUp(.(30.0f, 10.0f), .Left);
		Test.Assert(Near(s.Value, 40.0)); // the release after it changes nothing
		Test.Assert(changes == 0);

		// Told not to step on the wheel (in a scrolling list), the wheel goes on to what holds it.
		s.StepsOnWheel = false;
		int wheelsAbove = 0;
		root.AddEventListener(.MouseWheel, new [&] (e) => { wheelsAbove++; });
		d.InjectMouseWheel(.(50.0f, 10.0f), .(0.0f, 1.0f));
		Test.Assert(Near(s.Value, 40.0));
		Test.Assert(wheelsAbove == 1);
	}

	[Test]
	public static void VerticalGrowsUpwardExponentialSpreadsAWideRange()
	{
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let s = new Slider();
		defer s.ReleaseRef();
		s.OrientationName = "vertical";
		s.Size = .(20.0f, 100.0f); // usable y in [10, 90]
		root.AddChild(s);
		let d = root.EventDispatcher;
		d.InjectMouseDown(.(10.0f, 30.0f), .Left); // a quarter down: 0.75
		Test.Assert(Near(s.Value, 0.75));
		d.InjectMouseUp(.(10.0f, 30.0f), .Left);
		s.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Up);
		Test.Assert(Near(s.Value, 0.8));

		var hz = RangeValue();
		hz.Min = 20.0;
		hz.Max = 20000.0;
		hz.Exponential = true;
		Test.Assert(Near(hz.FromRatio(0.5), 632.45, 0.01)); // the geometric middle
		hz.Value = 2000.0;
		Test.Assert(Near(hz.Ratio, 2.0 / 3.0, 0.01));
		var steps = RangeValue();
		steps.Step = 0.25;
		Test.Assert(steps.Decimals == 2);
	}

	[Test]
	public static void AStepReadFromAFloatShowsItsOwnDecimalsAndLeavesNoErrorInTheValue()
	{
		var range = RangeValue();
		range.Min = 0.0;
		range.Max = 1000.0;
		range.Step = (double)0.1f; // 0.100000001: a reflected range's step
		Test.Assert(range.Decimals == 1);
		Test.Assert(range.Constrain(12.0) == 12.0); // not 12.0000001788
		Test.Assert(Near(range.Constrain(0.6), 0.6, 1e-12));
		range.Min = -8.0;
		range.Max = 8.0;
		Test.Assert(range.Constrain(0.0) == 0.0); // not 1.2e-07
		range.Step = (double)0.05f;
		Test.Assert(range.Decimals == 2);
		range.Step = 0.25;
		Test.Assert(range.Decimals == 2);
		range.Step = 1.0;
		Test.Assert(range.Decimals == 0);
	}
}
