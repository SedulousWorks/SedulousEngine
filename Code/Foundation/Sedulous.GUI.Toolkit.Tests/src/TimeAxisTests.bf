using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// Counts what an axis tells it.
class CountingAxisClient : ITimeAxisClient
{
	public int Changes = 0;

	public void OnTimeAxisChanged()
	{
		++Changes;
	}
}

/// A ruler 500 across in a root 600 by 100, on an axis of its own. The root goes with it.
class RulerBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public TimeAxis Axis = new .() ~ _.ReleaseRef();
	public TimeRuler Ruler = new .() ~ _.ReleaseRef();

	public this()
	{
		Root = NewRoot(600.0f, 100.0f);
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		Ruler.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(500.0f); });
		Root.AddChild(Ruler);
		Ruler.TimeAxis = Axis;
		Root.UpdateLayout();
	}

	public EventDispatcher D => Root.EventDispatcher;
}

/// One time axis: the scale, the scroll, a frame rate and the playhead held once and told to every
/// view on it; the ruler's ticks at a step whose labels never collide, in seconds or frames; a drag on
/// it scrubbing, the wheel zooming about the pointer and a middle drag panning.
class TimeAxisTests
{
	[Test]
	public static void OffsetsFollowTheScaleAndTheScrollAndAZoomKeepsTheTimeUnderThePointer()
	{
		let axis = new TimeAxis();
		defer axis.ReleaseLastRef();
		axis.Duration = 20.0f;
		axis.PixelsPerSecond = 50.0f;
		axis.Scroll = 2.0f;
		CheckNear(axis.TimeToOffset(4.0f), 100.0f);
		CheckNear(axis.OffsetToTime(100.0f), 4.0f);

		axis.ZoomAbout(4.0f, 2.0f);
		CheckNear(axis.PixelsPerSecond, 100.0f);
		CheckNear(axis.TimeToOffset(4.0f), 100.0f);

		axis.Frame(5.0f, 10.0f, 250.0f);
		CheckNear(axis.Scroll, 5.0f);
		CheckNear(axis.TimeToOffset(10.0f), 250.0f);
	}

	[Test]
	public static void TheScrollAndThePlayheadStayInTheClipAFrameRateSnaps()
	{
		let axis = new TimeAxis();
		defer axis.ReleaseLastRef();
		axis.Duration = 4.0f;
		axis.Scroll = -1.0f;
		Test.Assert(axis.Scroll == 0.0f);
		axis.Scroll = 9.0f;
		Test.Assert(axis.Scroll == 4.0f);
		axis.Playhead = 7.0f;
		Test.Assert(axis.Playhead == 4.0f);
		axis.Duration = 2.0f;
		Test.Assert(axis.Scroll == 2.0f);
		Test.Assert(axis.Playhead == 2.0f);

		Test.Assert(axis.Snap(0.37f) == 0.37f);
		axis.FrameRate = 10.0f;
		CheckNear(axis.Snap(0.37f), 0.4f);
	}

	[Test]
	public static void EveryViewOnItIsToldOfAChangeAndOneThatLeavesIsNot()
	{
		let axis = new TimeAxis();
		defer axis.ReleaseLastRef();
		let a = scope CountingAxisClient();
		let b = scope CountingAxisClient();
		axis.Join(a);
		axis.Join(b);
		axis.PixelsPerSecond = 80.0f;
		axis.Playhead = 1.0f;
		Test.Assert(a.Changes == 2);
		Test.Assert(b.Changes == 2);
		axis.Leave(a);
		axis.Scroll = 1.0f;
		Test.Assert(a.Changes == 2);
		Test.Assert(b.Changes == 3);
		axis.Scroll = 1.0f; // no change, no word
		Test.Assert(b.Changes == 3);

		float played = -1.0f;
		axis.SetOnPlayheadChanged(new [&] (t) => { played = t; });
		axis.Playhead = 2.5f;
		CheckNear(played, 2.5f);
		axis.SetOnPlayheadChanged(null);
		axis.Leave(b);
	}

	[Test]
	public static void TheTickStepIsOneTwoOrFiveTimesAPowerOfTenOfSecondsOrOfFrames()
	{
		let axis = new TimeAxis();
		defer axis.ReleaseLastRef();
		axis.PixelsPerSecond = 100.0f;
		CheckNear(axis.TickStep(60.0f), 1.0f); // 0.6 s at least
		CheckNear(axis.TickStep(100.0f), 1.0f);
		CheckNear(axis.TickStep(150.0f), 2.0f);
		axis.PixelsPerSecond = 1000.0f;
		CheckNear(axis.TickStep(60.0f), 0.1f);
		CheckNear(axis.TickStep(150.0f), 0.2f);
		CheckNear(axis.TickStep(300.0f), 0.5f);
		Test.Assert(axis.FormatTime(0.3f, 0.1f, .. scope String()) == "0.3");
		Test.Assert(axis.FormatTime(4.0f, 2.0f, .. scope String()) == "4");

		// Frames: never less than one, and labels are frame numbers.
		axis.FrameRate = 30.0f;
		CheckNear(axis.TickStep(60.0f) * 30.0f, 2.0f); // 1.8 frames at least
		axis.PixelsPerSecond = 100000.0f; // clamped, but a frame is still the least
		CheckNear(axis.TickStep(1.0f) * 30.0f, 1.0f);
		Test.Assert(axis.FormatTime(0.5f, 1.0f / 30.0f, .. scope String()) == "15");
	}

	[Test]
	public static void ItsLabelledTicksAreAtLeastTheSpacingApartAndCoverWhatItShows()
	{
		let bed = scope RulerBed();
		bed.Axis.Duration = 100.0f;
		bed.Axis.PixelsPerSecond = 100.0f;
		let ticks = scope List<TimeTick>();
		defer { ClearAndDeleteItems!(ticks); }
		bed.Ruler.GetTicks(ticks);
		Test.Assert(!ticks.IsEmpty);
		Test.Assert(ticks[0].Time == 0.0f);
		Test.Assert(ticks[0].Major);
		Test.Assert(ticks[0].Label == "0");
		float lastMajor = -1000.0f;
		int majors = 0;
		for (let tick in ticks)
		{
			Test.Assert(tick.Offset <= 500.0f + 0.01f);
			if (!tick.Major)
				continue;
			Test.Assert(tick.Offset - lastMajor >= TimeRuler.cMinLabelSpacing - 0.01f);
			lastMajor = tick.Offset;
			++majors;
		}
		Test.Assert(majors == 6); // 0 to 5 at 100 px a second over 500 px
		Test.Assert(ticks.Count == 26); // fifths of a second between them

		// Scrolled to 2.5 s, the first tick is the first minor one in view.
		bed.Axis.Scroll = 2.5f;
		bed.Ruler.GetTicks(ticks);
		CheckNear(ticks[0].Time, 2.6f);
		CheckNear(ticks[0].Offset, 10.0f);
	}

	[Test]
	public static void ADragScrubsThePlayheadOnFramesWithAFrameRate()
	{
		let bed = scope RulerBed();
		bed.Axis.Duration = 4.0f;
		bed.Axis.PixelsPerSecond = 100.0f;
		bed.Axis.FrameRate = 10.0f;
		bed.D.InjectMouseMove(.(123.0f, 10.0f));
		bed.D.InjectMouseDown(.(123.0f, 10.0f), .Left);
		CheckNear(bed.Axis.Playhead, 1.2f);
		bed.D.InjectMouseMove(.(257.0f, 10.0f));
		CheckNear(bed.Axis.Playhead, 2.6f);
		bed.D.InjectMouseMove(.(580.0f, 40.0f)); // past its end: held, kept in the clip
		CheckNear(bed.Axis.Playhead, 4.0f);
		bed.D.InjectMouseUp(.(580.0f, 40.0f), .Left);
		bed.D.InjectMouseMove(.(50.0f, 10.0f));
		CheckNear(bed.Axis.Playhead, 4.0f);
	}

	[Test]
	public static void TheWheelZoomsAboutThePointerAndAMiddleDragPans()
	{
		let bed = scope RulerBed();
		bed.Axis.Duration = 60.0f;
		bed.Axis.PixelsPerSecond = 100.0f;
		bed.Axis.Scroll = 1.0f;
		let under = bed.Axis.OffsetToTime(200.0f); // 3 s
		bed.D.InjectMouseMove(.(200.0f, 10.0f));
		bed.D.InjectMouseWheel(.(200.0f, 10.0f), .(0.0f, 1.0f));
		CheckNear(bed.Axis.PixelsPerSecond, 120.0f);
		CheckNear(bed.Axis.OffsetToTime(200.0f), under);
		bed.D.InjectMouseWheel(.(200.0f, 10.0f), .(0.0f, -1.0f));
		CheckNear(bed.Axis.PixelsPerSecond, 100.0f);

		bed.D.InjectMouseDown(.(200.0f, 10.0f), .Middle);
		bed.D.InjectMouseMove(.(100.0f, 10.0f));
		CheckNear(bed.Axis.Scroll, 2.0f);
		bed.D.InjectMouseUp(.(100.0f, 10.0f), .Middle);
		Test.Assert(bed.Axis.Playhead == 0.0f); // panning is not scrubbing
	}

	[Test]
	public static void ARulerThatGoesLeavesItsAxis()
	{
		let axis = new TimeAxis();
		defer axis.ReleaseLastRef();
		{
			let ruler = new TimeRuler();
			ruler.TimeAxis = axis;
			Test.Assert(axis.ClientCount == 1);
			let other = new TimeAxis();
			ruler.TimeAxis = other;
			Test.Assert(axis.ClientCount == 0);
			ruler.TimeAxis = axis;
			other.ReleaseRef(); // the ruler held it until it moved on
			ruler.ReleaseRef();
		}
		Test.Assert(axis.ClientCount == 0);
		axis.Scroll = 1.0f; // nothing left to tell
	}

	// What no Raptor test covers: a value to the decimals of its step, rounded half away from zero
	// (a step of 0.25 is one decimal: its tenfold, 2.5, ends the count).
	[Test]
	public static void AValueIsFormattedToTheDecimalsOfItsStep()
	{
		Test.Assert(FormatStepped(1.25f, 0.25f, .. scope String()) == "1.3");
		Test.Assert(FormatStepped(7.6f, 5.0f, .. scope String()) == "8");
		Test.Assert(FormatStepped(-0.54f, 0.1f, .. scope String()) == "-0.5");
	}
}
