using System;
using System.Collections;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A widget of the class `a` in a GUI, its own size 100 by 50, styled by a sheet and laid out. The
/// root, the widget and the manager go with it.
class KeyframesBed
{
	public SceneRoot Root = SceneFixtures.NewScene() ~ _.ReleaseRef();
	public UIWidget W = new .() ~ _.ReleaseRef();
	public StyleManager Styles = new .() ~ delete _;

	public this(StringView css)
	{
		W.AddClass("a");
		using (Node.StyleWriteScope(W)) // the widget's own size, which the sheet animates
		{
			W.Size = .(100.0f, 50.0f);
		}
		Root.AddChild(W);
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		Styles.StyleSheet = sheet;
		Styles.ApplyTree(Root);
		Root.UpdateLayout(); // sizes are the layout's, from the style
	}

	public void Advance(double seconds)
	{
		Root.Context.Update(SceneFixtures.Seconds(seconds));
	}
}

/// @keyframes: keyframe blocks parsed into named stops, and the animation runtime (an `animation`
/// property runs its stops through the widget's StyleAnimation on the GUI's clock): any property,
/// eased per segment, with delays, iteration counts, directions and fill modes.
class KeyframesTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void ParseNamesOffsetsPercentFromToAndStopDeclarations()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse(
			"@keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.25; } 100% { opacity: 1; } }" +
			"@keyframes fade  { from { opacity: 1; } to { opacity: 0; } }", sheet);

		Test.Assert(sheet.KeyframesCount == 2);

		let pulse = sheet.FindKeyframes("pulse");
		Test.Assert(pulse != null);
		Test.Assert(pulse.Stops.Count == 3);
		Test.Assert(Near(pulse.Stops[0].Offset, 0.0f));
		Test.Assert(Near(pulse.Stops[1].Offset, 0.5f));
		Test.Assert(Near(pulse.Stops[2].Offset, 1.0f));
		Test.Assert(pulse.Stops[1].Properties.Count == 1);

		let fade = sheet.FindKeyframes("fade");
		Test.Assert(fade != null);
		Test.Assert(fade.Stops.Count == 2);
		Test.Assert(Near(fade.Stops[0].Offset, 0.0f)); // from
		Test.Assert(Near(fade.Stops[1].Offset, 1.0f)); // to
	}

	[Test]
	public static void ACommaOffsetListSharesTheBlock()
	{
		let sheet = scope StyleSheet();
		CSSParser.Parse("@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0; } }", sheet);
		let blink = sheet.FindKeyframes("blink");
		Test.Assert(blink != null);
		Test.Assert(blink.Stops.Count == 3); // 0%, 100%, 50%
	}

	/// A new widget of the class `cls` in `root`, held by the caller, and a manager styling by `css`.
	private static UIWidget Animated(SceneRoot root, StringView cls, StringView css, StyleManager styles)
	{
		let w = new UIWidget();
		w.AddClass(cls);
		root.AddChild(w);
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		styles.StyleSheet = sheet;
		return w;
	}

	[Test]
	public static void TheAnimationPropertyDrivesOpacityAcrossTheStops()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let mgr = scope StyleManager();
		let w = Animated(root, "anim",
			"@keyframes fade { 0% { opacity: 1; } 50% { opacity: 0; } 100% { opacity: 1; } }" +
			".anim { animation: fade 2s linear; }", mgr);
		defer w.ReleaseRef();
		mgr.ApplyTree(root); // starts the animation; it applies t=0 at once

		Test.Assert(Near(w.Alpha, 1.0f)); // stop 0% -> 1

		root.Context.Update(SceneFixtures.Seconds(0.5)); // t=0.25 -> between 1 and 0, halfway -> 0.5
		Test.Assert(Near(w.Alpha, 0.5f));

		root.Context.Update(SceneFixtures.Seconds(0.5)); // t=0.5 -> 0
		Test.Assert(Near(w.Alpha, 0.0f));

		root.Context.Update(SceneFixtures.Seconds(0.5)); // t=0.75 -> halfway back -> 0.5
		Test.Assert(Near(w.Alpha, 0.5f));

		root.Context.Update(SceneFixtures.Seconds(0.5)); // t=1.0 -> 1 (non-looping: ends here)
		Test.Assert(Near(w.Alpha, 1.0f));
	}

	[Test]
	public static void InfiniteAnimationsLoop()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let mgr = scope StyleManager();
		let w = Animated(root, "loop",
			"@keyframes fade { 0% { opacity: 1; } 50% { opacity: 0; } 100% { opacity: 1; } }" +
			".loop { animation: fade 2s linear infinite; }", mgr);
		defer w.ReleaseRef();
		mgr.ApplyTree(root);

		root.Context.Update(SceneFixtures.Seconds(1.0)); // t=0.5 -> 0
		Test.Assert(Near(w.Alpha, 0.0f));
		root.Context.Update(SceneFixtures.Seconds(1.0)); // elapsed 2.0 -> wraps to t=0 -> 1 (still running)
		Test.Assert(Near(w.Alpha, 1.0f));
		root.Context.Update(SceneFixtures.Seconds(1.0)); // elapsed 3.0 -> t=0.5 -> 0 again (looped)
		Test.Assert(Near(w.Alpha, 0.0f));
	}

	[Test]
	public static void TheAnimationIsSpawnedOnceNotRespawnedEachApplyTree()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let mgr = scope StyleManager();
		let w = Animated(root, "anim",
			"@keyframes fade { 0% { opacity: 1; } 50% { opacity: 0; } 100% { opacity: 1; } }" +
			".anim { animation: fade 2s linear; }", mgr);
		defer w.ReleaseRef();

		mgr.ApplyTree(root);
		root.Context.Update(SceneFixtures.Seconds(1.0)); // t=0.5 -> 0
		mgr.ApplyTree(root); // re-apply must NOT restart the animation
		Test.Assert(Near(w.Alpha, 0.0f)); // still mid-animation, not reset to t=0
	}

	[Test]
	public static void AnimatesBackgroundColorAcrossTheStops()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let mgr = scope StyleManager();
		let w = Animated(root, "cycle",
			"@keyframes cyc { 0% { background-color: #000000; } 100% { background-color: #ffffff; } }" +
			".cycle { animation: cyc 2s linear forwards; }", mgr);
		defer w.ReleaseRef();
		mgr.ApplyTree(root);

		// At t=0 the background is black; halfway it's mid-grey; at the end white (held: forwards).
		void Grey(float expect)
		{
			Test.Assert(Near(w.Box.BackgroundColor.R, expect));
		}
		Grey(0.0f);
		root.Context.Update(SceneFixtures.Seconds(1.0)); // t=0.5 -> mid grey
		Grey(0.5f);
		root.Context.Update(SceneFixtures.Seconds(1.0)); // t=1.0 -> white
		Grey(1.0f);
	}

	[Test]
	public static void AnyPropertyAnimatesATransformABoxShadowALength()
	{
		let bed = scope KeyframesBed("@keyframes spin { from { transform: rotate(0deg); box-shadow: 0 0 0 #000000; width: 100; } " +
			"to { transform: rotate(180deg); box-shadow: 0 0 10px #000000; width: 200; } } " +
			".a { animation: spin 2s linear; }");
		bed.Advance(1.0);
		Test.Assert(bed.W.StyleTransforms.Count == 1);
		Test.Assert(Near(bed.W.StyleTransforms[0].Angle, 1.5707963f)); // 90deg
		Test.Assert(bed.W.Box.Shadows.Count == 1);
		Test.Assert(Near(bed.W.Box.Shadows[0].Blur, 5.0f));
		Test.Assert(Near(bed.W.Size.X, 150.0f));
	}

	[Test]
	public static void DelayIterationCountAlternateDirectionAndFillForwards()
	{
		let bed = scope KeyframesBed("@keyframes grow { from { width: 100; } to { width: 200; } } " +
			".a { width: 50; animation: grow 1s linear 0.5s 2 alternate forwards; }");
		Test.Assert(Near(bed.W.Size.X, 50.0f)); // the delay, no backwards fill: the target
		bed.Advance(0.75); // 0.25 into the first, forwards
		Test.Assert(Near(bed.W.Size.X, 125.0f));
		bed.Advance(1.0); // 0.25 into the second, backwards
		Test.Assert(Near(bed.W.Size.X, 175.0f));
		bed.Advance(2.0); // ended: the last iteration's end (100)
		Test.Assert(Near(bed.W.Size.X, 100.0f));
		Test.Assert(!bed.Root.ActionManager.IsEmpty); // forwards keeps showing it
	}

	[Test]
	public static void AStopsTimingFunctionEasesItsSegmentAMissingEndTakesTheTarget()
	{
		let bed = scope KeyframesBed("@keyframes half { 0% { opacity: 0; animation-timing-function: steps(2); } 50% { opacity: 1; } } " +
			".a { opacity: 0.2; animation: half 2s linear; }");
		bed.Advance(0.4); // 0.2 of the animation, 0.4 of the first segment: steps(2) holds 0
		Test.Assert(Near(bed.W.Alpha, 0.0f));
		bed.Advance(0.2); // 0.3, 0.6 of the segment: the second step, 0.5
		Test.Assert(Near(bed.W.Alpha, 0.5f));
		bed.Advance(1.0); // 0.8: between 50% (1) and the implicit 100% (the target 0.2), linear
		Test.Assert(Near(bed.W.Alpha, 1.0f + (0.2f - 1.0f) * 0.6f));
	}

	[Test]
	public static void RemovingTheAnimationStopsItAndTheTargetShows()
	{
		let bed = scope KeyframesBed("@keyframes pulse { from { opacity: 0; } to { opacity: 1; } } " +
			".a { animation: pulse 2s linear infinite; }");
		bed.Advance(0.5);
		Test.Assert(Near(bed.W.Alpha, 0.25f));
		bed.W.RemoveClass("a");
		bed.Styles.ApplyTree(bed.Root);
		Test.Assert(Near(bed.W.Alpha, 1.0f)); // no animation: the node's own 1
		bed.Advance(0.5);
		Test.Assert(Near(bed.W.Alpha, 1.0f));
	}
}
