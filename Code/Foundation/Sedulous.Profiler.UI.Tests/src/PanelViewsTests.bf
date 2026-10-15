using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.UI;
using Sedulous.Profiler;
using Sedulous.Profiler.UI;

namespace Sedulous.Profiler.UI.Tests;

/// The editor panel's views: the frame strip that selects frames, the timeline that lays the
/// selection out on one time axis, and the scope table that totals it by name.
class PanelViewsTests
{
	private static bool Near(double a, double b) => ProfileWindowTests.Near(a, b);

	private static void Stage(View view, float width, float height)
	{
		view.Measure(.Tight(width, height));
		view.Layout(0, 0, width, height);
	}

	private static int Draw(View view)
	{
		let vg = scope VGContext();
		let ctx = scope UIDrawContext(vg, 1.0f);
		view.OnDraw(ctx);
		return vg.GetBatch().Vertices.Count;
	}

	private static void Mouse(MouseEventArgs e, float x, float y, int32 clicks = 1)
	{
		e.Reset();
		e.X = x;
		e.Y = y;
		e.Button = .Left;
		e.ClickCount = clicks;
	}

	/// One 16 ms frame: Main's Update (0..10) holds Physics (1..5) and Audio (6..8) at depth 1;
	/// Worker 0 runs a Job (2..12); the GPU runs shadows (3..7) and forward (8..15).
	private static void OneFrame(KnownSource source)
	{
		let worker = source.Thread("Worker 0");
		let update = source.Name("Update");
		let physics = source.Name("Physics");
		let audio = source.Name("Audio");
		let job = source.Name("Job");
		let shadows = source.Name("shadows");
		let forward = source.Name("forward");
		let frame = source.AddFrame(16);
		KnownSource.AddScope(frame, physics, 1, 1, 5);
		KnownSource.AddScope(frame, audio, 1, 6, 8);
		KnownSource.AddScope(frame, update, 0, 0, 10);
		KnownSource.AddScopeOn(frame, worker, job, 0, 2, 12);
		KnownSource.AddPass(frame, shadows, 3, 7);
		KnownSource.AddPass(frame, forward, 8, 15);
	}

	[Test]
	public static void TheFrameStripFitsEveryFrameAndSelectsByClickAndDrag()
	{
		let source = scope KnownSource();
		for (int f < 11)
			source.AddFrame(10);
		let strip = new FrameTimeGraph();
		defer strip.ReleaseRef();
		strip.FitToSource = true;
		strip.Interactive = true;
		strip.Source = source;
		Stage(strip, 300, FrameTimeGraph.GraphHeight);
		strip.Refresh();
		Test.Assert(strip.CpuPoints.Length == 11, "all of them, however many FrameCount says");
		Test.Assert(Near(strip.CpuPoints[0].X, 0.0));
		Test.Assert(Near(strip.CpuPoints[10].X, 300.0));
		Test.Assert(strip.FrameAt(300.0f).First == 10);
		Test.Assert(strip.FrameAt(0.0f).First == 0);
		Test.Assert(strip.FrameAt(-50.0f).First == 0, "clamped to the oldest");

		let heard = scope List<FrameRange>();
		strip.OnSelectionChanged.Add(new (range) => heard.Add(range));
		let e = scope MouseEventArgs();
		Mouse(e, 300.0f, 10.0f);
		strip.OnMouseDown(e);
		Test.Assert(e.Handled);
		Test.Assert(heard.Count == 1);
		Test.Assert((heard[0].First == 10) && (heard[0].Last == 10));
		Mouse(e, 241.0f, 10.0f); // two frames back
		strip.OnMouseMove(e);
		Mouse(e, 241.0f, 10.0f);
		strip.OnMouseUp(e);
		Test.Assert(heard.Count == 2);
		Test.Assert((strip.Selection.First == 8) && (strip.Selection.Last == 10));
		Test.Assert(Draw(strip) > 0);

		Mouse(e, 0.0f, 10.0f); // not dragging: a move selects nothing
		strip.OnMouseMove(e);
		Test.Assert(heard.Count == 2);
	}

	[Test]
	public static void TheTimelineLaysAFramesLanesAndNestingOutOnItsTimeAxis()
	{
		let source = scope KnownSource();
		OneFrame(source);
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		timeline.Source = source;
		Stage(timeline, Timeline.HeaderWidth + 600.0f, 240.0f);
		timeline.Frames = ProfileWindow.LastFrames(source, 1);

		// Main, then Worker 0, then the GPU; Main two depths deep, the others one.
		Test.Assert(timeline.Lanes.Length == 3);
		Test.Assert(timeline.Lanes[0].Name == "Main");
		Test.Assert(timeline.Lanes[0].Depths == 2);
		Test.Assert(timeline.Lanes[1].Name == "Worker 0");
		Test.Assert(timeline.Lanes[2].Gpu);
		Test.Assert(timeline.Lanes[1].Y > timeline.Lanes[0].Y + timeline.Lanes[0].Height);

		// The whole frame in view: 16 ms across 600 units.
		Test.Assert(Near(timeline.XAt(timeline.ViewBegin), Timeline.HeaderWidth));
		Test.Assert(Near(timeline.ViewEnd - timeline.ViewBegin, 16.0));
		Test.Assert(timeline.Bars.Length == 6);
		int update = -1;
		int physics = -1;
		for (int i < timeline.Bars.Length)
		{
			if (source.NameOf(timeline.Bars[i].Name) == "Update")
				update = i;
			if (source.NameOf(timeline.Bars[i].Name) == "Physics")
				physics = i;
		}
		Test.Assert((update >= 0) && (physics >= 0));
		let u = timeline.Bars[update];
		let p = timeline.Bars[physics];
		Test.Assert(Near(u.Rect.X, Timeline.HeaderWidth));
		Test.Assert(Near(u.Rect.Width, 600.0 * 10.0 / 16.0));
		Test.Assert(p.Depth == 1);
		Test.Assert(Near(p.Rect.Y, u.Rect.Y + Timeline.RowHeight), "nested under it");
		Test.Assert(Near(p.Rect.X, Timeline.HeaderWidth + 600.0 / 16.0));
		Test.Assert(timeline.BarAt(.(p.Rect.X + 2, p.Rect.Y + 2)) == physics);
		Test.Assert(timeline.FrameEdges.Length == 1);
		Test.Assert(Draw(timeline) > 0);

		// Hovering a bar names it, and the draw keeps it (a draw recomputes the bars).
		let e = scope MouseEventArgs();
		Mouse(e, p.Rect.X + 2, p.Rect.Y + 2);
		timeline.OnMouseMove(e);
		Test.Assert(timeline.Hovered != null);
		Test.Assert(source.NameOf(timeline.Hovered.Value.Name) == "Physics");
		Draw(timeline);
		Test.Assert(timeline.Hovered != null, "the draw keeps the hover");
		// Bars rebuilt under a still pointer (the view zoomed): the hover is the bar now under it,
		// found from the pointer, not whatever bar holds the old index.
		timeline.ZoomAt(Timeline.HeaderWidth + 590.0f, 4.0f);
		let under = timeline.BarAt(.(p.Rect.X + 2, p.Rect.Y + 2));
		Test.Assert((under < 0) == (timeline.Hovered == null));
		if (under >= 0)
			Test.Assert(timeline.Hovered.Value.Name == timeline.Bars[under].Name);
		// The pointer gone: no hover, through a draw too.
		timeline.FitView();
		timeline.Refresh();
		Test.Assert(timeline.Hovered != null);
		timeline.OnMouseLeave();
		Draw(timeline);
		Test.Assert(timeline.Hovered == null, "left: no hover");
	}

	[Test]
	public static void ZoomKeepsTheTimeUnderThePointerADragPans()
	{
		let source = scope KnownSource();
		OneFrame(source);
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		timeline.Source = source;
		Stage(timeline, Timeline.HeaderWidth + 600.0f, 240.0f);
		timeline.Frames = ProfileWindow.LastFrames(source, 1);

		let x = Timeline.HeaderWidth + 150.0f;
		let under = timeline.TickAt(x);
		timeline.ZoomAt(x, 2.0f);
		Test.Assert(Near(timeline.TickAt(x), under));
		Test.Assert(Near(timeline.ViewEnd - timeline.ViewBegin, 8.0));
		timeline.ZoomAt(x, 0.5f);
		Test.Assert(Near(timeline.ViewEnd - timeline.ViewBegin, 16.0));
		Test.Assert(Near(timeline.TickAt(x), under));

		// A wheel notch zooms in about the pointer too.
		let wheel = scope MouseWheelEventArgs();
		wheel.X = x;
		wheel.DeltaY = 1.0f;
		timeline.OnMouseWheel(wheel);
		Test.Assert(Near(timeline.TickAt(x), under));
		Test.Assert(timeline.ViewEnd - timeline.ViewBegin < 16.0);

		// A drag 60 units right shows earlier time; a double click fits the frame again.
		let begin = timeline.ViewBegin;
		let perUnit = (timeline.ViewEnd - timeline.ViewBegin) / 600.0;
		let e = scope MouseEventArgs();
		Mouse(e, 400.0f, 50.0f);
		timeline.OnMouseDown(e);
		Mouse(e, 460.0f, 50.0f);
		timeline.OnMouseMove(e);
		Mouse(e, 460.0f, 50.0f);
		timeline.OnMouseUp(e);
		Test.Assert(Near(timeline.ViewBegin, begin - 60.0 * perUnit));
		Mouse(e, 400.0f, 50.0f, 2);
		timeline.OnMouseDown(e);
		Test.Assert(Near(timeline.ViewEnd - timeline.ViewBegin, 16.0));
	}

	[Test]
	public static void TheScopeTableTotalsSortsAndARowSelectsItsBars()
	{
		let source = scope KnownSource();
		OneFrame(source);
		let table = new ScopeTable();
		defer table.ReleaseRef();
		let timeline = new Timeline();
		defer timeline.ReleaseRef();
		table.Source = source;
		timeline.Source = source;
		Stage(table, 420, 240);
		Stage(timeline, Timeline.HeaderWidth + 600.0f, 240.0f);
		let frame = ProfileWindow.LastFrames(source, 1);
		table.Frames = frame;
		timeline.Frames = frame;

		// By own time, largest first: Job 10, forward 7, Physics 4, shadows 4, Update 4 (10 less 6), Audio 2.
		Test.Assert(table.Rows.Length == 6);
		Test.Assert(table.SortColumn == .Self);
		Test.Assert((table.Rows[0].Label == "Job") && Near(table.Rows[0].SelfMs, 10.0));
		Test.Assert((table.Rows[1].Label == "forward") && table.Rows[1].Gpu);
		Test.Assert(table.Rows[5].Label == "Audio");
		for (let row in table.Rows)
		{
			if (row.Label == "Update")
				Test.Assert(Near(row.TotalMs, 10.0) && Near(row.SelfMs, 4.0) && (row.Count == 1));
		}

		// A heading click sorts by its column: Name A to Z, then Z to A.
		let numbers = 420.0f - 3 * ScopeTable.NumberWidth;
		let e = scope MouseEventArgs();
		Mouse(e, 10.0f, 5.0f);
		table.OnMouseDown(e);
		Test.Assert(table.SortColumn == .Name);
		Test.Assert(table.Rows[0].Label == "Audio", table.Rows[0].Label);
		Mouse(e, 10.0f, 5.0f);
		table.OnMouseDown(e);
		Test.Assert(table.Rows[0].Label == "shadows", table.Rows[0].Label);
		Mouse(e, numbers + 5.0f, 5.0f);
		table.OnMouseDown(e);
		Test.Assert(table.SortColumn == .Total);
		Test.Assert(table.Rows[0].TotalMs >= table.Rows[1].TotalMs);

		// A row click selects its name; the timeline highlights that name's bars and no other.
		table.OnSelect.Add(new (row) =>
			{
				if (row != null)
					timeline.SetHighlight(row.Name, row.Gpu);
				else
					timeline.ClearHighlight();
			});
		int physicsRow = -1;
		for (int i < table.Rows.Length)
		{
			if (table.Rows[i].Label == "Physics")
				physicsRow = i;
		}
		Test.Assert(physicsRow >= 0);
		Mouse(e, 30.0f, ScopeTable.RowHeight * ((float)physicsRow + 1.5f));
		table.OnMouseDown(e);
		Test.Assert(table.SelectedRow == physicsRow);
		int highlighted = 0;
		for (let bar in timeline.Bars)
		{
			if (timeline.IsHighlighted(bar))
			{
				highlighted++;
				Test.Assert(source.NameOf(bar.Name) == "Physics");
			}
		}
		Test.Assert(highlighted == 1);
		// The selection follows its name through a re-sort.
		table.SortBy(.Count, true);
		Test.Assert(table.SelectedRow >= 0);
		Test.Assert(table.Rows[table.SelectedRow].Label == "Physics");
		Test.Assert(Draw(table) > 0);
		Test.Assert(Draw(timeline) > 0);
	}

	/// A view pointed at fixed frames (the panel's selection) reads those, not the newest; an
	/// empty range goes back to the newest.
	[Test]
	public static void AViewPointedAtFixedFramesReadsThose()
	{
		let source = scope KnownSource();
		let draws = source.Counter("Draws", .Count);
		for (let v in double[3](10.0, 20.0, 60.0))
			source.AddFrame(16).Counters.Add(.(draws, v));
		let counters = new CounterStrip();
		defer counters.ReleaseRef();
		counters.Source = source;
		Test.Assert(counters.Rows[0].Value == "30", "the newest frames: the mean of all three");
		var first = FrameRange();
		first.First = 0;
		first.Last = 0;
		first.Empty = false;
		counters.SetRange(first);
		Test.Assert(counters.Rows[0].Value == "10", scope String(counters.Rows[0].Value));
		counters.SetRange(.());
		Test.Assert(counters.Rows[0].Value == "30");
	}
}
