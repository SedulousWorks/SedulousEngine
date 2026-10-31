using System;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;
using Sedulous.Profiler;

namespace Sedulous.GUI.Tests;

// Frame stats: what a frame cost and why it was needed, written by the style, layout and draw
// passes and by NeedsFrame.

/// What a frame says it restyled, laid out and drew, and what asked for it.
class FrameStatsTests
{
	/// A new box `id`, 40 by 20, the last child of `parent`, held by the caller (it releases it).
	private static UIWidget Box(Node parent, StringView id)
	{
		let w = new UIWidget();
		w.Tag = "box";
		w.Id = id;
		w.Size = .(40.0f, 20.0f);
		parent.AddChild(w);
		return w;
	}

	// A host's frame: style, tick, lay out, ask, draw.
	private static bool Frame(SceneRoot root, StyleManager styles, VGContext canvas)
	{
		styles.ApplyTree(root);
		root.Context.Update(SceneFixtures.Frame);
		root.UpdateLayout();
		let needed = root.NeedsFrame();
		canvas.Clear();
		let dc = scope DrawContext(canvas);
		root.DrawFrame(dc);
		return needed;
	}

	[Test]
	public static void AFrameSaysWhatItRestyledLaidOutAndDrewAndAnIdleOneWhatAskedNothing()
	{
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let panel = Box(root, "panel");
		defer panel.ReleaseRef();
		panel.EditLayoutStyle(scope (s) => { s.Direction = .Column; });
		let a = Box(panel, "a");
		defer a.ReleaseRef();
		let b = Box(panel, "b");
		defer b.ReleaseRef();
		let sheet = scope StyleSheet();
		CSSParser.Parse("box { background-color: #336699; }", sheet);
		let styles = scope StyleManager(sheet);
		let canvas = scope VGContext();

		Test.Assert(Frame(root, styles, canvas));
		Test.Assert(root.LastFrameStats.Restyled == 3); // the three boxes (the root is no widget)
		Test.Assert(root.LastFrameStats.LaidOut >= 1);
		Test.Assert(root.LastFrameStats.NodesDrawn == 4); // the root and the boxes
		Test.Assert(root.LastFrameStats.Vertices > 0); // their backgrounds
		Test.Assert(root.LastFrameStats.Commands > 0);
		Test.Assert(root.LastFrameStats.FramesDrawn == 1);

		Frame(root, styles, canvas); // what the first frame left settles
		Test.Assert(!Frame(root, styles, canvas));
		Test.Assert(root.LastFrameStats.Restyled == 0);
		Test.Assert(root.LastFrameStats.LaidOut == 0);
		Test.Assert(!root.LastFrameStats.Reasons.Any);
		let text = scope String();
		root.LastFrameStats.Describe(text);
		Test.Assert(text.Contains("asked by: nothing", true));

		b.Displayed = false; // not drawn, not counted
		Frame(root, styles, canvas);
		Test.Assert(root.LastFrameStats.NodesDrawn == 3);
	}

	[Test]
	public static void AnAnimationThatKeepsAGUIDrawingIsNamedAChangeSaysRedraw()
	{
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let bar = new ProgressBar();
		defer bar.ReleaseRef();
		bar.Id = "busy";
		bar.Size = .(100.0f, 10.0f);
		root.AddChild(bar);
		let sheet = scope StyleSheet();
		CSSParser.Parse("progressbar { opacity: 1; }", sheet);
		let styles = scope StyleManager(sheet);
		let canvas = scope VGContext();
		bar.Indeterminate = true;
		Frame(root, styles, canvas);
		Frame(root, styles, canvas);
		Test.Assert(Frame(root, styles, canvas));
		let stats = root.LastFrameStats;
		Test.Assert(stats.Reasons.Animation);
		Test.Assert(stats.AnimatedNode == "ProgressBar #busy");
		let text = scope String();
		stats.Describe(text);
		Test.Assert(text.Contains("animation (ProgressBar #busy)", true));

		bar.Indeterminate = false;
		Frame(root, styles, canvas);
		Frame(root, styles, canvas);
		Test.Assert(!Frame(root, styles, canvas));
		bar.Value = 0.5;
		root.UpdateLayout();
		Test.Assert(root.NeedsFrame());
		Test.Assert(stats.Reasons.Redraw);
		Test.Assert(!stats.Reasons.Animation);
	}

	[Test]
	public static void AProfiledFrameTimesTheDrawsPhasesApartTheBoxTheWidgetsOwnDrawing()
	{
		let profiler = scope Sedulous.Profiler.Profiler();
		profiler.Arm();
		InitGlobalProfiler(profiler);
		defer ShutdownGlobalProfiler();
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let filled = Box(root, "filled");
		defer filled.ReleaseRef();
		let styles = scope StyleManager();
		let canvas = scope VGContext();
		profiler.BeginFrame();
		Frame(root, styles, canvas);
		profiler.EndFrame();
		let frame = profiler.LatestFrame;
		Test.Assert(frame != null);
		uint32 draws = 0;
		uint32 boxes = 0;
		uint32 widgets = 0;
		for (let thread in frame.Threads)
		{
			for (let scopeEvent in thread.Scopes)
			{
				let name = profiler.NameOf(scopeEvent.Name);
				draws += (name == "GUI.Draw") ? 1 : 0;
				boxes += (name == "GUI.Draw.Box") ? 1 : 0;
				widgets += (name == "GUI.Draw.Widget") ? 1 : 0;
			}
		}
		profiler.Disarm();
		Test.Assert(draws == 1);
		Test.Assert(boxes == 2, "the root's and the box's");
		Test.Assert(widgets == 2);
	}

	[Test]
	public static void AtADisplayScaleTheWindowsClipIsTheRootsDevicePixelsSoTheWholeWindowIsDrawn()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		root.DisplayScale = 1.75f;
		root.ViewportSize = .(1400.0f, 1050.0f); // device pixels: 800 x 600 laid out
		root.UpdateLayout();
		Test.Assert(Math.Abs(root.Size.X - 800.0f) < 0.01f);
		let filled = Box(root, "filled");
		defer filled.ReleaseRef();
		filled.SetInlineStyle("background-color", "red"); // something drawn
		let styles = scope StyleManager();
		let canvas = scope VGContext();
		Frame(root, styles, canvas);
		let batch = canvas.GetBatch();
		Test.Assert(!batch.Commands.IsEmpty);
		for (let command in batch.Commands)
		{
			Test.Assert(command.ClipRect.Width >= 1400.0f - 0.5f, "never the 800 of its layout");
			Test.Assert(command.ClipRect.Height >= 1050.0f - 0.5f);
		}
	}
}
