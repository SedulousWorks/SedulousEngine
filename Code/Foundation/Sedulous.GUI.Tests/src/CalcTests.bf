using System;
using Sedulous.Core;
using Sedulous.GUI;
using internal Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// calc(): a length as a sum of units, + and - between terms, * and / by plain numbers,
/// parentheses and nested calc(); resolved where its units are, and a transition between a calc()
/// and a plain length blending each unit.
class CalcTests
{
	private static float Term(LengthValue v, LengthUnit unit) => v.Terms[(int)unit];

	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	private static bool Near(float a, float b, float epsilon = 1.2e-5f) =>
		Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	[Test]
	public static void SumsOfUnitsParseIntoTheirTerms()
	{
		let a = ParseLengthValue("calc(100% - 20px)");
		Test.Assert(a.HasValue);
		Test.Assert(a.Value.Unit == .Calc);
		Test.Assert(Near(Term(a.Value, .Percent), 100.0f));
		Test.Assert(Near(Term(a.Value, .Px), -20.0f));
		let b = ParseLengthValue("calc(2 * (10px + 5px) - calc(1em / 2))");
		Test.Assert(b.HasValue);
		Test.Assert(Near(Term(b.Value, .Px), 30.0f));
		Test.Assert(Near(Term(b.Value, .Em), -0.5f));
		Test.Assert(ParseLengthValue("calc(-2rem + 50vw)").HasValue);
		// What CSS refuses: a length times a length, a number plus a length, dividing by a length
		// or by zero, unbalanced parentheses, an unknown unit.
		String[?] bad = .("calc(10px * 2px)", "calc(10px + 2)", "calc(10px / 1px)", "calc(10px / 0)", "calc((10px + 2px)", "calc(10pt)",
			"calc()");
		for (let text in bad)
			Test.Assert(!ParseLengthValue(text).HasValue, text);
	}

	[Test]
	public static void ItResolvesEachUnitAgainstItsOwnBase()
	{
		var ctx = LengthContext();
		ctx.RootFontSize = 10.0f;
		ctx.ElementFontSize = 20.0f;
		ctx.ViewportWidth = 800.0f;
		ctx.ViewportHeight = 600.0f;
		let v = ParseLengthValue("calc(50% + 1em + 2rem + 10vw - 5vh + 3px)").Value;
		// 50% of 200, 20, 20, 80, -30, 3.
		Test.Assert(Near(ResolveLengthValue(v, ctx, 200.0f), 100.0f + 20.0f + 20.0f + 80.0f - 30.0f + 3.0f));
		Test.Assert(Near(v.PercentPart, 50.0f));
		Test.Assert(Near(ResolveLengthValue(v, ctx, 0.0f), 93.0f)); // base 0: the percent drops out
	}

	[Test]
	public static void ATransitionBetweenACalcAndAPlainLengthBlendsEachUnit()
	{
		let from = ParseLengthValue("calc(100% - 40px)").Value;
		let to = ParseLengthValue("20px").Value;
		Test.Assert(StyleInterpolationDetail.MixLength(from, to, 0.5f, let mid));
		Test.Assert(mid.Unit == .Calc);
		Test.Assert(Near(Term(mid, .Percent), 50.0f));
		Test.Assert(Near(Term(mid, .Px), -10.0f));
	}
}
