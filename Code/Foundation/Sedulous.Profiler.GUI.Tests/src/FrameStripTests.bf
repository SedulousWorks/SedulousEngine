using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Profiler;
using Sedulous.Profiler.GUI;
using Sedulous.Profiler.Tests; // KnownSource

namespace Sedulous.Profiler.GUI.Tests;

/// The frame strip and the counters' plots on one frame axis (X7 of Raptor's editor-gui spec): the
/// axis fitting the source and following it until a zoom or a pan; a column a frame, or the frames
/// sharing a pixel as one showing the longest; the budget's scale; a click choosing a frame, a drag a
/// range, a double click fitting again; the name chosen drawn as its share of each frame; a counter's
/// value each frame.
class FrameStripTests
{
	private static bool Near(double a, double b, double epsilon = 1e-4) => Math.Abs(a - b) <= epsilon;

	/// A strip 528 by 64 and a counter plot under it, both a 128 gutter and a 400 plot, over 40 frames
	/// of 10 ms (frame 7 of 30, frame 20 of 50): frame n's column at 128 + 10 n.
	private class Bed
	{
		public KnownSource Source = new .() ~ delete _;
		public SceneRoot Root;
		public ProfileFocus Focus = new .() ~ _.ReleaseRef();
		public FrameAxis Axis = new .() ~ _.ReleaseRef();
		public FrameStrip Strip = new .() ~ _.ReleaseRef();
		public CounterPlot Plot = new .() ~ _.ReleaseRef();
		public uint32 Update = 0;
		public uint32 Draws = 0;
		public int Picked = 0;

		public this()
		{
			Update = Source.Name("Update");
			Draws = Source.Counter("Draw calls", .Count);
			for (int n < 40)
			{
				let frame = Source.AddFrame((n == 7) ? 30 : ((n == 20) ? 50 : 10));
				KnownSource.AddScope(frame, Update, 0, 0, (n == 20) ? 30 : 4);
				frame.Counters.Add(.(Draws, 100.0 + (double)n));
			}
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(600.0f, 200.0f);
			Root.EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Column;
					s.AlignItems = .Start;
				});
			for (let view in FrameAxisView[2](Strip, Plot))
			{
				view.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(528.0f); });
				Root.AddChild(view);
				view.Focus = Focus;
				view.Axis = Axis;
			}
			Strip.SetOnFramesPicked(new [=this] () => { Picked++; });
			Focus.SetSource(Source);
			Root.UpdateLayout();
		}

		public ~this()
		{
			// The views let go of the source before it goes.
			Focus.SetSource(null);
			Root.ReleaseRef();
		}

		public EventDispatcher D => Root.EventDispatcher;
		public static Float2 At(float frame) => .(128.0f + 10.0f * frame + 5.0f, 30.0f);

		public void Click(Float2 at)
		{
			D.InjectMouseMove(at);
			D.InjectMouseDown(at, .Left);
			D.InjectMouseUp(at, .Left);
		}

		public void Pause() => Click(.(590.0f, 190.0f));
	}

	[Test]
	public static void TheAxisFitsTheSourceAndFollowsItUntilAZoomOrAPanKeptOverTheFrames()
	{
		let bed = scope Bed();
		Test.Assert(bed.Axis.Fits);
		Test.Assert(bed.Axis.First == 0.0);
		Test.Assert(bed.Axis.Count == 40.0);

		for (int i < 10)
			bed.Source.AddFrame(10);
		bed.Focus.SourceGrew();
		Test.Assert(bed.Axis.Count == 50.0, "fitting: it follows");

		bed.Axis.ZoomAbout(25.0, 2.0);
		Test.Assert(!bed.Axis.Fits);
		Test.Assert(bed.Axis.Count == 25.0);
		Test.Assert(Near(bed.Axis.First, 12.5), "frame 25 stays halfway");
		bed.Source.AddFrame(10);
		bed.Focus.SourceGrew();
		Test.Assert(bed.Axis.Count == 25.0, "not fitting: it stays");

		bed.Axis.ZoomAbout(25.0, 1000.0);
		Test.Assert(bed.Axis.Count == FrameAxis.cMinFrames);
		bed.Axis.ZoomAbout(25.0, 0.0001);
		Test.Assert(bed.Axis.Count == 51.0, "never more than every frame");
		bed.Axis.PanBy(-100.0);
		Test.Assert(bed.Axis.First == 0.0, "kept over the frames");
	}

	[Test]
	public static void AColumnAFrameOrTheFramesSharingAPixelAsOneShowingTheLongest()
	{
		let bed = scope Bed();
		let columns = scope List<FrameColumn>();
		bed.Strip.GetColumns(columns);
		Test.Assert(columns.Count == 40);
		Test.Assert(columns[7].First == 7);
		Test.Assert(Near(columns[7].X, 70.0));
		Test.Assert(Near(columns[7].Width, 10.0));

		// Two thousand frames over 400 pixels: five a column; the hitch shows in its column.
		let many = scope KnownSource();
		for (int n < 2000)
			many.AddFrame((n == 1003) ? 40 : 10);
		bed.Focus.SetSource(many);
		bed.Strip.GetColumns(columns);
		Test.Assert(columns.Count == 400);
		Test.Assert(columns[200].First == 1000);
		Test.Assert(columns[200].Last == 1004);
		let times = scope List<FrameColumnTimes>();
		bed.Strip.GetColumnTimes(columns, times);
		Test.Assert(Near(times[200].CpuMs, 40.0));
		Test.Assert(Near(times[199].CpuMs, 10.0));
		bed.Focus.SetSource(bed.Source); // before `many` goes
	}

	[Test]
	public static void TheScaleIsTwiceTheBudgetOrWithoutOneTheLongestShownRoundedUp()
	{
		let bed = scope Bed();
		let columns = scope List<FrameColumn>();
		bed.Strip.GetColumns(columns);
		let times = scope List<FrameColumnTimes>();
		bed.Strip.GetColumnTimes(columns, times);
		Test.Assert(Near(bed.Strip.ScaleMs(times), 50.0), "the 50 ms frame, already round");
		bed.Strip.BudgetMs = 16.0f;
		Test.Assert(Near(bed.Strip.ScaleMs(times), 32.0));
		bed.Strip.BudgetMs = 0.0f;
		times[20].CpuMs = 61.0f;
		Test.Assert(Near(bed.Strip.ScaleMs(times), 100.0));
	}

	[Test]
	public static void AClickChoosesAFrameADragARangeADoubleClickFitsAgain()
	{
		let bed = scope Bed();
		bed.Click(Bed.At(7));
		Test.Assert(!bed.Focus.Frames.Empty);
		Test.Assert(bed.Focus.Frames.First == 7);
		Test.Assert(bed.Focus.Frames.Last == 7);
		Test.Assert(bed.Picked == 1);

		bed.Pause();
		bed.D.InjectMouseMove(Bed.At(12));
		bed.D.InjectMouseDown(Bed.At(12), .Left);
		bed.D.InjectMouseMove(Bed.At(10));
		bed.D.InjectMouseMove(Bed.At(9));
		bed.D.InjectMouseUp(Bed.At(9), .Left);
		Test.Assert(bed.Focus.Frames.First == 9);
		Test.Assert(bed.Focus.Frames.Last == 12);

		// The chosen frames' columns say so.
		let columns = scope List<FrameColumn>();
		bed.Strip.GetColumns(columns);
		let times = scope List<FrameColumnTimes>();
		bed.Strip.GetColumnTimes(columns, times);
		Test.Assert(times[10].Chosen);
		Test.Assert(!times[13].Chosen);

		// The wheel zooms (and stops fitting); a double click fits again.
		bed.Pause();
		bed.D.InjectMouseWheel(Bed.At(20), .(0.0f, 1.0f));
		Test.Assert(!bed.Axis.Fits);
		Test.Assert(bed.Axis.Count < 40.0);
		bed.Pause();
		bed.D.InjectMouseMove(Bed.At(5));
		bed.D.InjectMouseDown(Bed.At(5), .Left);
		bed.D.InjectMouseUp(Bed.At(5), .Left);
		bed.D.InjectMouseDown(Bed.At(5), .Left);
		bed.D.InjectMouseUp(Bed.At(5), .Left);
		Test.Assert(bed.Axis.Fits);
		Test.Assert(bed.Axis.Count == 40.0);
	}

	[Test]
	public static void TheNameChosenIsItsShareOfEachFrameTheHoverNamesTheFrame()
	{
		let bed = scope Bed();
		let columns = scope List<FrameColumn>();
		bed.Strip.GetColumns(columns);
		let times = scope List<FrameColumnTimes>();
		bed.Strip.GetColumnTimes(columns, times);
		Test.Assert(times[20].ChosenMs == 0.0f);
		bed.Focus.ChooseName(bed.Update, false);
		bed.Strip.GetColumnTimes(columns, times);
		Test.Assert(Near(times[20].ChosenMs, 30.0));
		Test.Assert(Near(times[3].ChosenMs, 4.0));

		bed.D.InjectMouseMove(Bed.At(20));
		Test.Assert(bed.Strip.TooltipText == "Frame 20: 50.00 ms, Update 30.00 ms", scope String(bed.Strip.TooltipText));
	}

	[Test]
	public static void ACountersValueEachFrameTheMostOfAColumnsTheHoverNamesIt()
	{
		let bed = scope Bed();
		bed.Plot.Counter = bed.Draws;
		var column = FrameColumn();
		column.First = 3;
		column.Last = 6;
		Test.Assert(bed.Plot.ColumnValue(column, var value));
		Test.Assert(value == 106.0);
		bed.Plot.Counter = 5; // no such counter: nothing set
		Test.Assert(!bed.Plot.ColumnValue(column, out value));

		bed.Plot.Counter = bed.Draws;
		let over = Float2(Bed.At(3).X, 64.0f + 13.0f);
		bed.D.InjectMouseMove(over);
		Test.Assert(bed.Plot.TooltipText == "Draw calls at frame 3: 103", scope String(bed.Plot.TooltipText));
		// A click on the plot chooses as the strip's does.
		bed.Click(over);
		Test.Assert(bed.Focus.Frames.First == 3);
	}
}
