using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Profiler;
using Sedulous.Profiler.GUI;
using Sedulous.Profiler.Tests; // KnownSource

namespace Sedulous.Profiler.GUI.Tests;

/// The timeline (X7 of Raptor's editor-gui spec): the frames chosen as lanes (each thread, then the
/// GPU) with their scopes by depth, fitted when the frames change; scopes too narrow to draw gathered
/// into one block with their count; a click choosing a scope's name (on nothing, none), the hover
/// naming it; a double click zooming to a scope or fitting again; the wheel zooming about the pointer,
/// Shift and the wheel scrolling the lanes, a drag panning; a drag on the ruler marking a span, a click
/// there letting it go; a lane folded to one row.
class ProfileTimelineTests
{
	private static bool Near(double a, double b, double epsilon = 1e-3) => Math.Abs(a - b) <= epsilon;

	/// A timeline 728 by 300 (names 128, the plot 600), frame 1 chosen: ticks 1010 to 1020 shown as
	/// 1009.9 to 1020.1, a tick 600 / 10.2 pixels. Lanes: Main at 42 (two rows), Worker at 84, GPU at
	/// 108.
	private class Bed
	{
		public KnownSource Source = new .() ~ delete _;
		public SceneRoot Root;
		public ProfileFocus Focus = new .() ~ _.ReleaseRef();
		public ProfileTimeline Timeline = new .() ~ _.ReleaseRef();
		public uint32 Update, Physics, Render, Job, Shadows, Lighting, Tiny;

		public this()
		{
			Update = Source.Name("Update");
			Physics = Source.Name("Physics");
			Render = Source.Name("Render");
			Job = Source.Name("Job");
			Shadows = Source.Name("Shadows");
			Lighting = Source.Name("Lighting");
			Tiny = Source.Name("Tiny");
			let worker = Source.Thread("Worker");
			let f0 = Source.AddFrame(10);
			KnownSource.AddScope(f0, Update, 0, 0, 8);
			let f1 = Source.AddFrame(10);
			KnownSource.AddScope(f1, Physics, 1, 2, 6);
			KnownSource.AddScope(f1, Render, 1, 6, 8);
			KnownSource.AddScope(f1, Update, 0, 1, 9);
			KnownSource.AddScopeOn(f1, worker, Job, 0, 2, 7);
			KnownSource.AddPass(f1, Shadows, 3, 5);
			KnownSource.AddPass(f1, Lighting, 5, 9);
			// Frame 2, a second long: thirty scopes of a tick under one, too narrow to draw apart.
			let f2 = Source.AddFrame(1000);
			for (int64 i < 30)
				KnownSource.AddScope(f2, Tiny, 1, 100 + i, 101 + i);
			KnownSource.AddScope(f2, Update, 0, 0, 900);

			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(800.0f, 400.0f);
			Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
			Timeline.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(728.0f);
					s.Height = LayoutLength.Px(300.0f);
				});
			Root.AddChild(Timeline);
			Timeline.Focus = Focus;
			Focus.SetSource(Source);
			Focus.SetFrame(1);
			Root.UpdateLayout();
			Timeline.FitView(); // laid out now: the frames fill the plot
		}

		public ~this()
		{
			Focus.SetSource(null);
			Root.ReleaseRef();
		}

		public EventDispatcher D => Root.EventDispatcher;
		public static float X(double tick) => 128.0f + (float)((tick - 1009.9) / 10.2 * 600.0);

		public void Click(Float2 at, uint32 modifiers = 0)
		{
			D.InjectMouseMove(at, modifiers);
			D.InjectMouseDown(at, .Left, modifiers);
			D.InjectMouseUp(at, .Left, modifiers);
		}

		public void DoubleClick(Float2 at)
		{
			Click(at);
			D.InjectMouseDown(at, .Left);
			D.InjectMouseUp(at, .Left);
		}

		public void Drag(Float2 from, Float2 to)
		{
			D.InjectMouseMove(from);
			D.InjectMouseDown(from, .Left);
			D.InjectMouseMove(.((from.X + to.X) * 0.5f, (from.Y + to.Y) * 0.5f));
			D.InjectMouseMove(to);
			D.InjectMouseUp(to, .Left);
		}

		public void Pause() => Click(.(790.0f, 390.0f));

		/// The bar of `name` (not a block), its index in Bars; -1: none.
		public int BarOf(uint32 name, bool gpu = false)
		{
			let bars = Timeline.Bars;
			for (int i < bars.Length)
			{
				if ((bars[i].Name == name) && (bars[i].Gpu == gpu) && (bars[i].Merged == 0))
					return i;
			}
			return -1;
		}
	}

	[Test]
	public static void ALanePerThreadThenTheGpusTheScopesByDepthFittedToTheFrames()
	{
		let bed = scope Bed();
		Test.Assert(Near(bed.Timeline.ViewBegin, 1009.9));
		Test.Assert(Near(bed.Timeline.ViewEnd, 1020.1));
		let lanes = bed.Timeline.Lanes;
		Test.Assert(lanes.Length == 3);
		Test.Assert(lanes[0].Name == "Main");
		Test.Assert(lanes[0].Depths == 2);
		Test.Assert(Near(lanes[0].Y, 42.0));
		Test.Assert(lanes[1].Name == "Worker");
		Test.Assert(Near(lanes[1].Y, 84.0));
		Test.Assert(lanes[2].Gpu);
		Test.Assert(Near(lanes[2].Y, 108.0));

		let physics = bed.BarOf(bed.Physics);
		Test.Assert(physics >= 0);
		let bar = bed.Timeline.Bars[physics];
		Test.Assert(bar.LaneIndex == 0);
		Test.Assert(bar.Depth == 1);
		Test.Assert(Near(bar.Box.X, Bed.X(1012.0), 0.5));
		Test.Assert(Near(bar.Box.Y, 61.0));
		let shadows = bed.BarOf(bed.Shadows, true);
		Test.Assert(shadows >= 0);
		Test.Assert(bed.Timeline.Bars[shadows].LaneIndex == 2);
		Test.Assert(bed.BarOf(bed.Tiny) < 0, "frame 2's: not chosen");
	}

	[Test]
	public static void ScopesTooNarrowToDrawGatherIntoOneBlockWithTheirCount()
	{
		let bed = scope Bed();
		bed.Focus.SetFrame(2);
		var found = false;
		for (let bar in bed.Timeline.Bars)
		{
			if (bar.Merged > 0)
			{
				Test.Assert(bar.Merged == 30);
				Test.Assert(bar.Depth == 1);
				found = true;
			}
		}
		Test.Assert(found);
		// Zoomed in, they are scopes of their own again.
		Test.Assert(bed.BarOf(bed.Update) >= 0);
		bed.Timeline.ZoomTo(1020.0 + 100.0, 1020.0 + 130.0); // frame 2 starts at 1020
		int tiny = 0;
		for (let bar in bed.Timeline.Bars)
		{
			if ((bar.Name == bed.Tiny) && (bar.Merged == 0))
				tiny++;
		}
		Test.Assert(tiny == 30);
	}

	[Test]
	public static void AClickChoosesAScopesNameOnNothingNoneTheHoverNamesIt()
	{
		let bed = scope Bed();
		bed.Click(.(Bed.X(1014.0), 69.0f)); // Physics
		Test.Assert(bed.Focus.Name.Is(bed.Physics, false));
		Test.Assert(bed.Timeline.IsChosen(bed.Timeline.Bars[bed.BarOf(bed.Physics)]));
		Test.Assert(!bed.Timeline.IsChosen(bed.Timeline.Bars[bed.BarOf(bed.Update)]));
		bed.Pause();
		bed.Click(.(Bed.X(1014.0), 117.0f)); // the GPU's Shadows
		Test.Assert(bed.Focus.Name.Is(bed.Shadows, true));
		bed.Pause();
		bed.Click(.(400.0f, 250.0f)); // under the lanes
		Test.Assert(!bed.Focus.Name.Any);

		bed.D.InjectMouseMove(.(Bed.X(1015.0), 51.0f));
		let hovered = bed.Timeline.Hovered;
		Test.Assert(hovered >= 0);
		Test.Assert(bed.Timeline.Bars[hovered].Name == bed.Update);
		Test.Assert(bed.Timeline.TooltipText == "Update  8.000 ms", scope String(bed.Timeline.TooltipText));
	}

	[Test]
	public static void ADoubleClickZoomsToAScopeOnNothingFitsFitInTheCornerFits()
	{
		let bed = scope Bed();
		bed.DoubleClick(.(Bed.X(1014.0), 69.0f)); // Physics, 1012 to 1016
		Test.Assert(Near(bed.Timeline.ViewBegin, 1011.96));
		Test.Assert(Near(bed.Timeline.ViewEnd, 1016.04));
		bed.Pause();
		bed.DoubleClick(.(400.0f, 250.0f));
		Test.Assert(Near(bed.Timeline.ViewBegin, 1009.9));
		bed.Timeline.ZoomTo(1012.0, 1013.0);
		bed.Pause();
		bed.Click(.(60.0f, 18.0f)); // the corner
		Test.Assert(Near(bed.Timeline.ViewEnd, 1020.1));
	}

	[Test]
	public static void TheWheelZoomsAboutThePointerShiftAndTheWheelScrollADragPans()
	{
		let bed = scope Bed();
		let x = Bed.X(1015.0);
		bed.D.InjectMouseWheel(.(x, 51.0f), .(0.0f, 1.0f));
		Test.Assert(Near(bed.Timeline.ViewEnd - bed.Timeline.ViewBegin, 10.2 / 1.25));
		Test.Assert(Near(bed.Timeline.TickAt(x), 1015.0), "the time under the pointer stays");

		let before = bed.Timeline.ViewBegin;
		bed.Drag(.(400.0f, 51.0f), .(460.0f, 51.0f)); // right: earlier time
		Test.Assert(bed.Timeline.ViewBegin < before);
		Test.Assert(!bed.Focus.Name.Any, "a drag chooses nothing");

		// Not enough lanes to scroll in 300 pixels: the scroll stays at the top.
		bed.D.InjectMouseWheel(.(x, 51.0f), .(0.0f, -1.0f), KeyModShift);
		Test.Assert(bed.Timeline.LaneScroll == 0.0f);
	}

	[Test]
	public static void ADragOnTheRulerMarksASpanAClickThereLetsItGo()
	{
		let bed = scope Bed();
		bed.Drag(.(Bed.X(1012.0), 10.0f), .(Bed.X(1016.0), 10.0f));
		Test.Assert(bed.Focus.Span.Any);
		Test.Assert(bed.Focus.Span.BeginTick == 1012);
		Test.Assert(bed.Focus.Span.EndTick == 1016);
		bed.Pause();
		bed.Click(.(Bed.X(1018.0), 10.0f));
		Test.Assert(!bed.Focus.Span.Any);
	}

	[Test]
	public static void AClickOnALanesArrowFoldsItToOneRowOfItsTopScopes()
	{
		let bed = scope Bed();
		bed.Click(.(8.0f, 51.0f)); // Main's arrow
		Test.Assert(bed.Timeline.IsFolded(0));
		let lanes = bed.Timeline.Lanes;
		Test.Assert(lanes[0].Folded);
		Test.Assert(Near(lanes[0].Height, ProfileTimeline.cRowHeight));
		Test.Assert(Near(lanes[1].Y, 66.0));
		Test.Assert(bed.BarOf(bed.Physics) < 0);
		Test.Assert(bed.BarOf(bed.Update) >= 0);
		bed.Pause();
		bed.Click(.(8.0f, 51.0f));
		Test.Assert(!bed.Timeline.IsFolded(0));
	}
}
