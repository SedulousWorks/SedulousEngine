using System;
using Sedulous.Core;
using Sedulous.VG.SVG;

namespace Sedulous.VG.SVG.Tests;

/// Parsing transform attributes.
class SVGTransformParserTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;
	private static bool NearPoint(Float2 a, Float2 b, float epsilon = 0.001f)
		=> Near(a.X, b.X, epsilon) && Near(a.Y, b.Y, epsilon);

	/// Where a point lands after the transform, which is the only thing a transform is for.
	private static Float2 Apply(StringView transform, Float2 point)
	{
		Test.Assert(SVGTransformParser.Parse(transform) case .Ok(let matrix),
			scope $"'{transform}' did not parse");
		return TransformPoint2D(point, matrix);
	}

	[Test]
	public static void AnEmptyTransformIsIdentity()
	{
		Test.Assert(SVGTransformParser.Parse("") case .Ok(let matrix));
		Test.Assert(matrix == Float4x4.Identity());
	}

	[Test]
	public static void TranslateMovesThePoint()
	{
		Test.Assert(NearPoint(Apply("translate(10, 20)", .(0, 0)), .(10, 20)));
		Test.Assert(NearPoint(Apply("translate(10,20)", .(5, 5)), .(15, 25)));
	}

	/// One argument moves along X only, and the Y defaults to zero.
	[Test]
	public static void TranslateDefaultsItsSecondArgumentToZero()
	{
		Test.Assert(NearPoint(Apply("translate(10)", .(0, 0)), .(10, 0)));
	}

	[Test]
	public static void ScaleMultipliesThePoint()
	{
		Test.Assert(NearPoint(Apply("scale(2, 3)", .(1, 1)), .(2, 3)));
	}

	/// One argument scales UNIFORMLY, which is the opposite of translate's default and the
	/// kind of asymmetry that is easy to get wrong.
	[Test]
	public static void ScaleDefaultsToUniform()
	{
		Test.Assert(NearPoint(Apply("scale(2)", .(1, 1)), .(2, 2)));
	}

	[Test]
	public static void RotateTurnsAboutTheOrigin()
	{
		Test.Assert(NearPoint(Apply("rotate(90)", .(1, 0)), .(0, 1)));
		Test.Assert(NearPoint(Apply("rotate(180)", .(1, 0)), .(-1, 0)));
	}

	/// With a centre it turns about THAT point, which is three factors rather than one.
	[Test]
	public static void RotateAboutAPointLeavesThatPointAlone()
	{
		let centre = Float2(50, 50);
		Test.Assert(NearPoint(Apply("rotate(90, 50, 50)", centre), centre));
		// And a point beside it swings around.
		Test.Assert(NearPoint(Apply("rotate(90, 50, 50)", .(51, 50)), .(50, 51)));
	}

	[Test]
	public static void SkewShearsAlongOneAxis()
	{
		// A skew along X displaces X by Y, so a point on the X axis does not move.
		Test.Assert(NearPoint(Apply("skewX(45)", .(1, 0)), .(1, 0)));
		Test.Assert(NearPoint(Apply("skewX(45)", .(0, 1)), .(1, 1)));

		Test.Assert(NearPoint(Apply("skewY(45)", .(0, 1)), .(0, 1)));
		Test.Assert(NearPoint(Apply("skewY(45)", .(1, 0)), .(1, 1)));
	}

	/// The six values are the linear part in column order, then the translation.
	[Test]
	public static void MatrixTakesItsSixValues()
	{
		// A scale of two with a translation of ten and twenty.
		Test.Assert(NearPoint(Apply("matrix(2, 0, 0, 2, 10, 20)", .(1, 1)), .(12, 22)));
		Test.Assert(NearPoint(Apply("matrix(1,0,0,1,0,0)", .(3, 4)), .(3, 4)), "the identity");
	}

	/// Functions COMPOSE left to right as written: the leftmost is applied last, so
	/// translate then scale scales the point and then moves it.
	[Test]
	public static void FunctionsComposeLeftToRight()
	{
		Test.Assert(NearPoint(Apply("translate(10, 0) scale(2)", .(1, 0)), .(12, 0)));
		// The other order scales the translation too.
		Test.Assert(NearPoint(Apply("scale(2) translate(10, 0)", .(1, 0)), .(22, 0)));
	}

	[Test]
	public static void SeparatorsAreFlexible()
	{
		let expected = Float2(12, 22);
		Test.Assert(NearPoint(Apply("translate(10,20) scale(2)", .(1, 1)), expected));
		Test.Assert(NearPoint(Apply("translate(10 20) scale(2)", .(1, 1)), expected));
		Test.Assert(NearPoint(Apply("  translate( 10 , 20 )   scale( 2 )  ", .(1, 1)), expected));
		Test.Assert(NearPoint(Apply("translate(10,20)\n\tscale(2)", .(1, 1)), expected));
	}

	[Test]
	public static void NegativeAndFractionalValuesParse()
	{
		Test.Assert(NearPoint(Apply("translate(-10, -20)", .(0, 0)), .(-10, -20)));
		Test.Assert(NearPoint(Apply("scale(0.5)", .(4, 4)), .(2, 2)));
		Test.Assert(NearPoint(Apply("translate(1e2, 0)", .(0, 0)), .(100, 0)));
	}

	/// A malformed transform FAILS rather than being partly applied, so an importer does
	/// not place an element somewhere arbitrary.
	[Test]
	public static void MalformedTransformsFail()
	{
		for (let text in scope StringView[](
			"translate", "translate(", "translate(10", "translate(10, 20",
			"rotate()", "matrix(1,2,3)", "wobble(10)", "scale(abc)"))
		{
			Test.Assert(SVGTransformParser.Parse(text) case .Err,
				scope $"'{text}' should not parse");
		}
	}
}
