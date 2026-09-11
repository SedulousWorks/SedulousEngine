using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The curve editor: its model, its evaluation, and the two things about the value axis that
/// were once wrong.
class CurveCanvasTests
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

	/// One channel, a pinned value frame, and a laid out canvas, which is what every input case
	/// needs before it can compute a screen position.
	private static CurveCanvas OneChannel(float timeSpan, float width, float height)
	{
		let canvas = new CurveCanvas();
		ChannelDescriptor[1] channels = .(.("X", Color.Rgb(255, 0, 0)));
		canvas.SetChannels(channels);
		canvas.TimeSpan = timeSpan;

		// PINNED: hit testing auto fits first, with a margin, so positions computed from the
		// defaults would miss the keys and click-add instead of selecting.
		canvas.AutoFitValueRange = false;
		canvas.ValueMin = 0.0f;
		canvas.ValueMax = 1.0f;

		canvas.Measure(BoxConstraints.Tight(width, height));
		canvas.Layout(0, 0, width, height);
		return canvas;
	}

	[Test]
	public static void AFreshCanvasHasNoChannelsAndSensibleDefaults()
	{
		let canvas = new CurveCanvas();
		defer canvas.ReleaseRef();

		Test.Assert(canvas.ChannelCount == 0);
		Test.Assert(canvas.SelectedChannel == -1);
		Test.Assert(canvas.SelectedKeyIndex == -1);
		Test.Assert(canvas.MaxKeys == 8);
		Test.Assert(!canvas.LinkedTime);
		Test.Assert(canvas.AutoFitValueRange);
		Test.Assert(canvas.ValueMin == 0.0f);
		Test.Assert(canvas.ValueMax == 1.0f);
	}

	[Test]
	public static void SetChannelsResetsTheSelectionToTheFirst()
	{
		let canvas = new CurveCanvas();
		defer canvas.ReleaseRef();

		ChannelDescriptor[2] channels = .(.("X", Color.Rgb(255, 0, 0)), .("Y", Color.Rgb(0, 255, 0)));
		channels[1].Interpolation = .Linear;
		canvas.SetChannels(channels);

		Test.Assert(canvas.ChannelCount == 2);
		Test.Assert(canvas.SelectedChannel == 0);
		Test.Assert(canvas.SelectedKeyIndex == -1);
		Test.Assert(canvas.GetChannelDescriptor(1).Interpolation == .Linear);
		Test.Assert(canvas.GetChannelDescriptor(1).Name == "Y");
		Test.Assert(canvas.GetKeyCount(0) == 0);
		Test.Assert(canvas.GetKeyCount(1) == 0);
	}

	[Test]
	public static void KeysRoundTripAndAnUnknownChannelIsANoOp()
	{
		let canvas = new CurveCanvas();
		defer canvas.ReleaseRef();

		ChannelDescriptor[1] channels = .(.("V", Color.White));
		canvas.SetChannels(channels);

		CurveCanvas.Key[3] keys = .(.(0.0f, 0.0f), .(0.5f, 1.0f, 0.25f, -0.25f, .Free),
			.(1.0f, 0.0f));
		canvas.SetKeys(0, keys);
		Test.Assert(canvas.GetKeyCount(0) == 3);

		let key = canvas.GetKey(0, 1);
		Test.Assert(key.Time == 0.5f);
		Test.Assert(key.Value == 1.0f);
		Test.Assert(key.TangentIn == 0.25f);
		Test.Assert(key.TangentOut == -0.25f);
		Test.Assert(key.Mode == .Free);

		canvas.SetKeys(5, keys);
		Test.Assert(canvas.GetKeyCount(0) == 3, "an out of range channel changes nothing");
	}

	/// The three interpolations, each at the midpoint between two keys where they differ most.
	[Test]
	public static void EachInterpolationFillsTheGapItsOwnWay()
	{
		let canvas = new CurveCanvas();
		defer canvas.ReleaseRef();

		ChannelDescriptor[3] channels = .(.("H", Color.White), .("L", Color.White),
			.("S", Color.White));
		channels[0].Interpolation = .Hermite;
		channels[1].Interpolation = .Linear;
		channels[2].Interpolation = .Step;
		canvas.SetChannels(channels);

		// Flat tangents, so Hermite and Linear disagree in a way that is easy to state.
		CurveCanvas.Key[2] keys = .(.(0.0f, 0.0f), .(1.0f, 1.0f));
		for (int32 c = 0; c < 3; c++)
			canvas.SetKeys(c, keys);

		Test.Assert(Near(canvas.Evaluate(0, 0.5f), 0.5f), "the cubic is symmetric at the middle");
		Test.Assert(Near(canvas.Evaluate(1, 0.5f), 0.5f));
		Test.Assert(Near(canvas.Evaluate(2, 0.5f), 0.0f), "a step holds the earlier value");

		// A flat Hermite EASES: at a quarter it has moved less than a straight line would.
		Test.Assert(canvas.Evaluate(0, 0.25f) < canvas.Evaluate(1, 0.25f));

		// Flat outside the ends, whatever the interpolation.
		for (int32 c = 0; c < 3; c++)
		{
			Test.Assert(canvas.Evaluate(c, -1.0f) == 0.0f);
			Test.Assert(canvas.Evaluate(c, 2.0f) == 1.0f);
		}
	}

	/// A REGRESSION GATE. The value readout once only LOOKED selection driven: it followed the
	/// scrub time, and there was no selection event at all. Every key pick must report itself.
	[Test]
	public static void ClickingAnyKeyReportsTheSelection()
	{
		let canvas = OneChannel(4.0f, 400.0f, 100.0f);
		defer canvas.ReleaseRef();

		CurveCanvas.Key[3] keys = .(.(0.0f, 0.0f), .(2.0f, 0.5f), .(4.0f, 1.0f));
		canvas.SetKeys(0, keys);

		var selectedChannel = -2;
		var selectedKey = -2;
		var fires = 0;
		canvas.OnSelectionChanged.Add(new [&](channel, key) =>
			{
				selectedChannel = channel;
				selectedKey = key;
				fires++;
			});

		// Four seconds across four hundred pixels, so t = 2 sits at x = 200.
		float[3] keyX = .(0.0f, 200.0f, 400.0f);
		for (int32 i = 0; i < 3; i++)
		{
			let down = Mouse(keyX[i], 100.0f * (1.0f - keys[i].Value));
			defer delete down;
			canvas.OnMouseDown(down);

			let up = Mouse(keyX[i], 100.0f * (1.0f - keys[i].Value));
			defer delete up;
			canvas.OnMouseUp(up);

			Test.Assert(selectedChannel == 0);
			Test.Assert(selectedKey == i);
		}

		Test.Assert(fires == 3, "one per pick, none skipped and none duplicated");
	}

	/// A REGRESSION GATE on the range trap: dragging once mapped through a CLAMPED conversion,
	/// so any value outside the framed range could not be reached by dragging at all.
	[Test]
	public static void DraggingPastTheEdgeExtrapolatesRatherThanClamping()
	{
		let canvas = OneChannel(2.0f, 200.0f, 100.0f);
		defer canvas.ReleaseRef();

		CurveCanvas.Key[2] keys = .(.(0.0f, 0.0f), .(2.0f, 1.0f));
		canvas.SetKeys(0, keys);

		// Grab the key at t = 2, which sits at the top right corner, and drag a full canvas
		// height ABOVE the top edge.
		let down = Mouse(200.0f, 0.0f);
		defer delete down;
		canvas.OnMouseDown(down);

		let move = Mouse(200.0f, -100.0f);
		defer delete move;
		canvas.OnMouseMove(move);

		let up = Mouse(200.0f, -100.0f);
		defer delete up;
		canvas.OnMouseUp(up);

		Test.Assert(Near(canvas.GetKey(0, 1).Value, 2.0f), "one height above the top is 2.0");
	}

	[Test]
	public static void TheWheelZoomsTheValueAxisAndPinsTheFrame()
	{
		let canvas = OneChannel(2.0f, 200.0f, 100.0f);
		defer canvas.ReleaseRef();

		let wheel = scope MouseWheelEventArgs();
		wheel.Y = 50.0f;
		wheel.DeltaY = 1.0f;

		let spanBefore = canvas.ValueMax - canvas.ValueMin;
		canvas.OnMouseWheel(wheel);

		Test.Assert((canvas.ValueMax - canvas.ValueMin) < spanBefore);
		Test.Assert(!canvas.AutoFitValueRange, "the user framed it, so auto fit stops");
	}

	/// A pan SHIFTS the frame without resizing it.
	[Test]
	public static void MiddleDraggingPansTheValueFrame()
	{
		let canvas = OneChannel(2.0f, 200.0f, 100.0f);
		defer canvas.ReleaseRef();

		let low = canvas.ValueMin;
		let high = canvas.ValueMax;

		let down = Mouse(100.0f, 50.0f, .Middle);
		defer delete down;
		canvas.OnMouseDown(down);
		Test.Assert(down.Handled);

		let move = Mouse(100.0f, 30.0f, .Middle);
		defer delete move;
		canvas.OnMouseMove(move);

		let up = Mouse(100.0f, 30.0f, .Middle);
		defer delete up;
		canvas.OnMouseUp(up);

		let shift = canvas.ValueMin - low;
		Test.Assert(shift != 0.0f);
		Test.Assert(Near(canvas.ValueMax - high, shift), "both ends moved together");
		Test.Assert(Near(canvas.ValueMax - canvas.ValueMin, high - low), "the span is unchanged");
	}

	/// Clicking empty space ADDS a key, up to the ceiling.
	[Test]
	public static void ClickingEmptySpaceAddsAKeyUpToTheLimit()
	{
		let canvas = OneChannel(4.0f, 400.0f, 100.0f);
		defer canvas.ReleaseRef();
		canvas.MaxKeys = 2;

		var added = 0;
		canvas.OnKeyAdded.Add(new [&](channel, key) => { added++; });

		for (int32 i = 0; i < 4; i++)
		{
			let down = Mouse(50.0f + (i * 60.0f), 50.0f);
			defer delete down;
			canvas.OnMouseDown(down);

			let up = Mouse(50.0f + (i * 60.0f), 50.0f);
			defer delete up;
			canvas.OnMouseUp(up);
		}

		Test.Assert(canvas.GetKeyCount(0) == 2);
		Test.Assert(added == 2, "the ceiling is enforced before the event, not after");
	}

	/// Under LINKED TIME a key belongs to every channel at once, so adding one adds it
	/// everywhere and the counts stay equal.
	[Test]
	public static void LinkedTimeKeepsEveryChannelAligned()
	{
		let canvas = new CurveCanvas();
		defer canvas.ReleaseRef();

		ChannelDescriptor[2] channels = .(.("X", Color.White), .("Y", Color.White));
		channels[1].DefaultValue = 0.25f;
		canvas.SetChannels(channels);
		canvas.LinkedTime = true;
		canvas.AutoFitValueRange = false;
		canvas.ValueMin = 0.0f;
		canvas.ValueMax = 1.0f;
		canvas.TimeSpan = 4.0f;
		canvas.Measure(BoxConstraints.Tight(400.0f, 100.0f));
		canvas.Layout(0, 0, 400.0f, 100.0f);

		let down = Mouse(200.0f, 50.0f);
		defer delete down;
		canvas.OnMouseDown(down);

		let up = Mouse(200.0f, 50.0f);
		defer delete up;
		canvas.OnMouseUp(up);

		Test.Assert(canvas.GetKeyCount(0) == 1);
		Test.Assert(canvas.GetKeyCount(1) == 1, "the other channel got one too");
		Test.Assert(canvas.GetKey(0, 0).Time == canvas.GetKey(1, 0).Time, "at the same time");
		Test.Assert(canvas.GetKey(1, 0).Value == 0.25f, "at its own declared default");
	}

	/// A LOCKED channel still draws but refuses edits.
	[Test]
	public static void ALockedChannelRefusesEdits()
	{
		let canvas = new CurveCanvas();
		defer canvas.ReleaseRef();

		ChannelDescriptor[1] channels = .(.("X", Color.White));
		channels[0].Locked = true;
		canvas.SetChannels(channels);
		canvas.AutoFitValueRange = false;
		canvas.ValueMin = 0.0f;
		canvas.ValueMax = 1.0f;
		canvas.Measure(BoxConstraints.Tight(400.0f, 100.0f));
		canvas.Layout(0, 0, 400.0f, 100.0f);

		let down = Mouse(200.0f, 50.0f);
		defer delete down;
		canvas.OnMouseDown(down);

		Test.Assert(canvas.GetKeyCount(0) == 0);
	}
}
