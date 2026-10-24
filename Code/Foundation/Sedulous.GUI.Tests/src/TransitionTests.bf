using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// Motion: the `transition` and `animation` lists parse; a changed property with a transition moves
// from what showed toward its new value on the GUI's clock, eased, for any property the sheet sets
// (opacity, lengths, colours, box shadows, transforms, gradients); without one, or unchanged,
// nothing moves; a transition retargets from where it is.

/// A widget in a GUI, styled by a sheet; Toggle toggles a class to change its style. The root, the
/// widget and the manager go with it.
class TransitionBed
{
	public SceneRoot Root = SceneFixtures.NewScene() ~ _.ReleaseRef();
	public UIWidget Widget = new .() ~ _?.ReleaseRef();
	public StyleManager Styles = new .() ~ delete _;

	public this(StringView css)
	{
		Widget.Tag = "box";
		using (Node.StyleWriteScope(Widget)) // the widget's own size, which the sheet animates
		{
			Widget.Size = .(100.0f, 50.0f);
		}
		Root.AddChild(Widget);
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		Styles.StyleSheet = sheet;
		Styles.ApplyTree(Root);
	}

	public void Toggle(StringView cls)
	{
		Widget.ToggleClass(cls);
		Styles.ApplyTree(Root);
	}

	public void Advance(double seconds)
	{
		Root.Context.Update(SceneFixtures.Seconds(seconds));
	}
}

/// Transitions: parsing, moving on the GUI's clock, easing, retargeting, interpolation.
class TransitionTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void TheListParsesPropertiesDurationsEasingsAndDelays()
	{
		let one = scope List<TransitionSpec>();
		defer { ClearAndDeleteItems!(one); }
		ParseTransitionList("opacity 0.3s", one);
		Test.Assert(one.Count == 1);
		Test.Assert(one[0].Property == "opacity");
		Test.Assert(Near(one[0].Duration, 0.3f));
		Test.Assert(one[0].Timing.Kind == .CubicBezier); // ease, CSS's default

		let many = scope List<TransitionSpec>();
		defer { ClearAndDeleteItems!(many); }
		ParseTransitionList("opacity 300ms linear 0.1s, transform 1s steps(4, jump-start), all 2s", many);
		Test.Assert(many.Count == 3);
		Test.Assert(Near(many[0].Duration, 0.3f));
		Test.Assert(Near(many[0].Delay, 0.1f));
		Test.Assert(many[0].Timing.Kind == .Linear);
		Test.Assert(many[1].Timing.Kind == .Steps);
		Test.Assert(many[1].Timing.Steps == 4);
		Test.Assert(many[2].Property == "all");
		let none = scope List<TransitionSpec>();
		defer { ClearAndDeleteItems!(none); }
		ParseTransitionList("none", none);
		Test.Assert(none.IsEmpty);
	}

	[Test]
	public static void OpacityMovesOnTheGUIsClockLinearlyWhenAsked()
	{
		let bed = scope TransitionBed("box { opacity: 1; transition: opacity 0.5s linear; } box.gone { opacity: 0; }");
		Test.Assert(Near(bed.Widget.Alpha, 1.0f));
		bed.Toggle("gone");
		Test.Assert(bed.Root.ActionManager.Count == 1); // the widget's StyleAnimation
		Test.Assert(Near(bed.Widget.Alpha, 1.0f)); // starts where it was
		bed.Advance(0.25);
		Test.Assert(Near(bed.Widget.Alpha, 0.5f)); // halfway
		bed.Advance(0.25);
		Test.Assert(Near(bed.Widget.Alpha, 0.0f)); // arrived
		Test.Assert(bed.Root.ActionManager.IsEmpty); // finished
	}

	[Test]
	public static void APropertySetByNoRuleBeforeMovesFromItsInitialValueAndBackToItWhenNoRuleSetsItAnyMore()
	{
		// Only the class sets them: put on, opacity moves from 1 (its initial value) to 0, as CSS's
		// does; taken off, it goes back to 1 and the transform to none.
		let bed = scope TransitionBed("box { transition: opacity 0.5s linear, transform 0.5s linear; } box.entering { opacity: 0; transform: translate(0, 8px); }");
		bed.Toggle("entering");
		Test.Assert(Near(bed.Widget.Alpha, 1.0f)); // from its initial value, not snapping
		bed.Advance(0.25);
		Test.Assert(Near(bed.Widget.Alpha, 0.5f));
		bed.Advance(0.75);
		Test.Assert(Near(bed.Widget.Alpha, 0.0f));
		bed.Toggle("entering");
		Test.Assert(Near(bed.Widget.Alpha, 0.0f)); // from where it was
		bed.Advance(0.25);
		Test.Assert(Near(bed.Widget.Alpha, 0.5f));
		bed.Advance(0.25);
		Test.Assert(Near(bed.Widget.Alpha, 1.0f));
		Test.Assert(bed.Root.ActionManager.IsEmpty);
	}

	[Test]
	public static void TheEasingShapesTheMoveEaseInStartsSlow()
	{
		let bed = scope TransitionBed("box { opacity: 0; transition: opacity 1s ease-in; } box.on { opacity: 1; }");
		bed.Toggle("on");
		bed.Advance(0.5);
		let expected = Easing.Bezier(0.42f, 0.0f, 1.0f, 1.0f).Evaluate(0.5f);
		Test.Assert(Near(bed.Widget.Alpha, expected));
		Test.Assert(bed.Widget.Alpha < 0.5f);
	}

	[Test]
	public static void WithoutATransitionOrWithNoChangeNothingMoves()
	{
		let snap = scope TransitionBed("box { opacity: 1; } box.gone { opacity: 0; }");
		snap.Toggle("gone");
		Test.Assert(Near(snap.Widget.Alpha, 0.0f));
		Test.Assert(snap.Root.ActionManager.IsEmpty);

		let same = scope TransitionBed("box { opacity: 1; transition: opacity 0.5s; } box.same { opacity: 1; }");
		same.Toggle("same");
		Test.Assert(same.Root.ActionManager.IsEmpty);
	}

	[Test]
	public static void AnyPropertyMovesALengthAColourBoxShadowsATransform()
	{
		let bed = scope TransitionBed("box { width: 100; background-color: #000000; box-shadow: 0 0 0 transparent; transform: rotate(0deg); " +
			"transition: all 1s linear; } " +
			"box.on { width: 200; background-color: #ff0000; box-shadow: 0 4px 8px #000000; transform: rotate(90deg); }");
		bed.Toggle("on");
		bed.Advance(0.5);
		Test.Assert(Near(bed.Widget.Size.X, 150.0f));
		Test.Assert(Near(bed.Widget.Box.BackgroundColor.R, 0.5f));
		Test.Assert(bed.Widget.Box.Shadows.Count == 1);
		Test.Assert(Near(bed.Widget.Box.Shadows[0].Offset.Y, 2.0f));
		Test.Assert(Near(bed.Widget.Box.Shadows[0].Blur, 4.0f));
		Test.Assert(bed.Widget.StyleTransforms.Count == 1);
		Test.Assert(Near(bed.Widget.StyleTransforms[0].Angle, 0.7853982f)); // 45deg
		bed.Advance(0.5);
		Test.Assert(Near(bed.Widget.Size.X, 200.0f));
		Test.Assert(Near(bed.Widget.StyleTransforms[0].Angle, 1.5707963f));
	}

	[Test]
	public static void ADelayHoldsTheOldValueAChangeMidWayRetargetsFromWhereItIs()
	{
		let bed = scope TransitionBed("box { width: 100; transition: width 1s linear 0.5s; } box.wide { width: 300; }");
		bed.Toggle("wide");
		bed.Advance(0.25);
		Test.Assert(Near(bed.Widget.Size.X, 100.0f)); // still in the delay
		bed.Advance(0.75); // 0.5 s into the move
		Test.Assert(Near(bed.Widget.Size.X, 200.0f));
		bed.Toggle("wide"); // back, from 200, after its own delay
		bed.Advance(0.5);
		Test.Assert(Near(bed.Widget.Size.X, 200.0f));
		bed.Advance(0.5);
		Test.Assert(Near(bed.Widget.Size.X, 150.0f)); // halfway from 200 to 100
	}

	[Test]
	public static void AGradientsStopsAndAngleMoveDifferentShapesSwitchHalfway()
	{
		let bed = scope TransitionBed("box { background-image: linear-gradient(0deg, #000000, #000000); transition: background-image 1s linear; } " +
			"box.on { background-image: linear-gradient(90deg, #ff0000, #0000ff); }");
		bed.Toggle("on");
		bed.Advance(0.5);
		Test.Assert(bed.Widget.Box.Layers.Count == 1);
		Test.Assert(Near(bed.Widget.Box.Layers[0].Gradient.Angle, 0.7853982f));
		Test.Assert(Near(bed.Widget.Box.Layers[0].Gradient.Stops[0].Color.R, 0.5f));

		// A keyword cannot interpolate: it switches at the halfway point.
		let left = scope StyleValue();
		let right = scope StyleValue();
		left.Kind = .Keyword;
		right.Kind = .Keyword;
		left.Keyword.Set("left");
		right.Keyword.Set("right");
		let mid = scope StyleValue();
		InterpolateStyleValue(left, right, 0.4f, mid);
		Test.Assert(mid.Keyword == "left");
		InterpolateStyleValue(left, right, 0.6f, mid);
		Test.Assert(mid.Keyword == "right");
	}

	[Test]
	public static void AWidgetDestroyedMidMoveEndsItsAnimationWhichNeverTouchesItAgain()
	{
		let bed = scope TransitionBed("box { opacity: 1; transition: opacity 1s linear; } box.gone { opacity: 0; }");
		bed.Toggle("gone");
		Test.Assert(bed.Root.ActionManager.Count == 1);
		bed.Styles.Forget(bed.Widget);
		bed.Root.RemoveChild(bed.Widget);
		bed.Widget.ReleaseRef(); // destroyed: the animation held it weakly
		bed.Widget = null;
		bed.Advance(0.25);
		Test.Assert(bed.Root.ActionManager.IsEmpty);
	}

	[Test]
	public static void TransformListsOfDifferentFunctionsMoveThroughTheirMatrices()
	{
		let a = scope StyleValue();
		let b = scope StyleValue();
		a.Kind = .Transforms;
		b.Kind = .Transforms;
		Test.Assert(ParseTransforms("translate(100px, 0)", a.Transforms));
		Test.Assert(ParseTransforms("rotate(90deg)", b.Transforms));
		var ctx = StyleInterpolationContext();
		ctx.BoxSize = .(100.0f, 50.0f);
		// Halfway: half the translation, half the turn, as one matrix.
		let half = scope StyleValue();
		InterpolateStyleValue(a, b, 0.5f, half, ctx);
		Test.Assert(half.Transforms.Count == 1);
		Test.Assert(half.Transforms[0].Kind == .Matrix);
		let m = ComposeTransforms(half.Transforms, ctx.BoxSize);
		Test.Assert(Near(m.Tx, 50.0f));
		Test.Assert(Near((float)Math.Atan2((double)m.B, (double)m.A), 0.7853982f));
		// The ends are the lists themselves.
		let end = scope StyleValue();
		InterpolateStyleValue(a, b, 1.0f, end, ctx);
		let atEnd = ComposeTransforms(end.Transforms, ctx.BoxSize);
		Test.Assert(NodeFixtures.Near(atEnd.A, 0.0f, 1e-5f));
		Test.Assert(Near(atEnd.B, 1.0f));
		Test.Assert(NodeFixtures.Near(atEnd.Tx, 0.0f, 1e-4f));

		// Through matrices the rotation goes the short way round: 170deg to -170deg passes 180, not 0.
		a.Transforms.Clear();
		Test.Assert(ParseTransforms("rotate(170deg) scale(1)", a.Transforms));
		b.Transforms.Clear();
		Test.Assert(ParseTransforms("rotate(-170deg)", b.Transforms));
		let turnedValue = scope StyleValue();
		InterpolateStyleValue(a, b, 0.5f, turnedValue, ctx);
		let turned = ComposeTransforms(turnedValue.Transforms, ctx.BoxSize);
		Test.Assert(Near(turned.A, -1.0f)); // 180deg
		Test.Assert(NodeFixtures.Near(turned.B, 0.0f, 1e-4f));

		// A skew and a scale survive the decomposition (a matrix's own ends are reproduced).
		a.Transforms.Clear();
		Test.Assert(ParseTransforms("skewX(30deg) scale(2, 3)", a.Transforms));
		b.Transforms.Clear();
		Test.Assert(ParseTransforms("rotate(10deg)", b.Transforms));
		let startValue = scope StyleValue();
		InterpolateStyleValue(a, b, 0.0f, startValue, ctx);
		let start = ComposeTransforms(startValue.Transforms, ctx.BoxSize);
		let original = ComposeTransforms(a.Transforms, ctx.BoxSize);
		Test.Assert(Near(start.A, original.A));
		Test.Assert(NodeFixtures.Near(start.B, original.B, 1e-4f));
		Test.Assert(Near(start.C, original.C));
		Test.Assert(Near(start.D, original.D));
	}

	[Test]
	public static void LengthsInDifferentUnitsMoveInPixelsAPercentageAgainstAnotherUnitSwitches()
	{
		let bed = scope TransitionBed("box { width: 100px; transition: width 1s linear; } box.on { width: 10rem; }");
		bed.Toggle("on");
		bed.Advance(0.5);
		Test.Assert(Near(bed.Widget.Size.X, 130.0f)); // (100 + 160) / 2, rem at 16

		let px = scope StyleValue();
		let pct = scope StyleValue();
		px.Kind = .Length;
		pct.Kind = .Length;
		px.Length = LengthValue(100.0f, .Px);
		pct.Length = LengthValue(50.0f, .Percent);
		let ctx = StyleInterpolationContext();
		let mid = scope StyleValue();
		InterpolateStyleValue(px, pct, 0.4f, mid, ctx);
		Test.Assert(mid.Length.Unit == .Px);
		InterpolateStyleValue(px, pct, 0.6f, mid, ctx);
		Test.Assert(mid.Length.Unit == .Percent);
	}

	[Test]
	public static void TheLonghandsCascadeOnTheirOwnShorterListsRepeating()
	{
		// The shorthand sets all four; a later longhand overrides one; a one-item list repeats.
		let bed = scope TransitionBed("box { opacity: 1; width: 100; transition: opacity 4s ease; } " +
			"box.fast { transition-property: opacity, width; transition-duration: 1s; transition-timing-function: linear; } " +
			"box.fast.on { opacity: 0; width: 200; }");
		bed.Toggle("fast");
		bed.Toggle("on");
		bed.Advance(0.5);
		Test.Assert(Near(bed.Widget.Alpha, 0.5f));
		Test.Assert(Near(bed.Widget.Size.X, 150.0f));

		let composed = scope List<TransitionSpec>();
		defer { ClearAndDeleteItems!(composed); }
		ComposeTransitions("a, b, c", "1s, 2s", "linear", "0s", composed);
		Test.Assert(composed.Count == 3);
		Test.Assert(Near(composed[2].Duration, 1.0f)); // 1s, 2s, 1s
		Test.Assert(composed[1].Timing.Kind == .Linear);
	}

	[Test]
	public static void AnimationPlayStatePausesAnAnimationsClockAndRunningResumesIt()
	{
		let bed = scope TransitionBed("@keyframes grow { from { width: 100; } to { width: 200; } } " +
			"box { animation: grow 1s linear infinite; } box.held { animation-play-state: paused; }");
		bed.Advance(0.25);
		Test.Assert(Near(bed.Widget.Size.X, 125.0f));
		bed.Toggle("held");
		bed.Advance(0.5);
		Test.Assert(Near(bed.Widget.Size.X, 125.0f)); // paused
		bed.Toggle("held");
		bed.Advance(0.25);
		Test.Assert(Near(bed.Widget.Size.X, 150.0f)); // resumed where it stood
	}

	[Test]
	public static void DestroyedWidgetsEntriesDoNotPileUpNorPassToAWidgetAtTheirAddress()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let styles = scope StyleManager();
		let sheet = scope StyleSheet();
		CSSParser.Parse("box { opacity: 0.3; } box.glow { animation: glow 1s linear; } " +
			"@keyframes glow { from { opacity: 0; } to { opacity: 1; } }", sheet);
		styles.StyleSheet = sheet;
		// Churn: rows made, styled and destroyed, as a list rebuilding them does, nobody calling Forget.
		for (int i = 0; i < 2000; i++)
		{
			let row = new UIWidget();
			row.Tag = "box";
			root.AddChild(row);
			styles.ApplyTree(root);
			root.RemoveChild(row);
			row.ReleaseRef();
		}
		styles.ApplyTree(root);
		Test.Assert(styles.CachedWidgetCount < 600); // swept as they grew, not one per row ever made

		// A widget at a destroyed one's address: its own style, and its own animation from the start.
		void* address = null;
		{
			let first = new UIWidget();
			first.Tag = "box";
			first.AddClass("glow");
			root.AddChild(first);
			styles.ApplyTree(root);
			root.Context.Update(SceneFixtures.Seconds(2.0)); // its animation ran out
			address = Internal.UnsafeCastToPtr(first);
			root.RemoveChild(first);
			first.ReleaseRef();
		}
		bool reused = false;
		for (int attempt = 0; (attempt < 64) && !reused; attempt++)
		{
			let next = new UIWidget();
			if (Internal.UnsafeCastToPtr(next) != address)
			{
				next.ReleaseRef();
				continue;
			}
			reused = true;
			next.Tag = "box";
			next.AddClass("glow");
			root.AddChild(next);
			styles.ApplyTree(root);
			root.Context.Update(SceneFixtures.Seconds(0.5));
			Test.Assert(Near(next.Alpha, 0.5f)); // half way through its own run (not the 0.3 at rest)
			root.RemoveChild(next);
			next.ReleaseRef();
		}
		// When no widget landed at the freed address, the reuse half was not exercised.
	}
}
