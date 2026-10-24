using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Easing functions: curves sampled against their formulas. A cubic Bezier is checked on its own
/// parametric points (x(s), y(s)); steps() against CSS's definitions of each jump position; the
/// names against their CSS curves.
class EasingTests
{
	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	private static bool Near(float a, float b, float epsilon = 1.2e-5f) =>
		Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	/// The curve from (0, 0) through (x1, y1), (x2, y2) to (1, 1) at parameter s.
	private static float BezierCoordinate(float s, float p1, float p2)
	{
		let u = 1.0f - s;
		return 3.0f * u * u * s * p1 + 3.0f * u * s * s * p2 + s * s * s;
	}

	private static void CheckBezier(Easing e, float x1, float y1, float x2, float y2)
	{
		for (int i = 0; i <= 50; i++)
		{
			let s = (float)i / 50.0f;
			let x = BezierCoordinate(s, x1, x2);
			let y = BezierCoordinate(s, y1, y2);
			Test.Assert(Near(e.Evaluate(x), y, 1e-4f), scope $"s {s} x {x}: {e.Evaluate(x)}, expected {y}");
		}
	}

	[Test]
	public static void CubicBezierFollowsItsCurveOvershootIncluded()
	{
		let custom = ParseEasing("cubic-bezier(0.1, 0.7, 1.0, 0.1)");
		Test.Assert(custom.HasValue);
		CheckBezier(custom.Value, 0.1f, 0.7f, 1.0f, 0.1f);

		// y may leave [0, 1] (a back-out bounce); x may not.
		let back = ParseEasing("cubic-bezier(0.34, 1.56, 0.64, 1)");
		Test.Assert(back.HasValue);
		CheckBezier(back.Value, 0.34f, 1.56f, 0.64f, 1.0f);
		Test.Assert(back.Value.Evaluate(0.6f) > 1.0f);
		Test.Assert(!ParseEasing("cubic-bezier(1.5, 0, 0.5, 1)").HasValue);

		Test.Assert(Near(custom.Value.Evaluate(0.0f), 0.0f));
		Test.Assert(Near(custom.Value.Evaluate(1.0f), 1.0f));
	}

	[Test]
	public static void TheNamedCurvesAreCss()
	{
		CheckBezier(ParseEasing("ease").Value, 0.25f, 0.1f, 0.25f, 1.0f);
		CheckBezier(ParseEasing("ease-in").Value, 0.42f, 0.0f, 1.0f, 1.0f);
		CheckBezier(ParseEasing("ease-out").Value, 0.0f, 0.0f, 0.58f, 1.0f);
		CheckBezier(ParseEasing("ease-in-out").Value, 0.42f, 0.0f, 0.58f, 1.0f);
		let linear = ParseEasing("linear").Value;
		for (int i = 0; i <= 10; i++)
			Test.Assert(Near(linear.Evaluate((float)i / 10.0f), (float)i / 10.0f));
	}

	[Test]
	public static void StepsJumpWhereTheirPositionSays()
	{
		// jump-end (the default): 0, 0.25, 0.5, 0.75 across the intervals, 1 at the end.
		let end = ParseEasing("steps(4)").Value;
		Test.Assert(Near(end.Evaluate(0.0f), 0.0f));
		Test.Assert(Near(end.Evaluate(0.24f), 0.0f));
		Test.Assert(Near(end.Evaluate(0.25f), 0.25f));
		Test.Assert(Near(end.Evaluate(0.99f), 0.75f));
		Test.Assert(Near(end.Evaluate(1.0f), 1.0f));
		// jump-start: each interval starts on its jump.
		let start = ParseEasing("steps(4, jump-start)").Value;
		Test.Assert(Near(start.Evaluate(0.0f), 0.25f));
		Test.Assert(Near(start.Evaluate(0.74f), 0.75f));
		Test.Assert(Near(start.Evaluate(0.75f), 1.0f));
		// jump-none: 5 steps hold 0, 0.25, 0.5, 0.75, 1.
		let none = ParseEasing("steps(5, jump-none)").Value;
		Test.Assert(Near(none.Evaluate(0.0f), 0.0f));
		Test.Assert(Near(none.Evaluate(0.2f), 0.25f));
		Test.Assert(Near(none.Evaluate(0.99f), 1.0f));
		// jump-both: 3 steps hold 1/4, 2/4, 3/4, and 1 at the end.
		let both = ParseEasing("steps(3, jump-both)").Value;
		Test.Assert(Near(both.Evaluate(0.0f), 0.25f));
		Test.Assert(Near(both.Evaluate(0.5f), 0.5f));
		Test.Assert(Near(both.Evaluate(0.99f), 0.75f));
		Test.Assert(Near(both.Evaluate(1.0f), 1.0f));
		// step-start and step-end are steps(1, start / end).
		Test.Assert(Near(ParseEasing("step-start").Value.Evaluate(0.1f), 1.0f));
		Test.Assert(Near(ParseEasing("step-end").Value.Evaluate(0.9f), 0.0f));
		// Malformed.
		Test.Assert(!ParseEasing("steps(0)").HasValue);
		Test.Assert(!ParseEasing("steps(1, jump-none)").HasValue);
		Test.Assert(!ParseEasing("wobble").HasValue);
	}

	[Test]
	public static void TimesParseInSecondsAndMilliseconds()
	{
		Test.Assert(Near(ParseTime("0.25s").Value, 0.25f));
		Test.Assert(Near(ParseTime("250ms").Value, 0.25f));
		Test.Assert(!ParseTime("250").HasValue);
	}

	[Test]
	public static void TheNamedCurvesPastCssTenFamiliesEasedInOutAndInOut()
	{
		String[?] families = .("sine", "quad", "cubic", "quart", "quint", "expo", "circ", "back", "elastic", "bounce");
		String[?] modes = .("ease-in-", "ease-out-", "ease-in-out-");
		for (let family in families)
		{
			for (let mode in modes)
			{
				let name = scope String(mode);
				name.Append(family);
				let e = ParseEasing(name);
				Test.Assert(e.HasValue, name);
				Test.Assert(e.Value.Kind == .Named, name);
				Test.Assert(Near(e.Value.Evaluate(0.0f), 0.0f, 1e-3f), name);
				Test.Assert(Near(e.Value.Evaluate(1.0f), 1.0f, 1e-3f), name);
			}
		}
		let outQuad = ParseEasing("ease-out-quad").Value;
		Test.Assert(Near(outQuad.Evaluate(0.5f), 0.75f));
		Test.Assert(Near(ParseEasing("ease-in-quad").Value.Evaluate(0.5f), 0.25f));
		let inOutCubic = ParseEasing("ease-in-out-cubic").Value;
		Test.Assert(Near(inOutCubic.Evaluate(0.5f), 0.5f));
		Test.Assert(Near(inOutCubic.Evaluate(0.25f), 1.0f - inOutCubic.Evaluate(0.75f))); // symmetric
		Test.Assert(ParseEasing("ease-in-back").Value.Evaluate(0.2f) < 0.0f); // pulls back first
		Test.Assert(ParseEasing("ease-out-back").Value.Evaluate(0.8f) > 1.0f); // overshoots
		Test.Assert(ParseEasing("ease-out-bounce").Value.Evaluate(0.5f) > 0.5f);
		// Not curves: an unknown family, a missing one, CSS's own names still beziers.
		Test.Assert(!ParseEasing("ease-out-wobble").HasValue);
		Test.Assert(!ParseEasing("ease-out-").HasValue);
		Test.Assert(ParseEasing("ease-out").Value.Kind == .CubicBezier);
		// A sheet's transition takes them too.
		let list = scope List<TransitionSpec>();
		defer { ClearAndDeleteItems(list); }
		ParseTransitionList("opacity 0.3s ease-out-elastic", list);
		Test.Assert(list.Count == 1);
		Test.Assert(list[0].Timing.Kind == .Named);
		Test.Assert(list[0].Timing.Family == .Elastic);
	}

	[Test]
	public static void ANamedCurvesNameReadsBackAsTheSameCurve()
	{
		let e = Easing.Named(.Back, .InOut);
		let text = scope String();
		NamedEasingText(e, text);
		Test.Assert(text == "ease-in-out-back");
		let again = ParseEasing(text).Value;
		Test.Assert(again.Family == .Back);
		Test.Assert(again.Mode == .InOut);
	}
}
