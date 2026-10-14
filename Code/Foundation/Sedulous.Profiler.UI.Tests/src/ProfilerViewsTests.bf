using System;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.UI;
using Sedulous.Profiler;
using Sedulous.Profiler.UI;

namespace Sedulous.Profiler.UI.Tests;

/// The profiler's views, laid out and drawn into a VG context headless (no fonts, so the shapes
/// alone): each shows the numbers of a source of known frames, and the overlay stacks them on a
/// panel in its corner.
class ProfilerViewsTests
{
	private static bool Near(double a, double b) => ProfileWindowTests.Near(a, b);

	/// `view` measured and laid out at `width` x `height`.
	private static void Stage(View view, float width, float height)
	{
		view.Measure(.Tight(width, height));
		view.Layout(0, 0, width, height);
	}

	/// The vertices a draw of `view` makes.
	private static int Draw(View view)
	{
		let vg = scope VGContext();
		let ctx = scope UIDrawContext(vg, 1.0f);
		view.OnDraw(ctx);
		return vg.GetBatch().Vertices.Count;
	}

	/// Ten frames of 10 ms, then one of 30 (a hitch); each with an Update scope and a forward
	/// pass.
	private static void Fill(KnownSource source)
	{
		let update = source.Name("Update");
		let forward = source.Name("forward");
		let draws = source.Counter("Draws", .Count);
		let memory = source.Counter("Buffer memory", .Bytes);
		for (int f < 11)
		{
			let frame = source.AddFrame((f == 10) ? 30 : 10);
			KnownSource.AddScope(frame, update, 0, 0, 6);
			KnownSource.AddPass(frame, forward, 1, 5);
			frame.Counters.Add(.(draws, 120.0));
			frame.Counters.Add(.(memory, 2.0 * 1024 * 1024));
		}
	}

	[Test]
	public static void TheFrameTimeGraphPlotsTheNewestFramesOnItsScale()
	{
		let source = scope KnownSource();
		Fill(source);
		let graph = new FrameTimeGraph();
		defer graph.ReleaseRef();
		Stage(graph, 300, FrameTimeGraph.GraphHeight);
		Test.Assert(Draw(graph) > 0, "its plot background, even with no source");
		Test.Assert(graph.CpuPoints.IsEmpty);

		graph.FrameCount = 11;
		graph.Source = source;
		Test.Assert(graph.CpuPoints.Length == 11);
		Test.Assert(graph.GpuPoints.Length == 11);
		Test.Assert(Near(graph.ScaleMs, 40.0), "30 ms needs 20 doubled");
		Test.Assert(Near(FrameTimeGraph.ScaleFor(10.0f), 20.0));
		Test.Assert(Near(FrameTimeGraph.ScaleFor(100.0f), 160.0));
		// Newest at the right edge, oldest at the left; 10 ms a quarter up, 30 three quarters up.
		Test.Assert(Near(graph.CpuPoints[10].X, 300.0));
		Test.Assert(Near(graph.CpuPoints[0].X, 0.0));
		Test.Assert(Near(graph.CpuPoints[0].Y, 48.0));
		Test.Assert(Near(graph.CpuPoints[10].Y, 16.0));
		Test.Assert(Near(graph.GpuPoints[0].Y, 64.0 * (1.0 - 4.0 / 40.0)));

		// A shorter history grows in from the right rather than stretching.
		graph.FrameCount = 21;
		Test.Assert(Near(graph.CpuPoints[0].X, 150.0));
		Test.Assert(Draw(graph) > 0);
	}

	[Test]
	public static void StatisticsTopListsAndCountersShowTheSourcesNumbers()
	{
		let source = scope KnownSource();
		Fill(source);

		let stats = new FrameStats();
		defer stats.ReleaseRef();
		stats.FrameCount = 11;
		stats.Source = source;
		Test.Assert(Near(stats.NewestCpuMs, 30.0));
		Test.Assert(Near(stats.NewestGpuMs, 4.0));
		Test.Assert(Near(stats.Stats.Cpu.Median, 10.0));
		Test.Assert(Near(stats.Stats.Cpu.Max, 30.0));
		Test.Assert(stats.Lines.Length == 3);
		Test.Assert(stats.Lines[0].StartsWith("CPU  30.00 ms"), stats.Lines[0]);
		Test.Assert(stats.Lines[2].StartsWith("85 fps"), stats.Lines[2]); // 1000 / (130 / 11)

		let scopes = new TopList(.Scopes, 4);
		defer scopes.ReleaseRef();
		scopes.Source = source;
		Test.Assert(scopes.Rows.Length == 1);
		Test.Assert(scopes.Rows[0].Name == "Update");
		Test.Assert(Near(scopes.Rows[0].MsPerFrame, 6.0));
		Test.Assert(Near(scopes.Rows[0].Bar, 1.0));
		let passes = new TopList(.GpuPasses, 4);
		defer passes.ReleaseRef();
		passes.Source = source;
		Test.Assert(passes.Rows.Length == 1);
		Test.Assert(passes.Rows[0].Name == "forward");
		Test.Assert(Near(passes.Rows[0].MsPerFrame, 4.0));
		Stage(passes, 300, 200);
		Test.Assert(Draw(passes) > 0, "the bar");

		let counters = new CounterStrip();
		defer counters.ReleaseRef();
		counters.Source = source;
		Test.Assert(counters.Rows.Length == 2);
		Test.Assert(counters.Rows[0].Name == "Draws");
		Test.Assert(counters.Rows[0].Value == "120");
		Test.Assert(counters.Rows[1].Value == "2.0 MiB");
		// Two to a line: the second beside the first, the third under it.
		Stage(counters, 300, 100);
		Test.Assert(Near(counters.CellOf(1).X, 150.0) && Near(counters.CellOf(1).Y, 0.0));
		Test.Assert(Near(counters.CellOf(2).X, 0.0) && Near(counters.CellOf(2).Y, FrameTimeGraph.LineHeight));
		Test.Assert(Near(counters.CellOf(3).Y, FrameTimeGraph.LineHeight));
	}

	[Test]
	public static void TheOverlayStacksTheViewsOnAPanelInItsCorner()
	{
		let source = scope KnownSource();
		Fill(source);
		let overlay = new ProfilerOverlay();
		defer overlay.ReleaseRef();
		overlay.Source = source;
		Test.Assert(!overlay.IsHitTestVisible);
		// Nor any view in it: a game under the panel keeps the pointer.
		Test.Assert(!overlay.Graph.IsHitTestVisible && !overlay.Stats.IsHitTestVisible && !overlay.Scopes.IsHitTestVisible
			&& !overlay.Passes.IsHitTestVisible && !overlay.Counters.IsHitTestVisible);
		Stage(overlay, 1280, 720);

		let panel = overlay.Panel;
		Test.Assert(Near(panel.Width, ProfilerOverlay.PanelWidth));
		Test.Assert(Near(panel.X, 1280.0 - ProfilerOverlay.Margin - ProfilerOverlay.PanelWidth));
		Test.Assert(Near(panel.Y, ProfilerOverlay.Margin));
		// The views inside the panel, one under the next.
		Test.Assert(Near(overlay.Graph.Width, ProfilerOverlay.PanelWidth - 2 * ProfilerOverlay.Padding));
		Test.Assert(overlay.Stats.Bounds.Y > overlay.Graph.Bounds.Y);
		Test.Assert(overlay.Counters.Bounds.Y + overlay.Counters.Height <= panel.Y + panel.Height);
		Test.Assert(overlay.Scopes.Rows.Length == 1);
		Test.Assert(Draw(overlay) > 0);

		overlay.Corner = .BottomLeft;
		Stage(overlay, 1280, 720);
		Test.Assert(Near(overlay.Panel.X, ProfilerOverlay.Margin));
		Test.Assert(Near(overlay.Panel.Y + overlay.Panel.Height, 720.0 - ProfilerOverlay.Margin));
	}
}
