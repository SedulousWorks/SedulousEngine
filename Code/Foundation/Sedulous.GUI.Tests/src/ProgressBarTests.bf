using System;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// ProgressBar tests: clamping and draw, and the indeterminate sweep.
class ProgressBarTests
{
	private static bool Near(double a, double b) => Math.Abs(a - b) < 1.2e-5 * (1.0 + Math.Max(Math.Abs(a), Math.Abs(b)));

	[Test]
	public static void ARangesValueClampedItsFillTheValuesShareDrawsTrackAndFill()
	{
		let p = new ProgressBar();
		defer p.ReleaseRef();
		p.Value = 0.5;
		Test.Assert(Near(p.Value, 0.5));
		p.Value = 2.0;
		Test.Assert(Near(p.Value, 1.0));
		p.Value = -1.0;
		Test.Assert(Near(p.Value, 0.0));
		p.Max = 200.0; // files: 50 of 200
		p.Value = 50.0;
		Test.Assert(Near(p.Ratio, 0.25));

		p.Size = .(120.0f, 10.0f);
		Test.Assert(WidgetFixtures.DrawnVertices(p) > 0);
	}

	[Test]
	public static void AnIndeterminateOneSweepsOnTheGUIsClock()
	{
		let root = SceneFixtures.NewScene(200.0f, 100.0f);
		defer root.ReleaseRef();
		let p = new ProgressBar();
		defer p.ReleaseRef();
		p.Size = .(120.0f, 10.0f);
		root.AddChild(p);
		p.Indeterminate = true;
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		root.Draw(dc); // shown: the sweep starts
		let start = p.SweepPhase;
		root.Context.Update(SceneFixtures.Seconds(0.35));
		Test.Assert(p.SweepPhase > start);
		Test.Assert(root.NeedsFrame());
		p.Indeterminate = false;
		root.Context.Update(SceneFixtures.Seconds(0.1));
		root.Context.Update(SceneFixtures.Seconds(0.1));
		Test.Assert(!root.Context.ActionManager.AnyAction(scope (action, target) => target == p));
	}
}
