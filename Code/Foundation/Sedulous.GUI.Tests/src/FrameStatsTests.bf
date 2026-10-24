using System;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

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
}
