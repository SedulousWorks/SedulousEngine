using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;
using Sedulous.Profiler;
using Sedulous.Profiler.GUI;
using Sedulous.Profiler.Tests; // KnownSource

namespace Sedulous.Profiler.GUI.Tests;

/// The in-game overlay: the frame time graph plots the
/// newest frames on its scale, the statistics, top lists and counters show the source's numbers, the
/// panel sits in its corner, and it never takes the pointer from the game under it.
class ProfilerOverlayTests
{
	private static bool Near(double a, double b, double epsilon = 1e-4) => Math.Abs(a - b) <= epsilon;

	/// The overlay filling a 1280 by 720 root, over ten frames of 10 ms then one of 30 (a hitch),
	/// each with an Update scope, a forward pass and two counters.
	private class Bed
	{
		public KnownSource Source = new .() ~ delete _;
		public SceneRoot Root;
		public ProfileFocus Focus = new .() ~ _.ReleaseRef();
		public ProfilerOverlay Overlay = new .() ~ _.ReleaseRef();

		public this()
		{
			let update = Source.Name("Update");
			let forward = Source.Name("forward");
			let draws = Source.Counter("Draws", .Count);
			let memory = Source.Counter("Buffer memory", .Bytes);
			for (int f < 11)
			{
				let frame = Source.AddFrame((f == 10) ? 30 : 10);
				KnownSource.AddScope(frame, update, 0, 0, 6);
				KnownSource.AddPass(frame, forward, 1, 5);
				frame.Counters.Add(.(draws, 120.0));
				frame.Counters.Add(.(memory, 2.0 * 1024 * 1024));
			}
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(1280.0f, 720.0f);
			Overlay.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Percent(100.0f);
					s.Height = LayoutLength.Percent(100.0f);
				});
			Root.AddChild(Overlay);
			Overlay.Focus = Focus;
			Focus.SetSource(Source);
			Root.UpdateLayout();
			Overlay.Refresh();
		}

		public ~this()
		{
			// The views let go of the source before it goes.
			Focus.SetSource(null);
			Root.ReleaseRef();
		}

		public int Draw()
		{
			let canvas = scope VGContext();
			let dc = scope DrawContext(canvas);
			Root.Draw(dc);
			return canvas.GetBatch().VertexCount;
		}
	}

	[Test]
	public static void TheGraphPlotsTheNewestFramesOnItsScaleNewestAtTheRightEdge()
	{
		let bed = scope Bed();
		Test.Assert(Near(bed.Overlay.ScaleMs, 40.0), "30 ms needs 20 doubled");
		Test.Assert(Near(ProfilerOverlay.ScaleFor(10.0f), 20.0));
		Test.Assert(Near(ProfilerOverlay.ScaleFor(100.0f), 160.0));
		Test.Assert(bed.Overlay.CpuPoints.Length == 11);
		Test.Assert(bed.Overlay.GpuPoints.Length == 11);
		let width = ProfilerOverlay.cPanelWidth - 2 * ProfilerOverlay.cPadding;
		let step = width / (float)(ProfilerOverlay.cGraphFrames - 1);
		Test.Assert(Near(bed.Overlay.CpuPoints[10].X, width, 1e-3));
		Test.Assert(Near(bed.Overlay.CpuPoints[0].X, width - 10.0f * step, 1e-3), "a short history grows in from the right");
		Test.Assert(Near(bed.Overlay.CpuPoints[0].Y, 48.0, 1e-3), "10 ms a quarter up the 64");
		Test.Assert(Near(bed.Overlay.CpuPoints[10].Y, 16.0, 1e-3), "30 ms three quarters up");
		Test.Assert(Near(bed.Overlay.GpuPoints[0].Y, 64.0f * (1.0f - 4.0f / 40.0f), 1e-3));
	}

	[Test]
	public static void TheStatisticsTheTopListsAndTheCountersShowTheSourcesNumbers()
	{
		let bed = scope Bed();
		let o = bed.Overlay;
		Test.Assert(o.StatLines.Length == 3);
		Test.Assert(o.StatLines[0].StartsWith("CPU  30.00 ms"), o.StatLines[0]);
		Test.Assert(o.StatLines[1].StartsWith("GPU  4.00 ms"), o.StatLines[1]);
		Test.Assert(o.StatLines[2].StartsWith("85 fps over 11 frames"), o.StatLines[2]); // 1000 / (130 / 11)
		Test.Assert(o.Scopes.Length == 1);
		Test.Assert(o.Scopes[0].Name == "Update");
		Test.Assert(Near(o.Scopes[0].MsPerFrame, 6.0));
		Test.Assert(Near(o.Scopes[0].Bar, 1.0));
		Test.Assert(o.Passes.Length == 1);
		Test.Assert(o.Passes[0].Name == "forward");
		Test.Assert(Near(o.Passes[0].MsPerFrame, 4.0));
		Test.Assert(o.Counters.Length == 2);
		Test.Assert(o.Counters[0].Name == "Draws");
		Test.Assert(o.Counters[0].Value == "120");
		Test.Assert(o.Counters[1].Value == "2.0 MiB", "what it holds: the newest");
		Test.Assert(bed.Draw() > 0);

		// A new frame: Refresh reads the source again.
		bed.Source.AddFrame(50);
		o.Refresh();
		Test.Assert(o.StatLines[0].StartsWith("CPU  50.00 ms"));
		Test.Assert(Near(o.ScaleMs, 80.0));
	}

	[Test]
	public static void ThePanelSitsInItsCornerAndThePointerPassesThroughToTheGame()
	{
		let bed = scope Bed();
		Test.Assert(!bed.Overlay.HitTestVisible);
		var panel = bed.Overlay.Panel;
		Test.Assert(Near(panel.Width, ProfilerOverlay.cPanelWidth));
		Test.Assert(Near(panel.X, 1280.0f - ProfilerOverlay.cMargin - ProfilerOverlay.cPanelWidth));
		Test.Assert(Near(panel.Y, ProfilerOverlay.cMargin));
		Test.Assert(Near(panel.Height, bed.Overlay.PanelHeight));

		bed.Overlay.Corner = .BottomLeft;
		panel = bed.Overlay.Panel;
		Test.Assert(Near(panel.X, ProfilerOverlay.cMargin));
		Test.Assert(Near(panel.Y + panel.Height, 720.0f - ProfilerOverlay.cMargin, 1e-3));

		// A widget under it still takes a click inside the panel.
		let under = new UIWidget();
		under.EditLayoutStyle(scope (s) =>
			{
				s.Placement = .Absolute;
				s.Left = LayoutLength.Px(0.0f);
				s.Top = LayoutLength.Px(0.0f);
				s.Width = LayoutLength.Px(1280.0f);
				s.Height = LayoutLength.Px(720.0f);
			});
		bed.Root.AddChildAt(under, 0);
		under.ReleaseRef(); // the root's keeps it
		bed.Root.UpdateLayout();
		let inside = Float2(panel.X + 20.0f, panel.Y + 20.0f);
		Test.Assert(bed.Root.EventDispatcher.NodeAt(inside) === under);
	}
}
